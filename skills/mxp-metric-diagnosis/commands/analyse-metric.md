# Command: analyse-metric

Run anomaly detection and drift detection against a single metric, in sequence.
Produces a verdict on *whether* something has happened. Does **not** attempt
root cause — that's `metric-rca`.

---

## Prerequisites

Before this command runs, Step 0 from `SKILL.md` must have produced the
normalized metric series object. If it hasn't, do that first.

If the user's input is a saved report but the metric is a **funnel** or
**retention** report, see the "Special cases" section at the bottom.

### Prerequisite — classify `metric_type`

Before firing any queries, classify the metric into one of:
`count`, `unique_count`, `ratio`, `funnel`, `retention`, `unknown`.

| Detected | Classification |
|---|---|
| Report type `funnels` | `funnel` |
| Report type `retention` | `retention` |
| Query template has A/B form or `% of total` (conversion rate, session rate, etc.) | `ratio` |
| Single-series count (event count, event count distinct users) | `count` |
| Single-series unique count | `unique_count` |
| Formula metric / custom SQL / anything else | `unknown` |

Store as `metric_type` on the metric series object. Used in:
- Phase A/B special cases (funnel, retention branches below)
- The `rca-context` handoff block emitted after Phase C

`metric-rca` will re-classify if `metric_type = unknown` (its Step 2.2
has the fallback), but `analyse-metric` should classify here so the
compact-card output can note metric type and the handoff block is
populated.

### Prerequisite — name the drift and baseline windows

Phase B's daily test uses two 30-day windows. The naming convention for
downstream use (compact card, handoff block, `metric-rca`):

- **`drift_window`** — the **recent** 30 days of Phase B's daily view (most recent 30 days ending today).
- **`baseline_window`** — the **prior** 30 days (30 days ending 30 days before today).

Both windows are computed in B1 regardless; just make sure the command
uses these names in all output (compact card, full card, handoff block).

Phase B's weekly test uses 8 vs 8 weeks — those windows are reported in
full mode only and don't flow into the handoff block (`metric-rca` uses
the daily windows as its drift/baseline reference).

---

## Execution order

**Strict sequence: anomaly detection first, drift detection second.**

Anomaly goes first because anomalies are point-in-time and their presence
changes how the drift test should be read — if the last 3 days have a blowout
anomaly, the "last 30 days vs prior 30 days" drift test will be contaminated
by those points. The drift output must note when this contamination is likely.

Do **not** run them in parallel in this skill. If the user asks for speed,
offer `metric-rca`'s "quick mode" instead (a future addition).

---

## Phase A — Anomaly Detection

### A1. Fetch series (2 queries, parallel)

Fire both `Run-Query` calls simultaneously:

| Query | Window | Granularity | Purpose |
|---|---|---|---|
| A1-hourly | Last 7 days | `hour` | Recent-blip detection |
| A1-daily | Last 30 days | `day` | Recent-day detection against a fuller baseline |

Use the `query_template` from the metric object; override only the date range
and granularity. Do not re-apply filters — they're already baked in.

Build the `Run-Query` body from `query_template` with only `date_range` and `granularity` overridden. Use `timeComparison` when a single call can cover both windows.

### A2. Compute expected ranges

For each series independently, compute the expected range at every timestamp.
Two methods, run both and use whichever flags more conservatively (more flags
= noisier; pick the one with fewer flags when they disagree):

**Method 1 — Z-score against time-bucketed mean:**

- For the **hourly** series: group all points by hour-of-day (0–23) and day-of-week (7 × 24 = 168 buckets). Compute mean (μ) and stddev (σ) per bucket across the 7-day window. Flag any point where `|value - μ| / σ > 2.5`.
- For the **daily** series: group by day-of-week (7 buckets). Compute μ and σ across the 30-day window. Flag any point where `|value - μ| / σ > 2.5`.
- Handle low-variance buckets: if σ is <5% of μ, skip the Z-score for that bucket and fall back to Method 2 only (division by tiny σ creates false alarms).

**Method 2 — IQR against time-bucketed median:**

