import { useState, useEffect } from 'react'
import { useParams } from 'react-router-dom'
import {
  collection,
  query,
  where,
  orderBy,
  onSnapshot,
} from 'firebase/firestore'
import { db } from '../../lib/firebase'
import { COLLECTIONS, BOOKING_STATUS, BOOKING_TYPES } from '../../constants'
import { subscribe } from '../../api/firestore'
import LiveDot from '../../components/ui/LiveDot'
import {
  calculateAvgServiceTime,
  estimateWaitMinutes,
  formatWaitTime,
  projectedCallTime,
  formatExpectedTime,
} from '../../lib/waitTime'

const todayString = () => {
  const d = new Date()
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

const bookingTypeLabel = {
  [BOOKING_TYPES.FIRST_VISIT]: 'First Visit',
  [BOOKING_TYPES.FOLLOW_UP]: 'Follow-up',
  [BOOKING_TYPES.REPORT]: 'Show Report',
}

export default function Board() {
  const { doctorId } = useParams()
  const [doctor, setDoctor] = useState(null)
  const [hospital, setHospital] = useState(null)
  const [bookings, setBookings] = useState([])
  const [loading, setLoading] = useState(true)
  const [time, setTime] = useState(new Date())

  // Live clock
  useEffect(() => {
    const interval = setInterval(() => setTime(new Date()), 1000)
    return () => clearInterval(interval)
  }, [])

  // Load doctor and hospital info
  useEffect(() => {
    const unsubDoctors = subscribe(COLLECTIONS.DOCTORS, (data) => {
      const found = data.find((d) => d.id === doctorId)
      setDoctor(found || null)
    })
    return () => unsubDoctors()
  }, [doctorId])

  useEffect(() => {
    if (!doctor?.hospitalId) return
    const unsubHospitals = subscribe(COLLECTIONS.HOSPITALS, (data) => {
      const found = data.find((h) => h.id === doctor.hospitalId)
      setHospital(found || null)
    })
    return () => unsubHospitals()
  }, [doctor])

  // Live queue for this doctor today
  useEffect(() => {
    if (!doctorId) {
      setLoading(false)
      return
    }
    const today = todayString()
    const q = query(
      collection(db, COLLECTIONS.BOOKINGS),
      where('doctorId', '==', doctorId),
      where('bookingDate', '==', today),
      orderBy('tokenNumber', 'asc')
    )
    const unsubscribe = onSnapshot(q, (snap) => {
      const data = snap.docs.map((d) => ({ id: d.id, ...d.data() }))
      setBookings(data)
      setLoading(false)
    })
    return () => unsubscribe()
  }, [doctorId])

  const active = bookings.find((b) => b.status === BOOKING_STATUS.ACTIVE)
  const pending = bookings.filter((b) => b.status === BOOKING_STATUS.PENDING)
  const upNext = pending.slice(0, 5)
  const avgServiceTime = calculateAvgServiceTime(bookings)

  // Format patient name with privacy (first name + last initial)
  const formatName = (name) => {
    if (!name) return '—'
    const parts = name.trim().split(' ')
    if (parts.length === 1) return parts[0]
    return `${parts[0]} ${parts[parts.length - 1][0]}.`
  }

  const timeString = time.toLocaleTimeString('en-US', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: true,
  })

  const dateString = time.toLocaleDateString('en-US', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  })

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-900 via-blue-800 to-indigo-900 flex items-center justify-center text-white text-2xl">
        Loading queue...
      </div>
    )
  }

  if (!doctor) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-900 via-blue-800 to-indigo-900 flex items-center justify-center text-white text-2xl">
        Doctor not found
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-900 via-blue-800 to-indigo-900 text-white">
      {/* Header */}
      <header className="p-6 md:p-8 border-b border-white/10">
        <div className="flex items-center justify-between flex-wrap gap-4">
          <div>
            <h1 className="text-3xl md:text-5xl font-bold">
              Dr. {doctor.name}
            </h1>
            <p className="text-blue-200 text-lg md:text-xl mt-2">
              {doctor.specialty}
              {hospital && ` · ${hospital.name}`}
            </p>
          </div>
          <div className="text-right">
            <p className="text-4xl md:text-6xl font-bold tabular-nums">
              {timeString}
            </p>
            <p className="text-blue-200 text-base md:text-lg mt-1">
              {dateString}
            </p>
          </div>
        </div>
      </header>

      {/* Main: Now Serving */}
      <section className="p-6 md:p-12">
        <p className="text-blue-200 text-xl md:text-2xl uppercase tracking-wider font-medium mb-4">
          Now Serving
        </p>
        {active ? (
          <div className="flex items-baseline gap-6 md:gap-12 flex-wrap">
            <div className="text-[10rem] md:text-[16rem] font-black leading-none tabular-nums">
              {active.tokenNumber}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-3xl md:text-5xl font-bold mb-3">
                {formatName(active.patientName)}
              </p>
              <span className="inline-block text-lg md:text-xl bg-white/20 px-4 py-2 rounded-full">
                {bookingTypeLabel[active.bookingType]}
              </span>
            </div>
          </div>
        ) : (
          <div className="text-6xl md:text-9xl font-black text-blue-300/50">
            — — —
          </div>
        )}
      </section>

      {/* Up Next */}
      <section className="p-6 md:p-12 bg-black/20 border-t border-white/10">
        <div className="flex items-baseline justify-between mb-6 flex-wrap gap-2">
          <p className="text-blue-200 text-xl md:text-2xl uppercase tracking-wider font-medium">
            Up Next
          </p>
          <p className="text-blue-200 text-base md:text-lg">
            {pending.length} waiting · ~{avgServiceTime} min per patient
          </p>
        </div>

        {upNext.length === 0 ? (
          <p className="text-blue-200 text-2xl md:text-3xl text-center py-12">
            No one in queue
          </p>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-3 md:gap-4">
            {upNext.map((b, idx) => {
              // Use the time stored at booking creation, not a recalculated one
              const storedCallTime = b.expectedCallAt ? new Date(b.expectedCallAt) : null
              // Fallback if old booking has no stored time
              const fallbackCallTime = projectedCallTime(idx + 1, avgServiceTime)
              const callTime = storedCallTime || fallbackCallTime
              return (
                <div
                  key={b.id}
                  className="bg-white/10 backdrop-blur rounded-xl p-4 md:p-6 border border-white/10"
                >
                  <p className="text-5xl md:text-6xl font-black tabular-nums">
                    {b.tokenNumber}
                  </p>
                  <p className="text-lg md:text-xl font-medium mt-2 truncate">
                    {formatName(b.patientName)}
                  </p>
                  <p className="text-sm md:text-base text-blue-200 mt-2">
                    Expected
                  </p>
                  <p className="text-lg md:text-xl font-bold text-white">
                    {formatExpectedTime(callTime)}
                  </p>
                </div>
              )
            })}
          </div>
        )}
      </section>

      {/* Footer with stats */}
      <footer className="p-4 md:p-6 border-t border-white/10 bg-black/20">
        <div className="flex items-center justify-between flex-wrap gap-4 text-blue-200">
          <p className="text-sm md:text-base">
            Total today: <strong className="text-white">{bookings.length}</strong>
            {' · '}
            Served: <strong className="text-white">{bookings.filter(b => b.status === BOOKING_STATUS.SERVED).length}</strong>
            {' · '}
            Waiting: <strong className="text-white">{pending.length}</strong>
          </p>
          <p className="text-sm md:text-base flex items-center justify-center gap-1.5">
            <LiveDot label="Live" /> · Updates automatically
          </p>
        </div>
      </footer>
    </div>
  )
}