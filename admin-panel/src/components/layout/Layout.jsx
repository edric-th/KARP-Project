import { Outlet, NavLink, useNavigate } from 'react-router-dom'
import {
  LayoutDashboard,
  Users,
  Building2,
  Calendar,
  ListOrdered,
  LogOut,
  Settings,
} from 'lucide-react'
import { useAuth } from '../../context/AuthContext'

const navItems = [
  { to: '/dashboard', icon: LayoutDashboard, label: 'Dashboard', end: true },
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
          <div className="flex flex-col gap-2">
            <NavLink
              to="/account-settings"
              className="flex items-center gap-2 text-sm text-gray-700 hover:text-primary-600"
            >
              <Settings size={16} /> Account settings
            </NavLink>
            <button
              onClick={handleSignOut}
              className="flex items-center gap-2 text-sm text-gray-700 hover:text-red-600"
            >
              <LogOut size={16} /> Sign out
            </button>
          </div>
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