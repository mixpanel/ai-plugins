# Branch 5 — Correlated event scan (Step 9)

**The narrative builder.** Doesn't prove causation. Doesn't attribute
the metric's movement to a segment or cohort. Gives the CSA *material*
for a customer conversation — "events that moved in the same window"
— so the handoff to the customer has something concrete to anchor on.

Writes to `rca_context.branch_5_findings` (schema in `preflight.md`).

Language discipline is non-negotiable: Branch 5's output must read as
**suggestive**, never causal. See 9.5.

---

## 9.1 Mode gating

| Mode | Action |
|---|---|
| Quick | **Skip entirely.** Record `skipped: true`, `skipped_reason: "quick mode — correlated scan deferred"`. Proceed to Branch 6. |
| Deep | Run the full scan per the steps below. |

This keeps Quick mode's query budget intact. Branch 5 is the single
most query-expensive branch in Deep mode — up to ~22 queries on
customers with a busy adjacency graph (2 scoping queries + up to 20
candidate shift queries). Quick mode's narrative in the final output
leans on Branches 1–4 instead.

---

## 9.2 Adjacency — union of two definitions

An "adjacent event" is any event that satisfies at least one of the
following, scoped to the same project as the base event:

**Behavioral adjacency (Flows-based)** — events that appear as the most
frequent steps **before** or **after** the base event in Mixpanel's
Flows report. This is an approximation of "events the same users fire
around the base event" — not a true ±24h co-occurrence query (Mixpanel
has no direct primitive for that). Flows returns the top path steps
before and after, which captures the practical adjacency signal the
CSA needs for narrative purposes.

**Structural adjacency** — events that appear **in the same saved
funnel or flow report** as the base event. Uses saved-report
definitions as the signal.

Candidate events are the **union** of both sets. Schema adjacency
(events that share a Lexicon property with the base event) has been
dropped — there is no efficient primitive in the MCP surface for
"find events sharing property P with event Y" without enumerating
every event's property list in the project, which is not practical
inside an RCA run.

---

## 9.3 Candidate selection (scoping queries)

Before measuring shifts, build the candidate list:

1. **Query 1 — Behavioral (Flows)**: `Run-Query(report_type='flows')`
   on the base event in the drift window, returning top path steps
   before and after. Collect the top ~10 event names from each side
   (pre and post). This is the behavioral adjacency set.
2. **Query 2 — Structural (Search-Entities + Get-Report)**: call
   `Search-Entities(entity_types=['funnels','flows'])` with a query
   matching the base event name (or empty + filter client-side). For
   each saved entity that references the base event, call `Get-Report`
   to pull its definition and extract the other event names in it.
   This is the structural adjacency set. Typically 2–5 such entities;
   skip gracefully if none exist.

Union the two results. Apply **volume floor**: any event with <1,000
occurrences in the drift window is dropped from the candidate list at
this stage. This is non-negotiable — low-volume events produce noisy
shift signals.

**Candidate cap**: if the post-floor list has >20 events, cap at the
**top 20 by Flows path-step frequency** (behavioral adjacency as the
tiebreaker, since Flows returns frequency-ranked steps). Record the
number of events filtered out in
`rca_context.branch_5_findings.candidates_filtered`.

---

## 9.4 Shift measurement

For each of the (up to 20) candidate events:

**Query**: One lightweight `Run-Query` returning the event's total count
in the drift window and in the baseline window.

**Math**:

```
event_shift_pct = (event_count_drift - event_count_baseline) / event_count_baseline
shift_direction = sign(event_shift_pct)
metric_direction = rca_context.verdict_direction   # "up" | "down" | "mixed"
```

**Filter to reportable events**: keep only events where:

- `abs(event_shift_pct) ≥ 10%`, and
- `shift_direction` is the **same as** `metric_direction` (or `metric_direction = mixed`, in which case any direction qualifies).

Events that moved in the opposite direction to the metric aren't
suppressed entirely — they're noted in a separate "moved opposite"
list, in case the CSA wants to investigate (a complementary shift can
be a useful signal). But they don't make the headline output.

---

## 9.5 Output cap and language discipline

Rank reportable events (same-direction movers) by `abs(event_shift_pct)`.

**Output cap**: top 5 only. Hard ceiling, not a suggestion.

**Required output phrasing** — every correlated-events section must
include this framing, verbatim or close to it:

> "These events moved in the same window. This is suggestive, not
> conclusive. They point to areas worth investigating — not proven
> causes."

**Forbidden phrasing** in Branch 5 output:
- "Caused by..."
- "Led to..."
- "Because of..."
- "Drove the drop in..."
- Any language that asserts causation between a correlated event and
  the metric.

**Preferred phrasing templates**:

- *"`<metric>` dropped `<X%>` starting `<date>`. In the same window, `<event_A>` dropped `<Y%>` and `<event_B>` rose `<Z%>`. Worth investigating whether a change to `<shared context>` affected all three."*
- *"`<N>` adjacent events moved in the same direction. The largest shift was `<event>` (`<shift_%>`)."*

The shared-context hook only applies when **structural** adjacency is
the reason the event was selected (the base event and the adjacent
event appear in the same saved funnel/flow). Behavioral adjacency
(Flows path-step) alone doesn't justify a "shared context" claim — it
just means users hit both events close in time.

Each reportable event entry records `adjacency_reasons` as a list
(`"behavioral"`, `"structural"`, or both) and `shared_context` as a
string only when structural adjacency applies.

---

## 9.6 The "no correlated movement" case

If no events pass the filter (all candidates moved <10% or moved opposite),
that's **itself a finding**. Set `no_correlated_movement = true` and
surface in the output:

> "The metric moved in isolation — no adjacent events shifted in the
> same direction. This usually points to something specific to the
> metric's own event/flow, rather than a broader product change."

This is a useful CSA signal — it narrows the investigation scope.

---

## 9.7 Exit rules

Branch 5 never halts the tree walk. Always proceed to Branch 6.

**Headline eligibility**: Branch 5 is **never** the headline of the
RCA output. Design-doc mandated. Correlated events are supporting
material only — they appear below whichever branch produced the
headline, framed as "worth investigating alongside."

This is a credibility boundary. The skill is trusted more when it
doesn't over-claim.
