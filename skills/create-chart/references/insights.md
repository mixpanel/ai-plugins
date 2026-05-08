# Insights — chart-type reference

Use this reference when the user's ask classified as **Insights** in
SKILL.md Step 2. Insights covers: event counts, trends over time, totals,
unique users, and breakdowns / segmentation.

Read this file alongside `Get-Query-Schema` from the Mixpanel MCP for the
authoritative query JSON. This file holds workflow notes, not schema.

---

## What "Insights" answers

- **Volume** — "how many checkout events last 30 days"
- **Trend** — "DAU over time", "signups per week"
- **Breakdown** — "events by country", "checkout by plan tier"
- **Comparison** — "events this period vs prior period"
- **Ratio / formula** — "checkout / signup conversion rate"

If the ask is *step-by-step conversion through a sequence*, that's a
Funnel, not Insights. If the ask is *did users come back*, that's
Retention. Re-classify in SKILL.md Step 2 and load the right reference.

---

## Build pattern

1. **Pick measurement unit** — `total events` (default) vs `unique users`
   vs `unique distinct_id`. Customer cues:
   - "events", "count", "volume" → total events
   - "users", "people", "uniques", "DAU/MAU" → unique users
   - "sessions" → unique sessions (if a session ID property exists)

2. **Apply filters** — only what the customer named. Do not add
   "exclude internal users" unless they ask, but if `Get-Business-Context`
   surfaces a known internal-user filter, mention you can apply it.

3. **Apply breakdown** (if any) — single property or two properties (max
   typically). For list-type properties, set `propertyType: 'list'` —
   read this from `Get-Properties`, do not assume.

4. **Date range** — last 30 days, daily granularity by default. Switch
   to weekly if range > 90 days, hourly if range < 3 days.

5. **Compare to prior period** — off by default. On if customer says
   "vs last month", "compared to", "WoW", "MoM".

---

## Common pitfalls

**Total events vs unique users confusion**
A customer asking "how many users signed up" usually means *unique
users who fired the signup event*, not the raw event count. Default to
unique users when the noun is "users", "people", or "customers".

**Breakdown of a high-cardinality property**
Properties like `URL`, `email`, or `user_id` will return thousands of
rows and either time out or render as visual noise. If `Get-Property-Values`
returns >50 distinct values for the breakdown property, ask:
*"This property has many values — want me to limit to the top 10?"*

**List-type properties without `propertyType: 'list'`**
A list-type property used as a normal breakdown returns wrong counts —
each row gets attributed to one value instead of all values in the list.
Always read the `type` field from `Get-Properties`.

**Default vs custom event**
If the customer says "Identify" or "Page View", this could be a default
SDK event (`$identify`, `$mp_page_view`) or a custom-named event. Check
both — `Get-Events` includes both namespaces.

---

## Render

After `Run-Query` returns a `query_id`, call `Display-Query` with that
ID. The widget handles chart type selection (line, bar, area) based on
the breakdown shape. Don't try to override unless the customer asks for
a specific visualization style.

---

## When to escalate to a different skill

- If the customer wants to know *why* the metric moved → `mxp-metric-diagnosis`
- If the customer wants to add multiple charts → `create-dashboard`
- If the chart is already saved and they want it explained → `analyze-chart`
