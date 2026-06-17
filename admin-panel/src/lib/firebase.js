import { initializeApp } from 'firebase/app'
import { getAuth, connectAuthEmulator } from 'firebase/auth'
import { getFirestore, connectFirestoreEmulator } from 'firebase/firestore'
import { getStorage } from 'firebase/storage'

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
}

const app = initializeApp(firebaseConfig)
export const auth = getAuth(app)
export const db = getFirestore(app)
export const storage = getStorage(app)

// Route Auth + Firestore to the local Firebase emulators when
// VITE_USE_EMULATOR=true (set in .env.local). Lets us develop against the
// emulator suite while the production project is over quota; set the flag back
// to false to use production. Must run before any auth/firestore call, so it
// lives here at module load. Storage stays on production config (unused at
// runtime — photos are inlined as base64 data-URLs, see api/storage.js).
export const USE_EMULATOR = import.meta.env.VITE_USE_EMULATOR === 'true'
if (USE_EMULATOR) {
  connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true })
  connectFirestoreEmulator(db, '127.0.0.1', 8020)
}

export default app
