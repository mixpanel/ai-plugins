---
fixture: pelando-onboarding-rollout
customer: Pelando
source: PRD — "AI Experiment Setup Agent & Result Review Agent" project (TODO: cite specific PRD section)
intent: ambiguous
expected_outcome: Skill routes to XP-vs-FF disambiguation, then walks the user through a proper experiment setup once intent is confirmed.
---

## Prompt

> **TODO (engineer landing this PR): replace with the verbatim Pelando quote from the PRD.**
>
> Placeholder representative prompt:
>
> "We're rolling out a redesigned onboarding flow. Can you set up an A/B test? We want to ship to 10% first and ramp from there if nothing breaks."

## Context

- Project: Pelando (Mixpanel project, exact ID/slug TBD from PRD).
- Prior experiments on the same surface: TBD (re-check with the engineer who landed the skill — the eval should run `search_prior_experiments` and exercise the prior-experiments code path).
- Baseline rate on signup→activation: ~12% (placeholder, replace with PRD-cited number if available).
- Daily new-user volume eligible for the experiment: ~8,000/day (placeholder).

## Expected behavior

- [ ] Skill detects the "ship to 10% first, ramp if nothing breaks" framing as **feature-flag intent**, not experiment intent, and asks the disambiguation question from `references/routing-xp-vs-ff.md`.
- [ ] If the user clarifies they _do_ want to measure causal impact on signup→activation conversion, skill routes back to the experiment workflow.
- [ ] If the user clarifies they _don't_ want a stopping rule, skill exits cleanly with "this is a feature flag, here's how to set one up; the experiment skill stops here."
- [ ] On the experiment path: coaches hypothesis (mechanism: which specific change in the redesign drives which specific user behaviour?).
- [ ] On the experiment path: pulls baseline signup→activation rate and exposure-event volume via `Run-Query`; computes required sample size; flags if 10% allocation under-supplies the per-arm target.
- [ ] On the experiment path: defaults to sequential testing model (the team is likely to peek given the "ramp if nothing breaks" framing); flags this rationale explicitly.
- [ ] On the experiment path: insists on at least one guardrail (Day-7 retention or session count) — onboarding redesigns frequently regress engagement health.

## Failure modes to catch

- Skill assumes "A/B test" means experiment and skips XP-vs-FF routing — produces a configured experiment for what's actually a phased rollout, wasting time and traffic.
- Skill picks Day-30 retention as primary on what is implicitly a short test (the "ramp from there" framing implies a 1–2 week observation window) — `references/metric-selection.md` lagging-indicator violation.
- Skill defaults to frequentist + sample_size without asking; the team peeks anyway and inflates the false-positive rate.
- Skill skips guardrails because the user didn't ask for any.

## Notes

The Pelando quote is the canonical "ambiguous intent" case in the PRD. If the verbatim quote is clearer about intent than the placeholder above, adjust `expected_outcome` accordingly. If the verbatim quote unambiguously specifies experiment intent, this fixture becomes a hypothesis-coaching fixture instead of an XP-vs-FF routing fixture — move it to that bucket and add a new XP-vs-FF fixture.
