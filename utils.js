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

function _luhnCheck(val) {
  let sum = 0;
  let shouldDouble = false;
  for (let i = val.length - 1; i >= 0; i--) {
    let digit = parseInt(val.charAt(i), 10);
    if (shouldDouble) {
      digit *= 2;
      if (digit > 9) digit -= 9;
    }
    sum += digit;
    shouldDouble = !shouldDouble;
  }
  return sum % 10 === 0;
}

// TODO: implement validateCreditCard(number)
// Luhn algorithm + card type detection (Visa/Mastercard/Amex)
// Returns: { valid: boolean, type: string|null, masked: string|null }
function validateCreditCard(number) {
  if (!_checkInput(number, "string")) {
    return _result(false, { type: null, masked: null });
  }

  const stripped = number.replace(/[\s-]/g, "");
  if (!/^\d+$/.test(stripped)) {
    return _result(false, { type: null, masked: null });
  }

  let type = null;
  if (/^4/.test(stripped) && (stripped.length === 13 || stripped.length === 16 || stripped.length === 19)) {
    type = "Visa";
  } else if (/^5[1-5]/.test(stripped) && stripped.length === 16) {
    type = "Mastercard";
  } else if (/^3[47]/.test(stripped) && stripped.length === 15) {
    type = "Amex";
  }

  if (!type || !_luhnCheck(stripped)) {
    return _result(false, { type: null, masked: null });
  }

  const last4 = stripped.slice(-4);
  const masked = `****-****-****-${last4}`;
  return _result(true, { type, masked });
}

/**
 * Validates password strength based on scoring system (0 to 100):
 * - Length (>=12: +30, >=8: +15, <8: 0)
 * - Uppercase (+15)
 * - Lowercase (+15)
 * - Number (+20)
 * - Symbol (+20)
 * valid = score >= 60
 * Returns: { valid: boolean, score: number, errors: string[] }
 */
function validatePasswordStrength(password) {
  if (!_checkInput(password, "string") || password.length === 0) {
    return _result(false, { score: 0, errors: ["Debe ser un string no vacío"] });
  }

  let score = 0;
  const errors = [];

  if (password.length >= 12) {
    score += 30;
  } else if (password.length >= 8) {
    score += 15;
  } else {
    errors.push("Debe tener al menos 8 caracteres");
  }

  if (/[A-Z]/.test(password)) {
    score += 15;
  } else {
    errors.push("Debe contener al menos una letra mayúscula");
  }

  if (/[a-z]/.test(password)) {
    score += 15;
  } else {
    errors.push("Debe contener al menos una letra minúscula");
  }

  if (/[0-9]/.test(password)) {
    score += 20;
  } else {
    errors.push("Debe contener al menos un número");
  }

  if (/[^a-zA-Z0-9]/.test(password)) {
    score += 20;
  } else {
    errors.push("Debe contener al menos un carácter especial o símbolo");
  }

  if (password.length < 8) {
    score = Math.min(score, 50);
  }

  const valid = score >= 60;

  return _result(valid, {
    score,
    errors: valid ? [] : errors,
  });
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
