"""
Hospital Queue Admin Panel - Project Scaffold Generator
Run from inside the admin-panel/ folder: python3 setup.py
"""

import os
from pathlib import Path

# ---------- Folder structure ----------
FOLDERS = [
    "public",
    "src",
    "src/api",
    "src/auth",
    "src/components",
    "src/components/ui",
    "src/components/layout",
    "src/pages",
    "src/pages/Dashboard",
    "src/pages/Queue",
    "src/pages/Doctors",
    "src/pages/Hospitals",
    "src/pages/Bookings",
    "src/pages/Login",
    "src/hooks",
    "src/lib",
    "src/context",
    "src/constants",
    "src/assets",
]

# ---------- File contents ----------

PACKAGE_JSON = r'''{
  "name": "hospital-queue-admin",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "@tanstack/react-query": "^5.51.0",
    "axios": "^1.7.2",
    "firebase": "^10.12.4",
    "lucide-react": "^0.408.0",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "react-hot-toast": "^2.4.1",
    "react-router-dom": "^6.25.1"
  },
  "devDependencies": {
    "@types/react": "^18.3.3",
    "@types/react-dom": "^18.3.0",
    "@vitejs/plugin-react": "^4.3.1",
    "autoprefixer": "^10.4.19",
    "postcss": "^8.4.39",
    "tailwindcss": "^3.4.6",
    "vite": "^5.3.4"
  }
}
'''

VITE_CONFIG = r'''import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 5173,
    open: true,
  },
})
'''

INDEX_HTML = r'''<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Hospital Queue Admin</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
'''

TAILWIND_CONFIG = r'''/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,jsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#eff6ff',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
        },
      },
    },
  },
  plugins: [],
}
'''

POSTCSS_CONFIG = r'''export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
'''

INDEX_CSS = r'''@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  body {
    @apply bg-gray-50 text-gray-900 antialiased;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  }
}

@layer components {
  .btn-primary {
    @apply bg-primary-600 hover:bg-primary-700 text-white font-medium px-4 py-2 rounded-lg transition;
  }
  .btn-secondary {
    @apply bg-gray-200 hover:bg-gray-300 text-gray-800 font-medium px-4 py-2 rounded-lg transition;
  }
  .card {
    @apply bg-white rounded-xl shadow-sm border border-gray-200 p-6;
  }
  .input {
    @apply w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent outline-none;
  }
}
'''

MAIN_JSX = r'''import React from 'react'
import ReactDOM from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { Toaster } from 'react-hot-toast'
import { AuthProvider } from './context/AuthContext'
import App from './App'
import './index.css'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60,
      refetchOnWindowFocus: false,
    },
  },
})

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <BrowserRouter>
      <QueryClientProvider client={queryClient}>
        <AuthProvider>
          <App />
          <Toaster position="top-right" />
        </AuthProvider>
      </QueryClientProvider>
    </BrowserRouter>
  </React.StrictMode>,
)
'''

APP_JSX = r'''import { Routes, Route, Navigate } from 'react-router-dom'
import { useAuth } from './context/AuthContext'
import Layout from './components/layout/Layout'
import Login from './pages/Login/Login'
import Dashboard from './pages/Dashboard/Dashboard'
import Queue from './pages/Queue/Queue'
import Doctors from './pages/Doctors/Doctors'
import Hospitals from './pages/Hospitals/Hospitals'
import Bookings from './pages/Bookings/Bookings'

function ProtectedRoute({ children }) {
  const { user, loading } = useAuth()
  if (loading) return <div className="flex items-center justify-center h-screen">Loading...</div>
  if (!user) return <Navigate to="/login" replace />
  return children
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route path="/" element={<ProtectedRoute><Layout /></ProtectedRoute>}>
        <Route index element={<Dashboard />} />
        <Route path="queue" element={<Queue />} />
        <Route path="doctors" element={<Doctors />} />
        <Route path="hospitals" element={<Hospitals />} />
        <Route path="bookings" element={<Bookings />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}
'''

FIREBASE_CONFIG = r'''import { initializeApp } from 'firebase/app'
import { getAuth } from 'firebase/auth'
import { getFirestore } from 'firebase/firestore'
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
export default app
'''

AUTH_CONTEXT = r'''import { createContext, useContext, useEffect, useState } from 'react'
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
'''

LOGIN_PAGE = r'''import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { signInWithEmailAndPassword } from 'firebase/auth'
import { auth } from '../../lib/firebase'
import toast from 'react-hot-toast'

export default function Login() {
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e) => {
    e.preventDefault()
    setLoading(true)
    try {
      await signInWithEmailAndPassword(auth, email, password)
      toast.success('Welcome back')
      navigate('/')
    } catch (err) {
      toast.error('Invalid credentials')
      console.error(err)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center px-4">
      <div className="card w-full max-w-md">
        <h1 className="text-2xl font-bold mb-2">Admin Panel</h1>
        <p className="text-gray-600 mb-6">Hospital Queue Management</p>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1">Email</label>
            <input
              type="email"
              required
              className="input"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="admin@hospital.com"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Password</label>
            <input
              type="password"
              required
              className="input"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
          </div>
          <button type="submit" disabled={loading} className="btn-primary w-full">
            {loading ? 'Signing in...' : 'Sign in'}
          </button>
        </form>
      </div>
    </div>
  )
}
'''

