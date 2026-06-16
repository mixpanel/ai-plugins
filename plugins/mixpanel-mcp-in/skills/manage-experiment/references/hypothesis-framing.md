# Hypothesis framing

All four properties of a good hypothesis — falsifiable, directional, mechanistic, bounded in time — matter. Drop any one and the design downstream silently degrades.

## Contents

- The shape
- When the user gives you a one-liner
- Mechanism → metric class
- Hypothesis ↔ metric alignment
- When to push back
- Worked examples

## The shape

> **If** `<change>`, **then** `<measurable outcome>` will `<direction>`, **because** `<mechanism>`.

| Property            | Test                                                        | Failure mode                                                                                                                                                                                     |
| ------------------- | ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Falsifiable**     | Could the data say "no"?                                    | "Improving UX" can't be falsified. "Increasing weekly retention by ≥2pp" can.                                                                                                                    |
| **Directional**     | Is the predicted change up or down?                         | "Affecting cart size" leaves the polarity ambiguous; the system defaults to `direction: "up"` and the interpretation step misreads regressions as wins.                                          |
| **Mechanistic**     | What's the proposed causal chain?                           | "Because users will see X and decide Y" is a mechanism. "We think it'll work" is not. Without a mechanism, the team can't tell when the metric they picked is actually downstream of the change. |
| **Bounded in time** | Does the predicted effect occur within a measurable window? | Day-30 LTV claims need a ≥30-day experiment. A 2-week test on a 30-day metric can't measure the real effect (the metric isn't mature yet) and invites a noise-driven false read. |

## When the user gives you a one-liner

Ask them to commit to five things, in order. Don't proceed until you have all five.

1. **The change** — what's different in treatment. A specific UI string, a routing change, a price, a copy variant. Vague ("the new onboarding") is not enough; "the new onboarding which moves the free-item offer to step 1" is.
2. **The primary outcome metric** — one specific event or rate, not a domain. "Engagement" is not a metric; "weekly active users with ≥1 report created" is.
3. **The expected direction** — up or down. (Goes straight into the metric's `direction` field.)
4. **The minimum effect size that would justify shipping** — this becomes the MDE. If the user can't name one, ask: "If the lift turned out to be 0.5%, would you ship?" Their answer reveals the MDE.
5. **The mechanism** — why you expect this to work. The mechanism is what binds the metric to the change. A change to onboarding screens shouldn't be measured by Day-30 retention if no one has gotten to Day 30 yet — the mechanism would say so explicitly.

## Mechanism → metric class

The mechanism predicts the _kind_ of metric that should move. Use this mapping as a sanity check:

| Mechanism flavour                                        | Likely primary-metric class                                                                           | Anti-pattern                                       |
| -------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- | -------------------------------------------------- |
| Reduces friction at a specific step                      | Step conversion rate (funnel-typed)                                                                   | Headline retention metric                          |
| Surfaces a new option / increases discoverability        | Click-through or first-use rate on the surfaced option (conversion)                                   | Total events per user                              |
| Reorders information / changes salience                  | Time-to-task, completion rate on the salient step                                                     | Account-level revenue                              |
| Changes the cost of an action (price, paywall, friction) | Conversion-to-paid, refund rate, cancel rate (with `direction: "down"`)                               | DAU                                                |
| Adds a new content / recommendation system               | CTR on recommendations, downstream conversion                                                         | Aggregate engagement                               |
| Long-term retention play (referrals, loyalty)            | Day-7 or Week-1 retention as leading proxy; lagging Day-30 stays a post-launch monitor, not a primary | Day-30 retention as primary on a 2-week experiment |

When the user's mechanism and proposed metric live on different rows of this table, push back — that's the **hypothesis ↔ metric mismatch** pitfall.

## Hypothesis ↔ metric alignment

A hypothesis names a specific outcome. The primary metric must measure that outcome — **same population, same denominator, same timeframe**. Common misalignments:

- Hypothesis predicts a **rate** change; primary metric is a **count** → switch to a rate metric, or use an exposure-rebalanced total.
- Hypothesis predicts effect on **paid users**; primary metric includes free users → add a cohort filter or scope the metric.
- Hypothesis predicts effect **within session**; primary metric is **per-user across sessions** → either narrow the metric or broaden the hypothesis.
- Hypothesis predicts effect **only on a new flow**; primary metric counts events that exist only in treatment → changed-denominator. The lift is artificially infinite. Pick a metric that exists for both arms.

## When to push back

Push back hard when:

- The hypothesis is non-falsifiable. Until it can be tested with a yes/no answer from data, there's nothing to set up.
- The hypothesis is non-directional. The system's `direction: "up"` default is wrong for cancel / error / latency / abandon metrics; leaving it default silently flips polarity at interpretation time.
- The mechanism doesn't predict the proposed metric. Most "experiment didn't work because we measured the wrong thing" post-mortems trace back to here.
- The proposed primary is strongly lagging on the planned duration (retention as primary on a 2-week test). Suggest a leading proxy.

When you push back, do it once with concrete language ("you said 'improve engagement' — which event do you want to move?"). If the user genuinely wants to leave the hypothesis vague, you can proceed, but log the vagueness in `description` so the post-launch step knows the test was exploratory rather than decisional.

## Worked examples

### ✅ Good

> If we surface a free-item offer during onboarding step 2, then signup→activation conversion will increase by ≥3pp (currently 18%), because reducing first-action friction lowers cold-start dropout for new accounts.

- Falsifiable: data can say "no, lift was <3pp."
- Directional: up.
- Mechanistic: first-action friction → cold-start dropout.
- Time-bounded: signup→activation is a within-session metric; readable inside any reasonable test duration.
- Mechanism predicts a conversion-class primary; signup→activation conversion fits.

### ✅ Good (lagging hypothesis, leading proxy primary)

> If we ship the new referral flow, then Day-30 retention will increase by ≥1.5pp, because referred users have stronger network effects. We will measure Day-7 retention as the experiment primary (historical correlation r=0.78 with Day-30) and keep Day-30 as a post-launch monitor.

- Bounded-in-time problem is acknowledged and solved with a leading proxy. The lagging metric remains a post-launch check, not a ship gate.

### ❌ Vague

> Test the new onboarding.

- No change description (which change? full redesign or one screen?).
- No outcome.
- No direction.
- No MDE.
- No mechanism.

Coach: pull each of the five commitments out of the user before going further.

### ❌ Non-falsifiable

> The new dashboard will improve the user experience.

- "Improve user experience" can't be tested. Ask: "Which specific behaviour changes if user experience is better? Engagement events per session? Time to first chart? Dashboards saved per user?"

### ❌ Mechanism doesn't predict the metric

> If we change the colour of the CTA button, then 30-day retention will increase by ≥2pp, because users will perceive the product as more polished.

- Mechanism is plausible at best, but Day-30 retention is far downstream of a button-colour change. Even if the colour change does help, a 2-week experiment won't measure it. Either pick a leading proxy (click-through on the CTA) or shelf the test until you have a more credible mechanism for retention.
