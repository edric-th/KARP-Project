import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  signInWithEmailAndPassword,
  sendPasswordResetEmail,
} from 'firebase/auth'
import { auth } from '../../lib/firebase'
import toast from 'react-hot-toast'

export default function Login() {
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [showForgot, setShowForgot] = useState(false)

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

          <button type="submit" disabled={loading} className="btn-primary w-full">
            {loading ? 'Signing in...' : 'Sign in'}
          </button>
        </form>
      </div>
    </div>
  )
}