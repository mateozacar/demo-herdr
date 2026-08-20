# Guía de Presentación — Herdr

> Referencia oficial: https://herdr.dev/docs/

---

## 0. Agenda

```
1. Flujo tradicional             ← punto de dolor
2. ¿Qué es Herdr?                ← solución
3. ¿Por qué usarlo?              ← valor
4. Ventajas clave                ← beneficios
5. Cuándo NO usarlo              ← honestidad
6. Herdr vs /agents + BMAD       ← pregunta frecuente
7. Buenas prácticas              ← cómo hacerlo bien
8. Memoria y contexto            ← patrones clave
9. Demo 2 en vivo                ← código real
10. Horizonte: multi-modelo      ← qué sigue
```

---

## 1. Flujo Tradicional

```
┌─────────────────────────────────────────────────────────────┐
│  SIN HERDR — flujo secuencial                               │
│                                                             │
│   Dev          Terminal          Agente                     │
│    │                                                        │
│    ├──── abre terminal ──────────────────►                  │
│    │                                                        │
│    ├──── lanza agente 1 ────────────────►│                  │
│    │                    espera...        │                  │
│    │◄──────────────── respuesta ─────────┘                  │
│    │                                                        │
│    ├──── copia output ─────────────────►                    │
│    │                                                        │
│    ├──── lanza agente 2 ────────────────►│                  │
│    │                    espera...        │                  │
│    │◄──────────────── respuesta ─────────┘                  │
│    │                                                        │
│    └──── repite manualmente para cada tarea                 │
│                                                             │
│  Problemas:                                                 │
│  ✗ Secuencial — un agente a la vez                          │
│  ✗ Sin visibilidad de estado (¿está trabajando o colgado?)  │
│  ✗ Contexto se pierde entre sesiones                        │
│  ✗ Coordinación manual entre agentes                        │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. ¿Qué es Herdr?

> "Herdr is the runtime your coding agents live on — laptop, desktop, or a box you rent."

```
┌─────────────────────────────────────────────────────────────┐
│                         HERDR                               │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              servidor persistente                    │  │
│  │                                                      │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐           │  │
│  │  │  Tab 1   │  │  Tab 2   │  │  Tab 3   │   ...      │  │
│  │  │ supervisor│  │arquitecto│  │implementadores│       │  │
│  │  │  [idle]  │  │ [working]│  │[working][working]│    │  │
│  │  └──────────┘  └──────────┘  └──────────┘           │  │
│  │                                                      │  │
│  │         CLI / Socket API (misma superficie)          │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  • Terminal multiplexer  +  runtime de agentes              │
│  • Sesiones persisten aunque cierres la laptop              │
│  • Claude Code, Codex, Cursor, Copilot, opencode, Grok...  │
│  • 1 binario — macOS / Linux / Windows                      │
└─────────────────────────────────────────────────────────────┘
```

**Instalación:**
```bash
curl -fsSL https://herdr.dev/install.sh | sh
herdr          # abre la sesión
```

---

## 3. ¿Por qué usarlo?

```
              SIN HERDR                    CON HERDR
           ──────────────               ──────────────
           
           [Agente 1] ──→ done          [Agente 1] ──┐
                                        [Agente 2] ──┼──→ done (paralelo)
           [Agente 2] ──→ done          [Agente 3] ──┘
           
           [Agente 3] ──→ done          Tiempo total = el más lento
           
           Tiempo total = suma
