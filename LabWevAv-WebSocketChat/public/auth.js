/* ============================================
   AUTH.JS - Autenticacion con Firebase Auth
   ============================================ */

// Importar Firebase via CDN (ES modules)
import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-app.js';
import {
  getAuth,
  setPersistence,
  browserSessionPersistence,
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  signOut,
  onAuthStateChanged
} from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-auth.js';

// Firebase config (hardcodeada - estas claves son publicas y seguras)
const firebaseConfig = {
  apiKey: 'AIzaSyB7LQiK7eAzyEp_tkUIouBeAp2Eo4n3K2I',
  authDomain: 'chatauth-2ab01.firebaseapp.com',
  projectId: 'chatauth-2ab01',
  storageBucket: 'chatauth-2ab01.firebasestorage.app',
  messagingSenderId: '252978820296',
  appId: '1:252978820296:web:79ba0e66727e3c147021fd',
};

// Inicializar Firebase
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);

// Usar persistencia de sesion (mejor para modo incognito)
setPersistence(auth, browserSessionPersistence).catch((err) => {
  console.warn('No se pudo configurar persistencia de sesion:', err);
});

// ============================================
// EXPORTAR PARA USO GLOBAL
// ============================================
window.firebaseAuth = {
  auth,
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  signOut,
  onAuthStateChanged
};
