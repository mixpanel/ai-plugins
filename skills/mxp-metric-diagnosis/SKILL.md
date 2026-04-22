---
name: mxp-metric-diagnosis
description: >
  Diagnose a Mixpanel metric for anomalies, drift, and root cause. Use
  whenever the user asks to investigate, debug, or explain a change in a
  Mixpanel metric — KPI, conversion rate, retention, event count, funnel
  step, or anything tracked in a saved report or dashboard. Trigger phrases:
  "what's going on with [metric]", "why did [metric] drop/spike", "diagnose
  this metric", "check for anomalies", "has [metric] drifted", "is this
  metric stable", "something looks off with [metric]", "did [metric] change
  last month", "what's driving the drop", "where is the movement coming
  from", "break this down", "run RCA on this metric". Also trigger when the
  user shares a Mixpanel report/dashboard link and asks what's happening, or
  when they describe a metric in natural language and want to know if the
  recent movement is real. Do NOT trigger for general portfolio health
  checks (use `weekly-pulse`) or adoption reports (use
  `gtm-customer-intelligence`). Requires Mixpanel MCP.
compatibility: "Requires Mixpanel MCP. Works for any project the user has access to."
---

# Mixpanel Metric Diagnosis

A focused diagnostic skill for a single metric at a time. Answers three
questions cleanly:

1. **Is a recent point weird?** (anomaly detection — `metric-anomaly`)
2. **Has the baseline itself shifted?** (drift detection — `metric-drift`)
3. **Where is the movement coming from?** (root-cause attribution —
   `metric-rca`)

Separation matters because the customer conversation is different for each:
an anomaly is an incident, drift is a trend, and RCA is the segmentation
story that makes either of the first two actionable.

`metric-rca` runs on top of an existing anomaly or drift diagnosis — it
consumes the diagnosis payload, fans out across segmentation branches, and
appends its findings to the diagnosis board. It does not perform detection
itself.

---

## Commands

This skill has three commands. Route to the right one based on the user's
ask.

### `metric-anomaly`
Detect point-in-time anomalies — recent spikes, drops, and clusters in a
single metric. Uses time-bucketed Z-score + IQR tests against 7-day hourly
and 30-day daily series. Produces flagged timestamps, classification
(isolated / cluster / edge), and a verdict. **Does not** test for
trend-level drift.

Trigger when the user wants to know *whether a specific point looks weird* —
"is this spike real?", "did something happen yesterday?", "is this a blip?".

→ See `commands/metric-anomaly.md`

### `metric-drift`
Detect trend-level drift — whether the baseline has shifted. Runs mean-shift
and variance-ratio tests on 60-day daily (last 30 vs prior 30) and 16-week
weekly (last 8 vs prior 8) windows. Includes a lightweight outlier
contamination check so it can run standalone without `metric-anomaly`
first. Produces direction, magnitude, shape (step/slope/oscillating), and
a verdict. **Does not** flag individual point anomalies.

Trigger when the user wants to know *whether the trend has changed* —
"has this drifted?", "is the baseline different now?", "what's happened over
the last month?".

→ See `commands/metric-drift.md`

### `metric-rca`
Root-cause attribution on top of an existing anomaly or drift diagnosis.
Fans out across five branches — component decomposition, default-property
breakdowns, distinct-id outliers, cohort comparison (stubbed), and
calendar/market context — over the same date windows the source command
used. Ranks findings by concentration and deviation, renders charts for
the important ones, and appends results to the diagnosis board.

Trigger when the user wants to know *where the movement came from* —
"what's driving this drop?", "where is the spike concentrated?", "break
this down", "run RCA", "is it a specific segment?". Requires a prior
`metric-anomaly` or `metric-drift` run in the same session.

→ See `commands/metric-rca.md`

---

## Choosing between the commands

- **Ambiguous or exploratory ask** ("something looks off") → default to
  `metric-anomaly` first. Anomaly is cheaper (2 queries) and catches
  point-in-time issues that would contaminate a drift test.
- **"Has this changed over the last month?"** → `metric-drift` directly.
- **Both detection questions matter** → run `metric-anomaly` first, then
  `metric-drift`. Drift will pick up any anomaly context if present and
  downgrade confidence accordingly.
- **User asks "why" or "where" after seeing a verdict** → `metric-rca`.
- **User opens with "why did X drop"** → run `metric-anomaly` or
  `metric-drift` first (whichever fits their framing better), then flow
  into `metric-rca`. Do not run RCA cold — it needs the detection payload.

---

## Step 0 — Input validation (both commands)

**Do not skip this step.** Before touching Step 1 or anything downstream,
confirm the user has given both a project and a metric. If either is
missing, ask once and wait.

### Validate the project

