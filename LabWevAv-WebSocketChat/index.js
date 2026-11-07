const express = require('express');
const WebSocket = require('ws');
const dotenv = require('dotenv');
const admin = require('firebase-admin');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const jwt = require('jsonwebtoken');

// ============================================
// CARGAR VARIABLES DE ENTORNO
// ============================================
dotenv.config();

const PORT = process.env.PORT || 3000;
const ALLOWED_ORIGIN = process.env.ALLOWED_ORIGIN || 'http://localhost:3000';
const JWT_SECRET = process.env.JWT_SECRET || 'fallback_secret_change_me';

// ============================================
// INICIALIZAR FIREBASE ADMIN SDK
// ============================================
const serviceAccount = {
  type: 'service_account',
  project_id: process.env.FIREBASE_PROJECT_ID,
  private_key: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
  client_email: process.env.FIREBASE_CLIENT_EMAIL,
  token_uri: 'https://oauth2.googleapis.com/token',
};

admin.initializeApp({
  credential: admin.cert(serviceAccount),
});

const db = getFirestore();

// ============================================
// EXPRESS
// ============================================
const app = express();

// Endpoint para obtener el firebaseConfig del cliente (sin exponer secretos)
app.get('/config', (req, res) => {
  res.json({
    apiKey: 'AIzaSyB7LQiK7eAzyEp_tkUIouBeAp2Eo4n3K2I',
    authDomain: 'chatauth-2ab01.firebaseapp.com',
    projectId: 'chatauth-2ab01',
    storageBucket: 'chatauth-2ab01.firebasestorage.app',
    messagingSenderId: '252978820296',
    appId: '1:252978820296:web:79ba0e66727e3c147021fd',
  });
});

app.use(express.static('public'));

const server = app.listen(PORT, () => {
  console.log(`Servidor corriendo en http://localhost:${PORT}`);
  console.log(`Dominio permitido: ${ALLOWED_ORIGIN}`);
});

// ============================================
// WEBSOCKET CON VALIDACION DE DOMINIO + JWT
// ============================================

const wss = new WebSocket.Server({
  server,
  verifyClient: (info) => {
    // === ITEM 4: Validar que la conexion viene del dominio permitido ===
    if (info.origin !== ALLOWED_ORIGIN) {
      console.log(`Conexion rechazada - origen no autorizado: ${info.origin}`);
      return false;
    }
    return true;
  },
});

// Almacenar clientes conectados: ws -> { uid, email, username }
const clients = new Map();

// Limites
const MAX_MESSAGE_LENGTH = 500;
const MAX_USERNAME_LENGTH = 20;
const MAX_HISTORY = 50;

// ============================================
// FUNCIONES AUXILIARES
// ============================================

function broadcast(payload) {
  const data = JSON.stringify(payload);
  clients.forEach((meta, client) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(data);
    }
  });
}

function broadcastUserCount() {
  broadcast({
    type: 'userCount',
    count: clients.size,
    timestamp: nowTime(),
  });
}

function nowTime() {
  return new Date().toLocaleTimeString('es-ES', {
    hour: '2-digit',
    minute: '2-digit',
  });
}

function getUserColor(username) {
  const colors = [
    '#e67e22', '#3498db', '#e74c3c',
    '#9b59b6', '#1abc9c', '#f39c12',
    '#2ecc71', '#e84393'
  ];
  let hash = 0;
  for (let i = 0; i < username.length; i++) {
    hash = username.charCodeAt(i) + ((hash << 5) - hash);
  }
  return colors[Math.abs(hash) % colors.length];
}

// ============================================
// CARGAR HISTORIAL DE MENSAJES DE FIRESTORE
// ============================================

async function loadHistory(ws) {
  try {
    const snapshot = await db
      .collection('messages')
      .orderBy('serverTimestamp', 'asc')
      .limit(MAX_HISTORY)
      .get();

    const messages = [];
    snapshot.forEach((doc) => {
      const data = doc.data();
      messages.push({
        type: 'message',
        username: data.username,
        text: data.text,
        color: data.color || '#666',
        timestamp: data.displayTimestamp || '',
        fromHistory: true,
      });
    });

    if (messages.length > 0) {
      ws.send(JSON.stringify({
        type: 'history',
        messages: messages,
      }));
    }
  } catch (error) {
    console.error('Error cargando historial:', error);
  }
}

// ============================================
// GUARDAR MENSAJE EN FIRESTORE
// ============================================

