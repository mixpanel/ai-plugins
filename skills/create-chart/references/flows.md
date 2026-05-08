# Flows — chart-type reference

Use this reference when the user's ask classified as **Flow** in
SKILL.md Step 2. Flows show the most common event sequences before or
after a chosen anchor event.

Read this file alongside `Get-Query-Schema` for authoritative flow
query JSON.

---

## What "Flow" answers

- **What users do next** — "what happens after signup"
- **What users did before** — "what leads up to a purchase"
- **Common paths** — "the most common 3-event sequences in onboarding"
- **Drop-off discovery** — "where do users go instead of completing
  checkout"

If the ask is *fixed-step conversion through known events*, that's a
Funnel, not a Flow. Flows are exploratory; Funnels are confirmatory.

---

## Build pattern

1. **Anchor event** — the event flows are measured *from* (or *to*).
   Customer cues: "after [event]", "before [event]", "starting from",
   "leading to".

2. **Direction** — forward (default) vs backward.
   - Forward: "what happens after signup" → forward from `User Signed Up`
   - Backward: "what users do before purchase" → backward from `Purchase`
   - "Around" / "in the session of" → run forward, surface that backward
     is also available

3. **Depth** — how many steps to show. Default 3. Customer cues:
   - "next event" → depth 1
   - "next few steps" → depth 3
   - "the whole journey" → depth 5+
   - More than depth 5 gets visually noisy fast — surface this if the
     customer asks for deep flows.

4. **Filters** — apply on the anchor event (e.g., "after signup, only
   for users on iOS"). Step-level filters within the flow are not
   typically supported — flag this if the customer asks for them.

5. **Date range** — last 30 days by default.

---

## Common pitfalls

**Anchor event has very low volume**
If the anchor fires < 100 times in the date range, the flow chart will
have a long tail of one-off paths. Surface this: *"The anchor event has
low volume — the flow may show many one-off paths. Want a longer date
range?"*

**Forward flow from a terminal event**
A "forward flow from purchase" might show very little if `Purchase` is
typically the last event in a session. Suggest backward direction
instead.

**Confusing flows with funnels**
A customer who says "what % of users go from signup to checkout" wants
a Funnel, not a Flow. Re-classify in SKILL.md Step 2.

**Many similar event names cluttering the flow**
If the project has both `Page View` and `$mp_page_view`, or `Click` with
many sub-types, the flow chart fragments. Suggest filtering the anchor
or using the events filter to consolidate.

**Sessionization assumption**
Flows in Mixpanel are not strictly session-bounded — events from
different sessions (hours or days apart) can appear in the same flow.
If the customer wants strict session flows, mention this caveat.

---

## Render

After `Run-Query`, call `Display-Query`. The flow widget renders a
Sankey-style diagram showing event-to-event transitions with width
proportional to user volume.

---

## When to escalate to a different skill

- If the customer wants the *conversion rate* through a specific path,
  not just the path discovery → re-classify as Funnel
- If the customer wants to know *why* the flow shifted → `mxp-metric-diagnosis`
- If the customer wants to compare flows across cohorts → still Flow
  here, add a breakdown property
