---
name: analyze-report
description: >
  Read and explain a Mixpanel report or chart — what it shows, what's
  notable, and what's worth a closer look. Use whenever the user asks to
  interpret, explain, summarize, review, or break down an existing
  chart, report, or saved query in Mixpanel. Trigger phrases:
  "what does this chart show", "explain this report", "interpret this
  chart", "summarize this for me", "what's notable here", "anything
  weird in this chart", "tell me what's happening", "review this
  insight", "walk me through this report", "what's the takeaway from
  this". Also trigger when the user pastes a Mixpanel chart or report
  URL and asks anything about it. Lean by default — surfaces what the
  report shows and flags notable patterns, but does not chase root
  causes. Do NOT trigger for building new charts, reviewing entire
  dashboards, or full root-cause diagnostic workflows (for "why did
  this change" questions, use monitor-metrics). Requires Mixpanel MCP (EU).
compatibility: "Requires Mixpanel MCP (EU). Works for any EU data-residency project the user has access to."
---

# Mixpanel Analyze Report

Take a Mixpanel report or chart that already exists (or just got built)
and turn it into a one-screen summary the customer can act on. The skill
is **lean by default** — it explains what the report shows and flags
what's notable, but does not chase root causes unless the customer asks.

This skill is built for fast interpretation: flag what you see and stop.
The boundary — when a "why" question turns this into a root-cause
investigation — is defined in "Hybrid scope — when to stop" below.

---

## When this skill runs, it does four things in order

1. **Locate the report** — by URL, ID, or fresh build
2. **Pull the data** — re-run the query and parse the result
3. **Read the shape** — trend, anomalies, breakdown distribution
4. **Summarize for the customer** — what it shows, what's notable, what to do next

---

## Step 1 — Locate the report

Three input modes. Detect which one applies from the customer's message:

### Mode A — Customer provides a URL or chart/report ID

Most common. Mixpanel report URLs look like
`https://eu.mixpanel.com/project/<project_id>/view/<board_id>/app/<chart>`
or include `report_id=<id>`. Extract the ID(s).

Fetch the report's saved configuration — the events, properties,
filters, breakdowns, date range, and chart type — so you can ground the
analysis without asking the customer to re-explain what they built.

If you can't resolve the URL/ID (404, permission error, malformed URL),
say so plainly and ask if they meant a different report.

### Mode B — Customer describes the report in natural language

If the customer says "the DAU chart on my exec board" or "the funnel I
built last week," they're pointing at an existing report but haven't
given an ID. Search saved reports for candidates, show the top 3 matches
with their titles and dates, and ask which one they mean.

If nothing useful comes back, escalate to Mode C:

> *"I can't find that report. Want to build it fresh and analyze that?"*

### Mode C — Customer wants to analyze a report that doesn't exist yet

The report has to be built before it can be analyzed. Build the chart
first (or ask the customer to point you at the configuration they want),
then come back to Step 2 and analyze the result. Once the chart is
built you have a fresh result and a rendered widget; this skill picks
up from there.

If the customer asks for both in one turn ("build me a DAU chart and
tell me what it shows"), do them as one workflow: build → analyze →
present together.

---

## Step 2 — Pull the data

For Mode A or B (existing report), re-run the report against its saved
configuration to get fresh data. Don't trust cached chart state — the
customer may not have refreshed in days.

For Mode C, the chart was just built, so its result is already current —
analyze that.

In all cases, you need:
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

- **Don't chase root cause here.** Flag movement and stop — see
  "Hybrid scope — when to stop".
- **Don't speculate about external causes.** "This might be holiday
  traffic" without evidence is hallucination.
- **Don't recommend fixes.** The customer asked what the report shows,
  not how to fix it.

---

## Step 4 — Summarize for the customer

Output structure (always this shape, length scales with content):

```
**What this shows**
[1–2 sentences: report subject, time window, current value]

**The shape**
[1–3 sentences: trend direction, magnitude, key inflection points]

**Worth noting**
[Bullet list — only items that meet the "flag" bar above. Skip if
nothing notable.]

**Want to dig in?**
[Offer to either: (a) investigate why the movement happened, OR
(b) recut the report with a different breakdown, filter, or date range
if that would help]
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
to dig into which segments are driving the drop?
```

Keep it tight. A customer reading this on a phone needs to get the
takeaway in the first paragraph.

---

## Hybrid scope — when to stop

Lean by default means: surface what's there, stop. The boundary is the
"why" question. If the customer asks any of:

- "Why did this drop / spike / change?"
- "What's causing this?"
- "Where is it coming from?"
- "Is it specific users / regions / platforms?"

…that's a root-cause investigation, which is a deeper, multi-step
workflow. Don't try to answer it inline here. Flag what the data shows
and offer the deeper dig as an explicit next step:

> *"That's a root-cause question — it can take a few cuts to answer
> properly. Want me to dig into the segments driving this?"*

Do not silently expand the analysis. An unbounded "why" question turns
a 30-second summary into a 10-minute investigation. Better to make the
boundary explicit and let the customer opt in.

---

## Hard rules

- **Always re-run the query.** Don't trust cached chart state.
- **Configuration metadata grounds the analysis.** Without knowing the
  events/filters, you can't tell the customer what they're looking at.
- **One screen of output.** Long analyses lose the customer.
- **No speculation about external causes.** Stick to what the data
  shows.

For chart-type-specific reading patterns, see the matching file in
`references/`.

---

## When to stop and redirect

- Customer wants to modify or rebuild the chart → that's a build task,
  out of scope for interpretation
- Customer wants to analyze the whole dashboard → out of scope; this
  skill reads a single report
- Customer wants to clean up or manage old charts → out of scope
