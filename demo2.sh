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
step()  { echo -e "\n${YELLOW}━━━ [${1}/${TOTAL}] ${2}${NC}"; }
ok()    { echo -e "  ${GREEN}✓${NC} ${1}"; }
info()  { echo -e "  ${CYAN}→${NC} ${1}"; }
dim()   { echo -e "  ${DIM}${1}${NC}"; }
err()   { echo -e "${RED}Error: ${1}${NC}" >&2; exit 1; }

# ─── guardia: debe correr dentro de HERDR ───────────────────────────────────
[[ "${HERDR_ENV:-}" == "1" ]] || err "Este script debe ejecutarse dentro de HERDR.\nAbrí HERDR con:  cd $(pwd) && herdr"

cd "$(dirname "$0")"
ROOT="$PWD"

# ─── run id único por ejecución ─────────────────────────────────────────────
RUN_ID=$(date +%Y%m%d_%H%M%S)
BRANCH_BASE="feat/run_${RUN_ID}"
BRANCH_CC="${BRANCH_BASE}-creditcard"
BRANCH_PS="${BRANCH_BASE}-passwordstrength"
BRANCH_DT="${BRANCH_BASE}-date"
WT_CC=".worktrees/${RUN_ID}-creditcard"
WT_PS=".worktrees/${RUN_ID}-passwordstrength"
WT_DT=".worktrees/${RUN_ID}-date"

echo -e "${BOLD}${CYAN}"
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║         Demo HERDR 2 — 5 agentes, worktrees, contexto compartido         ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  ${BOLD}Run ID:${NC} ${CYAN}${RUN_ID}${NC}"
echo -e "  ${BOLD}Rama de integración:${NC} ${CYAN}${BRANCH_BASE}${NC}"
echo -e "  ${BOLD}Ramas de implementadores:${NC}"
echo -e "    ${DIM}${BRANCH_CC}${NC}"
echo -e "    ${DIM}${BRANCH_PS}${NC}"
echo -e "    ${DIM}${BRANCH_DT}${NC}"

# ─── paso 0: limpieza de ejecuciones anteriores ─────────────────────────────
step 0 "Limpieza de ejecuciones anteriores"

