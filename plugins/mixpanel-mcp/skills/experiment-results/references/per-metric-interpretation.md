# Per-Metric Interpretation

Open this when the user wants you to translate a metric's lift, confidence interval, and p-value into a plain-language verdict — i.e. _"what does this single row of `summary` actually mean?"_

**Consume, don't recompute.** Read `lift`, `liftConfidence`, `value`, `sampleSize`, and the bucket-derived `significance` ("YES_POSITIVE" / "YES_NEGATIVE" / "NO") from the experiment-details response. Then translate.

---

## The mental model

Each row in `summary.positive` / `summary.negative` / `summary.no` answers four questions:

1. **Did the lift go up or down?** — the `summary` bucket name (sign-of-lift, not polarity).
2. **Was the change distinguishable from noise?** — the `significance` field (or the bucket name itself: rows in `summary.positive` / `summary.negative` are significant, rows in `summary.no` are not).
3. **Was the change in the goal direction?** — apply the polarity recipe with `metric.direction`.
4. **Was the change big enough to matter?** — multiply `lift` by the control baseline `value` to get absolute impact, then judge against business context.

A "win" requires **yes to (2)** AND **yes to (3)** AND **yes to (4)**. Skip any one of those and you're shipping the wrong thing.

---

## Polarity recipe (repeat from the spine — critical)

`metric.direction` is `"up"` or `"down"` (defaults to `"up"`).

- `lift is None` or `lift == 0` → **neutral** (treat as no measurement / no effect respectively).
- `direction == "up"` → **positive** if `lift > 0`, else **negative**.
- `direction == "down"` → **positive** if `lift < 0`, else **negative**.

A metric in `summary.positive` with `direction: "down"` is a **regression**. A metric in `summary.negative` with `direction: "down"` is a **win**. A `-1% interstitials_shown` lift in `summary.negative` with `direction: "down"` is plausibly a **win** (less interruption).

---

## Reading the p-value correctly

The p-value is the probability of observing a difference at least as extreme as the one measured, **assuming the null hypothesis (no real difference) is true**. It is NOT:

- ❌ The probability that the treatment works.
- ❌ The probability the result will replicate.
- ❌ A measure of effect size — a tiny lift can be highly significant on a huge sample.
- ❌ Proof of "no effect" when above threshold (see "Inconclusive results").

Mixpanel uses Welch's t-test (z-test for large samples). Default α = 0.05 at 95% confidence. The confidence level is set on `settings.confidenceLevel`. If it differs from 0.95, call it out in the verdict (`0.9` inflates false positives; `0.99` is conservative).

---

## Reading the lift correctly

```
lift = (treatment_mean - control_mean) / control_mean
```

- `liftConfidence` is the **confidence level used** (e.g. 0.95). It is NOT the confidence-interval width.
- **Total / sum metrics use exposure rebalancing.** If treatment has more exposed users than control, the raw sum will mechanically be higher. The platform computes lift per-exposure already; **don't manually divide raw totals when explaining results** — the `lift` field is correct.
- If `lift is None` in a row, **the calculation failed for that variant.** Surface the failure; do not interpret as "no effect."

---

## Verdict phrasing — a small palette

Pick the phrase that matches the four-question pattern. These are the words to use with users; they map onto the platform's already-computed numbers, so the agent never has to invent thresholds.

