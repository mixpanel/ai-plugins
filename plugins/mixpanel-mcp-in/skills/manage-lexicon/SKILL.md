---
name: manage-lexicon
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

# Manage Lexicon

This skill manages a Mixpanel project's Lexicon — the registry of tracked events and properties. It scores metadata quality, bulk-enriches missing descriptions / display names / tags, resets metadata, triages data quality issues, and renames or deletes tags. It runs as a single interactive session per project; do not invoke in parallel for the same project.

---

# Components

The skill is built from a small set of abstractions. The Execution section below tells you how to use them.

## Canonical commands

Each command lives in its own file under `commands/` and is loaded on demand. Match commands explicitly (user names them) or implicitly (message matches a trigger phrase below).

| Command | File | Match if message contains any of |
|---|---|---|
| `score-lexicon` | `commands/score-lexicon.md` | score, audit, health, grade |
| `enrich-and-tag` | `commands/enrich-and-tag.md` | enrich, fill, auto-tag, generate descriptions |
| `reset-lexicon` | `commands/reset-lexicon.md` | reset, wipe, clear metadata, clear tags |
| `review-issues` | `commands/review-issues.md` | issues, drift, anomaly, data quality |
| `manage-tags` | `commands/manage-tags.md` | rename tag, delete tag, merge tags |

If a message matches more than one command, show the Command menu instead.

## Command menu

Shown when no command was detected or inferred.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Manage Lexicon — [Project Name] ([project_id])
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1. Score Lexicon    — Health score (0–100), auto-offer bulk enrich
  2. Enrich & Tag     — Fill empty display names, descriptions & tags
  3. Reset Lexicon    — Clear descriptions / display names / tags
  4. Review Issues    — Triage data quality issues
  5. Manage Tags      — Rename or delete existing tags
  6. Exit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Session context

Persists across commands within a session. Always reuse — never re-fetch what already exists.

| Variable | Description |
|---|---|
| `project_id`, `project_name` | Active project (see Set Project below) |
| `event_list`, `event_details_cache` | Event names and `event_name → metadata` map |
| `property_names`, `property_details_cache` | Event + User property name lists and metadata map |
| `volume_rank_map` | `event_name → { volume, rank }` |
| `issues_list` | Normalised issues from `review-issues` |

## Reference files

Loaded on demand by individual commands. Do not pre-load.

| File | When to read |
|---|---|
| `references/exclusions.md` | Every command before building working sets — defines ignored events / properties (`$ae_*`, `$session_*`, `mp_*`, `$`-prefixed) |
| `references/gotchas.md` | When an unfamiliar MCP error or edge case appears |

## Behaviour rules

1. **No phase narration.** Output only what the user needs to see — progress lines during batched writes, previews, confirmation prompts, errors, and final results. No "I'll now fetch your events…" or "Let me analyze the score…" Just do the work and surface results.
2. **Preview before writes.** Show before/after and require explicit confirmation before any Lexicon mutation.
3. **Destructive writes require literal `CONFIRM`.** `reset-lexicon` requires the user to type `CONFIRM` (case-sensitive).
4. **`exit` always valid.** Stop, discard uncommitted work, return to the Command menu.
5. **Project switching.** Don't change `project_id` mid-command. Between commands, the user may switch projects by naming a different one — re-run Set Project.
6. **If a command can't complete, explain why.** Tell the user what failed and what they can try. Don't fail silently.
7. **Audit trail.** After every successful write command, append `data-governance-runs/[ISO-timestamp]-[command].json` in the working directory. Include `project_id`, command, counts of entities written, counts of failures.

---

# Execution

Follow these steps in order.

## 1. Set project

Resolve which Mixpanel project the user wants to operate on.

- **User named a project (name or ID):** Call `Get-Projects`. Match by ID first, then by case-insensitive name. If one match → `✅ [Project Name] ([project_id])`, proceed.
- **Multiple name matches:** Show the matches in a numbered list, ask the user to pick.
- **No match:** Tell the user what wasn't found, offer to `list` (which re-calls `Get-Projects` and shows the table).
- **User named nothing:** Ask which project. `list` → `Get-Projects` → show table.

If `Get-Projects` fails with tool-not-found, tell the user to connect the Mixpanel MCP and stop.

## 2. Set session context

Initialise empty. Each command populates only what it needs through the bulk-read tools (`Get-Events`, `Get-Properties`, `Get-Issues`, `Get-Business-Context`). Commands check cache first and skip fetches whose data already exists in session.

## 3. Command loop

For each user request, run these steps. Loop until the user exits or starts a new project.

### 3a. Set command

- **Explicit:** User names a command (`/score-lexicon`, "run reset", etc.) → use that command.
- **Implicit:** Message matches exactly one canonical trigger phrase → use that command.
- **Ambiguous or none:** Show the Command menu, take the user's choice.

### 3b. Load command

If the command file is not already in context, read `commands/[command].md`.

### 3c. Execute command

Follow the instructions in the command file. Reuse session context wherever possible.

### 3d. Complete command

Print `✅ Done.` Write the audit log entry (rule 9). Return to step 3a.

If the command itself produced a follow-on offer (Score → Enrich, Reset → Enrich, Review-Issues triage), honour that handoff before returning to step 3a.
