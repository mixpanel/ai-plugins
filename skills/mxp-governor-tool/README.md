# mxp-governor-tool

Lexicon governance for Mixpanel projects. Audit metadata health, auto-enrich events and properties, categorize with tags, triage data quality issues, reset metadata, and manage existing tags — all through a menu-driven workflow that validates before writing.

## Commands

| Command | What it does |
|---|---|
| **Score Lexicon** | Compute a weighted health score (0–100) across description coverage, display names, verification status, tagging, property metadata, hygiene, and open issues. Auto-offers bulk enrich when gaps exist. |
| **Enrich & Tag** | Auto-generate display names, descriptions, and tags for events/properties missing them. Fill-only-empty — never overwrites existing metadata. |
| **Reset Lexicon** | Clear descriptions, display names, or tags from events/properties. Destructive — requires literal `CONFIRM` to proceed. |
| **Review Issues** | Fetch open data quality issues, triage by severity (type drift, null properties, volume anomalies), with deep-dive and dismiss options |
| **Manage Tags** | Rename or delete existing Lexicon tags across all affected events |

## Example Prompts

- "Score my Lexicon for project 12345"
- "Enrich lexicon"
- "Auto-tag events"
- "Review data quality issues"
- "Reset all tags in my project"
- "Rename tags in my project"

## Requirements

- Mixpanel MCP connected in Claude.ai

## Changelog

### Apr 2026 — Bulk property writes

Property metadata writes (`description`, `display_name`) now go through `Bulk-Edit-Properties` in chunks of 50 instead of per-call `Edit-Property` in batches of 10. Mixpanel's bulk property tool now exposes per-entry `description` and `display_name`, so the previous fallback is no longer needed.

Affected paths:
- **Enrich & Tag** — Step 4d (property metadata) is now bulk. ~5× faster on property-heavy projects.
- **Reset Lexicon** — Step 4c (clearing property descriptions/display names) is now bulk.

Bulk calls split by `resource_type` (`Event` vs `User`) since each call is single-type. If a bulk chunk fails, the flow falls back to per-property `Edit-Property` for that chunk only and continues.

No breaking changes. Command menu, prompts, previews, confirmations, and output formats are identical.
