# Guidelines de Implementación

Este documento define los estándares y convenciones que deben seguir todos los implementadores al desarrollar funciones en `utils.js`.

---

## 1. Validación de Entrada

- Siempre validar el tipo de dato de entrada al inicio de cada función usando el helper `_checkInput`.
- Ejemplo:
  ```javascript
  if (!_checkInput(value, 'string')) {
    return _result(false, { /* campos correspondientes en null */ });
  }
  ```

---

## 2. Retorno Estandarizado

- Utilizar la función helper `_result(valid, { ...campos })` para construir el objeto de respuesta.
- La función garantiza que la propiedad `valid` sea un booleano (`Boolean(valid)`).
- Ejemplo:
  ```javascript
  return _result(true, {
    type: 'Visa',
    masked: '************1111'
  });
  ```

---

## 3. Manejo de Errores y Excepciones

- **Nunca lanzar excepciones**: bajo ningún concepto lanzar errores (`throw new Error(...)`) ante entradas inválidas, inesperadas, `null` o `undefined`.
- Cualquier entrada inválida debe retornar un resultado con `valid: false` y los campos de salida en `null`:
  ```javascript
  return _result(false, { campo: null });
  ```

---

## 4. Campos Opcionales y Valores Nulos

- Los campos opcionales o no aplicables deben ser explícitamente `null` cuando no apliquen.
- **Nunca retornar `undefined`**.
