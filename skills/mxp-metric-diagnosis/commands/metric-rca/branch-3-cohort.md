# Branch 3 — Cohort decomposition (Step 7)

**The fundamental question: did the users change, or did their experience
change?** Splits users by acquisition date, compares new cohort behavior
to existing cohort behavior.

Writes to `rca_context.branch_3_findings` (schema in `preflight.md`).

This is the most strongly gated branch in the tree. Runs only when the
data supports it.

---

## 7.1 Gating logic (metric-type-aware)

Branch 3 runs user-property filters on `$first_seen` to split cohorts.
It gates on `rca_context.first_seen_available` from Step 2.5. Retention
metrics are a carve-out — their cohort structure is baked into the
report itself and doesn't depend on `$first_seen` being populated.

| Metric type | `first_seen_available` | Branch 3 runs? |
|---|---|---|
| `count`, `unique_count`, `ratio`, `funnel` | `true` | Yes — full new-vs-existing + tenure sub-decomposition |
| `count`, `unique_count`, `ratio`, `funnel` | `false` | **Skip.** Record `skipped: true`, `skipped_reason: "$first_seen coverage below 50%"`. |
| `retention` | either | Yes — use the retention report's native cohort structure; `$first_seen` not required |

If Branch 3 is skipped, proceed to Branch 4. Note the skip in the final
output's "what this didn't check" section.

---

## 7.2 Cohort boundary — fixed 30-day window

The cut between "new" and "existing" users is a **fixed 30-day boundary**,
regardless of `rca_context.drift_window.end - drift_window.start`.

**Definition:**

- **New users** — `$first_seen` within the last 30 days from `drift_window.end`.
- **Existing users** — `$first_seen` more than 30 days before `drift_window.end`.

**Why fixed, not adaptive**: a window-matched cohort boundary is harder
to interpret and inconsistent across runs (the "new" label means different
things when the drift window shifts). Fixed 30d gives the CSA a stable
concept to reason about.

**Drift window mismatch warning**: if
`abs(drift_window_length_days - 30) > 7`, append to the output:

> "Note: 30-day cohort boundary doesn't align with the `<N>`-day drift
> window. New/existing labels are approximate — users first seen
> `<drift_window_length>`–30 days ago may be labelled 'existing' but
> are not long-term users."

Store the warning in `rca_context.branch_3_findings.boundary_warning`.

---

## 7.3 Primary split — new vs existing

**Queries** (two insights runs, each with a `$first_seen` user-property
filter, each using `timeComparison` to cover both windows in one call):
1. The metric restricted to users with `$first_seen` was since `drift_window.end - 30d` (new cohort).
2. The metric restricted to users with `$first_seen` was before `drift_window.end - 30d` (existing cohort).

Both filters use `DatetimePropertyFilter` with `resource: "user"`.

**Math per cohort**:

```
cohort_delta_pct      = (metric_recent - metric_prior) / metric_prior   # signed
cohort_volume_share   = cohort_events_recent / total_events_recent
cohort_contribution   = cohort_volume_share × cohort_delta_pct × 100
```

Apply `rca_context.dq_scaling_factor` to `cohort_contribution` before
classifying, same as Branches 1 and 2.

**Classification — four patterns**:

| Pattern | Condition | Interpretation | Customer conversation |
|---|---|---|---|
| **Acquisition-driven** | New cohort delta ≥10%, existing cohort delta <3% | New users behave differently; long-time users unchanged | Marketing, traffic mix, store rankings, new campaigns. Usually **not** a product problem. |
| **Experience-driven** | Existing cohort delta ≥10%, new cohort delta <3% | Something changed for people already using the product | Release regression, UX change, performance degradation. Usually **is** a product problem. |
| **Both changed** | Both cohorts delta ≥10%, same direction | Broad product issue OR two coincident effects | Fall through to tenure sub-decomposition (7.4) to separate. |
| **Mixed direction** | Cohorts moved in opposite directions | Compositional effect masking individual cohort behavior | Cross-reference Branch 1 Simpson's paradox check. |

---

## 7.4 Tenure sub-decomposition (Deep mode only)

In Deep mode, after the primary split, run the 4 tenure buckets to
catch lifecycle-pattern signals (onboarding vs activation vs engagement)
even when the new/existing split looks clean.

**In Quick mode, skip this section entirely** — 4 additional queries is
outside the Quick budget. Record `tenure_sub_decomposition_skipped: true`
with reason `"quick mode — tenure buckets deferred"`.

**Buckets** (by `$first_seen` relative to `drift_window.end`):

- **0–7 days** — brand new, first-week experience
- **8–30 days** — activation period
- **31–90 days** — early engagement
- **90+ days** — established users

**Queries**: four separate filtered runs — one per bucket. Each is an
insights query on the metric with a `$first_seen` user-property filter
bracketing the bucket's date range (two `DatetimePropertyFilter`
entries — `was since` the start and `was before` the end), plus
`timeComparison` to cover both windows. Mixpanel has no native
datetime-bucketing breakdown for user properties, so 4 queries is the
correct cost — there is no single-query version.

**Math**: Same as 7.3 — `tenure_delta_pct`, `tenure_volume_share`,
`tenure_contribution` scaled by DQ.

**Pattern detection**: check for a **monotonic tenure signal** — if
`abs(tenure_delta_pct)` trends in one direction across the 4 buckets
(strictly increasing or decreasing), flag it. Monotonic patterns are
structurally meaningful:

| Monotonic pattern | Likely meaning |
|---|---|
| Drop concentrated in 0–7 day bucket, tapering with tenure | **Onboarding regression** — first-week experience broke |
| Drop concentrated in 8–30 day bucket | **Activation gate** — users aren't getting to the "aha" moment |
| Drop grows with tenure (90+ day hit hardest) | **Established-user fatigue** — long-timers disengaging, often competitive or pricing driven |
| Flat across tenure buckets | **No lifecycle pattern** — drift is uniform across user age |

Store as `rca_context.branch_3_findings.tenure_pattern`.

---

## 7.5 Retention carve-out (retention metrics only)

When `metric_type = retention`, the primary split and tenure
sub-decomposition both use the **retention report's native cohort
structure** instead of querying by `$first_seen`:

- **"New" cohorts** — acquisition cohorts from the drift window.
- **"Existing" cohorts** — acquisition cohorts from the baseline window, measured at the same retention day.
- **Tenure buckets** — map cohort-age buckets to the 4 tenure buckets where possible (D0–D7 cohort age = 0–7 day tenure, etc.).

Math and classification stay the same. The retention carve-out is purely
about *how* we slice; the interpretation patterns still apply. Set
`rca_context.branch_3_findings.retention_carve_out_used = true`.

---

## 7.6 Exit rules

Branch 3, like Branch 2, **never halts the tree walk**. Always proceed
to Branch 4.

| Finding | Headline-eligible? |
|---|---|
| Clean acquisition-vs-experience split (one cohort clearly dominant) | Yes — this is usually the strongest narrative branch for customer conversations |
| Monotonic tenure pattern (onboarding / activation / established fatigue) | Yes — highly actionable lifecycle signal |
| Both cohorts moved similarly + flat tenure | No — broad finding, defer headline to other branches |
| Mixed direction | No — hand off to Branch 1 Simpson's finding if one exists |
| Skipped | No — nothing to report |
