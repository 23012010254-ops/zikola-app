import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';
import { getAuth, GoogleAuthProvider } from 'firebase/auth';

const firebaseConfig = {
  apiKey: "AIzaSyBY9km5-ttCNxABx-K_1bR0N_Nhp2wh2CM",
  appId: "1:510792598386:web:1ede3f867ac7d1365c93eb",
  messagingSenderId: "510792598386",
  projectId: "anak-app",
  authDomain: "anak-app.firebaseapp.com",
  storageBucket: "anak-app.firebasestorage.app",
  measurementId: "G-1YDQHHT6T3"
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
export const auth = getAuth(app);
export const googleProvider = new GoogleAuthProvider();
