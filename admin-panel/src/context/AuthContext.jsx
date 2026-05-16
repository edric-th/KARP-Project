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
    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
      if (firebaseUser) {
        try {
          const userDoc = await getDoc(doc(db, 'users', firebaseUser.uid))
          const userData = userDoc.exists() ? userDoc.data() : null
          if (userData && ['admin', 'receptionist'].includes(userData.role)) {
            setUser(firebaseUser)
            setRole(userData.role)
          } else {
            await fbSignOut(auth)
            setUser(null)
            setRole(null)
          }
        } catch (err) {
          console.error('Auth role check failed:', err)
          setUser(null)
        }
      } else {
        setUser(null)
        setRole(null)
      }
      setLoading(false)
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
