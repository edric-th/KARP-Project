import { useNavigate } from 'react-router-dom'
import { Settings, LogOut } from 'lucide-react'
import { useAuth } from '../../context/AuthContext'
import Reception from '../Reception/Reception'

/**
 * Full-screen reception desk — the focused view a receptionist lands on after
 * login. No admin sidebar; just a minimal top bar plus the existing Reception
 * panel (call-next / no-show / recall, locked to the receptionist's hospital).
 * Reuses Reception.jsx wholesale so there's a single source of desk logic.
 */
export default function ReceptionDesk() {
  const { user, role, signOut } = useAuth()
  const navigate = useNavigate()

  const handleSignOut = async () => {
    await signOut()
    navigate('/reception/login')
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white border-b border-gray-200 px-4 md:px-8 py-4 flex items-center justify-between flex-wrap gap-3">
        <div className="flex items-center gap-3 min-w-0">
          <img
            src="/mero-palo-logo.jpeg"
            alt="Meroपालो"
            className="w-10 h-10 object-contain rounded flex-shrink-0"
          />
          <div className="min-w-0">
            <h1 className="font-bold text-lg md:text-xl truncate text-gray-900">
              Reception Desk
            </h1>
            <p className="text-gray-500 text-xs md:text-sm truncate">
              {user?.email}
              {role ? ` · ${role}` : ''}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <button
            onClick={() => navigate('/account-settings')}
            className="p-2 hover:bg-gray-100 rounded-lg text-gray-500 hover:text-gray-800 transition"
            title="Account settings"
          >
            <Settings size={20} />
          </button>
          <button
            onClick={handleSignOut}
            className="p-2 hover:bg-gray-100 rounded-lg text-gray-500 hover:text-red-600 transition"
            title="Sign out"
          >
            <LogOut size={20} />
          </button>
        </div>
      </header>

      <main className="px-4 md:px-8 py-6 max-w-4xl mx-auto">
        <Reception />
      </main>
    </div>
  )
}
