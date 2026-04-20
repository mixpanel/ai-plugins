# Branch 2 — Structural decomposition (Step 6)

**Conditional branch.** Runs different logic per metric type, and skips
entirely for pure count metrics. The goal is to isolate *which component*
of the metric moved — numerator vs denominator for ratios, which step for
funnels, which retention day for retention.

Writes to `rca_context.branch_2_findings` (schema in `preflight.md`).
Path-specific fields (ratio / funnel / retention) are listed in this
file; the common wrapper (`path`, `skipped_reason`, `headline_eligible`,
`contribution_pct_scaled`) is in the schema.

Reads `rca_context.metric_type` (resolved in Step 2.2) and routes:

| Metric type | Branch 2 path |
|---|---|
| `count`, `unique_count` | **Skip.** Proceed to Branch 3. Record `path: "skipped"` with `skipped_reason: "count metric — no components to decompose"`. |
| `ratio` | 6.1 — Numerator/denominator decomposition |
| `funnel` | 6.2 — Funnel step walk |
| `retention` | 6.3 — Retention day walk |

All three non-skip paths apply the DQ scaling factor
(`rca_context.dq_scaling_factor`) to their contribution numbers the
same way Branch 1 did.

None of Branch 2's paths depend on `$first_seen` — they operate on the
metric's own components (numerator/denominator, funnel steps, retention
days), all of which are fully supported at the aggregate level.

---

## 6.1 Ratio metrics — numerator/denominator decomposition

For metrics of the form A/B (conversion rate, session rate, any rate
or ratio).

**Query**: One query returning the numerator series and denominator
series separately across both windows. For most saved Mixpanel reports
this means two `Run-Query` calls — one for the numerator event/count,
one for the denominator. Use the metric definition's underlying
components from `rca_context.query_template`.

Ratio decomposition runs at the aggregate level (numerator count,
denominator count, both per window). No per-user breakdown needed.

**Math per component**:

```
num_delta_pct = (num_recent - num_prior) / num_prior
den_delta_pct = (den_recent - den_prior) / den_prior
```

**Classification**:

| Condition | Classification | Customer conversation |
|---|---|---|
| `abs(num_delta_pct) ≥ 10%` and `abs(den_delta_pct) < 3%` | **Numerator-driven** | Behavior shift in the converting population. Product-side investigation. |
| `abs(den_delta_pct) ≥ 10%` and `abs(num_delta_pct) < 3%` | **Denominator-driven** | Volume/mix story, not behavior. "More/fewer people landing here, same fraction convert." Cross-reference with Branch 1 Source findings. |
| Both moved ≥10% | **Both moved — user base changed** | Usually means the user base itself changed. Cross-reference Branch 1 (acquisition source) and Branch 3 (cohort) when those run. |
| Neither moved ≥10% | **Tiny movements on both sides amplifying into a ratio shift** | Note as a precision-limit finding; ratio is sensitive to small absolute changes at low volume. |

**Path-specific fields written to `rca_context.branch_2_findings`** (in
addition to the common wrapper fields defined in `preflight.md`):
- `num_delta_pct`
- `den_delta_pct`
- `classification: "numerator_driven" | "denominator_driven" | "both_moved" | "marginal"`
- `headline_component: "numerator" | "denominator" | "both" | null`
- `supporting_components` — always includes both num and den for context

**Exit rules for 6.1**:

| Finding | Continue to Branch 3? |
|---|---|
| Numerator-driven or denominator-driven (clean attribution) | Yes — Branch 3 cohort view may add the *who* to Branch 2's *which component*. |
| Both moved | Yes — Branch 3 is likely to concentrate (this is the classic acquisition-driven signal). |
| Marginal | Yes — Branch 3 and 4 may still find something. |

No early tree-walk termination from Branch 2 ratio — it informs the
narrative but doesn't close it.

---

## 6.2 Funnel metrics — step-by-step walk

For funnel reports, decompose by step transition and identify which
step drifted.

**Query**: `Run-Query` against the funnel report in both drift and
baseline windows, returning per-step conversion rates. Walk steps at
the aggregate level; Mixpanel's funnel report returns per-step
conversion natively.

**Math per transition (step N → step N+1)**:

