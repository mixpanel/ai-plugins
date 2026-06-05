# Sizing the experiment

You almost never know the right sample size by guessing. Pull the data first, then run the math.

## The standard formula

Required sample size per variant (two-sample, two-sided test at 95% confidence, 80% power):

```
n = 16 × σ² / d²
```

Where:

- `σ²` = variance of the metric (depends on metric type — see below).
- `d` = MDE in the same units as the metric.

The `16` is `(z_{α/2} + z_{β})² × 2` rounded to a workable constant — `(1.96 + 0.84)² × 2 = 15.68 ≈ 16`. Good enough for setup-phase reasoning; for ship-decision rigour use the precise formula in `references/statistical-model.md`.

## Variance by metric type

- **Bernoulli (conversion rate).** `σ² = p(1−p)` where `p` is the baseline conversion rate. Variance peaks at `p = 0.5` (variance 0.25) and shrinks toward 0 at `p = 0` or `p = 1`. Lifts are easier to detect on rates near 50%, harder near the extremes.
- **Poisson (event counts per user).** `σ² ≈ mean count per user`. High-count metrics need proportionally more sample.
- **Gaussian (revenue, time-on-page, etc.).** Compute `σ²` from historical data directly. Long-tailed distributions have high variance — Winsorization (`references/advanced-features.md`) cuts this.

## Worked example

Detecting a 5% **relative** lift on a 10% baseline conversion rate at 80% power, 95% confidence:

```
p              = 0.10
σ²             = 0.10 × 0.90 = 0.09
absolute MDE   = 0.10 × 0.05 = 0.005
n              = 16 × 0.09 / 0.005² = 16 × 0.09 / 0.000025 = 57,600 per variant
```

That's ~57,600 per variant for a 5% relative lift — humbling, and surprising to most teams. Most "we'll just run it for two weeks" plans don't survive contact with this number.

## Kohavi's inverted formula

For most online experiments, traffic is the constraint, not patience. Pick a duration (2–4 weeks captures weekly cycles), use all available traffic in that window, then compute the **achievable MDE**:

```
MDE = 4σ / √n
```

This tells the user: "given your traffic, the smallest effect you can reliably detect is X." If that achievable MDE is larger than the lift the user actually expects, the experiment is **underpowered**. Flag immediately.

Underpowered experiments suffer from **winner's curse**: if you do reach significance, the lift estimate is exaggerated, because only the high-variance positive realisations crossed the threshold. The post-launch result then fails to replicate, and the team learns "experiments are unreliable" rather than "this experiment was underpowered."

## Estimating the inputs from real data

For each primary metric, before sizing, you need three numbers:

1. **Baseline rate** — query the metric over the prior 2–4 weeks (the longer of: one full business cycle, or four weeks). Record `mean` and `variance`. Use the same event definition, segment filters, and unit-of-analysis you'll use in the experiment — a baseline computed differently from how the metric is configured in the experiment is worse than no baseline at all.
2. **Daily traffic** — query the exposure event (or whatever event qualifies users for the experiment) over the same window, grouped by day. Average to get expected exposures per day per variant.
3. **MDE the user wants** — ask explicitly. _"What's the smallest lift that would be worth shipping?"_ If they don't know, propose a 5–10% relative lift and confirm.

From those three:

```
required_sample_per_variant = 16 × σ² / (baseline × MDE_relative)²
required_days               = required_sample_per_variant × n_variants / daily_traffic_per_variant
```

If `required_days > 28` (four weeks), the experiment is **underpowered for the requested MDE on available traffic**. Tell the user. Don't wave it through.

## Five remediations when the experiment is underpowered

Offer these in order of cost — cheap first.

1. **Accept a larger MDE.** Only commit to ship if the effect is bigger. This costs nothing but redraws the success criterion; confirm the user is OK with shipping only on a larger lift.
2. **Increase traffic allocation to the experiment.** If other tests don't need the traffic, give this one more.
3. **Use CUPED to reduce variance** (if pre-exposure data is available). 30–70% variance reduction translates directly into 30–70% smaller required sample. See `references/advanced-features.md`.
4. **Pick a higher-volume primary metric** (if the hypothesis allows). Often there's a leading proxy with more volume than the lagging metric the team originally chose.
5. **Don't run the experiment.** Invest the engineering elsewhere. Sometimes the right answer.

## Sample-size floor

Independent of the math: never set `sampleSize` below ~350–400 per variant. Below this, the statistical machinery itself becomes unreliable — CLT breaks down, the SRM check gets noisy. The Mixpanel default of 10,000 per variant is fine for most tests; 1,000 is the practical floor; 350–400 is the absolute floor.

If the math says `n = 50` per variant, the test is either trivially easy (the lift is huge) or the variance estimate is wrong. Sanity-check before launching at the floor.

## Lookup table (Bernoulli, 95% conf, 80% power)

For a Bernoulli (conversion-rate) primary metric at 95% confidence, 80% power, two-sided test, MDE expressed as a **relative** lift on the baseline:

| Baseline rate | MDE = 5% relative | MDE = 10% relative | MDE = 20% relative |
| ------------- | ----------------- | ------------------ | ------------------ |
| 1%            | ~633k / variant   | ~158k / variant    | ~40k / variant     |
| 5%            | ~122k / variant   | ~31k / variant     | ~7.6k / variant    |
| 10%           | ~58k / variant    | ~14k / variant     | ~3.6k / variant    |
| 25%           | ~19k / variant    | ~4.8k / variant    | ~1.2k / variant    |
| 50%           | ~6.4k / variant   | ~1.6k / variant    | ~400 / variant     |

Use this for quick sanity-checking. Always confirm with a query against actual baseline data — these are illustrative.

## Sample-size growth with variants

For a multi-arm test (N non-control variants), the per-variant target grows with the number of pairwise comparisons being made (each treatment vs control). With multiple-testing correction enabled (which is the right default at 2+ variants), the per-test α tightens, which inflates required sample size further.

Rule of thumb: a 3-variant test (control + 2 treatments) needs about 1.3× the per-arm sample of a 2-variant test for the same MDE; a 4-variant test needs about 1.5×. Exact multipliers depend on the correction method — see `references/advanced-features.md`.

## Duration considerations

- **Minimum 1 week** — anything shorter misses weekly seasonality and conflates the day-of-week mix between control and treatment if traffic differs across days.
- **Minimum 3 days for read-out** — even with sequential testing and big effects, results under 3 days are typically un-interpretable (cohort hasn't stabilised, day-of-week effects dominate, novelty effect not separated from treatment effect).
- **Multiples of the seasonal cycle.** If the primary metric has strong weekly seasonality, set `endCondition: "days"` and choose 7, 14, 21, or 28 days so each variant sees the same mix of high- and low-traffic periods.
- **Cap at ~6 weeks** for most tests — beyond this, novelty effects wear off, the user population drifts, and other experiments running in the same window create cross-test contamination. If the math says you need 8+ weeks, you're underpowered — pick a remediation from the list above.
