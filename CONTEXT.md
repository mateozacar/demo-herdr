# Guidelines para Implementadores

A continuación se detallan las pautas y convenciones para implementar las funciones de validación:

- Usar `_checkInput(value, 'string')` al inicio
- Retornar con `_result(valid, { ...campos })`
- Nunca lanzar excepciones — input inválido retorna `_result(false, { campo: null })`
- Campos opcionales: `null` cuando no aplican (nunca `undefined`)

