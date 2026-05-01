---
name: create-chart
description: >
  Create a Mixpanel chart from a natural-language description. Use
  whenever the user asks to build, make, plot, visualize, or chart
  anything in Mixpanel — event volumes, conversion funnels, retention
  curves, user flows, breakdowns, or segmentation. Trigger phrases:
  "create a chart", "make a chart of", "plot [event] over time", "build
  a funnel from X to Y", "show me retention for", "chart conversion
  from signup to checkout", "visualize [metric] by [property]", "I want
  to see [event] broken down by", "build me an insights report", "graph
  [event] last 30 days". Also trigger when the user describes what they
  want to see without naming the chart type — "how many users complete
  checkout each day", "what's the drop-off between cart and purchase",
  "do users come back after signup". Covers Insights, Funnels,
  Retention, and Flows. Do NOT trigger for building dashboards (use
  `create-dashboard`), explaining a chart (use `analyze-chart`), or RCA
  on a metric (use `mxp-metric-diagnosis`). Requires Mixpanel MCP.
compatibility: "Requires Mixpanel MCP. Works for any project the user has access to."
---

# Mixpanel Create Chart

Build a working Mixpanel chart from a natural-language ask. The customer
describes what they want to see; the skill resolves it against their
project, picks the right chart type, runs the query, renders the result
inline, and offers to save it as a saved report.

The skill is **render-first**: the user came here to see a chart, not to
review a query spec. Validation happens fast and silently when matches
are clean; only ambiguous matches surface as a confirmation question.

---

## When this skill runs, it does five things in order

1. **Resolve project context** — confirm which Mixpanel project to query
2. **Classify the chart type** — Insights / Funnel / Retention / Flow
3. **Resolve names against live data** — events, properties, filter values
4. **Build, run, and render the query** — never just show JSON
5. **Offer to save** — as a Mixpanel saved report

Each step has a defensive fallback. The skill never silently substitutes
a guess for a real match.

---

## Step 1 — Resolve project context

Customer-facing skills cannot assume project ID. Three ways to land it:

- **User states it** — "in project 12345" or "for our prod project"
- **MCP tool default** — call `Get-Projects`. If exactly one project is
  returned, use it and tell the user which project you're working in.
- **Ambiguous (multiple projects returned)** — show the list, ask the
  user which one. Never guess.

After project is resolved, call `Get-Business-Context` once. The user's
own context (north star, KPIs, segments) often disambiguates fuzzy asks
("our activation funnel" → maps to a defined activation event sequence).
If empty, proceed without it.

---

## Step 2 — Classify the chart type

Map the user's ask to one of four types. The classification rules:

| User says... | Chart type |
|---|---|
| "how many", "count of", "trend of", "by [property]", "broken down by", "over time" | **Insights** |
| "funnel", "conversion from X to Y", "drop-off", "complete checkout after", "step-by-step" | **Funnel** |
| "come back", "return", "retention", "stickiness", "DAU/WAU/MAU" | **Retention** |
| "user journey", "what do users do after", "flow from", "next event after", "paths" | **Flow** |

**Ambiguity rules** — when the ask could be two types, ask one short
question. Examples:
- "show me checkout conversion" → could be Insights ratio OR Funnel.
  Ask: *"Funnel from cart-add to checkout, or just the conversion rate
  over time?"*
- "users who completed signup" → could be Insights count OR cohort.
  Default to Insights (event count) unless they say "cohort".

When the ask is unambiguous, do not ask. Just classify and proceed.

For chart-type-specific build patterns, read the matching reference:
- Insights → `references/insights.md`
- Funnels → `references/funnels.md`
- Retention → `references/retention.md`
- Flows → `references/flows.md`

---

## Step 3 — Resolve names against live data

This is the step where customer-facing skills go silently wrong if you
skip it. Every event name, property name, and filter value must be
confirmed against live Mixpanel data before the query runs.

### Events

Call `Get-Events` for the project. Match the user's phrasing against
both `name` and `description` fields.