```

| Necesidad | Sin Herdr | Con Herdr |
|-----------|-----------|-----------|
| Múltiples agentes en paralelo | Manual, una terminal por agente | Nativo, con visibilidad de estado |
| Sesión persiste al cerrar laptop | Se pierde | Continúa automáticamente |
| Agente A habla con Agente B | Copiar/pegar manual | `herdr agent prompt` |
| Saber si un agente está colgado | Revisar manualmente | Estado visual: idle / working / blocked |
| Orquestación programática | Scripts complejos con tmux | API unificada CLI + socket |

---

## 4. Ventajas Clave

```
┌────────────────────────────────────────────────────────────┐
│                                                            │
│  1. PERSISTENCIA                                           │
│     laptop cerrada ──→ agentes siguen trabajando           │
│     restart ──→ Herdr restaura layout y sesiones           │
│                                                            │
│  2. VISIBILIDAD                                            │
│     cada pane tiene estado:                                │
│     [idle] [working] [blocked] ← bubble-up visual          │
│                                                            │
│  3. COMUNICACIÓN ENTRE AGENTES                             │
│     Agente puede:                                          │
│       herdr pane split ...       → crear espacio           │
│       herdr agent start ...      → lanzar otro agente      │
│       herdr agent prompt <name>  → enviar tarea            │
│       herdr agent wait <name>    → esperar resultado        │
│                                                            │
│  4. SIN MODIFICAR TU STACK                                 │
│     Claude Code, Codex, Cursor, Grok... funcionan          │
│     exactamente igual que antes                            │
│                                                            │
│  5. COMUNIDAD                                              │
│     30k ★ GitHub  |  491k instalaciones  |  705 plugins    │
└────────────────────────────────────────────────────────────┘
```

---

## 5. Cuándo NO Usarlo

```
┌──────────────────────────────────┐  ┌───────────────────────────────────┐
│  ✗ NO es ideal si...             │  │  ✓ SÍ es ideal si...              │
│                                  │  │                                   │
│  • Tarea simple de 1 agente      │  │  • Múltiples agentes en paralelo  │
│  • Solo exploración / prototipo  │  │  • Pipeline con fases definidas   │
│  • Sin necesidad de estado       │  │  • Sesiones de larga duración     │
│    persistente                   │  │  • Necesitás orquestación         │
│  • No hay coordinación entre     │  │    supervisor → workers           │
│    agentes                       │  │  • Quierés visibilidad de estado  │
│  • Overhead no vale la pena      │  │  • Equipos con múltiples devs     │
│    para scripts cortos           │  │    corriendo agentes              │
└──────────────────────────────────┘  └───────────────────────────────────┘
```

---

## 6. Herdr vs /agents + BMAD

> Pregunta frecuente: ¿BMAD con subagentes no resuelve lo mismo?

### Capa de abstracción — dónde vive cada uno

```
┌─────────────────────────────────────────────────────────────┐
│  /agents + BMAD                                             │
│                                                             │
│  ┌──────────────────────────────────────────────────┐       │
│  │           1 proceso de Claude Code               │       │
│  │                                                  │       │
│  │  orquestador                                     │       │
│  │    └── Agent tool → subagente A                  │       │
│  │    └── Agent tool → subagente B  ← comparten     │       │
│  │    └── Agent tool → subagente C    el mismo      │       │
│  │                      context window del padre    │       │
│  └──────────────────────────────────────────────────┘       │
│                                                             │
│  ─────────────────────────────────────────────────────      │
│                                                             │
│  Herdr                                                      │
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │proceso A │  │proceso B │  │proceso C │  │proceso D │    │
│  │ contexto │  │ contexto │  │ contexto │  │ contexto │    │
│  │ propio   │  │ propio   │  │ propio   │  │ propio   │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
│                                                             │
│         procesos del OS — verdaderamente aislados           │
└─────────────────────────────────────────────────────────────┘
```

### Comparación directa

| Dimensión | `/agents` + BMAD | Herdr |
|-----------|-----------------|-------|
| **Nivel** | Dentro de Claude Code | Runtime del OS |
| **Contexto** | Compartido — subagentes consumen el contexto del padre | Independiente — cada proceso tiene el suyo |
| **Paralelismo** | Limitado por el context window | Verdadero — procesos OS en paralelo |
| **Modelos** | Mismo modelo siempre | Puedes mezclar Claude, Codex, Gemini, etc. |
| **Persistencia** | Muere al cerrar Claude Code | Sobrevive al cierre de laptop/red |
| **Observabilidad** | Todo en una conversación | Terminal visible por agente + estado |
| **Vendor lock-in** | Solo Anthropic | Agnóstico de proveedor |

### La clave conceptual

```
BMAD / /agents:  orquestación DENTRO del modelo
                 → el modelo decide cuándo y cómo invocar subagentes
                 → todo ocurre en la "cabeza" de Claude
                 → un context window para gobernarlos a todos

Herdr:           orquestación FUERA del modelo
                 → procesos del OS reales
                 → el supervisor ejecuta comandos herdr en su terminal
                 → cada worker arranca con contexto 0 del resto
