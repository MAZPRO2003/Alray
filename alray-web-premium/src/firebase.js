import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";

// Alray Prod Firebase Configuration
const firebaseConfig = {
    apiKey: "AIzaSyAvBdKQdbAucMcJBRzOwHzQYt_DzwHUaxI",
    authDomain: "alray-prod.firebaseapp.com",
    projectId: "alray-prod",
    storageBucket: "alray-prod.firebasestorage.app",
    messagingSenderId: "775183573814",
    appId: "1:775183573814:web:7cf579945f64a578a2c997" // Adjusted to 'web' type as per standard patterns
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
export const auth = getAuth(app);
