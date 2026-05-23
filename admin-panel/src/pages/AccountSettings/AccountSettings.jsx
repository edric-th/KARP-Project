import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  EmailAuthProvider,
  reauthenticateWithCredential,
  updatePassword,
  updateEmail,
} from 'firebase/auth'
import { doc, updateDoc } from 'firebase/firestore'
import { ArrowLeft, Mail, Lock, User, Eye, EyeOff, Save } from 'lucide-react'
import toast from 'react-hot-toast'
import { auth, db } from '../../lib/firebase'
import { useAuth } from '../../context/AuthContext'
import { COLLECTIONS } from '../../constants'

export default function AccountSettings() {
  const { user, role } = useAuth()
  const navigate = useNavigate()

  const [currentPassword, setCurrentPassword] = useState('')
  const [newEmail, setNewEmail] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [showCurrent, setShowCurrent] = useState(false)
  const [showNew, setShowNew] = useState(false)
  const [saving, setSaving] = useState(false)
  const [activeTab, setActiveTab] = useState('password')

  const reauthenticate = async () => {
    const credential = EmailAuthProvider.credential(user.email, currentPassword)
    await reauthenticateWithCredential(user, credential)
  }

  const handleChangePassword = async (e) => {
    e.preventDefault()
    if (newPassword.length < 6) {
      toast.error('New password must be at least 6 characters')
      return
    }
    if (newPassword !== confirmPassword) {
      toast.error('New passwords do not match')
      return
    }
    setSaving(true)
    try {
      await reauthenticate()
      await updatePassword(user, newPassword)
      toast.success('Password updated successfully')
      setCurrentPassword('')
      setNewPassword('')
      setConfirmPassword('')
    } catch (err) {
      console.error(err)
      if (err.code === 'auth/wrong-password' || err.code === 'auth/invalid-credential') {
        toast.error('Current password is incorrect')
      } else if (err.code === 'auth/weak-password') {
        toast.error('Password is too weak')
      } else {
        toast.error('Failed to update password')
      }
    } finally {
      setSaving(false)
    }
  }

  const handleChangeEmail = async (e) => {
    e.preventDefault()
    if (!newEmail.trim() || !newEmail.includes('@')) {
      toast.error('Please enter a valid email')
      return
    }
    setSaving(true)
    try {
      await reauthenticate()
      await updateEmail(user, newEmail.trim())
      await updateDoc(doc(db, COLLECTIONS.USERS, user.uid), {
        email: newEmail.trim(),
      })
      toast.success('Email updated. Use the new email next time you log in.')
      setCurrentPassword('')
      setNewEmail('')
    } catch (err) {
      console.error(err)
      if (err.code === 'auth/wrong-password' || err.code === 'auth/invalid-credential') {
        toast.error('Current password is incorrect')
      } else if (err.code === 'auth/email-already-in-use') {
        toast.error('That email is already in use')
      } else if (err.code === 'auth/requires-recent-login') {
        toast.error('Please sign out and sign in again before changing email')
      } else {
        toast.error('Failed to update email')
      }
    } finally {
      setSaving(false)
    }
  }

  const goBack = () => {
    if (role === 'doctor') navigate('/doctor-queue')
    else navigate('/dashboard')
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8 px-4">
      <div className="max-w-2xl mx-auto">
        <button
          onClick={goBack}
          className="flex items-center gap-2 text-gray-600 hover:text-gray-900 mb-4"
        >
          <ArrowLeft size={16} /> Back
        </button>

        <div className="card">
          <h1 className="text-2xl font-bold mb-1">Account Settings</h1>
          <p className="text-gray-500 text-sm mb-6 flex items-center gap-2">
            <User size={14} /> Signed in as {user?.email}
          </p>

          <div className="flex gap-1 border-b mb-6">
            <button
              onClick={() => setActiveTab('password')}
              className={`px-4 py-2 text-sm font-medium border-b-2 transition ${
                activeTab === 'password'
                  ? 'border-primary-600 text-primary-700'
                  : 'border-transparent text-gray-500 hover:text-gray-700'
              }`}
            >
              <Lock size={14} className="inline mr-1" /> Change password
            </button>
            <button
              onClick={() => setActiveTab('email')}
              className={`px-4 py-2 text-sm font-medium border-b-2 transition ${
                activeTab === 'email'
                  ? 'border-primary-600 text-primary-700'
                  : 'border-transparent text-gray-500 hover:text-gray-700'
              }`}
            >
              <Mail size={14} className="inline mr-1" /> Change email
            </button>
          </div>

          {activeTab === 'password' && (
            <form onSubmit={handleChangePassword} className="space-y-4">
              <PasswordField
                label="Current password"
                value={currentPassword}
                onChange={setCurrentPassword}
                show={showCurrent}
                setShow={setShowCurrent}
              />
              <PasswordField
                label="New password"
                value={newPassword}
                onChange={setNewPassword}
                show={showNew}
                setShow={setShowNew}
              />
              <div>
                <label className="block text-sm font-medium mb-1">
                  Confirm new password
                </label>
                <input
                  type={showNew ? 'text' : 'password'}
                  className="input"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  required
                  minLength={6}
                />
              </div>
              <button
                type="submit"
                disabled={saving}
                className="btn-primary flex items-center gap-2"
              >
                <Save size={16} />
                {saving ? 'Updating...' : 'Update password'}
              </button>
            </form>
          )}

          {activeTab === 'email' && (
            <form onSubmit={handleChangeEmail} className="space-y-4">
              <div className="bg-blue-50 border border-blue-200 rounded-lg p-3 text-sm text-blue-900">
                You'll need to use your new email to sign in next time.
              </div>
              <PasswordField
                label="Current password"
                value={currentPassword}
                onChange={setCurrentPassword}
                show={showCurrent}
                setShow={setShowCurrent}
              />
              <div>
                <label className="block text-sm font-medium mb-1">New email</label>
                <input
                  type="email"
                  className="input"
                  value={newEmail}
                  onChange={(e) => setNewEmail(e.target.value)}
                  placeholder="new-email@example.com"
                  required
                />
              </div>
              <button
                type="submit"
                disabled={saving}
                className="btn-primary flex items-center gap-2"
              >
                <Save size={16} />
                {saving ? 'Updating...' : 'Update email'}
              </button>
            </form>
          )}
        </div>
      </div>
    </div>
  )
}

function PasswordField({ label, value, onChange, show, setShow }) {
  return (
    <div>
      <label className="block text-sm font-medium mb-1">{label}</label>
      <div className="relative">
        <input
          type={show ? 'text' : 'password'}
          className="input pr-10"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          required
          minLength={6}
        />
        <button
          type="button"
          onClick={() => setShow(!show)}
          className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-500"
        >
          {show ? <EyeOff size={16} /> : <Eye size={16} />}
        </button>
      </div>
    </div>
  )
}