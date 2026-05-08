---
name: analyze-chart
description: >
  Read and explain a Mixpanel chart — what it shows, what's notable,
  and what's worth a closer look. Use whenever the user asks to
  interpret, explain, summarize, review, or break down an existing
  chart, report, or saved query in Mixpanel. Trigger phrases:
  "what does this chart show", "explain this report", "interpret this
  chart", "summarize this for me", "what's notable here", "anything
  weird in this chart", "tell me what's happening", "review this
  insight", "walk me through this report", "what's the takeaway from
  this". Also trigger when the user pastes a Mixpanel chart URL and
  asks anything about it. Lean by default — surfaces what the chart
  shows and flags notable patterns. If the user asks WHY something
  moved, hand off to `mxp-metric-diagnosis` for deeper root-cause
  analysis. Do NOT trigger for building new charts (use `create-chart`),
  reviewing entire dashboards (use `analyze-dashboard`), or full
  diagnostic workflows (use `mxp-metric-diagnosis`). Requires Mixpanel MCP.
compatibility: "Requires Mixpanel MCP. Works for any project the user has access to."
---

# Mixpanel Analyze Chart

Take a Mixpanel chart that already exists (or just got built) and turn
it into a one-screen summary the customer can act on. The skill is
**lean by default** — it explains what the chart shows and flags what's
notable, but does not chase root causes unless the customer asks.

If the customer's follow-up is "why is this happening" or anything
similar, hand off to `mxp-metric-diagnosis`. That skill is built for
multi-branch RCA; this one is built for fast interpretation.

---

## When this skill runs, it does four things in order

1. **Locate the chart** — by URL, ID, or fresh build
2. **Pull the data** — re-run the query and parse the result
3. **Read the shape** — trend, anomalies, breakdown distribution
4. **Summarize for the customer** — what it shows, what's notable, what to do next

---

## Step 1 — Locate the chart

Three input modes. Detect which one applies from the customer's message:

### Mode A — Customer provides a URL or chart/report ID

Most common. Mixpanel chart URLs look like
`https://mixpanel.com/project/<project_id>/view/<board_id>/app/<chart>`
or include `report_id=<id>`. Extract the ID(s).

Use the relevant Mixpanel MCP tool to fetch the chart's metadata and
configuration — this gives you the events, properties, filters,
breakdowns, date range, and chart type without having to ask the
customer.

If you can't resolve the URL/ID (404, permission error, malformed URL),
say so plainly and ask if they meant a different chart.

### Mode B — Customer describes the chart in natural language

If the customer says "the DAU chart on my exec board" or "the funnel I
built last week," they're pointing at an existing chart but haven't
given an ID. Use `Search-Entities` with `entity_types=['report']` to
find candidates. Show the top 3 matches with their titles and dates,
ask which one.

If `Search-Entities` returns nothing useful, escalate to Mode C:

> *"I can't find that chart. Want to build it fresh and analyze that?"*

### Mode C — Customer wants to analyze a chart that doesn't exist yet

Run `create-chart` first to build the chart, then come back to Step 2
and analyze the result. This is a clean composition — `create-chart`
returns a `query_id` and a rendered widget; this skill picks up from
there.

