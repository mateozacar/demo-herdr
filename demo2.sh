#!/usr/bin/env bash
set -euo pipefail

# ─── colores ────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

TOTAL=6
step()  { echo -e "\n${YELLOW}━━━ [${1}/${TOTAL}] ${2} ${NC}"; }
ok()    { echo -e "  ${GREEN}✓${NC} ${1}"; }
info()  { echo -e "  ${CYAN}→${NC} ${1}"; }
dim()   { echo -e "  ${DIM}${1}${NC}"; }
err()   { echo -e "${RED}Error: ${1}${NC}" >&2; exit 1; }
header(){ echo -e "${BOLD}${CYAN}${1}${NC}"; }

# ─── guardia: debe correr dentro de HERDR ───────────────────────────────────
[[ "${HERDR_ENV:-}" == "1" ]] || err "Este script debe ejecutarse dentro de HERDR.\nAbrí HERDR con:  cd $(pwd) && herdr"

cd "$(dirname "$0")"
ROOT="$PWD"

echo -e "${BOLD}${CYAN}"
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║         Demo HERDR 2 — 5 agentes, worktrees, contexto compartido         ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ─── paso 0: limpieza de estado anterior ────────────────────────────────────
step 0 "Limpieza de ejecuciones anteriores"

for wt in creditcard passwordstrength date; do
  if git worktree list | grep -q ".worktrees/$wt"; then
    git worktree remove ".worktrees/$wt" --force 2>/dev/null || true
    ok "worktree $wt removido"
  fi
done

git branch -D feat/validate-creditcard feat/validate-passwordstrength feat/validate-date 2>/dev/null || true
dim "ramas anteriores eliminadas (si existían)"

# ─── paso 1: layout de panes ────────────────────────────────────────────────
step 1 "Creando layout: arquitecto | impl×3 | QA"

SCRIPT_PANE="${HERDR_PANE_ID}"
info "Pane orquestador: ${SCRIPT_PANE}"

# Fila superior: arquitecto (derecha del orquestador)
ARCH_PANE=$(herdr pane split --pane "$SCRIPT_PANE" --direction right --cwd "$ROOT" --no-focus | jq -r '.result.pane.pane_id')
info "Pane arquitecto:   ${ARCH_PANE}"

# Fila media: 3 implementadores (splits del arquitecto hacia la derecha)
IMPL1_PANE=$(herdr pane split --pane "$ARCH_PANE" --direction right --cwd "$ROOT" --no-focus | jq -r '.result.pane.pane_id')
info "Pane impl1 (creditcard):      ${IMPL1_PANE}"

IMPL2_PANE=$(herdr pane split --pane "$IMPL1_PANE" --direction right --cwd "$ROOT" --no-focus | jq -r '.result.pane.pane_id')
info "Pane impl2 (passwordstrength): ${IMPL2_PANE}"

IMPL3_PANE=$(herdr pane split --pane "$IMPL2_PANE" --direction right --cwd "$ROOT" --no-focus | jq -r '.result.pane.pane_id')
info "Pane impl3 (date):            ${IMPL3_PANE}"

# Fila inferior: QA (debajo del arquitecto)
QA_PANE=$(herdr pane split --pane "$ARCH_PANE" --direction down --cwd "$ROOT" --no-focus | jq -r '.result.pane.pane_id')
info "Pane QA:           ${QA_PANE}"

# ─── paso 2: lanzar los 5 agentes ────────────────────────────────────────────
step 2 "Lanzando 5 agentes Antigravity (agy)"

herdr agent start arquitecto     --kind agy --pane "$ARCH_PANE"  -- --dangerously-skip-permissions > /dev/null
ok "arquitecto listo  (${ARCH_PANE})"

herdr agent start implementador1 --kind agy --pane "$IMPL1_PANE" -- --dangerously-skip-permissions > /dev/null
ok "implementador1 listo (creditcard) (${IMPL1_PANE})"

