# Synthesis (Step 11)

Collapse all branch findings into a single narrative for the CSA.

This is where the whole tree becomes one output. No branch's raw
findings make it to the user unmediated — synthesis decides what
surfaces, in what order, and what drops.

---

## 11.1 Headline priority ladder

Pick the headline from the first of these that has a
`headline_eligible: true` finding. Ladder order matters — earlier
entries override later ones, even if a later branch also qualifies.

| Priority | Source | Condition | Headline phrasing template |
|---|---|---|---|
| 1 | Branch 0 | `dq_band = "severe"` (≥50%) | "Movement is primarily a data quality incident: `<dq_primary_check>`." |
| 2 | Branch 4 | `shape_final = "step"` with a clean `step_change_date` | "The metric moved sharply on `<date>`. Recommend correlating with the customer's release or change log." |
| 3 | Branch 1 | Layer 2 concentrated ≥70% on one dimension value (or 2–3 values together ≥70%) | "`<X%>` of the movement is concentrated on `<library>` `<dimension>` = `<segment>`." |
| 4 | Branch 3 | Clean acquisition-vs-experience split, OR a monotonic tenure pattern | "Movement is `<acquisition-driven / experience-driven / an onboarding regression / etc.>` — `<new/existing/tenure_bucket>` cohorts are behaving differently while others are stable." |
| 5 | Branch 2 | Path = `funnel` or `retention` with a clean causal step / day; OR path = `ratio` with clean numerator/denominator attribution | Funnel: "`<X%>` of the funnel drop is at the `<step_name>` step." Retention: "`<Day>` retention shifted by `<Xpp>` — the rest of the curve is stable." Ratio: "`<Numerator/Denominator>`-driven: `<component_name>` moved `<X%>` while the other side stayed stable." |
| 6 | Synthesis default | No branch concentrated — movement is broad-based | "Movement is broad-based: no single segment, cohort, component, or shape concentrated the shift. Recommend a deeper investigation or a longer observation window." |
| 7 | Branch 5 | Never used as headline | — |

**Simpson's paradox override**: if Branch 1 detected Simpson's paradox
(`simpsons_paradox_detected: true`), the Branch 1 headline becomes
*compositional* rather than segment-concentration:

> "Users didn't change — the mix of users did. `<metric>` moved because
> `<segment>`'s share of volume shifted from `<X%>` to `<Y%>` between windows."

This overrides the standard Priority 3 phrasing.

**DQ scaling caveat**: if `dq_band = "material"` (10–50%), prepend to
whatever headline was picked: *"After accounting for `<X%>` data
quality contribution, ..."*.

---

## 11.2 Supporting findings — top 3 bullets max

After the headline, surface **up to 3** additional findings from branches
that also produced `headline_eligible: true` but lost the priority
ladder. Ranked by contribution magnitude (scaled by DQ where applicable).

Branch findings that didn't make the top 3 are **dropped entirely** —
they don't appear as an appendix, a ruled-out list, or a collapsible
detail section. Design decision: the CSA reads faster when the output
is ruthlessly edited.

Exception: correlated events from Branch 5, if any passed the filter,
appear as a separate mini-section after the supporting bullets, framed
with Branch 5's required suggestive-not-conclusive language. Capped at
top 5 events per Branch 5's own rules.

---

## 11.3 Final output structure

Fixed section order. Every RCA output follows this exact shape:

```
━━ RCA — <metric_name> ━━
Project: <project_id>  •  Mode: <quick | deep>  •  Drift: <drift_window>  vs  Baseline: <baseline_window>

[chart — see 11.4]

━━ HEADLINE ━━
<one sentence, copy-pasteable into Slack>

━━ CONFIDENCE ━━
<High | Medium | Low> — <one-clause reason>

━━ WHAT WE FOUND ━━
<2–3 sentences elaborating the headline finding, including the relevant
numbers and the customer conversation starter if Branch 4 provided one>

━━ WHAT ELSE TO CHECK ━━
- <supporting finding 1>
- <supporting finding 2>
- <supporting finding 3>
(cap at 3 — drop everything else)

[Correlated events section, if Branch 5 found any — see 11.5]

━━ SCOPE ━━
RCA ran in <mode> mode. <List of branches skipped + reasons, one line.>

━━ WHAT MIXPANEL COULDN'T SEE ━━
<Branch 6 disclosure block>
```

---

## 11.4 Finding-adaptive chart

Every RCA output includes a chart. The chart is **finding-adaptive** —
its content depends on which branch produced the headline. A generic
line chart would be decorative; the chart has to illustrate the
finding.

