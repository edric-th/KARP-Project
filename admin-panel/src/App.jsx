import { Routes, Route, Navigate } from 'react-router-dom'
import { useAuth } from './context/AuthContext'
import Layout from './components/layout/Layout'
import Login from './pages/Login/Login'
import Dashboard from './pages/Dashboard/Dashboard'
import Queue from './pages/Queue/Queue'
import Doctors from './pages/Doctors/Doctors'
import Hospitals from './pages/Hospitals/Hospitals'
import Bookings from './pages/Bookings/Bookings'
import Board from './pages/Board/Board'

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
      <Route path="/board/:doctorId" element={<Board />} />
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
