import { useNavigate } from 'react-router-dom'
import { Settings, LogOut } from 'lucide-react'
import { useAuth } from '../../context/AuthContext'
import Queue from '../Queue/Queue'

/**
 * Full-screen offline-booking desk — the focused view a booking_staff user lands
 * on after login. No admin sidebar; a minimal top bar plus the existing Queue
 * panel (new booking / call-next / hold / served), locked to the desk's hospital
 * via useAuth().hospitalId inside Queue. Reuses Queue.jsx wholesale so there's a
 * single source of booking/queue logic — mirroring ReceptionDesk → Reception.
 */
export default function BookingDesk() {
  const { user, role, signOut } = useAuth()
  const navigate = useNavigate()

  const handleSignOut = async () => {
    await signOut()
    navigate('/booking/login')
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
              Offline Booking Desk
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

      <main className="px-4 md:px-8 py-6 max-w-6xl mx-auto">
        <Queue />
      </main>
    </div>
  )
}
