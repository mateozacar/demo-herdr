# Guidelines para Implementadores

A continuación se detallan las pautas y convenciones requeridas para implementar las funciones de validación:

- Usar `_checkInput(value, 'string')` al inicio de cada función de validación.
- Retornar siempre con `_result(valid, { ...campos })`.
- Nunca lanzar excepciones — ante un input inválido retornar `_result(false, { campo: null })`.
- Campos opcionales / no aplicables: `null` (nunca `undefined`).
