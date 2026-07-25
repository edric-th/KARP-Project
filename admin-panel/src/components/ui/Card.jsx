import { motion } from 'framer-motion'

/** Shared surface. Pass `animate` for a subtle slide-up entrance. */
export default function Card({ className = '', animate = false, children, ...props }) {
  if (animate) {
    return (
      <motion.div
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4, ease: [0.16, 1, 0.3, 1] }}
        className={`card ${className}`}
        {...props}
      >
        {children}
      </motion.div>
    )
  }
  return (
    <div className={`card ${className}`} {...props}>
      {children}
    </div>
  )
}
