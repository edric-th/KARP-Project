import { useState, useEffect } from 'react'
import { doc, setDoc, serverTimestamp } from 'firebase/firestore'
import {
  createUserWithEmailAndPassword,
  sendPasswordResetEmail,
} from 'firebase/auth'
import {
  UserCog,
  UserPlus,
  Building2,
  Mail,
  Lock,
  KeyRound,
  Ban,
  Loader2,
  Eye,
  EyeOff,
  User,
} from 'lucide-react'
import toast from 'react-hot-toast'
import { db, auth } from '../../lib/firebase'
import { getSecondaryAuth } from '../../lib/secondaryAuth'
import { subscribe, remove } from '../../api/firestore'
import { COLLECTIONS, ROLES } from '../../constants'
import ConfirmModal from '../../components/ConfirmModal'

const emptyForm = { name: '', email: '', password: '', hospitalId: '' }

/**
 * Staff management (admin only) — create and manage reception desk accounts.
 * A receptionist account is a Firebase Auth user plus a users/{uid} doc with
 * role 'receptionist' and an assigned hospitalId (which locks their desk to
 * that hospital). New accounts are created via a throwaway secondary auth app
 * so the admin's own session is never disturbed.
 */
export default function Staff() {
  const [hospitals, setHospitals] = useState([])
  const [receptionists, setReceptionists] = useState([])
  const [form, setForm] = useState(emptyForm)
  const [showPassword, setShowPassword] = useState(false)
  const [saving, setSaving] = useState(false)
  const [removeTarget, setRemoveTarget] = useState(null)
  const [removing, setRemoving] = useState(false)

  useEffect(() => {
    const unsub = subscribe(COLLECTIONS.HOSPITALS, (data) => {
      setHospitals(data)
      setForm((f) => (f.hospitalId ? f : { ...f, hospitalId: data[0]?.id || '' }))
    })
    return () => unsub()
  }, [])

  useEffect(() => {
    const unsub = subscribe(COLLECTIONS.USERS, (data) => {
      setReceptionists(data.filter((u) => u.role === ROLES.RECEPTIONIST))
    })
    return () => unsub()
  }, [])

  const hospitalName = (id) =>
    hospitals.find((h) => h.id === id)?.name || 'Unassigned'

  const set = (key) => (e) => setForm((f) => ({ ...f, [key]: e.target.value }))

  const handleCreate = async (e) => {
    e.preventDefault()
    const name = form.name.trim()
    const email = form.email.trim()
    if (!name) return toast.error('Please enter a name')
    if (!email) return toast.error('Please enter an email')
    if (form.password.length < 6)
      return toast.error('Password must be at least 6 characters')
    if (!form.hospitalId) return toast.error('Please assign a hospital')

    setSaving(true)
    try {
      const secondaryAuth = getSecondaryAuth()
      const cred = await createUserWithEmailAndPassword(
        secondaryAuth,
        email,
        form.password
      )
      await setDoc(doc(db, COLLECTIONS.USERS, cred.user.uid), {
        email,
        role: ROLES.RECEPTIONIST,
        hospitalId: form.hospitalId,
        name,
        createdAt: serverTimestamp(),
      })
      await secondaryAuth.signOut()
      toast.success(`Reception account created for ${name}`)
      setForm({ ...emptyForm, hospitalId: form.hospitalId })
    } catch (err) {
      console.error(err)
      if (err.code === 'auth/email-already-in-use') {
        toast.error('That email already has an account')
      } else if (err.code === 'auth/invalid-email') {
        toast.error('Invalid email format')
      } else {
        toast.error('Failed to create account')
      }
    } finally {
      setSaving(false)
    }
  }

  const handleReset = async (email) => {
    try {
      await sendPasswordResetEmail(auth, email)
      toast.success(`Reset email sent to ${email}`)
    } catch (err) {
      console.error(err)
      toast.error('Failed to send reset email')
    }
  }

  const confirmRemove = async () => {
    if (!removeTarget) return
    setRemoving(true)
    try {
      // Removes panel access by deleting the role doc. The Firebase Auth
      // credential itself can't be deleted from the client SDK and remains.
      await remove(COLLECTIONS.USERS, removeTarget.id)
      toast.success('Reception access removed')
    } catch (err) {
      console.error(err)
      toast.error('Failed to remove access')
    } finally {
      setRemoving(false)
      setRemoveTarget(null)
    }
  }

  return (
    <div>
      <div className="mb-6">
        <h1 className="text-2xl font-bold flex items-center gap-2">
          <UserCog size={22} className="text-primary-600" />
          Staff
        </h1>
        <p className="text-gray-500 text-sm mt-1">
          Create and manage reception desk accounts
        </p>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        {/* Create form */}
        <div className="card">
          <h2 className="font-bold text-lg mb-4 flex items-center gap-2">
            <UserPlus size={18} className="text-primary-600" />
            New reception account
          </h2>
          <form onSubmit={handleCreate} className="space-y-4">
            <div>
              <label className="block text-sm font-medium mb-1 flex items-center gap-1.5">
                <User size={14} className="text-gray-400" /> Name
              </label>
              <input
                className="input"
                value={form.name}
                onChange={set('name')}
                placeholder="Jane Doe"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1 flex items-center gap-1.5">
                <Mail size={14} className="text-gray-400" /> Email
              </label>
              <input
                type="email"
                className="input"
                value={form.email}
                onChange={set('email')}
                placeholder="reception@hospital.com"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1 flex items-center gap-1.5">
                <Lock size={14} className="text-gray-400" /> Password
              </label>
              <div className="relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  className="input pr-10"
                  value={form.password}
                  onChange={set('password')}
                  placeholder="At least 6 characters"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword((s) => !s)}
                  className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                >
                  {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium mb-1 flex items-center gap-1.5">
                <Building2 size={14} className="text-gray-400" /> Assigned hospital
              </label>
              <select
                className="input"
                value={form.hospitalId}
                onChange={set('hospitalId')}
              >
                {hospitals.length === 0 && <option value="">No hospitals</option>}
                {hospitals.map((h) => (
                  <option key={h.id} value={h.id}>
                    {h.name}
                  </option>
                ))}
              </select>
            </div>
            <button
              type="submit"
              disabled={saving}
              className="btn-primary w-full flex items-center justify-center gap-2"
            >
              {saving ? (
                <>
                  <Loader2 size={18} className="animate-spin" /> Creating…
                </>
              ) : (
                <>
                  <UserPlus size={18} /> Create account
                </>
              )}
            </button>
          </form>
        </div>

        {/* Existing receptionists */}
        <div className="card">
          <h2 className="font-bold text-lg mb-4">
            Reception staff ({receptionists.length})
          </h2>
          {receptionists.length === 0 ? (
            <p className="text-gray-500 text-sm">No reception accounts yet.</p>
          ) : (
            <div className="space-y-3">
              {receptionists.map((r) => (
                <div
                  key={r.id}
                  className="border border-gray-100 rounded-xl p-3 flex items-center gap-3 flex-wrap"
                >
                  <div className="min-w-0 flex-1">
                    <p className="font-semibold text-gray-900 truncate">
                      {r.name || r.email}
                    </p>
                    <p className="text-xs text-gray-500 truncate">{r.email}</p>
                    <p className="text-xs text-gray-500 flex items-center gap-1 mt-0.5">
                      <Building2 size={11} /> {hospitalName(r.hospitalId)}
                    </p>
                  </div>
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => handleReset(r.email)}
                      className="p-2 rounded-lg text-gray-500 hover:bg-gray-100 hover:text-primary-600"
                      title="Send password reset"
                    >
                      <KeyRound size={18} />
                    </button>
                    <button
                      onClick={() => setRemoveTarget(r)}
                      className="p-2 rounded-lg text-gray-500 hover:bg-red-50 hover:text-red-600"
                      title="Remove access"
                    >
                      <Ban size={18} />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
          <p className="text-gray-400 text-xs mt-4">
            “Remove access” deletes the staff role so they can no longer sign in
            to the desk. The underlying login credential itself isn’t deleted.
          </p>
        </div>
      </div>

      <ConfirmModal
        open={!!removeTarget}
        title="Remove reception access?"
        message={
          removeTarget
            ? `${removeTarget.name || removeTarget.email} will no longer be able to sign in to the reception desk.`
            : ''
        }
        confirmLabel="Remove access"
        danger
        busy={removing}
        onConfirm={confirmRemove}
        onClose={() => !removing && setRemoveTarget(null)}
      />
    </div>
  )
}
