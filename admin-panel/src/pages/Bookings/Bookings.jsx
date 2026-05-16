import { useState, useEffect, useMemo } from 'react'
import {
  Search,
  Calendar,
  User,
  Phone,
  Building2,
  Stethoscope,
  Trash2,
  Edit2,
  X as XIcon,
  Filter,
} from 'lucide-react'
import toast from 'react-hot-toast'
import { subscribe, update, remove } from '../../api/firestore'
import { COLLECTIONS, BOOKING_STATUS, BOOKING_TYPES } from '../../constants'

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

const statusLabel = {
  [BOOKING_STATUS.PENDING]: 'Pending',
  [BOOKING_STATUS.ACTIVE]: 'Active',
  [BOOKING_STATUS.SERVED]: 'Served',
  [BOOKING_STATUS.CANCELLED]: 'Cancelled',
  [BOOKING_STATUS.NO_SHOW]: 'No-show',
}

const statusColor = {
  [BOOKING_STATUS.PENDING]: 'bg-gray-100 text-gray-700',
  [BOOKING_STATUS.ACTIVE]: 'bg-green-100 text-green-700',
  [BOOKING_STATUS.SERVED]: 'bg-blue-100 text-blue-700',
  [BOOKING_STATUS.CANCELLED]: 'bg-red-100 text-red-700',
  [BOOKING_STATUS.NO_SHOW]: 'bg-orange-100 text-orange-700',
}

