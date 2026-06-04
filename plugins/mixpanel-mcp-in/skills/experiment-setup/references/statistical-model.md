# Statistical model

Once required sample size and acceptable duration are known, two settings are left: `settings.testingModel` and `settings.endCondition`. Plus the two adjacent settings that change how those tests are interpreted: `settings.confidenceLevel` and `settings.multipleTestingCorrection`.

## Testing model: sequential vs frequentist

**Default to `sequential`** for most users. Peeking is the most common Mixpanel customer mistake, and sequential testing makes early-look safe by design.

### Pick `sequential` when

- The user expects a **large lift** and wants to confirm or reject the hypothesis quickly. Sequential lets you stop the moment significance is reached — often days or weeks before a frequentist target.
- The user wants to check results before the experiment ends and act on them (early-stop on a clear winner).
- The expected effect size is uncertain (could be huge, could be tiny). Sequential adapts; frequentist needs you to commit to one MDE up front.
- The team will look at intermediate results regardless. Sequential prevents peeking from inflating false positives.
- The user is comfortable with slightly more complex stopping rules ("stop when the test-statistic crosses the boundary," not "stop when n reaches N").

### Pick `frequentist` when

- The user is hunting for a **very small lift** (e.g. 1–2% relative on a high-volume metric). Frequentist's fixed-sample design is statistically more efficient at the margin and avoids the early-stop boundary inflation that costs power on tiny effects.
- The team is comfortable waiting for the full sample before checking results — no peeking.
- The team prefers wider industry familiarity ("we used a t-test").
- The user wants the simplest reportable statistics (a single p-value and confidence interval at the end).
- The team has internal training / tooling that assumes frequentist.

### The "I want to peek with frequentist" trap

The most common request is "I want frequentist, but I also want to look at the results during the test." This inflates the false-positive rate enormously — naive peeking on a frequentist test at 5 evenly-spaced check-ins pushes the family-wise α from 5% to ~14%.

Switch them to sequential. Sequential's whole point is making peeking safe.

If the user insists on frequentist + peeking (some teams do, for tooling reasons), document the decision in `description` so the interpretation step later knows the reported p-values overstate confidence.

## End condition: sample_size vs days

### Pick `sample_size` when

- The team has a target MDE and wants the experiment to stop the moment the required sample is reached. Adaptive duration.
- Daily traffic is highly variable. Sample-size-based ends absorb the variability; date-based ends don't.
- There's no strong seasonality in the primary metric that would bias a mid-cycle stop.

### Pick `days` when

- The primary metric has **strong weekly (or other periodic) seasonality**. Pin the duration to a multiple of the seasonal cycle so each variant sees the same mix of high- and low-traffic periods.
  - A common pattern: customers with strong weekday/weekend behaviour shifts run all experiments in 1-week increments (or 2 weeks for a stricter check) to fully capture each cycle.
  - A `sample_size` end can fire mid-cycle and produce biased results in this case.
- The team has a fixed business window (e.g. "we want to ship by end of quarter").
- The team has historically struggled with experiments running indefinitely.
- The hypothesis specifically requires a calendar window (e.g. a holiday-season test).

### Combinations

All four combinations are valid. The one customers most often miss is **`frequentist + days`** — some teams prefer time-based experiments for operational reasons even when running frequentist tests. Don't flag this as a misconfiguration.

The one that's actually wrong is **`frequentist + sample_size + peeking`** — that's the "peeking trap" above. Surface it; switch them to sequential.

## Confidence level

Default `settings.confidenceLevel: 0.95` (α = 0.05). Change only with intent.

- **`0.99`** — for high-stakes irreversible ships (e.g. billing changes, deletion-flow changes, anything regulatory). Higher false-negative cost; accept it. Document the reason in `description`.
- **`0.90`** — for low-stakes exploratory tests where speed matters more than rigour. Acknowledge the inflated false-positive rate to the user explicitly: at α = 0.10, one in ten "wins" is noise.

Any change away from 0.95 belongs in `description`. The post-launch interpretation step uses this field to read the result correctly; without it, a "win" at 0.90 looks the same as a "win" at 0.95.

## Multiple testing correction

Enable when `len(primary_metrics) ≥ 2` OR `len(non_control_variants) ≥ 2`. Without correction, the family-wise false-positive rate compounds:

| Primaries | Non-control variants | Family-wise FPR at per-test α = 0.05 |
| --------: | -------------------: | -----------------------------------: |
|         1 |                    1 |                                 5.0% |
|         2 |                    1 |                               ~9.75% |
|         3 |                    1 |                               ~14.3% |
|         5 |                    1 |                               ~22.6% |
|         5 |                    2 |                               ~40.1% |
|         5 |                    3 |                               ~53.7% |

The takeaway: by the time you're testing 5 primaries on a 3-arm experiment, more than half of the "wins" are noise.

Two methods are available:

- **`"bonferroni"`** — divides α by the number of tests (`n_primary × n_non_control_variants`). Simple and conservative. Guarantees the family-wise error rate stays below α, but can be overly strict when many primary metrics are correlated, hurting power.
- **`"benjamini-hochberg"`** — controls the **false discovery rate** (FDR) instead of the family-wise error rate. Ranks all primary-metric p-values and applies progressively looser thresholds. More powerful than Bonferroni when there are many primary metrics, especially when some have real effects. Preferred when the user has 3+ primaries or correlated metrics.

**Default to `"benjamini-hochberg"`** for most experiments — less conservative, better suited to typical designs with correlated metrics. Use `"bonferroni"` when:

- The user needs strict family-wise error control (regulatory, high-stakes decisions where any single false positive is unacceptable).
- The primary metrics are independent (no shared drivers / overlapping populations), in which case Bonferroni's conservatism is not a real cost.
- The team explicitly asks for the simplest method to defend in a review.

Set `settings.multipleTestingCorrection: "off"` **only** when there's a single primary and a single non-control variant.

## Power vs significance trade-off

When the user pushes you on `confidenceLevel`:

- Raising α from 0.05 to 0.10 increases power (smaller required sample for the same MDE) but doubles the rate of false-positive "wins."
- Lowering α from 0.05 to 0.01 cuts the false-positive rate fivefold but requires roughly 1.5× the sample for the same MDE.

If the user wants more power without raising α, the right move is **smaller MDE → bigger required sample**, not loosening significance. If sample is the binding constraint, reach for CUPED (`references/advanced-features.md`) or a higher-volume proxy metric.