- Same bucketing scheme as Method 1.
- For each bucket, compute Q1, median, Q3, and IQR = Q3 − Q1.
- Flag any point where `value < Q1 − 1.5 × IQR` or `value > Q3 + 1.5 × IQR`.

**Deviation magnitude** (for every flagged point): report `(value − median) / median`
as a signed percentage. This is what the CSA actually cares about, not the Z-score itself.

### A3. Distinguish anomaly types

For each flagged timestamp, classify:

- **Isolated spike/drop** — one point flagged, neighbors normal. Most likely a real anomaly (outage, release, data gap).
- **Cluster** — 2+ consecutive points flagged in the same direction. Could be a short incident *or* the leading edge of drift. Flag as ambiguous and note in output.
- **Edge-of-window cluster** — flagged points are the most recent N points. Strongly suggestive of drift, not anomaly. Downgrade confidence that this is an "anomaly" per se and let the drift phase confirm.

### A4. Anomaly verdict

Produce, at most, a short list of flagged events. Each entry:

```
- <timestamp>  <value>  (deviation: <+/-X%> vs median, <+/-Zσ>)  [type: isolated | cluster | edge]
```

Cap the list at 10 entries. If there are more, summarize: "18 anomalies flagged
in the last 7 days — the metric is either undergoing a regime shift or the
baseline model is wrong. Recommend running drift detection before treating
any single point as actionable."

If **no** anomalies are flagged, say so cleanly: "No anomalies in the last 7
days or 30 days." Do not pad with what you checked.

---

## Phase B — Drift Detection

### B1. Fetch series (2 queries, parallel)

| Query | Window | Granularity | Comparison |
|---|---|---|---|
| B1-daily | Last 60 days | `day` | Last 30 days vs. prior 30 days |
| B1-weekly | Last 16 weeks | `week` | Last 8 weeks vs. prior 8 weeks |

The 60-day daily view catches medium-term drift. The 16-week weekly view
catches slow drift that the daily window would miss because daily noise
drowns the signal. Running both is cheap and they answer different questions.

### B2. Window split & contamination check

For each series, split into `recent` and `prior` halves (no overlap).
Before running tests, check against the anomaly results from Phase A:

- If ≥20% of points in the `recent` window were flagged as anomalies in A2 → flag **"drift test contaminated — recent window contains anomalies"** and mark all drift findings as low-confidence.
- If anomalies were concentrated on specific days and those days can be excluded without dropping >20% of points → compute drift both with and without them, report both.

### B3. Drift test battery

Run two tests per series. Both run on the aggregate daily series
returned by `Run-Query` — no per-user data required.

**Test 1 — Mean shift (level drift):**

```
mean_recent  = mean(recent_window)
mean_prior   = mean(prior_window)
level_delta  = (mean_recent − mean_prior) / mean_prior    # signed %
```

Flag thresholds:
- `|level_delta| < 5%` → no meaningful shift
- `5% ≤ |level_delta| < 15%` → moderate drift
- `|level_delta| ≥ 15%` → significant drift

Additionally compute a Welch's t-test on the two windows. If p < 0.05 and
level_delta ≥ 5%, drift is statistically supported. If p ≥ 0.05, note the
shift is observational but not statistically distinguishable from noise.

**Test 2 — Variance ratio (volatility drift):**

```
var_ratio = variance(recent_window) / variance(prior_window)
```

Flag thresholds:
- `0.67 ≤ var_ratio ≤ 1.5` → variance stable
- `var_ratio > 1.5` → metric got noisier (investigate instrumentation, cohort mix)
- `var_ratio < 0.67` → metric got smoother (often a sign of a flatlining or saturation)

Variance drift without level drift is an under-appreciated signal — the
headline number looks fine but something structural changed. Always surface
it separately.

Distribution-shape tests (KS, PSI) are intentionally **not** part of this
battery. They require per-user or per-segment values, which Mixpanel's
MCP surface does not return at practical cost. Compositional / mix-shift
detection happens later in `metric-rca` Branch 1 via the Simpson's
paradox check on segment-level breakdowns, which is the feasible
substitute.