# Remover todos los worktrees bajo .worktrees/ (de cualquier run anterior)
if [ -d ".worktrees" ]; then
  for wt_path in .worktrees/*/; do
    [ -d "$wt_path" ] || continue
    git worktree remove "$wt_path" --force 2>/dev/null && ok "worktree removido: $wt_path" || true
  done
fi

# Eliminar ramas locales de runs anteriores
git branch | grep -E "feat/run_" | xargs git branch -D 2>/dev/null && dim "ramas feat/run_* locales eliminadas" || dim "no había ramas feat/run_* locales"

# Limpiar utils.js de helpers de runs anteriores (si el arquitecto los dejó sin commitear)
git checkout -- utils.js 2>/dev/null || true
git checkout -- CONTEXT.md 2>/dev/null || true
[ -f "CONTEXT.md" ] && git rm --cached CONTEXT.md 2>/dev/null && rm -f CONTEXT.md || true

# ─── paso 1: layout de panes ────────────────────────────────────────────────
step 1 "Creando layout: orquestador | arquitecto | impl×3 | QA"

SCRIPT_PANE="${HERDR_PANE_ID}"
info "Pane orquestador:              ${SCRIPT_PANE}"

ARCH_PANE=$(herdr pane split --pane "$SCRIPT_PANE"  --direction right --cwd "$ROOT" --no-focus | jq -r '.result.pane.pane_id')
info "Pane arquitecto:               ${ARCH_PANE}"

IMPL1_PANE=$(herdr pane split --pane "$ARCH_PANE"   --direction right --cwd "$ROOT" --no-focus | jq -r '.result.pane.pane_id')
info "Pane implementador1 (creditcard):       ${IMPL1_PANE}"

IMPL2_PANE=$(herdr pane split --pane "$IMPL1_PANE"  --direction right --cwd "$ROOT" --no-focus | jq -r '.result.pane.pane_id')
info "Pane implementador2 (passwordstrength): ${IMPL2_PANE}"

IMPL3_PANE=$(herdr pane split --pane "$IMPL2_PANE"  --direction right --cwd "$ROOT" --no-focus | jq -r '.result.pane.pane_id')
info "Pane implementador3 (date):             ${IMPL3_PANE}"

QA_PANE=$(herdr pane split --pane "$ARCH_PANE"      --direction down  --cwd "$ROOT" --no-focus | jq -r '.result.pane.pane_id')
info "Pane QA:                       ${QA_PANE}"

# ─── paso 2: lanzar los 5 agentes ────────────────────────────────────────────
step 2 "Lanzando 5 agentes Antigravity (agy)"

herdr agent start arquitecto     --kind agy --pane "$ARCH_PANE"  -- --dangerously-skip-permissions > /dev/null
ok "arquitecto     (${ARCH_PANE})"

herdr agent start implementador1 --kind agy --pane "$IMPL1_PANE" -- --dangerously-skip-permissions > /dev/null
ok "implementador1 (${IMPL1_PANE})"

herdr agent start implementador2 --kind agy --pane "$IMPL2_PANE" -- --dangerously-skip-permissions > /dev/null
ok "implementador2 (${IMPL2_PANE})"

herdr agent start implementador3 --kind agy --pane "$IMPL3_PANE" -- --dangerously-skip-permissions > /dev/null
ok "implementador3 (${IMPL3_PANE})"

herdr agent start qa             --kind agy --pane "$QA_PANE"    -- --dangerously-skip-permissions > /dev/null
ok "qa             (${QA_PANE})"

# ─── paso 3: FASE 0 — arquitecto produce helpers y contexto ─────────────────
step 3 "FASE 0 — Arquitecto analiza el proyecto y produce helpers + CONTEXT.md"
info "El arquitecto escribe los archivos. El orquestador controla git."

PROMPT_ARCH_0="Sos el arquitecto de este proyecto de validación. Tu trabajo es preparar la base para los implementadores.

TAREA 1 — helpers compartidos en utils.js:
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

TAREA 2 — CONTEXT.md con guidelines para los implementadores:
Creá el archivo CONTEXT.md en el directorio raíz:

\`\`\`markdown
# Guía para implementadores — run ${RUN_ID}

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

\\\`\\\`\\\`javascript
function validateAlgo(input) {
  if (!_checkInput(input, 'string')) return _result(false, { campo: null });
  // ... lógica ...
  return _result(true, { campo: valor });
}
\\\`\\\`\\\`
\`\`\`

IMPORTANTE: NO hagas git add ni git commit. El orquestador controla git.
Confirmá cuando hayas terminado de escribir ambos archivos."

herdr agent prompt arquitecto "$PROMPT_ARCH_0" --wait --timeout 240000 > /dev/null
ok "Arquitecto terminó — utils.js y CONTEXT.md escritos"

# El orquestador toma el control de git: crea la rama de integración y commitea
info "Orquestador: creando rama de integración ${BRANCH_BASE} y commiteando helpers..."
git checkout -b "$BRANCH_BASE"
git add utils.js CONTEXT.md
git commit -m "arch(${RUN_ID}): add shared helpers and context guidelines"
git push -u origin "$BRANCH_BASE"
ok "Rama ${BRANCH_BASE} creada y pusheada"

# Capturar el contexto del arquitecto para inyectarlo en los implementadores
ARCH_CONTEXT=$(herdr agent read arquitecto --source recent-unwrapped --lines 60)
ok "Contexto del arquitecto capturado ($(echo "$ARCH_CONTEXT" | wc -w | tr -d ' ') palabras)"

# ─── paso 4: crear worktrees desde la rama de integración ────────────────────
step 4 "Creando 3 worktrees desde ${BRANCH_BASE}"

git worktree add "$WT_CC" -b "$BRANCH_CC" "$BRANCH_BASE"
ok "${BRANCH_CC} → ${WT_CC}"

git worktree add "$WT_PS" -b "$BRANCH_PS" "$BRANCH_BASE"
ok "${BRANCH_PS} → ${WT_PS}"

git worktree add "$WT_DT" -b "$BRANCH_DT" "$BRANCH_BASE"
ok "${BRANCH_DT} → ${WT_DT}"

# ─── paso 5: FASE 1 — 3 implementadores en paralelo ─────────────────────────
step 5 "FASE 1 — 3 implementadores trabajando en paralelo"
info "Tareas enviadas simultáneamente — cada uno en su worktree aislado..."

PROMPT_IMPL1="El arquitecto del proyecto te dejó este contexto:
---
${ARCH_CONTEXT}
---

Tu worktree de trabajo es: ${ROOT}/${WT_CC}
Estás en la rama: ${BRANCH_CC}
El package.json y los tests ya están — no necesitás npm install.

Tu tarea: implementar validateCreditCard(number) en ${ROOT}/${WT_CC}/utils.js

Lógica requerida:
1. Strippear espacios y guiones del input
2. Detectar tipo por prefijo: Visa (empieza con 4), Mastercard (51-55), Amex (34 o 37). Sin match → type: null
3. Algoritmo de Luhn para validar el checksum
4. Retornar usando _result(): { valid, type, masked }
   - masked: '****-****-****-XXXX' con los últimos 4 dígitos. null si inválido.
   - Usar _checkInput() y _result() del arquitecto — están en utils.js

Al terminar:
1. cd ${ROOT}/${WT_CC} && npx jest creditcard.test.js
2. Si todos los tests pasan:
   git -C ${ROOT}/${WT_CC} add utils.js
   git -C ${ROOT}/${WT_CC} commit -m 'feat(${RUN_ID}): implement validateCreditCard with Luhn algorithm'
   git -C ${ROOT}/${WT_CC} push -u origin ${BRANCH_CC}
3. Reportá: tests pasados/fallidos y decisiones de diseño relevantes."

PROMPT_IMPL2="El arquitecto del proyecto te dejó este contexto:
---
${ARCH_CONTEXT}
---

Tu worktree de trabajo es: ${ROOT}/${WT_PS}
Estás en la rama: ${BRANCH_PS}
El package.json y los tests ya están — no necesitás npm install.

Tu tarea: implementar validatePasswordStrength(password) en ${ROOT}/${WT_PS}/utils.js

Sistema de scoring (total 100pts):
- Longitud >= 12 chars: +30pts | >= 8 chars: +15pts (solo uno)
- Al menos una mayúscula: +15pts
- Al menos una minúscula: +15pts
- Al menos un número: +20pts
- Al menos un símbolo (!@#\$%^&*()_+-=[]{}|;':\",./<>?): +20pts
valid = score >= 60
errors: array de strings en español con los requisitos que NO cumple

Retornar usando _result(): { valid, score, errors }
Usar _checkInput() y _result() del arquitecto — están en utils.js.

Al terminar:
1. cd ${ROOT}/${WT_PS} && npx jest passwordstrength.test.js
2. Si todos los tests pasan:
   git -C ${ROOT}/${WT_PS} add utils.js
   git -C ${ROOT}/${WT_PS} commit -m 'feat(${RUN_ID}): implement validatePasswordStrength with scoring system'
   git -C ${ROOT}/${WT_PS} push -u origin ${BRANCH_PS}
3. Reportá: tests pasados/fallidos y decisiones de diseño relevantes."

PROMPT_IMPL3="El arquitecto del proyecto te dejó este contexto:
---
${ARCH_CONTEXT}
---

Tu worktree de trabajo es: ${ROOT}/${WT_DT}
Estás en la rama: ${BRANCH_DT}
El package.json y los tests ya están — no necesitás npm install.

Tu tarea: implementar validateDate(input) en ${ROOT}/${WT_DT}/utils.js

Formatos a aceptar:
- ISO: YYYY-MM-DD (separador guión)
- DD/MM/YYYY y MM/DD/YYYY (separador barra)

Detección de formato con barras:
- Primer número > 12 → DD/MM/YYYY
- Segundo número > 12 → MM/DD/YYYY
- Ambos <= 12 → intentar DD/MM/YYYY primero

Validación de fecha real: usar new Date(year, month-1, day) y verificar que los valores no hayan cambiado (ej: new Date(2024, 1, 30) se convierte en marzo).

Retornar usando _result(): { valid, normalized, format }
- normalized: 'YYYY-MM-DD'. null si inválido.
- format: 'ISO' | 'DD/MM/YYYY' | 'MM/DD/YYYY'. null si inválido.
Usar _checkInput() y _result() del arquitecto — están en utils.js.

Al terminar:
1. cd ${ROOT}/${WT_DT} && npx jest date.test.js
2. Si todos los tests pasan:
   git -C ${ROOT}/${WT_DT} add utils.js
   git -C ${ROOT}/${WT_DT} commit -m 'feat(${RUN_ID}): implement validateDate with multi-format support'
   git -C ${ROOT}/${WT_DT} push -u origin ${BRANCH_DT}
3. Reportá: tests pasados/fallidos y decisiones de diseño relevantes."

# Lanzar los 3 en paralelo
herdr agent prompt implementador1 "$PROMPT_IMPL1" --wait --timeout 300000 > /dev/null &
PID1=$!
herdr agent prompt implementador2 "$PROMPT_IMPL2" --wait --timeout 300000 > /dev/null &
PID2=$!
herdr agent prompt implementador3 "$PROMPT_IMPL3" --wait --timeout 300000 > /dev/null &
PID3=$!

info "Los 3 implementadores están trabajando en paralelo..."
wait $PID1 $PID2 $PID3
ok "Los 3 implementadores terminaron"

# Capturar resúmenes para QA y arquitecto (context sharing)
IMPL1_SUMMARY=$(herdr agent read implementador1 --source recent-unwrapped --lines 30)
IMPL2_SUMMARY=$(herdr agent read implementador2 --source recent-unwrapped --lines 30)
IMPL3_SUMMARY=$(herdr agent read implementador3 --source recent-unwrapped --lines 30)
ok "Resúmenes capturados de los 3 implementadores"

# ─── paso 6: FASE 2 — QA verifica + Arquitecto revisa y crea PRs ─────────────
step 6 "FASE 2 — QA verifica tests | Arquitecto revisa y crea PRs hacia ${BRANCH_BASE}"

PROMPT_QA="Los implementadores de este run (${RUN_ID}) reportaron:

IMPLEMENTADOR 1 — validateCreditCard (rama ${BRANCH_CC}):
${IMPL1_SUMMARY}

IMPLEMENTADOR 2 — validatePasswordStrength (rama ${BRANCH_PS}):
${IMPL2_SUMMARY}

IMPLEMENTADOR 3 — validateDate (rama ${BRANCH_DT}):
${IMPL3_SUMMARY}

Tu tarea: verificar la calidad corriendo los tests de cada implementación.

Ejecutá:
  cd ${ROOT}/${WT_CC} && npx jest creditcard.test.js --no-coverage 2>&1 | tail -15
  cd ${ROOT}/${WT_PS} && npx jest passwordstrength.test.js --no-coverage 2>&1 | tail -15
  cd ${ROOT}/${WT_DT} && npx jest date.test.js --no-coverage 2>&1 | tail -15

Reportá para cada una:
- Rama: ${BRANCH_CC} / ${BRANCH_PS} / ${BRANCH_DT}
- Tests pasados: N | Tests fallidos: N
- Status: OK / FALLA
- Observaciones: (si hay fallos, cuáles específicamente)

Sé conciso. El arquitecto usará este reporte para decidir qué PRs crear."

herdr agent prompt qa "$PROMPT_QA" --wait --timeout 240000 > /dev/null
ok "QA terminó"

QA_REPORT=$(herdr agent read qa --source recent-unwrapped --lines 50)

PROMPT_ARCH_2B="Sos el mismo arquitecto del run ${RUN_ID}.

REPORTE DEL QA:
${QA_REPORT}

Tu tarea final: verificar que las implementaciones aprobadas por QA siguen las guidelines de CONTEXT.md, y crear los PRs hacia la rama de integración ${BRANCH_BASE} (NO hacia main).

Para cada implementación que QA marcó OK, revisá el diff:
  git -C ${ROOT}/${WT_CC} diff ${BRANCH_BASE} -- utils.js | head -80
  git -C ${ROOT}/${WT_PS} diff ${BRANCH_BASE} -- utils.js | head -80
  git -C ${ROOT}/${WT_DT} diff ${BRANCH_BASE} -- utils.js | head -80

Verificá en cada diff:
  ✓ Usa _checkInput() al inicio
  ✓ Usa _result() para el retorno
  ✓ No lanza excepciones
  ✓ Campos opcionales son null (no undefined)

Para cada una que pase QA Y arquitectura, creá el PR hacia ${BRANCH_BASE}:
  gh pr create --base ${BRANCH_BASE} --head ${BRANCH_CC} \
    --title 'feat(${RUN_ID}): implement validateCreditCard with Luhn algorithm' \
    --body 'Algoritmo de Luhn, detección de tipo Visa/MC/Amex, masked output. Usa helpers del arquitecto. Tests pasando.'

  gh pr create --base ${BRANCH_BASE} --head ${BRANCH_PS} \
    --title 'feat(${RUN_ID}): implement validatePasswordStrength with scoring system' \
    --body 'Scoring 0-100 con 5 dimensiones, errors en español. Usa helpers del arquitecto. Tests pasando.'

  gh pr create --base ${BRANCH_BASE} --head ${BRANCH_DT} \
    --title 'feat(${RUN_ID}): implement validateDate with multi-format support' \
    --body 'Soporte ISO/DD-MM/MM-DD con detección automática, validación de fechas reales. Usa helpers del arquitecto. Tests pasando.'

Si alguna NO pasa la revisión arquitectural: describí qué incumple y NO crees su PR.
Mostrá las URLs de los PRs creados."

herdr agent prompt arquitecto "$PROMPT_ARCH_2B" --wait --timeout 240000 > /dev/null
ok "Arquitecto terminó — PRs creados en ${BRANCH_BASE}"

# ─── resumen final ───────────────────────────────────────────────────────────
echo -e "\n${BOLD}${GREEN}"
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║                       Pipeline completado ✓                              ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  Run ID: ${BOLD}${RUN_ID}${NC}"
echo ""
echo -e "  ${CYAN}FASE 0${NC}   Arquitecto escribió helpers — orquestador commiteó en ${BRANCH_BASE}"
echo -e "  ${CYAN}FASE 1${NC}   3 implementadores en paralelo en worktrees aislados"
echo -e "  ${CYAN}FASE 2${NC}   QA verificó tests de las 3 ramas"
echo -e "  ${CYAN}FASE 2b${NC}  Arquitecto revisó diffs → PRs hacia ${BRANCH_BASE}"
echo ""
echo -e "Comandos:"
echo -e "  ${CYAN}gh pr list --base ${BRANCH_BASE}${NC}"
echo -e "  ${CYAN}herdr agent read arquitecto --source recent-unwrapped --lines 60${NC}"
echo -e "  ${CYAN}herdr agent read qa         --source recent-unwrapped --lines 40${NC}"
