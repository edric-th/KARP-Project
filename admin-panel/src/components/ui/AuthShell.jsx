import { motion } from 'framer-motion'

/**
 * Branded, animated login layout shared by every sign-in door (admin, reception,
 * offline-booking). Left: a gradient brand panel with the Meroपालो logo; right:
 * the form card. Replaces the old bare gray-background / logo-less login screens.
 *
 * Props: title, subtitle, icon (lucide component), children (the form).
 */
export default function AuthShell({ title, subtitle, icon: Icon, children }) {
  return (
    <div className="min-h-screen flex bg-gray-50">
      {/* Brand panel (desktop only) */}
      <div className="hidden lg:flex lg:w-1/2 relative overflow-hidden bg-gradient-to-br from-primary-600 via-primary-700 to-accent-700 text-white">
        <div className="absolute -top-24 -left-24 w-96 h-96 rounded-full bg-white/10 blur-3xl" />
        <div className="absolute bottom-0 right-0 w-[28rem] h-[28rem] rounded-full bg-accent-400/20 blur-3xl" />
        <div className="relative z-10 flex flex-col justify-between p-12 w-full">
          <div className="flex items-center gap-3">
            <img
              src="/mero-palo-logo.jpeg"
              alt="Meroपालो"
              className="w-12 h-12 rounded-xl object-contain bg-white/90 p-1"
            />
            <span className="text-2xl font-bold">Meroपालो</span>
          </div>
          <motion.div
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
          >
            <h2 className="text-4xl font-black leading-tight">
              Hospital queues,
              <br />
              beautifully managed.
            </h2>
            <p className="mt-4 text-white/80 max-w-md">
              Real-time tokens, smart wait-time estimates, and a calmer front
              desk — all in one place.
            </p>
          </motion.div>
          <p className="text-white/60 text-sm">© Meroपालो · Smart OPD queueing</p>
        </div>
      </div>

      {/* Form side */}
      <div className="flex-1 flex items-center justify-center px-4 py-10">
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
          className="w-full max-w-md"
        >
          <div className="lg:hidden flex items-center gap-3 mb-6 justify-center">
            <img
              src="/mero-palo-logo.jpeg"
              alt="Meroपालो"
              className="w-10 h-10 rounded-lg object-contain"
            />
            <span className="text-xl font-bold">Meroपालो</span>
          </div>
          <div className="card shadow-elevated">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-primary-500 to-accent-600 text-white flex items-center justify-center shadow-glow flex-shrink-0">
                {Icon ? <Icon size={24} /> : null}
              </div>
              <div>
                <h1 className="text-xl font-bold text-gray-900">{title}</h1>
                {subtitle && <p className="text-gray-500 text-sm">{subtitle}</p>}
              </div>
            </div>
            {children}
          </div>
        </motion.div>
      </div>
    </div>
  )
}
