# Command: metric-anomaly

Detect point-in-time anomalies in a single metric — recent spikes, drops, and
clusters. Produces a verdict on *whether* something unusual happened at a
specific moment. Does **not** test for trend-level drift (run `metric-drift`
for that).

---

## Prerequisites

Before this command runs, Steps 0, 1, and 1.5 from `SKILL.md` must have
completed — input validation, normalized metric series object, and project
profile resolution. If any of those haven't happened, do them first.

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

Store as `metric_type` on the metric series object. Used in the verdict card
and in special-case routing (funnel, retention).

---

## Phase 1 — Fetch series (2 queries, parallel)

Fire both `Run-Query` calls simultaneously:

| Query | Window | Granularity | Purpose |
|---|---|---|---|
| Q1-hourly | Last 7 days | `hour` | Recent-blip detection |
| Q1-daily | Last 30 days | `day` | Recent-day detection against a fuller baseline |

Use the `query_template` from the metric object; override only the date range
and granularity. Do not re-apply filters — they're already baked in.

Build the `Run-Query` body from `query_template` with only `date_range` and
`granularity` overridden. Use `timeComparison` when a single call can cover
both windows.

---

## Phase 2 — Outlier tests (Z-score + IQR, time-bucketed)

For each series independently, compute the expected range at every timestamp.
Run **both** tests; flag a point if **either** test flags it. Report which
test(s) caught each flag.

### Test 1 — Z-score against time-bucketed mean

- For the **hourly** series: group all points by hour-of-day (0–23) and day-of-week (7 × 24 = 168 buckets). Compute mean (μ) and stddev (σ) per bucket across the 7-day window. Flag any point where `|value - μ| / σ > 2.5`.
- For the **daily** series: group by day-of-week (7 buckets). Compute μ and σ across the 30-day window. Flag any point where `|value - μ| / σ > 2.5`.
- Handle low-variance buckets: if σ is <5% of μ, skip the Z-score for that bucket and fall back to IQR only (division by tiny σ creates false alarms).

### Test 2 — IQR against time-bucketed median

- Same bucketing scheme as Test 1.
- For each bucket, compute Q1, median, Q3, and IQR = Q3 − Q1.
- Flag any point where `value < Q1 − 1.5 × IQR` or `value > Q3 + 1.5 × IQR`.

### Deviation magnitude

For every flagged point, report `(value − median) / median` as a signed
percentage. This is what the CSA actually cares about, not the Z-score itself.

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
   `SKILL.md`) for the board prompt and `metric-rca` caching

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
<timestamp>  <value>  <deviation %>  [isolated | cluster | edge]  (z-score | IQR | both)
<timestamp>  <value>  <deviation %>  [isolated | cluster | edge]  (z-score | IQR | both)
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
in `SKILL.md` Step 2 and hand it back to the skill-level flow:

```
{
  command: "metric-anomaly",
  project_id, project_name,
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
    hourly: [ { timestamp, value, deviation_pct, classification, test } , ... ],
    daily:  [ { timestamp, value, deviation_pct, classification, test } , ... ]
  }
}
```

The skill-level flow (Step 2 in `SKILL.md`) then asks the user about the
board and caches the payload for `metric-rca`. Do **not** ask the board
question from inside this command — that lives at the skill level so a
user running anomaly → drift back-to-back gets asked once at the end,
not twice.

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
- **Does not attribute cause.** Root-cause investigation is out of scope for this skill.
- **Does not produce recommendations beyond "run drift".** The verdict is the product.

Keep the surface narrow. A clean anomaly verdict in under 30 seconds is more
useful than a sprawling analysis that tries to do everything.