If the customer asks for both in one turn ("build me a DAU chart and
tell me what it shows"), do them as one workflow: build → analyze →
present together.

---

## Step 2 — Pull the data

For Mode A or B (existing chart), call `Run-Query` with the same
configuration as the saved chart to get fresh data. Don't trust cached
chart state — the customer may not have refreshed in days.

For Mode C, you already have the `query_id` from the just-built chart.

In both cases, you need:
- The query result data (time series, breakdown values, etc.)
- The chart configuration (events, properties, filters, date range,
  chart type)

Without configuration metadata, the analysis is shallow ("the line
goes up") instead of grounded ("checkout volume rose 18% WoW, isolated
to the iOS platform").

---

## Step 3 — Read the shape

What to look for depends on chart type. Read the matching reference:

- Insights → `references/read-insights.md`
- Funnels → `references/read-funnels.md`
- Retention → `references/read-retention.md`
- Flows → `references/read-flows.md`

The references hold the **specific patterns** to look for in each
chart type. The high-level rules across all types:

### What to surface (always)

- **The current value** — what the metric is right now
- **Direction and magnitude of change** — is it up/down/flat, by how
  much, vs. when
- **The biggest contributor** — if there's a breakdown, which segment
  drives the volume

### What to flag (only if present)

- **Step-change anomalies** — a single point that breaks the pattern
- **Sustained drift** — the baseline has shifted (last 30 days look
  different from prior 30 days)
- **Suspicious-looking segments** — one segment doing all the work, or
  a segment that suddenly disappeared
- **Data quality cues** — a sudden jump that aligns with a deploy, an
  event going to zero (looks like instrumentation broke)

### What NOT to do

- **Don't chase root cause.** If you spot a drop, flag it and stop.
  Root-cause attribution is `mxp-metric-diagnosis`'s job.
- **Don't speculate about external causes.** Saying "this might be
  because of holiday traffic" without evidence is hallucination.
- **Don't recommend fixes.** The customer didn't ask for fixes. They
  asked what the chart shows.

---

## Step 4 — Summarize for the customer

Output structure (always this shape, length scales with content):

```
**What this shows**
[1–2 sentences: chart subject, time window, current value]

**The shape**
[1–3 sentences: trend direction, magnitude, key inflection points]

**Worth noting**
[Bullet list — only items that meet the "flag" bar above. Skip if
nothing notable.]

**Want to dig in?**
[Offer to either: (a) escalate to mxp-metric-diagnosis if movement
needs explanation, OR (b) modify the chart via create-chart if a
different cut would help]
```

Example output for a DAU chart that dipped:

```
**What this shows**
Daily Active Users over the last 30 days. Currently at 142K DAU.

**The shape**
Flat through most of the month, with a clear step-down on March 18th
— DAU dropped from ~150K to ~135K and hasn't recovered. The post-drop
baseline is roughly 9% below the pre-drop average.

**Worth noting**
- The drop is a step-change, not a gradual decline — typical of a
  deploy, instrumentation change, or external event.
- Weekend dips are still present at the same magnitude — the issue
  isn't a day-of-week shift.

**Want to dig in?**
The shape suggests a single trigger event around March 18th. Want me
to run `mxp-metric-diagnosis` to find the segments driving the drop?
```

Keep it tight. A customer reading this on a phone needs to get the
takeaway in the first paragraph.

---

## Hybrid scope — when to escalate

Lean by default means: surface what's there, stop. Escalate when the
customer asks any of:

- "Why did this drop / spike / change?"
- "What's causing this?"
- "Where is it coming from?"
- "Is it specific users / regions / platforms?"

In any of those cases, do not attempt the analysis here. Hand off:

> *"That's a root-cause question — `mxp-metric-diagnosis` is built for
> that. Want me to run it on this metric?"*

Do not silently expand the analysis. The customer-facing version of
this skill should not do RCA inline because RCA can be many tool calls
deep, and an unbounded "why" question turns a 30-second summary into a
10-minute investigation. Better to make the handoff explicit.

---

## Hard rules

- **Always re-run the query.** Don't trust cached chart state.
- **Configuration metadata grounds the analysis.** Without knowing the
  events/filters, you can't tell the customer what they're looking at.
- **Flag, don't diagnose.** Drift detection ≠ root cause.
- **One screen of output.** Long analyses lose the customer.
- **Hand off "why" questions.** Don't try to RCA inline.
- **No speculation about external causes.** Stick to what the data
  shows.

---

## Quick reference — MCP tools used

| Step | Tool |
|---|---|
| 1 | `Get-Report` (for URL/ID), `Search-Entities` (for NL search) |
| 1, Mode C | hands off to `create-chart`, comes back with `query_id` |
| 2 | `Run-Query` |
| 3 | (no new tool calls — pure analysis on the data already pulled) |
| 4 | (output to user) |

For chart-type-specific reading patterns, see `references/`.

---

## When to escalate to a different skill

- Customer asks "why" → `mxp-metric-diagnosis`
- Customer wants to modify the chart → `create-chart`
- Customer wants to analyze the whole dashboard → `analyze-dashboard`
- Customer wants to clean up old charts → `mixpanel-dashboard-manager`