| Situation | Action |
|---|---|
| User gave a `project_id` (int) | Call `Mixpanel MCP:Get-Projects`, find the matching entry, and confirm the project **name** back to the user in one line: *"Running on project `<name>` (id: `<project_id>`) — confirm?"*. Wait for confirmation. |
| User gave a project **name** only | Call `Mixpanel MCP:Get-Projects`, find the match. If one match, resolve the id and confirm back. If multiple matches or no match, list the candidates and ask the user to pick. |
| Neither given | Ask: *"Which Mixpanel project should I run this on? Share the project id, name, or a report URL."* Do not guess from memory or past conversations. |

Store the resolved `project_id` and `project_name` on the metric series object.

### Validate the metric

| Situation | Action |
|---|---|
| User gave a report URL, `bookmark_id`, or dashboard URL | Resolve via the input-shape table below. Confirm the resolved metric name and one-sentence definition back to the user before firing queries. |
| User described the metric in prose | Confirm the metric definition back to the user in one sentence before firing queries. |
| Neither given | Ask: *"Which metric are we diagnosing? Share a report URL, a bookmark id, or describe it in one line."* Do not assume from context. |

Only proceed once both project and metric are confirmed.

---

## Step 1 — Metric ingestion (both commands)

Resolve the metric into a single canonical form. Accept three input shapes
and auto-detect:

| Input shape | How to recognize | How to resolve |
|---|---|---|
| **Saved report** | User gives a `bookmark_id` + `project_id`, or a Mixpanel report URL containing `/report/<project_id>/<bookmark_id>` | Call `Get-Report` with `skip_results=false` to pull the definition. Re-run via `Run-Query` at the granularities the command needs. |
| **Dashboard reference** | User gives a dashboard URL or says "the [metric name] tile on [dashboard]" | Call `Get-Dashboard` with `include_layout=true`, find the matching report in the layout, then treat as saved report. |
| **Natural language** | User describes the metric in prose ("session conversion rate in JioHotstar prod") | Build the query from scratch via `Run-Query`. The metric definition must have been confirmed back to the user in Step 0. |

**Normalize to a "metric series" object internally:**
```
{
  project_id: int,
  project_name: str,             # resolved and confirmed in Step 0
  metric_name: str,              # human-readable label
  metric_definition: str,        # one-sentence what-it-measures
  query_template: dict,          # reusable query body for Run-Query
  default_filters: dict,         # any filters baked into the saved report
}
```

Every downstream step operates on this object. No forking logic based on
input shape.

**Funnel and retention classification** is owned by each command's own
pre-flight (top of `commands/metric-anomaly.md` and `commands/metric-drift.md`),
not by Step 1. Step 1 here is deliberately narrow: resolve the metric into
a normalized series object. Nothing more.

---

## Step 1.5 — Project profile resolution

Before writing any query, resolve a minimal project profile:

- **Billing / account filter** — if the metric definition in the saved report includes a billing or account filter, note its exact property name and resource type (event vs user property) from `Get-Report`. Do not invent a filter name; use what the saved definition declares.
- **Exclusions** — same treatment for any internal-user or email exclusions baked into the saved report.
- **User-property filters** — if the metric definition includes user-property filters, verify they resolve before running full queries by running one lightweight probe with the filter applied.
- **Two-level breakdown truncation** — two-level breakdowns can return truncated result sets on high-cardinality dimensions. Treat any result that looks suspiciously round (e.g. exactly 1,000 / 3,000 / 10,000 rows and no tail) as potentially truncated and confirm before relying on it.

Store as `project_profile` for downstream use.

---

## Output contract

Both commands produce a structured verdict, not a data dump. The commands
define their own output formats; common principles:

- **Default to compact.** A CSA scanning between calls needs a verdict in under 60 seconds. Full detail is opt-in.
- **Always chart the trend.** Both commands always render inline charts — whether anomalies/drift were detected or not. A stable metric gets the same charts; the visual confirmation of stability is just as valuable as flagging a problem. Annotation overlays (anomaly dots, drift window shading, change-point markers) only appear when something was flagged.
- **Fixed section order.** Headline → confidence → next step. Never lead with a hedge.
- **Explicit scope limits.** Every output names what it did *not* do ("this does not test for drift — run `metric-drift`"; "this does not flag individual anomalies — run `metric-anomaly`").

Never output a wall of tables or raw query results. The CSA is the audience,
and the goal is a verdict they can act on.

---

## Step 2 — Post-diagnosis handoff (both commands)

At the end of Phase 3, each command hands back a structured **diagnosis
payload** to the skill-level flow. The skill then offers the user a board,
and caches the payload in conversation memory for a future `metric-rca`
command.

### The diagnosis payload

Both commands return the same shape:

