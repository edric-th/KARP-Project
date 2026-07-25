/**
 * Thin button wrapper over the shared .btn-* classes so pages can pick a variant
 * without repeating Tailwind strings. Falls through to a native <button>.
 */
const VARIANTS = {
  primary: 'btn-primary',
  secondary: 'btn-secondary',
  danger:
    'inline-flex items-center justify-center gap-2 bg-danger-600 hover:bg-danger-700 text-white font-semibold px-4 py-2 rounded-xl shadow-soft transition-all duration-200 active:scale-[0.98] disabled:opacity-60 disabled:pointer-events-none',
  ghost:
    'inline-flex items-center justify-center gap-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 font-medium px-3 py-2 rounded-xl transition',
}

export default function Button({ variant = 'primary', className = '', children, ...props }) {
  return (
    <button className={`${VARIANTS[variant] || VARIANTS.primary} ${className}`} {...props}>
      {children}
    </button>
  )
}
