---
name: manage-lexicon
license: Apache-2.0
description: >
  Audit, score, enrich, or clean up the Lexicon (events and properties metadata)
  for a Mixpanel project. Use whenever the user wants to score Lexicon health,
  bulk-fill missing descriptions / display names / tags, reset metadata, triage
  data quality issues (type drift, null values, volume anomalies), or rename
  and delete tags. Also use when the user describes the problem in their own
  words — "score lexicon", "enrich lexicon", "bulk enrich", "auto-tag events",
  "reset lexicon", "wipe tags", "review data quality issues", "rename/delete
  Lexicon tags", "event names are a mess", "half my events have no
  descriptions", "tracking plan audit", "clean up the schema", "score our
  instrumentation" — as long as Mixpanel is the context.
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

## Session vocabulary

The skill maintains a typed vocabulary of session state that persists across commands within a single session. Each command declares which keys it reads and writes at the top of its file (`Session reads:` / `Session writes:`). Commands check the session first and only fetch what's missing — never re-fetch what already exists.

| Key | Shape | Description |
|---|---|---|
| `project_id`, `project_name` | string | Active project (set in Step 1). |
| `event_list` | `string[]` | Event names in the project's Lexicon, post-exclusions. |
| `event_details_cache` | map | `event_name → full metadata` (description, display_name, verified, tags, hidden, dropped). |
| `property_names` | `{ event: [], user: [] }` | Property name lists split by resource type. |
| `property_details_cache` | map | `property_name → full metadata`. |
| `volume_rank_map` | map | `event_name → { volume, rank }`. Empty `{}` if volume query fails. |
| `issues_list` | array | Normalised data quality issues, populated by `review-issues`. |
| `existing_tags` | array | Tag names in use across the project, populated by `manage-tags` and `enrich-and-tag`. |

## Exclusions

Always-on filters. Apply before building any working set, gap list, or write payload — excluded entities are never read, scored, or written.

**Ignored events**
- `$ae_first_open`, `$ae_updated`, `$ae_session`, `$ae_iap`, `$ae_crashed` — legacy auto-tracked mobile SDK events. Mixpanel-managed; customers cannot edit metadata.
- `$session_start`, `$session_end` — virtual events (project session definitions). No Lexicon row.

**Ignored properties**
- Any property name starting with `mp_` — Mixpanel-managed reserved namespace.
- Any property name starting with `$` — Mixpanel system properties.

**Not excluded:** custom events that happen to start with `$` (only the explicit `$ae_*` / `$session_*` list is filtered). Hidden and dropped events stay in the working set — they're part of hygiene scoring.

## Behaviour rules

1. **No phase narration.** Output only what the user needs to see — progress lines during batched writes, previews, confirmation prompts, errors, and final results. No "I'll now fetch your events…" or "Let me analyze the score…". Do the work and surface results.
2. **Preview before writes.** Show before/after and require explicit confirmation before any Lexicon mutation.
3. **Destructive writes require literal `CONFIRM`** (case-sensitive). Anything else cancels, except `EXPORT`, which writes the preview to JSON without committing.
4. **`exit` always valid.** Stop, discard uncommitted work, return to the Command menu.
5. **Project switching.** If the user wants to operate on a different project mid-session, suggest starting a new conversation first. If they insist, resolve the new project and continue with that `project_id`.
6. **If a command can't complete, explain why.** Tell the user what failed and what they can try. Don't fail silently.
7. **Audit trail.** After every successful write command, append `data-governance-runs/[ISO-timestamp]-[command].json` in the working directory. Include `project_id`, command, counts of entities written, counts of failures.
8. **In `enrich-and-tag`, add tags; don't replace.** Add new tags to events without removing or replacing existing ones.
9. **Fill-only-empty in `enrich-and-tag`.** Only write to a field if it's currently null or empty. Never overwrite existing metadata. Use `reset-lexicon` first if regenerating.

---

# Execution

Follow these steps in order.

## 1. Set project

Resolve which Mixpanel project the user wants to operate on.

- **User named a project (name or ID):** list all projects in the workspace. Match by ID first, then by case-insensitive name. If one match → `✅ [Project Name] ([project_id])`, proceed.
- **Multiple name matches:** show the matches in a numbered list, ask the user to pick.
- **No match:** tell the user what wasn't found, offer to `list` (which re-fetches the project list and shows the table).
- **User named nothing:** ask which project. `list` → fetch projects → show table.

If the project listing fails with tool-not-found, tell the user to connect the Mixpanel MCP and stop.

## 2. Set session context

Start empty. Commands populate what they need and skip fetches whose data already exists in session.

## 3. Command loop

For each user request, run these steps. Loop until the user exits or starts a new project.

### 3a. Choose command

- **Explicit:** user names a command (`/score-lexicon`, "run reset", etc.) → use that command.
- **Implicit:** message matches exactly one canonical trigger phrase → use that command.
- **Ambiguous or none:** show the Command menu, take the user's choice.

### 3b. Load command

If the command file is not already in context, read `commands/[command].md`.

### 3c. Execute command

Follow the instructions in the command file. Reuse session context wherever possible.

### 3d. Complete command

Print `✅ Done.` Write the audit log entry per the Audit trail rule. Return to choosing the next command.

If the command itself produced a follow-on offer (Score → Enrich, Reset → Enrich, Review-Issues triage), honour that handoff before returning to command selection.
