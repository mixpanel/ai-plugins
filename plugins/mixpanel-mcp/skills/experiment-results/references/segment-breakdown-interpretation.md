# Segment-Breakdown Interpretation

Open this when the user has per-segment results in hand and wants to read them. The companion reference [segment-of-interest-selection.md](segment-of-interest-selection.md) covers how to pick the segments in the first place.

> **Platform support status.** Reading segment-level experiment results depends on the platform exposing per-segment metric rows. While that's still in progress, this skill may need to fall back to running per-segment queries against the experiment's metrics and exposures, then interpreting the resulting numbers with the same rules below. If the experiment-details response doesn't return segmented data and the user wants per-segment interpretation, say so explicitly and offer the per-segment query fallback — do not invent per-segment significance verdicts.

---

## The mental model

A segment breakdown asks: _did the treatment affect different user segments differently?_ It has three possible outcomes per segment:

1. **The segment moved in the same direction as the overall effect**, with similar magnitude → reinforces the overall verdict; nothing new.
2. **The segment moved much more or less than overall**, but in the same direction → heterogeneity; the effect is concentrated in a subset.
3. **The segment moved in the _opposite_ direction** to overall → Simpson's paradox or a real reversal — this is where segment analysis earns its keep.

Reading a segment breakdown well means recognizing which of those three you're looking at and not mistaking noise for any of them.

---

## Per-segment polarity recipe — apply per row

The same recipe from the per-metric reference applies _inside_ each segment. Don't take a shortcut.

- For each segment × metric × non-control variant, look at the row's `lift` and bucket (positive/negative/no).
- Translate sign-of-lift into business polarity using `metric.direction`. **The bucket name is sign-of-lift, never the business verdict** — same trap as the overall summary.
- Filter out the control row in each segment.

Surprisingly easy to forget when you're scanning a wide table — re-apply polarity per row.

---

## Sample-size floor per segment

Each segment value needs its own meaningful per-variant sample for the per-segment stats to be reliable. As a rule of thumb, the same ~350-per-variant floor used for overall trustworthiness applies per segment.

- Segments below the floor → mark "insufficient sample, treat as directional only."
- A "significant" lift on a 50-user-per-variant segment is almost always noise. Say so.
- If many small segments matter to the user, pool them (e.g. all small countries into "RoW") and re-slice.

---

## Heterogeneity vs Simpson's paradox vs noise

| What you see                                                                                        | Interpretation                                                                                                                                             |
| --------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Most segments lift positive, one or two negative, all with overlapping CIs                          | **Noise.** Not heterogeneity. Don't ship a segment-specific story.                                                                                         |
| One segment lifts much more than the rest, with a tight CI and a clear mechanism                    | **Real heterogeneity.** The change is concentrated in that segment. Consider shipping only to that segment, or revising the hypothesis.                    |
| Every segment shows treatment winning, but the overall metric shows control winning (or vice versa) | **Simpson's paradox.** The variant mix differs across segments. Run per-segment SRM checks — this often signals a bucketing bug rather than a real effect. |
| Two opposite-direction effects in different segments that roughly cancel overall                    | **Mixed effects.** The headline says "no effect" but real winners and losers are hiding. The product question is whether the gains outweigh the losses.    |

When you spot Simpson's paradox, route the user to [health-check-interpretation.md](health-check-interpretation.md) §SRM — it's usually the cause, not a real reversal.

---

## What a "ship only to segment X" recommendation requires

Don't recommend a segment-scoped ship unless **all** of these hold:

1. The segment was named in the hypothesis upfront (pre-committed), OR the mechanism makes the heterogeneity obvious in hindsight (and you can articulate it).
2. The segment's per-variant sample clears the ~350 floor by a comfortable margin.
3. The segment's overall result (polarity-corrected) is a win on the primary metric with no guardrail regressions in that segment.
4. Guardrail behavior in the **other** segments is acceptable — shipping to one cohort doesn't quietly regress the rest of the product.
5. Multiple-testing correction is enabled, OR the segment was named upfront so multiple-testing doesn't apply.

Otherwise, the segment-only ship is a post-hoc story dressed up as a decision. Recommend confirming with a follow-up experiment scoped to that segment.

---

## When a segment loses but overall wins

This is the everyday case of mixed effects.

- If the losing segment is small and its absolute hit is acceptable, ship to all — but call out the loser in the rationale.
- If the losing segment is large or has a guardrail regression, recommend iterate, not ship.
- If the losing segment is a regulated / strategic cohort (paying tier, top customers, EU), default to iterate — guardrails on the cohort, not just overall.

---

## What NOT to do

- ❌ Slice by every dimension after the fact and report the most significant segment as the result — that's the canonical fishing expedition.
- ❌ Apply overall multiple-testing correction logic to segment-level rows from a per-segment query fallback — they're not corrected unless the platform did it.
- ❌ Confuse Simpson's paradox with a real reversal — check SRM per segment before claiming a true reversal.
- ❌ Recommend ship-to-segment based on a segment that wasn't pre-committed in the hypothesis or doesn't have a clean mechanism.
- ❌ Quote a per-segment lift number without the sample-size context (a 40% lift on 60 users isn't a number, it's a sentence).

---

## Output shape

1. **One-sentence segment-level summary** — homogeneous, heterogeneous, or Simpson's-suspicious.
2. **Per-segment table** — segment, exposed-per-variant, polarity-corrected verdict (win / loss / no effect / underpowered).
3. **What the segment view changes about the overall verdict** — usually one of: nothing, narrow to subset, iterate due to one cohort, or "investigate Simpson's."
4. **Caveats** — which segments are below the sample floor, which weren't pre-committed (and so are hypothesis-generating).
