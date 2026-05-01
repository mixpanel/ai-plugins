# Reading Funnel charts — reference

Use this reference when the chart being analyzed is a **Funnel**.

---

## What to read first

1. **Top-line conversion rate** — entry to final step. State as a %.

2. **Where the biggest drop-off is** — identify the step with the
   largest absolute % drop, not the largest absolute user drop. (A
   step that loses 50% of 100 users matters more than one that loses
   5% of 1M users when you're talking about conversion quality.)

3. **Trend over time** — if the funnel is shown as a time series
   (conversion % over weeks/days), is it improving or degrading?

4. **Cohort segments** — if the funnel has a breakdown (by source,
   plan, platform), which segment converts best? Worst?

---

## Patterns to flag

### Surprising step where users drop

Funnels are intuitive when drop-off is concentrated at known friction
points (e.g., payment step). Flag when it's not — when users drop at
an unexpected step.

> Flag as: *"Most drop-off is at [step] — usually I'd expect [other
> step] to be the friction point. Worth checking if something changed
> on that page."*

### Conversion rate collapse

If the headline conversion rate dropped sharply over the time series,
identify which step caused it. The drop is rarely uniform — usually
one step regressed.

> Flag as: *"Conversion fell from X% to Y% over the window — the
> regression is concentrated at the [step] step."*

### Conversion rate looks too high or too low

Some patterns are physically suspicious:
- Final-step conversion >95% is rarely real — usually means the funnel
  steps are too lenient (each step almost guaranteed to fire after the
  previous)
- Final-step conversion <1% might be a definitional issue — wrong
  conversion window, wrong step ordering, or a step that genuinely
  shouldn't be in the funnel

> Flag as: *"Conversion of X% looks [implausibly high / implausibly
> low] — worth sanity-checking the funnel definition."*

### Step ordering looks wrong

If the absolute count at step 2 is *higher* than step 1, the funnel is
misconfigured (steps are out of order, or the user did the steps in a
different order than the funnel assumes).

> Flag as: *"Step counts don't decrease monotonically — step ordering
> may be wrong. Cart should usually come before Checkout."*

### Cohort divergence

If a breakdown shows one cohort converting at 60% and another at 5% on
the same funnel, that's the headline finding. The funnel isn't really
"the funnel" — it's two different user experiences.

> Flag as: *"[Cohort A] converts at X%, [Cohort B] at Y%. The headline
> rate hides a 10x gap between segments."*

### Time-to-convert anomaly

If the funnel chart includes time-to-convert distribution, flag if the
median time-to-convert is suspiciously fast (test traffic, bots) or
very slow (might mean conversion window is too generous and counting
unrelated activity).

---

## Common reader pitfalls

**Reading absolute numbers instead of conversion rates**
"100 users completed checkout" is a volume statement, not a funnel
performance statement. The funnel is about rates.

**Confusing per-step % with cumulative %**
Each step's drop can be reported as % of previous step or % of entry.
Mixing these gives wrong answers. Always be explicit which one is
being summarized.

**Mistaking volume change for conversion change**
A funnel can have flat conversion rates but lower entry volume — the
headline metric is the rate, not how many users entered.

**Conversion window mismatch**
A funnel with a 1-hour window will show worse conversion than the
same funnel with a 7-day window. Make sure the window is appropriate
for the user behavior being measured before flagging the rate as low.

---

## Output focus

Funnel summary should answer:
- What's the headline conversion rate?
- Where's the biggest drop-off?
- Is the drop-off pattern consistent or has it shifted?

Skip:
- Reorganizing the steps (that's a build task — `create-chart`)
- Hypothesis on causes ("the payment page might be slow" — that's
  `mxp-metric-diagnosis`)
