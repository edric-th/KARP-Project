export const COLLECTIONS = {
  USERS: 'users',
  HOSPITALS: 'hospitals',
  DOCTORS: 'doctors',
  BOOKINGS: 'bookings',
  QUEUES: 'queues',
  NOTIFICATIONS: 'notifications',
  REVIEWS: 'reviews',
}

export const BOOKING_TYPES = {
  FIRST_VISIT: 'first_visit',
  FOLLOW_UP: 'follow_up',
  REPORT: 'report',
}

export const BOOKING_STATUS = {
  PENDING: 'pending',
  ACTIVE: 'active',
  SERVED: 'served',
  CANCELLED: 'cancelled',
  NO_SHOW: 'no_show',
}

export const BOOKING_SOURCE = {
  APPOINTMENT: 'appointment',
  ONLINE_TOKEN: 'online_token',
}

// Average minutes the reception desk spends handling one online-token walk-in.
export const RECEPTION_MINUTES_PER_TOKEN = 4

export const ROLES = {
  ADMIN: 'admin',
  RECEPTIONIST: 'receptionist',
  PATIENT: 'patient',
}
