---
name: analyze-dashboard
description: >
  Read and summarize a Mixpanel dashboard end-to-end. Use whenever the
  user wants to review, summarize, walk through, or get the takeaway
  from a Mixpanel dashboard, board, or collection of reports. Trigger
  phrases: "review this dashboard", "summarize this board", "what's
  happening on this dashboard", "walk me through this", "give me the
  takeaway", "anything I should know about this board", "explain
  what's on this dashboard", "review my exec dashboard", "what's the
  story on this board". Also trigger when the user pastes a Mixpanel
  dashboard URL and asks anything about it. Produces a synthesis-first
  summary (one screen of takeaways) with a per-chart appendix. Flags
  obvious health issues (broken charts, no data, stale config) but
  does not audit hygiene — for full cleanup use
  `mixpanel-dashboard-manager`. Do NOT trigger for reviewing a single
  chart (use `analyze-chart`), RCA on a metric (use
  `mxp-metric-diagnosis`), or building dashboards (use
  `create-dashboard`). Requires Mixpanel MCP.
compatibility: "Requires Mixpanel MCP. Works for any project the user has access to."
---

# Mixpanel Analyze Dashboard

Read a Mixpanel dashboard end-to-end and produce a one-screen synthesis
of what it's saying. The customer didn't ask for 8 separate analyses —
they asked "what's happening on this dashboard." The job is to find the
narrative across the charts and surface it cleanly.

This skill **reuses `analyze-chart` logic** for individual chart reads,
but the headline output is synthesis, not chart-by-chart commentary.
The per-chart detail goes in an appendix that the customer can expand
if they want to dig deeper.

---

## When this skill runs, it does five things in order

1. **Locate the dashboard** — by URL, ID, or NL search
2. **Inventory the charts** — pull metadata for every chart on the board
3. **Run each chart** — re-fetch fresh data; flag broken / empty charts
4. **Read each chart, then synthesize** — find the cross-chart narrative
5. **Output: synthesis + concerns + appendix**

---

## Step 1 — Locate the dashboard

Three input modes, same as `analyze-chart`:

### Mode A — URL or dashboard ID

Mixpanel dashboard URLs include a board ID (e.g.,
`/view/<board_id>/`). Extract the ID and call `Get-Dashboard` with
`include_layout=True` to pull the full dashboard structure including
cell/row IDs and chart configurations.

If the URL/ID can't be resolved, surface the failure and ask for a
working reference.

### Mode B — Natural language

If the customer says "my exec dashboard" or "the launch board," use
`Search-Entities` with `entity_types=['dashboard']`. Show top 3 matches
with names and last-modified dates, ask which one.

### Mode C — Build first, then analyze

If the customer asks to build a dashboard and analyze it in the same
turn, run `create-dashboard` first, then return here with the new
board ID. Treat as one workflow.

---

## Step 2 — Inventory the charts

From `Get-Dashboard` with `include_layout=True`, extract:

- Total chart count
- Each chart's ID, title, type (Insights / Funnel / Retention / Flow),
  configuration (events, properties, filters, date range)
- Section structure (rows / cells / text headers)

If the dashboard has more than ~12 charts, surface this once before
proceeding:

> *"This dashboard has [N] charts — the synthesis will focus on the
> headline movements, not every chart. Per-chart detail will be in the
> appendix."*

This is a customer expectation-setting move, not a request to skip
charts. Read all of them.

---

## Step 3 — Run each chart

Call `Run-Query` for each chart with its saved configuration. Track
three states per chart:

- **Healthy** — query returned data
- **Empty** — query succeeded but returned zero data
- **Broken** — query failed (timeout, schema error, permission error,
  event/property no longer exists)

Empty and broken charts go into the "Concerns" section of the output,
not the synthesis. They cannot inform the narrative — they ARE the
narrative when present.

For light health flagging:
- Chart with date range hardcoded to old period (e.g., a chart showing
  "Q4 2024" still rendering in 2026) → flag as stale config
- Chart with event that returns zero rows for the date range → flag as
  potentially-broken instrumentation
- Chart with a property no longer in the project → flag as broken

Do not audit further. Stale charts and config drift are
`mixpanel-dashboard-manager`'s territory.

---

## Step 4 — Read each chart, then synthesize

### Per-chart read

For each healthy chart, run the analysis pattern from `analyze-chart`:
read the shape, identify movement direction, magnitude, anomalies. Use
the matching reference from `analyze-chart/references/`:

