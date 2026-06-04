import { useState, useEffect } from 'react'
import { Plus, Edit2, Trash2, MapPin, Phone, X } from 'lucide-react'
import toast from 'react-hot-toast'
import { subscribe, create, update, remove } from '../../api/firestore'
import { COLLECTIONS } from '../../constants'

export default function Hospitals() {
  const [hospitals, setHospitals] = useState([])
  const [loading, setLoading] = useState(true)
  const [showModal, setShowModal] = useState(false)
  const [editingHospital, setEditingHospital] = useState(null)

  // Real-time listener: any change in Firestore updates this list automatically
  useEffect(() => {
    const unsubscribe = subscribe(COLLECTIONS.HOSPITALS, (data) => {
      setHospitals(data)
      setLoading(false)
    })
    return () => unsubscribe()
  }, [])

  const handleAdd = () => {
    setEditingHospital(null)
    setShowModal(true)
  }

  const handleEdit = (hospital) => {
    setEditingHospital(hospital)
    setShowModal(true)
  }

  const handleDelete = async (hospital) => {
    if (!confirm(`Delete "${hospital.name}"? This cannot be undone.`)) return
    try {
      await remove(COLLECTIONS.HOSPITALS, hospital.id)
      toast.success('Hospital deleted')
    } catch (err) {
      toast.error('Failed to delete')
      console.error(err)
    }
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold">Hospitals</h1>
          <p className="text-gray-500 text-sm mt-1">Manage hospitals in the system</p>
        </div>
        <button onClick={handleAdd} className="btn-primary flex items-center gap-2">
          <Plus size={18} /> Add Hospital
        </button>
      </div>

      {loading ? (
        <div className="card text-center text-gray-500">Loading hospitals...</div>
      ) : hospitals.length === 0 ? (
        <div className="card text-center py-12">
          <p className="text-gray-500 mb-4">No hospitals added yet.</p>
          <button onClick={handleAdd} className="btn-primary">
            Add your first hospital
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {hospitals.map((hospital) => (
            <div key={hospital.id} className="card">
              <div className="flex items-start justify-between mb-3">
                <h3 className="font-semibold text-lg">{hospital.name}</h3>
                <div className="flex gap-1">
                  <button
                    onClick={() => handleEdit(hospital)}
                    className="p-1.5 text-gray-500 hover:text-primary-600 hover:bg-gray-100 rounded"
                  >
                    <Edit2 size={16} />
                  </button>
                  <button
                    onClick={() => handleDelete(hospital)}
                    className="p-1.5 text-gray-500 hover:text-red-600 hover:bg-gray-100 rounded"
                  >
                    <Trash2 size={16} />
                  </button>
                </div>
              </div>
              {hospital.address && (
                <p className="text-sm text-gray-600 flex items-start gap-2 mb-2">
                  <MapPin size={14} className="mt-0.5 flex-shrink-0" />
                  {hospital.address}
                </p>
              )}
              {hospital.phone && (
                <p className="text-sm text-gray-600 flex items-center gap-2">
                  <Phone size={14} />
                  {hospital.phone}
                </p>
              )}
            </div>
          ))}
        </div>
      )}

      {showModal && (
        <HospitalModal
          hospital={editingHospital}
          onClose={() => setShowModal(false)}
        />
      )}
    </div>
  )
}

// ---------- Modal for adding/editing ----------

function HospitalModal({ hospital, onClose }) {
  const isEditing = !!hospital
  const [formData, setFormData] = useState({
    name: hospital?.name || '',
    address: hospital?.address || '',
    phone: hospital?.phone || '',
    city: hospital?.city || '',
    openHours: hospital?.openHours || '',
    specialties: Array.isArray(hospital?.specialties)
      ? hospital.specialties.join(', ')
      : hospital?.specialties || '',
    photoUrl: hospital?.photoUrl || '',
    latitude: hospital?.latitude ?? '',
    longitude: hospital?.longitude ?? '',
  })
  const [saving, setSaving] = useState(false)

  const handleChange = (field) => (e) => {
    setFormData({ ...formData, [field]: e.target.value })
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!formData.name.trim()) {
      toast.error('Hospital name is required')
      return
    }
    setSaving(true)
    try {
      const payload = {
        ...formData,
        specialties: formData.specialties
          ? formData.specialties.split(',').map((s) => s.trim()).filter(Boolean)
          : [],
        latitude: formData.latitude !== '' ? Number(formData.latitude) : null,
        longitude: formData.longitude !== '' ? Number(formData.longitude) : null,
      }
      if (isEditing) {
        await update(COLLECTIONS.HOSPITALS, hospital.id, payload)
        toast.success('Hospital updated')
      } else {
        await create(COLLECTIONS.HOSPITALS, payload)
        toast.success('Hospital added')
      }
      onClose()
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
            {isEditing ? 'Edit Hospital' : 'Add Hospital'}
          </h2>
          <button
            onClick={onClose}
            className="p-1 hover:bg-gray-100 rounded"
          >
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
              placeholder="e.g. Bir Hospital"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">City</label>
            <input
              type="text"
              className="input"
              value={formData.city}
              onChange={handleChange('city')}
              placeholder="e.g. Kathmandu"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Address</label>
            <input
              type="text"
              className="input"
              value={formData.address}
              onChange={handleChange('address')}
              placeholder="Street address"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Phone</label>
            <input
              type="tel"
              className="input"
              value={formData.phone}
              onChange={handleChange('phone')}
              placeholder="e.g. +977 1 4221119"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Opening Hours</label>
            <input
              type="text"
              className="input"
              value={formData.openHours}
              onChange={handleChange('openHours')}
              placeholder="e.g. 8:00 AM – 8:00 PM  (or 24 Hours)"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Specialties</label>
            <input
              type="text"
              className="input"
              value={formData.specialties}
              onChange={handleChange('specialties')}
              placeholder="e.g. Cardiology, General, Orthopedics"
            />
            <p className="text-xs text-gray-500 mt-1">Comma-separated</p>
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Photo URL</label>
            <input
              type="url"
              className="input"
              value={formData.photoUrl}
              onChange={handleChange('photoUrl')}
              placeholder="https://…"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-sm font-medium mb-1">Latitude</label>
              <input
                type="number"
                step="any"
                className="input"
                value={formData.latitude}
                onChange={handleChange('latitude')}
                placeholder="27.6726"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Longitude</label>
              <input
                type="number"
                step="any"
                className="input"
                value={formData.longitude}
                onChange={handleChange('longitude')}
                placeholder="85.3239"
              />
            </div>
          </div>
          <p className="text-xs text-gray-500 -mt-2">
            Used for distance in the patient app (optional)
          </p>

          <div className="flex gap-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="btn-secondary flex-1"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={saving}
              className="btn-primary flex-1"
            >
              {saving ? 'Saving...' : isEditing ? 'Update' : 'Add'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}