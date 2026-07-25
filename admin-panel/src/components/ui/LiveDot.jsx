/**
 * Pulsing "live" indicator — replaces the literal 🔴 emoji used across the
 * real-time footers (DoctorQueue, Queue, Reception, Board).
 */
const DOT = {
  danger: 'bg-danger-500',
  success: 'bg-success-500',
  primary: 'bg-primary-500',
}

export default function LiveDot({ label = 'Live', color = 'danger', className = '' }) {
  const dot = DOT[color] || DOT.danger
  return (
    <span className={`inline-flex items-center gap-1.5 ${className}`}>
      <span className="relative flex h-2 w-2">
        <span className={`absolute inline-flex h-full w-full rounded-full ${dot} opacity-70 animate-ping`} />
        <span className={`relative inline-flex h-2 w-2 rounded-full ${dot}`} />
      </span>
      {label && <span>{label}</span>}
    </span>
  )
}