| Pattern (sig × polarity × magnitude)                        | Plain-language verdict                                                                                                                                                    |
| ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Significant, polarity positive, magnitude large vs baseline | "**Clear win** — `<metric>` moved `<lift%>` in the goal direction, which is meaningful at this baseline." (apply Twyman's Law if lift > ~30%)                             |
| Significant, polarity positive, magnitude small vs baseline | "**Statistically significant but practically small** — `<lift%>` on a `<baseline>` baseline is `<absolute>`; confirm with the user whether that clears the business bar." |
| Significant, polarity negative                              | "**Regression** — `<metric>` moved `<lift%>` against its goal direction. This is a reason not to ship even if other primaries won."                                       |
| Not significant, lift in goal direction, well-powered       | "**Likely no effect at the detectable size.** The experiment had enough power to detect `<MDE>`; the observed lift is below that threshold."                              |
| Not significant, lift in goal direction, underpowered       | "**Inconclusive — too underpowered to call.** Route to the why-no-statsig playbook to decide between wait / extend / restart."                                            |
| Not significant, lift in wrong direction                    | "**No detectable harm**, but no win either."                                                                                                                              |
| `lift is None`                                              | "**No measurement** — this variant's row failed to compute. Surface the failure and re-sync."                                                                             |
| Lift > ~30% on any metric                                   | Prefix with "**Twyman's Law check:** that lift is unusually large; verify the denominator hasn't changed before celebrating."                                             |

---

## Magnitude — make it absolute

Statistical significance ≠ business impact. Always convert a win into absolute terms before declaring it meaningful:

1. Baseline from the control variant: `live_metrics[metricId][controlKey].value` (or the `summary.no` row where `variant == controlKey`).
2. Lift from the winning row.
3. Absolute lift: `baseline_value × lift`. Examples:
   - `baseline = 0.02`, `lift = 0.04` → `+0.0008` → **+0.08 percentage points** of conversion rate.
   - `baseline = 12.4 events/user/week`, `lift = -0.05` → `-0.62 events/user/week`.
4. Project to population per period: ask the user for traffic estimates if not in context. "A 5% lift on a 20% baseline metric serving 1M users/week" sounds very different from "a 5% lift on a 0.1% baseline metric serving 1k users/week."

### Fallback when `value` / `sampleSize` are null

Common — happens whenever live computation timed out or `results_cache.metrics` was nulled. Don't silently skip practical significance; **a broken-data summary with only the lift number is exactly when users over-trust the percentage.**

Run a query on the metric, scoped to the control variant over the experiment's date range, to fetch the baseline. Match the metric's aggregation:

- `unique` (Bernoulli) → conversion **rate** as the baseline.
- `total` (Poisson / sum) → per-exposure **average** (raw total ÷ exposures), not the raw total. Multiplying lift by a raw total double-counts cohort size.

---

## Twyman's Law in practice — changed-denominator lifts

Before celebrating any lift > ~30%, ask: **did the treatment change who is _exposed_ to this metric, not just how they behave?**

If the treatment causes more users to _see_ a screen, more events naturally fire — the metric grows because the denominator changed, not because per-user behavior changed.

- A "Free item" promotion drives more users to checkout → "Checkout Screen Viewed" lifts +1000% mechanically. The interesting question is **conversion rate on the screen**, not raw views.
- A new banner makes a feature discoverable → "Feature Page Viewed" lifts dramatically. **Per-discover-er behavior** may be unchanged.

When you see a > 30% lift, name the risk explicitly:

> _"This metric measures exposure to the screen/event. The treatment likely caused more users to be exposed; that explains most of the lift mechanically. The interesting question is what those users did once they got there."_

---

## Metric distribution types

Different metric types behave differently; cite the relevant nuance in your verdict.

| Metric type                      | Distribution | Interpretation nuance                                                                                     |
| -------------------------------- | ------------ | --------------------------------------------------------------------------------------------------------- |
| Unique users / conversion rate   | Bernoulli    | Variance = `p(1−p)`. Lift on rates near 50% is most powered; rates near 0% or 100% need much more sample. |
| Event counts / sessions per user | Poisson      | Variance = mean. Highly sensitive to power users; consider whether one heavy user can swing results.      |
| Revenue / numeric properties     | Gaussian     | Long tails (whales) inflate variance. Strongly consider Winsorization.                                    |

---

## Variance-reduction & outlier settings that change interpretation

- **CUPED** (`settings.cuped.enabled == true`): mean is unchanged; variance reduced 30–70%; CIs narrower; power higher. Note: CUPED requires users to exist before the experiment — new-user-only experiments cannot use CUPED; if it's enabled there, it had no effect (mention as informational, not as a misconfiguration to fix).
- **Winsorization** (`settings.winsorization.enabled == true`): extreme values capped at the configured percentiles, pooled across variants. Lifts reflect typical-user behavior, not whale behavior. Bernoulli (conversion) metrics ignore Winsorization. A `percentile` much lower than the default 95 is a misconfiguration (see `health-check-interpretation.md` §Misconfig).

---

## Multiple comparisons & metric tiers — what's decisional and what isn't

| Tier          | How it influences the verdict                                                                                                                                                                                 |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Primary**   | **Decisional.** The platform auto-applies correction when `multipleTestingCorrection` is `"bonferroni"` or `"benjamini-hochberg"` (across primaries × variants).                                              |
| **Guardrail** | **Vetoes** a ship if polarity is negative with meaningful magnitude.                                                                                                                                          |
| **Secondary** | **Exploratory only.** NOT Bonferroni-corrected. **Never base a ship decision on secondary metrics**, even if the hypothesis text references them. Treat any "significance" here as a hypothesis to test next. |

If `settings.multipleTestingCorrection` is `"off"` AND there are 2+ primaries × 1+ non-control variants: don't auto-discount a single significant primary, but look at the aggregate. If most primaries point the same direction, there's likely a real effect. If only one or two of many are significant, it's inconclusive until correction is enabled.

---

## "Significance = NO" does NOT mean "no effect"

A row in `summary.no` means the experiment didn't have enough signal to distinguish the effect from noise at the chosen confidence level. **Important when the user is about to call something a null result.**

Options to suggest when a primary metric lands in `summary.no`:

1. **Extend duration** (if the experiment is still ACTIVE).
2. **Increase traffic allocation** (if there's headroom — never mid-Frequentist-test, which invalidates SRM).
3. **Use Sequential testing model** for the next experiment if continuous monitoring fits.
4. **Enable CUPED** if the metric correlates with pre-exposure behavior.
5. **Narrow the hypothesis** — test a stronger version, or scope to a more responsive segment.
6. **Accept the null** — if the experiment was well-powered for the MDE that matters, "no effect" is a real finding.

For the full "why hasn't this hit statsig yet" walk-through, see [why-no-statsig.md](why-no-statsig.md).

---

## Frequentist vs Sequential — what affects per-metric reading

Check `settings.testingModel`:

- `"frequentist"` — pre-defined sample size or duration. **Peeking inflates the false-positive rate.** If the user concluded before reaching the configured target, every per-metric significance verdict is suspect. Note: frequentist + `endCondition: "days"` is supported intentionally — do not flag the combination itself as a misconfiguration.
- `"sequential"` — designed for continuous monitoring. Stopping early when significance is reached is safe and intended.

Concluding a Frequentist experiment before it reaches its target is a peeking event. Flag it in the verdict.

---

## Triggered analysis & dilution

If the change only affects a subset of users (e.g. only triggers when a specific button is shown), the **effect on triggered users** is much larger than the **effect on the full exposed population**.

- Triggered analysis zooms in on users who actually saw the change.
- Dilution math: `population_lift = triggered_lift × (triggered_users / total_exposed)`.

The platform doesn't auto-compute triggered analysis. If the change is gated by a condition, ask the user about the trigger rate and walk through the math before declaring the population-level lift "small."

---

## Novelty and primacy

- **Novelty** — lift is large early, then decays as users habituate.
- **Primacy** — lift is small or negative early, then grows as users learn the new behavior.

To detect either, look at the line-chart view of the metric (date-segmented). A monotonic decay from day 1 → day 14 is classic novelty; the steady-state lift is what matters for shipping. Call this out when interpreting any experiment shorter than ~2 weeks.
