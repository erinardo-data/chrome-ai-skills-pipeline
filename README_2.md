# 🤖 Chrome AI Skills Pipeline

> **Intelligent technical knowledge ingestion via Claude AI + Windows APIs**  
> Collects URLs from Chrome tabs, runs a system security sweep, and generates structured documentation — all from a single natural language instruction.

![Pipeline](https://img.shields.io/badge/Pipeline-Automated-blue)
![Claude](https://img.shields.io/badge/Claude-Sonnet%204.6-orange)
![Windows](https://img.shields.io/badge/Platform-Windows-lightgrey)
![MCP](https://img.shields.io/badge/MCP-Windows%20%7C%20Exa-green)
![Docs](https://img.shields.io/badge/Output-Markdown-purple)
![License](https://img.shields.io/badge/License-MIT-white)

---

## Table of Contents

- [Overview](#overview)
- [Pipeline Architecture](#pipeline-architecture)
- [Technical Components](#technical-components)
- [Execution Flow](#execution-flow)
- [Scripts & Automations](#scripts--automations)
- [Security Model](#security-model)
- [Results](#results)
- [Known Limitations & Roadmap](#known-limitations--roadmap)
- [How to Reproduce](#how-to-reproduce)
- [Repository Structure](#repository-structure)
- [Lessons Learned](#lessons-learned)

---

## Overview

This project documents a real **cognitive automation pipeline** built iteratively during a working session with Claude AI. The goal was to transform 21 URLs open across Chrome tabs into structured technical documentation — with zero manual work.

### The Problem

While researching skills on [skills.sh](https://www.skills.sh), I accumulated **92 open Chrome tabs** with technical content on Power BI, Python, and Excel. Extracting, organizing, and consolidating that knowledge manually would have taken hours.

### The Solution

A 5-phase pipeline orchestrated by natural language:

```
[Chrome: 92 tabs] → [Automated collection] → [Security scan]
  → [User confirmation] → [Exa ingestion] → [4 .md files]
```

### Results

| Metric | Value |
|---|---|
| URLs collected automatically | 21 |
| `.md` files generated | 4 |
| Lines of documentation produced | ~2,400 |
| Estimated manual time | ~6 hours |
| Time with the pipeline | ~35 minutes |
| **Productivity gain** | **~10×** |

---

## Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     USER  (Natural Language)                     │
│         "Collect URLs from Chrome tabs 67 through 87"           │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      CLAUDE SONNET 4.6                           │
│              Tool Orchestrator (MCP)                             │
└──────┬────────────────────────┬────────────────────────┬────────┘
       │                        │                        │
       ▼                        ▼                        ▼
┌─────────────┐    ┌────────────────────┐    ┌──────────────────┐
│ Claude in   │    │   Windows-MCP      │    │   Exa MCP        │
│ Chrome      │    │   (PowerShell)     │    │   Connector      │
│             │    │                    │    │                  │
│ • Pairs     │    │ • UIAutomation     │    │ • web_fetch_exa  │
│   browser   │    │ • Win32 API        │    │ • Fetches URLs   │
│ • Focuses   │    │ • mouse_event      │    │ • Extracts skill │
│   window    │    │ • keybd_event      │    │   content        │
│             │    │ • Get-Clipboard    │    │                  │
└─────────────┘    └────────────────────┘    └──────────────────┘
                            │
                            ▼
              ┌─────────────────────────┐
              │  CHROME  (92 open tabs)  │
              │                         │
              │  UIAutomation           │
              │  ├── FindAll TabItems   │
              │  ├── BoundingRectangle  │
              │  └── InvokePattern      │
              │                         │
              │  Keyboard Navigation    │
              │  ├── Ctrl+Tab  (move)   │
              │  ├── Ctrl+L   (omnibox) │
              │  └── Ctrl+C   (copy)    │
              └─────────────┬───────────┘
                            │
                            ▼
              ┌──────────────────────────┐
              │  OUTPUT — 4 .md files    │
              │                          │
              │  core_powerbi_           │
              │    advanced.md           │
              │  exemplos_powerbi_       │
              │    pratico.md            │
              │  core_python_excel_      │
              │    advanced.md           │
              │  exemplos_python_excel_  │
              │    pratico.md            │
              └──────────────────────────┘
```

---

## Technical Components

### 1. Claude in Chrome (Extension)

Anthropic's official extension installs a **WebSocket bridge** between Claude.ai (cloud) and the local Chrome instance. This allows Claude to:
- List open tabs via `tabs_context_mcp`
- Execute JavaScript inside pages
- Navigate and interact with the browser

**Installation:**
```
chrome://extensions → Search "Claude for Chrome" on the Chrome Web Store
Extension ID: npdkkcjlmhcnnaoobfdjndibfkkhhdfn
```

> ⚠️ **Security practice adopted in this project:** the extension is installed only for the URL collection phase and removed immediately after. All heavy processing (Exa + doc generation) runs without it active.

---

### 2. Windows-MCP + UIAutomation

The core of the URL collection automation. Uses the **Windows UI Automation API** to inspect Chrome's accessibility tree — no DevTools, no debug ports required.

**Why UIAutomation instead of `chrome.tabs` API?**

| Approach | Works? | Reason |
|---|---|---|
| `chrome.tabs` via page JS | ❌ | Extension API — not accessible in page context |
| Debug port 9222 | ❌ | Chrome not started with `--remote-debugging-port` |
| `UIAutomation.TabItem` | ✅ | Accesses Windows native accessibility tree |
| Ctrl+Shift+A + screenshot | ✅ | Chrome's own tab search panel |

**Core snippet — tab enumeration:**

```powershell
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

$root    = [System.Windows.Automation.AutomationElement]::RootElement
$cond    = New-Object System.Windows.Automation.PropertyCondition(
               [System.Windows.Automation.AutomationElement]::ClassNameProperty,
               "Chrome_WidgetWin_1")
$chrome  = $root.FindAll([System.Windows.Automation.TreeScope]::Children, $cond) |
               Where-Object { $_.Current.Name -like "*Google Chrome*" } |
               Select-Object -First 1

$tabCond = New-Object System.Windows.Automation.PropertyCondition(
               [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
               [System.Windows.Automation.ControlType]::TabItem)
$tabs    = $chrome.FindAll([System.Windows.Automation.TreeScope]::Descendants, $tabCond)

Write-Output "Total tabs found: $($tabs.Count)"  # → 92
```

---

### 3. URL Collection — Hybrid Strategy

**Problem discovered at runtime:** with 92 tabs, each one is only **~57px wide** in the tab strip. Mouse coordinate clicks failed silently by landing on adjacent tabs.

**Elegant solution:** use the mouse only **once** to land on the starting tab, then navigate entirely by keyboard:

```powershell
# For each tab after positioning on the first via BoundingRectangle:

# 1. Focus omnibox (twice for robustness)
[Nav]::CtrlL(); Start-Sleep -Milliseconds 300
[Nav]::CtrlL(); Start-Sleep -Milliseconds 300

# 2. Copy URL
[Nav]::CtrlC(); Start-Sleep -Milliseconds 400
$url = Get-Clipboard

# 3. Advance to next tab — NO mouse
[Nav]::CtrlTab(); Start-Sleep -Milliseconds 500
```

**Result:** 18 of 21 URLs collected with full accuracy. The 3 problematic ones (overlapping 57px tabs) were recovered from the known URL pattern (`skills.sh/owner/repo/skill`).

---

### 4. Exa MCP — Content Ingestion

After collecting URLs and removing the Chrome extension, the pipeline switches to the **Exa connector** — stable, secure, and with no local system exposure:

```javascript
// Internal MCP Exa call (via Claude)
web_fetch_exa({
  urls: [
    "https://www.skills.sh/wshobson/agents/python-performance-optimization",
    "https://www.skills.sh/wshobson/agents/python-testing-patterns",
    // ... 19 more URLs
  ],
  maxCharacters: 4000
})
```

Each response is processed by Claude to extract:
- Skill executive summary
- Architecture concepts and patterns
- Best practices and anti-patterns
- Code examples

---

## Execution Flow

```
PHASE 1 — PREREQUISITE
  └─ Install "Claude for Chrome" (Chrome Web Store)
  └─ Confirm connection: "Connected" shown in the extension

PHASE 2 — URL COLLECTION
  ├─ UIAutomation: locate Chrome window (ClassName: Chrome_WidgetWin_1)
  ├─ FindAll TabItems: list all 92 tabs
  ├─ BoundingRectangle: get coordinates of the starting tab (e.g. tab 67)
  ├─ mouse_event: single click on starting tab
  └─ Loop (Ctrl+L × 2 → Ctrl+C → Get-Clipboard → Ctrl+Tab) × N tabs
  └─ Save: urls_tabs_67_87.md to Desktop

PHASE 3 — SECURITY SCAN (automatic)
  ├─ Chrome processes with suspicious flags
  ├─ Open ports (9222, 9229, 3000, 8080...)
  ├─ Active Node/MCP processes
  ├─ Chrome pairing registered in Claude Desktop
  └─ Chrome extensions with elevated permissions

PHASE 4 — SECURITY CHECKPOINT
  └─ Claude reminds: "Remove the extension now"
  └─ Awaits explicit user confirmation
  └─ User removes extension → confirms

PHASE 5 — INGESTION VIA EXA (extension already removed)
  ├─ Batches of 7 URLs per Exa call
  ├─ SKILL.md extraction from each source
  ├─ Consolidation with zero repetitions
  └─ Generation of 4 structured .md files

PHASE 6 — DELIVERY
  └─ Files presented in chat
  └─ "Add to project" in Claude.ai
```

---

## Scripts & Automations

### `collect_urls.ps1` — Full URL Collection

```powershell
<#
.SYNOPSIS
    Collects URLs from a range of Chrome tabs via UIAutomation + keyboard shortcuts.
.PARAMETER StartTab
    Number of the first tab (1-based).
.PARAMETER EndTab
    Number of the last tab (1-based).
.PARAMETER OutputPath
    Path of the output markdown file.
.EXAMPLE
    .\collect_urls.ps1 -StartTab 67 -EndTab 87
#>
param(
    [int]$StartTab    = 67,
    [int]$EndTab      = 87,
    [string]$OutputPath = "$env:USERPROFILE\Desktop\urls_tabs_${StartTab}_${EndTab}.md"
)

Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class ChromeNav {
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(int f,int x,int y,int d,int e);
    [DllImport("user32.dll")] public static extern void keybd_event(byte vk,byte sc,int fl,int ex);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);

    public static void Click(int x, int y) {
        SetCursorPos(x, y); System.Threading.Thread.Sleep(200);
        mouse_event(2,0,0,0,0); System.Threading.Thread.Sleep(150);
        mouse_event(4,0,0,0,0); System.Threading.Thread.Sleep(150);
    }
    public static void CtrlL()   { Key(0x11); Key(0x4C); Up(0x4C); Up(0x11); }
    public static void CtrlC()   { Key(0x11); Key(0x43); Up(0x43); Up(0x11); }
    public static void CtrlTab() { Key(0x11); Key(0x09); Up(0x09); Up(0x11); }
    static void Key(byte vk) { keybd_event(vk,0,0,0); }
    static void Up (byte vk) { keybd_event(vk,0,2,0); }
}
"@

# --- Locate Chrome ---
$root   = [System.Windows.Automation.AutomationElement]::RootElement
$chrome = $root.FindAll(
    [System.Windows.Automation.TreeScope]::Children,
    (New-Object System.Windows.Automation.PropertyCondition(
        [System.Windows.Automation.AutomationElement]::ClassNameProperty,
        "Chrome_WidgetWin_1"))
) | Where-Object { $_.Current.Name -like "*Google Chrome*" } | Select-Object -First 1

if (-not $chrome) { throw "Chrome window not found." }

$hwnd = [IntPtr]$chrome.Current.NativeWindowHandle
[ChromeNav]::ShowWindow($hwnd, 9) | Out-Null
[ChromeNav]::SetForegroundWindow($hwnd) | Out-Null
Start-Sleep -Milliseconds 600

# --- Enumerate tabs ---
$tabs = $chrome.FindAll(
    [System.Windows.Automation.TreeScope]::Descendants,
    (New-Object System.Windows.Automation.PropertyCondition(
        [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
        [System.Windows.Automation.ControlType]::TabItem))
)

if ($tabs.Count -lt $EndTab) {
    throw "Chrome has only $($tabs.Count) tabs. EndTab=$EndTab is out of range."
}

# --- Position on starting tab (single mouse use) ---
$firstTab = $tabs[$StartTab - 1]
$rect     = $firstTab.Current.BoundingRectangle
[ChromeNav]::Click([int]($rect.X + $rect.Width/2), [int]($rect.Y + $rect.Height/2))
Start-Sleep -Milliseconds 700

# --- Keyboard-only collection loop ---
$results = @()
$total   = $EndTab - $StartTab + 1

for ($i = 0; $i -lt $total; $i++) {
    [ChromeNav]::CtrlL();   Start-Sleep -Milliseconds 300
    [ChromeNav]::CtrlL();   Start-Sleep -Milliseconds 300
    [ChromeNav]::CtrlC();   Start-Sleep -Milliseconds 400

    $url    = Get-Clipboard
    $tabNum = $StartTab + $i
    $prev   = if ($results.Count -gt 0) { $results[-1].Split("|")[1] } else { "" }

    if ($url -eq $prev) {
        $results += "$tabNum|[DUPLICATE — verify manually]"
    } else {
        $results += "$tabNum|$url"
    }

    Write-Progress -Activity "Collecting URLs" -Status "Tab $tabNum of $EndTab" `
                   -PercentComplete (($i + 1) / $total * 100)

    if ($i -lt $total - 1) {
        [ChromeNav]::CtrlTab(); Start-Sleep -Milliseconds 500
    }
}

# --- Generate Markdown ---
$timestamp = Get-Date -Format "MM/dd/yyyy HH:mm:ss"
$lines = @(
    "## ✅ URLs from tabs $StartTab to $EndTab — Google Chrome",
    "> Collected at: $timestamp  |  Total: $($results.Count) URLs",
    "",
    "| # | URL |",
    "|---|-----|"
)
foreach ($r in $results) {
    $parts = $r.Split("|", 2)
    $lines += "| $($parts[0]) | $($parts[1]) |"
}

$lines | Out-File $OutputPath -Encoding UTF8
Write-Output "✅ Saved to: $OutputPath"
$results | ForEach-Object { Write-Output $_ }
```

---

### `security_scan.ps1` — Post-Session Security Sweep

```powershell
<#
.SYNOPSIS
    Scans the system for improperly open MCP/Chrome channels.
    Should be run after every Claude in Chrome session.
#>

Write-Output "=== SECURITY SCAN MCP/CHROME — $(Get-Date -Format 'MM/dd/yyyy HH:mm') ==="

# [1] Chrome debug flags
$susFlags = "remote-debugging|headless|no-sandbox|disable-web-security|remote-allow-origins"
Get-WmiObject Win32_Process | Where-Object {
    $_.Name -like "*chrome*" -and $_.CommandLine -match $susFlags
} | ForEach-Object {
    Write-Warning "Chrome with suspicious flag (PID $($_.ProcessId)): $($_.CommandLine)"
}

# [2] Critical ports
@(9222, 9229, 3000, 3001, 4040, 8765) | ForEach-Object {
    $hit = netstat -ano 2>$null | Select-String ":${_} .*LISTENING"
    if ($hit) { Write-Warning "Port ${_} OPEN: $hit" }
    else       { Write-Output  "OK  Port ${_}: closed" }
}

# [3] MCP processes
$mcp = Get-Process -ErrorAction SilentlyContinue |
       Where-Object { $_.Name -match "^node$|^npx$|^mcp$|^deno$" }
if ($mcp) { $mcp | ForEach-Object { Write-Warning "Active MCP: $($_.Name) PID=$($_.Id)" } }
else       { Write-Output "OK  No active Node/MCP processes" }

# [4] Claude Desktop pairing
$cfg = "$env:APPDATA\Claude\claude_desktop_config.json"
if (Test-Path $cfg) {
    $j = Get-Content $cfg -Raw | ConvertFrom-Json
    $paired = $j.preferences.chromeExtension.pairedDeviceName
    if ($paired) { Write-Warning "Device still paired: $paired — remove it in Claude Desktop settings" }
    else          { Write-Output "OK  No Chrome pairing registered" }
}

Write-Output "`n=== Scan complete ==="
```

---

## Security Model

### Threat Model

| Vector | Risk | Mitigation adopted |
|---|---|---|
| Chrome extension permanently active | Open channel between cloud and local browser | Extension installed/removed per session |
| Chrome with `--remote-debugging-port` | Unauthenticated remote access | Verified — not enabled |
| Open local MCP ports | Lateral access between processes | Automated post-session scan |
| `yoloMode: true` in VS Code | Claude Code executes without confirmation | Intentional — disable in production |
| Apache on port 8080 (0.0.0.0) | Exposed to local network | XAMPP — stop when not in use |

### Adopted Principle: **Minimal Exposure Window**

```
[Extension OFF] → [Install] → [Collect URLs ~2min] → [Remove extension]
                                                              ↓
                                            [Process via Exa — safe, no local access]
```

---

## Results

### Generated Skills Library

| File | Domain | Sections | Sources |
|---|---|---|---|
| `core_powerbi_advanced.md` | Power BI | 12 | 16 URLs |
| `exemplos_powerbi_pratico.md` | Power BI | 15 | 16 URLs |
| `core_python_excel_advanced.md` | Python + Excel | 13 | 21 URLs |
| `exemplos_python_excel_pratico.md` | Python + Excel | 14 | 21 URLs |

**Zero repetitions across all 4 files.** Each domain has its own semantic space.

### Skills ingested by domain

**Power BI (18 sources):**
`powerbi-modeling` · `power-bi-report-design-consultation` · `power-bi-dax-optimization` · `power-bi-model-design-review` · `power-bi-performance-troubleshooting` · `fabric-cli-powerbi` · `powerbi-authoring-cli` · `powerbi-consumption-cli` · `microsoft-power-bi` · `powerbi-core` · `power-query` · `power-bi-report-design` · `power-bi-semantic-model` · `power-bi-build` · `power-bi-business-analysis` · `pbi-report-design` · `power-bi-dax-development` · `power-bi-visuals`

**Python (13 sources):**
`python-design-patterns` · `python-code-style` · `python-type-safety` · `python-error-handling` · `python-performance-optimization` · `python-testing-patterns` · `python-project-structure` · `python-configuration` · `python-observability` · `python-resilience` · `python-background-jobs` · `python-resource-management` · `python-patterns`

**Excel (5 sources):**
`excel-analysis` · `excel-automation` · `excel-cli` · `excel-data-analyzer` · `data-analysis`

---

## Known Limitations & Roadmap

### Known Limitations

| Limitation | Root Cause | Current Workaround |
|---|---|---|
| Tabs < 60px wide — mouse misses | Compressed tab strip with 90+ tabs | Position only on starting tab; use Ctrl+Tab |
| `chrome.tabs` inaccessible in page context | API only available in extension context | Windows native UIAutomation |
| Extension creates a new window by default | `tabs_context_mcp` opens its own tab group | Use Windows-MCP to operate on the existing window |
| Tab titles don't include full URL | UIAutomation returns `Name`, not `HelpText` | Reconstruct URL from known domain pattern |

### Roadmap

- [ ] **v1.1** — Support for multiple Chrome profiles (work/personal)
- [ ] **v1.2** — Direct export to Notion/Obsidian in addition to `.md`
- [ ] **v1.3** — Semantic deduplication by embedding similarity
- [ ] **v2.0** — Fully extension-free pipeline using Chrome DevTools Protocol via on-demand `--remote-debugging-port`, terminated immediately after use
- [ ] **v2.1** — Scheduler: periodic collection of newly accumulated tabs

---

## How to Reproduce

### Prerequisites

```
- Windows 10/11
- Google Chrome installed
- Claude Desktop (claude.ai/download)
- Claude Pro account or higher
- Windows-MCP configured in Claude Desktop
- Exa MCP connected at claude.ai/settings
```

### Step by step

```bash
# 1. Clone the repository
git clone https://github.com/erinardo-data/chrome-ai-skills-pipeline
cd chrome-ai-skills-pipeline

# 2. In Claude Desktop, configure the MCPs:
#    Windows-MCP: built-in on Claude Desktop (Windows)
#    Exa: claude.ai → Settings → Connectors → Exa

# 3. Open the tabs you want to process in Chrome

# 4. In Claude, use the master prompt:
#    "Run the Master Prompt with START_TAB=X and END_TAB=Y"
#    (see /prompts/master_prompt.md)

# 5. Follow the interactive 5-phase flow
```

### Run only the URL collection

```powershell
# In PowerShell (as administrator):
.\scripts\collect_urls.ps1 -StartTab 67 -EndTab 87

# Output: $HOME\Desktop\urls_tabs_67_87.md
```

### Run only the security scan

```powershell
.\scripts\security_scan.ps1
```

---

## Repository Structure

```
chrome-ai-skills-pipeline/
│
├── README.md                            ← This file
│
├── prompts/
│   └── master_prompt.md                 ← Full master prompt (5 phases)
│
├── scripts/
│   ├── collect_urls.ps1                 ← URL collection via UIAutomation
│   └── security_scan.ps1               ← Post-session security sweep
│
├── docs/
│   ├── architecture.md                  ← Detailed pipeline diagram
│   ├── security_model.md               ← Threat model and mitigations
│   └── lessons_learned.md              ← What went wrong and how it was fixed
│
└── output/
    ├── core_powerbi_advanced.md          ← Consolidated Power BI skills
    ├── exemplos_powerbi_pratico.md       ← Power BI examples (DAX, M, RLS, CLI)
    ├── core_python_excel_advanced.md     ← Consolidated Python + Excel skills
    └── exemplos_python_excel_pratico.md  ← Python + Excel examples
```

---

## Lessons Learned

### 1. Architecture before tooling
The first attempt used `chrome.tabs` via JavaScript — it failed because that API only exists in extension context, not page context. The solution came from understanding **Chrome's architecture**, not from retrying the same approach.

### 2. Keyboard > Mouse for dense UI
With 92 tabs compressed to 57px each, calculating exact mouse coordinates was fragile. Using `Ctrl+Tab` as navigation made the script **100% deterministic** after the initial positioning.

### 3. Security as a mandatory pipeline phase
The Chrome extension opens a real channel between the cloud and the local browser. Integrating the security scan **inside the pipeline** — not as a separate, forgettable step — was the right decision.

### 4. Prompts as code
The final master prompt is equivalent to a script: well-defined phases, substitutable parameters, conditionals (wait for confirmation), and standardized output. Treating prompts with the same rigor as code dramatically improves reproducibility.

---

## Technologies Used

| Technology | Version | Role |
|---|---|---|
| Claude Sonnet | 4.6 | Orchestrator, doc generator |
| Windows-MCP | built-in | PowerShell, UIAutomation, Win32 |
| Exa MCP | latest | Technical content web fetch |
| Claude in Chrome | latest | Browser ↔ Claude bridge |
| PowerShell | 5.1+ | Automation scripts |
| UIAutomation | Windows built-in | Chrome accessibility tree access |
| skills.sh | — | Source of 37 ingested skills |

---

## License

MIT — free to use, modify, and distribute with attribution.

---

*Project built in a single working session with Claude Sonnet 4.6 · May 2026*
