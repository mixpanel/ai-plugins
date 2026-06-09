# Staged rollout and the kill switch

The lifecycle spine in `SKILL.md` covers a recommended `1% → 10% → 50% → 100%` cadence. Mixpanel doesn't impose this — it's a default that works for most teams; calibrate to product risk and the monitoring you actually have. This reference covers the cadence variants, why the cadence is logarithmic, and the rules for when to kill.

The pattern is **logarithmic, not linear**. Doubling at each stage exposes the failure mode you'd hit at 100% within the first few stages, while keeping the blast radius bounded if it does fail.

## Recommended cadence (default for most flags)

| Stage  | Rollout | Watch for                                              | Wait before next stage |
| ------ | ------- | ------------------------------------------------------ | ---------------------- |
| Canary | 1%      | Crash rate, error logs, support tickets                | 24 hours minimum       |
| Early  | 10%     | All canary signals + business KPI directional movement | 24–48 hours            |
| Mid    | 50%     | Sustained KPI signal, cohort-level differences         | 24–72 hours            |
| Full   | 100%    | Final guardrail check, support volume                  | —                      |

Bump the rollout incrementally — the merge preserves variants and other configuration. You don't need to re-send variants to change the rollout percentage.

## Slower cadence (high-stakes flags)

`0.5% → 2% → 10% → 25% → 50% → 100%`, with 48–72 hour holds at each stage.

Use for billing, auth, payments, anything where "small percentage of broken users" still means "support nightmare." The denser steps catch a regression earlier (a problem at 2% is half the blast radius of one at 10%), and the longer holds let slower-emerging signals (refund rates, support tickets, retention dip) surface.

## Faster cadence (low-stakes flags)

`10% → 50% → 100%` over a single day.

Use for non-user-facing changes (infra routing, internal tools, log format changes) where the failure mode is observable in seconds, not hours, and there's no user-experience regression class to worry about. Server-side errors are visible in monitoring within minutes; if nothing fires at 10%, the next bump is safe.

**Do not use faster cadence for**: UI changes, copy changes, pricing changes, onboarding changes, anything users will see or click. The cost of a 10%-of-users regression in those cases is paid in support volume and trust, not just error counts.

## Kill-switch triggers

A staged rollout exists so you can **kill fast** when something goes wrong. The kill switch is **disabling the flag**, not zeroing the rollout. The flag-update path treats these very differently — see [Why disable beats zero-rollout](#why-disable-beats-zero-rollout) below.

### Trigger conditions that justify a kill

- New crash or error metric spikes after enable or after a rollout bump.
- Support ticket volume rises on the affected feature.
- A guardrail metric (latency, conversion, retention) regresses.
- Cohort-level analysis shows a specific segment harmed.
- The team agreed in advance on a kill threshold and it was breached.

### Conditions that do not justify a kill

- A single user complaint without metric signal (could be UX preference, not bug).
- Statistical noise on a metric with no clear directional pattern.
- The change "looks weird" without a measurable impact.

The bar is "something measurable got worse," not "someone thinks it looks worse."

## Why disable beats zero-rollout

Two reasons, both compounding:

1. **Disable is instant and unambiguous.** Disable serves control to everyone immediately. Zeroing the rollout requires the SDK to re-evaluate the percentage, and depending on cache state, some users may briefly continue seeing the previous variant.
2. **Disable preserves the rollout configuration** so you can re-enable to the same percentage later without re-deciding what stage you were at. Zeroing the percentage destroys that information.

### The one exception

If you want to **stop new exposures while preserving the current bucketing for users already exposed**, that's a different problem and the right path is the experiment-side `conclude` action, not a flag-level operation. This only applies to experiment-linked flags; see [experiment-linked-flags.md](experiment-linked-flags.md).

## After mid-stage rollout — three honest choices

The lifecycle spine in `SKILL.md` covers ship / hold / roll back briefly. Two patterns to watch for:

- **"It moved, but not as much as we hoped."** This is a "hold" or "iterate" call, not a "ship anyway" call. A small positive effect at 50% rollout is the same small positive effect at 100%, and the maintenance cost of the flag is now the dominant question.
- **"Averages look fine but a cohort regressed."** Simpson's paradox is real. A flag that helps power users and hurts new users can show a flat overall effect while damaging the segment you most need to protect. Always look at cohorts before shipping to 100%.
