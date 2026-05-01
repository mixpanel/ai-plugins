---
name: create-dashboard
description: >
  Build a Mixpanel dashboard from a natural-language brief. Use whenever
  the user wants to create, build, set up, or assemble a dashboard,
  board, view, or report collection in Mixpanel — for executives, for a
  product launch, for a weekly review, for onboarding tracking, for
  anything that needs more than one chart in one place. Trigger phrases:
  "build a dashboard", "create a board", "set up a dashboard for",
  "I need a dashboard that shows", "make me an exec dashboard", "build
  a board with these charts", "put together a dashboard on", "weekly
  review board", "launch tracking dashboard", "dashboard with [X, Y, Z]".
  Also trigger when the user lists 3+ charts they want and implies they
  belong together. Organizes charts into logical sections (Overview,
  Acquisition, Engagement, Retention) when 5+ charts are involved. Do
  NOT trigger for single-chart asks (use `create-chart`), reviewing an
  existing dashboard (use `analyze-dashboard`), or general account
  health checks (use `weekly-pulse`). Requires Mixpanel MCP.
compatibility: "Requires Mixpanel MCP. Works for any project the user has access to."
---

# Mixpanel Create Dashboard

Build a working Mixpanel dashboard from a natural-language brief. The
customer describes what they want to track; the skill turns that into a
chart inventory, builds each chart, organizes them into a coherent
layout, and creates the dashboard.

This skill **shares logic with `create-chart`** — every chart on the
dashboard is built using the same validation and query patterns. The
difference is that `create-dashboard` skips the per-chart confirmation
dance: validate up front, build in one pass, render the whole
dashboard.

For chart-type-specific build patterns, read the matching reference
from the `create-chart` skill (`references/insights.md`,
`funnels.md`, `retention.md`, `flows.md`). Do not duplicate that logic
here.

---

## When this skill runs, it does six things in order

1. **Resolve project context** — same as `create-chart` Step 1
2. **Capture the brief** — what is this dashboard *for* and *who reads it*
3. **Plan the chart inventory** — list every chart, classified by type
4. **Validate everything in one batch** — all events, properties, values
5. **Build, render, and lay out** — section the charts, create the dashboard
6. **Hand back with a summary** — what was built, what to verify

---

## Step 1 — Resolve project context

Identical to `create-chart` Step 1. Call `Get-Projects`. If exactly one,
use it. If multiple, ask. After resolving, call `Get-Business-Context`
once — for dashboards this is more important than for single charts,
because the customer's defined KPIs and segments often map directly to
sections of the dashboard.

---

## Step 2 — Capture the brief

Two questions, asked together:

> *"Two quick things before I build:
> 1. What's this dashboard for? (e.g., weekly exec review, post-launch
>    tracking, onboarding health)
> 2. Who's the audience? (e.g., product team, leadership, GTM)"*

Why this matters: the same set of charts looks different when it's for
a VP vs. an analyst. A VP dashboard is 4–6 high-signal charts with
clear titles. An analyst dashboard is 8–12 charts with breakdowns and
filters. The brief drives the layout opinion in Step 5.

If the customer already gave you the audience and purpose in their
opening message, skip this step.

---

## Step 3 — Plan the chart inventory

Goal: turn the customer's brief into a concrete list of charts before
any query runs. List format:

```
Planned charts:
1. [Insights] DAU over time — last 30 days
2. [Insights] New signups by source — last 30 days, broken down by utm_source
3. [Funnel] Signup → activation → first key action — 7-day window
4. [Retention] Weekly retention from signup
5. [Insights] Feature adoption rate — top 5 features
```

**Soft cap at 8 charts.** If the inventory exceeds 8, surface this
once:

> *"That's [N] charts — dashboards above 8 charts get harder to scan.
> Want me to consolidate, or build it as planned?"*

Build whatever the customer asks for after the warning. Do not
re-prompt.

**Chart classification follows `create-chart` Step 2** — same lookup
table for Insights / Funnels / Retention / Flows. Customer doesn't need
to know the chart type; classify it for them.

Show the inventory before building, and ask: *"Look right?"* This is
the only confirmation gate in the whole skill — get it right once, then
build everything.

---

## Step 4 — Validate everything in one batch

This is the efficiency win over running `create-chart` N times. Make
each MCP read call once, not per chart:

- `Get-Events` once → use to validate every event across all charts
- `Get-Properties` once → use for every breakdown and filter
- `Get-Property-Values` per (property, chart) pair where needed

Build a validation table:

