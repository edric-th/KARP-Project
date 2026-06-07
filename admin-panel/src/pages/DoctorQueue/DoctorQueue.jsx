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
import { subscribe, update, create } from '../../api/firestore'
import { useAuth } from '../../context/AuthContext'
import {
  calculateAvgServiceTime,
  estimateWaitMinutes,
  formatWaitTime,
  projectedCallTime,
  formatExpectedTime,
} from '../../lib/waitTime'
import { COLLECTIONS, BOOKING_STATUS, BOOKING_TYPES } from '../../constants'
import DiagnosisModal from '../../components/DiagnosisModal'
import ConfirmModal from '../../components/ConfirmModal'


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
  const [diagOpen, setDiagOpen] = useState(false)
  const [noShowOpen, setNoShowOpen] = useState(false)
  const [acting, setActing] = useState(false)
  const [view, setView] = useState('today') // 'today' | 'history'
  const [history, setHistory] = useState([])
  const [historyLoading, setHistoryLoading] = useState(false)

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

  // Served-visit history across all dates (single-field query → no composite
  // index; filter/sort in JS). Lazily subscribed only while viewing History.
  useEffect(() => {
    if (view !== 'history' || !doctorProfile?.id) return
    setHistoryLoading(true)
    const q = query(
      collection(db, COLLECTIONS.BOOKINGS),
      where('doctorId', '==', doctorProfile.id)
    )
    const unsub = onSnapshot(
      q,
      (snap) => {
        const data = snap.docs
          .map((d) => ({ id: d.id, ...d.data() }))
          .filter((b) => b.status === BOOKING_STATUS.SERVED)
          .sort((a, b) =>
            (b.servedAt || b.bookingDate || '').localeCompare(
              a.servedAt || a.bookingDate || ''
            )
          )
        setHistory(data)
        setHistoryLoading(false)
      },
      (err) => {
        console.error('History listener error:', err)
        setHistoryLoading(false)
      }
    )
    return () => unsub()
  }, [view, doctorProfile])

  const active = bookings.find((b) => b.status === BOOKING_STATUS.ACTIVE)
  const pending = bookings.filter((b) => b.status === BOOKING_STATUS.PENDING)
  const served = bookings.filter((b) => b.status === BOOKING_STATUS.SERVED)
  const lastServed = served.length > 0 ? served[served.length - 1] : null
  const avgServiceTime = calculateAvgServiceTime(bookings)

  // Push an in-app notification to the patient (no-op for walk-ins with no app account)
  const notifyPatient = async (booking, title, body, category = 'queue') => {
    if (!booking?.patientUid) return
    try {
      await create(COLLECTIONS.NOTIFICATIONS, {
        patientUid: booking.patientUid,
        title,
        body,
        category,
        relatedBookingId: booking.id,
        isRead: false,
      })
    } catch (err) {
      console.error('Failed to create notification', err)
    }
  }

  // Activate the next pending token (shared by the Done and No-show flows).
  const callNextPending = async () => {
    if (pending.length === 0) return null
    const next = pending[0]
    await update(COLLECTIONS.BOOKINGS, next.id, {
      status: BOOKING_STATUS.ACTIVE,
      calledAt: new Date().toISOString(),
    })
    notifyPatient(
      next,
      "It's your turn!",
      `You're being called now — token #${next.tokenNumber} with Dr. ${doctorProfile?.name || ''}. Please proceed.`
    )
    return next
  }

  // Mark the active consult served (with optional notes), then call the next.
  const finishDoneAndNext = async (diagnosis) => {
    setActing(true)
    try {
      if (active) {
        const patch = {
          status: BOOKING_STATUS.SERVED,
          servedAt: new Date().toISOString(),
        }
        if (diagnosis && diagnosis.trim()) patch.diagnosis = diagnosis.trim()
        await update(COLLECTIONS.BOOKINGS, active.id, patch)
        notifyPatient(
          active,
          'Consultation complete',
          `Your consultation (token #${active.tokenNumber}) is complete. Take care!`
        )
      }
      const next = await callNextPending()
      if (next) toast.success(`Token #${next.tokenNumber} now called`)
      else if (active) toast.success('Patient marked as served. No one else in queue.')
      else toast('No patients in queue', { icon: 'ℹ️' })
    } catch (err) {
      toast.error('Action failed')
      console.error(err)
    } finally {
      setActing(false)
      setDiagOpen(false)
    }
  }

  // "Done — Call Next": capture optional notes via a themed modal when serving.
  const handleDoneAndNext = () => {
    if (active) setDiagOpen(true)
    else finishDoneAndNext(null)
  }

  const confirmNoShow = async () => {
    if (!active) return
    setActing(true)
    try {
      await update(COLLECTIONS.BOOKINGS, active.id, {
        status: BOOKING_STATUS.NO_SHOW,
      })
      notifyPatient(
        active,
        'Missed appointment',
        `Token #${active.tokenNumber} was marked as a no-show. Please rebook if needed.`,
        'alert'
      )
      await callNextPending()
      toast.success('Marked as no-show')
    } catch (err) {
      toast.error('Failed')
    } finally {
      setActing(false)
      setNoShowOpen(false)
    }
  }

  const handleNoShow = () => {
    if (active) setNoShowOpen(true)
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
      notifyPatient(
        lastServed,
        "It's your turn!",
        `Token #${lastServed.tokenNumber} is being called again. Please proceed.`
      )
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

  const renderHistory = () => {
    if (historyLoading) {
      return (
        <div className="card text-center text-gray-500">Loading history…</div>
      )
    }
    if (history.length === 0) {
      return (
        <div className="card text-center py-10">
          <Coffee className="mx-auto mb-2 text-gray-300" size={32} />
          <p className="text-gray-500">No past consultations yet.</p>
        </div>
      )
    }
    const groups = {}
    for (const b of history) {
      const key =
        b.bookingDate || (b.servedAt ? b.servedAt.slice(0, 10) : 'Earlier')
      ;(groups[key] ||= []).push(b)
    }
    const dates = Object.keys(groups).sort((a, b) => b.localeCompare(a))
    return (
      <div className="space-y-6">
        {dates.map((date) => (
          <div key={date}>
            <h3 className="text-xs font-bold uppercase tracking-wider text-gray-400 mb-2">
              {date} · {groups[date].length} served
            </h3>
            <div className="card !p-0 divide-y divide-gray-100">
              {groups[date].map((b) => (
                <div key={b.id} className="p-4">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-primary-50 text-primary-700 rounded-lg flex items-center justify-center font-bold tabular-nums flex-shrink-0">
                      {b.tokenNumber}
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="font-semibold text-gray-900 truncate flex items-center gap-2">
                        <User size={14} className="text-gray-400 flex-shrink-0" />
                        {b.patientName}
                      </p>
                      <div className="mt-1">
                        <span
                          className={`text-xs px-2 py-0.5 rounded ${bookingTypeColor[b.bookingType] || 'bg-gray-100 text-gray-600'}`}
                        >
                          {bookingTypeLabel[b.bookingType] || b.bookingType}
                        </span>
                      </div>
                    </div>
                  </div>
                  {b.diagnosis && (
                    <div className="mt-2 bg-gray-50 rounded-lg p-3 text-sm text-gray-700">
                      <span className="block text-[10px] font-bold uppercase tracking-wider text-gray-400 mb-1">
                        Notes
                      </span>
                      {b.diagnosis}
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    )
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <p className="text-gray-500 text-lg">Loading your queue…</p>
      </div>
    )
  }

  // Doctor profile not found (admin needs to link their account to a doctor record)
  if (!doctorProfile) {
    return (
      <div className="min-h-screen bg-gray-50 p-6 flex items-center justify-center">
        <div className="card max-w-md w-full text-center">
          <AlertCircle size={48} className="mx-auto mb-4 text-amber-500" />
          <h1 className="text-2xl font-bold mb-2 text-gray-900">Profile not linked</h1>
          <p className="text-gray-600 mb-6">
            Your doctor profile hasn't been set up yet. Please ask the
            administrator to add your email <strong>{user?.email}</strong> to
            your doctor record in the system.
          </p>
          <button onClick={handleSignOut} className="btn-secondary">
            Sign out
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white border-b border-gray-200 px-4 md:px-8 py-4 flex items-center justify-between flex-wrap gap-3">
        <div className="flex items-center gap-3 min-w-0">
          <div className="w-10 h-10 bg-primary-50 text-primary-600 rounded-full flex items-center justify-center flex-shrink-0">
            <Stethoscope size={20} />
          </div>
          <div className="min-w-0">
            <h1 className="font-bold text-lg md:text-xl truncate text-gray-900">
              Dr. {doctorProfile.name}
            </h1>
            <p className="text-gray-500 text-xs md:text-sm truncate">
              {doctorProfile.specialty}
              {hospital ? ` · ${hospital.name}` : ''}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <p className="text-2xl md:text-3xl font-bold tabular-nums text-gray-900">
            {timeString}
          </p>
          <button
            onClick={() => navigate('/account-settings')}
            className="p-2 hover:bg-gray-100 rounded-lg text-gray-500 hover:text-gray-800 transition"
            title="Account settings"
          >
            <Settings size={20} />
          </button>
          <button
            onClick={handleSignOut}
            className="p-2 hover:bg-gray-100 rounded-lg text-gray-500 hover:text-red-600 transition"
            title="Sign out"
          >
            <LogOut size={20} />
          </button>
        </div>
      </header>

      <main className="px-4 md:px-8 py-6 max-w-4xl mx-auto">
        {/* Today / History toggle */}
        <div className="flex gap-1 mb-6 bg-white border border-gray-200 rounded-xl p-1 w-full max-w-xs">
          {[
            { id: 'today', label: "Today's Queue" },
            { id: 'history', label: 'History' },
          ].map((t) => (
            <button
              key={t.id}
              onClick={() => setView(t.id)}
              className={`flex-1 px-3 py-2 rounded-lg text-sm font-semibold transition ${
                view === t.id
                  ? 'bg-primary-600 text-white'
                  : 'text-gray-600 hover:bg-gray-100'
              }`}
            >
              {t.label}
            </button>
          ))}
        </div>

        {view === 'history' && renderHistory()}

        {view === 'today' && (
          <>
        {/* Stats */}
        <div className="grid grid-cols-3 gap-3 mb-6">
          <Stat label="Waiting" value={pending.length} />
          <Stat label="Done today" value={served.length} />
          <Stat label="Avg time" value={`${avgServiceTime}m`} />
        </div>

        {/* Now Serving Card */}
        <div className="card mb-6">
          <p className="text-gray-400 text-sm uppercase tracking-wider font-medium mb-3">
            Now in consultation
          </p>
          {active ? (
            <div>
              <div className="flex items-baseline gap-6 mb-5 flex-wrap">
                <p className="text-7xl md:text-8xl font-black leading-none tabular-nums text-primary-600">
                  #{active.tokenNumber}
                </p>
                <div className="min-w-0 flex-1">
                  <p className="text-2xl md:text-3xl font-bold mb-2 break-words text-gray-900">
                    {active.patientName}
                  </p>
                  <div className="flex items-center gap-2 flex-wrap">
                    <span
                      className={`text-sm px-3 py-1 rounded-full ${bookingTypeColor[active.bookingType]}`}
                    >
                      {bookingTypeLabel[active.bookingType]}
                    </span>
                    {active.patientPhone && (
                      <span className="text-sm text-gray-500 flex items-center gap-1">
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
                  className="bg-primary-600 hover:bg-primary-700 text-white px-4 py-4 rounded-xl font-bold text-lg flex items-center justify-center gap-2 transition"
                >
                  <Check size={22} /> Done — Call Next
                </button>
                <button
                  onClick={handleNoShow}
                  className="bg-red-50 hover:bg-red-100 text-red-700 border border-red-200 px-4 py-4 rounded-xl font-bold text-lg flex items-center justify-center gap-2 transition"
                >
                  <XIcon size={22} /> No-show
                </button>
              </div>
            </div>
          ) : (
            <div>
              <p className="text-gray-500 text-lg mb-4">
                {pending.length === 0
                  ? 'No patients in queue right now'
                  : 'Ready to start with the next patient'}
              </p>
              {pending.length > 0 && (
                <button
                  onClick={handleDoneAndNext}
                  className="w-full bg-primary-600 hover:bg-primary-700 text-white px-4 py-4 rounded-xl font-bold text-lg flex items-center justify-center gap-2 transition"
                >
                  Call First Patient <ChevronRight size={22} />
                </button>
              )}
            </div>
          )}
        </div>

        {/* Recall button (if there's someone served) */}
        {lastServed && (
          <button
            onClick={handleRecall}
            className="w-full bg-white hover:bg-gray-50 border border-gray-200 text-gray-700 px-4 py-3 rounded-xl text-sm font-medium flex items-center justify-center gap-2 transition mb-6"
          >
            <RotateCcw size={16} /> Recall last patient (#{lastServed.tokenNumber} —{' '}
            {lastServed.patientName})
          </button>
        )}

        {/* Waiting list */}
        <div className="card">
          <h2 className="font-bold text-lg mb-4 flex items-center gap-2 text-gray-900">
            <Clock size={18} className="text-primary-600" />
            Up Next ({pending.length})
          </h2>

          {pending.length === 0 ? (
            <div className="text-center py-8">
              <Coffee className="mx-auto mb-2 text-gray-300" size={32} />
              <p className="text-gray-500">No one waiting. Take a break ☕</p>
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
                    className="bg-gray-50 border border-gray-100 rounded-xl p-3 md:p-4 flex items-center gap-3"
                  >
                    <div className="w-12 h-12 md:w-14 md:h-14 bg-primary-50 text-primary-700 rounded-lg flex items-center justify-center font-black text-xl md:text-2xl tabular-nums flex-shrink-0">
                      {b.tokenNumber}
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="font-semibold text-base md:text-lg truncate flex items-center gap-2 text-gray-900">
                        <User size={14} className="text-gray-400 flex-shrink-0" />
                        {b.patientName}
                      </p>
                      <div className="flex items-center gap-2 mt-1 flex-wrap">
                        <span
                          className={`text-xs px-2 py-0.5 rounded ${bookingTypeColor[b.bookingType]}`}
                        >
                          {bookingTypeLabel[b.bookingType]}
                        </span>
                        <span className="text-xs text-gray-500">
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
          </>
        )}

        {/* Footer info */}
        <p className="text-center text-gray-400 text-xs mt-6">
          🔴 Live · Changes appear instantly across all screens
        </p>
      </main>

      <DiagnosisModal
        open={diagOpen}
        tokenNumber={active?.tokenNumber}
        patientName={active?.patientName}
        initialValue={active?.diagnosis || ''}
        busy={acting}
        submitLabel="Save & call next"
        skipLabel="Skip & call next"
        onSubmit={(notes) => finishDoneAndNext(notes)}
        onSkip={() => finishDoneAndNext(null)}
        onClose={() => !acting && setDiagOpen(false)}
      />
      <ConfirmModal
        open={noShowOpen}
        title="Mark as no-show?"
        message={
          active
            ? `Token #${active.tokenNumber} · ${active.patientName} will be marked as a no-show and the next patient called.`
            : ''
        }
        confirmLabel="Mark no-show"
        danger
        busy={acting}
        onConfirm={confirmNoShow}
        onClose={() => !acting && setNoShowOpen(false)}
      />
    </div>
  )
}

function Stat({ label, value }) {
  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-4 text-center">
      <p className="text-gray-400 text-xs uppercase tracking-wider">{label}</p>
      <p className="text-2xl md:text-3xl font-bold mt-1 tabular-nums text-gray-900">
        {value}
      </p>
    </div>
  )
}