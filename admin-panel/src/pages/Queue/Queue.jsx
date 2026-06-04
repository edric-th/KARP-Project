import { useState, useEffect } from 'react'
import {
  collection,
  query,
  where,
  orderBy,
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
  Plus,
  Monitor,
} from 'lucide-react'
import toast from 'react-hot-toast'
import { db } from '../../lib/firebase'
import { subscribe, update, create } from '../../api/firestore'
import { COLLECTIONS, BOOKING_STATUS, BOOKING_TYPES } from '../../constants'
import PhoneInput from '../../components/PhoneInput'
import DiagnosisModal from '../../components/DiagnosisModal'
import ConfirmModal from '../../components/ConfirmModal'
import {
  calculateAvgServiceTime,
  estimateWaitMinutes,
  formatWaitTime,
  projectedCallTime,
  formatExpectedTime,
} from '../../lib/waitTime'

const todayString = () => {
  const d = new Date()
  const yyyy = d.getFullYear()
  const mm = String(d.getMonth() + 1).padStart(2, '0')
  const dd = String(d.getDate()).padStart(2, '0')
  return `${yyyy}-${mm}-${dd}`
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

export default function Queue() {
  const [doctors, setDoctors] = useState([])
  const [hospitals, setHospitals] = useState([])
  const [selectedDoctorId, setSelectedDoctorId] = useState('')
  const [bookings, setBookings] = useState([])
  const [loading, setLoading] = useState(true)
  const [showBookingModal, setShowBookingModal] = useState(false)
  const [diagBooking, setDiagBooking] = useState(null)
  const [noShowBooking, setNoShowBooking] = useState(null)
  const [acting, setActing] = useState(false)

  useEffect(() => {
    const unsubDoctors = subscribe(COLLECTIONS.DOCTORS, (data) => {
      setDoctors(data)
      if (data.length > 0) {
        setSelectedDoctorId((prev) => prev || data[0].id)
      }
    })
    const unsubHospitals = subscribe(COLLECTIONS.HOSPITALS, setHospitals)
    return () => {
      unsubDoctors()
      unsubHospitals()
    }
  }, [])

  useEffect(() => {
    if (!selectedDoctorId) {
      setBookings([])
      setLoading(false)
      return
    }
    setLoading(true)
    const today = todayString()
    const q = query(
      collection(db, COLLECTIONS.BOOKINGS),
      where('doctorId', '==', selectedDoctorId),
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
  }, [selectedDoctorId])

  const selectedDoctor = doctors.find((d) => d.id === selectedDoctorId)
  const selectedHospital = hospitals.find(
    (h) => h.id === selectedDoctor?.hospitalId
  )

  const active = bookings.find((b) => b.status === BOOKING_STATUS.ACTIVE)
  const pending = bookings.filter((b) => b.status === BOOKING_STATUS.PENDING)
  const served = bookings.filter((b) => b.status === BOOKING_STATUS.SERVED)
  const noShow = bookings.filter((b) => b.status === BOOKING_STATUS.NO_SHOW)

  // Calculate average service time for this doctor's queue
  const avgServiceTime = calculateAvgServiceTime(bookings)
  
  // Calculate next token number for this doctor today
  const nextTokenNumber =
    bookings.length === 0
      ? 1
      : Math.max(...bookings.map((b) => b.tokenNumber)) + 1

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

  const callNext = async () => {
    if (active) {
      await update(COLLECTIONS.BOOKINGS, active.id, {
        status: BOOKING_STATUS.SERVED,
        servedAt: new Date().toISOString(),
      })
      notifyPatient(
        active,
        'Consultation complete',
        `Your consultation (token #${active.tokenNumber}) is complete. Take care!`
      )
    }
    if (pending.length > 0) {
      const next = pending[0]
      await update(COLLECTIONS.BOOKINGS, next.id, {
        status: BOOKING_STATUS.ACTIVE,
        calledAt: new Date().toISOString(),
      })
      notifyPatient(
        next,
        "It's your turn!",
        `You're being called now — token #${next.tokenNumber} with Dr. ${selectedDoctor?.name || ''}. Please proceed.`
      )
      toast.success(`Token #${next.tokenNumber} called`)
    } else if (active) {
      toast.success('All tokens served')
    } else {
      toast('No pending tokens', { icon: 'ℹ️' })
    }
  }

  // Open the themed notes modal; the actual write happens in confirmServed.
  const markServed = (booking) => setDiagBooking(booking)

  const confirmServed = async (diagnosis) => {
    if (!diagBooking) return
    setActing(true)
    try {
      const patch = {
        status: BOOKING_STATUS.SERVED,
        servedAt: new Date().toISOString(),
      }
      if (diagnosis && diagnosis.trim()) patch.diagnosis = diagnosis.trim()
      await update(COLLECTIONS.BOOKINGS, diagBooking.id, patch)
      notifyPatient(
        diagBooking,
        'Consultation complete',
        `Your consultation (token #${diagBooking.tokenNumber}) is complete. Take care!`
      )
      toast.success(`Token #${diagBooking.tokenNumber} marked served`)
    } catch (err) {
      toast.error('Action failed')
      console.error(err)
    } finally {
      setActing(false)
      setDiagBooking(null)
    }
  }

  const markNoShow = (booking) => setNoShowBooking(booking)

  const confirmNoShow = async () => {
    if (!noShowBooking) return
    setActing(true)
    try {
      await update(COLLECTIONS.BOOKINGS, noShowBooking.id, {
        status: BOOKING_STATUS.NO_SHOW,
      })
      notifyPatient(
        noShowBooking,
        'Missed appointment',
        `Token #${noShowBooking.tokenNumber} was marked as a no-show. Please rebook if needed.`,
        'alert'
      )
      toast.success(`Token #${noShowBooking.tokenNumber} marked as no-show`)
    } catch (err) {
      toast.error('Failed')
    } finally {
      setActing(false)
      setNoShowBooking(null)
    }
  }

  const recallToken = async (booking) => {
    await update(COLLECTIONS.BOOKINGS, booking.id, {
      status: BOOKING_STATUS.ACTIVE,
      calledAt: new Date().toISOString(),
    })
    notifyPatient(
      booking,
      "It's your turn!",
      `Token #${booking.tokenNumber} is being called again. Please proceed.`
    )
    toast.success(`Token #${booking.tokenNumber} re-called`)
  }

  if (doctors.length === 0) {
    return (
      <div>
        <h1 className="text-2xl font-bold mb-6">Live Queue</h1>
        <div className="card text-center py-12">
          <p className="text-gray-500">
            No doctors available. Please add doctors first.
          </p>
        </div>
      </div>
    )
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6 flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold">Live Queue</h1>
          <p className="text-gray-500 text-sm mt-1 flex items-center gap-1.5">
            <CalendarDays size={14} />
            {todayString()}
          </p>
        </div>
        <div className="flex gap-2 flex-wrap">
          {selectedDoctorId && (
            <a
              href={`/board/${selectedDoctorId}`}
              target="_blank"
              rel="noopener noreferrer"
              className="btn-secondary flex items-center gap-2"
            >
              <Monitor size={18} /> Open Board
            </a>
          )}
          <button
            onClick={() => setShowBookingModal(true)}
            className="btn-primary flex items-center gap-2"
          >
            <Plus size={18} /> New Booking
          </button>
        </div>
      </div>

      <div className="card mb-6">
        <label className="block text-sm font-medium mb-2">Select Doctor</label>
        <select
          value={selectedDoctorId}
          onChange={(e) => setSelectedDoctorId(e.target.value)}
          className="input"
        >
          {doctors.map((d) => (
            <option key={d.id} value={d.id}>
              Dr. {d.name} {d.specialty ? `— ${d.specialty}` : ''}
            </option>
          ))}
        </select>
        {selectedHospital && (
          <p className="text-sm text-gray-500 mt-2">{selectedHospital.name}</p>
        )}
      </div>

      {loading ? (
        <div className="card text-center text-gray-500">Loading queue...</div>
      ) : (
        <>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mb-6">
            <StatCard label="Now Serving" value={active ? `#${active.tokenNumber}` : '—'} color="green" />
            <StatCard label="Waiting" value={pending.length} color="blue" />
            <StatCard label="Avg time / patient" value={`${avgServiceTime}m`} color="purple" />
            <StatCard label="Served" value={served.length} color="gray" />
          </div>

          <div className="card mb-6 bg-gradient-to-r from-primary-50 to-blue-50 border-primary-200">
            <div className="flex items-center justify-between flex-wrap gap-4">
              <div>
                <p className="text-sm font-medium text-primary-700">Now Serving</p>
                {active ? (
                  <div className="mt-2">
                    <p className="text-4xl font-bold">#{active.tokenNumber}</p>
                    <p className="text-gray-700 mt-1">{active.patientName}</p>
                    <span
                      className={`inline-block text-xs px-2 py-0.5 rounded mt-1 ${bookingTypeColor[active.bookingType]}`}
                    >
                      {bookingTypeLabel[active.bookingType]}
                    </span>
                  </div>
                ) : (
                  <p className="text-gray-500 mt-2">No active token</p>
                )}
              </div>
              <div className="flex gap-2">
                {active && (
                  <>
                    <button
                      onClick={() => markServed(active)}
                      className="px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg font-medium flex items-center gap-2"
                    >
                      <Check size={18} /> Mark Served
                    </button>
                    <button
                      onClick={() => markNoShow(active)}
                      className="px-4 py-2 bg-red-100 hover:bg-red-200 text-red-700 rounded-lg font-medium flex items-center gap-2"
                    >
                      <XIcon size={18} /> No-show
                    </button>
                  </>
                )}
                <button
                  onClick={callNext}
                  disabled={pending.length === 0 && !active}
                  className="btn-primary flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Call Next <ChevronRight size={18} />
                </button>
              </div>
            </div>
          </div>

          <div className="card mb-6">
            <h2 className="font-bold mb-4 flex items-center gap-2">
              <Clock size={18} /> Waiting ({pending.length})
            </h2>
            {pending.length === 0 ? (
              <p className="text-gray-500 text-sm text-center py-6">
                No one waiting
              </p>
            ) : (
              <div className="divide-y">
                {pending.map((b, idx) => (
                  <BookingRow
                    key={b.id}
                    booking={b}
                    position={idx + 1}
                    avgServiceTime={avgServiceTime}
                    showWaitTime
                    onMarkServed={markServed}
                    onMarkNoShow={markNoShow}
                  />
                ))}
              </div>
            )}
          </div>

          {served.length > 0 && (
            <div className="card mb-6">
              <h2 className="font-bold mb-4 flex items-center gap-2">
                <Check size={18} /> Served ({served.length})
              </h2>
              <div className="divide-y">
                {served.map((b) => (
                  <BookingRow
                    key={b.id}
                    booking={b}
                    completed
                    onRecall={recallToken}
                  />
                ))}
              </div>
            </div>
          )}

          {noShow.length > 0 && (
            <div className="card">
              <h2 className="font-bold mb-4 flex items-center gap-2 text-red-700">
                <XIcon size={18} /> No-show ({noShow.length})
              </h2>
              <div className="divide-y">
                {noShow.map((b) => (
                  <BookingRow
                    key={b.id}
                    booking={b}
                    completed
                    onRecall={recallToken}
                  />
                ))}
              </div>
            </div>
          )}
        </>
      )}

      {showBookingModal && (
        <NewBookingModal
          doctor={selectedDoctor}
          hospital={selectedHospital}
          nextTokenNumber={nextTokenNumber}
          pendingCount={pending.length}
          avgServiceTime={avgServiceTime}
          onClose={() => setShowBookingModal(false)}
        />
      )}

      <DiagnosisModal
        open={!!diagBooking}
        tokenNumber={diagBooking?.tokenNumber}
        patientName={diagBooking?.patientName}
        initialValue={diagBooking?.diagnosis || ''}
        busy={acting}
        onSubmit={(notes) => confirmServed(notes)}
        onSkip={() => confirmServed(null)}
        onClose={() => !acting && setDiagBooking(null)}
      />
      <ConfirmModal
        open={!!noShowBooking}
        title="Mark as no-show?"
        message={
          noShowBooking
            ? `Token #${noShowBooking.tokenNumber} · ${noShowBooking.patientName} will be marked as a no-show.`
            : ''
        }
        confirmLabel="Mark no-show"
        danger
        busy={acting}
        onConfirm={confirmNoShow}
        onClose={() => !acting && setNoShowBooking(null)}
      />
    </div>
  )
}

// ---------- New Booking Modal ----------

function NewBookingModal({ doctor, hospital, nextTokenNumber, pendingCount, avgServiceTime, onClose }) {
  const [formData, setFormData] = useState({
    patientName: '',
    patientPhone: '',
    bookingType: BOOKING_TYPES.FIRST_VISIT,
  })
  const [saving, setSaving] = useState(false)

  const handleChange = (field) => (e) => {
    setFormData({ ...formData, [field]: e.target.value })
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!formData.patientName.trim()) {
      toast.error('Patient name is required')
      return
    }
    setSaving(true)
    try {
      // Calculate expected call time AT BOOKING MOMENT and lock it in
      // Position = number of people ahead + 1 (yourself)
      const positionInQueue = pendingCount + 1
      const expectedCallAt = projectedCallTime(positionInQueue, avgServiceTime)

      await create(COLLECTIONS.BOOKINGS, {
        doctorId: doctor.id,
        doctorName: doctor.name,
        hospitalId: doctor.hospitalId,
        hospitalName: hospital?.name || '',
        patientName: formData.patientName.trim(),
        patientPhone: formData.patientPhone.trim(),
        bookingType: formData.bookingType,
        status: BOOKING_STATUS.PENDING,
        tokenNumber: nextTokenNumber,
        bookingDate: todayString(),
        expectedCallAt: expectedCallAt.toISOString(),
        estimatedWaitMinutes: positionInQueue * avgServiceTime,
      })
      toast.success(`Token #${nextTokenNumber} created · Expected around ${formatExpectedTime(expectedCallAt)}`)
      onClose()
    } catch (err) {
      toast.error('Failed to create booking')
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
            <h2 className="text-xl font-bold">New Booking</h2>
            <p className="text-sm text-gray-500 mt-1">
              Token #{nextTokenNumber} · Dr. {doctor?.name}
            </p>
          </div>
          <button onClick={onClose} className="p-1 hover:bg-gray-100 rounded">
            <XIcon size={20} />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1">
              Patient Name <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              required
              className="input"
              value={formData.patientName}
              onChange={handleChange('patientName')}
              placeholder="e.g. Ramesh Thapa"
              autoFocus
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Phone Number</label>
            <PhoneInput
              value={formData.patientPhone}
              onChange={(val) => setFormData({ ...formData, patientPhone: val })}
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">Booking Type</label>
            <div className="grid grid-cols-3 gap-2">
              {Object.entries(bookingTypeLabel).map(([value, label]) => (
                <button
                  key={value}
                  type="button"
                  onClick={() => setFormData({ ...formData, bookingType: value })}
                  className={`px-3 py-2 rounded-lg text-sm font-medium border-2 transition ${
                    formData.bookingType === value
                      ? 'border-primary-600 bg-primary-50 text-primary-700'
                      : 'border-gray-200 text-gray-700 hover:border-gray-300'
                  }`}
                >
                  {label}
                </button>
              ))}
            </div>
          </div>

          <div className="bg-blue-50 rounded-lg p-3 text-sm text-blue-800">
            This patient will be added to the queue as token{' '}
            <strong>#{nextTokenNumber}</strong> for today.
          </div>

          <div className="flex gap-3 pt-2">
            <button type="button" onClick={onClose} className="btn-secondary flex-1">
              Cancel
            </button>
            <button type="submit" disabled={saving} className="btn-primary flex-1">
              {saving ? 'Creating...' : 'Create Booking'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ---------- Small components ----------

function StatCard({ label, value, color }) {
  const colors = {
    green: 'bg-green-50 text-green-700',
    blue: 'bg-blue-50 text-blue-700',
    gray: 'bg-gray-100 text-gray-700',
    red: 'bg-red-50 text-red-700',
    purple: 'bg-purple-50 text-purple-700',
  }
  return (
    <div className={`rounded-xl p-4 ${colors[color]}`}>
      <p className="text-xs font-medium opacity-80">{label}</p>
      <p className="text-2xl font-bold mt-1">{value}</p>
    </div>
  )
}

function BookingRow({ booking, position, completed, avgServiceTime, showWaitTime, onMarkServed, onMarkNoShow, onRecall }) {
  const waitMinutes = showWaitTime && position && avgServiceTime
    ? estimateWaitMinutes(position - 1, avgServiceTime)
    : null
  return (
    <div className="py-3 flex items-center justify-between gap-4">
      <div className="flex items-center gap-3 min-w-0 flex-1">
        <div className="w-10 h-10 bg-gray-100 rounded-lg flex items-center justify-center font-bold text-gray-700 flex-shrink-0">
          #{booking.tokenNumber}
        </div>
        <div className="min-w-0 flex-1">
          <p className="font-medium truncate flex items-center gap-2">
            <User size={14} className="text-gray-400 flex-shrink-0" />
            {booking.patientName}
          </p>
          <div className="flex items-center gap-2 mt-0.5 flex-wrap">
            {booking.patientPhone && (
              <span className="text-xs text-gray-500 flex items-center gap-1">
                <Phone size={11} />
                {booking.patientPhone}
              </span>
            )}
            <span
              className={`text-xs px-2 py-0.5 rounded ${bookingTypeColor[booking.bookingType] || 'bg-gray-100'}`}
            >
              {bookingTypeLabel[booking.bookingType] || booking.bookingType}
            </span>
            {position && (
              <span className="text-xs text-gray-500">
                Position {position}
              </span>
            )}
            {waitMinutes !== null && (
              <span className="text-xs text-purple-700 bg-purple-50 px-2 py-0.5 rounded font-medium">
                ⏱ {formatWaitTime(waitMinutes)}
              </span>
            )}
          </div>
        </div>
      </div>
      <div className="flex gap-1 flex-shrink-0">
        {!completed && (
          <>
            <button
              onClick={() => onMarkServed(booking)}
              className="p-2 text-green-600 hover:bg-green-50 rounded"
              title="Mark served"
            >
              <Check size={16} />
            </button>
            <button
              onClick={() => onMarkNoShow(booking)}
              className="p-2 text-red-600 hover:bg-red-50 rounded"
              title="Mark no-show"
            >
              <XIcon size={16} />
            </button>
          </>
        )}
        {completed && onRecall && (
          <button
            onClick={() => onRecall(booking)}
            className="p-2 text-gray-600 hover:bg-gray-100 rounded text-xs flex items-center gap-1"
            title="Re-call"
          >
            <RotateCcw size={14} /> Recall
          </button>
        )}
      </div>
    </div>
  )
}