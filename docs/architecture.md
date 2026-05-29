# Architecture - Chrome AI Skills Pipeline

## Components
| Component         | Role                              | Access       |
|-------------------|-----------------------------------|--------------|
| Claude Sonnet 4.6 | Orchestration, doc synthesis      | Cloud only   |
| Claude in Chrome  | Browser-cloud WebSocket bridge    | Local browser|
| Windows-MCP       | PowerShell, UIAutomation, Win32   | Full local   |
| Exa MCP           | Web content fetching              | Cloud-cloud  |

## Data Flow
Phase 1 (Collection):
  Chrome tabs -> UIAutomation -> tab coordinates
  Ctrl+Tab + Ctrl+L + Ctrl+C -> URL per tab -> .md file

Phase 2 (Security):
  System state -> PowerShell -> security report

Phase 3 (Ingestion):
  URLs -> Exa -> raw content -> Claude -> structured .md

## Security Boundaries
ALWAYS SAFE:   Claude.ai <-> Exa | Claude.ai <-> Windows-MCP
TEMPORARY:     Claude.ai <-> Chrome extension (~2 min, Phase 1 only)
NEVER EXPOSED: local filesystem beyond output folder, passwords, credentials
