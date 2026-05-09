---
name: data-governance
license: Apache-2.0
description: >
  Audit, score, enrich, or clean up the Lexicon (events and properties metadata)
  for a Mixpanel project. Use whenever the user wants to score Lexicon health,
  bulk-fill missing descriptions / display names / tags, reset metadata, triage
  data quality issues (type drift, null values, volume anomalies), or rename
  and delete tags. Also use when the user describes the problem without naming
  the tool — "event names are a mess", "half my events have no descriptions",
  "tracking plan audit", "clean up the schema", "score our instrumentation" —
  as long as Mixpanel is the context. Trigger phrases: "score lexicon",
  "enrich lexicon", "bulk enrich", "auto-tag events", "reset lexicon",
  "wipe tags", "review data quality issues", "rename/delete Lexicon tags".
  Do NOT use for: deleting event data or user profiles; dashboard cleanup;
  cohort tagging; customer health scoring. Requires Mixpanel MCP.
---

# Mixpanel Data Governance

> **Loading model:** Progressive. Only this file on entry. Command and reference files are read on-demand after routing — do not pre-load.

Top-level router: validate project → route command → handle return.

---

## Step 0 — Project & Intent Routing

The router branches on three states:

| State | Definition | Action |
|---|---|---|
| **Direct route** | User message contains a project ID **AND** a phrase that matches one of the canonical command triggers (see table below) | Validate project → run that command directly. Skip the menu. |
| **Project only** | Project ID present, no command phrase | Validate project → show menu. |
| **Neither** | No project ID | Ask which project. `list` → call `Get-Projects`, show table. |

**Canonical command triggers (used to disambiguate "clear command intent"):**

| Command | Match if message contains any of |
|---|---|
| `score-lexicon` | score, audit, health, grade |
| `enrich-and-tag` | enrich, fill, auto-tag, generate descriptions |
| `reset-lexicon` | reset, wipe, clear metadata, clear tags |
| `review-issues` | issues, drift, anomaly, data quality |
| `manage-tags` | rename tag, delete tag, merge tags |

If a message matches more than one command — show the menu.

**Validation:**

1. Call `Get-Projects`. Match ID. If found → `✅ [Project Name] ([project_id])`, proceed.
2. Not found → error, ask to re-enter or `list`.

**MCP check:** `Get-Projects` fails with tool-not-found → tell user to connect Mixpanel MCP, stop.

---

## Command Menu

Show only when no direct command was inferred:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Data Governance — [Project Name] ([project_id])
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1. Score Lexicon    — Health score (0–100), auto-offer bulk enrich
  2. Enrich & Tag     — Fill empty display names, descriptions & tags
  3. Reset Lexicon    — Clear descriptions / display names / tags
  4. Review Issues    — Triage data quality issues
  5. Manage Tags      — Rename or delete existing tags
  6. Exit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

| Choice | File to read | Action |
|---|---|---|
| 1 | `commands/score-lexicon.md` | execute |
| 2 | `commands/enrich-and-tag.md` | execute |
| 3 | `commands/reset-lexicon.md` | execute |
| 4 | `commands/review-issues.md` | execute |
| 5 | `commands/manage-tags.md` | execute |
| 6 | — | exit |

---

## Return Handler

When a command completes → `✅ Done.` → re-display command menu. No re-validation of the project.

---

## Session Context

Persist across commands. **Cross-command reuse is mandatory** — never re-fetch what already exists in session.

| Variable | Description |
|---|---|
| `project_id` | Immutable after Step 0. |
| `project_name` | Display name. |
| `event_list` | Full event name list. |
| `event_details_cache` | `event_name → metadata` map. |
| `property_names` | Event + user property name lists. |
| `property_details_cache` | `property_name → metadata` map. |
| `volume_rank_map` | `event_name → { volume, rank }`. |
| `issues_list` | Normalised issues from `review-issues`. |

---

## Reference Files

Loaded on-demand by individual commands. Do not pre-load.

| File | When to read | Why |
|---|---|---|
| `references/schema-reader.md` | Any command that needs Lexicon data | Defines the (cached) bulk-fetch sequence for events, properties, and volume rank. |
| `references/exclusions.md` | Every command before building working sets | Single source of truth for ignored events / properties (`$ae_*`, `$session_*`, `mp_*`, `$`-prefixed). |
| `references/mcp-cheatsheet.md` | Any command that writes | Chunk sizes, `add` vs `set` semantics, single-resource-type bulk property writes, fallback paths. |
| `references/gotchas.md` | When unsure about an MCP edge case | Curated list of things that have broken historically. Read if you hit an unfamiliar error. |

---

## Behavior Rules

1. **Silent execution.** No phase announcements. Output only: progress during batch writes, errors, confirmation prompts, and final results. Nothing else.
2. **Preview before writes.** Before/after + explicit confirmation before any Lexicon mutation.
3. **Fill-only-empty for `enrich-and-tag`.** Never overwrite existing descriptions, display names, or tags. If the user wants to regenerate, they run `reset-lexicon` first. This is a hard rule — no config flag bypasses it.
4. **Destructive writes require literal `CONFIRM`.** `reset-lexicon` requires the user to type the string `CONFIRM` (case-sensitive). No soft confirmations.
5. **`exit` always valid.** Stop, discard uncommitted, return to menu.
6. **No per-command "what next" menus.** Commands return control here; the router shows the menu. Exceptions: `review-issues` Phase 4 (interactive triage), `score-lexicon` Phase 6 (bulk-enrich handoff), `reset-lexicon` Phase 6 (regenerate handoff).

## Mechanics Rules

7. **Project ID immutable.** All MCP calls use the confirmed `project_id`.
8. **Surface MCP failures explicitly.** Never silently skip.
9. **Query fallback.** `Run-Query` fails → `Get-Query-Schema` → retry once.
10. **Batch sizes.** See `references/mcp-cheatsheet.md` (single source of truth). Summary: bulk event/property writes in chunks of 50; per-call fallback writes in batches of 10 with progress per batch.
11. **Audit trail.** After every successful write command, append a one-line summary to `data-governance-runs/[ISO-timestamp]-[command].json` in the working directory. Include: project_id, command, counts of entities written, counts of failures.
