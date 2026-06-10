/**
 * Client-side image handling for doctor/profile photos.
 *
 * We deliberately AVOID Firebase Storage here: uploads were hanging indefinitely
 * whenever the Storage bucket/CORS wasn't configured. Instead we downscale and
 * JPEG-compress the picked image in the browser and return a small base64
 * data-URL, which is stored directly in the doctor's `photoUrl` field. It then
 * renders everywhere (Flutter app, doctor panel) with no extra wiring.
 */

/**
 * Read an image File, downscale it to fit within `maxSize` px on the longest
 * edge, and return a compressed JPEG data-URL.
 *
 * @param {File} file        The image File from an <input type="file">.
 * @param {object} [opts]
 * @param {number} [opts.maxSize=512]  Max width/height in pixels.
 * @param {number} [opts.quality=0.8]  JPEG quality 0..1.
 * @returns {Promise<string>} A `data:image/jpeg;base64,...` string.
 */
export const compressImageToDataUrl = (file, { maxSize = 512, quality = 0.8 } = {}) =>
  new Promise((resolve, reject) => {
    if (!file) {
      reject(new Error('No file provided'))
      return
    }
    const reader = new FileReader()
    reader.onerror = () => reject(new Error('Could not read the file'))
    reader.onload = () => {
      const img = new Image()
      img.onerror = () => reject(new Error('That file is not a valid image'))
      img.onload = () => {
        const longest = Math.max(img.width, img.height) || 1
        const scale = Math.min(1, maxSize / longest)
        const w = Math.max(1, Math.round(img.width * scale))
        const h = Math.max(1, Math.round(img.height * scale))
        const canvas = document.createElement('canvas')
        canvas.width = w
        canvas.height = h
        const ctx = canvas.getContext('2d')
        if (!ctx) {
          reject(new Error('Canvas not supported'))
          return
        }
        ctx.drawImage(img, 0, 0, w, h)
        try {
          resolve(canvas.toDataURL('image/jpeg', quality))
        } catch (err) {
          reject(err)
        }
      }
      img.src = reader.result
    }
    reader.readAsDataURL(file)
  })
