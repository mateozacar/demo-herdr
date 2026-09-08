# Guía de Implementación

Instrucciones y lineamientos para la implementación de validadores en el proyecto:

- **Validación de entrada inicial**: Usar `_checkInput(value, 'string')` al inicio de cada función validadora.
- **Estructura de retorno estándar**: Retornar siempre usando el helper `_result(valid, { ...campos })`.
- **Manejo de errores y excepciones**: Nunca lanzar excepciones (`throw`). En caso de input inválido o fallas de validación, retornar `_result(false, { campo: null })`.
- **Valores por defecto en campos opcionales**: Asignar `null` cuando un campo opcional no aplique o no esté presente (nunca usar `undefined`).
