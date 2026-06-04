# `Get-Experiment` Field Map

Quick reference for which `Get-Experiment` response field drives each interpretation. Always call with `compute_exposures=true, compute_metrics=true`.

This reference is **read-only domain knowledge** for the agent. It does NOT define thresholds — every "fail condition" listed below is a _characterization_ of how the platform itself already classifies the field, not a threshold this skill should re-apply.

---

## Identity & lifecycle

```
id, name, description, hypothesis, status, start_date, end_date
creator_email, tags, url, workspace_id
feature_flag_id                       → for feature-flag-based experiments
settings.controlKey                   → variant key treated as control (often "control"; may be "")
```

`status` is one of `"concluded" | "success" | "fail"` (the UI may additionally show `SUCCESS_DEFERRED` for the special variant constant — see "Decision metadata" below).

---

## Trustworthiness

```
live_srm_analysis                     → SRM verdict (consume — don't recompute)
  .p_value
  .chi_square
live_exposures[<variantKey>]          → per-variant exposure counts (live)
exposures_cache[<variantKey>]         → per-variant exposure counts (cached fallback)
exposures_cache.$srm_analysis         → cached SRM analysis
exposures_cache.$last_computed        → when the cache was last refreshed
settings.srm.enabled                  → whether the SRM check ran
settings.srm.targetAllocations        → expected per-variant allocation (percent)
settings.preExperimentBias            → whether Retro A/A was enabled
settings.excludeQA                    → whether QA traffic was filtered
live_results_errors                   → non-null = live computation failed; surface and fall back to cache
```

---

## Per-metric per-variant results

```
live_metrics[<metricId>][<variantKey>]
  .value             → metric value for this variant
  .sampleSize        → sample size for this variant on this metric
  .lift              → (treatment - control) / control  (0 for control row)
  .liftConfidence    → confidence LEVEL used (e.g. 0.95) — NOT the CI width
  .significance      → "YES_POSITIVE" | "YES_NEGATIVE" | "NO"  (sign-of-lift, NOT polarity)

results_cache.metrics[<metricId>][<variantKey>]  → cached fallback, same shape
```

---

## Bucketed summary

```
results_cache.summary.positive[]      → items with significance == "YES_POSITIVE" (lift > 0, sig)
results_cache.summary.negative[]      → items with significance == "YES_NEGATIVE" (lift < 0, sig)
results_cache.summary.no[]            → items with significance == "NO"

Each item:
  .metricId
  .variant
  .value
  .lift
  .liftConfidence
  .sampleSize
  .significance
```

**Pre-process the summary**: filter rows where `variant == settings.controlKey` (control-vs-control is mechanical noise), then apply the polarity recipe before drawing any conclusion.

---

## Metric catalog (for polarity lookups)

```
metrics[]
  .id, .name
  .type ("primary" | "guardrail" | "secondary")
  .direction ("up" | "down")          → always set; defaults to "up" if the source metric was unset
```

Build a lookup `metric_id → (type, direction)` and join to summary rows during interpretation.

---

## Settings that change interpretation

```
settings.confidenceLevel              → significance threshold (e.g. 0.95)
settings.testingModel                 → "frequentist" or "sequential"
settings.endCondition                 → "sample_size" or "days"
settings.sampleSize / .endAfterDays   → planned end target
settings.multipleTestingCorrection    → "off" | "bonferroni" | "benjamini-hochberg"
settings.cuped.enabled                → CUPED variance reduction applied
settings.cuped.preExposureDatePreset  → pre-exposure window
settings.winsorization.enabled        → outlier capping applied
settings.winsorization.percentile     → cap percentile (default 95; lower values are extreme)
```

---

## Decision metadata (post-decide)

```
results_cache.message                 → decision rationale
results_cache.variant                 → shipped variant key (or special constant)
status                                → "concluded" | "success" | "fail"
```

Special variant constants for `success=true`:

- `__no_variant_shipped__` — ship the change without picking a variant.
- `__defer_variant_decision__` — defer (UI shows `SUCCESS_DEFERRED`).

For a kill, pass `success=false`.

---

## Lifecycle hand-off

```
Update-Experiment(
  experiment_id=<id>,
  experiment={
    "action": "decide",
    "success": true | false,
    "variant": "<winner_key>",      # required when success=true
    "message": "<rationale: metrics evaluated, polarity, tradeoffs accepted>"
  }
)
```

`message` is required on every `decide` call.

---

## Misconfig field map (cross-link)

For _how_ to react to each of these, see [health-check-interpretation.md](health-check-interpretation.md) §7.

- `settings.multipleTestingCorrection in {"off", null}` with 2+ primaries × 1+ non-control variants
- `settings.winsorization.enabled == true` with `percentile` very low (< ~80) or very high (> ~99)
- `settings.srm == null` OR `settings.srm.enabled == false` (often intentional — only flag if results look suspicious)
- `settings.cuped.enabled == true` AND the experiment cohort is "new users only"
- `settings.confidenceLevel != 0.95`
- `metrics[]` entries with `name == ""`
- A primary metric in `metrics[]` but missing from `live_metrics` AND `results_cache.metrics`

---

## When to reach for sibling tools

- **Setup quality questions** ("was this experiment powered correctly?", "what sample size did we need?") → defer to the setup-side skill / `Get-Experiment-Setup-Guidance`.
- **Raw data for triggered or segmentation analysis** → `Run-Query` on the metric with appropriate filters.
- **Acting on the recommendation** (ship, kill, extend) → `Update-Experiment` with the appropriate action.
- **Feature-flag rollout history** for SRM root cause → `Get-Feature-Flag`.
- **Session replays** for behavioral explanation of a quantitative result → the replay-fetch tool (see [session-replay-analysis.md](session-replay-analysis.md)).
