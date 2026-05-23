import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  collection,
  query,
  where,
  orderBy,
  onSnapshot,
} from 'firebase/firestore'
import {
  Check,
  X as XIcon,
  ChevronRight,
  RotateCcw,
  LogOut,
  Clock,
  User,
  Phone,
  Stethoscope,
  AlertCircle,
  Coffee,
  Settings,
} from 'lucide-react'
import toast from 'react-hot-toast'
import { db } from '../../lib/firebase'
import { subscribe, update } from '../../api/firestore'
import { useAuth } from '../../context/AuthContext'
import {
  calculateAvgServiceTime,
  estimateWaitMinutes,
  formatWaitTime,
  projectedCallTime,
  formatExpectedTime,
} from '../../lib/waitTime'
import { COLLECTIONS, BOOKING_STATUS, BOOKING_TYPES } from '../../constants'


const todayString = () => {
  const d = new Date()
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

const bookingTypeLabel = {
  [BOOKING_TYPES.FIRST_VISIT]: 'First Visit',
  [BOOKING_TYPES.FOLLOW_UP]: 'Follow-up',
  [BOOKING_TYPES.REPORT]: 'Show Report',
}

const bookingTypeColor = {
  [BOOKING_TYPES.FIRST_VISIT]: 'bg-blue-100 text-blue-700',
  [BOOKING_TYPES.FOLLOW_UP]: 'bg-purple-100 text-purple-700',
  [BOOKING_TYPES.REPORT]: 'bg-amber-100 text-amber-700',
}

export default function DoctorQueue() {
  const { user, role, signOut } = useAuth()
  const navigate = useNavigate()

  const [doctorProfile, setDoctorProfile] = useState(null)
  const [hospital, setHospital] = useState(null)
  const [bookings, setBookings] = useState([])
  const [loading, setLoading] = useState(true)
  const [time, setTime] = useState(new Date())

  // Live clock
  useEffect(() => {
    const interval = setInterval(() => setTime(new Date()), 1000)
    return () => clearInterval(interval)
  }, [])

  // Find which doctor this user is linked to
  // We match by email since doctor accounts will be created with matching emails
  useEffect(() => {
    if (!user?.email) return
    const unsubscribe = subscribe(COLLECTIONS.DOCTORS, (docs) => {
      const matched = docs.find(
        (d) =>
          d.userEmail === user.email ||
          d.email === user.email
      )
      setDoctorProfile(matched || null)
      if (!matched) setLoading(false)
    })
    return () => unsubscribe()
  }, [user])

  // Load hospital info for the doctor
  useEffect(() => {
    if (!doctorProfile?.hospitalId) return
    const unsubscribe = subscribe(COLLECTIONS.HOSPITALS, (hospitals) => {
      const found = hospitals.find((h) => h.id === doctorProfile.hospitalId)
      setHospital(found || null)
    })
    return () => unsubscribe()
  }, [doctorProfile])

  // Load today's bookings for this doctor
  useEffect(() => {
    if (!doctorProfile?.id) {
      setBookings([])
      setLoading(false)
      return
    }
    const today = todayString()
    const q = query(
      collection(db, COLLECTIONS.BOOKINGS),
      where('doctorId', '==', doctorProfile.id),
      where('bookingDate', '==', today),
      orderBy('tokenNumber', 'asc')
    )
    const unsubscribe = onSnapshot(
      q,
      (snap) => {
        const data = snap.docs.map((d) => ({ id: d.id, ...d.data() }))
        setBookings(data)
        setLoading(false)
      },
      (err) => {
        console.error('Bookings listener error:', err)
        toast.error('Failed to load queue')
        setLoading(false)
      }
    )
    return () => unsubscribe()
  }, [doctorProfile])

  const active = bookings.find((b) => b.status === BOOKING_STATUS.ACTIVE)
  const pending = bookings.filter((b) => b.status === BOOKING_STATUS.PENDING)
  const served = bookings.filter((b) => b.status === BOOKING_STATUS.SERVED)
  const lastServed = served.length > 0 ? served[served.length - 1] : null
  const avgServiceTime = calculateAvgServiceTime(bookings)

  const handleDoneAndNext = async () => {
    try {
      // Mark current active as served
      if (active) {
        await update(COLLECTIONS.BOOKINGS, active.id, {
          status: BOOKING_STATUS.SERVED,
          servedAt: new Date().toISOString(),
        })
      }
      // Activate next pending token
      if (pending.length > 0) {
        const next = pending[0]
        await update(COLLECTIONS.BOOKINGS, next.id, {
          status: BOOKING_STATUS.ACTIVE,
          calledAt: new Date().toISOString(),
        })
        toast.success(`Token #${next.tokenNumber} now called`)
      } else if (active) {
        toast.success('Patient marked as served. No one else in queue.')
      } else {
        toast('No patients in queue', { icon: 'ℹ️' })
      }
    } catch (err) {
      toast.error('Action failed')
      console.error(err)
    }
  }

  const handleNoShow = async () => {
    if (!active) return
    if (!confirm(`Mark token #${active.tokenNumber} (${active.patientName}) as no-show?`)) return
    try {
      await update(COLLECTIONS.BOOKINGS, active.id, {
        status: BOOKING_STATUS.NO_SHOW,
      })
      // Auto-call next
      if (pending.length > 0) {
        const next = pending[0]
        await update(COLLECTIONS.BOOKINGS, next.id, {
          status: BOOKING_STATUS.ACTIVE,
          calledAt: new Date().toISOString(),
        })
      }
      toast.success('Marked as no-show')
    } catch (err) {
      toast.error('Failed')
    }
  }

  const handleRecall = async () => {
    if (!lastServed) {
      toast('No served patient to recall', { icon: 'ℹ️' })
      return
    }
    try {
      // Move current active back to pending (if exists)
      if (active) {
        await update(COLLECTIONS.BOOKINGS, active.id, {
          status: BOOKING_STATUS.PENDING,
        })
      }
      // Bring last served back to active
      await update(COLLECTIONS.BOOKINGS, lastServed.id, {
        status: BOOKING_STATUS.ACTIVE,
        calledAt: new Date().toISOString(),
      })
      toast.success(`Recalled token #${lastServed.tokenNumber}`)
    } catch (err) {
      toast.error('Failed to recall')
    }
  }

  const handleSignOut = async () => {
    await signOut()
    navigate('/login')
  }

  const timeString = time.toLocaleTimeString('en-US', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: true,
  })

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-emerald-900 via-teal-900 to-emerald-800 text-white flex items-center justify-center">
        <p className="text-xl">Loading your queue...</p>
      </div>
    )
  }

  // Doctor profile not found (admin needs to link their account to a doctor record)
  if (!doctorProfile) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-emerald-900 via-teal-900 to-emerald-800 text-white p-6 flex items-center justify-center">
        <div className="bg-white/10 backdrop-blur rounded-2xl p-8 max-w-md w-full text-center">
          <AlertCircle size={48} className="mx-auto mb-4 text-amber-300" />
          <h1 className="text-2xl font-bold mb-2">Profile not linked</h1>
          <p className="text-emerald-100 mb-6">
            Your doctor profile hasn't been set up yet. Please ask the
            administrator to add your email <strong>{user?.email}</strong> to
            your doctor record in the system.
          </p>
          <button
            onClick={handleSignOut}
            className="bg-white/20 hover:bg-white/30 px-6 py-2 rounded-lg font-medium transition"
          >
            Sign out
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-emerald-900 via-teal-900 to-emerald-800 text-white">
      {/* Header */}
      <header className="px-4 md:px-8 py-4 border-b border-white/10 flex items-center justify-between flex-wrap gap-3">
        <div className="flex items-center gap-3 min-w-0">
          <div className="w-10 h-10 bg-white/15 rounded-full flex items-center justify-center flex-shrink-0">
            <Stethoscope size={20} />
          </div>
          <div className="min-w-0">
            <h1 className="font-bold text-lg md:text-xl truncate">
              Dr. {doctorProfile.name}
            </h1>
            <p className="text-emerald-200 text-xs md:text-sm truncate">
              {doctorProfile.specialty}
              {hospital ? ` · ${hospital.name}` : ''}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <p className="text-2xl md:text-3xl font-bold tabular-nums">
            {timeString}
          </p>
          <button
            onClick={() => navigate('/account-settings')}
            className="p-2 hover:bg-white/10 rounded-lg text-emerald-200 hover:text-white transition"
            title="Account settings"
          >
            <Settings size={20} />
          </button>
          <button
            onClick={handleSignOut}
            className="p-2 hover:bg-white/10 rounded-lg text-emerald-200 hover:text-white transition"
            title="Sign out"
          >
            <LogOut size={20} />
          </button>
        </div>
      </header>

      <main className="px-4 md:px-8 py-6 max-w-4xl mx-auto">
        {/* Stats */}
        <div className="grid grid-cols-3 gap-3 mb-6">
          <Stat label="Waiting" value={pending.length} />
          <Stat label="Done today" value={served.length} />
          <Stat label="Avg time" value={`${avgServiceTime}m`} />
        </div>

        {/* Now Serving Card */}
        <div className="bg-white/10 backdrop-blur rounded-2xl p-6 md:p-8 mb-6 border border-white/10">
          <p className="text-emerald-200 text-sm uppercase tracking-wider font-medium mb-2">
            Now in consultation
          </p>
          {active ? (
            <div>
              <div className="flex items-baseline gap-6 mb-4 flex-wrap">
                <p className="text-7xl md:text-9xl font-black leading-none tabular-nums">
                  #{active.tokenNumber}
                </p>
                <div className="min-w-0 flex-1">
                  <p className="text-2xl md:text-4xl font-bold mb-2 break-words">
                    {active.patientName}
                  </p>
                  <div className="flex items-center gap-2 flex-wrap">
                    <span
                      className={`text-sm px-3 py-1 rounded-full ${bookingTypeColor[active.bookingType]}`}
                    >
                      {bookingTypeLabel[active.bookingType]}
                    </span>
                    {active.patientPhone && (
                      <span className="text-sm text-emerald-200 flex items-center gap-1">
                        <Phone size={12} />
                        {active.patientPhone}
                      </span>
                    )}
                  </div>
                </div>
              </div>

              {/* Action buttons */}
              <div className="grid grid-cols-2 gap-3">
                <button
                  onClick={handleDoneAndNext}
                  className="bg-emerald-500 hover:bg-emerald-400 active:bg-emerald-600 px-4 py-5 rounded-xl font-bold text-lg md:text-xl flex items-center justify-center gap-2 transition shadow-lg shadow-emerald-900/50"
                >
                  <Check size={24} /> Done — Call Next
                </button>
                <button
                  onClick={handleNoShow}
                  className="bg-red-500/80 hover:bg-red-500 active:bg-red-600 px-4 py-5 rounded-xl font-bold text-lg md:text-xl flex items-center justify-center gap-2 transition"
                >
                  <XIcon size={24} /> No-show
                </button>
              </div>
            </div>
          ) : (
            <div>
              <p className="text-emerald-200 text-xl mb-4">
                {pending.length === 0
                  ? 'No patients in queue right now'
                  : 'Ready to start with the next patient'}
              </p>
              {pending.length > 0 && (
                <button
                  onClick={handleDoneAndNext}
                  className="w-full bg-emerald-500 hover:bg-emerald-400 active:bg-emerald-600 px-4 py-5 rounded-xl font-bold text-lg md:text-xl flex items-center justify-center gap-2 transition shadow-lg shadow-emerald-900/50"
                >
                  Call First Patient <ChevronRight size={24} />
                </button>
              )}
            </div>
          )}
        </div>

        {/* Recall button (if there's someone served) */}
        {lastServed && (
          <button
            onClick={handleRecall}
            className="w-full bg-white/10 hover:bg-white/15 backdrop-blur border border-white/10 px-4 py-3 rounded-xl text-sm font-medium flex items-center justify-center gap-2 transition mb-6"
          >
            <RotateCcw size={16} /> Recall last patient (#{lastServed.tokenNumber} —{' '}
            {lastServed.patientName})
          </button>
        )}

        {/* Waiting list */}
        <div className="bg-white/5 backdrop-blur rounded-2xl p-4 md:p-6 border border-white/10">
          <h2 className="font-bold text-lg mb-4 flex items-center gap-2">
            <Clock size={18} />
            Up Next ({pending.length})
          </h2>

          {pending.length === 0 ? (
            <div className="text-center py-8">
              <Coffee className="mx-auto mb-2 text-emerald-300" size={32} />
              <p className="text-emerald-200">No one waiting. Take a break ☕</p>
            </div>
          ) : (
            <div className="space-y-2">
              {pending.map((b, idx) => {
                // Use stored time from booking creation, fallback if old booking
                const storedCallTime = b.expectedCallAt ? new Date(b.expectedCallAt) : null
                const fallbackCallTime = projectedCallTime(idx + 1, avgServiceTime)
                const callTime = storedCallTime || fallbackCallTime
                return (
                  <div
                    key={b.id}
                    className="bg-white/10 rounded-xl p-3 md:p-4 flex items-center gap-3"
                  >
                    <div className="w-12 h-12 md:w-14 md:h-14 bg-white/15 rounded-lg flex items-center justify-center font-black text-xl md:text-2xl tabular-nums flex-shrink-0">
                      {b.tokenNumber}
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="font-semibold text-base md:text-lg truncate flex items-center gap-2">
                        <User size={14} className="opacity-60 flex-shrink-0" />
                        {b.patientName}
                      </p>
                      <div className="flex items-center gap-2 mt-1 flex-wrap">
                        <span
                          className={`text-xs px-2 py-0.5 rounded ${bookingTypeColor[b.bookingType]}`}
                        >
                          {bookingTypeLabel[b.bookingType]}
                        </span>
                        <span className="text-xs text-emerald-200">
                          Expected {formatExpectedTime(callTime)}
                        </span>
                      </div>
                    </div>
                  </div>
                )
              })}
            </div>
          )}
        </div>

        {/* Footer info */}
        <p className="text-center text-emerald-300/60 text-xs mt-6">
          🔴 Live · Changes appear instantly across all screens
        </p>
      </main>
    </div>
  )
}

function Stat({ label, value }) {
  return (
    <div className="bg-white/10 backdrop-blur rounded-xl p-3 md:p-4 text-center border border-white/10">
      <p className="text-emerald-200 text-xs uppercase tracking-wider">
        {label}
      </p>
      <p className="text-2xl md:text-3xl font-bold mt-1 tabular-nums">{value}</p>
    </div>
  )
}