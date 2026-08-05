# Command: metric-anomaly

Detect point-in-time anomalies in a single metric — recent spikes, drops, and
clusters. Produces a verdict on *whether* something unusual happened at a
specific moment. Does **not** test for trend-level drift (run `metric-drift`
for that).

---

## Prerequisites

Before this command runs, Steps 0, 1, and 1.5 from `references/execution.md`
must have completed — input validation, normalized metric series object, and
project profile resolution. If any of those haven't happened, do them first.

If the user's input is a saved report but the metric is a **funnel** or
**retention** report, see the "Special cases" section at the bottom.

### Prerequisite — classify `metric_type`

Classify the metric per the `metric_type` table in `SKILL.md` and store
`metric_type` on the series object before firing any queries.

---

## Phase 1 — Fetch series (2 queries, parallel)

Fire both `cap:run-query` calls simultaneously (resolve `cap:run-query` via the session tool map — see `references/tools.md`):

| Query | Window | Granularity | Purpose |
|---|---|---|---|
| Q1-hourly | Last 7 days | `hour` | Recent-blip detection |
| Q1-daily | Last 30 days | `day` | Recent-day detection against a fuller baseline |

Use the `query_template` from the metric object; override only `dateRange`
and `unit` (granularity). Do not re-apply filters — they're already baked in.

Build the `cap:run-query` body from `query_template` with only `dateRange` and
`unit` (granularity) overridden. Use `timeComparison` when a single call can
cover both windows.

---

## Phase 2 — Outlier test (additive seasonal baseline + robust residual)

For each series independently, fit an **additive seasonal baseline**, then test
each point's residual against the spread of all residuals. One test per series —
the residual test below does the work the old Z-score/IQR split did, without the
per-cell sample-size problem.

#### Why additive, not per-cell

A 7-day hourly series has exactly 168 points. Bucketing into 168 independent
hour-of-day × day-of-week cells leaves **one observation per cell** — no μ, no σ,
no IQR to compute. Modelling hour-of-day and day-of-week as **additive effects**
instead pools across the margins: ~30 parameters estimated from 168 points
(~5–6 obs each), so the baseline is actually estimable. A robust fit also
self-protects — it keeps the spike being hunted from inflating its own baseline
and masking itself.

### Step 1 — Fit the additive baseline (median polish)

Arrange the series as a two-way table and fit
`value ≈ overall + row_effect + col_effect` by **median polish** (robust — means
get dragged by the very outliers being detected):

- **Hourly series:** rows = day-of-week (7), cols = hour-of-day (24).
- **Daily series:** one seasonal axis only — rows = day-of-week (7), no column
  effect. Same model with one margin dropped, not a different test.

Median polish = subtract each row's median, then each column's median, and
repeat (2–3 sweeps converges). What remains per point is its **residual**; the
removed pieces are the overall level plus the additive seasonal effects. The
fitted value for a point is `overall + row_effect + col_effect`. Compute this in
a code step for reproducibility rather than by hand.

### Step 2 — Flag on residual magnitude (robust)

- Robust spread: `scale = 1.4826 × median(|resid − median(resid)|)` (MAD → σ).
- Flag any point where `|resid| / scale > 3.5`. The 3.5 cutoff (vs the old 2.5)
  is deliberately tighter — MAD-based scores run leaner than classical Z and
  168 points are being screened, so this holds the false-positive rate down.
- Flat-metric guard: if `scale` is near zero (a genuinely flat series), fall
  back to a relative rule — flag points more than ±25% from the fitted value —
  so a flatline doesn't make every small wobble look catastrophic.

### Deviation magnitude

For every flagged point, report `(value − fitted) / fitted` as a signed
percentage — deviation from the *seasonal expectation*, not from a raw median.
This is what the CSA actually cares about, not the residual score itself.

### Classify each flagged timestamp

- **Isolated spike/drop** — one point flagged, neighbors normal. Most likely a real anomaly (outage, release, data gap).
- **Cluster** — 2+ consecutive points flagged in the same direction. Could be a short incident *or* the leading edge of drift. Flag as ambiguous and note that `metric-drift` may be a better follow-up.
- **Edge-of-window cluster** — flagged points are the most recent N points. Strongly suggestive of drift, not anomaly. Recommend running `metric-drift` before treating as an anomaly incident.

---

## Phase 3 — Summarise + charts + handoff

Produces **three things**, in order:

1. **A single visualizer widget with two charts stacked vertically**
2. **A compact verdict card**
3. **A diagnosis payload** handed back to the skill-level flow (Step 2 in
   `references/execution.md`) for the board prompt and `metric-rca` caching

### The charts — always rendered

Both charts render regardless of whether anything was flagged. A stable chart
is the visual proof of stability and saves the CSA from second-guessing.

**Top chart: 7-day hourly view** (Q1-hourly series)
- Line for the hourly series.
- Dots for every flagged hourly point — red for drops, amber for spikes. Omit entirely if no flags.
- Label the most recent flagged point inline with timestamp and deviation %.
- Title: `<metric_name> — last 7 days, hourly`.

