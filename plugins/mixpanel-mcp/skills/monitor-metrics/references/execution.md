# Execution — shared setup and board handoff

Shared steps for `monitor-metrics`. Steps 0, 1, and 1.5 run for
`metric-anomaly` and `metric-drift` before any detection query. Steps 2 and 3
run after a command returns its payload. `metric-rca` does not re-run Steps 0,
1, or 1.5 — it consumes the diagnosis payload (see
`commands/metric-rca.md` prerequisites).

> **Connector & tools:** every action below is a `cap:*` capability key, not a
> tool name. Resolve each against the session tool map built in Step −1 (see
> `references/tools.md`), routed through the `mixpanel-mcp` connector (Mixpanel
> US region) only. If the map isn't built yet, build it first.

## Contents

- Step 0 — Input validation (anomaly and drift)
- Step 1 — Metric ingestion (anomaly and drift)
- Step 1.5 — Project profile resolution
- Step 2 — Post-diagnosis handoff (anomaly and drift)
- Step 3 — Post-RCA board append

---

## Step 0 — Input validation (anomaly and drift)

**Do not skip this step.** Before touching Step 1 or anything downstream,
confirm the user has given both a project and a metric. If either is
missing, ask once and wait.

### Step 0a — Resolve org/project context first

Before validating the project, call the `cap:business-context` tool
**once per session**. Pass `project_id` if the user already gave one;
otherwise call without it. This returns:

- Org-specific vocabulary (project nicknames, internal acronyms, product
  terms) that may resolve the user's request without needing `cap:list-projects`.
- Project-specific guidance on how that customer queries their data
  (relevant for any project with established conventions).

If business context resolves the project name → proceed directly to the
metric validation step. If not → fall through to `cap:list-projects`.

Skip this call only if the user's input is unambiguous (a numeric
`project_id` plus a clearly-named saved metric/report, with no project name
to interpret).

### Validate the project

| Situation | Action |
|---|---|
| User gave a `project_id` (int) | Call `cap:list-projects`, find the matching entry, and confirm the project **name** back to the user in one line: *"Running on project `<name>` (id: `<project_id>`) — confirm?"*. Wait for confirmation. |
| User gave a project **name** only | Call `cap:list-projects`, find the match. If one match, resolve the id and confirm back. If multiple matches or no match, list the candidates and ask the user to pick. |
| Neither given | Ask: *"Which Mixpanel project should I run this on? Share the project id, name, or a report/metric URL."* Do not guess from memory or past conversations. |

Store the resolved `project_id` and `project_name` on the metric series object.

### Validate the metric

Resolve in this priority order. **Saved Mixpanel Metrics are the preferred
input** — they carry a complete, machine-readable definition (see Step 1).

| Situation | Action |
|---|---|
| User named a metric, or said "metric" generically | Call `cap:find-metrics` with `project_id` and `query=<name>`. If one saved Metric matches, confirm the resolved name back to the user. If several match, list and ask. If none match, fall through to the other shapes below (saved report / prose). |
| User gave a metric **id** | Treat as a saved Metric. Confirm via `cap:get-metric` in Step 1. |
| User gave a report URL, `bookmark_id`, or dashboard URL | Resolve via the Step 1 input-shape table. Confirm the resolved metric name and one-sentence definition back to the user before firing queries. |
| User described the metric in prose | Still call `cap:find-metrics` once to check whether a saved Metric already captures it — reuse beats rebuild. If no match, confirm the prose definition back to the user in one sentence before firing queries. |
| Nothing given | Ask: *"Which metric are we diagnosing? Share a saved Metric name, a report URL, a bookmark id, or describe it in one line."* Do not assume from context. |

Only proceed once both project and metric are confirmed.

---

## Step 1 — Metric ingestion (anomaly and drift)

Resolve the metric into a single canonical form: a normalized **metric
series** object whose `query_template` is the `report` body each command
will replay at its own date windows.

There are two ways `query_template` gets built. **Prefer the first.**

