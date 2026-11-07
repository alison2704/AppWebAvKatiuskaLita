/* ============================================
   CHAT.JS - Cliente WebSocket con autenticacion Firebase
   ============================================ */

// --- Limites ---
const MAX_MESSAGE_LENGTH = 500;
const RECONNECT_DELAY = 3000;
const TYPING_TIMEOUT = 3000;

// --- Estado global ---
let ws = null;
let myUsername = '';
let myEmail = '';
let isConnected = false;
let isAuthenticating = false;
let reconnectTimer = null;
let typingTimer = null;
let isTypingSent = false;
let typingUsers = new Set();
let idToken = null;

// --- Referencias del DOM ---
const messagesArea = document.getElementById('messagesArea');
const messagesList = document.getElementById('messagesList');
const messageInput = document.getElementById('messageInput');
const sendBtn = document.getElementById('sendBtn');
const statusDot = document.getElementById('statusDot');
const statusText = document.getElementById('statusText');
const userCountEl = document.getElementById('userCount');
const themeToggle = document.getElementById('themeToggle');
const typingIndicator = document.getElementById('typingIndicator');
const typingText = document.getElementById('typingText');
const loginOverlay = document.getElementById('loginOverlay');
const loginError = document.getElementById('loginError');
const loginInfo = document.getElementById('loginInfo');
const logoutBtn = document.getElementById('logoutBtn');

// Formularios auth
const loginForm = document.getElementById('loginForm');
const registerForm = document.getElementById('registerForm');
const tabLogin = document.getElementById('tabLogin');
const tabRegister = document.getElementById('tabRegister');
const emailInput = document.getElementById('emailInput');
const passwordInput = document.getElementById('passwordInput');
const regEmailInput = document.getElementById('regEmailInput');
const regPasswordInput = document.getElementById('regPasswordInput');

// ============================================
// TEMA CLARO / OSCURO
// ============================================

function initTheme() {
    const savedTheme = localStorage.getItem('chat-theme');
    document.documentElement.setAttribute('data-theme', savedTheme === 'dark' ? 'dark' : 'light');
}

function toggleTheme() {
    const current = document.documentElement.getAttribute('data-theme');
    const next = current === 'dark' ? 'light' : 'dark';
    document.documentElement.setAttribute('data-theme', next);
    localStorage.setItem('chat-theme', next);
}

themeToggle.addEventListener('click', toggleTheme);

// ============================================
// TABS LOGIN / REGISTRO
// ============================================

tabLogin.addEventListener('click', () => {
    tabLogin.classList.add('active');
    tabRegister.classList.remove('active');
    loginForm.style.display = 'block';
    registerForm.style.display = 'none';
    loginError.textContent = '';
    loginInfo.textContent = '';
});

tabRegister.addEventListener('click', () => {
    tabRegister.classList.add('active');
    tabLogin.classList.remove('active');
    registerForm.style.display = 'block';
    loginForm.style.display = 'none';
    loginError.textContent = '';
    loginInfo.textContent = '';
});

// ============================================
// ESTADO DE CONEXION
// ============================================

function setConnectionState(state) {
    statusDot.className = 'status-dot ' + state;
    switch (state) {
        case 'connected':
            statusText.textContent = 'Conectado';
            break;
        case 'disconnected':
            statusText.textContent = 'Desconectado';
            break;
        case 'reconnecting':
            statusText.textContent = 'Reconectando...';
            break;
    }
}

// ============================================
// AUTENTICACION CON FIREBASE
// ============================================

// Esperar a que auth.js cargue firebaseAuth en window
function waitForFirebaseAuth() {
    return new Promise((resolve) => {
        if (window.firebaseAuth) {
            resolve(window.firebaseAuth);
        } else {
            const interval = setInterval(() => {
                if (window.firebaseAuth) {
                    clearInterval(interval);
                    resolve(window.firebaseAuth);
                }
            }, 100);
        }
    });
}

