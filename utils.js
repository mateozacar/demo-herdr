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
  if (!_checkInput(number, "string")) {
    return _result(false, { type: null, masked: null });
  }

  const cleaned = number.replace(/[\s-]/g, "");
  if (!/^\d+$/.test(cleaned)) {
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

  const isValid = type !== null && sum % 10 === 0;

  return _result(isValid, {
    type: isValid ? type : null,
    masked: isValid ? `****-****-****-${cleaned.slice(-4)}` : null,
  });
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
  if (!_checkInput(password, "string")) {
    return _result(false, { score: 0, errors: ["Debe ser un string"] });
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

function validateDate(input) {
  if (!_checkInput(input, 'string')) {
    return _result(false, { normalized: null, format: null });
  }

  let year, month, day, format;

  const isoMatch = /^(\d{4})-(\d{2})-(\d{2})$/.exec(input);
  const slashMatch = /^(\d{2})\/(\d{2})\/(\d{4})$/.exec(input);

  if (isoMatch) {
    year = parseInt(isoMatch[1], 10);
    month = parseInt(isoMatch[2], 10);
    day = parseInt(isoMatch[3], 10);
    format = 'ISO';
  } else if (slashMatch) {
    const num1 = parseInt(slashMatch[1], 10);
    const num2 = parseInt(slashMatch[2], 10);
    year = parseInt(slashMatch[3], 10);

    if (num1 > 12) {
      format = 'DD/MM/YYYY';
      day = num1;
      month = num2;
    } else if (num2 > 12) {
      format = 'MM/DD/YYYY';
      month = num1;
      day = num2;
    } else {
      format = 'DD/MM/YYYY';
      day = num1;
      month = num2;
    }
  } else {
    return _result(false, { normalized: null, format: null });
  }

  const d = new Date(year, month - 1, day);
  const isValid =
    d.getFullYear() === year &&
    d.getMonth() === month - 1 &&
    d.getDate() === day;

  if (!isValid) {
    return _result(false, { normalized: null, format: null });
  }

  const normalized = `${String(year).padStart(4, '0')}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;

  return _result(true, {
    normalized,
    format,
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
