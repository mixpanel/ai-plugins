# manage-lexicon

Lexicon governance for Mixpanel projects. Score metadata health, auto-enrich events and properties, categorize with tags, triage data quality issues, reset metadata, and rename or delete tags — through a menu-driven workflow that previews and confirms before every write.

## Commands

| Command | What it does |
|---|---|
| **Score Lexicon** | Compute a weighted health score (0–100) across description coverage, display names, verification status, tagging, property metadata, hygiene, and open issues. Auto-offers bulk enrich when gaps exist. |
| **Enrich & Tag** | Auto-generate display names, descriptions, and tags for events / properties missing them. Fill-only-empty — never overwrites existing metadata. |
| **Reset Lexicon** | Clear descriptions, display names, or tags from events / properties. Destructive — requires literal `CONFIRM` to proceed. Auto-offers re-enrichment after a full reset. |
| **Review Issues** | Fetch open data quality issues, triage by severity (type drift, null properties, volume anomalies), with deep-dive and dismiss options. |
| **Manage Tags** | Rename or delete existing Lexicon tags across all affected events. |

## Example prompts

The skill resolves projects by name or ID, so you can refer to projects however you'd naturally describe them.

- "Score my Lexicon for the Acme project"
- "Half my events have no descriptions in project 12345"
- "Audit our tracking plan"
- "Auto-tag events for Acme Streaming"
- "Review data quality issues"
- "Reset all tags in our prod project"
- "Rename tags in Acme"

## Example output (Score Lexicon)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  LEXICON SCORE — Acme Streaming
  Score: 68/100 (C — Needs work)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Event descriptions      54%     (wt 20%)
  Event display names     71%     (wt 8%)
  Event verified          22%     (wt 15%)
  Event tags              48%     (wt 10%)
  Property descriptions   60%     (wt 20%)
  Property display names  82%     (wt 7%)
  Hygiene (hide/drop)     95%     (wt 10%)
  Data quality issues     86/100  (wt 10%)
───────────────────────────────────────────────

TOP GAPS
  1. 47 events — no description
  2. 53 events — no tags
  3. 4 zero-volume events not hidden
  4. 38 properties — no description

ZERO-METADATA EVENTS
  legacy_payment_init, debug_xyz, …
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

107 total metadata/tag gaps detected.

(a) Run bulk enrichment on gaps  (b) Return to menu
```

## How the skill is organised

`SKILL.md` is split into two sections:

- **Components** — the building blocks (canonical commands, command menu, session context, reference files, behaviour rules).
- **Execution** — the runtime flow (set project → set session context → command loop).

Each command runs inside the command loop in three steps: set the command (explicit, implicit, or via menu) → load the command file → execute. The loop reuses the session context across commands so nothing gets re-fetched.

## Folder layout

```
SKILL.md
README.md
CHANGELOG.md
commands/        — one file per user-facing command
  score-lexicon.md
  enrich-and-tag.md
  reset-lexicon.md
  review-issues.md
  manage-tags.md
references/      — on-demand content loaded by commands
  exclusions.md  — single source of truth for ignored events / properties
  gotchas.md     — edge cases and operational quirks the agent will otherwise get wrong
assets/          — static payloads
  volume-ranking-query.json
```

## Runtime notes

- Runs as a single interactive session per project. Do not invoke in parallel for the same project.
- Project switching between commands is supported — name a different project to re-run Set Project mid-session.
- Destructive commands (`reset-lexicon`) require literal `CONFIRM` (case-sensitive). `EXPORT` saves a JSON preview without committing.
- Every successful write command appends a one-line audit entry to `data-governance-runs/[timestamp]-[command].json` in the working directory.

## Requirements

- Mixpanel MCP connected.
- Working directory writable (for the audit log).

## Changelog

See `CHANGELOG.md`.
