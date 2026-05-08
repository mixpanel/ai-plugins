# Command: metric-rca

Root-cause investigation for a flagged metric. Takes the diagnosis payload
from a prior `metric-anomaly` or `metric-drift` run and fans out across a
set of segmentation branches to localise *where* the movement concentrated.
Produces a ranked list of findings and appends them to the diagnosis board
the user already created.

This command does **not** re-run anomaly or drift detection. It assumes the
movement has already been established — its job is attribution, not
detection.

---

## Prerequisites

Before this command runs, the session must hold a **diagnosis payload** in
conversation memory from an earlier `metric-anomaly` or `metric-drift` run
(see `SKILL.md` Step 2). The payload carries the project, metric, metric
type, date ranges, flagged points or drift windows, and the query bodies
used.

If no payload exists, do **not** attempt to run RCA from a cold start. Tell
the user: *"RCA runs on top of an existing anomaly or drift diagnosis. Run
`metric-anomaly` or `metric-drift` first, then come back here."* Stop.

### Board state

If the user persisted the diagnosis as a Mixpanel board (Step 2 in
`SKILL.md`), the payload will include `diagnosis_board_id`. This command
**appends** to that board — it does not create a new one. If no board was
created, skip the append step at the end and just return the findings
inline; do not silently create a new board.

### Ask once — business / market context

Before firing Branch 5, ask the user exactly once:

> *"What business or market is this metric tied to? (e.g., Indian
> e-commerce, Indian OTT streaming, SEA fintech.) I'll use this to check
> whether the flagged dates line up with festivals, launches, or
> category-specific events."*

Hold the answer as `business_context`. If the user skips or says "not
relevant", skip Branch 5 entirely — do not guess the market from project
name or memory.

---

## Phase 1 — Branch selection + parallel fan-out

Read the payload and decide which branches to run. Every branch runs
against the **same date ranges** the source command used:

- `metric-anomaly` payload → use 7-day hourly + 30-day daily windows.
- `metric-drift` payload → use 60-day daily + 16-week weekly windows, with
  recent vs prior window comparison preserved.

If both payloads exist in the session (user ran anomaly then drift),
prefer the drift payload's date ranges — RCA over a longer window is more
useful — and annotate findings with the anomaly payload's flagged
timestamps for cross-reference.

### Branch selection matrix

| Branch | Purpose | Runs when |
|---|---|---|
| **Branch 1 — Component decomposition** | Break ratio/funnel/retention into its component events + metric-definition filters | `metric_type ∈ {ratio, funnel, retention}` |
| **Branch 2 — Default-property breakdowns** | Source → geography → client-specific split | Always |
| **Branch 3 — Distinct-ID outliers** | Find whether a small set of users drove the movement | Anomaly payload only. Skip if in-window distinct user count >10k |
| **Branch 4 — Cohort comparison** | Run the metric filtered to top-N project cohorts to find concentration in named user segments | Always (skipped only if project has zero cohorts) |
| **Branch 5 — Calendar context** | Check whether flagged dates line up with festivals, launches, category events in `business_context` | `business_context` provided |

Run all selected branches **in parallel** via concurrent `Run-Query` calls.
Each branch can issue multiple queries; batch within a branch sequentially
if one query's result informs the next (Branch 2's second level depends
on the first).

---

## Branch 1 — Component decomposition

Only runs for `ratio`, `funnel`, and `retention` metrics. The question:
*is the movement in the numerator, the denominator, or a specific step?*

### For `ratio`
1. Pull numerator event as a standalone count series (same window,
   granularity, and filters from the metric definition).
2. Pull denominator event as a standalone count series (same window,
   granularity, and filters).
3. Compare each component's deviation % against the ratio's overall
   deviation %. Flag which component moved.
4. If both components moved in the same direction by similar magnitude →
   the ratio is stable but volumes shifted. Note as a volume story, not a
   conversion story.
5. If only one moved, or they moved opposite directions → the ratio
   shift is concentration-driven. Identify which.

### For `funnel`
1. Run the **same funnel definition** twice as `report_type=funnels` via
   `Run-Query`: once for the recent (drift/anomaly) window, once for the
   baseline window. The native funnels response returns step conversion
   rates and absolute counts per step.
2. For each step pair, compute the conversion-rate delta between recent
   and baseline.
3. Flag the **specific step pair** with the largest absolute conversion
   drop. One step usually owns the drop; surface that pair as the
   headline finding.
4. If the funnel has step-level filters (e.g. property filters on
   individual steps), do not decompose into standalone event counts —
   the filters change the meaning. The native funnels query is the only
   faithful comparison.

