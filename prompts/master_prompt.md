# MASTER PROMPT - Chrome AI Skills Pipeline
> Version 1.0 · May 2026 · Parameters: [START_TAB], [END_TAB], [TOPIC]

## PREREQUISITE - Install the Extension
1. Open Google Chrome
2. Go to: https://chromewebstore.google.com/detail/claude/npdkkcjlmhcnnaoobfdjndibfkkhhdfn
3. Click "Add to Chrome" -> "Add extension"
4. Click the extension icon -> sign in with the same account used on claude.ai
5. Confirm it shows "Connected"
6. Return here and say: "extension connected, ready to start"

## PHASE 1 - URL COLLECTION
Parameters: [START_TAB] = ? | [END_TAB] = ? | [TOPIC] = ?

Execute via Windows-MCP (PowerShell) with UIAutomation:
1.1 Locate Chrome: ClassName Chrome_WidgetWin_1, filter by "Google Chrome"
    SetForegroundWindow + ShowWindow(9) -> wait 500ms
1.2 Initial positioning (single mouse use):
    FindAll TabItems -> confirm total >= [END_TAB]
    BoundingRectangle of TabItem[[START_TAB]-1] -> Click(CenterX, CenterY) -> wait 700ms
1.3 Keyboard-only loop:
    REPEAT ([END_TAB] - [START_TAB] + 1) times:
      a. Ctrl+L  -> 300ms
      b. Ctrl+L  -> 300ms  (ensures omnibox focus)
      c. Ctrl+C  -> 400ms
      d. Get-Clipboard -> store in $results
      e. IF not last: Ctrl+Tab -> 500ms
    If duplicate URL: record "[DUPLICATE]" and continue.
1.4 Save: $env:USERPROFILE\Desktop\urls_[START_TAB]_[END_TAB].md
    Display table: | # | URL |

## PHASE 2 - SECURITY SCAN (automatic)
Check: Chrome debug flags | ports 9222,9229,3000,3001,4040,8080 |
       Node/MCP processes | Claude Desktop pairing | non-standard Chrome connections
Display: Item | Status (OK/WARNING) | Detail

## PHASE 3 - SECURITY CHECKPOINT (mandatory)
Emit:
  SECURITY REMINDER: Remove "Claude for Chrome" now.
  chrome://extensions -> Claude for Chrome -> REMOVE
  Confirm with: "go ahead"
DO NOT proceed to Phase 4 without explicit confirmation.

## PHASE 4 - INGESTION VIA EXA (after confirmation only)
Activate Exa connector (web_fetch_exa). Fetch Phase 1 URLs in batches of 7.

CORE artifact: core_[TOPIC]_advanced.md
  - Executive Summary | Architecture | Best Practices | Anti-patterns table

EXAMPLES artifact: exemplos_[TOPIC]_pratico.md
  - Code blocks by language (dax, python, sql, bash, m)
  - "WRONG vs RIGHT" pattern | Clickable index

Rules: zero repetitions across files | .md extension | bold keywords | comparison tables

## PHASE 5 - DELIVERY
  Artifacts generated:
    core_[TOPIC]_advanced.md
    exemplos_[TOPIC]_pratico.md
  -> Click top-right menu on each -> "Add to project"

## GLOBAL RULES
  NEVER   open a new Chrome window
  NEVER   calculate mouse coordinates after [START_TAB]
  NEVER   proceed to Phase 4 without confirmation
  ALWAYS  use Ctrl+Tab after the starting tab
  ALWAYS  run security scan after Phase 1
  ALWAYS  emit removal reminder before Phase 4