Before generating, read `visualize:read_me` with `modules: ["chart"]`
once per session. Do not narrate the read_me call.

| Headline source | Chart content |
|---|---|
| Branch 0 (DQ) | 60-day daily view of the metric with the DQ check that produced the max contribution overlaid (e.g., base event volume on a second axis if Check 2 triggered; `$import=true` volume share if Check 1 triggered) |
| Branch 4 (step change) | 60-day daily view with a vertical marker at `step_change_date` and "before" / "after" mean lines on either side |
| Branch 1 (segment concentration) | 60-day daily view broken down by the concentrated segment — 2 lines: the concentrated segment vs the rest |
| Branch 1 with Simpson's | Stacked-area chart of the top 3 segments' volume shares across the full window, illustrating the mix shift |
| Branch 3 (cohort) | 60-day daily view with two lines: new cohort vs existing cohort (or the tenure bucket that drove the finding, for monotonic patterns) |
| Branch 2 (funnel / retention) | Funnel step or retention curve with drift window values and baseline values overlaid |
| Branch 2 (ratio) | Dual-axis line chart: numerator on one axis, denominator on the other, across the full window |
| Broad-based default | 60-day daily view with drift and baseline windows shaded, mean lines for each |

If chart generation fails for any reason, fall back to text-only output
with a note: *"Chart unavailable — findings below."* Do not block on
the chart.

---

## 11.5 Correlated events mini-section

If `branch_5_findings.reportable_events` is non-empty, insert between
"WHAT ELSE TO CHECK" and "SCOPE":

```
━━ CORRELATED EVENTS ━━
These events moved in the same window. Suggestive, not conclusive:
- <event_A>  <shift_%>  (<adjacency_reason>)
- <event_B>  <shift_%>  (<adjacency_reason>)
...  (cap at 5)

Worth investigating whether a change to <shared_context> affected these alongside <metric>.
```

The "shared_context" hook appears only when structural adjacency is
the reason. Behavioral-only adjacency (Flows path-step) doesn't justify
a shared-context claim.

If `no_correlated_movement = true`, include a shorter version:

```
━━ CORRELATED EVENTS ━━
The metric moved in isolation — no adjacent events shifted in the same direction. This usually points to something specific to this metric's event or flow.
```

---

## 11.6 Confidence calibration

The Confidence line is not a hedge on the numbers — it's an honest read
on how trustworthy the narrative is.

| Confidence | Condition |
|---|---|
| **High** | Headline came from Branch 0 (DQ), Branch 4 (step change with date), or Branch 1 (Layer 2 ≥70% concentration on a single segment). No DoW contamination flag. No DQ-scaling caveat. |
| **Medium** | Headline came from Branch 2 or Branch 3. OR: high-priority headline but DQ is in "material" band (10–50%). OR: DoW contamination flagged. |
| **Low** | Broad-based finding (Priority 6). OR: multiple branches skipped due to `$first_seen` unavailability or missing dimensions. OR: Simpson's paradox detected (the segment story is compositional, not behavioral, and those are harder to act on cleanly). |

Always include the one-clause reason — "no single segment concentrated,"
"DQ contribution = 18%," "Simpson's paradox detected," etc.

---

## 11.7 Scope section content

One line, listing what didn't run and why:

- Branch 2: "Skipped — count metric" | "ran as ratio path" | etc.
- Branch 3: "Skipped — `$first_seen` coverage below 50%" | "ran with retention carve-out" | "tenure sub-decomposition skipped in Quick mode"
- Branch 5: "Skipped — Quick mode" | "ran, 2 correlated events found"
- Any dimensions skipped in Branch 1 from `rca_context.missing_dimensions`

Keep this line compact — the CSA needs to know what was ruled out, not
a play-by-play.

---

## 11.8 Never-produce rules

Synthesis enforces a few hard rules that override anything upstream:

- Never produce an output where Branch 5 is the headline.
- Never omit the "WHAT MIXPANEL COULDN'T SEE" section, even if every
  branch came back clean.
- Never emit more than 3 supporting bullets.
- Never use causal language ("caused by," "led to," "drove") in any
  section, not just Branch 5.
- Never include a chart if chart generation failed — fall back to text
  with the note, don't leave an empty chart placeholder.
- If the tree walk was halted by Branch 0 (DQ severe) or Branch 1
  Layer 0 (non-SDK concentration), synthesis produces a **DQ-framed
  output** — no behavioral supporting bullets, no correlated events
  section. The whole output becomes an instrumentation handoff.
