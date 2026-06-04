# Session-Replay Analysis Guidance

Open this when the user wants to use session replays to explain a quantitative experiment result — _"why is conversion down in treatment?"_, _"what are users actually doing in the treatment?"_, _"can replays explain the regression?"_. The goal is to turn a number into a behavior story.

> **Tool boundary.** This skill provides the _interpretation_ guidance for replay analysis. The actual replay-fetching tool — pulling replay IDs for control vs treatment cohorts — lives on the platform side (a separate fetch tool exposed alongside `Get-Experiment`, when available). If the fetch tool isn't yet available, say so to the user and recommend the manual flow: pull replays via the experiment's "View replays" UI for each variant, then bring the IDs back to discuss.

---

## When replays help, when they don't

| Question                                                                                 | Replays help?                                                                         |
| ---------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| "Why is conversion lower in treatment?"                                                  | Yes — behavior diff is observable.                                                    |
| "Why is `Checkout Screen Viewed` 10× higher in treatment?" (changed-denominator suspect) | Yes — replays show whether users are _bouncing_ or _converting_ after they get there. |
| "Why is `time_on_page` higher in treatment?"                                             | Yes — distinguishes engaged reading vs confused dwell.                                |
| "Is the treatment shipping a regression on iOS only?"                                    | Sometimes — better answered first by segment breakdown.                               |
| "Why is SRM failing?"                                                                    | No — replays don't show bucketing. Go to health checks.                               |
| "What's the lift?"                                                                       | No — replays are qualitative; they explain _why_, not what.                           |
| "Why hasn't this hit statsig yet?"                                                       | No — that's a sample/power question, not a behavior question.                         |

A useful heuristic: replays answer _behavioral_ questions. If the question isn't behavioral, replays will burn time without adding signal.

---

## Cohort selection: which replays to compare

You're looking for **paired contrast**, not a random sample. Pick the cohort that maximizes signal for the specific question.

| Question                                                             | Cohort A (replays to pull)                                 | Cohort B (replays to pull)                                  |
| -------------------------------------------------------------------- | ---------------------------------------------------------- | ----------------------------------------------------------- |
| Why is primary metric down in treatment?                             | Treatment users who **failed** the primary action          | Control users who **succeeded** at the primary action       |
| Why is a guardrail regression appearing?                             | Treatment users who **triggered** the guardrail negatively | Control users who did NOT trigger it                        |
| Why does treatment have a huge lift in `Screen Viewed` (denom shift) | Treatment users who reached the screen                     | Same users, looking at whether they completed the next step |
| Why is engagement higher / lower in a specific segment?              | Treatment users in that segment                            | Control users in the same segment                           |
| What does the new UI look like in practice?                          | Any treatment users who saw the change                     | Any control users to confirm the baseline UI                |

**Aim for ~5 replays per cohort.** Fewer and you're anecdote-shopping; many more and you'll just confirm what the first 5 already showed. If the first 5 are inconclusive or contradictory, pull 5 more before changing tactics.

Filter by recency — replays from the most recent days of the experiment best reflect steady-state behavior (avoid novelty / primacy noise).

---

## What to actually watch for

Go in with a hypothesis from the quantitative result. Don't watch replays blank-eyed; you'll see "users using the app" and learn nothing.

### Friction / failure patterns

- **Hesitation** — long pause before clicking a key element (often signals confusion).
- **Misclicks** — clicking non-interactive elements, or rage-clicking a button that didn't work.
- **Form abandonment** — typing into a field, then leaving without submitting.
- **Back-button bounce** — landing on the page, then immediately backing out.
- **Scroll-and-leave** — scrolling without engaging, then exiting.

If treatment has more of these than control, you have a behavior explanation for a primary loss or guardrail regression.

### Layout / discoverability issues

- **CTA below the fold** — users never scrolling to where the new button is.
- **Element overlap on mobile** — the treatment looks fine in desktop testing but breaks on small screens.
- **Hidden state** — a tooltip / modal that fires once and is then gone, so the user never sees the key affordance.

These usually explain segment heterogeneity (loss concentrated in mobile, or in a specific viewport size).

### Changed-denominator behavior

If you're investigating a Twyman's-Law-sized lift, look for:

- **Users landing on the new screen and immediately leaving** — explains the inflated `Viewed` event without explaining real conversion.
- **Users completing the rest of the funnel at a much lower rate per-arrival** — explains why the headline metric grew but downstream metrics didn't follow.

If treatment users _arrive_ at a screen more often but _complete_ at a lower per-arrival rate, the "lift" is a denominator artifact and the per-converter behavior is the real story.

### Variant-specific UI issues

- **Treatment showed the wrong copy / wrong asset** — surprisingly common; treatment shipped, but to a subset of routes only.
- **Treatment didn't render at all** — users in the treatment cohort saw the control UI (exposure-tracking bug; bucketing bug). If you see this, route back to [health-check-interpretation.md](health-check-interpretation.md).
- **Treatment fired twice / persisted state across sessions** — implementation regression.

---

## How to frame the findings

Replay analysis is qualitative. Be honest about that.

- ✅ _"In 4 of 5 treatment replays, users hesitated >5 seconds at the new modal then closed it without acting. In 5 of 5 control replays, users clicked through within 2 seconds. This is consistent with the conversion drop in `live_metrics`."_
- ❌ _"Treatment is causing confusion."_ — too strong; n=5 is a hypothesis, not a verdict.

Tie observations back to specific quantitative results from `Get-Experiment`. If the replay story contradicts the numbers, **trust the numbers first** and treat the replays as either a wrong cohort sample or a richer-than-expected behavior.

---

## What NOT to do

- ❌ Use replays to override a clear quantitative verdict. If primaries say "ship" and replays look ugly, the ugliness might be edge cases — confirm with segment analysis first.
- ❌ Cherry-pick a single dramatic replay. n=1 is anecdote.
- ❌ Replace segment analysis with replays. Replays explain _behavior_; segments explain _who_. Different questions.
- ❌ Pull replays from broad cohorts ("all treatment users") — the contrast pair is what reveals signal.
- ❌ Spend more time on replays than on the headline interpretation. The decision tree comes first; replays are the explanation step after it.

---

## Output shape

1. **The quantitative result the replays are explaining** — link back to the specific metric and verdict.
2. **Cohorts watched** — what filters were applied to A and B, how many replays in each.
3. **Patterns observed**, with counts (e.g. "4 of 5 treatment replays showed X; 0 of 5 control replays did").
4. **The explanation hypothesis** — careful to frame as hypothesis ("consistent with"), not as proof.
5. **Recommended next action** — usually one of: ship anyway (regression edge-case), iterate (fix the friction), kill (treatment is materially worse), or run a follow-up A/B with the fix.
