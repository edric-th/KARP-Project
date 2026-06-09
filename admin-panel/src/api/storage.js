import { ref, uploadBytes, getDownloadURL } from 'firebase/storage'
import { storage } from '../lib/firebase'

/**
 * Upload an image file to Firebase Storage and return its public download URL.
 *
 * @param {File} file   The image File from an <input type="file">.
 * @param {string} folder  Storage folder (e.g. "doctors").
 * @returns {Promise<string>} The download URL to store in Firestore.
 */
export const uploadImage = async (file, folder = 'doctors') => {
  if (!file) throw new Error('No file provided')
  // Sanitize the name and prefix with a timestamp to avoid collisions.
  const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, '_')
  const path = `${folder}/${Date.now()}_${safeName}`
  const storageRef = ref(storage, path)
  await uploadBytes(storageRef, file)
  return getDownloadURL(storageRef)
}
