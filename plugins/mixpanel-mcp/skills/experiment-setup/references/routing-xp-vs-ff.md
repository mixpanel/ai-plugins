# XP vs FF: routing intent

Before any setup work, decide whether the user actually wants an **experiment** (XP) or just a **feature flag** (FF). The decision is binary, but the language users use is blurry — "let's A/B test this" sometimes means "let's run a controlled experiment with a hypothesis and a stopping rule," and sometimes means "I want to ship it to 10% of users and see if anything breaks."

## The discriminator

| If the user wants…                                                                | Then it's a…                                                                   |
| --------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Causal evidence — "does this change move metric X by enough to justify shipping?" | **Experiment** (XP).                                                           |
| Progressive rollout — "ship to 10%, then 50%, then 100% if nothing breaks."       | **Feature flag** (FF).                                                         |
| Kill-switch — "I want to be able to turn this off instantly if it goes sideways." | **Feature flag** (FF).                                                         |
| Per-segment gating — "only show this to enterprise customers."                    | **Feature flag** (FF).                                                         |
| Targeted access — "give beta access to these 50 design partners."                 | **Feature flag** (FF).                                                         |
| Both — "ship to 10%, but also tell me if it moves checkout conversion."           | **Experiment** with a phased rollout, or **FF + a separate experiment** later. |

The clean way to think about it: a feature flag is a **delivery mechanism**. An experiment is a **decision mechanism** built on top of one. Every experiment uses a feature flag under the hood (Mixpanel auto-creates one when you call `create_experiment`); not every feature flag use case needs an experiment.

## Disambiguation prompt

When you can't tell from the user's wording, ask once, plainly:

> "Are you trying to **measure** whether this change moves a metric (experiment), or are you rolling it out gradually / behind a flag with **no measurement criterion** (feature flag)? An experiment commits to a hypothesis, metrics, and a stopping rule; a feature flag is purely a delivery mechanism."

Listen for these signals in the answer:

- "I want to see if it improves X" / "if checkout conversion goes up" → experiment.
- "I want to make sure it doesn't break X" → could be either. Probe: "Is 'doesn't break' a measurable threshold, like a guardrail, or is it 'I'll watch dashboards and roll back if it's obviously bad'?"
- "I want enterprise to get it first" / "I want to roll out by region" → feature flag.
- "I just want a kill switch" → feature flag.
- "I want to ship it and prove ROI later" → ask whether the proof needs to be causal. If yes, that's an experiment, and it should be set up _before_ shipping, not after. (Post-hoc ROI claims from a flag rollout are not credible.)

## Common ambiguous cases

### "Ship to 10% as an experiment"

Often this means "phased rollout, monitor metrics, ramp if nothing regresses." That's a feature flag with manual ramp logic, not an experiment.

Ask: "Do you have a primary metric you're committing to before launch, with an MDE that decides whether to ship to 100%?" If yes, run as an experiment. If no, ship as a flag.

### "I want to test the new pricing on enterprise customers"

If "test" means "see how they react and decide whether to roll out," and the audience is small (a few enterprise customers), that's a **rollout**, not an experiment. Enterprise samples are usually too small to power an experiment, and the per-account variance is too high for a meaningful aggregate.

Run as a flag, gather qualitative feedback, and decide based on the conversations — not on a p-value computed from N=4.

### "Hold out a control while we ship to 100%"

This is the classic "holdout experiment." Legitimate use case, but it has to be set up as an experiment up front (with a primary metric and a duration), not retroactively. After-the-fact holdout analysis suffers from selection bias and is not credible.

If the user has already shipped to 100% and wants to "analyse the effect," there is no experiment to set up. Tell them so, and suggest a forward-looking test on the next change to the same surface.

### "Just give me an A/B test, the simplest one"

Probably an experiment. But "simplest" usually means "skip hypothesis, skip MDE, skip guardrails," which kills the test's interpretability. Coach the user through Step 1 (hypothesis) and Step 2 (metrics) of the main workflow — the cost is 10 minutes; the value is having a result you can actually act on.

### "I want a feature flag but with stats"

Now you're back to an experiment. Run the full setup workflow.

## What changes once you've routed

### If experiment

Continue with the four-step setup workflow in the main `SKILL.md`. The output of this skill is a configured experiment ready to launch.

### If feature flag

This skill stops. Hand off to the user (or to a `manage-feature-flags` skill if one exists):

- They configure variants, targeting, and rollout percentages directly.
- No hypothesis, no MDE, no stopping rule needed.
- Mixpanel doesn't compute lift or significance on a flag — they're on their own for observation.

Make sure the user understands the trade-off explicitly: "Choosing flag means you give up the ship/no-ship decision criterion. If later you want to claim the change worked, that claim won't have the same evidentiary weight as a properly-designed experiment."

## Don't run an experiment when

There are cases where an experiment is technically possible but the wrong move:

- **Sample is too small.** Enterprise rollouts to ~10 accounts cannot power a real test. Ship as a flag and use qualitative feedback.
- **Treatment is risky/irreversible.** A real billing change with potential refunds shouldn't run as a 50/50 split — phase as a flag with conservative rollout and direct monitoring.
- **No baseline data.** Brand-new metric, brand-new feature, no historical observation. Run a 1–2 week passive observation period first, then design the experiment from real numbers.
- **Hypothesis is "let's see what happens."** No directional commitment means the test will be interpreted post-hoc, which is the same as not running an experiment.

Suggest the alternative explicitly so the user doesn't feel rejected — "this isn't an experiment-shaped problem; here's what to do instead."
