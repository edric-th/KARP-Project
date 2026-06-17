import { useState, useEffect } from 'react'
import {
  Plus,
  Edit2,
  Trash2,
  Stethoscope,
  X,
  Clock,
  Building2,
  Lock,
  Mail,
  Eye,
  EyeOff,
  Copy,
  CheckCircle,
  KeyRound,
  Ban,
  UserPlus,
  Upload,
  Loader2,
} from 'lucide-react'
import {
  createUserWithEmailAndPassword,
  initializeAuth,
  inMemoryPersistence,
  sendPasswordResetEmail,
  connectAuthEmulator,
} from 'firebase/auth'
import { initializeApp, getApps } from 'firebase/app'
import {
  doc,
  setDoc,
  serverTimestamp,
  query as fsQuery,
  collection,
  where,
  getDocs,
  deleteDoc,
} from 'firebase/firestore'
import toast from 'react-hot-toast'
import { subscribe, create, update, remove } from '../../api/firestore'
import { compressImageToDataUrl } from '../../api/storage'
import { db, auth, USE_EMULATOR } from '../../lib/firebase'
import { COLLECTIONS } from '../../constants'

const WEEKDAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
}

const getSecondaryAuth = () => {
  const apps = getApps()
  let secondaryApp = apps.find((a) => a.name === 'secondary')
  if (!secondaryApp) {
    secondaryApp = initializeApp(firebaseConfig, 'secondary')
  }
  const secondaryAuth = initializeAuth(secondaryApp, {
    persistence: inMemoryPersistence,
  })
  // Keep doctor-account creation on the emulator too (this is a separate
  // Firebase app, so it needs its own emulator wiring).
  if (USE_EMULATOR) {
    connectAuthEmulator(secondaryAuth, 'http://127.0.0.1:9099', {
      disableWarnings: true,
    })
  }
  return secondaryAuth
}

