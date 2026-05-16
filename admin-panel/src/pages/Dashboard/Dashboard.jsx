import { useState, useEffect, useMemo } from 'react'
import { Link } from 'react-router-dom'
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  CartesianGrid,
} from 'recharts'
import {
  Calendar,
  Clock,
  Users,
  CheckCircle,
  TrendingUp,
  Activity,
  ChevronRight,
  Stethoscope,
  AlertCircle,
} from 'lucide-react'
import { subscribe } from '../../api/firestore'
import { COLLECTIONS, BOOKING_STATUS, BOOKING_TYPES } from '../../constants'
import { calculateAvgServiceTime } from '../../lib/waitTime'

const todayString = () => {
  const d = new Date()
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

const bookingTypeLabel = {
  [BOOKING_TYPES.FIRST_VISIT]: 'First Visit',
  [BOOKING_TYPES.FOLLOW_UP]: 'Follow-up',
  [BOOKING_TYPES.REPORT]: 'Show Report',
}

const statusLabel = {
  [BOOKING_STATUS.PENDING]: 'booked',
  [BOOKING_STATUS.ACTIVE]: 'called',
  [BOOKING_STATUS.SERVED]: 'served',
  [BOOKING_STATUS.NO_SHOW]: 'no-show',
  [BOOKING_STATUS.CANCELLED]: 'cancelled',
}

const statusColor = {
  [BOOKING_STATUS.PENDING]: 'text-gray-600 bg-gray-100',
  [BOOKING_STATUS.ACTIVE]: 'text-green-700 bg-green-100',
  [BOOKING_STATUS.SERVED]: 'text-blue-700 bg-blue-100',
  [BOOKING_STATUS.NO_SHOW]: 'text-orange-700 bg-orange-100',
  [BOOKING_STATUS.CANCELLED]: 'text-red-700 bg-red-100',
}

export default function Dashboard() {
  const [bookings, setBookings] = useState([])
  const [doctors, setDoctors] = useState([])
  const [hospitals, setHospitals] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const unsubBookings = subscribe(COLLECTIONS.BOOKINGS, (data) => {
      setBookings(data)
      setLoading(false)
    })
    const unsubDoctors = subscribe(COLLECTIONS.DOCTORS, setDoctors)
    const unsubHospitals = subscribe(COLLECTIONS.HOSPITALS, setHospitals)
    return () => {
      unsubBookings()
      unsubDoctors()
      unsubHospitals()
    }
  }, [])

  const today = todayString()

  // All today's bookings
  const todaysBookings = useMemo(
    () => bookings.filter((b) => b.bookingDate === today),
    [bookings, today]
  )

  // Top-line stats
  const nowServing = todaysBookings.filter(
    (b) => b.status === BOOKING_STATUS.ACTIVE
  ).length
  const waiting = todaysBookings.filter(
    (b) => b.status === BOOKING_STATUS.PENDING
  ).length
  const served = todaysBookings.filter(
    (b) => b.status === BOOKING_STATUS.SERVED
  ).length
  const noShow = todaysBookings.filter(
    (b) => b.status === BOOKING_STATUS.NO_SHOW
  ).length

  // Bookings grouped by hour (0-23) for chart
  const hourlyData = useMemo(() => {
    const hours = Array.from({ length: 12 }, (_, i) => ({
      hour: `${i + 8}:00`, // 8 AM to 7 PM
      hourNum: i + 8,
      bookings: 0,
    }))
    todaysBookings.forEach((b) => {
      if (!b.createdAt) return
      // Firestore Timestamp has toDate(), but might also be a regular date
      let date
      try {
        date =
          b.createdAt.toDate?.() ||
          (b.createdAt.seconds
            ? new Date(b.createdAt.seconds * 1000)
            : new Date(b.createdAt))
      } catch {
        return
      }
      const hr = date.getHours()
      const idx = hours.findIndex((h) => h.hourNum === hr)
      if (idx >= 0) hours[idx].bookings += 1
    })
    return hours
  }, [todaysBookings])

  // Per-doctor activity today
  const doctorActivity = useMemo(() => {
    return doctors.map((doctor) => {
      const docBookings = todaysBookings.filter(
        (b) => b.doctorId === doctor.id
      )
      const active = docBookings.find(
        (b) => b.status === BOOKING_STATUS.ACTIVE
      )
      const docWaiting = docBookings.filter(
        (b) => b.status === BOOKING_STATUS.PENDING
      ).length
      const docServed = docBookings.filter(
        (b) => b.status === BOOKING_STATUS.SERVED
      ).length
      const hospital = hospitals.find((h) => h.id === doctor.hospitalId)
      const avgTime = calculateAvgServiceTime(docBookings)
      return {
        doctor,
        hospital,
        active,
        waiting: docWaiting,
        served: docServed,
        total: docBookings.length,
        avgTime,
      }
    }).filter(d => d.total > 0) // Only show doctors with bookings today
      .sort((a, b) => b.total - a.total) // Busiest first
  }, [doctors, hospitals, todaysBookings])

  // Recent activity (last 10 events, sorted by latest activity timestamp)
  const recentActivity = useMemo(() => {
    return [...todaysBookings]
      .map((b) => {
        // Most relevant timestamp depending on status
        const ts =
          b.servedAt ||
          b.calledAt ||
          b.createdAt?.toDate?.() ||
          (b.createdAt?.seconds
            ? new Date(b.createdAt.seconds * 1000)
            : null) ||
          null
        return { ...b, _timestamp: ts ? new Date(ts) : new Date(0) }
      })
      .sort((a, b) => b._timestamp - a._timestamp)
      .slice(0, 10)
  }, [todaysBookings])

  const formatTime = (date) => {
    if (!date || isNaN(date.getTime())) return ''
    return date.toLocaleTimeString('en-US', {
      hour: 'numeric',
      minute: '2-digit',
      hour12: true,
    })
  }

  const getDoctorName = (doctorId) => {
    const d = doctors.find((x) => x.id === doctorId)
    return d ? `Dr. ${d.name}` : 'Unknown doctor'
  }

  if (loading) {
    return (
      <div>
        <h1 className="text-2xl font-bold mb-6">Dashboard</h1>
        <div className="card text-center text-gray-500">Loading...</div>
      </div>
    )
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6 flex-wrap gap-3">
        <div>
          <h1 className="text-2xl font-bold">Dashboard</h1>
          <p className="text-gray-500 text-sm mt-1 flex items-center gap-1.5">
            <Calendar size={14} />
            {new Date().toLocaleDateString('en-US', {
              weekday: 'long',
              year: 'numeric',
              month: 'long',
              day: 'numeric',
            })}
          </p>
        </div>
        <div className="flex gap-2">
          <Link to="/queue" className="btn-primary flex items-center gap-2">
            <Activity size={16} /> Live Queue
          </Link>
        </div>
      </div>

      {/* Top stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mb-6">
        <StatCard
          icon={Calendar}
          label="Today's bookings"
          value={todaysBookings.length}
          color="blue"
        />
        <StatCard
          icon={Activity}
          label="Now serving"
          value={nowServing}
          color="green"
        />
        <StatCard
          icon={Clock}
          label="Waiting"
          value={waiting}
          color="amber"
        />
        <StatCard
          icon={CheckCircle}
          label="Served"
          value={served}
          color="purple"
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 mb-6">
        {/* Bookings by hour chart */}
        <div className="card lg:col-span-2">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-bold flex items-center gap-2">
              <TrendingUp size={18} /> Bookings by Hour
            </h2>
            <p className="text-xs text-gray-500">Today</p>
          </div>
          {todaysBookings.length === 0 ? (
            <p className="text-gray-500 text-sm text-center py-12">
              No bookings yet today
            </p>
          ) : (
            <ResponsiveContainer width="100%" height={240}>
              <BarChart data={hourlyData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                <XAxis
                  dataKey="hour"
                  stroke="#6b7280"
                  fontSize={12}
                  tickLine={false}
                />
                <YAxis
                  stroke="#6b7280"
                  fontSize={12}
                  tickLine={false}
                  allowDecimals={false}
                />
                <Tooltip
                  cursor={{ fill: 'rgba(59, 130, 246, 0.05)' }}
                  contentStyle={{
                    background: 'white',
                    border: '1px solid #e5e7eb',
                    borderRadius: '8px',
                    fontSize: '13px',
                  }}
                />
                <Bar
                  dataKey="bookings"
                  fill="#2563eb"
                  radius={[4, 4, 0, 0]}
                />
              </BarChart>
            </ResponsiveContainer>
          )}
        </div>

        {/* Summary card */}
        <div className="card">
          <h2 className="font-bold mb-4 flex items-center gap-2">
            <AlertCircle size={18} /> Summary
          </h2>
          <div className="space-y-3">
            <SummaryRow label="Total doctors" value={doctors.length} />
            <SummaryRow label="Total hospitals" value={hospitals.length} />
            <SummaryRow
              label="No-show today"
              value={noShow}
              danger={noShow > 0}
            />
            <SummaryRow
              label="Completion rate"
              value={
                todaysBookings.length === 0
                  ? '—'
                  : `${Math.round((served / todaysBookings.length) * 100)}%`
              }
            />
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-6">
        {/* Doctor activity */}
        <div className="card">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-bold flex items-center gap-2">
              <Stethoscope size={18} /> Doctor Activity
            </h2>
            <Link
              to="/doctors"
              className="text-xs text-primary-600 hover:underline flex items-center gap-1"
            >
              View all <ChevronRight size={12} />
            </Link>
          </div>
          {doctorActivity.length === 0 ? (
            <p className="text-gray-500 text-sm text-center py-12">
              No doctor activity today
            </p>
          ) : (
            <div className="divide-y">
              {doctorActivity.map(
                ({ doctor, hospital, active, waiting, served, avgTime }) => (
                  <div key={doctor.id} className="py-3">
                    <div className="flex items-center justify-between mb-2">
                      <div className="min-w-0">
                        <p className="font-medium truncate">
                          Dr. {doctor.name}
                        </p>
                        <p className="text-xs text-gray-500 truncate">
                          {doctor.specialty}
                          {hospital ? ` · ${hospital.name}` : ''}
                        </p>
                      </div>
                      {active && (
                        <span className="text-xs bg-green-100 text-green-700 px-2 py-0.5 rounded font-medium flex-shrink-0">
                          Serving #{active.tokenNumber}
                        </span>
                      )}
                    </div>
                    <div className="grid grid-cols-3 gap-2 text-xs">
                      <Metric label="Waiting" value={waiting} />
                      <Metric label="Served" value={served} />
                      <Metric label="Avg time" value={`${avgTime}m`} />
                    </div>
                  </div>
                )
              )}
            </div>
          )}
        </div>

        {/* Recent activity */}
        <div className="card">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-bold flex items-center gap-2">
              <Activity size={18} /> Recent Activity
            </h2>
            <Link
              to="/bookings"
              className="text-xs text-primary-600 hover:underline flex items-center gap-1"
            >
              View all <ChevronRight size={12} />
            </Link>
          </div>
          {recentActivity.length === 0 ? (
            <p className="text-gray-500 text-sm text-center py-12">
              No activity yet today
            </p>
          ) : (
            <div className="divide-y">
              {recentActivity.map((b) => (
                <div key={b.id} className="py-2.5 flex items-center gap-3">
                  <div className="w-8 h-8 bg-gray-100 rounded text-xs font-bold text-gray-700 flex items-center justify-center flex-shrink-0">
                    #{b.tokenNumber}
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-medium truncate">
                      {b.patientName}
                    </p>
                    <p className="text-xs text-gray-500 truncate">
                      {getDoctorName(b.doctorId)} ·{' '}
                      {bookingTypeLabel[b.bookingType]}
                    </p>
                  </div>
                  <div className="text-right flex-shrink-0">
                    <span
                      className={`text-xs px-2 py-0.5 rounded font-medium ${statusColor[b.status]}`}
                    >
                      {statusLabel[b.status]}
                    </span>
                    <p className="text-xs text-gray-500 mt-0.5">
                      {formatTime(b._timestamp)}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Quick actions */}
      {todaysBookings.length === 0 && (
        <div className="card bg-gradient-to-r from-primary-50 to-blue-50 border-primary-200 text-center py-8">
          <Users className="mx-auto mb-3 text-primary-600" size={32} />
          <h3 className="font-bold text-lg mb-1">Ready to start the day</h3>
          <p className="text-gray-600 text-sm mb-4">
            No bookings yet. Create the first booking to start the queue.
          </p>
          <Link to="/queue" className="btn-primary inline-flex items-center gap-2">
            Go to Live Queue <ChevronRight size={16} />
          </Link>
        </div>
      )}
    </div>
  )
}

// ---------- Small components ----------

function StatCard({ icon: Icon, label, value, color }) {
  const colors = {
    blue: 'bg-blue-50 text-blue-700',
    green: 'bg-green-50 text-green-700',
    amber: 'bg-amber-50 text-amber-700',
    purple: 'bg-purple-50 text-purple-700',
  }
  return (
    <div className="card">
      <div className="flex items-center gap-3 mb-2">
        <div className={`w-9 h-9 rounded-lg flex items-center justify-center ${colors[color]}`}>
          <Icon size={18} />
        </div>
        <p className="text-sm text-gray-500">{label}</p>
      </div>
      <p className="text-3xl font-bold">{value}</p>
    </div>
  )
}

function SummaryRow({ label, value, danger }) {
  return (
    <div className="flex items-center justify-between">
      <span className="text-sm text-gray-600">{label}</span>
      <span
        className={`text-sm font-semibold ${danger ? 'text-red-600' : 'text-gray-900'}`}
      >
        {value}
      </span>
    </div>
  )
}

function Metric({ label, value }) {
  return (
    <div className="bg-gray-50 rounded p-2 text-center">
      <p className="text-gray-500">{label}</p>
      <p className="font-bold text-gray-900 mt-0.5">{value}</p>
    </div>
  )
}