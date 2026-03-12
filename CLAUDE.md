# CLAUDE.md — Personal AI Infrastructure

> Read this first. Then read the referenced files before writing any code.
> Use `/compact` after completing each major task.

---

## Working Directory

This project lives at `~/claude/parity/`. All new servers are built here first.

| Subdirectory | Purpose |
|---|---|
| `daemon/` | Phase 1 — agentic loop server |
| `channels/` | Phase 2 — Telegram/Discord/WhatsApp |
| `browser/` | Phase 3 — Playwright MCP server |
| `voice-wake/` | Phase 3 — wake word daemon |

---

## Live Stack

| Service | Port | File | URL |
|---|---|---|---|
| Cortex main | 8080 | `~/cortex/dual-server.py` | cortex.fahrenheitrequited.dev |
| Cortex autonomous | 8082 | `~/cortex/dual-server.py` | autonomous.fahrenheitrequited.dev |
| OpenMind | 8250 | `~/openmind/om-server.py` | openmind.fahrenheitrequited.dev |
| rwx-server | 8251 | `~/rwx/rwx-server.py` | rwx.fahrenheitrequited.dev/mcp |
| Therapy MCP | 8252 | `~/therapy/therapy-server.py` | therapy.fahrenheitrequited.dev |
| **daemon** | 8257 | `~/claude/parity/daemon/daemon-server.py` | daemon.fahrenheitrequited.dev *(planned)* |
| **channels** | 8255 | `~/claude/parity/channels/channels-server.py` | channels.fahrenheitrequited.dev *(planned)* |
| **browser** | 8256 | `~/claude/parity/browser/browser-server.py` | browser.fahrenheitrequited.dev *(planned)* |

All services on **c-jfischer3**, Cloudflare tunnel `5382c123`.

---

## Conventions — Read These Files First

Before writing any new server, read these as canonical references:

