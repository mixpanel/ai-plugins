# Reading Flow charts — reference

Use this reference when the chart being analyzed is a **Flow** (Sankey
showing event-to-event transitions before or after an anchor event).

## Contents

- What to read first
- Patterns to flag
- Common reader pitfalls
- Output focus

---

## What to read first

1. **Anchor event volume** — how many users / events feed the anchor.
   This is the denominator for everything downstream.

2. **Top 1–3 paths** — what's the most common next event (or previous
   event, for backward flows)? What % of users go that way?

3. **Long tail** — how concentrated is the flow? If the top 3 paths
   account for 80% of users, the flow has clear dominant patterns. If
   the top 3 paths only account for 30%, the flow is fragmented.

4. **Drop-off branch** — in forward flows, where do users *exit* the
   product? In backward flows, where do they *enter* from?

---

## Patterns to flag

### Highly concentrated flow

If one path accounts for >70% of post-anchor activity, that path is
the de facto product behavior. Flag it as the dominant pattern.

> Flag as: *"After [anchor], [%] of users go to [next event] — that's
> the dominant path. Other branches are minor."*

### Highly fragmented flow

If the top 3 paths account for <40% combined, users do many different
things. This is either a power-user product (variety is healthy) or a
confusing UX (users don't know what to do next).

> Flag as: *"Flow is fragmented — top 3 paths account for only [%]
> combined. Either deep variety in user behavior, or unclear next-step
> guidance."*

### High drop-off branch in forward flow

A "drop-off" or "session end" branch claiming a large share is the
flow chart's version of a funnel drop-off. Flag if it's a meaningful
share (e.g., >30% drop off immediately after the anchor).

> Flag as: *"[%] of users drop off immediately after [anchor] — they
> don't proceed to any tracked event. Worth investigating where they
> go."*

### Unexpected next event

If the customer's mental model is "users do A → B" but the flow shows
"users do A → C", flag the surprise. The mental model and the data
disagree.

> Flag as: *"Most users go to [unexpected event] after [anchor] —
> [expected event] is only [%]. The flow's not what you might
> intuitively expect."*

### Uninformative backward flow

In a backward flow ("what leads to [event]"), if the top preceding
event is a generic event (Page View, App Open) rather than a meaningful
action, the flow tells you nothing about intent — the anchor is reached
from everywhere. Flag that the chart needs a deeper depth or a filter
excluding generic events to surface a real path.

> Flag as: *"The top event leading into [anchor] is [generic event] —
> so the flow isn't isolating a meaningful path. Worth filtering out
> generic events or going a step deeper."*

---

## Common reader pitfalls

**Confusing share % with conversion %**
A flow showing "30% of users go to checkout after cart" is not the
same as "30% of cart-add events convert." The flow share is users who
did *that next event*, not conversion through a defined funnel.

**Reading flows as session-bounded when they're not**
Mixpanel flows aren't strictly session-bounded — events from different
sessions hours or days apart can appear in the same flow. If the
customer is asking about within-session behavior, flag this caveat.

**Treating the anchor as a starting point when it isn't**
Flows can be anchored anywhere, not just on entry events. If the
customer says "user journey from signup" and the chart anchors on a
mid-funnel event, the data isn't answering the question they asked.

**Repeating events inflating the flow**
If the flow shows the same event repeating (Page View → Page View →
Page View), the transitions are real but uninformative — the flow needs
a property filter (which page?) to differentiate. Read it as a chart
configuration gap, not a behavior finding.

**Depth too shallow or too deep**
Depth-1 flows show only one next event — useful for "what's the
immediate next action" but not for path analysis. Depth-5+ flows are
visually noisy. If the chart depth doesn't match the question, surface
that.

---

## Output focus

Flow summary should answer:
- What's the dominant path?
- How concentrated is the behavior?
- What surprises (unexpected next/prior events, big drop-offs)?

Skip:
- Speculating on UX changes ("maybe the checkout button is
  hidden" — out of scope)
- Hypotheses on why users drop where they do (that's a root-cause
  investigation, out of scope)
