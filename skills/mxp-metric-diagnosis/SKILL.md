---
name: mxp-metric-diagnosis
description: >
  Diagnose a Mixpanel metric for anomalies, drift, and root cause. Use whenever
  the user asks to investigate, diagnose, debug, or explain a change in a
  Mixpanel metric — KPI, conversion rate, retention, event count, funnel step,
  or anything tracked in a saved report or dashboard. Trigger phrases:
  "what's going on with [metric]", "why did [metric] drop/spike", "diagnose
  this metric", "analyse this metric", "is this an anomaly", "has [metric]
  drifted", "run RCA on [metric]", "check [metric] for anomalies", "something
  looks off with [metric]". Also trigger when the user shares a Mixpanel
  report/dashboard link and asks what's happening, or when they describe a
  metric in natural language and want to know if the recent movement is real.
  Do NOT trigger for general portfolio health checks (use `weekly-pulse`) or
  adoption reports (use `gtm-customer-intelligence`). Requires Mixpanel MCP.
compatibility: "Requires Mixpanel MCP. Works for any project the user has access to."
---

# Mixpanel Metric Diagnosis

A focused diagnostic skill for a single metric at a time. Answers two questions
cleanly before attempting a third:

1. **Is a recent point weird?** (anomaly detection)
2. **Has the baseline itself shifted?** (drift detection)
3. **Why?** (root cause analysis — separate command)

Separation matters because the customer conversation is different for each:
an anomaly is an incident, drift is a trend, and RCA is the investigation that
follows either.

---

## Commands

This skill has two commands. Route to the right one based on the user's ask.

### `analyse-metric`
Run anomaly detection and drift detection against a single metric.
Produces flagged timestamps, drift magnitude/direction/shape, and a clean
verdict. **Does not** attempt root cause.

Trigger when the user wants to know *whether* something happened —
"is this real?", "is this a blip?", "has this metric drifted?".

→ See `commands/analyse-metric.md`

### `metric-rca`
Full root cause walk against a metric that `analyse-metric` has already
flagged. **Never runs cold** — requires the `rca-context` handoff block
from a prior `analyse-metric` run in the same conversation.

Trigger when the user wants to know *why* — "why did this drop?",
"what caused this?", "run RCA on this".

Structure:
- **Step 1** — metric selection (only if multiple metrics flagged)
- **Step 2** — pre-flight resolution (silent): project profile, metric
  type classification, ingestion-source classifier (`$import` × `mp_lib`),
  library-scoped property resolver, user-level data probe
- **Step 3** — mode selection (Quick ~5–8 queries vs Deep ~25–40 queries
  on cross-platform customers), with pre-flight signal surfaced so the
  user picks with context
- **Step 4 onward** — Branches 0–6 of the RCA tree (see command file)

→ See `commands/metric-rca.md`

**If the user's ask is ambiguous**, default to `analyse-metric` first.
RCA on a metric that hasn't drifted wastes queries chasing noise.
If the user invokes `metric-rca` without a prior `analyse-metric` run,
route them back — don't run cold.

---

## Step 0 — Metric Ingestion (both commands)

Before either command runs, resolve the metric into a single canonical form.
Accept three input shapes and auto-detect:

| Input shape | How to recognize | How to resolve |
|---|---|---|
| **Saved report** | User gives a `bookmark_id` + `project_id`, or a Mixpanel report URL containing `/report/<project_id>/<bookmark_id>` | Call `Get-Report` with `skip_results=false` to pull the definition. Re-run via `Run-Query` at the granularities the command needs. |
| **Dashboard reference** | User gives a dashboard URL or says "the [metric name] tile on [dashboard]" | Call `Get-Dashboard` with `include_layout=true`, find the matching report in the layout, then treat as saved report. |
| **Natural language** | User describes the metric in prose ("session conversion rate in JioHotstar prod") | Ask for `project_id` if not provided. Build the query from scratch via `Run-Query`. Confirm the metric definition back to the user in one sentence before firing queries. |

**Normalize to a "metric series" object internally:**
```
{
  project_id: int,
  metric_name: str,              # human-readable label
  metric_definition: str,        # one-sentence what-it-measures
  query_template: dict,          # reusable query body for Run-Query
  default_filters: dict,         # any filters baked into the saved report
}
```

Every downstream step operates on this object. No forking logic based on
input shape.

