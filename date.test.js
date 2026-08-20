const { validateDate } = require("./utils");

describe("validateDate", () => {
  // --- formato ISO (YYYY-MM-DD) ---
  test("ISO válido retorna correct normalized y format", () => {
    const r = validateDate("2024-01-15");
    expect(r.valid).toBe(true);
    expect(r.normalized).toBe("2024-01-15");
    expect(r.format).toBe("ISO");
  });

  test("ISO: 29 de febrero en año bisiesto es válido", () => {
    const r = validateDate("2024-02-29");
    expect(r.valid).toBe(true);
    expect(r.normalized).toBe("2024-02-29");
  });

  test("ISO: 29 de febrero en año no bisiesto es inválido", () => {
    const r = validateDate("2023-02-29");
    expect(r.valid).toBe(false);
  });

  test("ISO: 31 de noviembre es inválido", () => {
    const r = validateDate("2024-11-31");
    expect(r.valid).toBe(false);
  });

  test("ISO: mes 00 es inválido", () => {
    const r = validateDate("2024-00-15");
    expect(r.valid).toBe(false);
  });

  // --- formato DD/MM/YYYY ---
  test("DD/MM/YYYY válido con día > 12 (sin ambigüedad)", () => {
    const r = validateDate("15/01/2024");
    expect(r.valid).toBe(true);
    expect(r.normalized).toBe("2024-01-15");
    expect(r.format).toBe("DD/MM/YYYY");
  });

  test("DD/MM/YYYY: 29/02 en año bisiesto es válido", () => {
    const r = validateDate("29/02/2024");
    expect(r.valid).toBe(true);
    expect(r.normalized).toBe("2024-02-29");
  });

  test("DD/MM/YYYY: 31/04 (abril no tiene 31) es inválido", () => {
    const r = validateDate("31/04/2024");
    expect(r.valid).toBe(false);
  });

  // --- formato MM/DD/YYYY ---
  test("MM/DD/YYYY válido con día > 12 en posición 2 (sin ambigüedad)", () => {
    const r = validateDate("01/15/2024");
    expect(r.valid).toBe(true);
    expect(r.normalized).toBe("2024-01-15");
    expect(r.format).toBe("MM/DD/YYYY");
  });

  test("MM/DD/YYYY: mes 13 es inválido", () => {
    const r = validateDate("13/15/2024");
    expect(r.valid).toBe(false);
  });

  // --- normalized siempre en ISO ---
  test("normalized siempre tiene formato YYYY-MM-DD", () => {
    const r = validateDate("15/06/2024");
    expect(r.valid).toBe(true);
    expect(r.normalized).toMatch(/^\d{4}-\d{2}-\d{2}$/);
  });

  test("normalized es null cuando la fecha es inválida", () => {
    const r = validateDate("2024-13-01");
    expect(r.normalized).toBeNull();
  });

  test("format es null cuando la fecha es inválida", () => {
    const r = validateDate("not-a-date");
    expect(r.format).toBeNull();
  });

  // --- manejo de input inválido ---
  test("null retorna valid=false sin lanzar excepción", () => {
    const r = validateDate(null);
    expect(r.valid).toBe(false);
  });

  test("número (no string) retorna valid=false", () => {
    const r = validateDate(20240115);
    expect(r.valid).toBe(false);
  });

  test("string vacío retorna valid=false", () => {
    const r = validateDate("");
    expect(r.valid).toBe(false);
  });

  test("string aleatorio retorna valid=false", () => {
    const r = validateDate("hola mundo");
    expect(r.valid).toBe(false);
  });

  test("fecha con separadores incorrectos retorna valid=false", () => {
    const r = validateDate("2024.01.15");
    expect(r.valid).toBe(false);
  });

  // --- estructura del retorno ---
  test("siempre retorna objeto con las 3 claves", () => {
    const r = validateDate("2024-01-15");
    expect(r).toHaveProperty("valid");
    expect(r).toHaveProperty("normalized");
    expect(r).toHaveProperty("format");
  });

  test("valid siempre es boolean", () => {
    expect(typeof validateDate("2024-01-15").valid).toBe("boolean");
    expect(typeof validateDate(null).valid).toBe("boolean");
  });
});
