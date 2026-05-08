# create-chart

Build a Mixpanel chart from a natural-language description. Covers Insights, Funnels, Retention, and Flows. Render-first — the chart appears inline, not as a JSON spec. Offers to save into a Mixpanel dashboard at the end.

## What it does

Takes a fuzzy ask like *"show me checkout conversion last 30 days, broken down by platform"* and:

1. Resolves which Mixpanel project to query
2. Classifies the chart type (Insights / Funnel / Retention / Flow)
3. Validates every event, property, and filter value against live Mixpanel data
4. Builds the query, runs it, renders the chart inline
5. Offers to save it into a dashboard (existing or new)

## Who it's for

End users in their own Claude environment with Mixpanel MCP connected. The skill assumes nothing about the project — it works for any Mixpanel project the user has access to.

## Requirements

- Mixpanel MCP connected
- User has at least read access to the project they want to query
- For the save step: write access to a dashboard in the project

## Install

1. Download `create-chart.zip`
2. Unzip
3. Drop the `create-chart/` folder into your skills directory, or upload via the Claude UI's skill installer

## Trigger phrases

The skill activates on phrases like:

- "create a chart of [event]"
- "plot [metric] over time"
- "build a funnel from X to Y"
- "show me retention for [event]"
- "visualize [metric] by [property]"
- "how many users complete checkout each day"

It also activates when the user describes what they want without naming the chart type — the skill classifies it automatically.

## What the skill won't do

- Build dashboards (use `create-dashboard`)
- Explain a chart that already exists (use `analyze-chart`)
- Diagnose why a metric moved (use `mxp-metric-diagnosis`)

## File structure

```
create-chart/
├── SKILL.md                       # Workflow router (loaded when skill triggers)
└── references/
    ├── insights.md                # Insights chart build patterns
    ├── funnels.md                 # Funnel build patterns
    ├── retention.md               # Retention build patterns
    └── flows.md                   # Flow build patterns
```

The references are loaded on demand based on the chart type the user asked for. Each one covers build patterns, common pitfalls, and chart-specific defaults.

## Customizing for your team

The most common edits:

- **Add custom defaults** — in `SKILL.md` Step 4, change the default date range (currently 30 days), default measurement unit (currently total events), or compare-to-previous-period default.
- **Add team-specific event aliases** — if your team calls signups something specific, add it to the relevant reference file's name-resolution notes.
- **Tighten chart-type defaults** — e.g., if you want all retention charts to default to weekly granularity regardless of date range, edit `references/retention.md`.

## Known limitations

- The save step uses `Update-Dashboard` and `Create-Dashboard` (Mixpanel MCP doesn't expose a standalone save-as-report tool). So "save the chart" actually means "add it to a dashboard."
- Mixpanel chart URL formats vary across legacy and current versions. The skill handles current formats cleanly; for legacy URLs it falls back to asking the user for the report ID.
- Customer-facing skill — assumes the user is unfamiliar with Mixpanel MCP tool names. Defensive validation is a feature, not a bug.

## Pairs well with

- `create-dashboard` — same chart-build logic, batched across multiple charts
- `analyze-chart` — explains a chart this skill (or any other source) built
- `mxp-metric-diagnosis` — for the "but why did it move" follow-up

## Version

v1 — first draft, not yet eval'd. Test with real customer asks before treating as production-ready.
