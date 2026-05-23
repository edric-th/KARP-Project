import { createContext, useContext, useEffect, useState } from 'react'
import { onAuthStateChanged, signOut as fbSignOut } from 'firebase/auth'
import { doc, getDoc } from 'firebase/firestore'
import { auth, db } from '../lib/firebase'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null)
  const [role, setRole] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    console.log('[AUTH DEBUG] AuthProvider mounted, setting up listener')
    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
      console.log('[AUTH DEBUG] onAuthStateChanged fired')
      console.log('[AUTH DEBUG] firebaseUser:', firebaseUser)

      if (firebaseUser) {
        console.log('[AUTH DEBUG] User logged in:', firebaseUser.email, 'UID:', firebaseUser.uid)
        try {
          console.log('[AUTH DEBUG] Fetching users document...')
          const userDoc = await getDoc(doc(db, 'users', firebaseUser.uid))
          console.log('[AUTH DEBUG] userDoc.exists():', userDoc.exists())

          const userData = userDoc.exists() ? userDoc.data() : null
          console.log('[AUTH DEBUG] userData:', userData)
          console.log('[AUTH DEBUG] role field:', userData?.role)
          console.log('[AUTH DEBUG] role type:', typeof userData?.role)

          if (userData && ['admin', 'receptionist', 'doctor'].includes(userData.role)) {
            console.log('[AUTH DEBUG] ✅ Role accepted:', userData.role)
            setUser(firebaseUser)
            setRole(userData.role)
          } else {
            console.log('[AUTH DEBUG] ❌ Role rejected. Signing out.')
            console.log('[AUTH DEBUG] Reason: userData=', userData, 'role=', userData?.role)
            await fbSignOut(auth)
            setUser(null)
            setRole(null)
          }
        } catch (err) {
          console.log('[AUTH DEBUG] ❌ ERROR caught:', err.code, err.message)
          console.error('Auth role check failed:', err)
          setUser(null)
        }
      } else {
        console.log('[AUTH DEBUG] No user (logged out)')
        setUser(null)
        setRole(null)
      }
      setLoading(false)
      console.log('[AUTH DEBUG] setLoading(false) — auth check done')
    })
    return unsubscribe
  }, [])

  const signOut = () => fbSignOut(auth)

  return (
    <AuthContext.Provider value={{ user, role, loading, signOut }}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => useContext(AuthContext)