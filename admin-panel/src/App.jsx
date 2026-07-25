import { Routes, Route, Navigate } from 'react-router-dom'
import { useAuth } from './context/AuthContext'
import Layout from './components/layout/Layout'
import Login from './pages/Login/Login'
import ReceptionLogin from './pages/ReceptionLogin/ReceptionLogin'
import ReceptionDesk from './pages/ReceptionDesk/ReceptionDesk'
import BookingLogin from './pages/BookingLogin/BookingLogin'
import BookingDesk from './pages/BookingDesk/BookingDesk'
import BookingStaff from './pages/BookingStaff/BookingStaff'
import Dashboard from './pages/Dashboard/Dashboard'
import Queue from './pages/Queue/Queue'
import Reception from './pages/Reception/Reception'
import Staff from './pages/Staff/Staff'
import Doctors from './pages/Doctors/Doctors'
import Hospitals from './pages/Hospitals/Hospitals'
import Bookings from './pages/Bookings/Bookings'
import Board from './pages/Board/Board'
import DoctorQueue from './pages/DoctorQueue/DoctorQueue'
import AccountSettings from './pages/AccountSettings/AccountSettings'

function ProtectedRoute({ children, allowedRoles }) {
  const { user, role, loading } = useAuth()
  if (loading) return <div className="flex items-center justify-center h-screen">Loading...</div>
  if (!user) return <Navigate to="/login" replace />

  if (allowedRoles && !allowedRoles.includes(role)) {
    if (role === 'doctor') return <Navigate to="/doctor-queue" replace />
    return <Navigate to="/" replace />
  }

  return children
}

function HomeRedirect() {
  const { role, loading } = useAuth()
  if (loading) return <div className="flex items-center justify-center h-screen">Loading...</div>
  if (role === 'doctor') return <Navigate to="/doctor-queue" replace />
  if (role === 'receptionist') return <Navigate to="/reception-desk" replace />
  if (role === 'booking_staff') return <Navigate to="/booking-desk" replace />
  return <Navigate to="/dashboard" replace />
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route path="/reception/login" element={<ReceptionLogin />} />
      <Route path="/booking/login" element={<BookingLogin />} />
      <Route path="/board/:doctorId" element={<Board />} />

      {/* Account settings - accessible to any logged-in user */}
      <Route
        path="/account-settings"
        element={
          <ProtectedRoute>
            <AccountSettings />
          </ProtectedRoute>
        }
      />

      {/* Doctor-only route */}
      <Route
        path="/doctor-queue"
        element={
          <ProtectedRoute allowedRoles={['doctor']}>
            <DoctorQueue />
          </ProtectedRoute>
        }
      />

      {/* Receptionist focused desk — full screen, no admin sidebar */}
      <Route
        path="/reception-desk"
        element={
          <ProtectedRoute allowedRoles={['receptionist', 'admin']}>
            <ReceptionDesk />
          </ProtectedRoute>
        }
      />

      {/* Offline-booking desk — full screen, hospital-scoped doctor booking */}
      <Route
        path="/booking-desk"
        element={
          <ProtectedRoute allowedRoles={['booking_staff', 'admin']}>
            <BookingDesk />
          </ProtectedRoute>
        }
      />

      {/* Admin-only routes with sidebar layout. Receptionists are kept out of
          the admin panel entirely — they're bounced to their focused desk. */}
      <Route
        path="/dashboard"
        element={
          <ProtectedRoute allowedRoles={['admin']}>
            <Layout />
          </ProtectedRoute>
        }
      >
        <Route index element={<Dashboard />} />
      </Route>

      <Route
        element={
          <ProtectedRoute allowedRoles={['admin']}>
            <Layout />
          </ProtectedRoute>
        }
      >
        <Route path="/queue" element={<Queue />} />
        <Route path="/reception" element={<Reception />} />
        <Route path="/staff" element={<Staff />} />
        <Route path="/booking-staff" element={<BookingStaff />} />
        <Route path="/doctors" element={<Doctors />} />
        <Route path="/hospitals" element={<Hospitals />} />
        <Route path="/bookings" element={<Bookings />} />
      </Route>

      <Route path="/" element={<HomeRedirect />} />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}