const todayString = () => {
  const d = new Date()
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

export default function Bookings() {
  const [bookings, setBookings] = useState([])
  const [doctors, setDoctors] = useState([])
  const [hospitals, setHospitals] = useState([])
  const [loading, setLoading] = useState(true)
  const [editingBooking, setEditingBooking] = useState(null)

  // Filters
  const [search, setSearch] = useState('')
  const [filterDate, setFilterDate] = useState(todayString())
  const [filterDoctor, setFilterDoctor] = useState('all')
  const [filterStatus, setFilterStatus] = useState('all')
  const [filterType, setFilterType] = useState('all')

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

  const getDoctor = (id) => doctors.find((d) => d.id === id)
  const getHospital = (id) => hospitals.find((h) => h.id === id)

  const filtered = useMemo(() => {
    return bookings
      .filter((b) => {
        if (filterDate && b.bookingDate !== filterDate) return false
        if (filterDoctor !== 'all' && b.doctorId !== filterDoctor) return false
        if (filterStatus !== 'all' && b.status !== filterStatus) return false
        if (filterType !== 'all' && b.bookingType !== filterType) return false
        if (search.trim()) {
          const q = search.trim().toLowerCase()
          const matchesName = b.patientName?.toLowerCase().includes(q)
          const matchesPhone = b.patientPhone?.toLowerCase().includes(q)
          if (!matchesName && !matchesPhone) return false
        }
        return true
      })
      .sort((a, b) => {
        // Sort by date desc, then token number asc
        if (a.bookingDate !== b.bookingDate) {
          return b.bookingDate.localeCompare(a.bookingDate)
        }
        return (a.tokenNumber || 0) - (b.tokenNumber || 0)
      })
  }, [bookings, search, filterDate, filterDoctor, filterStatus, filterType])

  const clearFilters = () => {
    setSearch('')
    setFilterDate(todayString())
    setFilterDoctor('all')
    setFilterStatus('all')
    setFilterType('all')
  }

  const hasActiveFilters =
    search !== '' ||
    filterDate !== todayString() ||
    filterDoctor !== 'all' ||
    filterStatus !== 'all' ||
    filterType !== 'all'

  const handleDelete = async (booking) => {
    if (
      !confirm(
        `Delete booking #${booking.tokenNumber} for ${booking.patientName}? This cannot be undone.`
      )
    )
      return
    try {
      await remove(COLLECTIONS.BOOKINGS, booking.id)
      toast.success('Booking deleted')
    } catch (err) {
      toast.error('Failed to delete')
      console.error(err)
    }
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold">All Bookings</h1>
          <p className="text-gray-500 text-sm mt-1">
            Search, filter, and manage all bookings
          </p>
        </div>
      </div>

      {/* Filters */}
      <div className="card mb-4">
        <div className="flex items-center gap-2 mb-3">
          <Filter size={16} className="text-gray-500" />
          <h2 className="font-medium">Filters</h2>
          {hasActiveFilters && (
            <button
              onClick={clearFilters}
              className="ml-auto text-xs text-primary-600 hover:underline"
            >
              Clear all
            </button>
          )}
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-3">
          {/* Search */}
          <div className="lg:col-span-2 relative">
            <Search
              size={16}
              className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400"
            />
            <input
              type="text"
              placeholder="Search by name or phone..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="input pl-9"
            />
          </div>

          {/* Date */}
          <input
            type="date"
            value={filterDate}
            onChange={(e) => setFilterDate(e.target.value)}
            className="input"
          />

          {/* Doctor */}
          <select
            value={filterDoctor}
            onChange={(e) => setFilterDoctor(e.target.value)}
            className="input"
          >
            <option value="all">All doctors</option>
            {doctors.map((d) => (
              <option key={d.id} value={d.id}>
                Dr. {d.name}
              </option>
            ))}
          </select>

          {/* Status */}
          <select
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value)}
            className="input"
          >
            <option value="all">All statuses</option>
            {Object.entries(statusLabel).map(([value, label]) => (
              <option key={value} value={value}>
                {label}
              </option>
            ))}
          </select>
        </div>

        {/* Booking type filter (secondary row for cleaner layout) */}
        <div className="mt-3 flex items-center gap-2 flex-wrap">
          <span className="text-xs text-gray-500">Type:</span>
          <button
            onClick={() => setFilterType('all')}
            className={`text-xs px-3 py-1 rounded-full font-medium transition ${
              filterType === 'all'
                ? 'bg-gray-800 text-white'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
          >
            All
          </button>
          {Object.entries(bookingTypeLabel).map(([value, label]) => (
            <button
              key={value}
              onClick={() => setFilterType(value)}
              className={`text-xs px-3 py-1 rounded-full font-medium transition ${
                filterType === value
                  ? 'bg-gray-800 text-white'
                  : bookingTypeColor[value] + ' hover:opacity-80'
              }`}
            >
              {label}
            </button>
          ))}
        </div>
      </div>

      {/* Results count */}
      <div className="flex items-center justify-between mb-3">
        <p className="text-sm text-gray-600">
          {loading
            ? 'Loading...'
            : `${filtered.length} booking${filtered.length !== 1 ? 's' : ''}`}
        </p>
      </div>

      {/* Booking list */}
      {loading ? (
        <div className="card text-center text-gray-500">Loading bookings...</div>
      ) : filtered.length === 0 ? (
        <div className="card text-center py-12">
          <p className="text-gray-500 mb-2">No bookings match your filters.</p>
          {hasActiveFilters && (
            <button onClick={clearFilters} className="text-primary-600 text-sm hover:underline">
              Clear filters
            </button>
          )}
        </div>
      ) : (
        <div className="space-y-2">
          {filtered.map((booking) => {
            const doctor = getDoctor(booking.doctorId)
            const hospital = getHospital(doctor?.hospitalId || booking.hospitalId)
            return (
              <div key={booking.id} className="card hover:shadow-md transition">
                <div className="flex items-start justify-between gap-4">
                  <div className="flex items-start gap-3 min-w-0 flex-1">
                    <div className="w-12 h-12 bg-gray-100 rounded-lg flex items-center justify-center font-bold text-gray-700 flex-shrink-0">
                      #{booking.tokenNumber}
                    </div>
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-2 flex-wrap mb-1">
                        <h3 className="font-semibold">
                          <User
                            size={14}
                            className="inline mr-1 text-gray-400"
                          />
                          {booking.patientName}
                        </h3>
                        <span
                          className={`text-xs px-2 py-0.5 rounded ${statusColor[booking.status]}`}
                        >
                          {statusLabel[booking.status]}
                        </span>
                        <span
                          className={`text-xs px-2 py-0.5 rounded ${bookingTypeColor[booking.bookingType]}`}
                        >
                          {bookingTypeLabel[booking.bookingType]}
                        </span>
                      </div>

                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-4 gap-y-1 text-sm text-gray-600">
                        {booking.patientPhone && (
                          <p className="flex items-center gap-1.5">
                            <Phone size={12} />
                            {booking.patientPhone}
                          </p>
                        )}
                        <p className="flex items-center gap-1.5">
                          <Calendar size={12} />
                          {booking.bookingDate}
                        </p>
                        {doctor && (
                          <p className="flex items-center gap-1.5">
                            <Stethoscope size={12} />
                            Dr. {doctor.name}
                          </p>
                        )}
                        {hospital && (
                          <p className="flex items-center gap-1.5">
                            <Building2 size={12} />
                            {hospital.name}
                          </p>
                        )}
                      </div>
                    </div>
                  </div>

                  <div className="flex gap-1 flex-shrink-0">
                    <button
                      onClick={() => setEditingBooking(booking)}
                      className="p-2 text-gray-500 hover:text-primary-600 hover:bg-gray-100 rounded"
                      title="Edit"
                    >
                      <Edit2 size={16} />
                    </button>
                    <button
                      onClick={() => handleDelete(booking)}
                      className="p-2 text-gray-500 hover:text-red-600 hover:bg-gray-100 rounded"
                      title="Delete"
                    >
                      <Trash2 size={16} />
                    </button>
                  </div>
                </div>
              </div>
            )
          })}
        </div>
      )}

      {editingBooking && (
        <EditBookingModal
          booking={editingBooking}
          doctors={doctors}
          onClose={() => setEditingBooking(null)}
        />
      )}
    </div>
  )
}

// ---------- Edit Booking Modal ----------

function EditBookingModal({ booking, doctors, onClose }) {
  const [formData, setFormData] = useState({
    patientName: booking.patientName || '',
    patientPhone: booking.patientPhone || '',
    bookingType: booking.bookingType,
    status: booking.status,
    bookingDate: booking.bookingDate,
    doctorId: booking.doctorId,
  })
  const [saving, setSaving] = useState(false)

  const handleChange = (field) => (e) => {
    setFormData({ ...formData, [field]: e.target.value })
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setSaving(true)
    try {
      await update(COLLECTIONS.BOOKINGS, booking.id, formData)
      toast.success('Booking updated')
      onClose()
    } catch (err) {
      toast.error('Failed to update')
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
            Edit Booking #{booking.tokenNumber}
          </h2>
          <button onClick={onClose} className="p-1 hover:bg-gray-100 rounded">
            <XIcon size={20} />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1">Patient Name</label>
            <input
              type="text"
              required
              className="input"
              value={formData.patientName}
              onChange={handleChange('patientName')}
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Phone</label>
            <input
              type="tel"
              className="input"
              value={formData.patientPhone}
              onChange={handleChange('patientPhone')}
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Doctor</label>
            <select
              className="input"
              value={formData.doctorId}
              onChange={handleChange('doctorId')}
            >
              {doctors.map((d) => (
                <option key={d.id} value={d.id}>
                  Dr. {d.name}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Date</label>
            <input
              type="date"
              className="input"
              value={formData.bookingDate}
              onChange={handleChange('bookingDate')}
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Booking Type</label>
            <select
              className="input"
              value={formData.bookingType}
              onChange={handleChange('bookingType')}
            >
              {Object.entries(bookingTypeLabel).map(([value, label]) => (
                <option key={value} value={value}>
                  {label}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Status</label>
            <select
              className="input"
              value={formData.status}
              onChange={handleChange('status')}
            >
              {Object.entries(statusLabel).map(([value, label]) => (
                <option key={value} value={value}>
                  {label}
                </option>
              ))}
            </select>
          </div>

          <div className="flex gap-3 pt-2">
            <button type="button" onClick={onClose} className="btn-secondary flex-1">
              Cancel
            </button>
            <button type="submit" disabled={saving} className="btn-primary flex-1">
              {saving ? 'Saving...' : 'Save Changes'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
