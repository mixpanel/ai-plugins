# Branch 4 — Temporal pattern (Step 8)

**What kind of drift is this?** The *shape* of the movement tells you
what kind of cause to look for. A step change points to a discrete event
(release, flag flip, outage); a gradual slope points to compounding
effects; oscillation points to traffic-mix shifts.

Writes to `rca_context.branch_4_findings` (schema in `preflight.md`).

Branch 4 is intentionally lightweight. **`analyse-metric` owns shape
classification end-to-end** — it runs the classifier in its Phase B6 and
writes `verdict_shape` into the handoff block. Branch 4's only job is
to *interpret* that shape into a cause hypothesis and actionability
level. It does **not** re-classify.

This is an intentional single-source-of-truth decision: if
`analyse-metric` classified `step` and Branch 4 re-ran the classifier
and got `slope`, the handoff block would become untrustworthy. Instead,
the handoff is authoritative and Branch 4 trusts it.

---

## 8.1 Read shape from handoff

Read `rca_context.verdict_shape` from the handoff block:

| `verdict_shape` value | Action |
|---|---|
| `step`, `slope`, `oscillating`, `spike` | **Use directly.** No queries. Proceed to 8.2 (interpretation). |
| `unclassified` | **Accept the honest finding.** `analyse-metric`'s classifier already ran and couldn't decide — Branch 4 does not re-run it. Produce an honest "shape unclear" interpretation in 8.2 rather than forcing a label. |

Set `rca_context.branch_4_findings.shape_from_handoff` and
`rca_context.branch_4_findings.shape_final` both to the incoming value.
`shape_final` exists as a field name for historical consistency but
always equals `shape_from_handoff` — Branch 4 never changes the shape.

**Step-change date**: when `verdict_shape = step`, the change-point date
is recorded in `rca_context.analyse_metric_notes` (by convention,
phrased as "Change-point detected on YYYY-MM-DD"). Parse the date out of
the notes and write to `rca_context.branch_4_findings.step_change_date`.
If the date isn't parseable from the notes, leave `step_change_date:
null` and treat the finding as a `step` shape without a pinnable date —
synthesis will downgrade it to supporting material.

---

## 8.2 Interpretation table

Map the shape to cause hypothesis and actionability:

| Shape | Likely cause | Actionability | Customer conversation starter |
|---|---|---|---|
| `step` | Discrete event: release, config change, pricing change, outage, feature flag flip | **Highest.** Pin the exact date, hand to the customer to correlate with their change log. | "The metric moved sharply on `<date>`. What shipped that day?" |
| `slope` | Compounding effects: cohort decay, slow UX degradation, competitor pressure, uncaptured seasonality | Medium. Points to systemic investigation. | "The metric has been declining steadily. Suggest we investigate whether cohort composition is shifting or whether there's a gradual UX regression." |
| `oscillating` | Traffic-mix shift — more weekend users, different time zones entering | Medium. Cross-reference Branch 1 Country/Source findings. | "The day-of-week pattern has changed. The mix of users hitting the product is likely different." |
| `spike` | Incident, already resolved | Low. Worth noting but not alerting. | "There was a temporary deviation on `<date>` but the metric has recovered. Confirm no lingering impact." |
| `unclassified` | Shape wasn't clearly any of the above — could be noise, a mild trend, or a mix of effects | N/A | "The shape of the movement is ambiguous. Recommend longer observation window or manual inspection." |

Write `cause_hypothesis` (free text, usually pulled from the "Likely
cause" cell) and `actionability` (one of the four levels) to
`rca_context.branch_4_findings`.

---

## 8.3 Day-of-week contamination recheck (always runs, 0 queries)

Every Branch 4 run performs this check, regardless of shape. It operates
on data already in the handoff block (daily series) — no new queries.

**Computation:**

```
weekday_mix_drift    = count_of_each_weekday_in_drift_window
weekday_mix_baseline = count_of_each_weekday_in_baseline_window
weekday_delta_max_pct = max over weekdays of:
    abs(weekday_mix_drift[d] / len(drift_window)
        - weekday_mix_baseline[d] / len(baseline_window)) × 100
```

If `weekday_delta_max_pct ≥ 10%`, flag contamination. This typically
happens when the drift window includes an extra weekend / fewer weekdays
compared to the baseline.

**Actions on flag:**

- Set `rca_context.branch_4_findings.dow_contamination = true`.
- Append to the final output: *"Note: drift window contains a different
  weekday mix than the baseline window (`<N>` extra weekend days). Some
  of the observed movement may be calendar artifact rather than
  behavior change."*
- If `verdict_shape = slope` or `oscillating` and DoW contamination is
  flagged → set `rca_context.branch_4_findings.dow_downgraded_confidence = true`.
  The slope may be spurious; the oscillation may be a detection of the
  calendar mismatch itself.

Record `dow_weekday_delta_max_pct` regardless of whether the flag
triggered — a below-threshold value is still useful context.

---

## 8.4 Exit rules

Branch 4 **never halts the tree walk**. Always proceed to Branch 5
(or to Branch 6 directly in Quick mode).

| Finding | Headline-eligible? |
|---|---|
| `step` with a clean change-point date | **Yes — highest headline priority.** This is the single most actionable finding the entire RCA tree can produce. |
| `step` without a parseable date (date missing from `analyse_metric_notes`) | No — downgrade to supporting material |
| `slope`, `oscillating`, `spike` | No — supporting findings, surface below the headline |
| `unclassified` | No — honest "shape unclear" note |
| DoW contamination flagged | No — caveats other findings, doesn't headline on its own |
