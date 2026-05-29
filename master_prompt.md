# 🤖 MASTER PROMPT — Chrome AI Skills Pipeline
> Version 1.0 · May 2026 · Parameters: [START_TAB], [END_TAB], [TOPIC]

---

## PREREQUISITE — Install the Extension

1. Open Google Chrome
2. Go to: https://chromewebstore.google.com/detail/claude/npdkkcjlmhcnnaoobfdjndibfkkhhdfn
3. Click **"Add to Chrome"** → **"Add extension"**
4. Click the extension icon → sign in with the same account used on claude.ai
5. Confirm it shows **"Connected"**
6. Return here and say: **"extension connected, ready to start"**

---

## PHASE 1 — URL COLLECTION FROM CHROME TABS

**Parameters:** [START_TAB] = ? | [END_TAB] = ? | [TOPIC] = ?

Execute via Windows-MCP (PowerShell) with UIAutomation:

**1.1 — Locate Chrome:**
- ClassName: `Chrome_WidgetWin_1`
- Filter by name containing "Google Chrome"
- SetForegroundWindow + ShowWindow(9) → wait 500ms

**1.2 — Initial positioning (single mouse use):**
- FindAll TabItems → confirm total >= [END_TAB]
- BoundingRectangle of TabItem[[START_TAB] - 1] (0-based index)
- Click(CenterX, CenterY) → wait 700ms

**1.3 — Keyboard-only collection loop:**
```
REPEAT ([END_TAB] - [START_TAB] + 1) times:
  a. keybd_event Ctrl+L  → 300ms
  b. keybd_event Ctrl+L  → 300ms  (ensures omnibox focus)
  c. keybd_event Ctrl+C  → 400ms
  d. Get-Clipboard → store in $results with tab number
  e. IF not the last tab:
       keybd_event Ctrl+Tab → 500ms
```

If Get-Clipboard = previous URL: record `"[DUPLICATE — verify manually]"` and continue.

**1.4 — Save and display result:**

File: `$env:USERPROFILE\Desktop\urls_tabs_[START_TAB]_[END_TAB].md`

Format in chat:
```
## ✅ URLs from tabs [START_TAB] to [END_TAB] — Google Chrome
> Collected at: [DATETIME]  |  Total: [N] URLs

| # | URL |
|---|-----|
| N | https://... |
```

---

## PHASE 2 — SECURITY SCAN (automatic — do not ask)

```powershell
[1] Chrome processes with flags:
    --remote-debugging-port, --headless, --no-sandbox, --disable-web-security

[2] Open ports — check: 9222, 9229, 3000, 3001, 4040, 8080, 8765
    Report any port on 0.0.0.0 (exposed to network)

[3] Active processes: node, npx, mcp, deno, uvicorn

[4] $env:APPDATA\Claude\claude_desktop_config.json
    Check chromeExtension.pairedDeviceId

[5] Active Chrome TCP connections to non-Google IPs
    (exclude ports 80, 443 and Google IP ranges)

[6] Local ports (127.0.0.1) — identify processes by PID
    Report any unknown process
```

Display result as table: Item | Status (✅/⚠️) | Detail

---

## PHASE 3 — SECURITY CHECKPOINT (mandatory)

After the scan, ALWAYS emit this block:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔔 SECURITY REMINDER — ACTION REQUIRED

The "Claude for Chrome" extension is still active
and keeps an open channel between Claude and your
browser. To close that access:

  → Open: chrome://extensions
  → Find "Claude for Chrome"
  → Click REMOVE (or toggle OFF)

Do this NOW, before continuing.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

After removing it, confirm with: "go ahead" or "yes"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

⛔ DO NOT proceed to Phase 4 without explicit user confirmation.

---

## PHASE 4 — INGESTION VIA EXA (only after confirmation)

Activate the Exa connector with `web_fetch_exa`. Access the Phase 1 URLs in batches of 7.

**CORE artifact — `core_[TOPIC]_advanced.md`:**
- Skill Executive Summary
- Modeling and Architecture Concepts
- Performance and Governance Best Practices
- Anti-patterns table: anti-pattern | why it's bad | correct solution

**EXAMPLES artifact — `exemplos_[TOPIC]_pratico.md`:**
- All content compiled WITHOUT repetitions across sources
- Code blocks by language: ` ```dax `, ` ```python `, ` ```sql `, ` ```bash `
- "❌ WRONG vs ✅ RIGHT" pattern throughout
- Clickable index at the top

**Mandatory visual standard:** `##`, `###`, **bold keywords**, comparison tables, ✅ ⚠️ ❌

**Important:** consolidate new content WITH existing project files — no repetitions between domains.

---

## PHASE 5 — DELIVERY

```
✅ Artifacts generated:
   📄 core_[TOPIC]_advanced.md
   📄 exemplos_[TOPIC]_pratico.md

👆 Click the top-right menu on each file → "Add to project"
```

---

## GLOBAL RULES

```
NEVER   open a new Chrome window
NEVER   calculate mouse coordinates for tabs after [START_TAB]
NEVER   proceed to Phase 4 without user confirmation
ALWAYS  use Ctrl+Tab for navigation after the starting tab
ALWAYS  run the security scan after Phase 1
ALWAYS  emit the removal reminder before Phase 4
ALWAYS  generate artifacts with .md extension
ALWAYS  consolidate WITHOUT repetitions across files
```