```

### No se excluyen — se complementan

```
┌───────────────────────────────────────────────────────┐
│  Herdr                                                │
│                                                       │
│  Tab: supervisor          Tab: worker 1               │
│  ┌──────────────────┐     ┌──────────────────────┐    │
│  │  Claude Code     │     │  Claude Code         │    │
│  │  con BMAD config │     │  con BMAD config      │    │
│  │  + /agents       │     │  + /agents            │    │
│  └──────────────────┘     └──────────────────────┘    │
│                                                       │
│  Cada pane puede correr su propio Claude Code         │
│  con su propio set de /agents y roles BMAD            │
└───────────────────────────────────────────────────────┘
```

**Cuándo usar cada uno:**
- **Solo BMAD/agents** → tarea única, mismo modelo, sesión corta, sin necesidad de aislamiento real
- **Solo Herdr** → múltiples agentes distintos (no necesariamente Claude), procesos paralelos, larga duración
- **Ambos juntos** → el escenario más potente: Herdr como runtime externo + BMAD para especializar roles dentro de cada proceso

---

## 7. Buenas Prácticas

### 7.1 Estructura de panes y tabs

```
✓ BIEN — cada rol tiene su propio tab

  Tab: supervisor   Tab: arquitecto   Tab: implementadores     Tab: qa
  ┌──────────────┐  ┌─────────────┐   ┌────┬────┬────┐      ┌───────────┐
  │  supervisor  │  │  arquitecto │   │impl│impl│impl│      │    qa     │
  │              │  │             │   │ 1  │ 2  │ 3  │      │           │
  └──────────────┘  └─────────────┘   └────┴────┴────┘      └───────────┘

✗ MAL — todo en splits del mismo tab → ilegible a escala
```

### 7.2 Supervisor como único orquestador

```
        ┌──────────────────────────────────────┐
        │           SUPERVISOR AGENT           │
        │  (único que toma decisiones globales)│
        └──────┬───────────┬───────────┬───────┘
               │           │           │
          ┌────▼───┐  ┌────▼───┐  ┌───▼────┐
          │impl 1  │  │impl 2  │  │impl 3  │
          │(worker)│  │(worker)│  │(worker)│
          └────────┘  └────────┘  └────────┘

✓ Agentes worker NO se hablan entre sí directamente
✓ El supervisor lee output, toma decisiones y redirecciona
✓ Bash script solo hace bootstrap — NO lógica de negocio
```

### 7.3 Secuencia de comandos correcta

```bash
# 1. Crear layout primero
PANE=$(herdr tab create --label "worker" --cwd "$ROOT" --no-focus | jq -r '.result.root_pane.pane_id')

# 2. Lanzar agente en ese pane
herdr agent start worker --kind agy --pane "$PANE" -- --dangerously-skip-permissions

# 3. Esperar estado activo antes de enviar prompt
herdr agent wait worker --until working --timeout 30000

# 4. Enviar tarea
herdr agent prompt worker "tu tarea aquí"

# 5. Esperar resultado
herdr agent wait worker --until idle --timeout 300000

# 6. Leer output
herdr agent read worker --source recent-unwrapped --lines 60
```

### 7.4 Paralelismo real — pattern correcto

```bash
# ✓ Lanzar los 3 prompts seguidos (sin esperar entre ellos)
herdr agent prompt implementador1 "tarea 1"
herdr agent prompt implementador2 "tarea 2"
herdr agent prompt implementador3 "tarea 3"

# ✓ Luego esperar los 3 en paralelo con & + wait
herdr agent wait implementador1 --until idle --timeout 300000 &
herdr agent wait implementador2 --until idle --timeout 300000 &
herdr agent wait implementador3 --until idle --timeout 300000 &
wait   # espera que los 3 terminen

# ✗ MAL — esperar uno a la vez anula el paralelismo
herdr agent prompt implementador1 "tarea" && herdr agent wait implementador1 --until idle
herdr agent prompt implementador2 "tarea" && herdr agent wait implementador2 --until idle
```

### 7.5 Worktrees para aislamiento

```
                    main branch
                        │
                 BRANCH_BASE ──── commit del arquitecto
                     ├──────────────────────────────┐
                     │                              │
              BRANCH_CC                       BRANCH_PS
              .worktrees/creditcard           .worktrees/passwordstrength
              (impl1 trabaja aquí)            (impl2 trabaja aquí)
              
✓ Cada implementador en su propio worktree → sin conflictos de merge
✓ Arquitecto hace commit en BRANCH_BASE antes de crear worktrees
✓ PRs van hacia BRANCH_BASE, no hacia main
```

---

## 8. Memoria y Contexto

### 8.1 El problema del contexto distribuido

```
┌─────────────────────────────────────────────────────────────┐
│  Agente 1 sabe:  "utils.js tiene _checkInput y _result"    │
│  Agente 2 sabe:  ???  (nada por defecto)                    │
│  Agente 3 sabe:  ???  (nada por defecto)                    │
│                                                             │
│  Sin coordinación → cada agente reinventa la rueda          │
└─────────────────────────────────────────────────────────────┘
```

### 8.2 Patrón: CONTEXT.md como memoria compartida

```
FASE 0: Arquitecto escribe CONTEXT.md
        │
        ▼
   CONTEXT.md ──→ commiteado en BRANCH_BASE
        │
        ├──→ worktree creditcard         (impl1 puede leerlo)
        ├──→ worktree passwordstrength   (impl2 puede leerlo)
        └──→ worktree date               (impl3 puede leerlo)

