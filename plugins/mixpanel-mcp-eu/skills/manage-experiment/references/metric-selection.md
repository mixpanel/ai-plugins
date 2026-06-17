# Metric selection

Each metric serves exactly one of three roles. The hypothesis tells you which.

## Primary metrics (1–3 max)

The metrics whose movement decides ship / no-ship. They come straight from the hypothesis's "outcome will `<direction>`" clause.

- **Cap at 3.** Each additional primary inflates the family-wise false-positive rate. With multiple-testing correction enabled (which is the right default at 2+ primaries), more primaries → tighter per-metric threshold → harder to detect any individual effect. Beyond 3 the math punishes you regardless of how well the test is run.
- **Explicit direction.** Every primary needs `up` or `down`. The platform's default is `up` (verify in product), which is wrong for cancel / error / latency / abandon / refund metrics. Set it explicitly at setup time so the polarity stays correct through interpretation; if it's wrong, the metric-update tool can fix it in place later (direction lives on the saved metric).
- **Leading, not lagging.** A primary must be able to actually move within the planned experiment window. Match the metric's response window to the experiment's duration:
  - Onboarding-screen change → activation in the first session, not Week-4 retention.
  - Checkout button A/B → checkout conversion, not 30-day LTV.
  - Pricing-page tweak → click-through and trial start, not annualised revenue.
  - When the only metric the team cares about is lagging, use a **leading proxy** with a known historical correlation to the lagging metric. The lagging metric stays a post-launch monitor, not a ship gate.
- **Prefer rates over counts** when the hypothesis is about behaviour change. "Conversion rate" is interpretable; "total conversions" conflates per-user behaviour with cohort size.

If the user proposes a primary, sanity-check:

- _Is this metric downstream of the change?_ (A pricing change cannot move "tutorial completion".)
- _Does the metric exist for both control and treatment users?_ If the change creates new events that don't exist in control, lift is artificially infinite (changed-denominator).
- _Is the metric's response window shorter than the experiment's duration?_ If not, the metric is lagging — pick a leading proxy.
- _Does the metric have enough volume to detect the expected lift?_ (Volume drives the sizing math.)

## Guardrail metrics (0+, strongly recommended)

Metrics that **must not regress**, even if primaries win. The trustworthiness backstop on a ship decision: a 5% relative regression on any guardrail blocks ship even if the primary wins. This is the **>5% guardrail hard-gate** — the umbrella owns the threshold (rationale in the pitfall catalogue), and it's the most important single rule there.

Standard guardrails by domain — pick at least one from the row that matches the change:

| Change targets…                      | Guardrail candidates                                    |
| ------------------------------------ | ------------------------------------------------------- |
| Performance / UI / new client code   | Page load time, API latency, error rate, crash rate     |
| Engagement / activation / onboarding | Weekly active users, session count, Day-7 retention     |
| Revenue / monetisation / pricing     | ARPU, conversion-to-paid, refund rate, cancel rate      |
| Trust / safety / moderation          | Complaint rate, unsubscribe rate, support-ticket volume |
| Time-to-task / search / IA           | Task abandonment rate, time-to-completion               |

For every guardrail, **set direction explicitly**. A guardrail named "errors" left at the default `up` will silently let regressions slip through interpretation as "wins." A wrong direction is fixable later via the metric-update tool.

Same lagging-indicator rule applies: a guardrail that takes 30 days to react can't protect a 2-week experiment. If the user names retention or LTV as a guardrail on a short experiment, recommend a leading proxy (Day-1 or Day-7 retention) and demote the lagging metric to a post-launch monitor.

## Secondary metrics (0+, diagnostic only)

Metrics for understanding **why** the primary moved, not for the ship decision. Examples: funnel-step completions, feature sub-use rates, time-on-screen, exploratory cohort breakdowns.

**Secondary metrics are not decisional.** Even if the user names a secondary in their hypothesis text, they cannot ship/kill on its result. If a metric matters for the decision, it must be primary or guardrail.

> **Setup misconfiguration to flag.** If the user's hypothesis text names a metric that they then classify as secondary, ask:
> _"You mentioned `<metric>` in your hypothesis. Should this be a primary metric? Secondary metrics don't influence ship/no-ship decisions, so if it matters for the outcome, promote it."_

This is the **Hypothesis ↔ metric mismatch** pitfall in the pre-launch pitfall catalogue.

## Sanity checklist

Run this before locking the metric set:

- [ ] Each primary directly measures the hypothesis's predicted outcome.
- [ ] Each primary has an explicit direction (not the platform default).
- [ ] At least one guardrail covers the most likely failure mode of the change (perf for UI changes, retention for monetisation changes, etc.).
- [ ] Each guardrail has an explicit direction.
- [ ] No metric whose denominator is created by the treatment itself (changed-denominator).
- [ ] No primary or guardrail is a strong lagging indicator on the planned experiment duration (use leading proxies; demote lagging metrics to post-launch monitors).
- [ ] Total primary count ≤ 3.
- [ ] If primary count ≥ 2 OR non-control variants ≥ 2, multiple-testing correction is on (Benjamini-Hochberg default, Bonferroni for strict family-wise control).
- [ ] For each primary, baseline rate has been pulled from real data (not guessed).

## Anti-patterns

- ⛔ **No guardrails to "avoid noise."** Guardrails are the regression detection, not noise. Without them, a winning primary with a quietly regressing latency or refund-rate is a ship — and then a rollback two weeks later.
- ⛔ **Five primaries because "they're all important."** Past 3, the false-positive risk dominates. Pick the 1–3 the hypothesis actually predicts; demote the rest to secondaries.
- ⛔ **Primary = "total signups," metric = behaviour change.** A behaviour-change hypothesis needs a rate metric; total signups conflates per-user behaviour with the size of the cohort that entered the experiment.
- ⛔ **Guardrail left at default direction `up` on an error / cancel / latency metric.** Silently inverts the regression check.
- ⛔ **30-day retention as primary on a 2-week experiment.** Either the lagging metric can't move (no signal) or it moves on noise (false significance). Use a leading proxy.
- ⛔ **Primary metric only exists in treatment.** Changed denominator. Lift is meaningless.
