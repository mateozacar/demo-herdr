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

/**
 * Validates a date string in ISO (YYYY-MM-DD), DD/MM/YYYY, or MM/DD/YYYY format.
 * Validates real dates (leap years, days per month) and auto-detects format.
 * Returns: { valid: boolean, normalized: string|null, format: string|null }
 */
function validateDate(input) {
  if (!_checkInput(input, "string")) {
    return _result(false, { normalized: null, format: null });
  }

  let year, month, day, detectedFormat;

  if (/^\d{4}-\d{2}-\d{2}$/.test(input)) {
    const parts = input.split("-");
    year = parseInt(parts[0], 10);
    month = parseInt(parts[1], 10);
    day = parseInt(parts[2], 10);
    detectedFormat = "ISO";
  } else if (/^\d{2}\/\d{2}\/\d{4}$/.test(input)) {
    const parts = input.split("/");
    const num1 = parseInt(parts[0], 10);
    const num2 = parseInt(parts[1], 10);
    year = parseInt(parts[2], 10);

    if (num1 > 12) {
      detectedFormat = "DD/MM/YYYY";
      day = num1;
      month = num2;
    } else if (num2 > 12) {
      detectedFormat = "MM/DD/YYYY";
      month = num1;
      day = num2;
    } else {
      detectedFormat = "DD/MM/YYYY";
      day = num1;
      month = num2;
    }
  } else {
    return _result(false, { normalized: null, format: null });
  }

  const date = new Date(year, month - 1, day);
  const isValid =
    date.getFullYear() === year &&
    date.getMonth() + 1 === month &&
    date.getDate() === day;

  if (!isValid) {
    return _result(false, { normalized: null, format: null });
  }

  const yStr = String(year).padStart(4, "0");
  const mStr = String(month).padStart(2, "0");
  const dStr = String(day).padStart(2, "0");
  const normalized = `${yStr}-${mStr}-${dStr}`;

  return _result(true, {
    normalized,
    format: detectedFormat,
  });
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
