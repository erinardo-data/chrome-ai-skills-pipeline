# How I turned 92 Chrome tabs into structured technical docs using Claude AI

Posted by Erinardo Araujo - Data Engineer | Power BI | Python | AI Automation

---

I had a problem that had been bothering me for weeks: 92 open Chrome tabs packed with
technical content on Power BI, Python, and Excel that I needed to organize and document.

Manual work would have taken hours. With AI, it took 35 minutes.

## The Real Problem

Researching skills on skills.sh, I kept accumulating tabs with DAX patterns, Excel
automation, Python design patterns, observability, resilience...

The problem was not lack of content. It was unorganized excess.

## The Solution: A 5-Phase Pipeline

1. Accesses Chrome locally via UIAutomation (Windows native API)
2. Navigates tabs using only keyboard shortcuts
3. Collects URLs automatically (Ctrl+L -> Ctrl+C per tab)
4. Runs a security scan of the system
5. Ingests the content via Exa connector and generates structured documentation

## What I Learned Technically

### UIAutomation > chrome.tabs API
First attempt: chrome.tabs via JavaScript. Failed - extension API only.
Solution: Windows UI Automation API. No debugging ports, no special extensions.

### Keyboard > Mouse for dense UI
92 tabs at 57px each. Mouse coordinate clicks failed silently.
Fix: mouse once on starting tab, then 100% keyboard with Ctrl+Tab.

### Security built into the flow
The Chrome extension opens a real channel between cloud and local browser.
Solution: extension installed only during collection (~2 min).
Automated security scan always runs after.

## The Context Window (STM) Angle

Everything Claude did here lived inside its context window - its short-term memory.
No persistence. No trace after the session ends.

That shaped the design:
- Outputs saved to disk at each phase
- Security scan while context was still active
- Extension removal built into the prompt itself

When you understand how AI memory works, you design differently.

## Results

21 URLs collected | 4 docs generated | ~35 min | 10x faster

Full project: github.com/erinardo-data/chrome-ai-skills-pipeline

Have you automated any workflow with AI in an unconventional way?

---
#ArtificialIntelligence #Automation #PowerBI #Python #ClaudeAI
#DataEngineering #WindowsAutomation #MCP #PromptEngineering #ContextWindow #STM
