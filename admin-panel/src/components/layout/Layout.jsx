import { Outlet, NavLink, useNavigate } from 'react-router-dom'
import { motion } from 'framer-motion'
import {
  LayoutDashboard,
  Users,
  UserCog,
  Building2,
  Calendar,
  ListOrdered,
  Ticket,
  CalendarPlus,
  LogOut,
  Settings,
} from 'lucide-react'
import { useAuth } from '../../context/AuthContext'

const navItems = [
  { to: '/dashboard', icon: LayoutDashboard, label: 'Dashboard', end: true },
  { to: '/queue', icon: ListOrdered, label: 'Live Queue' },
  { to: '/reception', icon: Ticket, label: 'Reception' },
  { to: '/booking-staff', icon: CalendarPlus, label: 'Booking Desks' },
  { to: '/bookings', icon: Calendar, label: 'Bookings' },
  { to: '/doctors', icon: Users, label: 'Doctors' },
  { to: '/staff', icon: UserCog, label: 'Staff' },
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
    <div className="min-h-screen flex bg-gray-50">
      <aside className="w-64 bg-white border-r border-gray-200 flex flex-col">
        <div className="p-4 border-b border-gray-100">
          <div className="flex items-center gap-3 rounded-2xl bg-gradient-to-br from-primary-600 to-accent-700 p-3 text-white shadow-glow">
            <img
              src="/mero-palo-logo.jpeg"
              alt="Meroपालो"
              className="w-10 h-10 object-contain rounded-lg bg-white/90 p-0.5 flex-shrink-0"
            />
            <div className="min-w-0">
              <h1 className="font-bold text-lg leading-tight">Meroपालो</h1>
              <p className="text-xs text-white/80">Admin Panel</p>
            </div>
          </div>
        </div>
        <nav className="flex-1 p-3 space-y-1 overflow-y-auto">
          {navItems.map(({ to, icon: Icon, label, end }) => (
            <NavLink
              key={to}
              to={to}
              end={end}
              className={({ isActive }) =>
                `relative flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition ${
                  isActive
                    ? 'text-primary-700'
                    : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'
                }`
              }
            >
              {({ isActive }) => (
                <>
                  {isActive && (
                    <motion.span
                      layoutId="nav-active"
                      className="absolute inset-0 rounded-xl bg-primary-50 border border-primary-100"
                      transition={{ type: 'spring', stiffness: 500, damping: 40 }}
                    />
                  )}
                  <Icon size={18} className="relative z-10" />
                  <span className="relative z-10">{label}</span>
                </>
              )}
            </NavLink>
          ))}
        </nav>
        <div className="p-4 border-t border-gray-100">
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