This replaces the prior "pull each funnel step as a standalone event
count" approach. Standalone event counts ignore step ordering and
step-level filters; the native funnels report does not.

### For `retention`
1. Pull the cohort-defining event as a standalone count series.
2. Pull the return event as a standalone count series.
3. Check whether cohort size changed, return count changed, or both.
4. A drop in retention with stable return count + larger cohort is a mix
   effect; a drop in return count with stable cohort is real attrition.

### Event × metric-definition filter combinations

For every component event above, re-run it with **each filter from the
metric definition applied independently** (i.e. one filter at a time, not
all combinations — combinatorial blowup is not useful here). This shows
whether a specific filter value concentrates the movement.

Example: if the metric definition has `user_type = premium` baked in,
and the numerator event is `video_play`, run:
- `video_play` with no filter
- `video_play` with `user_type = premium` (the baked filter) — this
  should match the metric's numerator
- `video_play` broken down **by** `user_type` (all values) — exposes
  whether the movement is specific to `premium` or shared across the
  population.

Cap at 5 filter values per property breakdown; drop the long tail.

---

## Branch 2 — Default-property breakdowns

Two-level cascade. Always runs.

### Level 1 — Source segmentation

Break down the metric by the SDK / ingestion source. Two properties
together:

- Event property `mp_lib` (string) — SDK name (e.g. `web`, `android`,
  `iphone`, `swift`, `python`, `ruby`, `java`).
- Event property `$import` (boolean) — true for events ingested via the
  Import API, false for Track API.

Output: a matrix of `mp_lib × $import` with deviation % per cell. The
goal here is to isolate whether the movement is concentrated in
client-side vs server-side vs Import API ingestion.

### Level 2 — Conditional breakdowns

The Level 2 slice depends on what Level 1 surfaced. Run the slice whose
dominant source owns the movement; skip the others.

**For client-side sources (`web`, `android`, `iphone`, `swift`, etc.):**
Common first slice — geography in a step function:
- Event property `$os`
- Event property `platform` (or the project's equivalent; check the
  metric definition or fall back to `mp_lib` if not present)
- Event property `mp_country_code`
- Event property `$region`
- Event property `$city`

Run these as a **step function**, not a cross-product: start with
`mp_country_code`. If one country owns >50% of the movement, break that
country down by `$region`. If one region owns >50%, break by `$city`.
Stop when the concentration flattens.

**For `web` specifically:**
- Event property `$device`
- Event property `utm_source`
- Event property `$browser`

**For `android` / `iphone` / `swift` / `ios`:**
- Event property `$app_version_string`
- Event property `$model`

Run these as single-property breakdowns, not two-level (avoids the
3k cardinality truncation risk in Project 1297132 and similar).

### Cardinality discipline

- Any breakdown returning exactly 1,000 / 3,000 / 10,000 rows is
  potentially truncated — flag in findings, do not treat the result as
  exhaustive.
- If a two-level breakdown (`mp_lib × $import`) is used, keep the
  first-level cardinality bounded: if `mp_lib` returns >20 distinct
  values, filter to the top 10 by volume before running the second
  level.

---

## Branch 3 — Distinct-ID outliers

Only runs for anomaly payloads. Goal: is a small set of users
responsible for the flagged point(s)?

### Cardinality gate

Before running, check in-window distinct user count against the metric's
base query. If >10,000 distinct users contributed to the metric in the
flagged window, skip this branch and note "Branch 3 skipped — user
cardinality too high for outlier detection via MCP." A top-N breakdown
on 100k users returns noise.

### If within cardinality

1. Break the metric down by `distinct_id` for the flagged window only
   (not the whole series — this keeps the query tractable).
2. Rank users by their contribution to the metric in the flagged window.
3. Flag outliers: users whose contribution in the flagged window is
   >5σ above the median user's contribution, OR users who appear in
   the flagged window but not in the baseline window.
4. Cap output at the top 20 distinct_ids by deviation.

If the top 5 users account for >30% of the movement → strong user-driven
outlier signal. Surface this prominently. Could be bots, internal test
traffic, or a single high-volume customer.

### Optional follow-up — session replay context

If the top 3 distinct_ids each account for ≥10% of the movement individually,
offer the user a follow-up: *"Top user(s) `<distinct_id>` drove [X]% of the
flagged window. Want me to pull their session replays from that window so
you can see what they did?"*

If the user says yes, call `Get-User-Replays-Data` for each flagged
distinct_id with `from_date` and `to_date` set to the flagged window. Cap at
3 distinct_ids and 5 replays per user. Surface the replay URLs + timestamps
in the findings card under the Branch 3 section.

