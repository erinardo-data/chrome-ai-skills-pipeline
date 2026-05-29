# Lessons Learned — Chrome AI Skills Pipeline

> An honest record of what went wrong, what was discovered at runtime, and how each issue was solved.

---

## Iteration 1: chrome.tabs API doesn't work in page context

**What I tried:** Running `chrome.tabs.query({}, callback)` via JavaScript injected into a page.

**Why it failed:** The `chrome.tabs` API is part of the Chrome Extension API and is only available in the extension's **background service worker**. Scripts running in normal pages have no access to it — even when the Claude extension is installed.

**How I solved it:** Windows native UIAutomation — accesses Chrome's accessibility tree without needing any browser API.

**Lesson:** Understand the architecture before trying. "JavaScript in the browser" is not the same as "extension API."

---

## Iteration 2: Mouse clicks failing on 57px tabs

**What I tried:** Calculating the `BoundingRectangle` of each tab and clicking its center X, Y.

**Why it failed:** With 92 tabs in a 3440px-wide window, each tab is roughly 37px wide (the active tab is slightly wider, which is why I initially read 57px). The margin of error in `mouse_event` was larger than the tab itself.

**Symptom:** `Get-Clipboard` always returned the same URL — the click wasn't switching the active tab.

**How I solved it:** Mouse click only for the starting tab. `Ctrl+Tab` for all the rest. Deterministic and robust.

**Lesson:** For dense UI, keyboard is more reliable than mouse. Coordinates are fragile; keyboard shortcuts are absolute.

---

## Iteration 3: Claude in Chrome was opening a new window

**What I tried:** Using `tabs_context_mcp` to list the user's tabs.

**Why it failed:** The extension's MCP creates its **own tab group in a new Chrome window**. The user's 92 tabs live in a different window — which the MCP doesn't see by default.

**How I solved it:** Windows-MCP (PowerShell) operates on the **existing** Chrome window regardless of the extension's MCP. Tabs are accessible via `FindAll(TabItem)` on the correct window.

**Lesson:** Each MCP has its own scope. To operate on the user's real window, the path is Windows-MCP, not Claude in Chrome.

---

## Iteration 4: Clipboard not updating fast enough

**What I tried:** A 200ms sleep after `Ctrl+C`.

**Why it failed:** In some cases, `Get-Clipboard` returned the previous URL because the clipboard hadn't updated yet.

**How I solved it:** Increased sleep to 400ms + double `Ctrl+L` before `Ctrl+C` (ensures the omnibox text is selected before copying).

**Lesson:** UI automation needs conservative delays. The 200ms overhead per tab (21 tabs × 200ms = 4.2 extra seconds) is irrelevant compared to getting a wrong URL.

---

## Iteration 5: 3 tabs with incorrect URLs

**What happened:** Tabs 68, 69, and 70 ended up with the URL from the last tab in the previous run.

**Why:** They were the first tabs in the loop, and Chrome hadn't processed the first `Ctrl+Tab` by the time the clipboard was read.

**How I solved it:** Reconstruction from title. The tabs followed the pattern `skills.sh/owner/repo/skill-name`, which is deterministic. Using the tab titles (`excel-automation — claude-office-skills/skills`), the URL was correctly inferred.

**Lesson:** Have a fallback based on known patterns. Document the 3 reconstructed cases instead of hiding them.

---

## Discovery: Apache running on 0.0.0.0:8080

The security scan revealed Apache (XAMPP) listening on `0.0.0.0:8080` — exposed to the entire local network.

Not a critical security breach, but an **unnecessary risk**. Stopping Apache when not in active use is the right call.

**Lesson:** The security scan found something relevant that wasn't on the radar. Worth running regularly.

---

## The Insight That Changed Everything: Prompts as Code

At the start, each instruction was an informal chat message. By the end, the "Master Prompt" had:
- Named parameters (`[START_TAB]`, `[END_TAB]`)
- Sequential phases with defined inputs and outputs
- Explicit conditionals (wait for confirmation)
- Edge case handling (duplicates, missing tabs)
- Standardized, reproducible output

That's **prompt engineering**, not chat. The distinction matters.

---

## The Context Window (STM) Factor

Everything in this pipeline ran inside Claude's **context window** — its short-term memory. This shaped several design decisions:

- Outputs were saved to disk at each phase (not just at the end)
- The security scan ran while the context was still active and complete
- The extension removal reminder was built into the prompt itself

When you understand that the AI's memory resets with each session, you design differently. You stop relying on "Claude will remember" and start building pipelines that are **stateless by design**.

**Lesson:** Design for the context window, not against it.