- **Exact match** → use it, no confirmation needed
- **One close match** (e.g., user said "signup", event is `User Signed
  Up`) → use it, mention the resolution in passing: *"Using `User Signed
  Up` for signup."*
- **Multiple plausible matches** → show top 3, ask which one
- **No match** → show the 3 most similar events found, ask which to use,
  or offer to refine

Do not ask the user to pick when there's only one obvious match. The
goal is render speed.

### Properties

Call `Get-Properties` for breakdowns and filters. Same resolution
pattern as events.

**Critical**: `Get-Properties` returns both event-scoped and user-scoped
properties. Read the `entity` / scope field — validating an event
property against the user-property namespace returns false negatives.
When the user names a property, infer scope from context (breakdown of
event volume → event property; segment users by → user property), and
ask only when truly ambiguous.

**List-type properties**: read the `type` field from `Get-Properties`. If
`type: list`, the breakdown query needs `propertyType: 'list'`.
Forgetting this returns wrong counts.

### Filter values

Call `Get-Property-Values` scoped to the validated event/property. Same
resolution pattern. For high-cardinality properties (>50 values), match
on substring. If still ambiguous, show top 5 and ask.

---

## Step 4 — Build, run, and render

Every chart type uses two MCP calls:

1. `Run-Query` — execute the query, returns a `query_id`
2. `Display-Query` — renders the chart inline via the visualization widget

**Always call `Display-Query`.** Returning JSON or a text summary is a
failure mode — the customer asked for a chart.

For exact query schema per chart type, the model running this skill
should call `Get-Query-Schema` from the MCP. Schema changes faster than
documentation; do not hardcode field names from memory.

### Defaults the customer didn't specify

When the user is vague, fill in sensible defaults rather than asking:

- **Date range**: last 30 days, daily granularity
- **Compare to previous period**: off (turn on if user says "vs last
  month" or "compared to")
- **Unit**: total events (turn to unique users if user says "users",
  "people", "uniques")
- **Sampling**: off
- **Segmentation filters**: only what the user explicitly named

Mention the defaults you applied in one line: *"Showing last 30 days,
total events, no segmentation."* Customer can correct in one turn.

### Errors that need the user

- **Query timeout** — surface plainly: *"Query timed out. Want to narrow
  the date range or remove a breakdown?"*
- **No data** — surface plainly: *"No data returned. The event exists
  but has zero matching rows in the date range. Try a longer window?"*
- **Permission error** — surface plainly: *"Project access denied. Check
  with your Mixpanel admin."*

Do not retry silently. Do not fabricate a result.

---

## Step 5 — Offer to save into a dashboard

The Mixpanel MCP exposes `Create-Dashboard` and `Update-Dashboard`, not
a standalone save-as-report tool. So saving = adding the chart to a
dashboard.

After the chart renders, offer:

> *"Want me to save this into a dashboard? I can add it to an existing
> one or create a new one."*

If **add to existing** → call `Search-Entities` with
`entity_types=['dashboard']` to find dashboards in the project, list
the top matches, ask which one, then call `Update-Dashboard` to append
the chart as a new cell. Read `Get-Dashboard` with
`include_layout=True` first to get cell/row IDs (required by
`Update-Dashboard`).

If **create new** → ask for a dashboard name (suggest one based on the
chart), then call `Create-Dashboard`.

If **no** → end the turn cleanly. Do not push.

Confirm with a link to the dashboard in either path.

---

## Hard rules

These apply across every chart type. No exceptions.

- **Never skip name resolution.** An unvalidated event silently produces
  wrong results.
- **Always render via `Display-Query`.** JSON output is not a chart.
- **One question at a time.** Customer-facing means low patience for
  multi-question prompts.
- **Show defaults, don't hide them.** One line: *"Last 30 days, daily,
  total events."* So the customer can correct.
- **List-type properties need `propertyType: 'list'`.** Read it from
  `Get-Properties`, do not infer.
- **Render first, save second.** Never ask "do you want to save" before
  the chart is on screen.

---

## Quick reference — MCP tools used

| Step | Tool |
|---|---|
| 1 | `Get-Projects`, `Get-Business-Context` |
| 3 | `Get-Events`, `Get-Properties`, `Get-Property-Values` |
| 4 | `Get-Query-Schema`, `Run-Query`, `Display-Query` |
| 5 | `Search-Entities`, `Get-Dashboard`, `Update-Dashboard`, `Create-Dashboard` |

For chart-type-specific schema, read the matching reference file in
`references/`.
