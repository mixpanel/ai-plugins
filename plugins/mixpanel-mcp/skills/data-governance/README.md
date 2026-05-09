# data-governance

Lexicon governance for Mixpanel projects. Audit metadata health, auto-enrich events and properties, categorize with tags, triage data quality issues, reset metadata, and manage existing tags — all through a menu-driven workflow that previews and confirms before writing.

## Commands

| Command | What it does |
|---|---|
| **Score Lexicon** | Compute a weighted health score (0–100) across description coverage, display names, verification status, tagging, property metadata, hygiene, and open issues. Auto-offers bulk enrich when gaps exist. |
| **Enrich & Tag** | Auto-generate display names, descriptions, and tags for events / properties missing them. Fill-only-empty — never overwrites existing metadata. |
| **Reset Lexicon** | Clear descriptions, display names, or tags from events / properties. Destructive — requires literal `CONFIRM` to proceed. Auto-offers re-enrichment after a full reset. |
| **Review Issues** | Fetch open data quality issues, triage by severity (type drift, null properties, volume anomalies), with deep-dive and dismiss options. |
| **Manage Tags** | Rename or delete existing Lexicon tags across all affected events. |

## Example Prompts

- "Score my Lexicon for project 12345"
- "Half my events have no descriptions"
- "Audit our tracking plan"
- "Auto-tag events"
- "Review data quality issues"
- "Reset all tags in my project"
- "Rename tags in my project"

## Example Output (Score Lexicon)

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

## Folder Layout

```
SKILL.md
README.md
CHANGELOG.md
commands/        — one file per user-facing command
references/      — on-demand reference content (schema, exclusions, MCP quirks, gotchas)
assets/          — static payloads (e.g. canonical Run-Query JSON)
```

## Requirements

- Mixpanel MCP connected.
- Working directory writable (for the per-run audit log).

## Changelog

See `CHANGELOG.md`.
