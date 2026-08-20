#!/usr/bin/env bash
set -euo pipefail

# ─── colores ────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

step()  { echo -e "\n${YELLOW}[${1}/${TOTAL}] ${2}${NC}"; }
ok()    { echo -e "  ${GREEN}✓${NC} ${1}"; }
info()  { echo -e "  ${CYAN}→${NC} ${1}"; }
err()   { echo -e "${RED}Error: ${1}${NC}" >&2; exit 1; }

TOTAL=5

# ─── guardia: debe correr dentro de HERDR ───────────────────────────────────
[[ "${HERDR_ENV:-}" == "1" ]] || err "Este script debe ejecutarse dentro de HERDR.\nAbrí HERDR con:  cd $(pwd) && herdr"

cd "$(dirname "$0")"

echo -e "${BOLD}${CYAN}"
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║       Demo HERDR — dos agentes Antigravity (agy), un pipeline     ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ─── paso 1: estado inicial ──────────────────────────────────────────────────
step 1 "Estado inicial del proyecto"
info "Corriendo npm test..."
npm test 2>&1 | grep -E "✓|✕|Tests:|Test Suites:" || true

# ─── paso 2: dividir pantalla ────────────────────────────────────────────────
step 2 "Creando layout: orquestador | implementador | reviewer"

# El script corre en este pane (orquestador) — los agentes van en panes nuevos
SCRIPT_PANE="${HERDR_PANE_ID}"
info "Pane orquestador: ${SCRIPT_PANE}"

# Primer split → pane del implementador
SPLIT1=$(herdr pane split --pane "$SCRIPT_PANE" --direction right --cwd "$PWD" --no-focus)
IMPL_PANE=$(echo "$SPLIT1" | jq -r '.result.pane.pane_id')
info "Pane implementador: ${IMPL_PANE}"

# Segundo split desde el pane del implementador → pane del reviewer
SPLIT2=$(herdr pane split --pane "$IMPL_PANE" --direction right --cwd "$PWD" --no-focus)
REVIEWER_PANE=$(echo "$SPLIT2" | jq -r '.result.pane.pane_id')
info "Pane reviewer:      ${REVIEWER_PANE}"

# ─── paso 3: lanzar agentes ──────────────────────────────────────────────────
step 3 "Lanzando dos instancias de Antigravity (agy)"

herdr agent start implementador --kind agy --pane "$IMPL_PANE" -- --dangerously-skip-permissions > /dev/null
ok "implementador listo  (pane ${IMPL_PANE})"

herdr agent start reviewer --kind agy --pane "$REVIEWER_PANE" -- --dangerously-skip-permissions > /dev/null
ok "reviewer listo       (pane ${REVIEWER_PANE})"

# ─── paso 4: tarea para el implementador ────────────────────────────────────
step 4 "Enviando tarea al implementador"
info "Implementar validateEmail() y pasar los 6 tests..."

PROMPT_IMPL="Implementa la función validateEmail(email) en utils.js: valida formato básico de email (usuario@dominio.ext), retorna true/false, maneja null y valores no-string sin errores. Agrégala al module.exports junto a las otras funciones. Al terminar ejecuta npm test"

herdr agent prompt implementador "$PROMPT_IMPL" --wait --timeout 180000 > /dev/null

ok "implementador terminó"

# ─── paso 5: reviewer analiza el diff ────────────────────────────────────────
step 5 "El reviewer analiza el trabajo del implementador"
info "Revisando el diff automáticamente..."

PROMPT_REVIEW="El agente implementador acaba de agregar validateEmail() a utils.js. Ejecuta git diff para ver los cambios y analiza: 1) edge cases no cubiertos por los tests, 2) problemas con la regex si usó una, 3) consistencia con el estilo del resto del archivo. Sé directo y conciso."

herdr agent prompt reviewer "$PROMPT_REVIEW" --wait --timeout 180000 > /dev/null

ok "reviewer terminó"

# ─── resumen ─────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}${GREEN}"
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                     Pipeline completado ✓                        ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "Ver análisis del reviewer:"
echo -e "  ${CYAN}herdr agent read reviewer --source recent-unwrapped --lines 50${NC}"
