import { motion } from 'framer-motion'

const TONES = {
  primary: { bg: 'bg-primary-50', text: 'text-primary-600' },
  success: { bg: 'bg-success-50', text: 'text-success-600' },
  warning: { bg: 'bg-warning-50', text: 'text-warning-600' },
  danger: { bg: 'bg-danger-50', text: 'text-danger-600' },
  info: { bg: 'bg-info-50', text: 'text-info-600' },
  purple: { bg: 'bg-purple-50', text: 'text-purple-600' },
  gray: { bg: 'bg-gray-100', text: 'text-gray-600' },
}

/** Metric tile with an icon chip and a staggered entrance (via `index`). */
export default function StatCard({ label, value, icon: Icon, tone = 'primary', index = 0 }) {
  const t = TONES[tone] || TONES.primary
  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, delay: index * 0.06, ease: [0.16, 1, 0.3, 1] }}
      className="bg-white rounded-2xl shadow-card border border-gray-100 p-4 flex items-center gap-3"
    >
      {Icon && (
        <div className={`w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 ${t.bg} ${t.text}`}>
          <Icon size={20} />
        </div>
      )}
      <div className="min-w-0">
        <p className="text-xs font-medium text-gray-500 truncate">{label}</p>
        <p className="text-2xl font-bold text-gray-900 leading-tight">{value}</p>
      </div>
    </motion.div>
  )
}
