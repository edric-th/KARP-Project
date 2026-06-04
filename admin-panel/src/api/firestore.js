import { collection, doc, getDocs, getDoc, addDoc, updateDoc, deleteDoc, query, where, orderBy, onSnapshot, serverTimestamp } from 'firebase/firestore'
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

export const subscribe = (collectionName, callback, filters = []) => {
  let q = collection(db, collectionName)
  if (filters.length) q = query(q, ...filters)
  return onSnapshot(q, (snap) => {
    const items = snap.docs.map(d => ({ id: d.id, ...d.data() }))
    callback(items)
  })
}

export { where, orderBy, query }
