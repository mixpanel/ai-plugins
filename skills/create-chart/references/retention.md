# Retention — chart-type reference

Use this reference when the user's ask classified as **Retention** in
SKILL.md Step 2. Retention measures whether users come back after a
defining "birth" event.

Read this file alongside `Get-Query-Schema` for authoritative retention
query JSON.

---

## What "Retention" answers

- **Cohort retention** — "what % of users who signed up in week 1 came
  back in week 2, 3, 4..."
- **Stickiness** — "DAU / MAU ratio"
- **Feature retention** — "do users who try [feature] keep using it"

If the ask is *did a single user complete a sequence of events*, that's
a Funnel, not Retention.

---

## Build pattern

Retention needs three things, in order:

1. **Birth event** — the defining action that puts a user into the
   cohort. Common: `User Signed Up`, `First Purchase`, `Account
   Created`. Customer cues: "after signup", "after first purchase",
   "after they activated".

2. **Return event** — the action that counts as "they came back". Often
   the same as a key engagement event. Customer cues: "came back to
   use", "returned and did", "kept using".
   - If the customer says only "retention" without naming the return
     event, default to **any event** (general activity retention) and
     surface it: *"Using any event as the return signal — say if you
     want to measure retention on a specific action."*

3. **Retention type** — `unbounded` (default) vs `bounded`.
   - **Unbounded**: user counts as retained in week N if they fired the
     return event *at any point in week N*. This is the standard.
   - **Bounded**: user counts as retained only if they fired the return
     event *every preceding period as well*. Stricter, used for
     subscription-style products.
   - Default to unbounded unless the customer asks for "rolling" or
     "consecutive" retention.

4. **Granularity** — daily / weekly / monthly. Default by date range:
   - Range < 30 days → daily
   - Range 30–180 days → weekly
   - Range > 180 days → monthly

5. **Cohort window** — default last 12 periods of granularity (e.g., 12
   weeks for weekly).

---

## Common pitfalls

**Birth event with too few users**
If the birth event has < 100 users in the lookback window, retention
curves are noisy and easily misread. After running the query, if the
cohort sizes are small, surface it: *"Cohorts are small (< 100 users
per week) — the retention numbers will be noisy. Want a longer window?"*

**Return event = birth event accidentally**
If the customer says "signup retention" without specifying the return
event, do not use `User Signed Up` as both birth and return — every
user signs up exactly once, so retention on signup itself will be 0%
after period 0. Default to "any event" or ask which return event they
want.

**Confusing N-day retention with cohort retention**
"30-day retention" can mean either:
- *Cohort* retention: % of week-N cohort still active in week N+30
- *Rolling* retention: % of users active today who were active 30 days ago
The Mixpanel native chart is cohort retention. If the customer wants
rolling retention, surface the difference and confirm.

**User properties as cohort filter**
Filtering retention by user property (e.g., "retention for paid users")
applies the property at query time, not at birth time. So a user who
was free at signup but is now paid will show up in the "paid users"
retention bucket. Flag this when relevant.

---

## Render

After `Run-Query`, call `Display-Query`. The retention widget renders
the standard retention triangle (cohort × period). If the customer
asked for stickiness (DAU/MAU), the widget renders a single curve, not
a triangle.

---

## When to escalate to a different skill

- If retention dropped and they want to know why → `mxp-metric-diagnosis`
- If they want to see what users do *between* birth and return events
  → re-classify as Flow
