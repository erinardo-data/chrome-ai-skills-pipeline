# Lessons Learned - Chrome AI Skills Pipeline

## Iteration 1: chrome.tabs API does not work in page context
chrome.tabs is extension API only. Solution: Windows UIAutomation.

## Iteration 2: Mouse failing on 57px tabs
92 tabs = ~57px each. Coordinate clicks missed silently.
Solution: mouse only on starting tab, Ctrl+Tab for the rest.

## Iteration 3: Claude in Chrome opened a new window
tabs_context_mcp creates its own tab group.
Solution: Windows-MCP operates on the existing Chrome window directly.

## Iteration 4: Clipboard not updating fast enough
200ms was not enough. Solution: 400ms + double Ctrl+L before Ctrl+C.

## Iteration 5: 3 tabs returned duplicate URLs
First tabs in loop before Ctrl+Tab settled.
Solution: reconstructed from known URL pattern (skills.sh/owner/repo/skill).

## Discovery: Apache on 0.0.0.0:8080
Security scan found XAMPP exposed to local network. Stop when not in use.

## Key Insight: Prompts as Code
Named parameters, sequential phases, conditionals, error handling,
reproducible output. That is prompt engineering, not chat.

## The Context Window (STM) Factor
Everything ran inside Claude context window (short-term memory).
No persistence after session. Design accordingly:
- Save outputs to disk at each phase
- Run security scan while context is active
- Build extension removal reminder into the prompt itself