### B4. Drift verdict

Combine the two tests into one of five verdicts per series:

| Verdict | When |
|---|---|
| **No drift** | Level stable, variance stable, shape stable (or unknown) |
| **Level drift** | Level shifted ≥5%, variance/shape stable |
| **Variance drift** | Level stable, variance ratio outside 0.67–1.5 |
| **Shape drift** | Level stable, variance stable, KS/PSI flags |
| **Compound drift** | Two or more of the above |

Also report **direction** (up / down) and **magnitude** (% for level, ratio for variance, PSI value for shape).

### B5. Reconcile the two series

The 60-day-daily and 16-week-weekly views should agree on direction. If they
disagree:

- Weekly says drift, daily says none → slow drift that daily noise hides. Trust the weekly.
- Daily says drift, weekly says none → recent movement that hasn't accumulated into the weekly window yet. Could be the leading edge of real drift, or a contained incident. Trust the daily but note the weekly hasn't confirmed.
- Both agree → high confidence, state it.

### B6. Resolve verdict for handoff

After reconciliation, compute the five verdict fields that feed the
`rca-context` handoff block. This is a pure computation step — no new
queries.

**`verdict`** — categorize the overall finding:

| Condition | `verdict` value |
|---|---|
| Phase A flagged anomalies, Phase B showed no drift | `anomaly` |
| Phase B showed drift (any of the 4 drift verdicts in B4), Phase A flagged no anomalies | `drift` |
| Both phases flagged something | `drift` (drift takes precedence; anomalies get noted in `analyse_metric_notes` as potential contamination) |
| Neither flagged anything | **Do not emit the handoff block.** The metric is stable; RCA would waste queries. |
| User explicitly forced RCA on a clean metric | `user_forced` (only set when `metric-rca` invokes `analyse-metric` with a forced-investigation flag) |

**`verdict_magnitude`** — the headline number:
- If `verdict = drift`: Phase B Test 1's `level_delta` (signed %) from the daily view.
- If `verdict = anomaly`: the deviation % of the largest flagged anomaly from A2.

**`verdict_direction`** — sign of `verdict_magnitude`:
- Positive → `up`
- Negative → `down`
- If drift is compound (B4 = "Compound drift") and level/variance/shape
  disagree on direction → `mixed`.

**`verdict_shape`** — classify the shape of the drift or anomaly pattern
using the daily series from B1-daily:

| Condition | `verdict_shape` value |
|---|---|
| Single-day change point where mean shift before vs after explains ≥60% of variance, and before/after segments are each <20% within-segment variance | `step` (record the change-point date in `analyse_metric_notes`) |
| Linear regression fit to the full 60-day series has R² ≥ 0.5 and non-zero slope | `slope` |
| 7-day autocorrelation on residuals ≥ 0.5, and periodicity strength differs between drift and baseline windows | `oscillating` |
| Anomaly detected in A2 but metric returned to within 5% of baseline mean before `drift_window.end` | `spike` |
| None of the above fit cleanly | `unclassified` |

**Shape precedence**: if multiple shapes fit, use this priority: `step`
> `spike` > `slope` > `oscillating` > `unclassified`. (Step changes are
the most actionable; surface them first when ambiguous.)

**`analyse_metric_notes`** — aggregate any of the following that apply:
- Contamination flag from B2 (if recent window had ≥20% anomaly points)
- User-level data availability flag (if Test 3 was skipped)
- Weekly-vs-daily disagreement from B5 reconciliation
- Change-point date if `verdict_shape = step`
- Retention cohort-comparison fallback note (if applicable; see Special Cases)
- Low-volume warning (if applicable; see Special Cases)

Keep the notes short — the CSA reads them inline in the handoff block,
not as a report. One or two clauses per note, semicolon-separated.

All five fields are stored for use in C1 and C2 output generation.

---

## Phase C — Final output

Two output modes. **Default: compact card + chart.** Full report only when the
user asks for it ("show me more", "full report", "detail", "expand", etc.).

---

### C1. Default mode — Compact card + chart

Produces **two things**:

