---
name: mxp-your-skill-name
description: >
  [One sentence: what the skill does.] ALWAYS use this skill when a user asks to:
  [list 3–5 specific actions]. Also trigger on phrases like:
  "[trigger-1]", "[trigger-2]", "[trigger-3]".
  Requires Mixpanel MCP.
compatibility:
  tools:
    - Mixpanel MCP
---

# [Skill Title]

> **Loading model:** Progressive. Only this file on entry. Command/reference files read on-demand after routing.

[1–2 sentence summary of what this skill does and when to use it.]

---

## Execution Philosophy

**Silent execution.** Do not narrate steps. Execute MCP calls, process results, present only final output. The user sees: menus (when needed), confirmation prompts before writes, progress indicators during batch loops, errors, and final output.

---

## Step 0 — Project Validation

[How to validate and resolve the Mixpanel project ID before any commands run.]

---

## Command Menu

[Present available commands. Route to command files.]

---

## Session Context

[Define session variables that persist across commands.]

---

## Global Rules

[List rules that apply across all commands — batch sizes, error handling, exit behavior, etc.]
