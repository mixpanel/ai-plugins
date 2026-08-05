# Per-Metric Interpretation

Translate a metric's lift, confidence interval, and p-value into a plain-language verdict — i.e. _"what does this single result row actually mean?"_

## Contents

- The mental model
- Polarity recipe
- Reading the p-value in this platform
- Reading the lift correctly
- Verdict phrasing — a small palette
- Magnitude — make it absolute
- Twyman's Law in practice — changed-denominator lifts
- Metric distribution types
- Variance-reduction & outlier settings that change interpretation
- Multiple comparisons & metric tiers — what's decisional and what isn't
- When a primary metric is inconclusive
- Frequentist vs Sequential — what affects per-metric reading
- Triggered analysis & dilution
- Novelty and primacy

---

## The mental model

Each row (positive / negative / no-effect bucket) answers four questions:

1. **Did the lift go up or down?** — the bucket name (sign-of-lift, not polarity).
2. **Was the change distinguishable from noise?** — the significance classification (or the bucket name itself: positive / negative buckets are significant, the no-effect bucket is not).
3. **Was the change in the goal direction?** — apply the polarity recipe with the metric's direction.
4. **Was the change big enough to matter?** — multiply lift by the control baseline value to get absolute impact, then judge against business context.

A "win" requires **yes to (2)** AND **yes to (3)** AND **yes to (4)**. Skip any one of those and you're shipping the wrong thing.

---

## Polarity recipe

Apply the **canonical polarity recipe** (defined in the interpret command's Components): the bucket name is sign-of-lift only; the business verdict comes from combining that sign with the metric's **Direction** (Shared glossary in `SKILL.md`). Re-apply it on every row here — a positive-sign movement on a "down" metric is a regression, not a win. Examples worth remembering:

- A positive-bucket row on a "down" metric is a **regression**.
- A negative-bucket row on a "down" metric is a **win** (e.g. a -1% interstitials_shown lift means less interruption).

---

## Reading the p-value in this platform

Mixpanel runs a frequentist comparison at the experiment's configured confidence level — typically 0.95 (verify in product if results look off). If it differs from 0.95, call it out (`0.9` inflates false positives; `0.99` is conservative).

The platform-specific trap worth flagging: the confidence figure shown on each result row is the **confidence level used** (e.g. 0.95), **not the CI width**. Easy to misread.

For the general meaning of a p-value (the probability under the null), trust the model's baseline knowledge — don't invent thresholds in either direction.

---

## Reading the lift correctly

```
lift = (treatment_mean - control_mean) / control_mean
```

- **Total / sum metrics use exposure rebalancing.** If treatment has more exposed users than control, the raw sum will mechanically be higher. The platform computes lift per-exposure already; **don't manually divide raw totals when explaining results** — the reported lift is correct.
- If a row's lift is missing, **the calculation failed for that variant.** Surface the failure; do not interpret as "no effect."

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

1. Baseline from the control variant's metric value (the experiment-details response carries it on the per-variant row).
2. Lift from the winning row.
3. Absolute lift: `baseline × lift`. Examples:
   - `baseline = 0.02`, `lift = 0.04` → `+0.0008` → **+0.08 percentage points** of conversion rate.
   - `baseline = 12.4 events/user/week`, `lift = -0.05` → `-0.62 events/user/week`.
4. Project to population per period: ask the user for traffic estimates if not in context. "A 5% lift on a 20% baseline metric serving 1M users/week" sounds very different from "a 5% lift on a 0.1% baseline metric serving 1k users/week."

### Fallback when the baseline value or sample size is missing

Common — happens whenever live computation timed out or the cached results were nulled. Don't silently skip practical significance; **a broken-data summary with only the lift number is exactly when users over-trust the percentage.**

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

- **CUPED enabled**: mean is unchanged; variance reduced 30–70%; CIs narrower; power higher. Note: CUPED requires users to exist before the experiment — new-user-only experiments cannot use CUPED; if it's enabled there, it had no effect (mention as informational, not as a misconfiguration to fix).
- **Winsorization enabled**: extreme values capped at both tails, pooled across variants. The tail-width setting defaults to 5 (5% tails). Lifts reflect typical-user behavior, not whale behavior. Bernoulli (conversion) metrics ignore Winsorization. A much higher tail width — capping more than ~20% of each side — is a misconfiguration; see the Misconfigurations notes in the health-check interpretation reference.

---

## Multiple comparisons & metric tiers — what's decisional and what isn't

| Tier          | How it influences the verdict                                                                                                                                                                                 |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Primary**   | **Decisional.** The platform auto-applies correction when the experiment is configured for Bonferroni or Benjamini-Hochberg (across primaries × variants).                                                    |
| **Guardrail** | **Vetoes** a ship if polarity is negative with meaningful magnitude.                                                                                                                                          |
| **Secondary** | **Exploratory only.** NOT Bonferroni-corrected. **Never base a ship decision on secondary metrics**, even if the hypothesis text references them. Treat any "significance" here as a hypothesis to test next. |

If multiple-testing correction is off AND there are 2+ primaries × 1+ non-control variants: don't auto-discount a single significant primary, but look at the aggregate. If most primaries point the same direction, there's likely a real effect. If only one or two of many are significant, it's inconclusive until correction is enabled.

---

## When a primary metric is inconclusive

A "not significant" verdict means the experiment didn't have enough signal to distinguish the effect from noise at the chosen confidence level — **not that there is no effect.** Important when the user is about to call something a null result.

For the full walk-through on what to do about it (wait, extend, boost power, narrow, accept null), see the why-no-statsig playbook.

---

## Frequentist vs Sequential — what affects per-metric reading

Concluding a Frequentist experiment before it reaches its configured target is a peeking event — per-metric significance verdicts become unreliable. Sequential experiments are designed for continuous monitoring and don't have this problem.

For the full diagnosis when peeking is suspected, see the **Frequentist peeking** section of the health-check interpretation reference.

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
