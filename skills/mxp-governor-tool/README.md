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