**Bottom chart: 30-day daily view** (Q1-daily series)
- Line for the daily series.
- Dots for every flagged daily point — red for drops, amber for spikes. Omit entirely if no flags.
- Label the most recent flagged point inline with timestamp and deviation %.
- Title: `<metric_name> — last 30 days, daily`.

Both charts share x-axis type (date/time) but not range — render as two
separate plots in one widget, stacked, with consistent y-axis formatting.

Before generating, read `visualize:read_me` with `modules: ["chart"]` once if
not already loaded this session. Do not narrate the read_me call to the user.

If chart generation fails, fall back to card-only output with the note
"Chart unavailable — card below." Do not block on the chart.

### The compact verdict card

```
METRIC: <metric_name> — <project_id>
DEFINITION: <one-sentence what-it-measures>

━━ ANOMALY VERDICT ━━
Hourly series (7d):  <Clean | N flagged | Edge cluster — possible drift>
Daily series (30d):  <Clean | N flagged | Edge cluster — possible drift>

━━ TOP FLAGS ━━
<timestamp>  <value>  <deviation %>  [isolated | cluster | edge]  (resid <score>σ)
<timestamp>  <value>  <deviation %>  [isolated | cluster | edge]  (resid <score>σ)
... (cap 5; omit section entirely if no flags)

━━ HEADLINE ━━
<one sentence the CSA could paste into a customer Slack>

━━ CONFIDENCE ━━
<high | medium | low> — <reason for any hedge>

━━ NEXT STEP ━━
<one concrete action>

━━ WHAT THIS ISN'T ━━
This is point-in-time anomaly detection only. Trend-level drift is not
tested here — run `metric-drift` for that.
```

#### Headline phrasing discipline

- No flags: "Metric is stable at the point-in-time level — no anomalies in the last 7 or 30 days."
- Isolated flag(s): "Metric had a [spike/drop] of X% on [date]. Baseline otherwise stable."
- Cluster or edge cluster: "Metric has [N] anomalies concentrated in the last [window] — likely the leading edge of drift. Recommend running `metric-drift` next."

Never lead with a confidence hedge. State the finding, then qualify it.

If >10 flags total across both series, cap the TOP FLAGS list at 5 entries
sorted by deviation magnitude descending and add a note to the headline:
"18 anomalies flagged in the last 7 days — the metric is either undergoing a
regime shift or the baseline model is wrong. Run `metric-drift` before
treating any single point as actionable."

### The diagnosis payload

After rendering the charts and verdict card, assemble the payload defined
in `references/execution.md` Step 2 and hand it back to the skill-level flow:

```
{
  command: "metric-anomaly",
  project_id, project_name, metric_id,
  metric_name, metric_definition, metric_type,
  queries: [
    { label: "Q1-hourly", window: "last 7 days", granularity: "hour",
      run_query_body: <body used>, result: <series> },
    { label: "Q1-daily",  window: "last 30 days", granularity: "day",
      run_query_body: <body used>, result: <series> }
  ],
  verdict_card: <full rendered card above>,
  headline: <the HEADLINE line from the card>,
  flags: {
    hourly: [ { timestamp, value, deviation_pct, classification, resid_score } , ... ],
    daily:  [ { timestamp, value, deviation_pct, classification, resid_score } , ... ]
  }
}
```

Hand the payload to the skill-level flow. The board prompt and
`metric-rca` caching are handled there — see `references/execution.md`
Step 2. Do not ask the board question from inside this command.

---

## Special cases

**Funnel metrics:** The hourly view is usually too noisy for a multi-step
funnel at low volume. Drop Q1-hourly and run Q1-daily only (last 14 days
instead of 30 to stay lightweight). Note in output: "Hourly anomaly detection
skipped — funnel volume too low at hourly granularity."

**Retention metrics:** Retention is a rolling cohort metric — point-in-time
anomaly detection mostly doesn't apply. Tell the user directly and recommend
`metric-drift` instead, which has a cohort-over-cohort fallback for retention.

**Very low-volume metrics (<100 events/day):** Skip Q1-hourly and run
Q1-daily only — the Poisson noise floor dominates at hourly granularity.
State this in the output.

---

## Error handling

| Situation | Response |
|---|---|
| Either query fails | Retry once. If still failing, mark that series partial, continue the other, note in output. |
| Both queries fail | Stop. Report the failure and ask the user to verify project access. |
| Project requires a filter the user didn't provide | Ask once, then proceed. Don't guess. |
| Metric returns zero events in window | Stop. The metric is either broken or the filter excludes everything. Report as a possible data quality issue; do not proceed to Phase 2. |

---

## What this command deliberately doesn't do

- **Does not test for trend-level drift.** That's `metric-drift`.
- **Does not attribute cause.** Root-cause investigation is out of scope for this command — run `metric-rca` after detection.
- **Does not produce recommendations beyond "run drift" / "run RCA".** The verdict is the product.

Keep the surface narrow. A clean anomaly verdict in under 30 seconds is more
useful than a sprawling analysis that tries to do everything.
