# mxp-skill-creator

Guided wizard to create, edit, and review standardised Mixpanel query skills for any customer or internal team. Every event, property, and filter value is validated against live Mixpanel data before being written.

## Flows

| Flow | What it does |
|---|---|
| **Create — Guided** | Step-by-step wizard through 6 modules: business context, metric definitions, breakdown dimensions, data quality signals, presentation guidelines, and final review. Validates everything against live MCP data. |
| **Create — Quick** | Accepts structured YAML/text input, validates in one batch pass, generates the skill in a single shot |
| **Edit** | Locates an existing skill, shows section health, lets you add/replace/remove metrics, breakdowns, and config without rebuilding from scratch |
| **Describe / Review** | Read-only audit of an existing skill across 6 quality dimensions with prioritised improvement suggestions |

## What It Produces

A complete `[customer]-mixpanel-skill/SKILL.md` file containing:
- Business context and validated project IDs
- Metric definitions with canonical event names, aggregations, and filters
- Breakdown properties with known values and list-type flags
- Data quality signals (instrumentation gaps, event aliases, default exclusion filters)
- Query conventions (timezone, lookback, thresholds)
- Presentation and brand guidelines

The output skill can then be installed in Claude.ai so that future analytics queries for that customer automatically use validated definitions.

## Requirements

- **Mixpanel MCP** connected in Claude.ai (mcp.mixpanel.com or mcp-in.mixpanel.com)
- Project-level access to the customer's Mixpanel project(s)

## Example Prompts

- "Create a Mixpanel skill for Acme Corp"
- "Let's build a query skill for my customer"
- "Edit the existing Nykaa skill — add a new metric"
- "Review the JioHotstar skill and suggest improvements"
- "Resume the skill I was building yesterday"

## File Structure

```
mxp-skill-creator/
├── SKILL.md                           # Main wizard — all flows, modules, global rules
└── references/
    ├── skill-output-template.md       # Template for the generated skill file
    ├── skill-discovery.md             # Logic to locate existing skills for edit/review
    └── packaging-instructions.md      # How to package a skill into a .skill file
```
