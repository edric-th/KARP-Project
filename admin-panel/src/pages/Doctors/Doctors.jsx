import { useState, useEffect } from 'react'
import { Plus, Edit2, Trash2, Stethoscope, X, Clock, Building2 } from 'lucide-react'
import toast from 'react-hot-toast'
import { subscribe, create, update, remove } from '../../api/firestore'
import { COLLECTIONS } from '../../constants'

export default function Doctors() {
  const [doctors, setDoctors] = useState([])
  const [hospitals, setHospitals] = useState([])
  const [loading, setLoading] = useState(true)
  const [showModal, setShowModal] = useState(false)
  const [editingDoctor, setEditingDoctor] = useState(null)
  const [filterHospital, setFilterHospital] = useState('all')

  // Subscribe to both doctors and hospitals collections
  useEffect(() => {
    const unsubDoctors = subscribe(COLLECTIONS.DOCTORS, (data) => {
      setDoctors(data)
      setLoading(false)
    })
    const unsubHospitals = subscribe(COLLECTIONS.HOSPITALS, (data) => {
      setHospitals(data)
    })
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
    if (!confirm(`Delete Dr. ${doctor.name}? This cannot be undone.`)) return
    try {
      await remove(COLLECTIONS.DOCTORS, doctor.id)
      toast.success('Doctor deleted')
    } catch (err) {
      toast.error('Failed to delete')
      console.error(err)
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
          <p className="text-gray-500 text-sm mt-1">Manage doctors and their schedules</p>
        </div>
        <button onClick={handleAdd} className="btn-primary flex items-center gap-2">
          <Plus size={18} /> Add Doctor
        </button>
      </div>

      {hospitals.length > 0 && (
        <div className="mb-4 flex items-center gap-3">
          <label className="text-sm font-medium text-gray-700">Filter by hospital:</label>
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
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-primary-50 text-primary-600 rounded-full flex items-center justify-center">
                    <Stethoscope size={18} />
                  </div>
                  <div>
                    <h3 className="font-semibold">Dr. {doctor.name}</h3>
                    <p className="text-xs text-gray-500">{doctor.specialty}</p>
                  </div>
                </div>
                <div className="flex gap-1">
                  <button
                    onClick={() => handleEdit(doctor)}
                    className="p-1.5 text-gray-500 hover:text-primary-600 hover:bg-gray-100 rounded"
                  >
                    <Edit2 size={16} />
                  </button>
                  <button
                    onClick={() => handleDelete(doctor)}
                    className="p-1.5 text-gray-500 hover:text-red-600 hover:bg-gray-100 rounded"
                  >
                    <Trash2 size={16} />
                  </button>
                </div>
              </div>
              <div className="space-y-1.5 text-sm text-gray-600">
                <p className="flex items-center gap-2">
                  <Building2 size={14} />
                  {getHospitalName(doctor.hospitalId)}
                </p>
                {doctor.consultationHours && (
                  <p className="flex items-center gap-2">
                    <Clock size={14} />
                    {doctor.consultationHours}
                  </p>
                )}
                {doctor.fee && (
                  <p className="text-sm font-medium text-gray-800 pt-2 border-t mt-2">
                    Rs. {doctor.fee}
                  </p>
                )}
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
        />
      )}
    </div>
  )
}

// ---------- Modal for adding/editing ----------

function DoctorModal({ doctor, hospitals, onClose }) {
  const isEditing = !!doctor
  const [formData, setFormData] = useState({
    name: doctor?.name || '',
    specialty: doctor?.specialty || '',
    hospitalId: doctor?.hospitalId || hospitals[0]?.id || '',
    fee: doctor?.fee || '',
    consultationHours: doctor?.consultationHours || '',
  })
  const [saving, setSaving] = useState(false)

  const handleChange = (field) => (e) => {
    setFormData({ ...formData, [field]: e.target.value })
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
    setSaving(true)
    try {
      // Convert fee to number if provided
      const payload = {
        ...formData,
        fee: formData.fee ? Number(formData.fee) : null,
      }
      if (isEditing) {
        await update(COLLECTIONS.DOCTORS, doctor.id, payload)
        toast.success('Doctor updated')
      } else {
        await create(COLLECTIONS.DOCTORS, payload)
        toast.success('Doctor added')
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
            {isEditing ? 'Edit Doctor' : 'Add Doctor'}
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
              placeholder="e.g. Cardiologist, Dermatologist"
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
            <label className="block text-sm font-medium mb-1">Consultation Hours</label>
            <input
              type="text"
              className="input"
              value={formData.consultationHours}
              onChange={handleChange('consultationHours')}
              placeholder="e.g. Mon-Fri 10am-2pm"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Consultation Fee (Rs.)</label>
            <input
              type="number"
              min="0"
              className="input"
              value={formData.fee}
              onChange={handleChange('fee')}
              placeholder="e.g. 1500"
            />
          </div>

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