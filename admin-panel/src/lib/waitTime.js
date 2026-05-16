// Calculate estimated wait time in minutes based on historical data

const DEFAULT_MINUTES_PER_PATIENT = 10
const MIN_SAMPLES = 3 // Need at least 3 served patients for a reliable average

/**
 * Calculates average service time (in minutes) for a doctor based on
 * recently served bookings. Falls back to default if not enough data.
 */
export function calculateAvgServiceTime(bookings) {
  // Look at served bookings that have both calledAt and servedAt timestamps
  const served = bookings.filter(
    (b) => b.status === 'served' && b.calledAt && b.servedAt
  )

  if (served.length < MIN_SAMPLES) {
    return DEFAULT_MINUTES_PER_PATIENT
  }

  // Take the 10 most recent served patients
  const recent = served
    .sort((a, b) => new Date(b.servedAt) - new Date(a.servedAt))
    .slice(0, 10)

  const totalMinutes = recent.reduce((sum, b) => {
    const called = new Date(b.calledAt).getTime()
    const finished = new Date(b.servedAt).getTime()
    const minutes = (finished - called) / 1000 / 60
    // Clamp to reasonable range (1 to 60 mins) to avoid outliers
    return sum + Math.min(Math.max(minutes, 1), 60)
  }, 0)

  return Math.round(totalMinutes / recent.length)
}

/**
 * Estimates wait time for a specific token, given its position in queue.
 * @param {number} position - 1-based position in waiting queue (1 = next up)
 * @param {number} avgMinutes - average service time per patient
 * @returns {number} estimated minutes until called
 */
export function estimateWaitMinutes(position, avgMinutes) {
  if (position <= 0) return 0
  return position * avgMinutes
}

/**
 * Formats minutes into a human-readable string.
 */
export function formatWaitTime(minutes) {
  if (minutes < 1) return 'Now'
  if (minutes < 60) return `~${minutes} min`
  const hours = Math.floor(minutes / 60)
  const mins = minutes % 60
  return mins === 0 ? `~${hours}h` : `~${hours}h ${mins}m`
}