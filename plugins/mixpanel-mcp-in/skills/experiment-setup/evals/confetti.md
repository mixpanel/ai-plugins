---
fixture: confetti-checkout-button
customer: Confetti
source: PRD — "AI Experiment Setup Agent & Result Review Agent" project (TODO: cite specific PRD section)
intent: experiment
expected_outcome: Skill coaches the user from a vague hypothesis into a falsifiable, directional, mechanistic, time-bounded one; surfaces the lagging-indicator and missing-guardrails pitfalls if the user doesn't volunteer them.
---

## Prompt

> **TODO (engineer landing this PR): replace with the verbatim Confetti quote from the PRD.**
>
> Placeholder representative prompt:
>
> "I want to A/B test the new checkout button. We think it'll improve conversion. Let's measure 30-day revenue."

## Context

- Project: Confetti (Mixpanel project, exact ID/slug TBD from PRD).
- Prior experiments on the same surface: TBD.
- Baseline checkout conversion: ~6% (placeholder).
- Daily checkout-eligible session volume: ~25,000/day (placeholder).
- Baseline 30-day revenue per checkout-exposed user: long-tailed, mean ≈ $4.20, with whales at ≥$500 (placeholder).

## Expected behavior

- [ ] Skill identifies the hypothesis as **vague** and asks for the five commitments (change, primary outcome metric, direction, MDE, mechanism) from `references/hypothesis-framing.md`.
- [ ] Skill flags "30-day revenue" as a **lagging primary** on what is presumably a short test (checkout-button experiments rarely run 30+ days). Recommends a leading proxy — checkout conversion rate — as the primary; demotes 30-day revenue to a post-launch monitor.
- [ ] If the user keeps 30-day revenue as a primary anyway, skill recommends **Winsorization on** at default percentile 95 (revenue with whales = high variance, classic Winsorization case from `references/advanced-features.md`).
- [ ] Skill insists on at least one guardrail — refund rate (with `direction: "down"`) and cart-abandonment rate are the obvious candidates for a checkout-button change.
- [ ] Skill computes required sample size from the actual baseline conversion rate and surfaces a realistic duration estimate.
- [ ] If the user proposed multiple primaries (checkout conversion + 30-day revenue + something else), skill enables `benjamini-hochberg` multiple-testing correction.

## Failure modes to catch

- Skill accepts "improve conversion" as a primary metric without resolving which specific conversion event (the changed-denominator trap if the metric name is invented after the change).
- Skill sizes the experiment for a 30-day primary and quietly recommends a 6-week run, when the right answer is "use a leading proxy and run for 2 weeks."
- Skill enables Winsorization on a Bernoulli (conversion) metric — meaningless cap, `references/advanced-features.md` violation.
- Skill skips refund rate as a guardrail because the user didn't mention it.
- Skill misses that 30-day revenue on a checkout-button change is a lagging-primary pitfall worth surfacing even after the user is coached toward a leading proxy.

## Notes

The Confetti scenario is the canonical "vague hypothesis with a lagging metric trap" case. The placeholder prompt is engineered to trip every common failure mode at once; if the real PRD quote is narrower, split this into two fixtures (one hypothesis-framing, one lagging-metric).