```
Event/Property                Found?   Resolution
User Signed Up                 ✅       exact
Activated                      ⚠️       found "User Activated" — use that
Page View                      ✅       exact (default $mp_page_view)
utm_source                     ✅       event property, list-type ❌
plan                           ✅       user property
```

Surface only the items that need a decision (⚠️ rows). Resolve them all
in one batch:

> *"A couple of name resolutions:
> - 'Activated' isn't an event — closest match is `User Activated`. Use that?
> - 'Page View' resolved to the default `$mp_page_view`. OK?"*

Resolve in one turn. Then proceed.

For chart-type-specific validation gotchas (list-type breakdowns,
funnel step ordering, retention birth/return events), read the matching
reference from `create-chart/references/`. The pitfalls section of each
file applies here too.

---

## Step 5 — Build, render, and lay out

Run `Run-Query` for each chart. Collect the `query_id`s. Then create
the dashboard with all charts in one pass.

### Layout: when to section

**Flat layout** if 4 or fewer charts. The customer doesn't need
sectioning for that few.

**Sectioned layout** if 5+ charts. Group charts into sections following
the funnel of user lifecycle. Default sections, in order:

1. **Overview** — top-line metrics (DAU, MAU, key conversion rate)
2. **Acquisition** — how users arrive (signups, sources, channels)
3. **Engagement** — what users do (feature usage, key events)
4. **Retention** — do users come back (cohort retention, stickiness)
5. **Quality / Errors** — only if the brief mentions errors, infra,
   reliability

Map each chart to a section based on its content. A chart that doesn't
fit any section goes in **Overview**. Skip sections with zero charts.

**Custom sections override defaults.** If the customer's brief is
domain-specific (e.g., "post-launch tracking"), name sections to match
the domain (e.g., **Launch Funnel**, **Adoption**, **Feedback Signals**)
rather than forcing the default lifecycle layout.

Surface the planned sectioning before creating:

```
Layout:
📊 Overview
  - DAU over time
  - Signup → activation funnel

📥 Acquisition
  - New signups by source

🔄 Retention
  - Weekly cohort retention
```

If the customer is OK, call `Create-Dashboard` with the full structure.
The widget renders the dashboard inline.

---

## Step 6 — Hand back

After the dashboard is created, return:

- A link to the dashboard in Mixpanel
- A summary of charts built, grouped by section
- Any items that need the customer's attention (e.g., charts with low
  data volume, breakdowns capped at top-10, default date ranges that
  could be tuned)

Example handback:

```
✅ Dashboard created: [link]

What's on it:
  Overview — 2 charts
  Acquisition — 1 chart
  Retention — 1 chart

Worth knowing:
  • Cohort retention has small cohorts (<100 users/week) — numbers
    will be noisy
  • Acquisition breakdown capped at top 10 utm_sources
```

End the turn cleanly.

---

## Hard rules

- **Validate in one batch.** Per-chart validation = 8 round-trips. Do
  it once.
- **One confirmation gate.** Step 3 (inventory) is the gate. Don't ask
  again before building unless validation fails.
- **Sectioning above 4 charts.** A flat list of 8 charts is hard to
  read.
- **Soft cap, not hard cap.** Warn once at >8, then build what they ask.
- **Reuse `create-chart` references.** Don't duplicate the chart-type
  logic. Read the matching reference file at build time.
- **Render via the dashboard widget.** `Create-Dashboard` returns a
  rendered view — don't return JSON.

---

## Quick reference — MCP tools used

| Step | Tool |
|---|---|
| 1 | `Get-Projects`, `Get-Business-Context` |
| 4 | `Get-Events`, `Get-Properties`, `Get-Property-Values` |
| 5 | `Get-Query-Schema`, `Run-Query` (per chart), `Create-Dashboard` |
| 6 | `Get-Dashboard` (for the link / verification) |

For chart-type-specific schema and pitfalls, read the matching
reference file from `create-chart/references/`:
- Insights → `create-chart/references/insights.md`
- Funnels → `create-chart/references/funnels.md`
- Retention → `create-chart/references/retention.md`
- Flows → `create-chart/references/flows.md`

This skill has its own reference for **layout patterns** in
`references/layout-patterns.md`.

---

## When to escalate to a different skill

- If the customer wants to build a single chart → `create-chart`
- If the customer wants to review an existing dashboard → `analyze-dashboard`
- If the customer wants to clean up or template existing dashboards →
  `mixpanel-dashboard-manager`
- If a metric on the dashboard moved and they want to know why →
  `mxp-metric-diagnosis`
