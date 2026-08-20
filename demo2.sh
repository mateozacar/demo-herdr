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

TOTAL=3
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
echo "║         Demo HERDR 2 — Supervisor Agent + 4 workers + worktrees          ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  ${BOLD}Run ID:${NC} ${CYAN}${RUN_ID}${NC}"
echo -e "  ${BOLD}Rama de integración:${NC} ${CYAN}${BRANCH_BASE}${NC}"

# ─── paso 1: limpieza + layout de panes ─────────────────────────────────────
step 1 "Limpieza y layout de panes"

if [ -d ".worktrees" ]; then
  for wt_path in .worktrees/*/; do
    [ -d "$wt_path" ] || continue
    git worktree remove "$wt_path" --force 2>/dev/null && ok "worktree removido: $wt_path" || true
  done
fi
git branch | grep -E "feat/run_" | xargs git branch -D 2>/dev/null && dim "ramas feat/run_* eliminadas" || dim "no había ramas feat/run_*"
git checkout -- utils.js 2>/dev/null || true
git checkout -- CONTEXT.md 2>/dev/null || true
[ -f "CONTEXT.md" ] && git rm --cached CONTEXT.md 2>/dev/null && rm -f CONTEXT.md || true

SCRIPT_PANE="${HERDR_PANE_ID}"

SUPER_PANE=$(herdr pane split --pane "$SCRIPT_PANE"  --direction right --cwd "$ROOT" --no-focus | jq -r '.result.pane.pane_id')
ARCH_PANE=$(herdr pane split --pane "$SUPER_PANE"    --direction right --cwd "$ROOT" --no-focus | jq -r '.result.pane.pane_id')
IMPL1_PANE=$(herdr pane split --pane "$ARCH_PANE"    --direction right --cwd "$ROOT" --no-focus | jq -r '.result.pane.pane_id')
IMPL2_PANE=$(herdr pane split --pane "$IMPL1_PANE"   --direction right --cwd "$ROOT" --no-focus | jq -r '.result.pane.pane_id')
IMPL3_PANE=$(herdr pane split --pane "$IMPL2_PANE"   --direction right --cwd "$ROOT" --no-focus | jq -r '.result.pane.pane_id')
QA_PANE=$(herdr pane split --pane "$SUPER_PANE"      --direction down  --cwd "$ROOT" --no-focus | jq -r '.result.pane.pane_id')

ok "supervisor    (${SUPER_PANE})"
ok "arquitecto   (${ARCH_PANE})"
ok "implementador1 — creditcard       (${IMPL1_PANE})"
ok "implementador2 — passwordstrength (${IMPL2_PANE})"
ok "implementador3 — date             (${IMPL3_PANE})"
ok "qa            (${QA_PANE})"

# ─── paso 2: lanzar agentes ─────────────────────────────────────────────────
step 2 "Lanzando 5 agentes workers + 1 supervisor"

herdr agent start supervisor     --kind agy --pane "$SUPER_PANE"  -- --dangerously-skip-permissions > /dev/null
herdr agent start arquitecto     --kind agy --pane "$ARCH_PANE"   -- --dangerously-skip-permissions > /dev/null
herdr agent start implementador1 --kind agy --pane "$IMPL1_PANE"  -- --dangerously-skip-permissions > /dev/null
herdr agent start implementador2 --kind agy --pane "$IMPL2_PANE"  -- --dangerously-skip-permissions > /dev/null
herdr agent start implementador3 --kind agy --pane "$IMPL3_PANE"  -- --dangerously-skip-permissions > /dev/null
herdr agent start qa             --kind agy --pane "$QA_PANE"     -- --dangerously-skip-permissions > /dev/null
ok "6 agentes listos"

# ─── paso 3: entregar el control al supervisor ───────────────────────────────
step 3 "Entregando control al Supervisor Agent"
info "El supervisor toma las decisiones — el bash solo espera."

herdr agent prompt supervisor "$(cat <<SUPERVISOR_PROMPT
Sos el supervisor de este pipeline de desarrollo. Tu trabajo es orquestar a los
demás agentes usando los comandos herdr y git disponibles en tu terminal.

━━━ CONTEXTO DEL RUN ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Run ID:              ${RUN_ID}
Directorio raíz:     ${ROOT}
Rama de integración: ${BRANCH_BASE}
Ramas de workers:    ${BRANCH_CC} | ${BRANCH_PS} | ${BRANCH_DT}
Worktrees:           ${ROOT}/${WT_CC} | ${ROOT}/${WT_PS} | ${ROOT}/${WT_DT}

Agentes disponibles (usá 'herdr agent prompt <nombre> "..."'):
  arquitecto     — escribe código compartido, revisa diffs, crea PRs
  implementador1 — implementa validateCreditCard
  implementador2 — implementa validatePasswordStrength
  implementador3 — implementa validateDate
  qa             — corre tests y reporta resultados

Para esperar que un agente termine: herdr agent wait <nombre> --until idle
Para leer su output:               herdr agent read <nombre> --source recent-unwrapped --lines 60

━━━ PIPELINE QUE DEBÉS EJECUTAR ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

FASE 0 — Arquitecto prepara la base
  Pedile al arquitecto que agregue en utils.js estas dos funciones helpers
  (ANTES de las funciones TODO, después de validatePassword):

    function _checkInput(value, type) {
      if (value === null || value === undefined) return false;
      return typeof value === type;
    }
    function _result(valid, fields) {
      return { valid: Boolean(valid), ...(fields || {}) };
    }

  Y que exporte _checkInput y _result en module.exports.

  También que cree CONTEXT.md con las guidelines para los implementadores:
  - Usar _checkInput(value, 'string') al inicio
  - Retornar con _result(valid, { ...campos })
  - Nunca lanzar excepciones — input inválido retorna _result(false, { campo: null })
  - Campos opcionales: null cuando no aplican (nunca undefined)

  Importante: el arquitecto NO debe hacer git add ni git commit.
  Una vez que termine, vos (supervisor) hacés:
    git checkout -b ${BRANCH_BASE}
    git add utils.js CONTEXT.md
    git commit -m "arch(${RUN_ID}): add shared helpers and context guidelines"
    git push -u origin ${BRANCH_BASE}

  Luego creá los 3 worktrees:
    git worktree add ${ROOT}/${WT_CC} -b ${BRANCH_CC} ${BRANCH_BASE}
    git worktree add ${ROOT}/${WT_PS} -b ${BRANCH_PS} ${BRANCH_BASE}
    git worktree add ${ROOT}/${WT_DT} -b ${BRANCH_DT} ${BRANCH_BASE}

FASE 1 — 3 implementadores en paralelo (en sus worktrees)
  Enviá los 3 prompts seguidos (sin esperar entre ellos), luego esperalos en paralelo:

  implementador1 — validateCreditCard en ${ROOT}/${WT_CC}/utils.js
    - Strippear espacios/guiones
    - Detectar tipo por prefijo: Visa (4), Mastercard (51-55), Amex (34/37)
    - Algoritmo de Luhn para checksum
    - Retornar { valid, type, masked } usando _result() y _checkInput()
    - masked: '****-****-****-XXXX'. null si inválido.
    - Al terminar: npx jest creditcard.test.js en su worktree; si pasa → git add/commit/push

  implementador2 — validatePasswordStrength en ${ROOT}/${WT_PS}/utils.js
    - Scoring (0-100): longitud>=12: +30 | >=8: +15, mayúscula: +15, minúscula: +15, número: +20, símbolo: +20
    - valid = score >= 60
    - errors: array de strings en español con requisitos no cumplidos
    - Al terminar: npx jest passwordstrength.test.js; si pasa → git add/commit/push

  implementador3 — validateDate en ${ROOT}/${WT_DT}/utils.js
    - Formatos: ISO (YYYY-MM-DD), DD/MM/YYYY, MM/DD/YYYY
    - Detección con barras: primer número >12 → DD/MM; segundo >12 → MM/DD; ambos <=12 → DD/MM
    - Validar fecha real con new Date() verificando que los valores no cambien
    - Retornar { valid, normalized, format }; normalized: 'YYYY-MM-DD', null si inválido
    - Al terminar: npx jest date.test.js; si pasa → git add/commit/push

  Para esperar los 3 en paralelo:
    herdr agent wait implementador1 --until idle --timeout 300000 &
    herdr agent wait implementador2 --until idle --timeout 300000 &
    herdr agent wait implementador3 --until idle --timeout 300000 &
    wait

FASE 2 — QA verifica
  Leé el output de los 3 implementadores y pasáselo a QA.
  QA debe correr los tests de los 3 worktrees y reportar: tests pasados/fallidos, status OK/FALLA.
  Esperá a que QA termine.

FASE 3 — Arquitecto revisa y crea PRs
  Leé el reporte de QA.
  Pasáselo al arquitecto junto con instrucciones de:
    - Revisar el diff de cada implementación aprobada por QA:
        git -C ${ROOT}/${WT_CC} diff ${BRANCH_BASE} -- utils.js | head -80
      Verificar que usa _checkInput(), _result(), no lanza excepciones, campos null
    - Crear PRs hacia ${BRANCH_BASE} (NO hacia main) solo para las que pasen QA Y revisión arquitectural:
        gh pr create --base ${BRANCH_BASE} --head ${BRANCH_CC} --title "..." --body "..."
  Si alguna no pasa, describirle al arquitecto qué incumple sin crear su PR.

━━━ REGLAS DE ORQUESTACIÓN ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
- Si un agente falla o reporta errores, decidí si reintentás o continuás sin él
- No avances a la siguiente fase hasta confirmar que la anterior terminó bien
- Al finalizar, mostrá un resumen con las URLs de los PRs creados
SUPERVISOR_PROMPT
)" > /dev/null

info "Supervisor en control — esperando que complete el pipeline..."
herdr agent wait supervisor --until idle --timeout 900000
ok "Pipeline completado"

echo -e "\n${BOLD}${CYAN}"
echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║                       Pipeline completado ✓                              ║"
echo "╚══════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  Run ID: ${BOLD}${RUN_ID}${NC}"
echo ""
echo -e "Comandos para inspeccionar:"
echo -e "  ${CYAN}herdr agent read supervisor   --source recent-unwrapped --lines 80${NC}"
echo -e "  ${CYAN}herdr agent read qa           --source recent-unwrapped --lines 40${NC}"
echo -e "  ${CYAN}gh pr list --base ${BRANCH_BASE}${NC}"
