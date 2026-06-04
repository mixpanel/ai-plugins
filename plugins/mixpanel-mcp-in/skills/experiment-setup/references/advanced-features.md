# Advanced features

Three optional settings most experiments don't touch — and that, used in the right spot, dramatically improve power or trustworthiness. Each one has a clear set of conditions where it helps and a clear set of conditions where enabling it is wrong.

## CUPED — variance reduction

**What it does.** CUPED (Controlled-experiment Using Pre-Experiment Data) reduces variance on metrics that correlate with users' pre-experiment behaviour. Lower variance → smaller required sample size → faster experiments. Typical reductions are 30–70%, which translates directly into 30–70% smaller required sample.

**Setting:** `settings.cuped.enabled = true`, with `settings.cuped.preExposureDatePreset` choosing the pre-exposure window.

### When to enable

- The primary metric correlates with users' pre-exposure behaviour on the same metric. Strong correlations: revenue, engagement (events per user), retention, time-on-platform. Weak correlations: anything one-time or onboarding-specific.
- **All experiment users existed before the experiment start** — i.e., not a new-user-only cohort. CUPED needs a pre-exposure observation period; new users don't have one.
- A 2–4 week pre-exposure window is available with stable behaviour. If the metric was launched 5 days ago, CUPED has nothing to read.

### When NOT to enable

- New-user-only experiments. No pre-exposure data exists. CUPED gives zero variance reduction and adds noise.
- Brand-new metrics without historical data.
- Metrics where pre-exposure behaviour is not predictive of post-exposure (e.g., one-time onboarding events: the user either did or didn't complete onboarding once; pre-exposure has nothing to say about it).
- Pre-exposure window short enough that the behaviour you'd "control for" is itself a transient spike (e.g., metric just had a viral moment last week).

### Pre-exposure window presets

- `"2-weeks"` — fast-moving metrics with no strong weekly seasonality.
- `"4-weeks"` — most metrics with weekly seasonality (default sweet spot).
- `"60-days"` — deeply seasonal metrics like spend.
- `"90-days"` — long-cycle metrics (renewal-driven revenue, etc.).

### What changes downstream

- Required sample size shrinks by the variance-reduction factor. A 50% variance reduction on a primary that needed 60k per arm shrinks the target to ~30k per arm.
- The point estimate of the lift is unchanged. CUPED is a variance-reduction technique, not a bias correction; the headline lift is the same, the confidence interval is narrower.
- The post-launch interpretation step needs to know CUPED was on, because the standard error formula differs. The setting is persisted on the experiment object; the interpretation step reads it automatically.

## Winsorization — outlier handling

**What it does.** Caps extreme values at a percentile boundary (default 95th, i.e. cap the top 5% and bottom 5% at the 95th and 5th percentile values respectively). This squeezes the long tail of heavy-tailed distributions so a handful of outliers can't dominate the per-arm mean.

**Setting:** `settings.winsorization.enabled = true`, with `settings.winsorization.percentile` choosing the cap point.

### When to enable

- Revenue or spend metrics with whales (one customer spends 100× the median; that customer assigned to treatment is enough to swing the headline).
- Time-on-page or session-duration metrics with users who fall asleep on the page (one session at 8 hours dwarfs 10,000 sessions at 30 seconds).
- Any Gaussian-distributed metric with a heavy right tail (count metrics, event volume per user, page view counts).

### When NOT to enable

- Bernoulli (conversion) metrics. Capping a 0/1 outcome is meaningless; the 95th percentile of a 0/1 distribution is also 0 or 1.
- Metrics where the tail behaviour **is** the hypothesis. If the test is "did this change move whale spending?", Winsorization throws away exactly the signal you're testing for.
- Metrics already winsorized upstream (in the metric definition / data pipeline) — double-winsorization adds nothing.

### Percentile guidance

Default is 95 (cap top/bottom 5%). This is almost always right. Push back if the user sets `percentile < 80` — that's >20% of values being capped, which throws away too much signal. Confirm intent before launching.

For very heavy tails (extreme whale distributions), 99th percentile is sometimes appropriate, but that's the corner case. 95 is the default for a reason.

### What changes downstream

- Variance on the affected metric drops, often substantially. Required sample size shrinks accordingly.
- The point estimate of the mean shifts toward the centre of the distribution. This is the desired behaviour; the whole point is to stop a few outliers from anchoring the estimate.
- The post-launch interpretation step reports the winsorized mean and standard error. If the team also wants to know what the un-winsorized mean did (the "did whales react?" question), they'd need a separate secondary metric without Winsorization.

## Multiple testing correction — Bonferroni vs Benjamini-Hochberg

Covered in detail in `references/statistical-model.md`. The short version:

- Enable when `len(primary_metrics) ≥ 2` OR `len(non_control_variants) ≥ 2`.
- Default to `"benjamini-hochberg"`. More powerful with correlated primaries.
- Use `"bonferroni"` when family-wise error control is required (regulatory, etc.) or when the primaries are independent.
- Set `"off"` only with a single primary and a single non-control variant.

## Decision flowchart

```
Primary metric is Bernoulli (conversion rate)?
├── Yes → Winsorization OFF.
│         Does it correlate with pre-exposure behavior of existing users?
│         ├── Yes → CUPED ON (if 2-4 week pre-exposure window available, no new-user cohort)
│         └── No  → CUPED OFF
└── No (continuous / count / retention)
          Heavy-tailed distribution with outliers (revenue, time-on-page, session length)?
          ├── Yes → Winsorization ON (default percentile = 95)
          └── No  → Winsorization OFF
          Does it correlate with pre-exposure behavior of existing users?
          ├── Yes → CUPED ON (if 2-4 week pre-exposure window available, no new-user cohort)
          └── No  → CUPED OFF

Primary count ≥ 2 OR non-control variants ≥ 2?
├── Yes → Multiple testing correction ON ("benjamini-hochberg" default; "bonferroni" for strict family-wise control)
└── No  → Multiple testing correction OFF
```

## Common misconfigurations

- ⛔ **CUPED on a new-user-only experiment.** No pre-exposure data; the feature does nothing. Worse, the user thinks they're being protected and ships an underpowered test.
- ⛔ **Winsorization on a conversion metric.** Capping 0/1 values is meaningless. The setting either no-ops or, if a buggy implementation interprets it literally, makes the metric worse.
- ⛔ **Winsorization at percentile < 80.** Cuts more than 20% of data. Almost always a typo for 95 or 90. Confirm intent.
- ⛔ **Multiple testing correction OFF on a 5-primary test.** Family-wise FPR balloons to ~22.6%. One in five "wins" is noise.
- ⛔ **CUPED enabled "to be safe" on a metric where pre-exposure doesn't predict post-exposure.** Best case: no effect. Common case: the variance estimate gets noisier because the regression adjustment is fitting to noise.
