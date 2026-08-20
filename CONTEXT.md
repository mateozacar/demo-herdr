# Guía para implementadores — run 20260820_123746

## Reglas que TODOS deben seguir

1. Usar _checkInput(value, 'string') al inicio para validar el tipo de input
2. Retornar siempre con _result(valid, { ...campos }) — nunca un objeto literal
3. Nunca lanzar excepciones — input inválido retorna _result(false, { campo: null, ... })
4. El campo valid siempre es boolean (Boolean() lo garantiza)
5. Campos opcionales: null cuando no aplican (nunca undefined)

## Estructura esperada de cada validador

- validateCreditCard(number)        → _result(valid, { type, masked })
- validatePasswordStrength(password) → _result(valid, { score, errors })
- validateDate(input)               → _result(valid, { normalized, format })

## Cómo usar los helpers

```javascript
function validateAlgo(input) {
  if (!_checkInput(input, 'string')) return _result(false, { campo: null });
  // ... lógica ...
  return _result(true, { campo: valor });
}
```