1. **A single inline chart** via the visualizer (`visualize:show_widget`).
2. **A compact verdict card** immediately after the chart, in chat.

Order: chart first, card second. The chart is the sanity check; the card is
the verdict to act on.

#### The chart

**Always rendered — regardless of whether anomaly or drift was detected.**
The trend visualization is the first thing the CSA sees. A clean chart
confirming stability is just as useful as one highlighting a problem — it
saves the CSA from second-guessing the verdict.

- **Type:** line chart, 60-day daily view of the metric (the B1-daily series).
- **Always present (both stable and flagged metrics):**
  - The 60-day daily trend line.
  - Shaded band for the **prior 30-day drift window** (subtle grey fill).
  - Shaded band for the **recent 30-day drift window** (subtle brand blue fill).
  - Horizontal line for `mean_prior` (dashed grey).
  - Horizontal line for `mean_recent` (dashed brand blue).
- **Conditional overlays (only when flagged):**
  - Dots marking **flagged anomaly points** from Phase A — red for drops, amber for spikes. Only show daily-series anomalies on this chart (hourly anomalies would clutter it; save those for full report).
  - Label the most recent flagged anomaly inline with its date and deviation %.
- **Stable-metric variant:** when no anomalies and no drift are detected, the chart renders with only the always-present elements above. The two mean lines will be visually close, the shaded windows will show no divergence — this *is* the visual proof of stability. Add a subtle annotation at the chart footer: "No anomalies or drift detected in this window."
- **Axes:** x-axis = date, y-axis = metric value (raw, not indexed). Show gridlines sparingly.
- **Title:** `<metric_name> — last 60 days`.
- **No legend inside the chart** — put the legend below it as one line of text.

Before generating, read `visualize:read_me` with `modules: ["chart"]` for the
CSS variables and sizing rules. Do not narrate the read_me call to the user.

If chart generation fails for any reason, fall back to card-only output with a
note: "Chart unavailable — card below." Do not block on the chart.

#### The compact card

Same fixed format as before. No changes here beyond existing to both modes:

```
METRIC: <metric_name> — <project_id>
DEFINITION: <one-sentence what-it-measures>

━━ ANOMALY ━━
Verdict: <Clean | N anomalies flagged | Anomaly cluster — possible drift>
Most recent flag: <timestamp>  <deviation %>  [type]

━━ DRIFT ━━
60-day / daily view:   <verdict>  <direction>  <magnitude>
16-week / weekly view: <verdict>  <direction>  <magnitude>
Reconciled verdict:    <one sentence>
Contamination flag:    <none | recent anomalies may be inflating drift>

━━ HEADLINE ━━
<one sentence the CSA could paste into a customer Slack>

━━ CONFIDENCE ━━
<high | medium | low> — <reason for any hedge>

━━ NEXT STEP ━━
<one concrete action>
```

Note two deliberate changes from the earlier draft:
- The "Top flags (up to 5)" list is removed from compact mode. It lives in the full report instead — five flagged timestamps in a card is too much detail for scan-speed reading.
- The "What this isn't" section is removed from compact mode. It's still in the full report.

#### Handoff block for `metric-rca` (conditional)

**Emit only when Phase A or Phase B flagged something.** If the reconciled
verdict is "stable — no action needed" with no anomalies, skip the block
entirely. Running RCA on a clean metric wastes 15–25 queries chasing noise.

When emitted, place the block **after the compact card and before the
"full report" prompt**. Same placement in the expanded card (C2).

The block is a fenced markdown block with language tag `rca-context`.
`metric-rca` parses it as its sole source of input context — no
re-elicitation of project_id, metric definition, or windows.

````
```rca-context
project_id: <int>
metric_name: <str>
metric_definition: <one-sentence what-it-measures>
metric_type: count | unique_count | ratio | funnel | retention | unknown
query_template: <dict, reusable query body for Run-Query>
default_filters: <dict, filters baked into the saved report>
verdict: anomaly | drift | user_forced
verdict_magnitude: <signed %, e.g. -12.4>
verdict_direction: up | down | mixed
verdict_shape: step | slope | oscillating | spike | unclassified
drift_window: {start: YYYY-MM-DD, end: YYYY-MM-DD}
baseline_window: {start: YYYY-MM-DD, end: YYYY-MM-DD}
analyse_metric_notes: <free text, any caveats flagged above>
```
````

