const { validateCreditCard } = require("./utils");

describe("validateCreditCard", () => {
  // --- tipos de tarjeta ---
  test("Visa: número válido detectado correctamente", () => {
    const r = validateCreditCard("4111111111111111");
    expect(r.valid).toBe(true);
    expect(r.type).toBe("Visa");
  });

  test("Mastercard: número válido detectado correctamente", () => {
    const r = validateCreditCard("5500005555555559");
    expect(r.valid).toBe(true);
    expect(r.type).toBe("Mastercard");
  });

  test("Amex: número válido detectado correctamente", () => {
    const r = validateCreditCard("378282246310005");
    expect(r.valid).toBe(true);
    expect(r.type).toBe("Amex");
  });

  // --- algoritmo de Luhn ---
  test("checksum Luhn inválido retorna valid=false", () => {
    const r = validateCreditCard("4111111111111112");
    expect(r.valid).toBe(false);
  });

  test("número con todos los dígitos iguales falla Luhn", () => {
    const r = validateCreditCard("1111111111111111");
    expect(r.valid).toBe(false);
  });

  // --- formato del campo masked ---
  test("masked muestra solo los últimos 4 dígitos", () => {
    const r = validateCreditCard("4111111111111111");
    expect(r.masked).toBe("****-****-****-1111");
  });

  test("masked es null cuando el número es inválido", () => {
    const r = validateCreditCard("4111111111111112");
    expect(r.masked).toBeNull();
  });

  // --- normalización de input ---
  test("acepta número con espacios", () => {
    const r = validateCreditCard("4111 1111 1111 1111");
    expect(r.valid).toBe(true);
  });

  test("acepta número con guiones", () => {
    const r = validateCreditCard("4111-1111-1111-1111");
    expect(r.valid).toBe(true);
  });

  // --- manejo de input inválido ---
  test("null retorna valid=false sin lanzar excepción", () => {
    const r = validateCreditCard(null);
    expect(r.valid).toBe(false);
  });

  test("número (no string) retorna valid=false", () => {
    const r = validateCreditCard(4111111111111111);
    expect(r.valid).toBe(false);
  });

  test("string vacío retorna valid=false", () => {
    const r = validateCreditCard("");
    expect(r.valid).toBe(false);
  });

  test("letras retornan valid=false", () => {
    const r = validateCreditCard("abcd-efgh-ijkl-mnop");
    expect(r.valid).toBe(false);
  });

  // --- estructura del retorno ---
  test("siempre retorna objeto con las 3 claves", () => {
    const r = validateCreditCard("4111111111111111");
    expect(r).toHaveProperty("valid");
    expect(r).toHaveProperty("type");
    expect(r).toHaveProperty("masked");
  });

  test("valid siempre es boolean", () => {
    expect(typeof validateCreditCard("4111111111111111").valid).toBe("boolean");
    expect(typeof validateCreditCard(null).valid).toBe("boolean");
  });
});
