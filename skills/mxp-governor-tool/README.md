# mxp-governor-tool

Lexicon governance for Mixpanel projects. Scores metadata health, auto-fills missing descriptions and display names, categorizes events into tags, triages data quality issues, and manages tag lifecycle.

## Commands

| Command | What it does |
|---|---|
| **Score Lexicon** | Audits metadata coverage across events and properties, computes a weighted health score (0–100), and surfaces the biggest gaps |
| **Enrich Lexicon** | Auto-generates display names and descriptions for events/properties missing them, writes to Lexicon after preview and confirmation |
| **Tag Events** | Analyzes event names to propose functional tags (Commerce, Authentication, Navigation, etc.), creates tags and assigns them |
| **Review Issues** | Fetches open data quality issues, triages by severity (type drift, null values, volume anomalies), supports deep-dive queries and bulk dismiss |
| **Manage Tags** | Rename or delete existing Lexicon tags across all associated events |

## Requirements

- **Mixpanel MCP** connected in Claude.ai (mcp.mixpanel.com or mcp-in.mixpanel.com)
- Project-level access to the Mixpanel project you want to govern

## Example Prompts

- "Score the Lexicon for project 12345"
- "Enrich my Mixpanel project's metadata"
- "Auto-tag events in my project"
- "What data quality issues does project 67890 have?"
- "Clean up tags in my Lexicon"

## File Structure

```
mxp-governor-tool/
├── SKILL.md                    # Router — project validation, command menu, session state
├── commands/
│   ├── score-lexicon.md        # Health scoring pipeline
│   ├── enrich-lexicon.md       # Auto-fill display names & descriptions
│   ├── tag-events.md           # Pattern-based event categorization
│   ├── review-issues.md        # Data quality issue triage
│   └── manage-tags.md          # Rename / delete tags
└── shared/
    └── schema-reader.md        # Reusable schema fetching logic
```
