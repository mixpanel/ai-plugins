---
name: mxp-governor-tool
description: >
  Governance workflow for a Mixpanel project's Lexicon — the registry of tracked events
  and properties. Use whenever the user wants to audit, score, bulk-enrich, bulk-tag,
  reset, or clean up event/property metadata (descriptions, display names, tags) in
  Mixpanel, or triage Lexicon data quality issues like type drift and null values. Also
  use when the user describes the problem without naming the tool — "event names are a
  mess", "half my events have no descriptions", "tracking plan audit", "clean up the
  schema", "score our instrumentation" — as long as Mixpanel is the context. Trigger
  phrases: "score lexicon", "enrich lexicon", "bulk enrich", "auto-tag events", "reset
  lexicon", "wipe tags", "review data quality issues", "rename/delete Lexicon tags",
  "run the governor". Do NOT use for: deleting event data or user profiles; dashboard
  cleanup; cohort tagging; customer health scoring. Requires Mixpanel MCP.
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
  1. Score Lexicon    — Health score (0–100), auto-offer bulk enrich
  2. Enrich & Tag     — Fill empty display names, descriptions & tags
  3. Reset Lexicon    — Clear descriptions / display names / tags
  4. Review Issues    — Triage data quality issues
  5. Manage Tags      — Rename or delete existing tags
  6. Exit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

| Choice | Action |
|--------|--------|
| **1** | Read `commands/score-lexicon.md`, execute |
| **2** | Read `commands/enrich-and-tag.md`, execute |
| **3** | Read `commands/reset-lexicon.md`, execute |
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
6. **Fill-only-empty for enrich-and-tag.** Never overwrite existing descriptions, display names, or tags. If the user wants to regenerate, they run `reset-lexicon` first.
7. **Destructive writes require literal CONFIRM.** `reset-lexicon` requires the user to type the string `CONFIRM` (case-sensitive) — no soft confirmations.
8. **Batch sizes.**
   - `Bulk-Edit-Events` / `Bulk-Edit-Properties` → chunks of up to **50** per call.
   - Per-call writes (`Edit-Event`, `Edit-Property`, `Create-Tag`, `Delete-Tag`, `Rename-Tag`) → batches of **10**, show progress per batch.
   - `Bulk-Edit-Properties` does NOT support `description` or `display_name` — property metadata writes fall back to per-call `Edit-Property`.
9. **'exit' always valid.** Stop, discard uncommitted, return to menu.
10. **No per-command "what next" menus.** Commands return control here. The router shows the menu. Commands must NOT display their own next-action options.
    - *Exceptions:*
      - `review-issues` Phase 4 (triage actions) may present an action prompt — issue triage is inherently interactive.
      - `score-lexicon` Phase 6 may present a bulk-enrich handoff prompt when gaps exist.
