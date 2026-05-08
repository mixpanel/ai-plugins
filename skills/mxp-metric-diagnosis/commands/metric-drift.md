# Command: metric-drift

Detect trend-level drift in a single metric — whether the baseline itself has
shifted over recent weeks. Produces a verdict on *whether* the metric is in a
new regime. Does **not** test for point-in-time anomalies (run `metric-anomaly`
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

### Prerequisite — name the drift and baseline windows

The naming convention used throughout this command's output:

- **`drift_window`** — the **recent** 30 days (most recent 30 days ending today).
- **`baseline_window`** — the **prior** 30 days (30 days ending 30 days before today).

Both windows are computed from Q1-daily. The weekly test uses 8 vs 8 weeks —
those windows are reported alongside but are secondary to the daily windows
for headline purposes.

---

## Phase 1 — Fetch series (2 queries, parallel)

Fire both `Run-Query` calls simultaneously:

| Query | Window | Granularity | Comparison |
|---|---|---|---|
| Q1-daily | Last 60 days | `day` | Last 30 days vs. prior 30 days |
| Q1-weekly | Last 16 weeks | `week` | Last 8 weeks vs. prior 8 weeks |

The 60-day daily view catches medium-term drift. The 16-week weekly view
catches slow drift that the daily window would miss because daily noise
drowns the signal. Running both is cheap and they answer different questions.

Use the `query_template` from the metric object; override only the date range
and granularity. Do not re-apply filters — they're already baked in.

---

## Phase 2 — Drift tests (mean shift + variance ratio)

### Window split & contamination check

For each series, split into `recent` and `prior` halves (no overlap).

**Lightweight anomaly contamination check** (important because this command
can run standalone without `metric-anomaly` having run first):

Scan the `recent` window for obvious outliers using a simple rule — any point
more than 3σ from the window mean. If ≥20% of points in the `recent` window
qualify → flag **"drift test potentially contaminated by outliers in the
recent window"** and mark all drift findings as low-confidence. Recommend the
user run `metric-anomaly` first.

If 0–20% of points qualify, proceed normally but note the count in the
verdict card's contamination section.

This is deliberately lighter than `metric-anomaly`'s full time-bucketed
test — its job here is only to flag contamination risk, not to produce a
publishable anomaly verdict.

### Test 1 — Mean shift (level drift)

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
`level_delta ≥ 5%`, drift is statistically supported. If p ≥ 0.05, note the
shift is observational but not statistically distinguishable from noise.

### Test 2 — Variance ratio (volatility drift)

```
var_ratio = variance(recent_window) / variance(prior_window)
```

Flag thresholds:
- `0.67 ≤ var_ratio ≤ 1.5` → variance stable
- `var_ratio > 1.5` → metric got noisier (investigate instrumentation, cohort mix)
- `var_ratio < 0.67` → metric got smoother (often a sign of flatlining or saturation)

Variance drift without level drift is an under-appreciated signal — the
headline number looks fine but something structural changed. Always surface
it separately.

Distribution-shape tests (KS, PSI) are intentionally **not** part of this
battery. They require per-user or per-segment values, which Mixpanel's MCP
surface does not return at practical cost.

### Combine into a per-series verdict

| Verdict | When |
|---|---|
| **No drift** | Level stable AND variance stable |
| **Level drift** | Level shifted ≥5%, variance stable |
| **Variance drift** | Level stable, variance ratio outside 0.67–1.5 |
| **Compound drift** | Both |

Also report **direction** (up / down) and **magnitude** (% for level, ratio
for variance).

### Reconcile the two series

The 60-day-daily and 16-week-weekly views should agree on direction. If they
disagree:

- **Weekly says drift, daily says none** → slow drift that daily noise hides. Trust the weekly.
- **Daily says drift, weekly says none** → recent movement that hasn't accumulated into the weekly window yet. Could be the leading edge of real drift, or a contained incident. Trust the daily but note the weekly hasn't confirmed.
- **Both agree** → high confidence, state it.

### Classify drift shape

If drift is flagged, classify its shape using the daily series for use in
the verdict card:

| Condition | `verdict_shape` value |
|---|---|
| Single-day change point where mean shift before vs after explains ≥60% of variance, and before/after segments are each <20% within-segment variance | `step` (record the change-point date) |
| Linear regression fit to the full 60-day series has R² ≥ 0.5 and non-zero slope | `slope` |
| 7-day autocorrelation on residuals ≥ 0.5, and periodicity strength differs between drift and baseline windows | `oscillating` |
| None of the above fit cleanly | `unclassified` |

**Shape precedence**: if multiple shapes fit, use this priority:
`step` > `slope` > `oscillating` > `unclassified`. (Step changes are the
most actionable; surface them first when ambiguous.)

If no drift was flagged, skip shape classification entirely.

---

## Phase 3 — Summarise + charts + handoff

Produces **three things**, in order:

1. **A single visualizer widget with two charts stacked vertically**
2. **A compact verdict card**
3. **A diagnosis payload** handed back to the skill-level flow (Step 2 in
   `SKILL.md`) for the board prompt and `metric-rca` caching

### The charts — always rendered

Both charts render regardless of whether drift was detected. A stable chart
is the visual proof of stability.

**Top chart: 60-day daily view** (Q1-daily series)
- Line for the daily series.
- **Shaded band** for the prior 30-day baseline window (subtle grey fill).
- **Shaded band** for the recent 30-day drift window — red-tinted fill if drift is `down`, green-tinted if `up`, amber-tinted if `mixed`, grey if no drift.
- Horizontal line for `mean_prior` (dashed grey).
- Horizontal line for `mean_recent` (dashed, colored to match drift direction).
- If `verdict_shape = step`, annotate the change-point date with a vertical dashed line.
- Title: `<metric_name> — last 60 days, daily`.

**Bottom chart: 16-week weekly view** (Q1-weekly series)
- Line for the weekly series.
- **Shaded band** for the prior 8-week baseline window (subtle grey fill).
- **Shaded band** for the recent 8-week drift window — same direction-based coloring as above.
- Horizontal lines for `mean_prior_weekly` (dashed grey) and `mean_recent_weekly` (dashed, colored).
- Title: `<metric_name> — last 16 weeks, weekly`.

Both charts share x-axis type (date) and consistent y-axis formatting.
Render as two separate plots in one widget, stacked.

Before generating, read `visualize:read_me` with `modules: ["chart"]` once if
not already loaded this session. Do not narrate the read_me call to the user.

If chart generation fails, fall back to card-only output with the note
"Chart unavailable — card below." Do not block on the chart.

### The compact verdict card

```
METRIC: <metric_name> — <project_id>
DEFINITION: <one-sentence what-it-measures>

━━ DRIFT VERDICT ━━
60-day / daily view:   <verdict>  <direction>  <magnitude>  (t-test p = <p>)
16-week / weekly view: <verdict>  <direction>  <magnitude>
Reconciled verdict:    <one sentence>
Shape:                 <step | slope | oscillating | unclassified>  <change-point date if step>

━━ CONTAMINATION ━━
<none | recent window contains N outliers — drift confidence downgraded; recommend metric-anomaly first>

━━ HEADLINE ━━
<one sentence the CSA could paste into a customer Slack>

━━ CONFIDENCE ━━
<high | medium | low> — <reason for any hedge>

━━ NEXT STEP ━━
<one concrete action>

━━ WHAT THIS ISN'T ━━
This is trend-level drift detection only. Point-in-time anomalies are not
tested here — run `metric-anomaly` for that.
```

#### Headline phrasing discipline

- No drift: "Metric is stable — trend has not shifted in the last 30 days or 8 weeks."
- Level drift: "Metric has drifted [up/down] by X% over the last 30 days. [Weekly view confirms / Weekly view hasn't confirmed yet]."
- Variance drift only: "Metric level is stable but volatility has [increased/decreased] — variance ratio [X.XX]. Something structural changed without moving the headline."
- Compound drift: "Metric has drifted [up/down] by X% AND volatility changed. Compound drift — investigate both level and structure."
- Contamination flag: append "Drift confidence is low — recent window has N outlier points. Run `metric-anomaly` first to clean up before attributing."

Never lead with a confidence hedge. State the finding, then qualify it.

### The diagnosis payload

After rendering the charts and verdict card, assemble the payload defined
in `SKILL.md` Step 2 and hand it back to the skill-level flow:

```
{
  command: "metric-drift",
  project_id, project_name,
  metric_name, metric_definition, metric_type,
  queries: [
    { label: "Q1-daily",  window: "last 60 days",  granularity: "day",
      run_query_body: <body used>, result: <series> },
    { label: "Q1-weekly", window: "last 16 weeks", granularity: "week",
      run_query_body: <body used>, result: <series> }
  ],
  verdict_card: <full rendered card above>,
  headline: <the HEADLINE line from the card>,
  flags: {
    daily:  { verdict, direction, level_delta, var_ratio, t_test_p, shape, change_point_date },
    weekly: { verdict, direction, level_delta, var_ratio },
    reconciled: <one-line reconciled verdict>,
    contamination: { outlier_count, contaminated: bool }
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

**Funnel metrics:** Phase 1 and Phase 2 work as-is for multi-step funnels
— the overall conversion series is what drifts. No special handling needed.

**Retention metrics:** Retention is a rolling cohort metric — "drift" on a
retention curve means cohort-over-cohort degradation. Replace the 60-day
daily and 16-week weekly splits with a cohort-over-cohort comparison: last
8 cohorts vs. prior 8 cohorts on the same retention day (D1, D7, D30). Flag
which retention day shifted. Note in the verdict card: "Retention
cohort-over-cohort comparison used in place of daily/weekly split."

**Very low-volume metrics (<100 events/day):** The tests still apply but
statistical confidence drops sharply. Downgrade confidence to `low` regardless
of `level_delta` magnitude and note: "Low-volume metric — drift signal may be
Poisson noise."

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

- **Does not detect point-in-time anomalies.** That's `metric-anomaly`.
- **Does not attribute cause.** Root-cause investigation is out of scope for this skill.
- **Does not produce recommendations beyond "run anomaly first".** The verdict is the product.

Keep the surface narrow. A clean drift verdict in under 60 seconds is more
useful than a sprawling analysis that tries to do everything.
