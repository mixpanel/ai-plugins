---
name: mxp-governor-tool
description: >
  Mixpanel Lexicon governance plugin with five commands: score-lexicon, enrich-lexicon, tag-events, review-issues, manage-tags.
  ALWAYS use this skill when a user asks to: audit Lexicon health, score Lexicon coverage, enrich or auto-fill
  event/property metadata (descriptions, display names), auto-tag events, categorize events by name patterns,
  review or triage data quality issues, check for type drift or null property values, rename or delete Lexicon tags,
  clean up tags, manage tags, or says anything like
  "score my Lexicon", "enrich this project's schema", "auto-tag events", "tag my events", "review issues",
  "data quality check", "Lexicon audit", "governor", "governance tool", "enrich lexicon", "score lexicon",
  "what issues does this project have", "categorize my events", "run the governor", "data governor",
  "rename tags", "delete tags", "manage tags", "clean up tags".
  Requires Mixpanel MCP (mcp.mixpanel.com or mcp-in.mixpanel.com).
compatibility:
  tools:
    - Mixpanel MCP
---

# Mixpanel Governor Tool

> **Loading model:** Progressive. Only this file on entry. Command files read on-demand after routing. Do not pre-load.

Top-level router: validate project → route command → handle return.

---

## Execution Philosophy

**Silent execution.** Do not narrate steps, announce phases, or explain what you are about to do. Execute MCP calls, process results, present only final output. The user sees:
- Command menu (when needed)
- Confirmation prompts before destructive writes
- Progress indicators during batch loops (e.g. "Updated 10/47...")
- Error messages
- Final output tables/reports

Nothing else. No "Starting X...", no "I'll now fetch Y...", no "Let me analyze Z...". Just do the work and show the result.

---

## Step 0 — Project Validation

**Direct routing:** If the user's message contains a project ID AND a clear command intent (e.g. "enrich lexicon for project 12345", "score project 67890"), extract both, validate, and route directly — skip the menu.

**Project ID without command:** Validate and show menu.

**No project ID:** Ask which project. 'list' → call `Get-Projects`, show table.

**Validation:**
1. Call `Get-Projects`. Match ID. If found → `✅ [Project Name] ([project_id])`, proceed.
2. Not found → error, ask to re-enter or 'list'.

**MCP check:** If `Get-Projects` fails with tool-not-found → tell user to connect Mixpanel MCP, stop.

---

## Command Menu

Show only when no direct command was inferred:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Governor Tool — [Project Name] ([project_id])
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1. Score Lexicon    — Health score (0–100)
  2. Enrich Lexicon   — Auto-fill display names & descriptions
  3. Tag Events       — Auto-categorize into tags
  4. Review Issues    — Triage data quality issues
  5. Manage Tags      — Rename or delete existing tags
  6. Exit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

| Choice | Action |
|--------|--------|
| **1** | Read `commands/score-lexicon.md`, execute |
| **2** | Read `commands/enrich-lexicon.md`, execute |
| **3** | Read `commands/tag-events.md`, execute |
| **4** | Read `commands/review-issues.md`, execute |
| **5** | Read `commands/manage-tags.md`, execute |
| **6** | Exit |

---

## Return Handler

When a command completes → `✅ Done.` → re-display command menu. No re-validation.

---

## Session Context

Persist across commands. **Cross-command reuse is mandatory** — never re-fetch what exists in session.

| Variable | Description |
|----------|-------------|
| `project_id` | Immutable after Step 0. |
| `project_name` | Display name. |
| `event_list` | Full event name list. |
| `event_details_cache` | `event_name → metadata` map. |
| `property_names` | Event + user property name lists. |
| `property_details_cache` | `property_name → metadata` map. |
| `volume_rank_map` | `event_name → { volume, rank }`. |
| `issues_list` | Normalised issues from review-issues. |

---

## Global Rules

1. **Silent execution.** No narration, no phase announcements. Only output: progress during batch writes, errors, confirmation prompts, and final results.
2. **Project ID immutable.** All MCP calls use confirmed `project_id`.
3. **Surface MCP failures explicitly.** Never silently skip.
4. **Query fallback.** `Run-Query` fails → `Get-Query-Schema` → retry once.
5. **Preview before writes.** Before/after + explicit confirmation before any Lexicon mutation.
6. **Batch writes: groups of 10.** Show progress per batch.
7. **'exit' always valid.** Stop, discard uncommitted, return to menu.
8. **No per-command "what next" menus.** Commands return control here. The router shows the menu. Commands must NOT display their own next-action options.
   - *Exception:* `review-issues` Phase 4 (triage actions) may present an action prompt because issue triage is inherently interactive. All other commands return control to the router immediately.