### Path A — Saved Mixpanel Metric (preferred)

A saved Metric is the only input shape that returns its **full definition**
programmatically. Use it whenever Step 0 resolved a saved Metric.

1. Call `cap:get-metric` with `project_id` and `metric_id`.
2. The response carries the complete metric structure — events, formulas,
   filters, and aggregation. Lift this directly into `query_template`. You
   do **not** need to reconstruct it from prose, and you do **not** need
   `cap:query-schema` for a saved Metric — the definition is authoritative.
3. Confirm the resolved metric **name** and a one-line plain-English summary
   of what it measures back to the user before firing any time-series query.
4. Record `metric_id` on the series object so a board or RCA run can
   reference the source Metric.

### Path B — Saved report, dashboard tile, or prose (rebuild)

Used when there is no saved Metric. Here `query_template` must be **built
fresh** and confirmed with the user, because these shapes do not expose a
replayable query body.

> **Important:** A saved report doesn't give you a replayable query — treat it
> only as a starting point for confirming the metric definition, then rebuild
> every downstream `cap:run-query` fresh from the confirmed prose definition
> using `cap:query-schema`. This is the key contrast with Path A, where a saved
> Metric's definition *is* authoritative and can be replayed directly. (If a
> capability's response does expose a replayable body, prefer that over
> rebuilding — resolve by what the tool returns, not by its name.)

#### Input shape resolution (Path B)

| Input shape | How to recognize | How to resolve |
|---|---|---|
| **Saved report (with ID)** | A `bookmark_id` + `project_id`, or a report URL containing `/report/<project_id>/<bookmark_id>` | Fetch the report *including* its result data (not just metadata) via `cap:get-report`. From the metadata + native-granularity results, draft a one-sentence prose definition (event(s), measurement type, obvious filters). Confirm with the user. |
| **Dashboard tile (with URL or ID)** | A dashboard URL containing `/dashboards/<dashboard_id>` | Fetch the dashboard *with its layout* via `cap:get-dashboard`, find the matching report cell, then treat as saved report (above). |
| **Report/dashboard referenced by name only** | "the conversion tile on the funnel board" with no URL | Search saved entities by name via `cap:search-entities`, scoping to dashboards for boards or to report types (insights, funnels, retention, flows) for reports. One match → resolve. Multiple → list and ask. None → ask for the URL. |
| **Natural language** | User describes the metric in prose | Confirmation already done in Step 0. Proceed to query construction. |

#### Build the query body (Path B)

Once the metric definition is confirmed in prose:

1. Determine `report_type` (`insights`, `funnels`, `retention`, or `flows`).
2. Call `cap:query-schema` for that report type.
3. Construct the `report` body — events, measurement, filters, breakdowns —
   matching the prose definition. Do **not** copy from a saved report's raw
   response; build from the schema.

### Normalize to a "metric series" object internally

```
{
  project_id: int,
  project_name: str,             # resolved and confirmed in Step 0
  metric_id: int | null,         # set when source is a saved Metric (Path A)
  metric_name: str,              # human-readable label
  metric_definition: str,        # one-sentence what-it-measures (confirmed)
  report_type: str,              # insights | funnels | retention | flows
  query_template: dict,          # `report` body (from cap:get-metric or cap:query-schema)
  default_filters: list,         # filters baked into query_template, for RCA reference
  metric_type: str,              # classified per the metric_type table in SKILL.md
}
```

Classify `metric_type` per the table in **SKILL.md** and store it on this
object before either detection command fires queries. Every downstream step
operates on this object. Each command's Phase 1 overrides only `dateRange`
and `unit` (granularity) on `query_template`.

**Funnel and retention classification** is owned by each command's own
pre-flight (top of `commands/metric-anomaly.md` and `commands/metric-drift.md`),
not by Step 1. Step 1 is deliberately narrow: resolve the metric into a
normalized series object. Nothing more.

---

## Step 1.5 — Project profile resolution

