# Chrome AI Skills Pipeline

> Intelligent technical knowledge ingestion via Claude AI + Windows APIs
> Collects URLs from Chrome tabs, runs a system security sweep, and generates structured documentation - all from a single natural language instruction.

![Pipeline](https://img.shields.io/badge/Pipeline-Automated-blue)
![Claude](https://img.shields.io/badge/Claude-Sonnet%204.6-orange)
![Windows](https://img.shields.io/badge/Platform-Windows-lightgrey)
![MCP](https://img.shields.io/badge/MCP-Windows%20%7C%20Exa-green)
![Docs](https://img.shields.io/badge/Output-Markdown-purple)
![License](https://img.shields.io/badge/License-MIT-white)

## Overview

This project documents a real cognitive automation pipeline built iteratively during a working session with Claude AI.
The goal: transform 21 URLs open across Chrome tabs into structured technical documentation with zero manual work.

### Results

| Metric | Value |
|---|---|
| URLs collected automatically | 21 |
| .md files generated | 4 |
| Lines of documentation produced | ~2,400 |
| Estimated manual time | ~6 hours |
| Time with the pipeline | ~35 minutes |
| Productivity gain | ~10x |

## Pipeline Architecture

```
USER (Natural Language)
  -> Claude Sonnet 4.6 (Orchestrator)
     -> Windows-MCP (UIAutomation + Win32 + PowerShell)
        -> Chrome: 92 tabs | BoundingRectangle | Ctrl+Tab loop
     -> Exa MCP (web_fetch)
        -> skills.sh content extraction
  -> 4 structured .md files
```

## How It Works

### Phase 1 - URL Collection
UIAutomation reads all open Chrome tabs. Mouse clicks only on the starting tab.
Navigation uses Ctrl+Tab exclusively - robust against compressed 57px tab strips.

```powershell
.\scripts\collect_urls.ps1 -StartTab 67 -EndTab 87
```

### Phase 2 - Security Scan
Automatic post-collection sweep: debug ports, MCP processes, Chrome pairing.

```powershell
.\scripts\security_scan.ps1
```

### Phase 3 - Extension Removal Checkpoint
Claude reminds the user to remove the Chrome extension before ingestion.
Extension exposure window: approximately 2 minutes.

### Phase 4 - Content Ingestion via Exa
With extension removed, Exa fetches all skill pages from skills.sh.
Cloud-to-cloud: no local system access during ingestion.

### Phase 5 - Structured Output
4 Markdown files covering Power BI, Python, and Excel skills.
Zero repetitions across domains.

## Why UIAutomation Instead of chrome.tabs?

| Approach | Works | Reason |
|---|---|---|
| chrome.tabs via page JS | No | Extension API unavailable in page context |
| Debug port 9222 | No | Chrome not started with --remote-debugging-port |
| UIAutomation TabItem | Yes | Windows native accessibility tree |

## Repository Structure

```
chrome-ai-skills-pipeline/
  README.md
  linkedin_infographic.png
  linkedin_post.md
  .gitignore
  prompts/
    master_prompt.md
  scripts/
    collect_urls.ps1
    security_scan.ps1
  docs/
    architecture.md
    lessons_learned.md
  output/
    core_powerbi_advanced.md
    exemplos_powerbi_pratico.md
    core_python_excel_advanced.md
    exemplos_python_excel_pratico.md
```

## Prerequisites

- Windows 10/11
- Google Chrome
- Claude Desktop (claude.ai/download)
- Claude Pro account or higher
- Windows-MCP (built-in on Claude Desktop for Windows)
- Exa MCP connected at claude.ai/settings

## Security Model

| Vector | Risk | Mitigation |
|---|---|---|
| Chrome extension active | Open cloud-to-browser channel | Installed/removed per session only |
| Chrome debug port | Unauthenticated remote access | Not enabled - verified by scan |
| Open MCP ports | Lateral process access | Automated post-session scan |

## Lessons Learned

1. Architecture before tooling - understand the API boundaries first
2. Keyboard beats mouse for dense UI (57px tabs, 92 of them)
3. Security as a mandatory pipeline phase, not an afterthought
4. Prompts as code: parameters, phases, conditionals, error handling
5. Design for the context window (STM) - outputs saved at each phase

## Technologies

| Technology | Role |
|---|---|
| Claude Sonnet 4.6 | Orchestration, doc synthesis |
| Windows-MCP | PowerShell, UIAutomation, Win32 |
| Exa MCP | Web content fetching |
| Claude in Chrome | Browser-cloud bridge (session only) |
| skills.sh | Source of 37 ingested skills |

## License

MIT - free to use, modify, and distribute with attribution.

*Built in a single working session with Claude Sonnet 4.6 - May 2026*