**Funnel and retention classification** is owned by each command's own
pre-flight, not by Step 0:
- `analyse-metric` classifies the metric type in its own **Prerequisites**
  section (top of `commands/analyse-metric.md`), because Phase A/B have
  funnel- and retention-specific branches.
- `metric-rca` reads `metric_type` from the handoff block and falls back
  to classification in its **Step 2.2** when the handoff says `unknown`.

Step 0 here is deliberately narrow: resolve the metric into a normalized
series object. Nothing more.

---

## Step 0.5 — Project profile resolution

Before writing any query, resolve a minimal project profile:

- **Billing / account filter** — if the metric definition in the saved report includes a billing or account filter, note its exact property name and resource type (event vs user property) from `Get-Report`. Do not invent a filter name; use what the saved definition declares.
- **Exclusions** — same treatment for any internal-user or email exclusions baked into the saved report.
- **User-property filters** — if the metric definition includes user-property filters, verify they resolve before running full queries by running one lightweight probe with the filter applied.
- **Two-level breakdown truncation** — two-level breakdowns can return truncated result sets on high-cardinality dimensions. Treat any result that looks suspiciously round (e.g. exactly 1,000 / 3,000 / 10,000 rows and no tail) as potentially truncated and confirm before relying on it.

Store as `project_profile` for downstream branches to read.

---

## Output contract

Both commands produce a structured verdict, not a data dump. The commands
define their own output formats; common principles:

- **Default to compact.** A CSA scanning between calls needs a verdict in under 60 seconds. Full detail is opt-in.
- **Always chart the trend.** `analyse-metric` always renders an inline trend chart — whether anomalies/drift were detected or not. A stable metric gets the same 60-day line with drift-window shading and mean lines; the visual confirmation of stability is just as valuable as flagging a problem. Anomaly dots and drift annotations overlay only when something was flagged.
- **Fixed section order.** Headline → confidence → next step. Never lead with a hedge.
- **Explicit scope limits.** Every output names what it did *not* do ("this does not attribute cause — run `metric-rca`").

Never output a wall of tables or raw query results. The CSA is the audience,
and the goal is a verdict they can act on.

### Cross-command handoff: the `rca-context` block

When `analyse-metric` flags an anomaly or drift, it emits a fenced
markdown block with language tag `rca-context` at the end of its output.
This block is the **sole input contract** for `metric-rca` — the RCA
command parses it instead of re-eliciting project_id, metric definition,
or drift/baseline windows.

The block is emitted **only when something was flagged**. For a stable
metric, no block is emitted and RCA should not be offered.

Full schema and field sourcing rules live in `commands/analyse-metric.md`
under "Handoff block for `metric-rca`". Parse spec lives in
`commands/metric-rca.md` under "Handoff contract".

---

## When not to use this skill

- **Portfolio-wide sweeps** → use `weekly-pulse`.
- **Full adoption story / QBR prep** → use `gtm-customer-intelligence`.
- **Lexicon / instrumentation health** → use `mixpanel-governor-tool`.
- **Metric definition help** ("how should I measure X?") → answer directly, no skill needed.

This skill is deliberately narrow: one metric, one diagnosis.

---

## Files

- `commands/analyse-metric.md` — anomaly + drift detection workflow (emits `rca-context` handoff block; owns shape classification)
- `commands/metric-rca.md` — root cause decomposition workflow — routing file for the full tree
- `commands/metric-rca/preflight.md` — Step 2 pre-flight (five resolution tasks) + master `rca_context` schema (single source of truth for branch output shapes)
- `commands/metric-rca/branch-0-dq.md` — Branch 0 data quality gate
- `commands/metric-rca/branch-1-dimensional.md` — Branch 1 dimensional decomposition
- `commands/metric-rca/branch-2-structural.md` — Branch 2 structural decomposition (ratio / funnel / retention)
- `commands/metric-rca/branch-3-cohort.md` — Branch 3 cohort decomposition (new/existing, tenure, retention carve-out)
- `commands/metric-rca/branch-4-temporal.md` — Branch 4 temporal pattern (interpretation only — does not re-classify shape)
- `commands/metric-rca/branch-5-correlated.md` — Branch 5 correlated event scan (Deep mode only)
- `commands/metric-rca/branch-6-disclosure.md` — Branch 6 external factor disclosure
- `commands/metric-rca/synthesis.md` — Step 11 synthesis (headline ladder, chart, confidence)