Contenido de CONTEXT.md:
  - Usar _checkInput(value, 'string') al inicio
  - Retornar con _result(valid, { ...campos })
  - Nunca lanzar excepciones
  - Campos null cuando no aplican (nunca undefined)
```

### 8.3 Patrón: Prompt como contexto explícito

```bash
# ✓ Pasarle al siguiente agente el output del anterior
OUTPUT=$(herdr agent read qa --source recent-unwrapped --lines 60)

herdr agent prompt arquitecto "$(cat <<EOF
Reporte de QA:
$OUTPUT

Instrucciones: revisar diffs y crear PRs solo para las que pasen QA.
EOF
)"

# ✗ MAL — asumir que el agente "ya sabe" lo que hizo otro
herdr agent prompt arquitecto "revisa el trabajo de QA"
```

### 8.4 Ventana de contexto — gestión por agente

```
┌─────────────────────────────────────────────────────────────┐
│  Cada agente tiene su propia ventana de contexto            │
│                                                             │
│  Supervisor: contexto del pipeline completo                 │
│  Workers:    contexto acotado a su tarea específica         │
│                                                             │
│  Principio: dar a cada agente el contexto MÍNIMO necesario  │
│  para su tarea — no todo el historial global                │
│                                                             │
│  ✓ supervisor lee output con --lines 60 (no todo)           │
│  ✓ CONTEXT.md define contratos, no implementaciones         │
│  ✓ cada worker recibe solo su spec, no el spec de los otros │
└─────────────────────────────────────────────────────────────┘
```

---

## 9. Demo 2 — Walkthrough

### Arquitectura del pipeline

```
  ┌─────────────────────────────────────────────────────────────┐
  │                    PIPELINE DEMO 2                          │
  │                                                             │
  │  [BASH]                                                     │
  │    ├── crea tabs + panes                                    │
  │    ├── lanza 6 agentes                                      │
  │    └── entrega control al supervisor ──────────────────┐    │
  │                                                        │    │
  │  [SUPERVISOR]                                          │    │
  │    │                                                   │    │
  │    ├── FASE 0: Arquitecto prepara base ─────────────►  │    │
  │    │     utils.js: _checkInput, _result                │    │
  │    │     CONTEXT.md: guidelines                        │    │
  │    │     commit + push en BRANCH_BASE                  │    │
  │    │     crea 3 worktrees                              │    │
  │    │                                                   │    │
  │    ├── FASE 1: 3 implementadores en paralelo ────────► │    │
  │    │     ┌─────────────────────────────────────┐       │    │
  │    │     │ impl1: validateCreditCard  (Luhn)   │       │    │
  │    │     │ impl2: validatePasswordStrength     │ ──→ & │    │
  │    │     │ impl3: validateDate (ISO/DD-MM/etc) │       │    │
  │    │     └─────────────────────────────────────┘       │    │
  │    │     cada uno: jest → commit → push                │    │
  │    │                                                   │    │
  │    ├── FASE 2: QA verifica ────────────────────────►   │    │
  │    │     corre tests en los 3 worktrees                │    │
  │    │     reporta: OK / FALLA por función               │    │
  │    │                                                   │    │
  │    └── FASE 3: Arquitecto revisa y crea PRs ────────►  │    │
  │          lee reporte QA                                │    │
  │          git diff por función                          │    │
  │          gh pr create (solo las que pasan)             │    │
  │          PRs → BRANCH_BASE (no main)                   │    │
  │                                                    ◄───┘    │
  │  [BASH] supervisor terminó → muestra resumen               │
  └─────────────────────────────────────────────────────────────┘
```

### Layout de pantalla

```
  ┌──────────────┐ ┌─────────────┐ ┌─────────────────────────┐ ┌──────────┐
  │  supervisor  │ │  arquitecto │ │     implementadores      │ │    qa    │
  │              │ │             │ │  impl1 │ impl2 │  impl3  │ │          │
  │  orquesta    │ │  shared     │ │  card  │  pwd  │  date   │ │ verifica │
  │  todo        │ │  code+PRs   │ │        │       │         │ │  tests   │
  └──────────────┘ └─────────────┘ └─────────────────────────┘ └──────────┘
     Tab 1              Tab 2              Tab 3                   Tab 4