```
{
  command: "metric-anomaly" | "metric-drift",
  project_id: int,
  project_name: str,
  metric_name: str,
  metric_definition: str,
  metric_type: str,
  queries: [
    { label: str, window: str, granularity: str, run_query_body: dict, result: dict },
    ...
  ],
  verdict_card: str,       # the full rendered card from Phase 3
  headline: str,           # one-line summary from the card
  flags: dict              # command-specific (flagged points for anomaly; level_delta / var_ratio / shape for drift)
}
```

This payload is held in conversation memory only — do not write to disk.
It survives for the session and is what `metric-rca` consumes when
invoked. If the user later creates a board (below), the resulting
`board_id` is attached to the payload as `diagnosis_board_id` so
`metric-rca` knows where to append.

### The board prompt

After rendering the Phase 3 charts + verdict card, ask the user **exactly
once**:

> *"Want me to save this as a board in Mixpanel?"*

Do not offer the prompt if either of these is true:
- The command aborted in error handling (no usable verdict).
- The metric is `retention` and the command was `metric-anomaly` (was skipped to drift — nothing to board).

### If the user says yes

Create a dashboard in the same `project_id` and populate it with:

1. **One saved report per query in `queries[]`** — use the `run_query_body`
   from each. Name them `<metric_name> — <window>, <granularity>` (matches
   the chart titles from Phase 3 so the board reads the same as the output
   the user just saw).
2. **One text card** containing `verdict_card` verbatim. Place it at the
   top of the dashboard layout so it reads before the reports.

Board naming: `<metric_name> — <command> diagnosis (YYYY-MM-DD)`.

Use the `mixpanel-dashboard-manager` skill for the create mechanics — do not
reinvent the board-creation plumbing here. Return the board URL to the user
when done, and **store the resulting `board_id` back onto the diagnosis
payload as `diagnosis_board_id`** so a subsequent `metric-rca` run can
append to it.

### If the user says no

Do nothing. The payload is already in conversation memory; `metric-rca`
will pick it up when invoked later in the session.

---

## Step 3 — Post-RCA board append

Runs after `metric-rca` returns its payload (see `commands/metric-rca.md`
Phase 2). The RCA payload carries `important_findings`, `findings_card`,
and `rca_queries` — Step 3's job is to append these to the existing
diagnosis board without creating a new one.

### Append target

Read `diagnosis_board_id` from the source payload (the anomaly/drift
payload that RCA consumed).

- **If present** → append to that board. This is the default path.
- **If null** (the user declined the board earlier) → do not create a
  board silently. Return the findings card + charts inline and tell the
  user: *"No diagnosis board was created earlier, so I'm not appending
  anywhere. Want me to create a board now with the diagnosis + RCA
  findings together?"* If they say yes, follow Step 2's board-creation
  path first, then run Step 3 against the new board.

### What to append

Delegate to `mixpanel-dashboard-manager` for the append mechanics. The
content to add, in order:

1. **One text card** containing `findings_card` verbatim. Place it
   beneath the existing Phase 3 verdict card (visual continuity: diagnosis
   first, then attribution).
2. **One saved report per important finding** — use `chart_spec` +
   `run_query_body` from the RCA payload's `rca_queries`. Name each
   `<metric_name> — RCA: <segment description>` so the board reads as a
   story: headline → verdict → findings → per-segment charts.

Cap appended reports at 6 (matches the RCA findings cap). If there are
zero important findings, append only the text card — the "no single
segment concentrates the movement" result is still worth boarding.

### Do not offer a second prompt

RCA's append to an existing board is automatic — do not ask *"should I
append?"*. The user already opted into the board at Step 2. The only ask
at Step 3 is the fallback above, when no board exists yet.

Return the updated board URL when done.

---

## When not to use this skill

- **Portfolio-wide sweeps** → use `weekly-pulse`.
- **Full adoption story / QBR prep** → use `gtm-customer-intelligence`.
- **Lexicon / instrumentation health** → use `mixpanel-governor-tool`.
- **Metric definition help** ("how should I measure X?") → answer directly, no skill needed.
- **Root-cause investigation from scratch, without a prior diagnosis** →
  run `metric-anomaly` or `metric-drift` first, then `metric-rca`. RCA
  does not run cold.

This skill is deliberately narrow: one metric, one diagnosis, one
attribution pass.

---

## Files

- `commands/metric-anomaly.md` — point-in-time anomaly detection (Z-score + IQR, time-bucketed; 2 queries; 7-day hourly + 30-day daily views)
- `commands/metric-drift.md` — trend-level drift detection (mean shift + variance ratio; 2 queries; 60-day daily + 16-week weekly views; owns shape classification)
- `commands/metric-rca.md` — root-cause attribution (5-branch segmentation fan-out on same windows as source command; ranks findings by concentration × deviation; appends to the diagnosis board)