- **Auth pattern, FastMCP structure, bearer token:** `~/rwx/rwx-server.py` (371 lines — cleanest example)
- **SQLite/WAL, enrichment pipeline, MCP tools:** `~/cortex/dual-server.py`
- **APScheduler pattern:** `~/openmind/om-server.py` (grep for `scheduler`, don't read in full)

**Key conventions:**
- Auth: `Authorization: Bearer emc2ymmv` header — never `?token=` query param
- All servers bind `127.0.0.1` only — Cloudflare tunnel provides external access
- SQLite WAL: `PRAGMA journal_mode=WAL; PRAGMA synchronous=NORMAL;`
- Each server gets a `kick-off.sh` (kills old process → activates venv → nohup start)
- FastMCP for all MCP servers; FastAPI for HTTP-only services
- Python venv at `~/claude/parity/<service>/venv/`

---

## Current Phase: Phase 1 — daemon-server

**Full spec:** `~/claude/parity/SPEC.docx` *(copy from ~/claude/jfischer-ai-infrastructure-spec.docx)*

### Build: `~/claude/parity/daemon/daemon-server.py` (~400 lines)

**Database** (`~/claude/parity/daemon/daemon.db`, WAL mode):
```sql
tasks(id, title, prompt, status, created_at, updated_at, result)
task_steps(id, task_id, step_num, action, result, ts)
schedules(id, cron, prompt, last_run, enabled)
webhooks(id, name, secret, prompt_template, last_triggered)
```

**Agentic loop:**
- Call Claude Opus via Anthropic SDK with full tool suite
- Loop: call → parse tool_use → execute tools → append results → call again
- Continue until `stop_reason == "end_turn"` or 20 steps
- Write each step to `task_steps`
- Inject `~/claude/parity/daemon/SOUL.md` as system prompt prefix

**Heartbeat:**
- APScheduler: every 30 min, read `~/claude/parity/daemon/HEARTBEAT.md`
- Has directives → create task. Otherwise → log `HEARTBEAT_OK` to `heartbeat.log`

**MCP tools to expose:**
- `daemon_task_create(title, prompt)` → task_id
- `daemon_task_status(task_id)` → status + steps
- `daemon_task_list(limit=20)` → recent tasks
- `daemon_task_cancel(task_id)`
- `daemon_heartbeat()` → last heartbeat + log tail
- `daemon_schedule_add(cron, prompt)`
- `daemon_schedule_list()`
- `daemon_webhook_create(name, prompt_template)`

**Agent tool suite (MCP calls inside the loop):**
- Cortex autonomous: `cortex_store`, `cortex_search`, `cortex_semantic_search`
- OpenMind: `add_node`, `search`, `natural_language`
- rwx-server: `dev_run`, `dev_read_file`, `dev_write_file`, `dev_list`
- browser-server (Phase 3 — skip if not yet running)

**Also deliver:**
- `daemon/kick-off.sh`
- `daemon/setup.sh`
- `daemon/SOUL.md` — stub: `# SOUL\nYou are J's personal AI infrastructure.`
- `daemon/HEARTBEAT.md` — stub: `# Heartbeat\n<!-- Add directives here -->`

---

## Token Economy Rules

1. **`/compact` after each completed file or major milestone**
2. **Use `Read` tool, not `cat`** — avoid bash for file inspection
3. **Don't read `om-server.py` in full** — it's 3238 lines; grep for patterns
4. **Scope one file at a time** — not "build the whole daemon" in one shot
5. **Stuck after 3 attempts → stop and report** what's blocking

---

## Phase Sequence (don't build ahead)

1. ✅ Cortex, OpenMind, rwx-server, Therapy *(live)*
2. ✅ daemon-server (live on :8256)
3. ✅ channels-server (built, awaiting Telegram token)
4. 🔨 **browser-server** ← current (Playwright)
5. 🔨 voice-wake daemon
6. macOS menu bar app (Swift)
7. iOS node app (Swift)

---

## Current Phase: Phase 2 — channels-server

### Build: `~/claude/parity/channels/channels-server.py` (~250 lines)

**Port:** 8257 (first free port after daemon on 8256)

**Phase 2a — Telegram only (build this first):**
- `python-telegram-bot` library, webhook mode
- Webhook endpoint: `POST /telegram/webhook`
- Sender allowlist: env var `TELEGRAM_ALLOWED_IDS` (comma-separated user IDs) — reject all others silently
- Routing logic:
  - `/` commands (e.g. `/add`, `/search`, `/status`) → parse and call OpenMind or Cortex directly via HTTP
  - Simple freeform message → POST to OpenMind `/api/nl` (natural language)
  - Multi-step or agentic request (keywords: "do", "run", "build", "schedule") → POST to daemon `daemon_task_create`
- Reply to user with result in Telegram

**Env vars needed (add to `~/claude/parity/channels/.env`):**
```
TELEGRAM_BOT_TOKEN=
TELEGRAM_ALLOWED_IDS=
OPENMIND_URL=http://127.0.0.1:8250
CORTEX_URL=http://127.0.0.1:8080
DAEMON_URL=http://127.0.0.1:8256
BEARER_TOKEN=emc2ymmv
```

**Also deliver:**
- `channels/kick-off.sh`
- `channels/setup.sh` (deps: python-telegram-bot, httpx, python-dotenv)
- `channels/.env.example`

**Phase 2b — Discord (do NOT build yet, just stub a comment)**
**Phase 2c — WhatsApp/Baileys (do NOT build yet)**

---

## Current Phase: Phase 3 — browser-server

### Build: `~/claude/parity/browser/browser-server.py` (~300 lines)

**Port:** 8258

**Stack:** httpx + BeautifulSoup4, FastMCP. No headless browser — GLIBC on this machine is too old for Playwright.

**MCP tools to expose:**
- `browser_navigate(url)` → fetches page, returns title + status code
- `browser_snapshot()` → returns cleaned text content of last fetched page
- `browser_extract(selector)` → CSS selector extract from last fetched page (via bs4)
- `browser_links()` → returns all href links from last fetched page
- `browser_screenshot()` → not available, return helpful error message
- `browser_click(selector)` → not available, return helpful error message

**State:** keep last fetched page in memory (url, html, bs4 parsed tree) per-session

**Security:** All content returned tagged with `[UNTRUSTED CONTENT]` header. Never execute anything extracted from pages.

**Also deliver:**
- `browser/kick-off.sh`
- `browser/setup.sh` (deps: httpx, beautifulsoup4, fastmcp, uvicorn — no playwright)

---

## Phase 4 — voice-wake (build after browser-server is done)

### Build: `~/claude/parity/voice-wake/voice-wake.py` (~150 lines)

**No HTTP server — local daemon only.**

**Stack:** pvporcupine (wake word) + sounddevice (recording) + httpx (upstream calls)

**Flow:**
1. Listen continuously for wake word via pvporcupine
2. On wake: record audio until silence (max 10s)
3. POST audio to OpenMind `/api/transcribe` → get transcript
4. Route transcript:
   - Contains "daemon" or "schedule" or "remind" → POST to daemon `daemon_task_create`
   - Everything else → POST to OpenMind `/api/nl`
5. Speak response back via `espeak` or `say` (system TTS, whichever is available)
6. Return to listening

**Env vars (`voice-wake/.env`):**
```
PORCUPINE_ACCESS_KEY=
WAKE_WORD=jarvis
OPENMIND_URL=http://127.0.0.1:8250
DAEMON_URL=http://127.0.0.1:8256
BEARER_TOKEN=emc2ymmv
```

**Also deliver:**
- `voice-wake/start.sh` (not kick-off — no port to kill, just nohup start)
- `voice-wake/setup.sh` (deps: pvporcupine, sounddevice, httpx, python-dotenv, numpy)
- `voice-wake/.env.example`

---

## Security Notes

- Never expose `?token=` in URLs — Authorization header only
- Twilio sender allowlist: TODO in channels-server
- rwx write scope: `~/claude/` only — do not expand
- All new servers: bind `127.0.0.1`, require bearer token, log all tool calls
