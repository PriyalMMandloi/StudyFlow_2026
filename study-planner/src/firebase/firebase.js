import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

// 🔥 YOUR CONFIG (same as yours)
const firebaseConfig = {
  apiKey: "AIzaSyDIKbA9IKN_9cQZuY9qQAIobPGQuHFK7ls",
  authDomain: "studyflow-4290e.firebaseapp.com",
  projectId: "studyflow-4290e",
  storageBucket: "studyflow-4290e.firebasestorage.app",
  messagingSenderId: "777579005121",
  appId: "1:777579005121:web:2e3e4dda777af300bfc040"
};

// 🔥 INITIALIZE
const app = initializeApp(firebaseConfig);

// 🔥 EXPORT (IMPORTANT)
export const auth = getAuth(app);
export const db = getFirestore(app);