async function initAuth() {
    const { auth, createUserWithEmailAndPassword, signInWithEmailAndPassword, signOut, onAuthStateChanged } = await waitForFirebaseAuth();

    // Escectar cambios de estado de autenticacion
    onAuthStateChanged(auth, async (user) => {
        if (user) {
            // Usuario logueado - obtener token
            idToken = await user.getIdToken();
            myEmail = user.email;
            loginOverlay.classList.add('hidden');
            logoutBtn.style.display = 'flex';
            loginError.textContent = ''; // limpiar errores previos

            // Conectar WebSocket
            connect();
        } else {
            // Usuario no logueado
            idToken = null;
            myEmail = '';
            loginOverlay.classList.remove('hidden');
            logoutBtn.style.display = 'none';

            if (ws) {
                ws.close();
                ws = null;
            }
        }
    });

    // Login form
    loginForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        loginError.textContent = '';
        loginInfo.textContent = 'Iniciando sesion...';

        const email = emailInput.value.trim();
        const password = passwordInput.value.trim();

        if (!email || !password) {
            loginError.textContent = 'Completa todos los campos.';
            loginInfo.textContent = '';
            return;
        }

        // Timeout de seguridad: si Firebase no responde en 10s
        const timeoutId = setTimeout(() => {
            loginInfo.textContent = '';
            loginError.textContent = 'El login esta tardando demasiado. Prueba desactivar la prevencion de rastreo de Edge o usa Chrome.';
        }, 10000);

        try {
            await signInWithEmailAndPassword(auth, email, password);
            clearTimeout(timeoutId);
            loginInfo.textContent = '';
        } catch (error) {
            clearTimeout(timeoutId);
            console.error('Error login Firebase:', error.code, error.message);
            loginInfo.textContent = '';
            loginError.textContent = translateFirebaseError(error.code, error.message);
        }
    });

    // Register form
    registerForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        loginError.textContent = '';
        loginInfo.textContent = 'Creando cuenta...';

        const email = regEmailInput.value.trim();
        const password = regPasswordInput.value.trim();

        if (!email || !password) {
            loginError.textContent = 'Completa todos los campos.';
            loginInfo.textContent = '';
            return;
        }

        if (password.length < 6) {
            loginError.textContent = 'La contrasena debe tener al menos 6 caracteres.';
            loginInfo.textContent = '';
            return;
        }

        // Timeout de seguridad
        const timeoutId = setTimeout(() => {
            loginInfo.textContent = '';
            loginError.textContent = 'El registro esta tardando demasiado. Prueba desactivar la prevencion de rastreo de Edge o usa Chrome.';
        }, 10000);

        try {
            await createUserWithEmailAndPassword(auth, email, password);
            clearTimeout(timeoutId);
            loginInfo.textContent = '';
        } catch (error) {
            clearTimeout(timeoutId);
            console.error('Error registro Firebase:', error.code, error.message);
            loginInfo.textContent = '';
            loginError.textContent = translateFirebaseError(error.code, error.message);
        }
    });

    // Logout
    logoutBtn.addEventListener('click', async () => {
        try {
            await signOut(auth);
        } catch (error) {
            console.error('Error al cerrar sesion:', error);
        }
    });
}

// Traducir codigos de error de Firebase
function translateFirebaseError(code, message = '') {
    const errors = {
        'auth/invalid-email': 'Correo electronico invalido.',
        'auth/user-disabled': 'Esta cuenta ha sido deshabilitada.',
        'auth/user-not-found': 'No existe una cuenta con este correo.',
        'auth/wrong-password': 'Contrasena incorrecta.',
        'auth/email-already-in-use': 'Ya existe una cuenta con este correo.',
        'auth/weak-password': 'La contrasena es demasiado debil (min 6 caracteres).',
        'auth/invalid-credential': 'Credenciales invalidas. Verifica tu correo y contrasena.',
        'auth/too-many-requests': 'Demasiados intentos. Intenta mas tarde.',
        'auth/network-request-failed': 'Error de red. Verifica tu conexion.',
        'auth/api-key-not-valid': 'La API key de Firebase no es valida. Revisa la configuracion.',
    };
    return errors[code] || `Ocurrio un error (${code}): ${message || 'Intenta de nuevo.'}`;
}

// ============================================
// CONEXION WEBSOCKET
// ============================================

function connect() {
    if (!idToken) return;

    setConnectionState('reconnecting');

    const protocol = location.protocol === 'https:' ? 'wss:' : 'ws:';
    ws = new WebSocket(`${protocol}//${location.host}`);

    ws.onopen = () => {
        isConnected = true;
        setConnectionState('connected');

        // Enviar token JWT para autenticar la conexion
        ws.send(JSON.stringify({
            type: 'auth',
            token: idToken
        }));
    };

    ws.onmessage = (event) => {
        try {
            const msg = JSON.parse(event.data);
            handleMessage(msg);
        } catch (e) {
            console.error('Error parseando mensaje:', e);
        }
    };

    ws.onclose = async (event) => {
        isConnected = false;
        setConnectionState('disconnected');
        messageInput.disabled = true;
        sendBtn.disabled = true;

        // Si fue cerrado por auth invalida, no reconectar
        if (event.code === 4003 || event.code === 4002) {
            loginOverlay.classList.remove('hidden');
            logoutBtn.style.display = 'none';
            ws = null;
            // Forzar cierre de sesion en Firebase para evitar bucle
            try {
                await signOut(auth);
            } catch (e) {}
            loginError.textContent = 'Sesion invalida. Inicia sesion de nuevo.';
            return;
        }

        // Reconectar automaticamente
        clearTimeout(reconnectTimer);
        reconnectTimer = setTimeout(() => {
            if (idToken) {
                connect();
            }
        }, RECONNECT_DELAY);
        setConnectionState('reconnecting');
    };

    ws.onerror = (error) => {
        console.error('Error WebSocket:', error);
    };
}

// ============================================
// MANEJO DE MENSAJES RECIBIDOS
// ============================================