LAYOUT = r'''import { Outlet, NavLink, useNavigate } from 'react-router-dom'
import { LayoutDashboard, Users, Building2, Calendar, ListOrdered, LogOut } from 'lucide-react'
import { useAuth } from '../../context/AuthContext'

const navItems = [
  { to: '/', icon: LayoutDashboard, label: 'Dashboard', end: true },
  { to: '/queue', icon: ListOrdered, label: 'Live Queue' },
  { to: '/bookings', icon: Calendar, label: 'Bookings' },
  { to: '/doctors', icon: Users, label: 'Doctors' },
  { to: '/hospitals', icon: Building2, label: 'Hospitals' },
]

export default function Layout() {
  const { user, role, signOut } = useAuth()
  const navigate = useNavigate()

  const handleSignOut = async () => {
    await signOut()
    navigate('/login')
  }

  return (
    <div className="min-h-screen flex">
      <aside className="w-64 bg-white border-r border-gray-200 flex flex-col">
        <div className="p-6 border-b border-gray-200">
          <h1 className="font-bold text-lg">Hospital Queue</h1>
          <p className="text-xs text-gray-500 mt-1">Admin Panel</p>
        </div>
        <nav className="flex-1 p-4 space-y-1">
          {navItems.map(({ to, icon: Icon, label, end }) => (
            <NavLink
              key={to}
              to={to}
              end={end}
              className={({ isActive }) =>
                `flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition ${
                  isActive ? 'bg-primary-50 text-primary-700' : 'text-gray-700 hover:bg-gray-100'
                }`
              }
            >
              <Icon size={18} />
              {label}
            </NavLink>
          ))}
        </nav>
        <div className="p-4 border-t border-gray-200">
          <p className="text-sm font-medium truncate">{user?.email}</p>
          <p className="text-xs text-gray-500 capitalize mb-3">{role}</p>
          <button onClick={handleSignOut} className="flex items-center gap-2 text-sm text-gray-700 hover:text-red-600">
            <LogOut size={16} /> Sign out
          </button>
        </div>
      </aside>
      <main className="flex-1 overflow-auto">
        <div className="p-8">
          <Outlet />
        </div>
      </main>
    </div>
  )
}
'''

DASHBOARD_PAGE = r'''export default function Dashboard() {
  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Dashboard</h1>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="card">
          <p className="text-sm text-gray-500">Today's bookings</p>
          <p className="text-3xl font-bold mt-2">0</p>
        </div>
        <div className="card">
          <p className="text-sm text-gray-500">Active queue</p>
          <p className="text-3xl font-bold mt-2">0</p>
        </div>
        <div className="card">
          <p className="text-sm text-gray-500">Avg wait time</p>
          <p className="text-3xl font-bold mt-2">-- min</p>
        </div>
      </div>
    </div>
  )
}
'''

QUEUE_PAGE = r'''export default function Queue() {
  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Live Queue</h1>
      <div className="card">
        <p className="text-gray-500">Queue management goes here.</p>
      </div>
    </div>
  )
}
'''

DOCTORS_PAGE = r'''export default function Doctors() {
  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Doctors</h1>
      <div className="card">
        <p className="text-gray-500">Doctor management goes here.</p>
      </div>
    </div>
  )
}
'''

HOSPITALS_PAGE = r'''export default function Hospitals() {
  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Hospitals</h1>
      <div className="card">
        <p className="text-gray-500">Hospital management goes here.</p>
      </div>
    </div>
  )
}
'''

BOOKINGS_PAGE = r'''export default function Bookings() {
  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Bookings</h1>
      <div className="card">
        <p className="text-gray-500">Booking management goes here.</p>
      </div>
    </div>
  )
}
'''

FIRESTORE_API = r'''import { collection, doc, getDocs, getDoc, addDoc, updateDoc, deleteDoc, query, where, orderBy, onSnapshot, serverTimestamp } from 'firebase/firestore'
import { db } from '../lib/firebase'

export const getAll = async (collectionName) => {
  const snap = await getDocs(collection(db, collectionName))
  return snap.docs.map(d => ({ id: d.id, ...d.data() }))
}

export const getById = async (collectionName, id) => {
  const snap = await getDoc(doc(db, collectionName, id))
  return snap.exists() ? { id: snap.id, ...snap.data() } : null
}

export const create = async (collectionName, data) => {
  const ref = await addDoc(collection(db, collectionName), {
    ...data,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  })
  return ref.id
}

export const update = async (collectionName, id, data) => {
  await updateDoc(doc(db, collectionName, id), {
    ...data,
    updatedAt: serverTimestamp(),
  })
}

export const remove = async (collectionName, id) => {
  await deleteDoc(doc(db, collectionName, id))
}

export const subscribe = (collectionName, callback, filters = []) => {
  let q = collection(db, collectionName)
  if (filters.length) q = query(q, ...filters)
  return onSnapshot(q, (snap) => {
    const items = snap.docs.map(d => ({ id: d.id, ...d.data() }))
    callback(items)
  })
}

export { where, orderBy, query }
'''