Before writing any time-series query, resolve a minimal project profile.
This step is cheap (metadata calls only) and catches filter/instrumentation
problems before they contaminate the diagnosis.

### Filter resolution (cheap metadata calls, not probe queries)

For every filter referenced in `query_template` (billing/account filters,
exclusions, user-property filters, segment scopes):

1. **Confirm the property exists.** Via `cap:list-properties`, confirm the
   filter property exists on the relevant event or user resource (scoped to
   the specific event where the filter applies). If it doesn't resolve, stop
   and tell the user — the filter references a property that doesn't exist in
   this project.
2. **Confirm the filter value is real.** Via `cap:property-values`, fetch the
   property's distinct values (scoped to the relevant event for event
   properties). If the filter value isn't among them, stop and tell the
   user — the filter excludes everything because the value never appears.

Skip this for filters that came from a saved Metric definition (Path A) and
are already known-good — but still validate any filter the *user* added on
top of the saved Metric.

### Instrumentation health check

Call `cap:data-issues` once, scoped to the events used by `query_template`,
covering the window back to the earliest date the diagnosis will look at
(60 days back for drift, 30 days back for anomaly). If issues exist (type
drift, null spikes, schema changes) in that window:

- Capture issue summaries.
- Do **not** abort the diagnosis. Carry these forward to the verdict card
  under contamination — a separate signal from the statistical
  contamination check. The customer needs to know if instrumentation
  changed during the window even if the metric itself looks stable.

### Two-level breakdown truncation note

Two-level breakdowns can return truncated result sets on high-cardinality
dimensions. Treat any result that looks suspiciously round (e.g. exactly
1,000 / 3,000 / 10,000 rows and no tail) as potentially truncated and
confirm before relying on it. Mainly an RCA Branch 2 concern but applies
anywhere a two-level breakdown is run.

Store as `project_profile` for downstream use:
```
{
  filters_validated: list,           # filters confirmed to resolve
  instrumentation_issues: list,      # issues from cap:data-issues, may be empty
  truncation_warnings: list,         # populated by downstream branches
}
```

---

## Step 2 — Post-diagnosis handoff (anomaly and drift)

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
  metric_id: int | null,
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

This lives at skill level so a user running anomaly → drift back-to-back is
asked once at the end, not once per command.

Do not offer the prompt if either of these is true:
- The command aborted in error handling (no usable verdict).
- The metric is `retention` and the command was `metric-anomaly` (anomaly detection doesn't apply to retention — nothing to board).

### If the user says yes

Create a dashboard in the same `project_id`. Use `cap:create-board` directly
— this case (one board, N reports, one text card) is simple enough that
delegating to a dashboard-manager skill adds unnecessary indirection.

Build the rows as follows:

1. **Run each query in `queries[]` first** in register-only mode (no result
   payload) to get their `query_id`s back. Do this in parallel.
2. **Assemble the dashboard rows:**
   - Row 1: a single text cell rendering `verdict_card` as HTML, using the
     tags `cap:create-board` supports.
   - Row 2 onwards: one report cell per query in `queries[]`, named
     `<metric_name> — <window>, <granularity>` (matching the chart titles
     from Phase 3).
3. **Call `cap:create-board`** with `title=<metric_name> — <command>
   diagnosis (YYYY-MM-DD)`, the rows above, and the user's project_id.

`cap:create-board` advertises its own schema (allowed HTML tags, parameters)
— follow it rather than re-documenting it here.

Return the board URL to the user when done, and **store the resulting
`board_id` back onto the diagnosis payload as `diagnosis_board_id`** so a
subsequent `metric-rca` run can append to it.

For the **append** path at Step 3 (adding RCA findings to an existing
board), fetch the board with its layout via `cap:get-dashboard`, then
`cap:update-board` to add cells without disturbing the existing layout.

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

Fetch the board with its layout via `cap:get-dashboard`, then
`cap:update-board` to append. The content to add, in order:

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
