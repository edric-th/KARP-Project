import { useState, useEffect } from 'react'
import {
  collection,
  query,
  where,
  onSnapshot,
} from 'firebase/firestore'
import {
  ChevronRight,
  Check,
  X as XIcon,
  Clock,
  User,
  Phone,
  RotateCcw,
  CalendarDays,
  Coffee,
  Building2,
  Ticket,
} from 'lucide-react'
import toast from 'react-hot-toast'
import { db } from '../../lib/firebase'
import { subscribe, update, create } from '../../api/firestore'
import { useAuth } from '../../context/AuthContext'
import {
  COLLECTIONS,
  BOOKING_STATUS,
  BOOKING_SOURCE,
  RECEPTION_MINUTES_PER_TOKEN,
} from '../../constants'
import ConfirmModal from '../../components/ConfirmModal'
import { projectedCallTime, formatExpectedTime } from '../../lib/waitTime'

const todayString = () => {
  const d = new Date()
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

/**
 * Reception desk panel — the online-token (walk-in) queue for ONE hospital.
 * Online tokens are NOT tied to any doctor; the receptionist simply calls the
 * next token number. This mirrors the doctor queue but operates on bookings
 * where bookingSource === 'online_token' for the selected hospital.
 */
export default function Reception() {
  const { hospitalId: ownHospitalId } = useAuth()

  const [hospitals, setHospitals] = useState([])
  const [selectedHospitalId, setSelectedHospitalId] = useState('')
  const [tokens, setTokens] = useState([])
  const [loading, setLoading] = useState(true)
  const [noShowOpen, setNoShowOpen] = useState(false)
  const [acting, setActing] = useState(false)

  // Hospitals (admins pick one; receptionists are locked to their own).
  useEffect(() => {
    const unsub = subscribe(COLLECTIONS.HOSPITALS, (data) => {
      setHospitals(data)
      setSelectedHospitalId((prev) => {
        if (prev) return prev
        if (ownHospitalId && data.some((h) => h.id === ownHospitalId)) {
          return ownHospitalId
        }
        return data.length > 0 ? data[0].id : ''
      })
    })
    return () => unsub()
  }, [ownHospitalId])

  // Today's online tokens for the selected hospital. Single-field query +
  // in-memory filter/sort so no composite index is required.
  useEffect(() => {
    if (!selectedHospitalId) {
      setTokens([])
      setLoading(false)
      return
    }
    setLoading(true)
    const today = todayString()
    const q = query(
      collection(db, COLLECTIONS.BOOKINGS),
      where('hospitalId', '==', selectedHospitalId)
    )
    const unsubscribe = onSnapshot(
      q,
      (snap) => {
        const data = snap.docs
          .map((d) => ({ id: d.id, ...d.data() }))
          .filter(
            (b) =>
              b.bookingSource === BOOKING_SOURCE.ONLINE_TOKEN &&
              b.bookingDate === today
          )
          .sort((a, b) => (a.tokenNumber || 0) - (b.tokenNumber || 0))
        setTokens(data)
        setLoading(false)
      },
      (err) => {
        console.error('Reception listener error:', err)
        toast.error('Failed to load reception queue')
        setLoading(false)
      }
    )
    return () => unsubscribe()
  }, [selectedHospitalId])

  const selectedHospital = hospitals.find((h) => h.id === selectedHospitalId)
  const isLocked = !!ownHospitalId

  const active = tokens.find((b) => b.status === BOOKING_STATUS.ACTIVE)
  const pending = tokens.filter((b) => b.status === BOOKING_STATUS.PENDING)
  const served = tokens.filter((b) => b.status === BOOKING_STATUS.SERVED)
  const lastServed = served.length > 0 ? served[served.length - 1] : null

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
      `Reception is calling token #${next.tokenNumber} now${
        selectedHospital ? ` at ${selectedHospital.name}` : ''
      }. Please proceed to the desk.`
    )
    return next
  }

  const handleDoneAndNext = async () => {
    setActing(true)
    try {
      if (active) {
        await update(COLLECTIONS.BOOKINGS, active.id, {
          status: BOOKING_STATUS.SERVED,
          servedAt: new Date().toISOString(),
        })
        notifyPatient(
          active,
          'Token complete',
          `Your reception token #${active.tokenNumber} has been handled. Thank you!`
        )
      }
      const next = await callNextPending()
      if (next) toast.success(`Token #${next.tokenNumber} now called`)
      else if (active) toast.success('Token handled. No one else in queue.')
      else toast('No tokens in queue', { icon: 'ℹ️' })
    } catch (err) {
      toast.error('Action failed')
      console.error(err)
    } finally {
      setActing(false)
    }
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
        'Missed token',
        `Token #${active.tokenNumber} was marked as a no-show at reception. Please get a new token if needed.`,
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

  const handleRecall = async () => {
    if (!lastServed) {
      toast('No served token to recall', { icon: 'ℹ️' })
      return
    }
    try {
      if (active) {
        await update(COLLECTIONS.BOOKINGS, active.id, {
          status: BOOKING_STATUS.PENDING,
        })
      }
      await update(COLLECTIONS.BOOKINGS, lastServed.id, {
        status: BOOKING_STATUS.ACTIVE,
        calledAt: new Date().toISOString(),
      })
      notifyPatient(
        lastServed,
        "It's your turn!",
        `Token #${lastServed.tokenNumber} is being called again at reception. Please proceed.`
      )
      toast.success(`Recalled token #${lastServed.tokenNumber}`)
    } catch (err) {
      toast.error('Failed to recall')
    }
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6 flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold flex items-center gap-2">
            <Ticket size={22} className="text-primary-600" />
            Reception · Online Tokens
          </h1>
          <p className="text-gray-500 text-sm mt-1 flex items-center gap-1.5">
            <CalendarDays size={14} />
            {todayString()}
          </p>
        </div>
      </div>

      {/* Hospital selector / lock */}
      <div className="card mb-6">
        <label className="block text-sm font-medium mb-2 flex items-center gap-1.5">
          <Building2 size={16} className="text-gray-400" /> Hospital
        </label>
        {isLocked ? (
          <p className="font-semibold text-gray-900">
            {selectedHospital?.name || '—'}
          </p>
        ) : (
          <select
            value={selectedHospitalId}
            onChange={(e) => setSelectedHospitalId(e.target.value)}
            className="input"
          >
            {hospitals.length === 0 && <option value="">No hospitals</option>}
            {hospitals.map((h) => (
              <option key={h.id} value={h.id}>
                {h.name}
              </option>
            ))}
          </select>
        )}
      </div>

      {loading ? (
        <div className="card text-center text-gray-500">Loading reception queue…</div>
      ) : (
        <>
          {/* Stats */}
          <div className="grid grid-cols-3 gap-3 mb-6">
            <Stat label="Now serving" value={active ? `#${active.tokenNumber}` : '—'} />
            <Stat label="Waiting" value={pending.length} />
            <Stat label="Done today" value={served.length} />
          </div>

          {/* Now Serving Card */}
          <div className="card mb-6">
            <p className="text-gray-400 text-sm uppercase tracking-wider font-medium mb-3">
              Now at the desk
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
                    {active.patientPhone && (
                      <span className="text-sm text-gray-500 flex items-center gap-1">
                        <Phone size={12} />
                        {active.patientPhone}
                      </span>
                    )}
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <button
                    onClick={handleDoneAndNext}
                    disabled={acting}
                    className="bg-primary-600 hover:bg-primary-700 text-white px-4 py-4 rounded-xl font-bold text-lg flex items-center justify-center gap-2 transition disabled:opacity-50"
                  >
                    <Check size={22} /> Done — Call Next
                  </button>
                  <button
                    onClick={() => setNoShowOpen(true)}
                    disabled={acting}
                    className="bg-red-50 hover:bg-red-100 text-red-700 border border-red-200 px-4 py-4 rounded-xl font-bold text-lg flex items-center justify-center gap-2 transition disabled:opacity-50"
                  >
                    <XIcon size={22} /> No-show
                  </button>
                </div>
              </div>
            ) : (
              <div>
                <p className="text-gray-500 text-lg mb-4">
                  {pending.length === 0
                    ? 'No online tokens in the queue right now'
                    : 'Ready to call the next token'}
                </p>
                {pending.length > 0 && (
                  <button
                    onClick={handleDoneAndNext}
                    disabled={acting}
                    className="w-full bg-primary-600 hover:bg-primary-700 text-white px-4 py-4 rounded-xl font-bold text-lg flex items-center justify-center gap-2 transition disabled:opacity-50"
                  >
                    Call First Token <ChevronRight size={22} />
                  </button>
                )}
              </div>
            )}
          </div>

          {/* Recall */}
          {lastServed && (
            <button
              onClick={handleRecall}
              className="w-full bg-white hover:bg-gray-50 border border-gray-200 text-gray-700 px-4 py-3 rounded-xl text-sm font-medium flex items-center justify-center gap-2 transition mb-6"
            >
              <RotateCcw size={16} /> Recall last token (#{lastServed.tokenNumber} —{' '}
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
                <p className="text-gray-500">No one waiting at reception ☕</p>
              </div>
            ) : (
              <div className="space-y-2">
                {pending.map((b, idx) => {
                  const storedCallTime = b.expectedCallAt
                    ? new Date(b.expectedCallAt)
                    : null
                  const fallbackCallTime = projectedCallTime(
                    idx + 1,
                    RECEPTION_MINUTES_PER_TOKEN
                  )
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
                          {b.patientPhone && (
                            <span className="text-xs text-gray-500 flex items-center gap-1">
                              <Phone size={11} />
                              {b.patientPhone}
                            </span>
                          )}
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

          <p className="text-center text-gray-400 text-xs mt-6">
            🔴 Live · Online tokens are reception-only and not linked to any doctor
          </p>
        </>
      )}

      <ConfirmModal
        open={noShowOpen}
        title="Mark as no-show?"
        message={
          active
            ? `Token #${active.tokenNumber} · ${active.patientName} will be marked as a no-show and the next token called.`
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