**Field sourcing — single source of truth is Phase B6.** Every field
in the block except the Step 0 inputs is resolved in B6. The block is
just a serialization of B6's output + the metric series object.

- `project_id`, `metric_name`, `metric_definition`, `query_template`,
  `default_filters` — from the metric series object built in Step 0.
- `metric_type` — from the Prerequisites classification step (top of
  this file). `metric-rca`'s Step 2.2 handles the `unknown` fallback.
- `verdict`, `verdict_magnitude`, `verdict_direction`, `verdict_shape`,
  `analyse_metric_notes` — all resolved in **Phase B6** (see the
  "Resolve verdict for handoff" section above for the full logic).
- `drift_window` — the **recent 30-day window** from Phase B1 daily
  (`{start: today - 30d, end: today}`).
- `baseline_window` — the **prior 30-day window** (`{start: today - 60d,
  end: today - 30d}`).

#### Worked example

For a realistic case — Nykaa's session-to-order conversion rate
dropping 12.4% with a clean change-point on March 18 — the emitted
block looks like:

````
```rca-context
project_id: 2852656
metric_name: Session → Order conversion rate
metric_definition: Share of sessions that result in at least one order within the session
metric_type: ratio
query_template: {event: "$any_event", filters: {...}, numerator: "Order Placed", denominator: "Session Start"}
default_filters: {platform: ["web", "ios", "android"]}
verdict: drift
verdict_magnitude: -12.4
verdict_direction: down
verdict_shape: step
drift_window: {start: 2026-03-20, end: 2026-04-19}
baseline_window: {start: 2026-02-18, end: 2026-03-20}
analyse_metric_notes: Change-point detected on 2026-03-18; 16w/60d views agree on direction.
```
````

Three patterns to note from this example:
- `metric_type: ratio` → `metric-rca` routes to Branch 2.1 (num/den decomposition).
- `verdict_shape: step` with the change-point in `notes` → Branch 4 trusts this and doesn't re-query; synthesis puts this at Priority 2 on the headline ladder.
- `analyse_metric_notes` is compact (three clauses, semicolon-separated). Not a report, not a changelog.

After the block, **append the one-line prompt**: "Want the full report
(both series, all flagged points, test details)? Ask and I'll expand."

**Headline phrasing discipline** (unchanged):
- No anomaly and no drift: "Metric is stable — no action needed."
- Anomaly only: "Metric had a [spike/drop] of X% on [date] but the baseline is otherwise stable."
- Drift only: "Metric has drifted [up/down] by X% over the last [window]. No single-point anomalies."
- Both: "Metric has drifted [up/down] by X% and had [N] anomalies in the last 7 days. Drift test may be contaminated by recent anomalies — investigate before attributing."

Never lead with a confidence hedge. State the finding, then qualify it.

---

### C2. Full report mode — Two charts stacked + expanded card

Trigger only on explicit request. Produces **three things**:

1. **A single visualizer widget** containing **two charts stacked vertically** (always rendered, same as C1 — charts appear for both stable and flagged metrics):
   - **Top chart:** 7-day hourly view (A1-hourly series). Anomaly focus.
     - Red/amber dots on every flagged hourly anomaly (omitted if none flagged).
     - No drift shading (not relevant at this window).
     - Title: `<metric_name> — last 7 days, hourly`.
   - **Bottom chart:** 60-day daily view (B1-daily series). Drift focus.
     - Same overlays as C1: drift-window shading, mean lines always present; anomaly dots conditional.
     - Title: `<metric_name> — last 60 days, daily`.
   - Both charts share x-axis type (date/time) but not range — render them as two separate plots in one widget, stacked, with consistent y-axis formatting.
2. **The expanded verdict card** (below).
3. **A flagged-points table** for Phase A (below the card).

