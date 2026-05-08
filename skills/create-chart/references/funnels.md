# Funnels — chart-type reference

Use this reference when the user's ask classified as **Funnel** in
SKILL.md Step 2. Funnels measure step-by-step conversion through an
ordered sequence of events.

Read this file alongside `Get-Query-Schema` for authoritative funnel
query JSON.

---

## What "Funnel" answers

- **Conversion** — "what % of users who add to cart complete checkout"
- **Drop-off** — "where do users drop off in onboarding"
- **Time-to-convert** — "how long from signup to first purchase"
- **Cohort comparison** — "is conversion higher for paid users"

If the ask is just *count of users who did event X*, that's Insights,
not a funnel.

---

## Build pattern

1. **Identify steps** — funnels need ≥2 events in a defined order. Ask
   the customer to confirm step order if their ask is ambiguous.
   - "from cart to checkout" → 2 steps: cart-add, checkout
   - "the onboarding funnel" → ask which events are the steps if
     `Get-Business-Context` doesn't define them

2. **Resolve each step event** — call `Get-Events` once, then validate
   each step name. If any step doesn't resolve cleanly, surface the
   ambiguity and ask before building the query.

3. **Conversion window** — default to 7 days. Customer cues:
   - "within an hour", "same session" → 1 hour
   - "within a day" → 24 hours
   - "eventually" → 30 days
   - If the customer says nothing about timing, use 7 days and surface
     it: *"Using a 7-day conversion window."*

4. **Step filters** — only if the customer specifies. Filters can be
   applied per-step (e.g., "checkout where amount > $50") or globally
   (e.g., "users on iOS").

5. **Conversion criteria** — default `linear` (each step in order).
   `unique` if the customer says "users who did all of these events"
   without caring about order.

---

## Common pitfalls

**Step ordering matters**
A funnel of `[checkout, cart-add]` will return near-zero conversion
because users add to cart *before* they check out. If the conversion
rate looks suspiciously low, double-check step order with the customer
before assuming the data is the problem.

**Same event repeated as steps**
If the customer asks for "page view → page view → page view" (a flow
through multiple page views), check whether each step needs a property
filter (e.g., `page_name = 'home'` vs `page_name = 'pricing'`). Without
filters, the funnel collapses.

**Conversion window too short**
B2B and high-consideration purchase flows often span days or weeks. A
7-day default is fine for most consumer flows but will undercount
conversion for enterprise / SaaS purchase funnels. If the customer's
business context (from `Get-Business-Context`) suggests a long sales
cycle, default to 30 days and mention it.

**Property scope on per-step filters**
A per-step filter like "checkout where plan = pro" needs `plan` as an
event property, not a user property. If `plan` is user-scoped, the
filter still works but applies to the user at query time, not at the
event time — flag this if it could mislead.

---

## Render

After `Run-Query`, call `Display-Query`. Funnel widgets show the bar
chart of conversion at each step plus the overall conversion rate.

If the customer asked for a *time-to-convert* breakdown, that's a
separate query type (funnel time series) — read `Get-Query-Schema` for
the right shape.

---

## When to escalate to a different skill

- If conversion dropped and they want to know why → `mxp-metric-diagnosis`
- If they want to compare conversion across cohorts → still Funnel here,
  add a breakdown property
- If they want to see the broader user journey, not just one funnel →
  re-classify as Flow