This is **opt-in only** — do not pull replays automatically. Replays add
value when the customer wants the "what did they actually do" answer, but
they're noisy if Session Replay isn't widely enabled in the project. Ask
once, run if confirmed, skip if declined.

---

## Branch 4 — Cohort comparison

Goal: is the movement concentrated in a specific user cohort the customer
already cares about? Cohorts are typically the most CSA-actionable RCA
signal — "your churn-risk cohort dropped 40%" is a far better headline than
"users on iOS 17.4 dropped 40%."

### Step 1 — Discover cohorts in the project

Call `Search-Entities` with `entity_types=["cohort"]` and `limit=25`,
`sort_by="popularity"`. This returns the cohorts defined in the project
with their names and IDs.

If the project has zero cohorts → record *"Branch 4 skipped — no cohorts
defined in this project."* and continue.

### Step 2 — Pick which cohorts to compare against

Cap at the **top 5 cohorts** by relevance. Selection rules in priority
order:

1. If the user mentioned cohort names in their original ask (e.g. "is
   this happening in our power users?"), match those by name first.
2. Otherwise, take the top 5 most-popular cohorts from `Search-Entities`
   (popularity reflects how often the customer actually uses them — a
   reasonable proxy for "cohorts the customer cares about").
3. If the project has fewer than 5 cohorts, use all of them.

Surface the cohort names in the findings — the customer recognizes their
own cohort names and that's part of the value.

### Step 3 — Run the metric filtered by each cohort

For each selected cohort, run the same `query_template` as the headline
metric, with one cohort-membership filter added. The exact filter shape
comes from `Get-Query-Schema` — Mixpanel's query schema accepts cohort
membership as a filter on `distinct_id` referencing the cohort_id.

Run all cohort queries in parallel via concurrent `Run-Query` calls. Each
query covers the same date window the source command used (drift window
or anomaly window).

### Step 4 — Score and rank

For each cohort, compute the same concentration + deviation scores used
in the Phase 2 ranking step (cohort_delta_abs / total_delta_abs and the
cohort's own deviation %). Treat cohorts as candidate findings the same
way property breakdowns are treated.

A cohort is **important** if either:
- It explains ≥30% of the headline movement (lower threshold than the
  default 40% — cohorts are smaller slices than top-level properties,
  and 30% concentration in a named cohort is a strong signal), OR
- Its individual deviation is ≥1.5× the headline metric's deviation.

### Error handling

| Situation | Response |
|---|---|
| `Search-Entities` returns zero cohorts | Skip branch, record reason. |
| A cohort filter fails in `Run-Query` (cohort schema mismatch) | Retry once. If still failing, skip that cohort, continue others, note in branch coverage. |
| All cohort queries fail | Skip branch, note "Branch 4 skipped — cohort filtering failed across all cohorts." |

---

## Branch 5 — Calendar context

Only runs if the user provided `business_context`.

1. Identify the key dates in the flagged window. For anomaly payloads,
   use the timestamps from `payload.flags.hourly` and `payload.flags.daily`.
   For drift payloads, use the change-point date if `shape = step`, or
   the start of the drift window otherwise.
2. Run a `web_search` with a query built from `business_context` + the
   relevant date(s). Example: if `business_context = "Indian e-commerce"`
   and the change-point is `2026-03-08`, search `"Indian e-commerce
   events March 8 2026 festival sale"`.
3. Look for matches: religious festivals, cricket fixtures, sale events
   (BBD, EOSS, GOSF), product launches, regulatory dates (e.g. RBI policy
   announcements).
4. If a plausible match surfaces, include it in findings with a
   confidence label: `strong` (exact date match, major event), `moderate`
   (same week, category-aligned), `weak` (same month, tangential).
5. If nothing surfaces, record: *"No calendar events found for
   `<business_context>` on the flagged dates."*

This branch is **context**, not **evidence**. Phrase findings as "the
flagged date falls on [event]" — never as "the [event] caused the
movement." Correlation only; causation belongs to the customer.

---

## Phase 2 — Synthesise, rank, visualise

### Rank findings

For every branch, each sub-segment (a `mp_lib` value, a country, a funnel
step, a distinct_id, etc.) is a candidate finding. Score each:

- **Concentration score** — share of the total movement this segment
  explains. `segment_delta_abs / total_delta_abs`. A segment with 70%
  concentration is worth surfacing; 5% is not.
- **Deviation score** — this segment's deviation % compared to its own
  baseline. A segment that individually deviated 40% is stronger signal
  than one that deviated 5%.

Flag a finding as **"important"** if **either** of these is true:
- Concentration score ≥ 0.4 (one segment owns ≥40% of the movement), OR
- Segment deviation ≥ 1.5× the headline metric's deviation (the movement
  concentrates here).

Cap total important findings at 6. If more than 6 qualify, keep the top 6
by concentration × deviation combined rank.

### Visualise important findings

Render a single visualizer widget containing one chart per important
finding, stacked vertically. Chart type by branch:

| Branch | Chart |
|---|---|
| Branch 1 (component) | Two-line overlay: headline metric vs component metric, same window, same granularity |
| Branch 2 (property breakdown) | Horizontal bar chart, one bar per segment, bar length = deviation %, color-coded by direction |
| Branch 3 (distinct_id) | Horizontal bar chart, top-N users by contribution % in flagged window |
| Branch 4 (cohort) | Horizontal bar chart, one bar per important cohort, bar length = deviation %, color-coded by direction |
| Branch 5 (calendar) | No chart — rendered as an annotation in the written findings block |

Before generating, read `visualize:read_me` with `modules: ["chart"]`
once if not already loaded this session. Do not narrate the read_me call.

### The findings card

```
METRIC: <metric_name> — <project_id>
DIAGNOSIS SOURCE: <metric-anomaly | metric-drift | both>
WINDOW: <window described in the same language as the source verdict card>

━━ HEADLINE ━━
<one sentence naming the strongest finding, or "No single segment concentrates the movement — treat as distributed.">

━━ IMPORTANT FINDINGS (ranked) ━━
1. [Branch N] <segment description> — <concentration %> of movement,
   <deviation %> vs baseline. <one-line interpretation>.
2. ...
(cap 6; omit section if no important findings)

━━ BRANCH COVERAGE ━━
Branch 1 (component):        <ran | skipped — reason>
Branch 2 (default props):    <ran | skipped — reason>
Branch 3 (distinct_id):      <ran | skipped — reason>
Branch 4 (cohort):           <ran + N cohorts compared | skipped — no cohorts in project>
Branch 5 (calendar):         <ran + N events found | skipped — no business context>

━━ WHAT THIS ISN'T ━━
This is attribution by segmentation, not causal analysis. Findings show
where the movement concentrated; they do not prove what caused it.
Calendar matches are correlation only.
```

### The RCA payload (passed back to SKILL.md)

After rendering the findings card + charts, hand back to the skill-level
flow:

```
{
  command: "metric-rca",
  project_id, project_name,
  metric_name, metric_definition, metric_type,
  source_payload_command: "metric-anomaly" | "metric-drift",
  business_context: <string or null>,
  rca_queries: [
    { branch: int, label: str, run_query_body: dict, result: dict }, ...
  ],
  important_findings: [
    { branch: int, segment: str, concentration_pct: float,
      deviation_pct: float, interpretation: str,
      chart_spec: dict },
    ... (cap 6)
  ],
  findings_card: <full rendered card above>,
  headline: <the HEADLINE line>,
  diagnosis_board_id: <from source payload, or null>
}
```

The skill-level flow (Step 3 in `SKILL.md`, added with this command)
handles the board append.

---

## Error handling

| Situation | Response |
|---|---|
| No diagnosis payload in session | Stop. Tell user to run `metric-anomaly` or `metric-drift` first. |
| A branch query fails | Retry once. If still failing, mark that branch partial, continue others, note in branch coverage. |
| All branches fail | Stop. Report failure and ask the user to verify project access. |
| Branch 2 Level 1 returns only one `mp_lib × $import` cell with meaningful volume | Skip Branch 2 Level 2 conditional logic; run the fallback geography step function directly. |
| User declines to provide `business_context` | Skip Branch 5 entirely, proceed with others. |
| No important findings after ranking (all segments <40% concentration and <1.5× deviation) | Surface that finding: "Movement is distributed across segments — no single dimension concentrates it." This is a valid, useful result. |

---

## What this command deliberately doesn't do

- **Does not re-run anomaly or drift detection.** It consumes the payload.
- **Does not claim causation.** Correlation by segmentation is the ceiling.
- **Does not cross-join properties combinatorially.** Branch 2 is a
  step-function cascade, not a cross-product, because high-cardinality
  two-level breakdowns truncate silently.
- **Does not source calendar dates from memory.** Always `web_search`
  with the user-provided `business_context`.
- **Does not create a new board.** Appends to the existing diagnosis
  board via the skill-level flow.

Keep the surface narrow. A ranked list of 3-6 concentrated segments with
charts beats a 40-branch exhaustive report every time.
