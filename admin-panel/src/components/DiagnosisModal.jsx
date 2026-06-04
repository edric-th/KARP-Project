import { useState, useEffect } from 'react'
import { X, Stethoscope } from 'lucide-react'

/**
 * Themed replacement for the old window.prompt() diagnosis capture.
 * Lets the doctor add optional visit notes before calling the next patient.
 */
export default function DiagnosisModal({
  open,
  tokenNumber,
  patientName,
  initialValue = '',
  busy = false,
  submitLabel = 'Save notes',
  skipLabel = 'Skip',
  onSubmit,
  onSkip,
  onClose,
}) {
  const [value, setValue] = useState(initialValue)

  useEffect(() => {
    if (open) setValue(initialValue || '')
  }, [open, initialValue])

  if (!open) return null

  return (
    <div
      className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50"
      onClick={onClose}
    >
      <div
        className="bg-white rounded-xl shadow-xl w-full max-w-md"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-lg bg-primary-50 text-primary-600 flex items-center justify-center">
              <Stethoscope size={18} />
            </div>
            <div>
              <h2 className="text-lg font-bold text-gray-900">Visit notes</h2>
              <p className="text-xs text-gray-500">
                Token #{tokenNumber}
                {patientName ? ` · ${patientName}` : ''}
              </p>
            </div>
          </div>
          <button onClick={onClose} className="p-1 hover:bg-gray-100 rounded">
            <X size={20} />
          </button>
        </div>

        <div className="p-6 space-y-2">
          <label className="text-sm font-medium text-gray-700">
            Diagnosis / visit notes{' '}
            <span className="text-gray-400 font-normal">(optional)</span>
          </label>
          <textarea
            autoFocus
            rows={4}
            className="input resize-none"
            value={value}
            onChange={(e) => setValue(e.target.value)}
            placeholder="e.g. Mild hypertension. Advised low-salt diet and follow-up in 2 weeks."
          />
        </div>

        <div className="flex gap-3 p-6 pt-0">
          <button
            type="button"
            onClick={onSkip}
            disabled={busy}
            className="btn-secondary flex-1"
          >
            {skipLabel}
          </button>
          <button
            type="button"
            onClick={() => onSubmit(value)}
            disabled={busy}
            className="btn-primary flex-1"
          >
            {busy ? 'Saving…' : submitLabel}
          </button>
        </div>
      </div>
    </div>
  )
}
