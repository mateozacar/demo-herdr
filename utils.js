// Utility functions for user input validation

/**
 * Validates that a username meets requirements:
 * - 3 to 20 characters
 * - Only letters, numbers, and underscores
 */
function validateUsername(username) {
  if (typeof username !== "string") return false;
  return /^[a-zA-Z0-9_]{3,20}$/.test(username);
}

/**
 * Validates a phone number in formats:
 * +1234567890 or 1234567890 (8 to 15 digits)
 */
function validatePhone(phone) {
  if (typeof phone !== "string") return false;
  return /^\+?[0-9]{8,15}$/.test(phone);
}

/**
 * Validates that a password meets minimum security requirements:
 * - At least 8 characters
 * - Contains at least one uppercase letter
 * - Contains at least one number
 */
function validatePassword(password) {
  if (typeof password !== "string") return false;
  if (password.length < 8) return false;
  if (!/[A-Z]/.test(password)) return false;
  if (!/[0-9]/.test(password)) return false;
  return true;
}

// Shared helpers — written by architect, used by all validators
function _checkInput(value, type) {
  if (value === null || value === undefined) return false;
  return typeof value === type;
}

function _result(valid, fields) {
  return { valid: Boolean(valid), ...(fields || {}) };
}

// TODO: implement validateEmail(email)
// Should validate basic email format and return true/false

// TODO: implement validateCreditCard(number)
// Luhn algorithm + card type detection (Visa/Mastercard/Amex)
// Returns: { valid: boolean, type: string|null, masked: string|null }
function validateCreditCard(number) {
  if (!_checkInput(number, "string")) {
    return _result(false, { type: null, masked: null });
  }

  const cleaned = number.replace(/[\s-]/g, "");
  if (!/^\d+$/.test(cleaned) || cleaned.length < 13 || cleaned.length > 19) {
    return _result(false, { type: null, masked: null });
  }

  let type = null;
  if (/^4/.test(cleaned)) {
    type = "Visa";
  } else if (/^5[1-5]/.test(cleaned)) {
    type = "Mastercard";
  } else if (/^3[47]/.test(cleaned)) {
    type = "Amex";
  }

  // Luhn algorithm checksum
  let sum = 0;
  let shouldDouble = false;
  for (let i = cleaned.length - 1; i >= 0; i--) {
    let digit = parseInt(cleaned[i], 10);
    if (shouldDouble) {
      digit *= 2;
      if (digit > 9) digit -= 9;
    }
    sum += digit;
    shouldDouble = !shouldDouble;
  }

  const isLuhnValid = sum % 10 === 0;
  const valid = isLuhnValid && type !== null;
  const masked = valid ? `****-****-****-${cleaned.slice(-4)}` : null;

  return _result(valid, { type, masked });
}

// TODO: implement validatePasswordStrength(password)
// Score-based analysis (0-100): length, uppercase, lowercase, numbers, symbols
// Returns: { valid: boolean, score: number, errors: string[] }
// valid = score >= 60
function validatePasswordStrength(password) {
  throw new Error("Not implemented");
}

// TODO: implement validateDate(input)
// Accepts ISO (YYYY-MM-DD), DD/MM/YYYY, MM/DD/YYYY
// Validates real dates (no Feb 30), auto-detects format
// Returns: { valid: boolean, normalized: string|null, format: string|null }
function validateDate(input) {
  throw new Error("Not implemented");
}

module.exports = {
  validateUsername,
  validatePhone,
  validatePassword,
  validateCreditCard,
  validatePasswordStrength,
  validateDate,
  _checkInput,
  _result,
};

