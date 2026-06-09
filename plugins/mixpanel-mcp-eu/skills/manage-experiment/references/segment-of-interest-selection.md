# Segment-of-Interest Selection

Pick 3–5 segments **likely to reveal a real effect difference** before slicing every available dimension and ending up p-hacking.

The companion reference [segment-breakdown-interpretation.md](segment-breakdown-interpretation.md) covers how to _read_ the per-segment results once you have them.

---

## Why this matters: the fishing-expedition problem

If you slice an experiment by every available property (10 platforms × 20 countries × 5 plan tiers × …), you will find "significant" segment-level effects by chance alone. The family-wise false positive rate explodes the same way it does for too many primary metrics — except there's usually no platform-level correction across segments. **Pre-committing to a small set of segments, ordered by hypothesis-driven probability, is the discipline that makes segment analysis credible.**

Aim for 3–5 segments, max. If the user wants more, ask which ones are connected to the hypothesis and which are exploration. Mark the exploration set as "hypothesis-generating, not decisional."

---

## The decision tree for picking segments

Walk through these in order. The first match is the most defensible pick.

### 1. Segments the hypothesis explicitly names

If the experiment's `hypothesis` (or `description`) text mentions "new users", "mobile", "Pro tier", "EU customers" — those segments are pre-committed by the experiment design. Always include them.

Look at:

- `experiment.hypothesis`
- `experiment.description`
- The setup-side conversation, if present

These are not exploratory; they're the variables the team committed to test.

### 2. Segments where the mechanism is expected to matter

The hypothesis names _what_ the change is and (ideally) _why_ it should work. The "why" tells you which user attributes plausibly moderate the effect:

| Hypothesis mechanism                              | Segments likely to moderate the effect             |
| ------------------------------------------------- | -------------------------------------------------- |
| "Reduces first-time friction in onboarding"       | New vs returning; signup source; locale            |
| "Improves discoverability of feature X"           | Users who previously used X vs not; tenure         |
| "Speeds up a slow flow"                           | Platform (mobile slower than web); connection type |
| "Lowers payment friction"                         | Plan tier; payment-method type; geography          |
| "Replaces a confusing UI element"                 | New vs returning (returning users habituated)      |
| "Surfaces a feature only relevant to power users" | Engagement-tier cohorts; tenure                    |
| "Localized copy / pricing change"                 | Country / language                                 |

If you can't articulate _why_ a segment should respond differently, it's not a hypothesis-driven slice. Demote it.

### 3. Segments where the **denominator** plausibly differs

Some properties don't change _behavior_ but change _who gets exposed_. Slicing on these helps catch changed-denominator artifacts before they're called a win.

- Triggered vs untriggered cohorts (if the treatment only fires on certain pages).
- Platform / app version (the treatment may only ship on a subset of clients).
- Device class (mobile vs desktop) when the change is platform-specific.

A 1000% lift in `Checkout Screen Viewed` overall usually disappears once you condition on "users who reached the checkout funnel" — that disappearance is the finding.

### 4. Segments where SRM or baseline shift is suspected

If overall SRM is borderline (or failing in one variant only), per-segment SRM can localize the bucketing bug to a specific platform / country / cohort. Examples:

- iOS vs Android (often the SDK bucketing layer differs).
- Bot-suspicious countries (`bot_traffic` cause from health-check).
- A specific app version range that shipped a flag-evaluation change.

This is diagnostic segmentation, not interpretation segmentation. Use it when the **trustworthiness gate** has already flagged trouble.

### 5. Segments the platform de facto requires

Some user dimensions are so foundational that any results report should mention them once:

- **Platform** — web vs iOS vs Android.
- **New vs returning** — defined as first session within the experiment window vs before.
- **Geo region** — EU vs US vs APAC, when results meaningfully differ by regulatory or payment context.

Don't include all three blindly — pick the one(s) most likely to vary given the change.

---

## Sanity checks before committing to a slice

For each segment you want to break down on:

1. **Does each segment value have enough exposed users per variant to clear the platform's overall sufficiency threshold?** Below that, the per-segment stats are unreliable. If not, suggest pooling small segments or extending the experiment.
2. **Is the segmenting property captured for both control and treatment users?** (It almost always is, but verify.) A property only set when the treatment fires is not a valid segmenting axis.
3. **Is the segment defined the same way in pre- and during-experiment data?** Drifting definitions (e.g. "Pro tier" boundaries changed mid-test) invalidate the comparison.
4. **Is the segment determined _before_ exposure?** Segments derived from in-experiment behavior are post-treatment effects, not user attributes — slicing on them is selection-bias, not stratification.

---

## How many slices to commit to

| Situation                                                         | Number of slices                |
| ----------------------------------------------------------------- | ------------------------------- |
| Hypothesis-driven, well-powered, decisional                       | 3–5 segments, named upfront     |
| Exploratory ("anything weird?"), flagged as hypothesis-generating | Up to ~10, with explicit caveat |
| Diagnostic (chasing a failing SRM or strange overall result)      | Whatever helps localize the bug |

If the user wants to "just look at everything", push back: pick the top 3–5 with reasoning, then offer a separate exploratory pass that won't be used for the ship decision.

---

## The pre-commit ritual

Before running the breakdowns, tell the user something like:

> _"Based on the hypothesis (`<one-line summary>`), I'd slice by `<segment A>` and `<segment B>` because `<why each matters>`. I'm intentionally not slicing `<X, Y, Z>` because they don't connect to the proposed mechanism — looking at every dimension makes false positives almost guaranteed. We can do an exploratory pass after, separately from the ship decision. Sound right?"_

Pre-commitment is what separates "segmentation analysis" from "fishing."

---

## Then read the results

Once the segment breakdown is in hand, switch to [segment-breakdown-interpretation.md](segment-breakdown-interpretation.md). The reading rules (Simpson's paradox, per-segment polarity, sample-size floor per segment) live there.
