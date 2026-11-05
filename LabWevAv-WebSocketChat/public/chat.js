/* ============================================
   CHAT.JS - Logica del cliente WebSocket
   ============================================ */

// --- Limites ---
const MAX_MESSAGE_LENGTH = 500;
const MAX_USERNAME_LENGTH = 20;
const RECONNECT_DELAY = 3000;
const TYPING_TIMEOUT = 3000;

// --- Estado global ---
let ws = null;
let myUsername = '';
let isConnected = false;
let reconnectTimer = null;
let typingTimer = null;
let isTypingSent = false;
let typingUsers = new Set();

// --- Referencias del DOM ---
const messagesArea = document.getElementById('messagesArea');
const messagesList = document.getElementById('messagesList');
const messageInput = document.getElementById('messageInput');
const sendBtn = document.getElementById('sendBtn');
const usernameInput = document.getElementById('usernameInput');
const joinBtn = document.getElementById('joinBtn');
const loginOverlay = document.getElementById('loginOverlay');
const loginError = document.getElementById('loginError');
const statusDot = document.getElementById('statusDot');
const statusText = document.getElementById('statusText');
const userCountEl = document.getElementById('userCount');
const themeToggle = document.getElementById('themeToggle');
const typingIndicator = document.getElementById('typingIndicator');
const typingText = document.getElementById('typingText');

// ============================================
// TEMA CLARO / OSCURO
// ============================================

function initTheme() {
    const savedTheme = localStorage.getItem('chat-theme');
    if (savedTheme === 'dark') {
        document.documentElement.setAttribute('data-theme', 'dark');
    } else {
        document.documentElement.setAttribute('data-theme', 'light');
    }
}

function toggleTheme() {
    const current = document.documentElement.getAttribute('data-theme');
    const next = current === 'dark' ? 'light' : 'dark';
    document.documentElement.setAttribute('data-theme', next);
    localStorage.setItem('chat-theme', next);
}

themeToggle.addEventListener('click', toggleTheme);

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
// LOGIN / JOIN
// ============================================

function handleJoin() {
    const username = usernameInput.value.trim();

    if (!username) {
        loginError.textContent = 'Por favor ingresa tu nombre.';
        usernameInput.focus();
        return;
    }

    if (username.length > MAX_USERNAME_LENGTH) {
        loginError.textContent = `Maximo ${MAX_USERNAME_LENGTH} caracteres.`;
        return;
    }

    myUsername = username;

    if (isConnected && ws && ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({
            type: 'join',
            username: myUsername
        }));
    }

    loginOverlay.classList.add('hidden');
    messageInput.disabled = false;
    sendBtn.disabled = false;
    messageInput.focus();
}

joinBtn.addEventListener('click', handleJoin);

usernameInput.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') {
        handleJoin();
    }
});

// ============================================
// CONEXION WEBSOCKET
// ============================================

function connect() {
    setConnectionState('reconnecting');

    const protocol = location.protocol === 'https:' ? 'wss:' : 'ws:';
    ws = new WebSocket(`${protocol}//${location.host}`);

    ws.onopen = () => {
        isConnected = true;
        setConnectionState('connected');

        // Si ya tenemos username, re-enviar join
        if (myUsername) {
            ws.send(JSON.stringify({
                type: 'join',
                username: myUsername
            }));
        }
    };

    ws.onmessage = (event) => {
        try {
            const msg = JSON.parse(event.data);
            handleMessage(msg);
        } catch (e) {
            console.error('Error parseando mensaje:', e);
        }
    };

    ws.onclose = () => {
        isConnected = false;
        setConnectionState('disconnected');
        messageInput.disabled = true;
        sendBtn.disabled = true;

        // Reconectar automaticamente
        clearTimeout(reconnectTimer);
        reconnectTimer = setTimeout(connect, RECONNECT_DELAY);
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

function addChatMessage(msg) {
    const isOwn = msg.username === myUsername;
    const bubble = document.createElement('div');
    bubble.className = 'message-bubble ' + (isOwn ? 'message-sent' : 'message-received');

    // Escapar HTML para prevenir XSS
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
        : '<span class="sys-icon">&#10006;</span>';

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

    // Remover despues de 3 segundos
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

    // Validar mensaje vacio
    if (!text) {
        return;
    }

    // Validar mensaje demasiado largo
    if (text.length > MAX_MESSAGE_LENGTH) {
        addErrorMessage(`El mensaje es demasiado largo (maximo ${MAX_MESSAGE_LENGTH} caracteres).`);
        return;
    }

    if (!isConnected || !ws || ws.readyState !== WebSocket.OPEN) {
        addErrorMessage('No hay conexion al servidor.');
        return;
    }

    // Enviar como JSON
    ws.send(JSON.stringify({
        type: 'message',
        text: text
    }));

    // Limpiar input y detener indicador typing
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

    // Si no hemos enviado "typing", enviarlo
    if (!isTypingSent) {
        ws.send(JSON.stringify({
            type: 'typing',
            isTyping: true
        }));
        isTypingSent = true;
    }

    // Reiniciar timer: si deja de escribir por 3s, enviar "stop typing"
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

// Enter para enviar
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
connect();
usernameInput.focus();
