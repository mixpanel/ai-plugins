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

### Step 0a — Resolve org/project context first

Before validating the project, call `Mixpanel MCP:Get-Business-Context`
**once per session**. Pass `project_id` if the user already gave one;
otherwise call without it. This returns:

- Org-specific vocabulary (project nicknames, internal acronyms, product
  terms) that may resolve the user's request without needing `Get-Projects`.
- Project-specific guidance on how that customer queries their data
  (relevant for IGP, JioHotstar, Nykaa, CRED, etc. — any project with
  established conventions).

If business context resolves the project name → proceed directly to the
metric validation step. If not → fall through to `Get-Projects`.

Skip this call only if the user's input is unambiguous (a numeric
`project_id` plus a clearly-named saved report URL, with no project name
to interpret).

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

Resolve the metric into a single canonical form. All input shapes converge
on the same path: **confirm the definition with the user, then build a
fresh query body via `Get-Query-Schema` + `Run-Query`**.

> **Important:** `Get-Report` returns report metadata + results at the
> report's native granularity but **does not** return the underlying query
> definition. The skill cannot lift a saved report's query body and replay
> it at a different granularity. Saved reports are used only as a starting
> point for confirming the metric definition with the user — every
> downstream `Run-Query` is built fresh from the confirmed prose definition
> using `Get-Query-Schema`.

### Input shape resolution

| Input shape | How to recognize | How to resolve |
|---|---|---|
| **Saved report (with ID)** | User gives a `bookmark_id` + `project_id`, or a report URL containing `/report/<project_id>/<bookmark_id>` | Call `Get-Report` with `skip_results=false`. From the returned metadata + native-granularity results, draft a one-sentence prose definition (event(s), measurement type, any obvious filters from the report name). Confirm with the user. |
| **Dashboard tile (with URL or ID)** | User gives a dashboard URL containing `/dashboards/<dashboard_id>` | Call `Get-Dashboard` with `include_layout=true`, find the matching report cell in the layout, then treat as saved report (above). |
| **Dashboard or report referenced by name only** | User says "the conversion tile on the IGP funnel board" or "the Session Conversion Rate report" with no URL | Call `Search-Entities` with appropriate `entity_types` (`["dashboard"]` for boards, `["insights","funnels","retention","flows"]` for reports) and `query=<name>`. If one match, resolve and proceed. If multiple, list and ask. If no match, ask for the URL. |
| **Natural language** | User describes the metric in prose ("session conversion rate in JioHotstar prod") | Confirmation already done in Step 0. Skip directly to query construction. |

### Build the query body

Once the metric definition is confirmed (in prose), build the `Run-Query`
body from scratch:

1. Determine `report_type` (`insights`, `funnels`, `retention`, or `flows`)
   from the confirmed definition.
2. Call `Get-Query-Schema` for that report type.
3. Construct the `report` body — events, measurement, filters, breakdowns —
   matching the prose definition. Do **not** attempt to copy from a saved
   report's raw response; build from the schema.

This `report` body is the `query_template` used downstream. Each command's
Phase 1 overrides only `dateRange` and `unit` (granularity).

**Normalize to a "metric series" object internally:**
```
{
  project_id: int,
  project_name: str,             # resolved and confirmed in Step 0
  metric_name: str,              # human-readable label
  metric_definition: str,        # one-sentence what-it-measures (confirmed)
  report_type: str,              # insights | funnels | retention | flows
  query_template: dict,          # `report` body built via Get-Query-Schema
  default_filters: list,         # filters baked into query_template, for RCA reference
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

Before writing any time-series query, resolve a minimal project profile.
This step is cheap (metadata calls only) and catches filter/instrumentation
problems before they contaminate the diagnosis.

### Filter resolution (cheap metadata calls, not probe queries)

For every filter referenced in `query_template` (billing/account filters,
exclusions, user-property filters, segment scopes):

1. **Confirm the property exists.** Call `Get-Properties` with
   `property_names=[<filter_property>]` and `resource_type=<Event|User>`.
   If the property doesn't resolve, stop and tell the user — the filter is
   referencing a property that doesn't exist in this project.
2. **Confirm the filter value is real.** Call `Get-Property-Values` with
   the property name and (for event properties) the relevant event. If the
   filter value (e.g. `user_type = premium`) isn't in the returned distinct
   values, stop and tell the user — the filter excludes everything because
   the value never appears.

This replaces the prior "lightweight probe query" pattern. Metadata calls
are cheaper and produce a clearer error message ("filter value `premium`
doesn't exist in this property") than a probe query that returns zero
events ("metric returned 0 — could be filter, could be data quality, who
knows").

### Instrumentation health check

Call `Get-Issues` once, scoped to the events used by `query_template`
(`event_name=<event>` for each), with `since_date` set to the earliest
date the diagnosis will look at (60 days back for drift, 30 days back for
anomaly). If issues exist (type drift, null spikes, schema changes) in
that window:

- Capture issue summaries.
- Do **not** abort the diagnosis. Carry these forward to the verdict card
  under contamination — they're a separate signal from the statistical
  contamination check, and the customer needs to know if instrumentation
  changed during the window even if the metric itself looks stable.

### Two-level breakdown truncation note

Two-level breakdowns can return truncated result sets on high-cardinality
dimensions. Treat any result that looks suspiciously round (e.g. exactly
1,000 / 3,000 / 10,000 rows and no tail) as potentially truncated and
confirm before relying on it. This is mainly an RCA Branch 2 concern but
applies anywhere a two-level breakdown is run.

Store as `project_profile` for downstream use:
```
{
  filters_validated: list,           # filters confirmed to resolve
  instrumentation_issues: list,      # issues from Get-Issues, may be empty
  truncation_warnings: list,         # populated by downstream branches
}
```

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

Create a dashboard in the same `project_id`. Use `Create-Dashboard` directly
— this case (one board, N reports, one text card) is simple enough that
delegating to `mixpanel-dashboard-manager` adds an unnecessary indirection.

Build the rows as follows:

1. **Run each query in `queries[]` first** with `skip_results=true` to
   register them and get their `query_id`s back. Do this in parallel.
2. **Assemble the dashboard rows:**
   - Row 1: a single text cell containing `verdict_card` (HTML-formatted
     using `Create-Dashboard`'s allowed tags: `<h2>`, `<h3>`, `<p>`,
     `<strong>`, `<ul>`, `<li>`, `<br>`, etc. — no newlines, each element
     is a new line).
   - Row 2 onwards: one report cell per query in `queries[]`, named
     `<metric_name> — <window>, <granularity>` (matching the chart titles
     from Phase 3).
3. **Call `Create-Dashboard`** with `title=<metric_name> — <command>
   diagnosis (YYYY-MM-DD)`, the rows above, and the user's project_id.

Return the board URL to the user when done, and **store the resulting
`board_id` back onto the diagnosis payload as `diagnosis_board_id`** so a
subsequent `metric-rca` run can append to it.

For the **append** path at Step 3 (adding RCA findings to an existing
board), continue to delegate to `mixpanel-dashboard-manager` — that
genuinely needs `Get-Dashboard` (with `include_layout=true`) →
`Update-Dashboard` orchestration, and the dashboard-manager skill already
encapsulates that.

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
