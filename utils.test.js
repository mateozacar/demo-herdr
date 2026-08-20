const { validateUsername, validatePhone, validatePassword, validateEmail } = require("./utils");

// --- validateUsername ---
test("username válido", () => {
  expect(validateUsername("mateo_99")).toBe(true);
});
test("username demasiado corto", () => {
  expect(validateUsername("ab")).toBe(false);
});
test("username con caracteres especiales", () => {
  expect(validateUsername("mateo@dev")).toBe(false);
});

// --- validatePhone ---
test("teléfono con prefijo +", () => {
  expect(validatePhone("+541155558888")).toBe(true);
});
test("teléfono sin prefijo", () => {
  expect(validatePhone("541155558888")).toBe(true);
});
test("teléfono con letras", () => {
  expect(validatePhone("5411abc8888")).toBe(false);
});

// --- validatePassword ---
test("contraseña válida", () => {
  expect(validatePassword("Segura123")).toBe(true);
});
test("contraseña sin mayúscula", () => {
  expect(validatePassword("segura123")).toBe(false);
});
test("contraseña corta", () => {
  expect(validatePassword("Cor1")).toBe(false);
});

// --- validateEmail (pendiente de implementar) ---
test("email válido simple", () => {
  expect(validateEmail("user@example.com")).toBe(true);
});
test("email con subdominio", () => {
  expect(validateEmail("user@mail.example.com")).toBe(true);
});
test("email sin arroba", () => {
  expect(validateEmail("userexample.com")).toBe(false);
});
test("email sin dominio", () => {
  expect(validateEmail("user@")).toBe(false);
});
test("email vacío", () => {
  expect(validateEmail("")).toBe(false);
});
test("email null", () => {
  expect(validateEmail(null)).toBe(false);
});
