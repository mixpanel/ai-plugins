# Reading Retention charts — reference

Use this reference when the chart being analyzed is a **Retention**
chart (cohort retention triangle, stickiness, DAU/MAU).

---

## What to read first

1. **Period-1 retention** — what % of cohort returns the period
   immediately after birth. This is the steepest drop-off and the most
   important number.

2. **Long-tail retention** — where does the curve flatten? A retention
   curve that flattens at 20% means roughly 1-in-5 users become
   long-term active. A curve that goes to zero has no durable base.

3. **Cohort comparison** — are recent cohorts retaining better, worse,
   or similar to older cohorts? This is the trend signal — improving
   onboarding shows up here.

4. **Cohort sizes** — note if cohorts are very different sizes,
   especially if recent cohorts are small. Small cohorts have noisy
   retention.

---

## Patterns to flag

### Curve doesn't flatten

A healthy retention curve flattens — losing fewer users each period
because the remaining users are increasingly engaged. If the curve
keeps declining linearly, the product has no "sticky" base.

> Flag as: *"Curve continues to decline through period [N] without
> flattening — no sign of a durable retained user base."*

### Flat curve after period 1

Sometimes the curve drops sharply in period 1 then is essentially flat
— a small core of users who keep coming back. The headline retention %
might look low, but the *shape* is healthy.

> Flag as: *"Big drop in period 1, then nearly flat — small but
> durable retained cohort."*

### Recent cohorts diverging from older cohorts

If recent cohorts retain noticeably better or worse than older ones,
something changed — onboarding flow, acquisition source mix, or
product changes. Worth flagging clearly.

> Flag as: *"Cohorts from [recent period] retain ~X% [better/worse] than
> cohorts from [earlier period] — the product or acquisition changed."*

### Small cohort noise

If recent cohorts are <100 users per period, retention numbers are
unreliable. Surface this so the customer doesn't read meaning into
noise.

> Flag as: *"Recent cohorts are small (<100 users/period) — the
> percentages are noisy. Need a longer date range or larger acquisition
> volume for clean numbers."*

### Impossible retention (>100% or 0%)

If period-N retention shows >100%, the retention type is bounded vs.
unbounded mismatched, or the same user is being counted multiple times.
Surface as a chart configuration issue, not a finding.

If period-1 retention is 0% across the board, the return event likely
is the same as the birth event (e.g., signup retention measured against
signup, which by definition only fires once per user).

### Stickiness (DAU/MAU) anomalies

For DAU/MAU charts:
- Healthy consumer products: 10–25%
- Healthy B2B products: 30–50%
- >70% almost always means MAU is artificially low (small user base or
  short measurement window)
- <5% means daily engagement is rare — flag as low stickiness

---

## Common reader pitfalls

**Reading retention as engagement**
A user who returns once in week N counts as retained, even if their
engagement is shallow. High retention % doesn't mean high usage.

**Comparing cohorts across product changes**
If the product changed materially mid-window, comparing pre-change
cohorts to post-change cohorts is comparing two different products.
Surface this if the customer's business context mentions a recent
launch or major change.

**Confusing retention with churn**
Retention is the inverse of churn, but they're not always perfectly
complementary in Mixpanel. A user "not retained" in week N might
return in week N+1. Don't equate "not retained this week" with "lost
forever."

**Cohort retention vs. rolling retention**
Mixpanel's native retention is cohort retention (% of birth-week users
who returned in week N). If the customer asks about "30-day retention"
and means rolling retention (% of users active today who were active
30 days ago), the chart might not be answering their question.

---

## Output focus

Retention summary should answer:
- What's period-1 retention?
- Does the curve flatten, and at what level?
- Are recent cohorts trending better or worse?

Skip:
- Methodology lectures (only explain bounded vs. unbounded if relevant
  to a finding)
- Hypotheses on why retention shifted (that's `mxp-metric-diagnosis`)
