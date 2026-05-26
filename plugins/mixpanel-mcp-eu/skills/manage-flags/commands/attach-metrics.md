# Command: attach-metrics

Bind a flag to its measurement plan. Typical shape: **1 success metric +
2–3 guardrails**. The guardrail set is PM-shaped by default — business
KPIs, counter-metrics, optional UX/reliability metrics — not engineering
counter-metrics.

The metric IDs are persisted into the flag's rollout-state JSON so
`run-rollout` and `analyze-impact` read the same set. Once metrics are
attached and a rollout is in flight, the set is locked.

This command can be invoked standalone for a flag that already exists,
or chained from `plan-rollout` before `run-rollout`.

---

## Prerequisites

Steps 0 and 1 from `SKILL.md` must complete:

- Step 0 (flag resolution): a flag must exist or be queued for creation.
- Step 1 (project resolution).

Connector and project ID come from `config.md`.

---

## Phase 1 — Ground in Business Context

Before proposing any metric, call `Get-Business-Context` for the
project. The output describes the business KPIs the customer has
already declared important — revenue, retention, conversion targets.

Two reasons this matters:

1. The success metric for a flag rollout should usually be the *closest
   tracked KPI to what the feature is trying to move*. Anchoring against
   Business Context prevents drift into one-off metric definitions.
2. The first guardrail proposal should default to a business KPI most
   at risk if the feature backfires.

If `Get-Business-Context` returns nothing useful (project hasn't filled
it in), continue with PM-shaped defaults but surface the gap: "no
business context defined for this project — recommend filling it in
later for cleaner rollout retrospectives."

---

## Phase 2 — Propose the success metric

Ask the PM in plain language: *what's the one outcome you'd hold this
release accountable to?*

Common patterns:

- Checkout flow change → checkout conversion rate
- Onboarding redesign → activation rate (or D7 retention of new users)
- New paywall variant → paid conversion rate
- Search ranking change → search → click-through rate

**Step 1: Search for a reusable saved metric.**

Call `Search-Entities` with the PM's phrasing. If `List-Metrics` returns
candidates with similar names, surface them and ask. Reuse-first
posture — duplicate metrics in the catalog are the most common cause of
later confusion in retrospectives.

**Step 2: Confirm the definition.**

For any matched metric, call `Get-Metric` and surface the actual
definition (event, filters, aggregation method). The PM confirms it
matches what they meant.

**Step 3: Propose a new metric only if no match exists.**

If no reusable match, propose a fresh definition. Show it as a draft:
event, filters, aggregation, breakdowns. **Do not call `Create-Metric`
yet** — require explicit PM approval first.

On approval, `Create-Metric`. Capture the returned ID.

---

## Phase 3 — Propose the guardrail set

Three default categories, in this order. Always propose **at least one
counter-metric** — the thing most likely to silently regress when the
success metric improves.

### Category A — Business KPI guardrail (default to one)

The metric most at risk if the feature backfires, drawn from Business
Context if possible. Examples:

- Success metric is checkout conversion → guardrail is *revenue per
  session* (catches a conversion lift that comes from cheaper baskets).
- Success metric is signup conversion → guardrail is *7-day retention
  of new signups* (catches "we tricked more people into signing up but
  they don't come back").
- Success metric is feature engagement → guardrail is *paying user
  retention* (catches engagement that pulls users away from value).

### Category B — Counter-metric (required)

The metric that moves *in the opposite direction* when the success
metric improves for the wrong reasons. Examples:

- Success: checkout conversion → counter: post-checkout cancellation rate
- Success: signup conversion → counter: 7-day churn of new signups
- Success: time-on-page → counter: bounce-back-to-search rate
- Success: feature engagement → counter: support ticket volume on the
  changed surface

If no obvious counter-metric exists for the success metric, surface that
and ask the PM to name one.

### Category C — UX / reliability guardrail (optional)

Error rate, latency, crash rate, or any reliability metric the PM wants
to protect. Skip if the PM doesn't want it.

---

## Phase 4 — Resolve thresholds

For each guardrail, set the trigger threshold (relative degradation %
that triggers a pause):

- Default from `config.md`: `2.0%` relative degradation.
- The PM can override per-metric. Common override: tighter (1.0%) on a
  counter-metric, looser (5.0%) on a noisy support-volume metric.

Surface the defaults; require explicit confirmation or override.

---

## Phase 5 — Compute baselines

For each bound metric, compute a pre-rollout baseline over a recent
stable window (default last 14 days). `Run-Query` per metric, scoped to
the user population that the targeting will match (so the baseline is
apples-to-apples with what `run-rollout` will measure later).

Baselines are persisted in the rollout-state JSON. They are not
recomputed during the rollout — that's the whole point of pre-registration.

---

## Phase 6 — Persist into state

Update (or initialize) the flag's rollout-state JSON. Fields touched:

```json
{
  "metric_ids": {
    "success": "<id>",
    "guardrails": ["<id1>", "<id2>", "<id3>"]
  },
  "guardrail_thresholds": {
    "default_relative_degradation_pct": 2.0,
    "overrides": { "<id1>": 1.0 }
  },
  "baselines": {
    "<id_success>": { "value": ..., "computed_at": "..." },
    "<id_guard1>": { "value": ..., "computed_at": "..." }
  }
}
```

Write back via `Update-Feature-Flag`, preserving any human description
above the state markers.

If the flag doesn't exist yet (the metric plan was built before flag
creation), persist the plan in conversation context only — `run-rollout`
will create the flag and write state on its first invocation.

---

## Output

```markdown
## Metrics Attached — <flag name>

### Success metric
- `checkout_conversion_v2` (reused saved metric)
- Definition: unique users completing `purchase` event after `cart_view`,
  by day
- Baseline (last 14d, target cohort): **14.2%**

### Guardrails
| Metric | Type | Baseline | Threshold |
|---|---|---|---|
| `revenue_per_session` | Business KPI | $4.18 | -2% relative |
| `post_checkout_cancellation_rate` | Counter-metric | 1.8% | -1% relative (tighter) |
| `error_rate_checkout_surface` | UX / reliability | 0.18% | -2% relative |

### Notes
- Business Context anchor: `revenue_per_session` is one of the project's
  tracked KPIs.
- Counter-metric chosen on the assumption that conversion gains could be
  offset by buyer's remorse cancellations within 24h.

### Next step
→ Run `run-rollout` to start stage 1.
```

---

## What this command does NOT do

- **Silently create metrics.** Every `Create-Metric` call requires
  explicit PM approval on the proposed definition.
- **Recompute baselines mid-rollout.** Baselines are locked at attach
  time. If the PM thinks the baseline is wrong, re-invoke this command
  fresh — and log the change in `history`.
- **Bind more than one success metric.** v1 enforces exactly one. If
  the feature has multiple outcomes, route to `manage-experiments` and
  use the secondary metric slots there.
- **Define metrics outside the project's Lexicon.** Every metric must
  resolve to existing events and properties in the project.
- **Compute statistics.** Baselines are point estimates, not confidence
  intervals. Passthrough posture.
