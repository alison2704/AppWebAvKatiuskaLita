const express = require('express');
const WebSocket = require('ws');

const app = express();
const port = 3000;

// Servir archivos estaticos
app.use(express.static('public'));

// Crear servidor HTTP
const server = app.listen(port, () => {
  console.log(`Servidor corriendo en http://localhost:${port}`);
});

// Crear servidor WebSocket
const wss = new WebSocket.Server({ server });

// Almacenar clientes conectados con sus metadatos
const clients = new Map(); // ws -> { username, id }

// Contador para generar IDs unicos
let userIdCounter = 0;

// Limites de validacion
const MAX_MESSAGE_LENGTH = 500;
const MAX_USERNAME_LENGTH = 20;

/**
 * Envia un mensaje a todos los clientes conectados
 * @param {object} payload - Objeto mensaje a enviar
 */
function broadcast(payload) {
  const data = JSON.stringify(payload);
  clients.forEach((meta, client) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(data);
    }
  });
}

/**
 * Envia el contador de usuarios a todos los clientes
 */
function broadcastUserCount() {
  broadcast({
    type: 'userCount',
    count: clients.size,
    timestamp: new Date().toLocaleTimeString('es-ES', {
      hour: '2-digit',
      minute: '2-digit'
    })
  });
}

/**
 * Genera un color aleatorio estable para un usuario
 * @param {string} username - Nombre del usuario
 * @returns {string} Color en formato hsl
 */
function getUserColor(username) {
  const colors = [
    '#e67e22', // naranja
    '#3498db', // azul
    '#e74c3c', // rojo
    '#9b59b6', // morado
    '#1abc9c'  // turquesa
  ];
  let hash = 0;
  for (let i = 0; i < username.length; i++) {
    hash = username.charCodeAt(i) + ((hash << 5) - hash);
  }
  return colors[Math.abs(hash) % colors.length];
}

wss.on('connection', (ws) => {
  const clientId = ++userIdCounter;
  clients.set(ws, { username: null, id: clientId });

  // Enviar contador inicial al nuevo cliente
  ws.send(JSON.stringify({
    type: 'userCount',
    count: clients.size,
    timestamp: new Date().toLocaleTimeString('es-ES', {
      hour: '2-digit',
      minute: '2-digit'
    })
  }));

  ws.on('message', (data) => {
    try {
      const message = JSON.parse(data);
      const meta = clients.get(ws);

      // === TIPO: JOIN (usuario se une con su nombre) ===
      if (message.type === 'join') {
        const username = (message.username || '').trim();

        if (!username) {
          ws.send(JSON.stringify({
            type: 'error',
            text: 'El nombre de usuario no puede estar vacio.'
          }));
          return;
        }

        if (username.length > MAX_USERNAME_LENGTH) {
          ws.send(JSON.stringify({
            type: 'error',
            text: `El nombre de usuario no puede superar ${MAX_USERNAME_LENGTH} caracteres.`
          }));
          return;
        }

        meta.username = username;
        meta.color = getUserColor(username);

        // Notificar a todos que el usuario se unio
        broadcast({
          type: 'system',
          subtype: 'join',
          username: username,
          text: `${username} se unio al chat`,
          timestamp: new Date().toLocaleTimeString('es-ES', {
            hour: '2-digit',
            minute: '2-digit'
          })
        });

        broadcastUserCount();
        return;
      }

      // === TIPO: TYPING (indicador "escribiendo...") ===
      if (message.type === 'typing') {
        const isTyping = message.isTyping === true || message.isTyping === 'true';
        const meta = clients.get(ws);
        if (meta && meta.username) {
          // Reenviar a todos excepto al remitente
          const payload = JSON.stringify({
            type: 'typing',
            username: meta.username,
            isTyping: isTyping
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
        const meta = clients.get(ws);
        const username = meta ? meta.username : (message.username || '').trim();
        const text = (message.text || '').trim();

        // Validar nombre de usuario
        if (!username) {
          ws.send(JSON.stringify({
            type: 'error',
            text: 'Debes ingresar tu nombre de usuario primero.'
          }));
          return;
        }

        // Rechazar mensajes vacios
        if (!text) {
          ws.send(JSON.stringify({
            type: 'error',
            text: 'El mensaje no puede estar vacio.'
          }));
          return;
        }

        // Rechazar mensajes demasiado largos
        if (text.length > MAX_MESSAGE_LENGTH) {
          ws.send(JSON.stringify({
            type: 'error',
            text: `El mensaje es demasiado largo (maximo ${MAX_MESSAGE_LENGTH} caracteres).`
          }));
          return;
        }

        // Broadcast del mensaje a todos
        broadcast({
          type: 'message',
          username: username,
          text: text,
          color: meta ? meta.color : '#666',
          timestamp: new Date().toLocaleTimeString('es-ES', {
            hour: '2-digit',
            minute: '2-digit'
          })
        });
      }
    } catch (error) {
      console.error('Error procesando mensaje:', error);
    }
  });

  ws.on('close', () => {
    const meta = clients.get(ws);

    if (meta && meta.username) {
      // Notificar que el usuario salio
      broadcast({
        type: 'system',
        subtype: 'leave',
        username: meta.username,
        text: `${meta.username} salio del chat`,
        timestamp: new Date().toLocaleTimeString('es-ES', {
          hour: '2-digit',
          minute: '2-digit'
        })
      });
    }

    clients.delete(ws);
    console.log('Cliente desconectado. Total:', clients.size);
    broadcastUserCount();
  });

  ws.on('error', (error) => {
    console.error('Error WebSocket:', error);
    clients.delete(ws);
    broadcastUserCount();
  });

  console.log('Cliente conectado. Total:', clients.size);
});
