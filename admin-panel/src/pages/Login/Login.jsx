import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  signInWithEmailAndPassword,
  sendPasswordResetEmail,
} from 'firebase/auth'
import { ShieldCheck } from 'lucide-react'
import { auth } from '../../lib/firebase'
import { useAuth } from '../../context/AuthContext'
import AuthShell from '../../components/ui/AuthShell'
import toast from 'react-hot-toast'

export default function Login() {
  const navigate = useNavigate()
  const { user, role, loading: authLoading } = useAuth()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [showForgot, setShowForgot] = useState(false)

  // Redirect only once the auth context has fully resolved a logged-in user AND
  // their role. Navigating here — instead of right after signIn — avoids the race
  // where we'd redirect before onAuthStateChanged had loaded the role doc, which
  // sent the user through a protected route with stale (null) auth and bounced
  // them back to /login, forcing a second email/password entry.
  useEffect(() => {
    if (authLoading || !user || !role) return
    // Route everyone through "/" and let HomeRedirect send each role to its home
    // (admin → dashboard, doctor → doctor-queue, receptionist → reception-desk).
    navigate('/', { replace: true })
  }, [authLoading, user, role, navigate])

  const handleSubmit = async (e) => {
    e.preventDefault()
    setLoading(true)
    try {
      await signInWithEmailAndPassword(auth, email, password)
      // On success, the effect above redirects once the role resolves. Keep the
      // button busy until then; the auth context's `loading` covers that window.
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

  // While signing in or while the auth context is resolving a just-authenticated
  // user's role, keep the submit button busy.
  const busy = loading || (!!user && authLoading)

  return (
    <AuthShell
      title="Admin Panel"
      subtitle="Hospital Queue Management"
      icon={ShieldCheck}
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
              placeholder="admin@hospital.com"
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