```

### Comandos clave del demo

```bash
# Layout
herdr tab create --label "supervisor" --cwd "$ROOT" --no-focus
herdr pane split --pane "$IMPL1_PANE" --direction right --cwd "$ROOT" --no-focus

# Agentes
herdr agent start supervisor --kind agy --pane "$SUPER_PANE" -- --dangerously-skip-permissions

# Comunicación
herdr agent prompt supervisor "$(cat <<PROMPT ... PROMPT)"

# Espera con timeout (race condition avoidance)
herdr agent wait supervisor --until working --timeout 30000
herdr agent wait supervisor --until idle   --timeout 900000
```

### Ejecución

```bash
# Prerequisito: estar dentro de Herdr
herdr

# Correr el demo
./demo2.sh
```

---

## 10. Horizonte: Multi-Agente con Diferentes Modelos

> No implementado en este demo — concepto a mostrar

### El problema actual

```
┌─────────────────────────────────────────────────────────────┐
│  Demo 2: todos los agentes usan el mismo modelo             │
│                                                             │
│  supervisor   ──►  claude-code (agy)                        │
│  arquitecto   ──►  claude-code (agy)                        │
│  implementador──►  claude-code (agy)                        │
│  qa           ──►  claude-code (agy)                        │
│                                                             │
│  Limitación: un modelo no es siempre el mejor para todo     │
└─────────────────────────────────────────────────────────────┘
```

### La idea: modelo por rol

```
┌─────────────────────────────────────────────────────────────┐
│  DISEÑO MULTI-MODELO                                        │
│                                                             │
│  supervisor   ──►  claude-opus-4    (razonamiento complejo) │
│  arquitecto   ──►  claude-sonnet-5  (diseño + código)       │
│  implementador──►  claude-haiku-4   (tareas acotadas, rápido│
│                                      y más económico)       │
│  qa           ──►  gemini / codex   (segunda opinión)       │
│                                                             │
│  Herdr soporta esto hoy:                                    │
│  herdr agent start <name> --kind claude    → Claude Code    │
│  herdr agent start <name> --kind codex     → OpenAI Codex   │
│  herdr agent start <name> --kind opencode  → opencode       │
│                                                             │
│  Beneficios:                                                │
│  ✓ Costo optimizado — haiku para workers simples            │
│  ✓ Calidad maximizada — opus donde importa                  │
│  ✓ Redundancia — QA con modelo distinto = segunda opinión   │
│  ✓ Sin vendor lock-in — mix de proveedores                  │
└─────────────────────────────────────────────────────────────┘
```

### Patrón de orquestación avanzada

```
                   ┌─────────────────────┐
                   │  Supervisor (Opus)  │
                   │  "¿qué hacer?"      │
                   └──────┬──────┬───────┘
                          │      │
              ┌───────────┘      └────────────┐
              │                               │
   ┌──────────▼───────────┐      ┌────────────▼──────────────┐
   │  Arquitecto (Sonnet) │      │      QA (Gemini/Codex)    │
   │  diseño + contratos  │      │  tests + revisión externa │
   └──────────────────────┘      └───────────────────────────┘
              │
   ┌──────────┴──────────────┐
   │                         │
┌──▼──────┐  ┌───────────┐  ┌▼────────┐
│Haiku-4  │  │Haiku-4    │  │Haiku-4  │
│impl 1   │  │impl 2     │  │impl 3   │
│(rápido) │  │(rápido)   │  │(rápido) │
└─────────┘  └───────────┘  └─────────┘

Tiempo = Costo × Calidad × Velocidad optimizados por capa
```

---

## Referencia Rápida de Comandos

```bash
# ─── Sesión ───────────────────────────────────────────────────
herdr                          # abrir sesión
herdr attach                   # reconectar a sesión existente

# ─── Tabs ─────────────────────────────────────────────────────
herdr tab create --label "nombre" --cwd "$PWD" --no-focus

# ─── Panes ────────────────────────────────────────────────────
herdr pane split --pane "$ID" --direction right --cwd "$PWD" --no-focus

# ─── Agentes ──────────────────────────────────────────────────
herdr agent start <nombre> --kind agy --pane "$ID" -- --dangerously-skip-permissions
herdr agent stop  <nombre>
herdr agent prompt <nombre> "mensaje"
herdr agent prompt <nombre> "mensaje" --wait --timeout 180000
herdr agent wait  <nombre> --until idle    --timeout 300000
herdr agent wait  <nombre> --until working --timeout 30000
herdr agent read  <nombre> --source recent-unwrapped --lines 60
herdr agent attach <nombre>                # conectarse interactivamente
```

---

*Fuente: https://herdr.dev/docs/ — Apache 2.0 — YC-backed*
