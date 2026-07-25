import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  signInWithEmailAndPassword,
  sendPasswordResetEmail,
} from 'firebase/auth'
import { Ticket } from 'lucide-react'
import { auth } from '../../lib/firebase'
import { useAuth } from '../../context/AuthContext'
import AuthShell from '../../components/ui/AuthShell'
import toast from 'react-hot-toast'

/**
 * Dedicated reception-desk login. Functionally the same as the admin login but
 * branded for reception staff and routing a receptionist straight to their
 * focused desk (/reception-desk) instead of the admin panel. Other roles that
 * happen to use this door are still routed to their correct home.
 */
export default function ReceptionLogin() {
  const navigate = useNavigate()
  const { user, role, loading: authLoading } = useAuth()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [showForgot, setShowForgot] = useState(false)

  // Redirect once auth fully resolves the role (avoids the stale-auth bounce).
  useEffect(() => {
    if (authLoading || !user || !role) return
    if (role === 'receptionist') {
      navigate('/reception-desk', { replace: true })
    } else {
      navigate(role === 'doctor' ? '/doctor-queue' : '/', { replace: true })
    }
  }, [authLoading, user, role, navigate])

  const handleSubmit = async (e) => {
    e.preventDefault()
    setLoading(true)
    try {
      await signInWithEmailAndPassword(auth, email, password)
    } catch (err) {
      toast.error('Invalid credentials')
      console.error(err)
    } finally {
      setLoading(false)
    }
  }

  const handleForgotPassword = async () => {
    if (!email.trim()) {
      toast.error('Please enter your email first')
      return
    }
    setLoading(true)
    try {
      await sendPasswordResetEmail(auth, email.trim())
      toast.success(`Reset email sent to ${email}`)
      setShowForgot(false)
    } catch (err) {
      console.error(err)
      if (err.code === 'auth/user-not-found') {
        toast.error('No account found for this email')
      } else if (err.code === 'auth/invalid-email') {
        toast.error('Invalid email format')
      } else {
        toast.error('Failed to send reset email')
      }
    } finally {
      setLoading(false)
    }
  }

  const busy = loading || (!!user && authLoading)

  return (
    <AuthShell
      title="Reception Desk"
      subtitle="Sign in to manage the token queue"
      icon={Ticket}
    >
      <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1">Email</label>
            <input
              type="email"
              required
              className="input"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="reception@hospital.com"
            />
          </div>
          <div>
            <div className="flex items-center justify-between mb-1">
              <label className="block text-sm font-medium">Password</label>
              <button
                type="button"
                onClick={() => setShowForgot(!showForgot)}
                className="text-xs text-primary-600 hover:underline"
              >
                Forgot password?
              </button>
            </div>
            <input
              type="password"
              required
              className="input"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
          </div>

          {showForgot && (
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-3 text-sm">
              <p className="text-blue-900 mb-2">
                Enter your email above, then click below to receive a password reset link.
              </p>
              <button
                type="button"
                onClick={handleForgotPassword}
                disabled={loading}
                className="text-sm bg-blue-600 hover:bg-blue-700 text-white px-3 py-1.5 rounded-lg font-medium"
              >
                {loading ? 'Sending...' : 'Send reset email'}
              </button>
            </div>
          )}

          <button type="submit" disabled={busy} className="btn-primary w-full">
            {busy ? 'Signing in...' : 'Sign in'}
          </button>
        </form>
    </AuthShell>
  )
}
