/** Small status pill with an optional leading lucide icon. */
const TONES = {
  neutral: 'bg-gray-100 text-gray-700',
  primary: 'bg-primary-50 text-primary-700',
  success: 'bg-success-50 text-success-700',
  warning: 'bg-warning-50 text-warning-700',
  danger: 'bg-danger-50 text-danger-700',
  info: 'bg-info-50 text-info-700',
}

export default function Badge({ tone = 'neutral', icon: Icon, className = '', children }) {
  return (
    <span className={`badge ${TONES[tone] || TONES.neutral} ${className}`}>
      {Icon && <Icon size={12} />}
      {children}
    </span>
  )
}
