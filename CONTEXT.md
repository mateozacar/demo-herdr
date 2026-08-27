# Guidelines de Implementación

Este documento define las convenciones y reglas de diseño que deben seguir todas las funciones de validación en `utils.js`.

---

## 1. Validación de Entrada
- Usar `_checkInput(value, 'string')` al inicio de cada función para validar el tipo de dato recibido.
- Si el input es inválido (por ejemplo: `null`, `undefined`, números u otros tipos no esperados), no continuar la ejecución y retornar de inmediato el resultado de error correspondiente.

```javascript
if (!_checkInput(input, 'string')) {
  return _result(false, { /* campos en null o valores por defecto */ });
}
```

---

## 2. Formato de Retorno
- Todas las funciones que retornen objetos estructurados deben utilizar el helper `_result(valid, { ...campos })`.
- `valid` debe ser siempre un valor booleano (`true` o `false`).

```javascript
return _result(true, {
  type: 'Visa',
  masked: '****-****-****-1234'
});
```

---

## 3. Manejo de Errores y Excepciones
- **Nunca lanzar excepciones** (`throw Error`, `throw new TypeError`, etc.).
- Ante cualquier entrada inválida o malformada, retornar siempre un objeto con `valid: false` y los campos adicionales seteados en `null` (o el formato definido por la función).

```javascript
// Ejemplo para input inválido
return _result(false, {
  type: null,
  masked: null
});
```

---

## 4. Campos Opcionales y Nulos
- Los campos que no apliquen o no contengan valor deben retornar explícitamente `null`.
- **Nunca retornar `undefined`** en las propiedades del objeto de resultado.

---

## 5. Helpers Disponibles en `utils.js`

### `_checkInput(value, type)`
Verifica que el valor no sea `null` ni `undefined` y que coincida con el `typeof` esperado (`'string'`, etc.).

### `_result(valid, fields)`
Construye el objeto de respuesta asegurando que `valid` sea un booleano y combinando los campos provistos.
