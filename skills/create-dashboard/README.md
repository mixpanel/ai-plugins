# create-dashboard

Build a Mixpanel dashboard from a natural-language brief. Reuses `create-chart` logic for individual charts, but skips the per-chart confirmation dance — validates everything in one batch, then builds. Auto-organizes charts into sections when there are 5+ charts.

## What it does

Takes a brief like *"build me a weekly product review dashboard for our exec team — DAU, top funnels, retention, and feature adoption"* and:

1. Resolves project context
2. Captures the dashboard's purpose and audience
3. Plans the chart inventory (lists every planned chart, classified by type)
4. Validates all events, properties, and values in one batch
5. Builds and renders all charts, organized into logical sections
6. Hands back with a summary and any issues worth attention

## Who it's for

End users in their own Claude environment with Mixpanel MCP connected. Designed for users who want a working dashboard from a brief, not a wireframe to review.

## Requirements

- Mixpanel MCP connected
- User has read access to the project, write access to create dashboards

## Install

1. Download `create-dashboard.zip`
2. Unzip
3. Drop the `create-dashboard/` folder into your skills directory

## Trigger phrases

- "build a dashboard for [purpose]"
- "create a board with [chart list]"
- "set up an exec dashboard"
- "I need a dashboard that shows X, Y, Z"
- "weekly review board"
- "post-launch tracking dashboard"

Also activates when the user lists 3+ charts that clearly belong together, even if they don't say the word "dashboard."

## How sectioning works

- 4 or fewer charts → flat layout
- 5+ charts → sectioned layout
- Default sections follow the lifecycle: Overview → Acquisition → Engagement → Retention → Quality
- Custom domains override defaults — a "post-launch tracking" dashboard gets sections like "Launch Funnel" and "Adoption" instead of the lifecycle defaults
- Section names adapt to the customer's vocabulary (pulled from `Get-Business-Context`)

## Soft cap on chart count

If the user asks for more than 8 charts, the skill warns once that scannability drops above 8 — then builds whatever the user asks for. No hard cap.

## What the skill won't do

- Single charts (use `create-chart`)
- Reviewing or summarizing an existing dashboard (use `analyze-dashboard`)
- Cleanup, templating, or auditing of existing dashboards (use `mixpanel-dashboard-manager`)

## File structure

```
create-dashboard/
├── SKILL.md                       # Workflow router
└── references/
    └── layout-patterns.md         # Sectioning logic for different audiences
```

The skill also reads chart-build references from the `create-chart` skill at runtime — install both for full functionality.

## Customizing for your team

- **Adjust the soft cap** — currently 8 charts. Change in `SKILL.md` Step 3.
- **Edit default section order** — in `references/layout-patterns.md`. The lifecycle order works for most use cases; change it if your team thinks about dashboards in a different shape.
- **Add team-specific layout patterns** — e.g., if your team has a standard "weekly review" dashboard shape, add it as a named pattern in `layout-patterns.md`.

## Known limitations

- The Mixpanel MCP `Create-Dashboard` tool uses cells and rows, not labeled sections. The skill uses markdown text cells as section headers — this works in current Mixpanel UI but the rendering may evolve.
- Soft cap warning fires once per build. There's no enforcement loop.
- Layout decisions assume a single-screen reader; for very long dashboards, sectioning may not be enough.

## Pairs well with

- `create-chart` — the per-chart logic this skill reuses
- `analyze-dashboard` — for reviewing a dashboard built by this skill
- `mixpanel-dashboard-manager` — for templating, cloning, and cleanup of dashboards built by this skill

## Version

v1 — first draft. Test with real customer briefs before relying on it.
