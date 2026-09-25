# Guía de Implementación y Contexto para Desarrolladores

Este documento establece las directrices de arquitectura y los estándares que todos los implementadores deben seguir al agregar o modificar funciones de validación en este proyecto.

---

## Directrices Obligatorias

### 1. Validación de Entrada al Inicio
- Toda función debe verificar su entrada usando el helper `_checkInput(value, 'string')` al inicio.
- Si el input no es válido (ej. `null`, `undefined` o de un tipo diferente al esperado), se debe retornar inmediatamente un resultado inválido.

```javascript
if (!_checkInput(input, 'string')) {
  return _result(false, { /* campos correspondientes en null o valor por defecto */ });
}
```

### 2. Estructura de Retorno Estandarizada
- Todas las funciones que retornan objetos de resultado deben usar el helper `_result(valid, { ...campos })`.
- El helper garantiza que la propiedad `valid` sea un booleano estricto (`true` o `false`).

```javascript
return _result(true, {
  type: "Visa",
  masked: "****-****-****-1111"
});
```

### 3. Manejo de Errores: Nunca Lanzar Excepciones
- **Bajo ninguna circunstancia se deben lanzar excepciones** (`throw Error`, `TypeError`, etc.) ante entradas inesperadas o inválidas.
- Cualquier input inválido (`null`, `undefined`, números pasados donde se espera string, strings vacíos o cadenas no parseables) debe ser manejado de forma segura retornando:
  ```javascript
  _result(false, { campo: null })
  ```

### 4. Campos Opcionales y Valores Nulos
- Cuando un campo no aplique o el resultado sea inválido, el valor debe ser explícitamente `null` (o el tipo vacío especificado en el contrato, como un array vacío `[]` para listas de errores).
- **Nunca retornar `undefined`** para campos esperados en el objeto de respuesta.
- Todos los objetos devueltos deben mantener una estructura consistente de claves.

---

## Helpers Disponibles en `utils.js`

```javascript
function _checkInput(value, type) {
  if (value === null || value === undefined) return false;
  return typeof value === type;
}

function _result(valid, fields) {
  return { valid: Boolean(valid), ...(fields || {}) };
}
```

Ambos helpers se encuentran exportados en `utils.js` para su uso y testeo.

---

## Contratos de las Funciones Pendientes (TODO)

### `validateCreditCard(number)`
- **Propósito**: Validación de número de tarjeta mediante el algoritmo de Luhn y detección de emisor (Visa, Mastercard, Amex). Normaliza espacios y guiones.
- **Retorno**: `{ valid: boolean, type: string|null, masked: string|null }`
- **Comportamiento ante error / input inválido**:
  ```javascript
  return _result(false, { type: null, masked: null });
  ```

### `validatePasswordStrength(password)`
- **Propósito**: Análisis de seguridad de contraseña con puntaje de 0 a 100 y lista de sugerencias o errores (`valid = score >= 60`).
- **Retorno**: `{ valid: boolean, score: number, errors: string[] }`
- **Comportamiento ante error / input inválido**:
  ```javascript
  return _result(false, { score: 0, errors: ["Input inválido o vacío"] });
  ```

### `validateDate(input)`
- **Propósito**: Valida fechas reales en formatos ISO (`YYYY-MM-DD`), `DD/MM/YYYY` y `MM/DD/YYYY` (detectando años bisiestos y días por mes).
- **Retorno**: `{ valid: boolean, normalized: string|null, format: string|null }`
- **Comportamiento ante error / input inválido**:
  ```javascript
  return _result(false, { normalized: null, format: null });
  ```

---

## Resumen Rápido para Implementadores
1. Validar al entrar: `if (!_checkInput(val, 'string')) return _result(false, { ... });`
2. Formatear salida con `_result(isValid, { ... })`.
3. Cero `throw`.
4. Usar `null`, jamás `undefined`.
