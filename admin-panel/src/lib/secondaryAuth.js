import { initializeApp, getApps } from 'firebase/app'
import {
  initializeAuth,
  inMemoryPersistence,
  connectAuthEmulator,
} from 'firebase/auth'
import { USE_EMULATOR } from './firebase'

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
}

/**
 * A throwaway secondary Firebase Auth instance with in-memory persistence, used
 * to create staff login accounts (doctors, receptionists) WITHOUT signing the
 * admin out of their own session. Sign out of this instance after creating the
 * account. Shared by the Doctors and Staff pages so the wiring stays in one place.
 */
export const getSecondaryAuth = () => {
  const apps = getApps()
  let secondaryApp = apps.find((a) => a.name === 'secondary')
  if (!secondaryApp) {
    secondaryApp = initializeApp(firebaseConfig, 'secondary')
  }
  const secondaryAuth = initializeAuth(secondaryApp, {
    persistence: inMemoryPersistence,
  })
  // The secondary app is separate, so it needs its own emulator wiring.
  if (USE_EMULATOR) {
    connectAuthEmulator(secondaryAuth, 'http://127.0.0.1:9099', {
      disableWarnings: true,
    })
  }
  return secondaryAuth
}