CONSTANTS = r'''export const COLLECTIONS = {
  USERS: 'users',
  HOSPITALS: 'hospitals',
  DOCTORS: 'doctors',
  BOOKINGS: 'bookings',
  QUEUES: 'queues',
}

export const BOOKING_TYPES = {
  FIRST_VISIT: 'first_visit',
  FOLLOW_UP: 'follow_up',
  REPORT: 'report',
}

export const BOOKING_STATUS = {
  PENDING: 'pending',
  ACTIVE: 'active',
  SERVED: 'served',
  CANCELLED: 'cancelled',
  NO_SHOW: 'no_show',
}

export const ROLES = {
  ADMIN: 'admin',
  RECEPTIONIST: 'receptionist',
  PATIENT: 'patient',
}
'''

ENV_EXAMPLE = r'''VITE_FIREBASE_API_KEY=your_api_key_here
VITE_FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=your_project_id
VITE_FIREBASE_STORAGE_BUCKET=your_project.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
VITE_FIREBASE_APP_ID=your_app_id
'''

GITIGNORE = r'''node_modules/
dist/
dist-ssr/
.env
.env.local
.env.*.local
*.log
.DS_Store
.vscode/
.idea/
'''

README = r'''# Hospital Queue - Admin Panel

React admin panel for managing the hospital queue system.

## Setup

1. Install dependencies: npm install
2. Copy .env.example to .env.local and fill in your Firebase config
3. Start dev server: npm run dev

## Project structure

- src/pages/ - Top-level route pages
- src/components/ - Reusable UI components
- src/components/layout/ - Layout shell (sidebar, etc.)
- src/context/ - React context (auth state)
- src/lib/ - Firebase initialization
- src/api/ - Firestore CRUD helpers
- src/hooks/ - Custom React hooks
- src/constants/ - Shared constants

## First-time admin setup

After signing in once with a new email, manually create a document in Firestore:
- Collection: users
- Document ID: your Firebase Auth UID
- Fields: email (string), role (string, set to "admin"), name (string)

The auth context blocks anyone without role admin or receptionist.
'''

# ---------- File map: path -> content ----------
FILES = {
    "package.json": PACKAGE_JSON,
    "vite.config.js": VITE_CONFIG,
    "index.html": INDEX_HTML,
    "tailwind.config.js": TAILWIND_CONFIG,
    "postcss.config.js": POSTCSS_CONFIG,
    ".env.example": ENV_EXAMPLE,
    ".gitignore": GITIGNORE,
    "README.md": README,
    "src/main.jsx": MAIN_JSX,
    "src/App.jsx": APP_JSX,
    "src/index.css": INDEX_CSS,
    "src/lib/firebase.js": FIREBASE_CONFIG,
    "src/context/AuthContext.jsx": AUTH_CONTEXT,
    "src/components/layout/Layout.jsx": LAYOUT,
    "src/pages/Login/Login.jsx": LOGIN_PAGE,
    "src/pages/Dashboard/Dashboard.jsx": DASHBOARD_PAGE,
    "src/pages/Queue/Queue.jsx": QUEUE_PAGE,
    "src/pages/Doctors/Doctors.jsx": DOCTORS_PAGE,
    "src/pages/Hospitals/Hospitals.jsx": HOSPITALS_PAGE,
    "src/pages/Bookings/Bookings.jsx": BOOKINGS_PAGE,
    "src/api/firestore.js": FIRESTORE_API,
    "src/constants/index.js": CONSTANTS,
}


def main():
    root = Path(".").resolve()
    print(f"Creating project in: {root}\n")

    for folder in FOLDERS:
        folder_path = root / folder
        folder_path.mkdir(parents=True, exist_ok=True)
        print(f"  [folder] {folder}")

    print()

    for file_path, content in FILES.items():
        full_path = root / file_path
        full_path.parent.mkdir(parents=True, exist_ok=True)
        if full_path.exists():
            print(f"  [skip]   {file_path} (already exists)")
            continue
        full_path.write_text(content, encoding="utf-8")
        print(f"  [file]   {file_path}")

    print("\n" + "=" * 60)
    print("Done! Next steps:")
    print("=" * 60)
    print("1. npm install")
    print("2. cp .env.example .env.local")
    print("3. Edit .env.local with your Firebase config")
    print("4. npm run dev")
    print("5. Open http://localhost:5173")
    print("=" * 60)


if __name__ == "__main__":
    main()