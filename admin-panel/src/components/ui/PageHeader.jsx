/** Consistent page title block: gradient icon chip + title/subtitle + actions. */
export default function PageHeader({ icon: Icon, title, subtitle, children }) {
  return (
    <div className="mb-6 flex items-start justify-between gap-4 flex-wrap">
      <div className="flex items-center gap-3">
        {Icon && (
          <div className="w-11 h-11 rounded-2xl bg-gradient-to-br from-primary-500 to-accent-600 text-white flex items-center justify-center shadow-glow flex-shrink-0">
            <Icon size={22} />
          </div>
        )}
        <div>
          <h1 className="text-2xl font-bold text-gray-900">{title}</h1>
          {subtitle && <p className="text-gray-500 text-sm mt-0.5">{subtitle}</p>}
        </div>
      </div>
      {children && <div className="flex items-center gap-2 flex-wrap">{children}</div>}
    </div>
  )
}
