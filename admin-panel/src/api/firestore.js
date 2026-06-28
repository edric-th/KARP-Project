import { collection, doc, getDocs, getDoc, addDoc, updateDoc, deleteDoc, query, where, orderBy, onSnapshot, serverTimestamp, runTransaction } from 'firebase/firestore'
import { db } from '../lib/firebase'

export const getAll = async (collectionName) => {
  const snap = await getDocs(collection(db, collectionName))
  return snap.docs.map(d => ({ id: d.id, ...d.data() }))
}

export const getById = async (collectionName, id) => {
  const snap = await getDoc(doc(db, collectionName, id))
  return snap.exists() ? { id: snap.id, ...snap.data() } : null
}

export const create = async (collectionName, data) => {
  const ref = await addDoc(collection(db, collectionName), {
    ...data,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  })
  return ref.id
}

export const update = async (collectionName, id, data) => {
  await updateDoc(doc(db, collectionName, id), {
    ...data,
    updatedAt: serverTimestamp(),
  })
}

export const remove = async (collectionName, id) => {
  await deleteDoc(doc(db, collectionName, id))
}

// Allocate the next queue token for a doctor on a given day from the SAME
// race-safe counter the backend uses (counters/{doctorId}_{date}), so tokens
// created here and in the patient app share one source of truth and never
// collide. Mirrors backend next_token_number(): increment when the counter
// exists; on first creation seed it from the highest token already booked.
export const allocateToken = async (doctorId, date, seedTokens = []) =>
  runTransaction(db, async (tx) => {
    const ref = doc(db, 'counters', `${doctorId}_${date}`)
    const snap = await tx.get(ref)
    const last = snap.exists()
      ? snap.data().lastToken || 0
      : Math.max(0, ...seedTokens)
    const next = last + 1
    tx.set(ref, { doctorId, date, lastToken: next }, { merge: true })
    return next
  })

export const subscribe = (collectionName, callback, filters = []) => {
  let q = collection(db, collectionName)
  if (filters.length) q = query(q, ...filters)
  return onSnapshot(q, (snap) => {
    const items = snap.docs.map(d => ({ id: d.id, ...d.data() }))
    callback(items)
  })
}

export { where, orderBy, query }
