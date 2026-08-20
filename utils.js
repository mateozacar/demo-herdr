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
  throw new Error("Not implemented");
}

// TODO: implement validatePasswordStrength(password)
// Score-based analysis (0-100): length, uppercase, lowercase, numbers, symbols
// Returns: { valid: boolean, score: number, errors: string[] }
// valid = score >= 60
function validatePasswordStrength(password) {
  throw new Error("Not implemented");
}

function _isValidDate(year, month, day) {
  if (month < 1 || month > 12 || day < 1 || day > 31) return false;
  const d = new Date(year, month - 1, day);
  d.setFullYear(year);
  return (
    d.getFullYear() === year &&
    d.getMonth() === month - 1 &&
    d.getDate() === day
  );
}

// TODO: implement validateDate(input)
// Accepts ISO (YYYY-MM-DD), DD/MM/YYYY, MM/DD/YYYY
// Validates real dates (no Feb 30), auto-detects format
// Returns: { valid: boolean, normalized: string|null, format: string|null }
function validateDate(input) {
  if (!_checkInput(input, "string")) {
    return _result(false, { normalized: null, format: null });
  }

  const isoMatch = input.match(/^(\d{4})-(\d{2})-(\d{2})$/);
  if (isoMatch) {
    const year = parseInt(isoMatch[1], 10);
    const month = parseInt(isoMatch[2], 10);
    const day = parseInt(isoMatch[3], 10);

    if (_isValidDate(year, month, day)) {
      const normalized = `${isoMatch[1]}-${isoMatch[2]}-${isoMatch[3]}`;
      return _result(true, { normalized, format: "ISO" });
    }
    return _result(false, { normalized: null, format: null });
  }

  const slashMatch = input.match(/^(\d{2})\/(\d{2})\/(\d{4})$/);
  if (slashMatch) {
    const first = parseInt(slashMatch[1], 10);
    const second = parseInt(slashMatch[2], 10);
    const year = parseInt(slashMatch[3], 10);
    const yearStr = slashMatch[3];

    if (first > 12 && second <= 12) {
      const day = first;
      const month = second;
      if (_isValidDate(year, month, day)) {
        const normalized = `${yearStr}-${slashMatch[2]}-${slashMatch[1]}`;
        return _result(true, { normalized, format: "DD/MM/YYYY" });
      }
    } else if (first <= 12 && second > 12) {
      const month = first;
      const day = second;
      if (_isValidDate(year, month, day)) {
        const normalized = `${yearStr}-${slashMatch[1]}-${slashMatch[2]}`;
        return _result(true, { normalized, format: "MM/DD/YYYY" });
      }
    } else if (first <= 12 && second <= 12) {
      // Ambos <= 12: intentar DD/MM/YYYY primero
      const dayDD = first;
      const monthDD = second;
      if (_isValidDate(year, monthDD, dayDD)) {
        const normalized = `${yearStr}-${slashMatch[2]}-${slashMatch[1]}`;
        return _result(true, { normalized, format: "DD/MM/YYYY" });
      }

      const monthMM = first;
      const dayMM = second;
      if (_isValidDate(year, monthMM, dayMM)) {
        const normalized = `${yearStr}-${slashMatch[1]}-${slashMatch[2]}`;
        return _result(true, { normalized, format: "MM/DD/YYYY" });
      }
    }

    return _result(false, { normalized: null, format: null });
  }

  return _result(false, { normalized: null, format: null });
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