Before generating, read `visualize:read_me` with `modules: ["chart"]` once if
not already loaded this session.

#### Expanded card

All fields from compact, plus:

```
━━ ANOMALY DETAIL ━━
Hourly series (7d):  <N flagged>  — top flags:
  - <timestamp>  <value>  <deviation %>  [type]
  - ...  (cap 5)
Daily series (30d):  <N flagged>  — top flags:
  - <timestamp>  <value>  <deviation %>  [type]
  - ...  (cap 5)

━━ DRIFT DETAIL ━━
60-day / daily view:
  Mean shift:     <+/-X.X%>    Welch's t p-value: <p>
  Variance ratio: <X.XX>
  Shape test:     <KS stat / PSI value | not run (aggregate data only)>
16-week / weekly view:
  Mean shift:     <+/-X.X%>    Welch's t p-value: <p>
  Variance ratio: <X.XX>
  Shape test:     <KS stat / PSI value | not run (aggregate data only)>

━━ WHAT THIS ISN'T ━━
<explicit scope limits>
```

All other compact fields (HEADLINE, CONFIDENCE, NEXT STEP) remain in the same
positions in the expanded card.

#### Flagged-points table

Only include if Phase A produced >5 flags in either series. Full table of all
flags, sorted by deviation magnitude descending. Columns: `timestamp | value |
deviation % | σ | type`. If ≤5 flags total, the card already showed them —
skip the table.

#### Handoff block (C2)

Same rules as C1. Emit the `rca-context` fenced block **after the
expanded card + flagged-points table, before any closing prompt**.
Only emit if Phase A or Phase B flagged something. Schema and field
sourcing identical to C1 — see the C1 "Handoff block for `metric-rca`"
section above.

---

### C3. Mode selection logic

- Default to C1 unless the user's original ask contained "full", "detailed", "expand", "show me more", "full report", or similar.
- If the user asks for the full report *after* C1 has already run, re-use the
  metric series data already in context — **do not re-fire the Mixpanel queries.**
  Just regenerate the widget with both charts and print the expanded card.
- Never produce both C1 and C2 in the same response. One or the other.

---

## Special cases

**Funnel metrics:** The hourly view is usually too noisy for a multi-step funnel
at low volume. If the metric is a funnel, drop Phase A's hourly query and run
A1-daily only (last 14 days instead of 30 to stay lightweight). Proceed with
Phase B as normal. Note in output: "Hourly anomaly detection skipped — funnel volume too low at hourly granularity."

**Retention metrics:** Retention is inherently a rolling cohort metric — "drift"
on a retention curve usually means cohort-over-cohort degradation. Phase A
mostly doesn't apply. Skip to Phase B and replace the daily/weekly split with
a cohort-over-cohort comparison: last 8 cohorts vs. prior 8 cohorts on the
same retention day (D1, D7, D30). Flag which retention day shifted.

**Very low-volume metrics (<100 events/day):** Anomaly detection at hourly
granularity is unreliable — the Poisson noise floor dominates. Skip A1-hourly
and only run A1-daily. State this in the output.

---

## Error handling

| Situation | Response |
|---|---|
| Any single query fails | Retry once. If still failing, mark that phase partial, continue the rest, note in output. |
| Project requires a filter the user didn't provide | Ask once, then proceed. Don't guess. |
| Metric returns zero events in window | Stop. The metric is either broken or the filter excludes everything. Report this as a possible data quality issue, do not proceed to drift analysis. |
| User-level data unavailable for Test 3 | Skip Test 3, state explicitly in output. Not a blocker. |

---

## What this command deliberately doesn't do

- **Does not attribute drift to a segment, cohort, release, or cause.** That's `metric-rca`.
- **Does not run data quality checks.** That's a dedicated branch inside `metric-rca`.
- **Does not fetch correlated events.** Same reason.
- **Does not produce recommendations beyond "run RCA" or "confirm with customer".** The verdict is the product.

Keep the surface narrow. A clean anomaly/drift verdict in under 60 seconds is
more useful than a sprawling analysis that tries to do everything.