```
step_conv_recent = count(step_N+1_recent) / count(step_N_recent)
step_conv_prior  = count(step_N+1_prior)  / count(step_N_prior)
step_delta_pp    = step_conv_recent - step_conv_prior   # percentage points
```

**Identify the causal step**: walk transitions in order and find the
**first** step where `abs(step_delta_pp) ≥ 3pp`. Per the design doc,
the first drifted step is usually the causal one — downstream drift is
often propagation, not new information.

**Hidden leading indicators**: Even if a middle step drifted and the
overall funnel outcome looks normal, surface it. A middle-step shift is
a leading indicator the customer should care about before it propagates.

**Path-specific fields written to `rca_context.branch_2_findings`**:
- `step_deltas` — list of `{step_name, step_conv_recent, step_conv_prior, step_delta_pp}`
- `causal_step: {step_name, step_delta_pp} | null` — first ≥3pp drifted step
- `leading_indicators` — middle-step shifts that didn't move overall

**Exit rules for 6.2**:

| Finding | Continue to Branch 3? |
|---|---|
| Causal step identified cleanly (one step drifted, rest stable) | Yes — Branch 3 asks whether the shift is cohort-specific. |
| Multiple steps drifted | Yes — suggests broader product/UX issue, Branch 3/4 likely to add signal. |
| No step drifted ≥3pp but overall funnel still moved | **Unusual.** Likely a cohort-mix or volume-mix effect; flag in output and continue to Branch 3 with a note. |

---

## 6.3 Retention metrics — retention day walk

For retention reports, decompose by retention checkpoint (D1, D7, D30,
or whatever days the report exposes) and identify which day shifted.
Conceptually parallel to 6.2's funnel step walk — walk each checkpoint,
find which one moved.

**Query**: `Run-Query` against the retention report pulling retention
rate at each available day (D1, D7, D30 standard; D14, D60, D90 if
instrumented). Drift window cohorts vs baseline window cohorts. Runs
at the cohort-aggregate level using the retention report's native
cohort structure.

**Math per day**:

```
retention_day_recent = % of drift-window cohort retained at day N
retention_day_prior  = % of baseline-window cohort retained at day N
day_delta_pp         = retention_day_recent - retention_day_prior
```

**Identify the causal day**: find the **earliest** retention day
where `abs(day_delta_pp) ≥ 3pp`. Same logic as funnels — earlier
checkpoints drifting is usually more causal than later ones, because
later retention is conditional on earlier retention.

**Interpretation patterns to surface**:

| Pattern | What it means | Customer conversation |
|---|---|---|
| D1 dropped, D7/D30 proportional | Activation problem | First-session experience or onboarding regressed |
| D1 stable, D7 dropped | Week-1 engagement cliff | Something in the week-1 experience stopped working |
| D1/D7 stable, D30 dropped | Long-term engagement decay | Harder to attribute — often competitive or market factors |
| All days dropped proportionally | Cohort itself is different | Not a retention problem per se — acquisition shifted. Cross-reference Branch 3. |

**Path-specific fields written to `rca_context.branch_2_findings`**:
- `day_deltas` — list of `{retention_day, rate_recent, rate_prior, day_delta_pp}`
- `causal_day: {retention_day, day_delta_pp} | null`
- `interpretation_pattern: "activation" | "week1_cliff" | "long_term_decay" | "cohort_shift" | "unclear"`

**Exit rules for 6.3**:

| Finding | Continue to Branch 3? |
|---|---|
| Causal retention day identified with a clean pattern | Yes — Branch 3 refines by cohort tenure. |
| All days proportional (cohort shift pattern) | Yes — Branch 3 is very likely to concentrate. This pattern is nearly always acquisition-driven. |
| No day drifted ≥3pp but overall retention curve moved | Flag as a precision-limit finding; continue. |

---

## 6.4 Exit rules for Branch 2 as a whole

Branch 2 **never stops the tree walk**. Unlike Branch 0 (DQ severity
can halt) and Branch 1 (Layer 0 concentration on non-SDK ingestion can
halt), Branch 2 always proceeds to Branch 3. The structural finding
informs the narrative but doesn't close it.

Exception: if Branch 2 is skipped for a count metric, proceed to
Branch 3 with nothing from Branch 2.
