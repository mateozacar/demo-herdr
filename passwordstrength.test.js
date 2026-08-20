const { validatePasswordStrength } = require("./utils");

describe("validatePasswordStrength", () => {
  // --- contraseñas válidas (score >= 60) ---
  test("contraseña fuerte es válida con score alto", () => {
    const r = validatePasswordStrength("MyStr0ng!Pass");
    expect(r.valid).toBe(true);
    expect(r.score).toBeGreaterThanOrEqual(60);
    expect(r.errors).toHaveLength(0);
  });

  test("contraseña muy larga con todo tiene score máximo o cercano", () => {
    const r = validatePasswordStrength("SuperSecure@Password123");
    expect(r.valid).toBe(true);
    expect(r.score).toBeGreaterThanOrEqual(80);
  });

  // --- contraseñas inválidas (score < 60) ---
  test("contraseña corta (< 8 chars) es inválida", () => {
    const r = validatePasswordStrength("Ab1!");
    expect(r.valid).toBe(false);
    expect(r.score).toBeLessThan(60);
    expect(r.errors.length).toBeGreaterThan(0);
  });

  test("solo minúsculas y números: sin mayúscula ni símbolo, score bajo", () => {
    const r = validatePasswordStrength("password123");
    expect(r.valid).toBe(false);
  });

  test("solo letras minúsculas: máximo penalizado", () => {
    const r = validatePasswordStrength("abcdefgh");
    expect(r.valid).toBe(false);
    expect(r.errors.length).toBeGreaterThan(0);
  });

  // --- scoring relativo ---
  test("contraseña más larga (>= 12) tiene mayor score que una de 8", () => {
    const short = validatePasswordStrength("Passw0rd");
    const long = validatePasswordStrength("LongPassw0rd!");
    expect(long.score).toBeGreaterThan(short.score);
  });

  test("agregar símbolo aumenta el score", () => {
    const sinSimbolo = validatePasswordStrength("MyPassw0rd");
    const conSimbolo = validatePasswordStrength("MyPassw0rd!");
    expect(conSimbolo.score).toBeGreaterThan(sinSimbolo.score);
  });

  test("agregar mayúscula aumenta el score", () => {
    const sinMayus = validatePasswordStrength("mypassw0rd!");
    const conMayus = validatePasswordStrength("MyPassw0rd!");
    expect(conMayus.score).toBeGreaterThan(sinMayus.score);
  });

  // --- campo errors ---
  test("errors lista los requisitos faltantes como strings", () => {
    const r = validatePasswordStrength("abcdefgh");
    expect(Array.isArray(r.errors)).toBe(true);
    r.errors.forEach((e) => expect(typeof e).toBe("string"));
  });

  test("contraseña válida tiene errors vacío", () => {
    const r = validatePasswordStrength("MyStr0ng!Pass");
    expect(r.errors).toHaveLength(0);
  });

  // --- manejo de input inválido ---
  test("null retorna valid=false sin lanzar excepción", () => {
    const r = validatePasswordStrength(null);
    expect(r.valid).toBe(false);
  });

  test("número (no string) retorna valid=false", () => {
    const r = validatePasswordStrength(12345678);
    expect(r.valid).toBe(false);
  });

  test("string vacío retorna valid=false", () => {
    const r = validatePasswordStrength("");
    expect(r.valid).toBe(false);
  });

  // --- estructura del retorno ---
  test("siempre retorna objeto con las 3 claves", () => {
    const r = validatePasswordStrength("MyStr0ng!Pass");
    expect(r).toHaveProperty("valid");
    expect(r).toHaveProperty("score");
    expect(r).toHaveProperty("errors");
  });

  test("score es un número entre 0 y 100", () => {
    const r = validatePasswordStrength("Test1234!");
    expect(r.score).toBeGreaterThanOrEqual(0);
    expect(r.score).toBeLessThanOrEqual(100);
  });

  test("valid siempre es boolean", () => {
    expect(typeof validatePasswordStrength("MyStr0ng!Pass").valid).toBe("boolean");
    expect(typeof validatePasswordStrength(null).valid).toBe("boolean");
  });
});