herdr agent start implementador2 --kind agy --pane "$IMPL2_PANE" -- --dangerously-skip-permissions > /dev/null
ok "implementador2 listo (passwordstrength) (${IMPL2_PANE})"

herdr agent start implementador3 --kind agy --pane "$IMPL3_PANE" -- --dangerously-skip-permissions > /dev/null
ok "implementador3 listo (date) (${IMPL3_PANE})"

herdr agent start qa             --kind agy --pane "$QA_PANE"   -- --dangerously-skip-permissions > /dev/null
ok "QA listo (${QA_PANE})"

# ─── paso 3: FASE 0 — arquitecto analiza y genera contexto ──────────────────
step 3 "FASE 0 — Arquitecto analiza el proyecto y escribe los helpers compartidos"
info "El arquitecto lee el código, escribe _checkInput/_result y produce CONTEXT.md..."

PROMPT_ARCH_0="Sos el arquitecto de este proyecto de validación. Tu trabajo es hacer dos cosas antes de que arranquen los implementadores.

PRIMERA TAREA — helpers compartidos en utils.js:
Abrí utils.js y agregá estas dos funciones ANTES de las funciones TODO (después de validatePassword):

\`\`\`javascript
// Shared helpers — written by architect, used by all validators
function _checkInput(value, type) {
  if (value === null || value === undefined) return false;
  return typeof value === type;
}

function _result(valid, fields) {
  return { valid: Boolean(valid), ...(fields || {}) };
}
\`\`\`

Agregá también _checkInput y _result al module.exports al final del archivo.

SEGUNDA TAREA — CONTEXT.md con las guidelines:
Creá un archivo CONTEXT.md en el directorio raíz con este contenido exacto (adaptando si querés el texto):

\`\`\`markdown
# Guía para implementadores

## Reglas que TODOS deben seguir

1. Usar _checkInput(value, 'string') al inicio de cada función para validar el tipo de input
2. Retornar siempre con _result(valid, { ...campos }) — nunca un objeto literal directamente
3. Nunca lanzar excepciones — todo input inválido debe retornar _result(false, { campo: null, ... })
4. El campo valid siempre es boolean (Boolean() convierte automáticamente)
5. Los campos opcionales deben ser null cuando no aplican (no undefined)

## Estructura esperada de cada validador

- validateCreditCard(number) → _result(valid, { type, masked })
- validatePasswordStrength(password) → _result(valid, { score, errors })
- validateDate(input) → _result(valid, { normalized, format })

## Cómo usar los helpers

\\\`\\\`\\\`javascript
function validateAlgo(input) {
  if (!_checkInput(input, 'string')) return _result(false, { campo: null });
  // ... lógica ...
  return _result(true, { campo: valor });
}
\\\`\\\`\\\`
\`\`\`

Cuando termines ambas tareas, hacé: git add utils.js CONTEXT.md && git commit -m 'arch: add shared helpers and context guidelines'

Confirmá cuando el commit esté hecho."

herdr agent prompt arquitecto "$PROMPT_ARCH_0" --wait --timeout 240000 > /dev/null
ok "Arquitecto terminó — helpers y CONTEXT.md commiteados en main"

# Leer el contexto producido por el arquitecto para inyectarlo en los implementadores
info "Leyendo contexto del arquitecto para los implementadores..."
ARCH_CONTEXT=$(herdr agent read arquitecto --source recent-unwrapped --lines 60)
ok "Contexto del arquitecto capturado ($(echo "$ARCH_CONTEXT" | wc -w | tr -d ' ') palabras)"

# ─── paso 4: crear worktrees y hacer pull del commit del arquitecto ───────────
step 4 "Creando 3 worktrees aislados desde main (con los helpers del arquitecto)"

git pull origin main --rebase 2>/dev/null || true

git worktree add ".worktrees/creditcard"      feat/validate-creditcard
ok "worktree feat/validate-creditcard      → .worktrees/creditcard"

git worktree add ".worktrees/passwordstrength" feat/validate-passwordstrength
ok "worktree feat/validate-passwordstrength → .worktrees/passwordstrength"

git worktree add ".worktrees/date"            feat/validate-date
ok "worktree feat/validate-date             → .worktrees/date"

# ─── paso 5: FASE 1 — 3 implementadores en paralelo ─────────────────────────
step 5 "FASE 1 — 3 implementadores trabajando en paralelo"
info "Enviando tareas simultáneamente — cada uno en su worktree aislado..."

PROMPT_IMPL1="El arquitecto del proyecto te dejó este contexto:
---
${ARCH_CONTEXT}
---

Tu worktree de trabajo es: ${ROOT}/.worktrees/creditcard (rama feat/validate-creditcard)
El package.json y los tests ya están ahí — no necesitás npm install.

Tu tarea: implementar validateCreditCard(number) en ${ROOT}/.worktrees/creditcard/utils.js

Algoritmo requerido:
1. Strippear espacios y guiones del input
2. Detectar tipo de tarjeta por prefijo: Visa (empieza con 4), Mastercard (51-55), Amex (34 o 37). Si no matchea ninguno: type = null
3. Algoritmo de Luhn para validar el checksum
4. Retornar usando _result() del arquitecto: { valid, type, masked }
   - masked: '****-****-****-XXXX' con los últimos 4 dígitos. null si inválido.
   - Seguir EXACTAMENTE las convenciones de CONTEXT.md

Cuando termines:
- Corré: cd ${ROOT}/.worktrees/creditcard && npx jest creditcard.test.js
- Si pasan todos los tests: git -C ${ROOT}/.worktrees/creditcard add utils.js && git -C ${ROOT}/.worktrees/creditcard commit -m 'feat: implement validateCreditCard with Luhn algorithm' && git -C ${ROOT}/.worktrees/creditcard push -u origin feat/validate-creditcard
- Reportá: cuántos tests pasaron, cuántos fallaron, y cualquier decisión de diseño relevante."

PROMPT_IMPL2="El arquitecto del proyecto te dejó este contexto:
---
${ARCH_CONTEXT}
---

Tu worktree de trabajo es: ${ROOT}/.worktrees/passwordstrength (rama feat/validate-passwordstrength)
El package.json y los tests ya están ahí — no necesitás npm install.

Tu tarea: implementar validatePasswordStrength(password) en ${ROOT}/.worktrees/passwordstrength/utils.js

Sistema de scoring requerido (total 100pts):
- Longitud >= 12 chars: +30pts / Longitud >= 8 chars: +15pts (solo uno aplica)
- Tiene al menos una mayúscula: +15pts
- Tiene al menos una minúscula: +15pts
- Tiene al menos un número: +20pts
- Tiene al menos un símbolo (!@#\$%^&*()_+-=[]{}|;':\",./<>?): +20pts
valid = score >= 60
errors: array de strings en español describiendo cada requisito que NO cumple

Retornar usando _result() del arquitecto: { valid, score, errors }
Seguir EXACTAMENTE las convenciones de CONTEXT.md.

Cuando termines:
- Corré: cd ${ROOT}/.worktrees/passwordstrength && npx jest passwordstrength.test.js
- Si pasan todos los tests: git -C ${ROOT}/.worktrees/passwordstrength add utils.js && git -C ${ROOT}/.worktrees/passwordstrength commit -m 'feat: implement validatePasswordStrength with scoring system' && git -C ${ROOT}/.worktrees/passwordstrength push -u origin feat/validate-passwordstrength
- Reportá: cuántos tests pasaron, cuántos fallaron, y cualquier decisión de diseño relevante."

PROMPT_IMPL3="El arquitecto del proyecto te dejó este contexto:
---
${ARCH_CONTEXT}
---

Tu worktree de trabajo es: ${ROOT}/.worktrees/date (rama feat/validate-date)
El package.json y los tests ya están ahí — no necesitás npm install.

Tu tarea: implementar validateDate(input) en ${ROOT}/.worktrees/date/utils.js

Formatos a aceptar:
- ISO: YYYY-MM-DD (separador: guión)
- DD/MM/YYYY y MM/DD/YYYY (separador: barra)

Detección automática de formato para /barras:
- Si el primer número > 12: es DD/MM/YYYY (no puede ser mes)
- Si el segundo número > 12: es MM/DD/YYYY (no puede ser día en pos 2 siendo mes)
- Si ambos son <= 12: intentá DD/MM/YYYY primero

Validación de fecha real:
- Usar Date de JS para verificar que la fecha es válida (ej: new Date(year, month-1, day))
- Comparar que day/month/year siguen siendo los mismos después de construir el Date

Retornar usando _result() del arquitecto: { valid, normalized, format }
- normalized: siempre 'YYYY-MM-DD'. null si inválido.
- format: 'ISO', 'DD/MM/YYYY', o 'MM/DD/YYYY'. null si inválido.
Seguir EXACTAMENTE las convenciones de CONTEXT.md.

Cuando termines:
- Corré: cd ${ROOT}/.worktrees/date && npx jest date.test.js
- Si pasan todos los tests: git -C ${ROOT}/.worktrees/date add utils.js && git -C ${ROOT}/.worktrees/date commit -m 'feat: implement validateDate with multi-format support' && git -C ${ROOT}/.worktrees/date push -u origin feat/validate-date
- Reportá: cuántos tests pasaron, cuántos fallaron, y cualquier decisión de diseño relevante."

# Lanzar los 3 en paralelo con background processes de bash
herdr agent prompt implementador1 "$PROMPT_IMPL1" --wait --timeout 300000 > /dev/null &
PID1=$!

herdr agent prompt implementador2 "$PROMPT_IMPL2" --wait --timeout 300000 > /dev/null &
PID2=$!

herdr agent prompt implementador3 "$PROMPT_IMPL3" --wait --timeout 300000 > /dev/null &
PID3=$!

info "Los 3 implementadores están trabajando en paralelo..."
wait $PID1 $PID2 $PID3
ok "Los 3 implementadores terminaron"

# Capturar resúmenes de cada implementador (context sharing → QA y arquitecto)
info "Capturando resúmenes de los implementadores para QA y arquitecto..."
IMPL1_SUMMARY=$(herdr agent read implementador1 --source recent-unwrapped --lines 30)
IMPL2_SUMMARY=$(herdr agent read implementador2 --source recent-unwrapped --lines 30)
IMPL3_SUMMARY=$(herdr agent read implementador3 --source recent-unwrapped --lines 30)
ok "Resúmenes capturados"

# ─── paso 6a: FASE 2 — QA verifica tests en las 3 ramas ─────────────────────
step 6 "FASE 2 — QA verifica tests + Arquitecto revisa y crea los PRs"
info "QA corriendo los tests de las 3 implementaciones..."

PROMPT_QA="Los implementadores reportaron lo siguiente:

IMPLEMENTADOR 1 (validateCreditCard, rama feat/validate-creditcard):
${IMPL1_SUMMARY}

IMPLEMENTADOR 2 (validatePasswordStrength, rama feat/validate-passwordstrength):
${IMPL2_SUMMARY}

IMPLEMENTADOR 3 (validateDate, rama feat/validate-date):
${IMPL3_SUMMARY}

Tu tarea: verificar la calidad de las 3 implementaciones corriendo los tests específicos de cada una.

Ejecutá estos comandos y reportá el resultado:
  cd ${ROOT}/.worktrees/creditcard && npx jest creditcard.test.js --no-coverage 2>&1 | tail -15
  cd ${ROOT}/.worktrees/passwordstrength && npx jest passwordstrength.test.js --no-coverage 2>&1 | tail -15
  cd ${ROOT}/.worktrees/date && npx jest date.test.js --no-coverage 2>&1 | tail -15

Para cada implementación reportá en formato estructurado:
- Rama: feat/validate-XXX
- Tests pasados: N
- Tests fallidos: N
- Status: OK / FALLA
- Observaciones: (si hay fallos, cuáles específicamente)

Sé conciso y estructurado. El arquitecto va a usar este reporte para decidir qué PRs crear."

herdr agent prompt qa "$PROMPT_QA" --wait --timeout 240000 > /dev/null
ok "QA terminó — reporte listo"

QA_REPORT=$(herdr agent read qa --source recent-unwrapped --lines 50)

# ─── paso 6b: FASE 2b — arquitecto verifica y crea PRs ───────────────────────
info "Arquitecto revisando implementaciones y creando PRs..."

PROMPT_ARCH_2B="Sos el mismo arquitecto que diseñó este sistema al inicio.

REPORTE DEL QA:
${QA_REPORT}

Tu tarea final: verificar que las implementaciones que el QA aprobó siguen las guidelines arquitecturales de CONTEXT.md, y crear los PRs correspondientes.

Para cada implementación que el QA marcó como OK, revisá el diff:
  git -C ${ROOT}/.worktrees/creditcard diff main -- utils.js | head -80
  git -C ${ROOT}/.worktrees/passwordstrength diff main -- utils.js | head -80
  git -C ${ROOT}/.worktrees/date diff main -- utils.js | head -80

Verificá en cada diff:
  ✓ Usa _checkInput() al inicio
  ✓ Usa _result() para el retorno
  ✓ No lanza excepciones
  ✓ Campos opcionales son null (no undefined) cuando no aplican

Para cada implementación que pase TANTO el QA COMO la revisión arquitectural, creá el PR:
  gh pr create --base main --head feat/validate-creditcard \
    --title 'feat: implement validateCreditCard with Luhn algorithm' \
    --body 'Implementación del algoritmo de Luhn con detección de tipo (Visa/MC/Amex) y masked output. Usa helpers compartidos del arquitecto. Suite completa de tests pasando.'

  gh pr create --base main --head feat/validate-passwordstrength \
    --title 'feat: implement validatePasswordStrength with scoring system' \
    --body 'Sistema de scoring 0-100 con 5 dimensiones. Retorna score, valid y errors en español. Usa helpers compartidos del arquitecto. Suite completa de tests pasando.'

  gh pr create --base main --head feat/validate-date \
    --title 'feat: implement validateDate with multi-format support' \
    --body 'Soporte para ISO, DD/MM/YYYY y MM/DD/YYYY con detección automática. Validación de fechas reales (bisiestos, meses de 30/31 días). Usa helpers compartidos del arquitecto. Suite completa de tests pasando.'

Si alguna implementación NO pasa la revisión arquitectural, describí exactamente qué incumple y NO crees su PR.

Mostrá las URLs de los PRs creados al final."

herdr agent prompt arquitecto "$PROMPT_ARCH_2B" --wait --timeout 240000 > /dev/null
ok "Arquitecto terminó — PRs creados para las implementaciones aprobadas"

# ─── resumen final ───────────────────────────────────────────────────────────
echo -e "\n${BOLD}${GREEN}"
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║                       Pipeline completado ✓                              ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "Qué pasó:"
echo -e "  ${CYAN}FASE 0${NC}  Arquitecto → analizó código, escribió _checkInput/_result, generó CONTEXT.md"
echo -e "  ${CYAN}FASE 1${NC}  3 implementadores en paralelo → cada uno en worktree aislado, con contexto del arquitecto"
echo -e "  ${CYAN}FASE 2${NC}  QA → corrió tests de las 3 ramas y reportó al arquitecto"
echo -e "  ${CYAN}FASE 2b${NC} Arquitecto → revisó diffs, verificó guidelines, creó PRs aprobados"
echo ""
echo -e "Comandos útiles:"
echo -e "  ${CYAN}gh pr list${NC}"
echo -e "  ${CYAN}herdr agent read arquitecto --source recent-unwrapped --lines 60${NC}"
echo -e "  ${CYAN}herdr agent read qa --source recent-unwrapped --lines 40${NC}"