export default function Doctors() {
  const [doctors, setDoctors] = useState([])
  const [hospitals, setHospitals] = useState([])
  const [loading, setLoading] = useState(true)
  const [showModal, setShowModal] = useState(false)
  const [editingDoctor, setEditingDoctor] = useState(null)
  const [filterHospital, setFilterHospital] = useState('all')
  const [showCredentials, setShowCredentials] = useState(null)
  const [creatingLoginFor, setCreatingLoginFor] = useState(null)

  useEffect(() => {
    const unsubDoctors = subscribe(COLLECTIONS.DOCTORS, (data) => {
      setDoctors(data)
      setLoading(false)
    })
    const unsubHospitals = subscribe(COLLECTIONS.HOSPITALS, setHospitals)
    return () => {
      unsubDoctors()
      unsubHospitals()
    }
  }, [])

  const getHospitalName = (hospitalId) => {
    const hospital = hospitals.find((h) => h.id === hospitalId)
    return hospital?.name || 'Unknown hospital'
  }

  const handleAdd = () => {
    if (hospitals.length === 0) {
      toast.error('Please add a hospital first')
      return
    }
    setEditingDoctor(null)
    setShowModal(true)
  }

  const handleEdit = (doctor) => {
    setEditingDoctor(doctor)
    setShowModal(true)
  }

  const handleDelete = async (doctor) => {
    if (
      !confirm(
        `Delete Dr. ${doctor.name}? This cannot be undone.\n\nNote: Their Firebase Auth account stays — delete it from Firebase Console if needed.`
      )
    )
      return
    try {
      await remove(COLLECTIONS.DOCTORS, doctor.id)
      toast.success('Doctor deleted')
    } catch (err) {
      toast.error('Failed to delete')
      console.error(err)
    }
  }

  const handleSendPasswordReset = async (doctor) => {
    if (!doctor.userEmail) {
      toast.error('This doctor has no login account')
      return
    }
    if (
      !confirm(`Send password reset email to ${doctor.userEmail}?`)
    )
      return
    try {
      await sendPasswordResetEmail(auth, doctor.userEmail)
      toast.success('Reset email sent')
    } catch (err) {
      console.error(err)
      if (err.code === 'auth/user-not-found') {
        toast.error('No account found for this email')
      } else {
        toast.error('Failed to send reset email')
      }
    }
  }

  const handleRevokeAccess = async (doctor) => {
    if (!doctor.userEmail) {
      toast.error('This doctor has no login account')
      return
    }
    if (
      !confirm(
        `Revoke login access for Dr. ${doctor.name}?\n\nThey won't be able to log in.`
      )
    )
      return
    try {
      const q = fsQuery(
        collection(db, COLLECTIONS.USERS),
        where('email', '==', doctor.userEmail)
      )
      const snap = await getDocs(q)
      if (!snap.empty) {
        for (const userDoc of snap.docs) {
          await deleteDoc(doc(db, COLLECTIONS.USERS, userDoc.id))
        }
      }
      await update(COLLECTIONS.DOCTORS, doctor.id, { userEmail: '' })
      toast.success('Login access revoked')
    } catch (err) {
      console.error(err)
      toast.error('Failed to revoke access')
    }
  }

  const filteredDoctors =
    filterHospital === 'all'
      ? doctors
      : doctors.filter((d) => d.hospitalId === filterHospital)

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold">Doctors</h1>
          <p className="text-gray-500 text-sm mt-1">
            Manage doctors and their schedules
          </p>
        </div>
        <button onClick={handleAdd} className="btn-primary flex items-center gap-2">
          <Plus size={18} /> Add Doctor
        </button>
      </div>

      {hospitals.length > 0 && (
        <div className="mb-4 flex items-center gap-3">
          <label className="text-sm font-medium text-gray-700">
            Filter by hospital:
          </label>
          <select
            value={filterHospital}
            onChange={(e) => setFilterHospital(e.target.value)}
            className="px-3 py-1.5 border border-gray-300 rounded-lg text-sm bg-white focus:ring-2 focus:ring-primary-500 outline-none"
          >
            <option value="all">All hospitals</option>
            {hospitals.map((h) => (
              <option key={h.id} value={h.id}>
                {h.name}
              </option>
            ))}
          </select>
        </div>
      )}

      {loading ? (
        <div className="card text-center text-gray-500">Loading doctors...</div>
      ) : filteredDoctors.length === 0 ? (
        <div className="card text-center py-12">
          <p className="text-gray-500 mb-4">
            {doctors.length === 0
              ? 'No doctors added yet.'
              : 'No doctors match the selected filter.'}
          </p>
          {doctors.length === 0 && (
            <button onClick={handleAdd} className="btn-primary">
              Add your first doctor
            </button>
          )}
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {filteredDoctors.map((doctor) => (
            <div key={doctor.id} className="card">
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center gap-3 min-w-0">
                  {doctor.photoUrl ? (
                    <img
                      src={doctor.photoUrl}
                      alt={doctor.name}
                      className="w-11 h-11 rounded-full object-cover flex-shrink-0"
                    />
                  ) : (
                    <div className="w-11 h-11 bg-primary-50 text-primary-600 rounded-full flex items-center justify-center flex-shrink-0">
                      <Stethoscope size={18} />
                    </div>
                  )}
                  <div className="min-w-0">
                    <h3 className="font-semibold truncate">Dr. {doctor.name}</h3>
                    <p className="text-xs text-gray-500 truncate">
                      {doctor.specialty || 'General'}
                    </p>
                  </div>
                </div>
                <div className="flex gap-1 flex-shrink-0">
                  {doctor.userEmail ? (
                    <>
                      <button
                        onClick={() => handleSendPasswordReset(doctor)}
                        className="p-1.5 text-gray-500 hover:text-amber-600 hover:bg-gray-100 rounded"
                        title="Send password reset email"
                      >
                        <KeyRound size={16} />
                      </button>
                      <button
                        onClick={() => handleRevokeAccess(doctor)}
                        className="p-1.5 text-gray-500 hover:text-orange-600 hover:bg-gray-100 rounded"
                        title="Revoke login access"
                      >
                        <Ban size={16} />
                      </button>
                    </>
                  ) : (
                    <button
                      onClick={() => setCreatingLoginFor(doctor)}
                      className="p-1.5 text-gray-500 hover:text-emerald-600 hover:bg-gray-100 rounded"
                      title="Create login account"
                    >
                      <UserPlus size={16} />
                    </button>
                  )}
                  <button
                    onClick={() => handleEdit(doctor)}
                    className="p-1.5 text-gray-500 hover:text-primary-600 hover:bg-gray-100 rounded"
                    title="Edit"
                  >
                    <Edit2 size={16} />
                  </button>
                  <button
                    onClick={() => handleDelete(doctor)}
                    className="p-1.5 text-gray-500 hover:text-red-600 hover:bg-gray-100 rounded"
                    title="Delete"
                  >
                    <Trash2 size={16} />
                  </button>
                </div>
              </div>
              <div className="flex flex-wrap items-center gap-2 mb-3">
                <span
                  className={`text-xs font-medium px-2 py-0.5 rounded-full ${
                    doctor.isAvailable === false
                      ? 'bg-gray-100 text-gray-500'
                      : 'bg-emerald-50 text-emerald-700'
                  }`}
                >
                  {doctor.isAvailable === false ? 'Unavailable' : 'Available'}
                </span>
                {doctor.rating > 0 && (
                  <span className="text-xs font-medium px-2 py-0.5 rounded-full bg-amber-50 text-amber-700">
                    ★ {doctor.rating} ({doctor.reviewCount || 0})
                  </span>
                )}
                {doctor.experience ? (
                  <span className="text-xs font-medium px-2 py-0.5 rounded-full bg-gray-100 text-gray-600">
                    {doctor.experience} yrs exp
                  </span>
                ) : null}
              </div>
              <div className="space-y-1.5 text-sm text-gray-600">
                <p className="flex items-center gap-2">
                  <Building2 size={14} className="text-gray-400 flex-shrink-0" />
                  {getHospitalName(doctor.hospitalId)}
                </p>
                {Array.isArray(doctor.availabilityDays) &&
                  doctor.availabilityDays.length > 0 && (
                    <p className="flex items-center gap-2">
                      <Clock size={14} className="text-gray-400 flex-shrink-0" />
                      {doctor.availabilityDays.join(', ')}
                      {doctor.availabilityStart && doctor.availabilityEnd
                        ? ` · ${doctor.availabilityStart}–${doctor.availabilityEnd}`
                        : ''}
                    </p>
                  )}
                {doctor.userEmail ? (
                  <p className="flex items-center gap-2 text-xs text-emerald-700 bg-emerald-50 px-2 py-1 rounded">
                    <CheckCircle size={12} className="flex-shrink-0" />
                    <span className="truncate">{doctor.userEmail}</span>
                  </p>
                ) : (
                  <p className="flex items-center gap-2 text-xs text-amber-700 bg-amber-50 px-2 py-1 rounded">
                    <Lock size={12} className="flex-shrink-0" />
                    No login account
                  </p>
                )}
              </div>
              <div className="flex items-center justify-between pt-3 mt-3 border-t border-gray-100">
                <span className="text-sm font-semibold text-gray-800">
                  {doctor.fee ? `Rs. ${doctor.fee}` : 'Fee not set'}
                </span>
              </div>
            </div>
          ))}
        </div>
      )}

      {showModal && (
        <DoctorModal
          doctor={editingDoctor}
          hospitals={hospitals}
          onClose={() => setShowModal(false)}
          onCredentialsCreated={setShowCredentials}
        />
      )}

      {creatingLoginFor && (
        <CreateLoginModal
          doctor={creatingLoginFor}
          onClose={() => setCreatingLoginFor(null)}
          onCredentialsCreated={setShowCredentials}
        />
      )}

      {showCredentials && (
        <CredentialsModal
          credentials={showCredentials}
          onClose={() => setShowCredentials(null)}
        />
      )}
    </div>
  )
}