function handleMessage(msg) {
    switch (msg.type) {
        case 'authRequired':
            // El servidor pide autenticacion - ya enviamos el token en onopen
            break;

        case 'authSuccess':
            myUsername = msg.username;
            messageInput.disabled = false;
            sendBtn.disabled = false;
            messageInput.focus();
            break;

        case 'history':
            // Cargar mensajes del historial
            if (msg.messages && msg.messages.length > 0) {
                msg.messages.forEach((m) => addChatMessage(m, true));
            }
            break;

        case 'message':
            addChatMessage(msg);
            break;

        case 'system':
            addSystemMessage(msg);
            break;

        case 'userCount':
            userCountEl.textContent = msg.count;
            break;

        case 'typing':
            handleTyping(msg);
            break;

        case 'error':
            addErrorMessage(msg.text);
            break;
    }
}

// ============================================
// RENDERIZAR MENSAJES
// ============================================

function addChatMessage(msg, isHistory = false) {
    const isOwn = msg.username === myUsername;
    const bubble = document.createElement('div');
    bubble.className = 'message-bubble ' + (isOwn ? 'message-sent' : 'message-received');

    if (isHistory) {
        bubble.style.opacity = '0.7';
    }

    const safeUsername = escapeHtml(msg.username);
    const safeText = escapeHtml(msg.text);

    bubble.innerHTML = `
        <span class="msg-username" style="color: ${msg.color || 'var(--color-verde-primario)'}">${safeUsername}</span>
        <span class="msg-text">${safeText}</span>
        <span class="msg-timestamp">${msg.timestamp || ''}</span>
    `;

    messagesList.appendChild(bubble);
    scrollToBottom();
}

function addSystemMessage(msg) {
    const sysDiv = document.createElement('div');
    sysDiv.className = 'message-system ' + (msg.subtype || '');

    const icon = msg.subtype === 'join'
        ? '<span class="sys-icon">&#10148;</span>'
        : msg.subtype === 'leave'
        ? '<span class="sys-icon">&#10006;</span>'
        : '<span class="sys-icon">&#9998;</span>';

    sysDiv.innerHTML = `${icon} ${escapeHtml(msg.text)} <span class="msg-timestamp">${msg.timestamp || ''}</span>`;

    messagesList.appendChild(sysDiv);
    scrollToBottom();
}

function addErrorMessage(text) {
    const errDiv = document.createElement('div');
    errDiv.className = 'message-error';
    errDiv.textContent = text;
    messagesList.appendChild(errDiv);
    scrollToBottom();
    setTimeout(() => errDiv.remove(), 3000);
}

// ============================================
// INDICADOR "ESCRIBIENDO..."
// ============================================

function handleTyping(msg) {
    if (msg.username === myUsername) return;

    if (msg.isTyping) {
        typingUsers.add(msg.username);
    } else {
        typingUsers.delete(msg.username);
    }

    updateTypingIndicator();
}

function updateTypingIndicator() {
    if (typingUsers.size === 0) {
        typingIndicator.style.display = 'none';
    } else {
        const names = Array.from(typingUsers);
        if (names.length === 1) {
            typingText.textContent = `${names[0]} esta escribiendo`;
        } else if (names.length === 2) {
            typingText.textContent = `${names[0]} y ${names[1]} estan escribiendo`;
        } else {
            typingText.textContent = `${names.length} personas estan escribiendo`;
        }
        typingIndicator.style.display = 'flex';
    }
    scrollToBottom();
}

// ============================================
// ENVIO DE MENSAJES
// ============================================

function sendMessage() {
    const text = messageInput.value.trim();

    if (!text) return;

    if (text.length > MAX_MESSAGE_LENGTH) {
        addErrorMessage(`El mensaje es demasiado largo (maximo ${MAX_MESSAGE_LENGTH} caracteres).`);
        return;
    }

    if (!isConnected || !ws || ws.readyState !== WebSocket.OPEN) {
        addErrorMessage('No hay conexion al servidor.');
        return;
    }

    ws.send(JSON.stringify({
        type: 'message',
        text: text
    }));

    messageInput.value = '';
    stopTyping();
}

sendBtn.addEventListener('click', sendMessage);

// ============================================
// TYPING - DETECCION DE ESCRITURA
// ============================================

messageInput.addEventListener('input', () => {
    if (!isConnected || !ws || ws.readyState !== WebSocket.OPEN) return;
    if (!myUsername) return;

    if (!isTypingSent) {
        ws.send(JSON.stringify({
            type: 'typing',
            isTyping: true
        }));
        isTypingSent = true;
    }

    clearTimeout(typingTimer);
    typingTimer = setTimeout(stopTyping, TYPING_TIMEOUT);
});

function stopTyping() {
    clearTimeout(typingTimer);
    if (isTypingSent && ws && ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({
            type: 'typing',
            isTyping: false
        }));
    }
    isTypingSent = false;
}

messageInput.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') {
        sendMessage();
    }
});

// ============================================
// UTILIDADES
// ============================================

function scrollToBottom() {
    requestAnimationFrame(() => {
        messagesArea.scrollTop = messagesArea.scrollHeight;
    });
}

function escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
}

// ============================================
// INICIALIZACION
// ============================================

initTheme();
initAuth();
