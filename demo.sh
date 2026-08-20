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
info "Creando rama, implementando validateEmail(), tests, commit y push..."

PROMPT_IMPL="Crea una rama llamada feat/validate-email (git checkout -b feat/validate-email). Luego implementa la función validateEmail(email) en utils.js: valida formato básico de email (usuario@dominio.ext), retorna true/false, maneja null y valores no-string sin errores. Agrégala al module.exports junto a las otras funciones. Ejecuta npm test para verificar que los 15 tests pasen. Finalmente haz commit de los cambios (git add utils.js && git commit -m 'feat: implement validateEmail') y haz push al remoto (git push -u origin feat/validate-email)."

herdr agent prompt implementador "$PROMPT_IMPL" --wait --timeout 180000 > /dev/null

ok "implementador terminó (rama pusheada)"

# ─── paso 5: reviewer analiza el diff y crea PR ──────────────────────────────
step 5 "El reviewer analiza el trabajo y crea el Pull Request"
info "Revisando cambios, validando tests y creando PR..."

PROMPT_REVIEW="Revisa el trabajo del implementador en la rama feat/validate-email. Ejecuta git log -1 y git diff main...HEAD para analizar los cambios. Ejecuta npm test para confirmar que todos los tests pasen. Si todo está correcto y los tests pasan, crea el Pull Request hacia main usando GitHub CLI: gh pr create --base main --head feat/validate-email --title 'feat: implement validateEmail function' --body 'Implementación de validateEmail con manejo de null/no-strings y paso de suite completa de tests.' y muestra la URL del PR creado."

herdr agent prompt reviewer "$PROMPT_REVIEW" --wait --timeout 180000 > /dev/null

ok "reviewer terminó (PR creado)"

# ─── resumen ─────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}${GREEN}"
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                     Pipeline completado ✓                        ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "Ver Pull Requests y análisis del reviewer:"
echo -e "  ${CYAN}gh pr list${NC}"
echo -e "  ${CYAN}herdr agent read reviewer --source recent-unwrapped --lines 50${NC}"