// ---------- Add/Edit Doctor Modal ----------

function DoctorModal({ doctor, hospitals, onClose, onCredentialsCreated }) {
  const isEditing = !!doctor
  const [formData, setFormData] = useState({
    name: doctor?.name || '',
    specialty: doctor?.specialty || '',
    hospitalId: doctor?.hospitalId || hospitals[0]?.id || '',
    fee: doctor?.fee || '',
    userEmail: doctor?.userEmail || '',
    bio: doctor?.bio || '',
    experience: doctor?.experience ?? '',
    photoUrl: doctor?.photoUrl || '',
    isAvailable: doctor?.isAvailable ?? true,
    availabilityDays: Array.isArray(doctor?.availabilityDays)
      ? doctor.availabilityDays
      : [],
    availabilityStart: doctor?.availabilityStart || '',
    availabilityEnd: doctor?.availabilityEnd || '',
  })
  const [createLogin, setCreateLogin] = useState(!isEditing)
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [saving, setSaving] = useState(false)
  const [uploading, setUploading] = useState(false)

  const toggleDay = (day) => {
    setFormData((fd) => ({
      ...fd,
      availabilityDays: fd.availabilityDays.includes(day)
        ? fd.availabilityDays.filter((d) => d !== day)
        : [...fd.availabilityDays, day],
    }))
  }

  const handlePhotoFile = async (e) => {
    const file = e.target.files?.[0]
    if (!file) return
    if (!file.type.startsWith('image/')) {
      toast.error('Please choose an image file')
      return
    }
    setUploading(true)
    try {
      const dataUrl = await compressImageToDataUrl(file, { maxSize: 512, quality: 0.8 })
      setFormData((fd) => ({ ...fd, photoUrl: dataUrl }))
      toast.success('Photo added')
    } catch (err) {
      console.error(err)
      toast.error('Could not process that photo')
    } finally {
      // Always clear the spinner — even on failure — so it never hangs.
      setUploading(false)
      // Reset the input so picking the same file again re-triggers onChange.
      e.target.value = ''
    }
  }

  const handleChange = (field) => (e) => {
    setFormData({ ...formData, [field]: e.target.value })
  }

  const generatePassword = () => {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789'
    const symbols = '!@#$%'
    let pw = ''
    for (let i = 0; i < 10; i++)
      pw += chars[Math.floor(Math.random() * chars.length)]
    pw += symbols[Math.floor(Math.random() * symbols.length)]
    setPassword(pw)
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!formData.name.trim()) {
      toast.error('Doctor name is required')
      return
    }
    if (!formData.hospitalId) {
      toast.error('Please select a hospital')
      return
    }

    if (createLogin && !isEditing) {
      if (!formData.userEmail.trim()) {
        toast.error('Email is required to create login')
        return
      }
      if (!password || password.length < 6) {
        toast.error('Password must be at least 6 characters')
        return
      }
    }

    setSaving(true)
    try {
      const payload = {
        ...formData,
        fee: formData.fee ? Number(formData.fee) : null,
        experience: formData.experience ? Number(formData.experience) : null,
      }

      let createdCredentials = null

      if (isEditing) {
        await update(COLLECTIONS.DOCTORS, doctor.id, payload)
        toast.success('Doctor updated')
      } else {
        if (createLogin) {
          const secondaryAuth = getSecondaryAuth()
          try {
            const userCred = await createUserWithEmailAndPassword(
              secondaryAuth,
              formData.userEmail.trim(),
              password
            )
            await setDoc(doc(db, COLLECTIONS.USERS, userCred.user.uid), {
              email: formData.userEmail.trim(),
              role: 'doctor',
              name: `Dr. ${formData.name}`,
              createdAt: serverTimestamp(),
            })
            await secondaryAuth.signOut()
            createdCredentials = {
              email: formData.userEmail.trim(),
              password,
              doctorName: formData.name,
            }
          } catch (authErr) {
            if (authErr.code === 'auth/email-already-in-use') {
              toast.error('Email already has an account. Use a different email.')
            } else if (authErr.code === 'auth/invalid-email') {
              toast.error('Invalid email format')
            } else {
              toast.error(`Login creation failed: ${authErr.message}`)
            }
            setSaving(false)
            return
          }
        }
        await create(COLLECTIONS.DOCTORS, payload)
        toast.success(createLogin ? 'Doctor added with login' : 'Doctor added')
      }

      onClose()
      if (createdCredentials) {
        setTimeout(() => onCredentialsCreated(createdCredentials), 100)
      }
    } catch (err) {
      toast.error('Failed to save')
      console.error(err)
    } finally {
      setSaving(false)
    }
  }

  return (
    <div
      className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50"
      onClick={onClose}
    >
      <div
        className="bg-white rounded-xl shadow-xl w-full max-w-md max-h-[90vh] overflow-y-auto"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between p-6 border-b">
          <h2 className="text-xl font-bold">
            {isEditing ? 'Edit Doctor' : 'Add Doctor'}
          </h2>
          <button onClick={onClose} className="p-1 hover:bg-gray-100 rounded">
            <X size={20} />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1">
              Name <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              required
              className="input"
              value={formData.name}
              onChange={handleChange('name')}
              placeholder="e.g. Ram Bahadur Sharma"
            />
            <p className="text-xs text-gray-500 mt-1">Don't include "Dr." prefix</p>
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Specialty</label>
            <input
              type="text"
              className="input"
              value={formData.specialty}
              onChange={handleChange('specialty')}
              placeholder="e.g. Cardiologist"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">
              Hospital <span className="text-red-500">*</span>
            </label>
            <select
              required
              className="input"
              value={formData.hospitalId}
              onChange={handleChange('hospitalId')}
            >
              <option value="">Select a hospital</option>
              {hospitals.map((h) => (
                <option key={h.id} value={h.id}>
                  {h.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">
              Consultation Fee (Rs.)
            </label>
            <input
              type="number"
              min="0"
              className="input"
              value={formData.fee}
              onChange={handleChange('fee')}
              placeholder="e.g. 1500"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-sm font-medium mb-1">
                Experience (years)
              </label>
              <input
                type="number"
                min="0"
                className="input"
                value={formData.experience}
                onChange={handleChange('experience')}
                placeholder="e.g. 12"
              />
            </div>
            <div className="flex items-end pb-2">
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={formData.isAvailable}
                  onChange={(e) =>
                    setFormData({ ...formData, isAvailable: e.target.checked })
                  }
                  className="w-4 h-4 text-primary-600 rounded"
                />
                <span className="text-sm font-medium">Accepting patients</span>
              </label>
            </div>
          </div>

          <div className="border-t pt-4">
            <label className="block text-sm font-medium mb-2">
              Availability
            </label>
            <div className="flex flex-wrap gap-1.5 mb-3">
              {WEEKDAYS.map((day) => {
                const active = formData.availabilityDays.includes(day)
                return (
                  <button
                    key={day}
                    type="button"
                    onClick={() => toggleDay(day)}
                    className={`px-3 py-1.5 rounded-full text-xs font-medium border transition-colors ${
                      active
                        ? 'bg-primary-600 text-white border-primary-600'
                        : 'bg-white text-gray-600 border-gray-300 hover:bg-gray-50'
                    }`}
                  >
                    {day}
                  </button>
                )
              })}
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs text-gray-500 mb-1">
                  From
                </label>
                <TimeAmPm
                  value={formData.availabilityStart}
                  onChange={(v) =>
                    setFormData((fd) => ({ ...fd, availabilityStart: v }))
                  }
                />
              </div>
              <div>
                <label className="block text-xs text-gray-500 mb-1">To</label>
                <TimeAmPm
                  value={formData.availabilityEnd}
                  onChange={(v) =>
                    setFormData((fd) => ({ ...fd, availabilityEnd: v }))
                  }
                />
              </div>
            </div>
            <p className="text-xs text-gray-500 mt-1">
              Days and hours the doctor consults. Patients see "not available"
              outside these.
            </p>
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Doctor Photo</label>
            <div className="flex items-center gap-3">
              {formData.photoUrl ? (
                <img
                  src={formData.photoUrl}
                  alt="Doctor"
                  className="w-16 h-16 rounded-full object-cover border border-gray-200 flex-shrink-0"
                />
              ) : (
                <div className="w-16 h-16 rounded-full bg-gray-100 text-gray-400 flex items-center justify-center flex-shrink-0">
                  <Stethoscope size={22} />
                </div>
              )}
              <div className="flex-1">
                <label
                  className={`inline-flex items-center gap-2 px-3 py-2 border border-gray-300 rounded-lg text-sm font-medium cursor-pointer hover:bg-gray-50 ${
                    uploading ? 'opacity-60 pointer-events-none' : ''
                  }`}
                >
                  {uploading ? (
                    <Loader2 size={16} className="animate-spin" />
                  ) : (
                    <Upload size={16} />
                  )}
                  {uploading ? 'Uploading…' : 'Upload photo'}
                  <input
                    type="file"
                    accept="image/*"
                    className="hidden"
                    onChange={handlePhotoFile}
                    disabled={uploading}
                  />
                </label>
                {formData.photoUrl && (
                  <button
                    type="button"
                    onClick={() => setFormData({ ...formData, photoUrl: '' })}
                    className="ml-2 text-sm text-red-600 hover:underline"
                  >
                    Remove
                  </button>
                )}
              </div>
            </div>
            <input
              type="url"
              className="input mt-2"
              value={formData.photoUrl}
              onChange={handleChange('photoUrl')}
              placeholder="…or paste an image URL"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Bio</label>
            <textarea
              rows={3}
              className="input"
              value={formData.bio}
              onChange={handleChange('bio')}
              placeholder="Short professional bio shown in the patient app"
            />
          </div>

          {!isEditing && (
            <div className="border-t pt-4">
              <label className="flex items-center gap-2 mb-3 cursor-pointer">
                <input
                  type="checkbox"
                  checked={createLogin}
                  onChange={(e) => setCreateLogin(e.target.checked)}
                  className="w-4 h-4 text-primary-600 rounded"
                />
                <span className="text-sm font-medium">
                  Create login account for this doctor
                </span>
              </label>

              {createLogin && (
                <div className="space-y-3 bg-blue-50 p-4 rounded-lg">
                  <div>
                    <label className="text-sm font-medium mb-1 flex items-center gap-2">
                      <Mail size={14} /> Doctor's Email
                    </label>
                    <input
                      type="email"
                      className="input"
                      value={formData.userEmail}
                      onChange={handleChange('userEmail')}
                      placeholder="doctor@hospital.com"
                      required={createLogin}
                    />
                  </div>
                  <div>
                    <label className="text-sm font-medium mb-1 flex items-center gap-2">
                      <Lock size={14} /> Password
                    </label>
                    <div className="flex gap-2">
                      <div className="flex-1 relative">
                        <input
                          type={showPassword ? 'text' : 'password'}
                          className="input pr-10"
                          value={password}
                          onChange={(e) => setPassword(e.target.value)}
                          placeholder="At least 6 characters"
                          required={createLogin}
                          minLength={6}
                        />
                        <button
                          type="button"
                          onClick={() => setShowPassword(!showPassword)}
                          className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-500"
                        >
                          {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                        </button>
                      </div>
                      <button
                        type="button"
                        onClick={generatePassword}
                        className="px-3 py-2 bg-white border border-gray-300 rounded-lg text-sm font-medium hover:bg-gray-50"
                      >
                        Generate
                      </button>
                    </div>
                  </div>
                </div>
              )}
            </div>
          )}

          {isEditing && formData.userEmail && (
            <div className="bg-gray-50 p-3 rounded-lg text-sm">
              <p className="font-medium flex items-center gap-2 text-gray-700">
                <Lock size={14} /> Login account
              </p>
              <p className="text-gray-600 mt-1">{formData.userEmail}</p>
              <p className="text-xs text-gray-500 mt-2">
                Use the key icon on the doctor card to send a password reset email.
              </p>
            </div>
          )}

          {isEditing && !formData.userEmail && (
            <div className="bg-amber-50 border border-amber-200 p-3 rounded-lg text-sm">
              <p className="font-medium text-amber-800">No login account yet</p>
              <p className="text-xs text-amber-700 mt-1">
                Close this dialog and use the green person icon on the doctor card
                to create their login.
              </p>
            </div>
          )}

          <div className="flex gap-3 pt-4">
            <button type="button" onClick={onClose} className="btn-secondary flex-1">
              Cancel
            </button>
            <button type="submit" disabled={saving} className="btn-primary flex-1">
              {saving
                ? 'Saving...'
                : isEditing
                  ? 'Update'
                  : createLogin
                    ? 'Add & Create Login'
                    : 'Add'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ---------- AM/PM time picker (stores 24h "HH:mm") ----------

function TimeAmPm({ value, onChange }) {
  const parse = (v) => {
    if (!v || !v.includes(':')) return { h12: 9, m: 0, period: 'AM' }
    const [hStr, mStr] = v.split(':')
    let h = parseInt(hStr, 10)
    if (Number.isNaN(h)) h = 9
    const m = parseInt(mStr, 10) || 0
    const period = h >= 12 ? 'PM' : 'AM'
    let h12 = h % 12
    if (h12 === 0) h12 = 12
    return { h12, m, period }
  }

  const { h12, m, period } = parse(value)

  const emit = (nh12, nm, nperiod) => {
    let h = nh12 % 12
    if (nperiod === 'PM') h += 12
    onChange(`${String(h).padStart(2, '0')}:${String(nm).padStart(2, '0')}`)
  }

  const hours = Array.from({ length: 12 }, (_, i) => i + 1)
  // 5-minute steps, plus the current minute if it isn't on the grid.
  const minutes = Array.from(
    new Set([...Array.from({ length: 12 }, (_, i) => i * 5), m])
  ).sort((a, b) => a - b)

  const sel =
    'input px-2 py-2 text-sm'

  return (
    <div className="flex gap-1.5">
      <select
        className={sel}
        value={h12}
        onChange={(e) => emit(Number(e.target.value), m, period)}
      >
        {hours.map((h) => (
          <option key={h} value={h}>
            {h}
          </option>
        ))}
      </select>
      <span className="self-center text-gray-400">:</span>
      <select
        className={sel}
        value={m}
        onChange={(e) => emit(h12, Number(e.target.value), period)}
      >
        {minutes.map((mm) => (
          <option key={mm} value={mm}>
            {String(mm).padStart(2, '0')}
          </option>
        ))}
      </select>
      <select
        className={sel}
        value={period}
        onChange={(e) => emit(h12, m, e.target.value)}
      >
        <option value="AM">AM</option>
        <option value="PM">PM</option>
      </select>
    </div>
  )
}

// ---------- Create Login for Existing Doctor ----------

function CreateLoginModal({ doctor, onClose, onCredentialsCreated }) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [saving, setSaving] = useState(false)

  const generatePassword = () => {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789'
    const symbols = '!@#$%'
    let pw = ''
    for (let i = 0; i < 10; i++)
      pw += chars[Math.floor(Math.random() * chars.length)]
    pw += symbols[Math.floor(Math.random() * symbols.length)]
    setPassword(pw)
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!email.trim()) {
      toast.error('Email is required')
      return
    }
    if (!password || password.length < 6) {
      toast.error('Password must be at least 6 characters')
      return
    }

    setSaving(true)
    try {
      const secondaryAuth = getSecondaryAuth()
      try {
        const userCred = await createUserWithEmailAndPassword(
          secondaryAuth,
          email.trim(),
          password
        )
        await setDoc(doc(db, COLLECTIONS.USERS, userCred.user.uid), {
          email: email.trim(),
          role: 'doctor',
          name: `Dr. ${doctor.name}`,
          createdAt: serverTimestamp(),
        })
        await secondaryAuth.signOut()

        // Link the email to the existing doctor record
        await update(COLLECTIONS.DOCTORS, doctor.id, {
          userEmail: email.trim(),
        })

        toast.success(`Login created for Dr. ${doctor.name}`)
        onClose()
        setTimeout(
          () =>
            onCredentialsCreated({
              email: email.trim(),
              password,
              doctorName: doctor.name,
            }),
          100
        )
      } catch (authErr) {
        if (authErr.code === 'auth/email-already-in-use') {
          toast.error('This email already has an account. Use a different email.')
        } else if (authErr.code === 'auth/invalid-email') {
          toast.error('Invalid email format')
        } else {
          toast.error(`Failed: ${authErr.message}`)
        }
      }
    } catch (err) {
      toast.error('Failed to create login')
      console.error(err)
    } finally {
      setSaving(false)
    }
  }

  return (
    <div
      className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50"
      onClick={onClose}
    >
      <div
        className="bg-white rounded-xl shadow-xl w-full max-w-md"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between p-6 border-b">
          <div>
            <h2 className="text-xl font-bold">Create Login</h2>
            <p className="text-sm text-gray-500 mt-1">
              For Dr. {doctor.name} · {doctor.specialty}
            </p>
          </div>
          <button onClick={onClose} className="p-1 hover:bg-gray-100 rounded">
            <X size={20} />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div className="bg-blue-50 p-3 rounded-lg text-sm text-blue-900">
            This will create a Firebase login account and link it to Dr.{' '}
            {doctor.name}'s profile. Use a unique email — it can't already be in
            use.
          </div>

          <div>
            <label className="text-sm font-medium mb-1 flex items-center gap-2">
              <Mail size={14} /> Doctor's Email
            </label>
            <input
              type="email"
              className="input"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="unique-email@hospital.com"
              required
              autoFocus
            />
          </div>

          <div>
            <label className="text-sm font-medium mb-1 flex items-center gap-2">
              <Lock size={14} /> Password
            </label>
            <div className="flex gap-2">
              <div className="flex-1 relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  className="input pr-10"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="At least 6 characters"
                  required
                  minLength={6}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-500"
                >
                  {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
              <button
                type="button"
                onClick={generatePassword}
                className="px-3 py-2 bg-white border border-gray-300 rounded-lg text-sm font-medium hover:bg-gray-50"
              >
                Generate
              </button>
            </div>
            <p className="text-xs text-gray-600 mt-1">
              You'll see this password once after saving.
            </p>
          </div>

          <div className="flex gap-3 pt-2">
            <button type="button" onClick={onClose} className="btn-secondary flex-1">
              Cancel
            </button>
            <button type="submit" disabled={saving} className="btn-primary flex-1">
              {saving ? 'Creating...' : 'Create Login'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ---------- Credentials Display Modal ----------

function CredentialsModal({ credentials, onClose }) {
  const [copied, setCopied] = useState(false)

  const copyAll = () => {
    const text = `Doctor: Dr. ${credentials.doctorName}
Email: ${credentials.email}
Password: ${credentials.password}
Login at: ${window.location.origin}/login`
    navigator.clipboard.writeText(text)
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
    toast.success('Copied to clipboard')
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-xl shadow-xl w-full max-w-md">
        <div className="p-6 border-b bg-emerald-50">
          <div className="flex items-center gap-3 mb-2">
            <div className="w-10 h-10 bg-emerald-100 rounded-full flex items-center justify-center">
              <CheckCircle className="text-emerald-600" size={20} />
            </div>
            <h2 className="text-xl font-bold text-emerald-900">Login Created</h2>
          </div>
          <p className="text-sm text-emerald-800">
            Save these credentials and give them to Dr. {credentials.doctorName}.
            They won't be shown again.
          </p>
        </div>

        <div className="p-6 space-y-4">
          <div className="bg-gray-50 p-4 rounded-lg space-y-3">
            <div>
              <p className="text-xs text-gray-500 uppercase tracking-wider mb-1">
                Email
              </p>
              <p className="font-mono font-medium">{credentials.email}</p>
            </div>
            <div>
              <p className="text-xs text-gray-500 uppercase tracking-wider mb-1">
                Password
              </p>
              <p className="font-mono font-medium select-all">
                {credentials.password}
              </p>
            </div>
            <div>
              <p className="text-xs text-gray-500 uppercase tracking-wider mb-1">
                Login URL
              </p>
              <p className="font-mono text-sm">{window.location.origin}/login</p>
            </div>
          </div>

          <button
            onClick={copyAll}
            className="w-full btn-secondary flex items-center justify-center gap-2"
          >
            <Copy size={16} />
            {copied ? 'Copied!' : 'Copy all details'}
          </button>

          <div className="bg-amber-50 border border-amber-200 rounded-lg p-3 text-xs text-amber-800">
            <strong>Important:</strong> This is the only time the password will be
            shown. Share it with the doctor securely.
          </div>

          <button onClick={onClose} className="btn-primary w-full">
            Done — I've saved these credentials
          </button>
        </div>
      </div>
    </div>
  )
}