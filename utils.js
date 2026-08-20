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

// Score-based analysis (0-100): length, uppercase, lowercase, numbers, symbols
// Returns: { valid: boolean, score: number, errors: string[] }
// valid = score >= 60
function validatePasswordStrength(password) {
  if (!_checkInput(password, "string")) {
    return _result(false, {
      score: 0,
      errors: ["La contraseña debe ser una cadena de texto"],
    });
  }

  const errors = [];
  let score = 0;

  // Length scoring: >= 12 (+30pts) | >= 8 (+15pts)
  if (password.length >= 12) {
    score += 30;
  } else if (password.length >= 8) {
    score += 15;
  } else {
    errors.push("La contraseña debe tener al menos 8 caracteres");
  }

  // Uppercase letter (+15pts)
  if (/[A-Z]/.test(password)) {
    score += 15;
  } else {
    errors.push("Debe contener al menos una letra mayúscula");
  }

  // Lowercase letter (+15pts)
  if (/[a-z]/.test(password)) {
    score += 15;
  } else {
    errors.push("Debe contener al menos una letra minúscula");
  }

  // Number (+20pts)
  if (/[0-9]/.test(password)) {
    score += 20;
  } else {
    errors.push("Debe contener al menos un número");
  }

  // Special symbol (+20pts) from !@#$%^&*()_+-=[]{}|;':",./<>?
  const symbolRegex = /[!@#$%^&*()_+\-=\[\]{}|;':",./<>?]/;
  if (symbolRegex.test(password)) {
    score += 20;
  } else {
    errors.push("Debe contener al menos un símbolo");
  }

  // A password shorter than 8 characters is invalid and capped below 60
  if (password.length < 8) {
    score = Math.min(score, 50);
  }

  const valid = score >= 60;

  return _result(valid, { score, errors });
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

