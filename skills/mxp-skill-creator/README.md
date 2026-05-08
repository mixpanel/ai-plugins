# mxp-skill-creator

Guided wizard to create, edit, and review standardised Mixpanel query skills for any customer or internal team. Every event, property, and filter value is validated against live Mixpanel data before being written.

## Flows

| Flow | What it does |
|---|---|
| **Create — Guided** | Step-by-step wizard through 6 modules: business context, metric definitions, breakdown dimensions, data quality signals, presentation guidelines, and final review. Validates everything against live MCP data. Writes one reference file per module. |
| **Create — Quick** | Accepts structured YAML/text input, validates in one batch pass, generates the full skill folder in a single shot. |
| **Edit** | Locates an existing skill folder, shows section health per reference file, lets you add/replace/remove metrics, breakdowns, and config without rebuilding from scratch. Per-file changelog at finalisation. |
| **Describe / Review** | Read-only audit of an existing skill across 6 quality dimensions with prioritised improvement suggestions, citing the reference file each issue lives in. |

## What It Produces

A modular skill **folder** named `[customer]-mixpanel-skill/`, packaged as a `.skill` file:

```
[customer]-mixpanel-skill/
├── SKILL.md                       # Lean entry point: frontmatter, trigger, router, hard rules
└── references/
    ├── business-context.md        # Customer identity + project registry
    ├── metrics.md                 # Standard metric definitions
    ├── breakdowns.md              # Breakdown properties + known values
    ├── data-quality.md            # Gaps, aliases, default filters, service accounts
    ├── query-conventions.md       # Timezone, lookback, thresholds
    └── presentation.md            # Brand, audience, format, chart defaults
```

The lean `SKILL.md` is loaded on every invocation; reference files are loaded on demand by Claude based on the routing table inside `SKILL.md`. This keeps the trigger description visible, lets reference files grow independently, and produces clean per-file diffs when editing.

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
    ├── skill-output-template.md       # Template for the generated skill folder (7 files)
    ├── skill-discovery.md             # Logic to locate existing skills for edit/review
    └── packaging-instructions.md      # How to package a skill folder into a .skill file
```