async function saveMessage(messageData) {
  try {
    await db.collection('messages').add({
      uid: messageData.uid,
      username: messageData.username,
      text: messageData.text,
      color: messageData.color,
      displayTimestamp: messageData.timestamp,
      serverTimestamp: FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error('Error guardando mensaje en Firestore:', error);
  }
}

// ============================================
// MANEJO DE CONEXIONES WEBSOCKET
// ============================================

wss.on('connection', (ws) => {
  // Cliente no autenticado hasta que envie token valido
  clients.set(ws, { uid: null, email: null, username: null, authenticated: false });

  // Enviar mensaje de bienvenida pidiendo autenticacion
  ws.send(JSON.stringify({
    type: 'authRequired',
    text: 'Por favor envia tu token de autenticacion.',
  }));

  // Timeout: si no se autentica en 10 segundos, cerrar conexion
  const authTimeout = setTimeout(() => {
    const meta = clients.get(ws);
    if (meta && !meta.authenticated) {
      ws.close(4001, 'Timeout de autenticacion');
    }
  }, 10000);

  ws.on('message', async (data) => {
    try {
      const message = JSON.parse(data);
      const meta = clients.get(ws);

      // === TIPO: AUTH (verificar JWT de Firebase) ===
      if (message.type === 'auth') {
        clearTimeout(authTimeout);

        const token = message.token;
        if (!token) {
          ws.send(JSON.stringify({
            type: 'error',
            text: 'Token no proporcionado.',
          }));
          ws.close(4002, 'Token no proporcionado');
          return;
        }

        try {
          // Verificar el JWT con Firebase Admin
          const decoded = await getAuth().verifyIdToken(token);

          // Token valido: extraer info del usuario
          meta.uid = decoded.uid;
          meta.email = decoded.email;

          // Generar JWT propio del servidor para sesion adicional
          const serverToken = jwt.sign(
            { uid: decoded.uid, email: decoded.email },
            JWT_SECRET,
            { expiresIn: '1h' }
          );

          meta.authenticated = true;
          meta.color = getUserColor(meta.email);

          // Obtener username desde Firestore o usar parte del email
          // Si Firestore falla, no bloqueamos el login — usamos fallback
          let usernameFromDb = null;
          try {
            const userDoc = await db.collection('users').doc(decoded.uid).get();
            if (userDoc.exists && userDoc.data().username) {
              usernameFromDb = userDoc.data().username;
            } else {
              // Crear usuario en Firestore si no existe
              usernameFromDb = meta.email.split('@')[0];
              await db.collection('users').doc(decoded.uid).set({
                email: meta.email,
                username: usernameFromDb,
                createdAt: FieldValue.serverTimestamp(),
              });
            }
          } catch (dbError) {
            console.warn('Firestore no disponible, usando username fallback:', dbError.message);
            usernameFromDb = meta.email.split('@')[0];
          }

          meta.username = usernameFromDb;

          // Confirmar autenticacion al cliente
          ws.send(JSON.stringify({
            type: 'authSuccess',
            username: meta.username,
            email: meta.email,
            serverToken: serverToken,
          }));

          // Cargar historial de mensajes
          await loadHistory(ws);

          // Notificar a todos que el usuario se unio
          broadcast({
            type: 'system',
            subtype: 'join',
            username: meta.username,
            text: `${meta.username} se unio al chat`,
            timestamp: nowTime(),
          });

          broadcastUserCount();
          console.log(`Usuario autenticado: ${meta.email}`);
          return;

        } catch (error) {
          console.error('Error verificando token:', error.message);
          ws.send(JSON.stringify({
            type: 'error',
            text: 'Token invalido o expirado. Inicia sesion de nuevo.',
          }));
          ws.close(4003, 'Token invalido');
          return;
        }
      }

      // === A partir de aqui, requiere autenticacion ===
      if (!meta || !meta.authenticated) {
        ws.send(JSON.stringify({
          type: 'error',
          text: 'Debes autenticarte primero.',
        }));
        return;
      }

      // === TIPO: SET_USERNAME (cambiar nombre de usuario) ===
      if (message.type === 'setUsername') {
        const username = (message.username || '').trim();

        if (!username || username.length > MAX_USERNAME_LENGTH) {
          ws.send(JSON.stringify({
            type: 'error',
            text: `Nombre invalido. Maximo ${MAX_USERNAME_LENGTH} caracteres.`,
          }));
          return;
        }

        const oldName = meta.username;
        meta.username = username;
        meta.color = getUserColor(username);

        // Actualizar en Firestore
        await db.collection('users').doc(meta.uid).update({
          username: username,
        });

        // Notificar cambio
        broadcast({
          type: 'system',
          subtype: 'rename',
          text: `${oldName} ahora se llama ${username}`,
          timestamp: nowTime(),
        });
        return;
      }

      // === TIPO: TYPING (escribiendo...) ===
      if (message.type === 'typing') {
        const isTyping = message.isTyping === true || message.isTyping === 'true';
        if (meta.username) {
          const payload = JSON.stringify({
            type: 'typing',
            username: meta.username,
            isTyping: isTyping,
          });
          clients.forEach((otherMeta, client) => {
            if (client !== ws && client.readyState === WebSocket.OPEN) {
              client.send(payload);
            }
          });
        }
        return;
      }

      // === TIPO: MESSAGE (mensaje de chat) ===
      if (message.type === 'message' || !message.type) {
        const text = (message.text || '').trim();

        // Rechazar mensajes vacios
        if (!text) {
          ws.send(JSON.stringify({
            type: 'error',
            text: 'El mensaje no puede estar vacio.',
          }));
          return;
        }

        // Rechazar mensajes demasiado largos
        if (text.length > MAX_MESSAGE_LENGTH) {
          ws.send(JSON.stringify({
            type: 'error',
            text: `El mensaje es demasiado largo (maximo ${MAX_MESSAGE_LENGTH} caracteres).`,
          }));
          return;
        }

        const msgData = {
          type: 'message',
          uid: meta.uid,
          username: meta.username,
          text: text,
          color: meta.color,
          timestamp: nowTime(),
        };

        // Broadcast a todos los clientes
        broadcast(msgData);

        // Guardar en Firestore (async, sin bloquear)
        saveMessage(msgData);
      }
    } catch (error) {
      console.error('Error procesando mensaje:', error);
    }
  });

  ws.on('close', () => {
    clearTimeout(authTimeout);
    const meta = clients.get(ws);

    if (meta && meta.authenticated && meta.username) {
      broadcast({
        type: 'system',
        subtype: 'leave',
        username: meta.username,
        text: `${meta.username} salio del chat`,
        timestamp: nowTime(),
      });
    }

    clients.delete(ws);
    broadcastUserCount();
    console.log('Cliente desconectado. Total:', clients.size);
  });

  ws.on('error', (error) => {
    console.error('Error WebSocket:', error);
    clearTimeout(authTimeout);
    clients.delete(ws);
    broadcastUserCount();
  });

  console.log('Nueva conexion WebSocket (pendiente autenticacion)');
});
