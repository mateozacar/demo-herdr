# Guidelines de Implementación para el Pipeline de Validación

Este documento define las reglas y estándares para los implementadores al escribir funciones de validación en este proyecto (`utils.js`).

## Reglas Principales

1. **Validación inicial del tipo de entrada:**
   - Usar `_checkInput(value, 'string')` (o el tipo correspondiente) al inicio de cada función de validación.

2. **Formato uniforme de retorno:**
   - Retornar los resultados utilizando el helper `_result(valid, { ...campos })`.
   - El primer argumento es un booleano `valid` (`true` o `false`).
   - El segundo argumento es un objeto con los campos resultantes requeridos por la especificación de la función.

3. **Manejo de errores / Excepciones:**
   - **Nunca lanzar excepciones** (`throw`).
   - Si la entrada es inválida o no cumple el tipo esperado, retornar `_result(false, { campo: null, ... })` con los campos configurados en `null`.

4. **Campos opcionales y valores vacíos:**
   - Usar `null` cuando un campo no aplique o sea nulo.
   - **Nunca usar `undefined`** como valor en los objetos de resultado.

---

### Ejemplo de Estructura

```javascript
function validateExample(input) {
  if (!_checkInput(input, 'string')) {
    return _result(false, { data: null });
  }

  // Lógica de validación...
  if (isValid) {
    return _result(true, { data: processedValue });
  }

  return _result(false, { data: null });
}
```