- Insights → `analyze-chart/references/read-insights.md`
- Funnels → `analyze-chart/references/read-funnels.md`
- Retention → `analyze-chart/references/read-retention.md`
- Flows → `analyze-chart/references/read-flows.md`

Capture per-chart: current value, direction, magnitude, anomalies (if
any). Keep these short — they go into the appendix and feed the
synthesis.

### Synthesis

This is the headline output. The synthesis answers: **across all the
charts together, what's the story?**

For synthesis patterns and how to construct the narrative, read
`references/synthesis-patterns.md`.

The high-level rules:

- **Lead with movement, not stability.** A dashboard where 7 of 8
  charts are flat and 1 dropped 30% — the synthesis is about the 30%
  drop, not the 7 flat ones.
- **Group related findings.** If acquisition, signups, and DAU all
  dropped together, that's *one* finding (volume drop), not three.
- **Cross-chart contradictions are headline material.** "Acquisition is
  up but DAU is flat" is a sharper finding than either alone.
- **Don't summarize chart by chart.** That's the appendix's job.

If the dashboard genuinely has nothing notable — everything is flat,
no anomalies, no surprises — the synthesis says so plainly:

> *"The dashboard is steady — nothing material moved this period."*

That's a valid finding. Don't manufacture drama.

---

## Step 5 — Output

Always this shape, in this order:

```
**The story**
[2–4 sentences. The cross-chart narrative. What moved, what's
notable, the one thing the customer should walk away with.]

**Worth your attention**
[Bullet list — only items that meet the bar:
- Big movements (>15% change in either direction)
- Cross-chart contradictions
- Anomalies that look like a single trigger event
- Health issues (broken charts, empty data, stale config)
Skip if there's nothing in this category.]

**Want to dig in?**
[Offer one or both, depending on what's in 'Worth your attention':
- "Run mxp-metric-diagnosis on [specific metric] to find what's
  driving the movement"
- "Open the per-chart appendix below"]

---

**Per-chart appendix**

[For each chart on the dashboard, in dashboard order, one line:
- Chart title — current value, direction, magnitude, any flags
Example:
- DAU (Insights) — 142K, down 9% WoW, step-change on Mar 18
- Signup → Activation funnel — 47% conversion, flat WoW
- Weekly retention — Period-1 retention 31%, flat across cohorts]
```

The appendix is always included but visually de-prioritized — the
customer reads "The story" first, scans "Worth your attention," and
only opens the appendix if they want detail.

For dashboards with broken or empty charts, list those in the
appendix with the issue inline:

```
- Checkout funnel — ❌ event 'Order Placed' no longer exists in project
- Daily errors — ⚠️ zero data for date range — instrumentation may be off
```

---

## Hard rules

- **Synthesis first, charts second.** The customer reads the
  synthesis. The appendix is reference material.
- **Don't summarize chart-by-chart in the headline.** That's lazy
  output and defeats the purpose of synthesizing.
- **Group related findings.** If three charts tell the same story,
  it's one finding.
- **Hand off "why" questions.** If the customer's follow-up is "why
  did X drop," route to `mxp-metric-diagnosis`. Don't RCA inline.
- **Don't audit the dashboard.** Flag broken/empty/stale charts, then
  stop. Hygiene = `mixpanel-dashboard-manager`.
- **Re-run the queries.** Don't trust cached chart state.
- **No speculation about external causes.** Stick to what the data
  shows.

---

## Quick reference — MCP tools used

| Step | Tool |
|---|---|
| 1 | `Get-Dashboard` (URL/ID), `Search-Entities` (NL search) |
| 1, Mode C | hands off to `create-dashboard`, comes back with dashboard ID |
| 2 | `Get-Dashboard` with `include_layout=True` |
| 3 | `Run-Query` (per chart) |
| 4 | (no new tool calls — analysis on data already pulled) |

For chart-type-specific reading patterns, reuse:
- `analyze-chart/references/read-insights.md`
- `analyze-chart/references/read-funnels.md`
- `analyze-chart/references/read-retention.md`
- `analyze-chart/references/read-flows.md`

For synthesis patterns specific to dashboard-level analysis, see
`references/synthesis-patterns.md`.

---

## When to escalate to a different skill

- Customer asks "why" on a specific metric → `mxp-metric-diagnosis`
- Customer wants to clean up the dashboard → `mixpanel-dashboard-manager`
- Customer wants to add or remove charts → `create-chart` or
  `create-dashboard`
- Customer wants to deep-dive one specific chart → `analyze-chart`
