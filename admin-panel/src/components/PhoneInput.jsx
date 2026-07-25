import { useState } from 'react'
import { ChevronDown, Phone, Check } from 'lucide-react'

// Country codes with their digit lengths (mobile numbers, excluding the country
// code). `iso` is the 2-letter country code shown in a small badge in place of a
// flag emoji.
const COUNTRY_CODES = [
  { code: '+977', country: 'Nepal', iso: 'NP', digits: 10 },
  { code: '+91', country: 'India', iso: 'IN', digits: 10 },
  { code: '+1', country: 'USA/Canada', iso: 'US', digits: 10 },
  { code: '+44', country: 'UK', iso: 'GB', digits: 10 },
  { code: '+86', country: 'China', iso: 'CN', digits: 11 },
  { code: '+61', country: 'Australia', iso: 'AU', digits: 9 },
  { code: '+971', country: 'UAE', iso: 'AE', digits: 9 },
  { code: '+966', country: 'Saudi Arabia', iso: 'SA', digits: 9 },
  { code: '+60', country: 'Malaysia', iso: 'MY', digits: 9 },
  { code: '+82', country: 'South Korea', iso: 'KR', digits: 10 },
  { code: '+81', country: 'Japan', iso: 'JP', digits: 10 },
  { code: '+65', country: 'Singapore', iso: 'SG', digits: 8 },
]

const DEFAULT_COUNTRY = COUNTRY_CODES[0] // Nepal default

// Parse a phone string like "+977 9841234567" into { code, number }
const parsePhone = (fullPhone) => {
  if (!fullPhone) return { code: '+977', number: '' }
  const match = COUNTRY_CODES.find((c) =>
    fullPhone.trim().startsWith(c.code)
  )
  if (match) {
    return {
      code: match.code,
      number: fullPhone.substring(match.code.length).replace(/\D/g, ''),
    }
  }
  return { code: '+977', number: fullPhone.replace(/\D/g, '') }
}

export default function PhoneInput({ value, onChange, required = false, autoFocus = false }) {
  const initial = parsePhone(value || '')
  const [selectedCode, setSelectedCode] = useState(
    COUNTRY_CODES.find((c) => c.code === initial.code) || DEFAULT_COUNTRY
  )
  const [number, setNumber] = useState(initial.number)
  const [showDropdown, setShowDropdown] = useState(false)

  const updateValue = (newCode, newNumber) => {
    if (newNumber) {
      onChange(`${newCode} ${newNumber}`)
    } else {
      onChange('')
    }
  }

  const handleCodeSelect = (country) => {
    setSelectedCode(country)
    setShowDropdown(false)
    // Trim number if longer than new country's allowed digits
    const trimmed = number.substring(0, country.digits)
    setNumber(trimmed)
    updateValue(country.code, trimmed)
  }

  const handleNumberChange = (e) => {
    // Strip all non-digits, then limit to max for selected country
    const onlyDigits = e.target.value.replace(/\D/g, '')
    const limited = onlyDigits.substring(0, selectedCode.digits)
    setNumber(limited)
    updateValue(selectedCode.code, limited)
  }

  const isNepal = selectedCode.code === '+977'
  // Nepal mobiles must be 10 digits starting with 98 or 97.
  const nepalPrefixOk = !isNepal || /^9[78]/.test(number)
  const isValid =
    number.length === 0 ||
    (number.length === selectedCode.digits && nepalPrefixOk)

  return (
    <div>
      <div className="flex gap-2">
        {/* Country code dropdown */}
        <div className="relative">
          <button
            type="button"
            onClick={() => setShowDropdown(!showDropdown)}
            className="flex items-center gap-1 px-3 py-2 border border-gray-300 rounded-lg bg-white hover:bg-gray-50 text-sm h-full"
          >
            <span className="text-[11px] font-bold bg-gray-100 text-gray-600 rounded px-1.5 py-0.5">
              {selectedCode.iso}
            </span>
            <span className="font-medium">{selectedCode.code}</span>
            <ChevronDown size={14} className="text-gray-500" />
          </button>

          {showDropdown && (
            <>
              {/* Overlay to close on outside click */}
              <div
                className="fixed inset-0 z-10"
                onClick={() => setShowDropdown(false)}
              />
              <div className="absolute top-full left-0 mt-1 w-64 max-h-72 overflow-y-auto bg-white border border-gray-200 rounded-lg shadow-lg z-20">
                {COUNTRY_CODES.map((country) => (
                  <button
                    key={country.code}
                    type="button"
                    onClick={() => handleCodeSelect(country)}
                    className={`w-full flex items-center gap-2 px-3 py-2 text-sm hover:bg-gray-50 text-left ${
                      selectedCode.code === country.code
                        ? 'bg-primary-50'
                        : ''
                    }`}
                  >
                    <span className="text-[11px] font-bold bg-gray-100 text-gray-600 rounded px-1.5 py-0.5 w-9 text-center">
                      {country.iso}
                    </span>
                    <span className="font-medium">{country.code}</span>
                    <span className="text-gray-600 flex-1 truncate">
                      {country.country}
                    </span>
                    <span className="text-xs text-gray-400">
                      {country.digits} digits
                    </span>
                  </button>
                ))}
              </div>
            </>
          )}
        </div>

        {/* Number input */}
        <input
          type="tel"
          inputMode="numeric"
          className="input flex-1"
          value={number}
          onChange={handleNumberChange}
          placeholder={`${selectedCode.digits} digits`}
          required={required}
          autoFocus={autoFocus}
        />
      </div>
      {/* Help text */}
      <p className="text-xs text-gray-500 mt-1 flex items-center gap-1">
        <Phone size={11} />
        {number.length > 0 && !isValid ? (
          <span className="text-red-600">
            {isNepal && !nepalPrefixOk
              ? 'Nepal mobiles must start with 98 or 97'
              : `Expected ${selectedCode.digits} digits, got ${number.length}`}
          </span>
        ) : (
          <span>
            {isNepal
              ? 'Nepal format: 10 digits starting with 98 / 97'
              : `${selectedCode.country} format: ${selectedCode.digits} digits`}
            {number.length > 0 && isValid && (
              <Check size={12} className="inline text-green-600" />
            )}
          </span>
        )}
      </p>
    </div>
  )
}