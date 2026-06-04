---
fixture: polarsteps-trip-discovery
customer: Polarsteps
source: PRD — "AI Experiment Setup Agent & Result Review Agent" project (TODO: cite specific PRD section)
intent: experiment
expected_outcome: Skill recommends CUPED for variance reduction on an engagement metric with strong pre-exposure correlation; surfaces underpowered-duration pitfalls if the user requests an unrealistically short run.
---

## Prompt

> **TODO (engineer landing this PR): replace with the verbatim Polarsteps quote from the PRD.**
>
> Placeholder representative prompt:
>
> "We're testing a new trip-discovery feed. We want to measure engagement — trips viewed per user per week. Want to run for 2 weeks; we only have about 30,000 weekly active users."

## Context

- Project: Polarsteps (Mixpanel project, exact ID/slug TBD from PRD).
- Prior experiments on the same surface: TBD — engagement metric likely has prior baseline data the skill should pull via `search_prior_experiments` if available.
- Weekly active users eligible for the experiment: ~30,000 (placeholder, taken from prompt).
- Baseline trips-viewed-per-user-per-week: mean ≈ 8.4, σ² ≈ 22 (Poisson-ish with overdispersion; placeholder).
- Pre-exposure trips-viewed correlation with post-exposure: strong (existing users have stable per-week viewing patterns; placeholder estimate r ≈ 0.65).

## Expected behavior

- [ ] Skill coaches the user to commit to a direction and MDE on "trips viewed per user per week."
- [ ] Skill computes required sample size from the actual baseline mean and variance via `Run-Query`. With σ² ≈ 22 on a mean of 8.4 and (say) 5% relative MDE, the math indicates the requested 2-week duration on 30k WAU may be marginal or insufficient.
- [ ] Skill surfaces `underpowered_duration_marginal` (or `_insufficient` if math says so) per `references/pitfalls.md`.
- [ ] Skill recommends **CUPED on** as the primary lever for variance reduction — Polarsteps users are existing users with stable pre-exposure behaviour on the same metric, which is exactly the CUPED sweet spot from `references/advanced-features.md`. CUPED can reasonably shrink required sample by 30–70% and bring the 2-week duration into the powered range.
- [ ] If trips-viewed has a long tail (a few power users viewing 200+ trips/week), skill also recommends Winsorization on at default 95th percentile.
- [ ] Skill insists on at least one guardrail — Day-7 retention is the obvious candidate for an engagement-feature experiment.
- [ ] Skill defaults to sequential testing model (the team is unlikely to wait the full fixed-horizon run before checking).

## Failure modes to catch

- Skill doesn't recommend CUPED on a metric where pre-exposure data is plentiful and strongly correlated — wastes 30–70% of available sample-size headroom.
- Skill accepts the 2-week request without checking if the experiment is powered; user launches an underpowered test and gets an inconclusive result they don't know how to interpret.
- Skill recommends Winsorization without checking whether trips-viewed has a heavy tail; "always Winsorize" is the wrong default. Winsorization is conditional on tail behaviour.
- Skill picks "weekly active users" as a guardrail on a 2-week test where the experiment itself is intended to _move_ WAU — circular guardrail.
- Skill skips Day-7 retention as a guardrail because the user said "engagement" and didn't say "retention." Engagement experiments very often regress retention via novelty churn.

## Notes

The Polarsteps scenario is the canonical "CUPED to rescue a sample-constrained test" case in the PRD. If the real quote names a different metric or different cohort size, recompute the placeholders and adjust the expected sample-size math.
