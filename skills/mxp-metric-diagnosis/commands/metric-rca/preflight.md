# Pre-flight resolution (Step 2)

Five resolution tasks run in order before any branch fires. All five
output into a single `rca_context` object that every branch reads from.
No branch re-resolves its own inputs.

Pre-flight runs **without narrating each step to the user**. Two user
prompts may fire, both compact and only when needed:
- **2.2** — if metric type is ambiguous (formula / custom SQL edge cases)
- **2.4** — if Lexicon resolution is ambiguous for ≥1 dimension

Everything else is silent.

---

## 2.1 Load project profile

Resolve the metric's project profile from its saved-report definition and
from one lightweight probe. Do **not** hardcode filter names or column
conventions — what works in one project doesn't work in another.

Pull from `Get-Report` on the saved metric (or from the user's natural
language if the metric was defined inline):

- **Billing / account filter** — if present in the saved definition, capture the exact `propertyName` and `resource` (`event` vs `user`).
- **Exclusions** — same treatment for internal-user or email exclusions.
- **User-property filters** — verify they resolve with one lightweight probe query before running the full sweep.

Two-level breakdowns in `Run-Query` can return truncated result sets on
high-cardinality dimensions. Set `project_profile.row_cap = null` by
default; downstream queries flag suspiciously round result sizes
(exactly 1,000 / 3,000 / 10,000 rows with no tail) rather than relying
on a hardcoded cap.

Store as `rca_context.project_profile`. Every query downstream composes
its filters against this profile.

---

## 2.2 Classify metric type

If the handoff block has `metric_type: unknown`, classify via `Get-Report`
metadata plus query template inspection:

| Detected | Classification | Branch 2 behavior |
|---|---|---|
| Report type `funnels` | **funnel** | Step-by-step walk |
| Report type `retention` | **retention** | Cohort-age decomposition overrides Branch 3 defaults |
| Query template has A/B form or `% of total` | **ratio** | Numerator/denominator decomposition |
| Single-series count / unique count | **count** | Skip Branch 2 entirely |
| Formula metric / custom SQL / anything else | **ambiguous** | Ask user |

**Ambiguous fallback** (per design decision): ask the user once:

> "I can't confidently classify this metric as count-like or ratio-like.
> For Branch 2 decomposition: should I treat it as (a) a count — skip
> numerator/denominator math — or (b) a ratio — decompose into
> numerator and denominator components?"

Store the user's answer in `rca_context.metric_type`. Do not re-ask.

---

## 2.3 Resolve the ingestion-source classifier

Before any property sweeps, classify events in the metric's base event by
ingestion source using `$import` × `mp_lib`:

| `$import` | `mp_lib` present? | Source | Property sweep eligibility |
|---|---|---|---|
| `false` or absent | Yes | **Client SDK** | Full library-specific sweep (per 2.4) |
| `false` or absent | No | **Track API** | Country common check only; no platform/version/device/source |
| `true` | Either | **Import API** | Flag to Branch 0 as potential backfill; exclude from behavioral sweep |

Run one breakdown query on the metric's base event in the drift window
broken down by `$import` and `mp_lib` simultaneously. Store the volume
share of each source in `rca_context.ingestion_split`.

**Backfill check**: also compute the `$import = true` volume share in the
**baseline window**. If the delta between baseline and drift is ≥5
percentage points (either direction), flag `rca_context.backfill_suspected
= true`. Branch 0 will escalate this as a standard DQ check.

---

## 2.4 Resolve library-specific property map for Branch 1

The Branch 1 property sweep is **library-scoped**, not flat. For each
client SDK library present in `rca_context.ingestion_split` with ≥5%
volume share, resolve its property map:

**Common (run for every library):**
- **Country chain** — cascading drill-down: `mp_country_code` → `$region` → `$city`. Start at country; drill down only if one level concentrates ≥70% of movement. Never run all three in parallel.
- **Platform** — `$os` first, then `platform` or closest match available on the event.

**When `mp_lib = web`** (overrides common Platform):
- Platform: `$browser`
- Source chain: `utm_source` → `source` → `acquisition_source` → `referrer_source`
- Device chain: `$device` → `$model`

**When `mp_lib ∈ {android, ios, swift}` (native):**
- Version: `$app_version_string`
- Device: `$model`
- (Source generally absent on native — skip unless a custom property resolves)

**Resolver logic — three phases, not per-property:**

**Phase 1 — Cache check (once, up front).** Read the property-map cache
(see "Cache location" at the end of this file). If the cache has a
`mappings` entry for the metric's `base_event` **and** the entry's
`resolved_at` is newer than the most recent Lexicon update on that event
(fetched via `Get-Events` metadata), use the cached map for every
library/dimension and skip to Phase 3 cache writeback (no-op) and the
user-level probe. No further Lexicon queries needed.

**Phase 2 — Lexicon probe (only if cache miss or stale).** For each
eligible library, call `Get-Property-Names` scoped to the base event
once per library. For each dimension, resolve against the candidate
list:

- **Exactly one candidate resolves** → use silently.
- **Multiple candidates resolve** → defer to the batched confirmation
  below.
- **No candidate resolves** → skip that dimension, log to
  `rca_context.missing_dimensions`. Final output will surface the gap.

**Phase 3 — Batched user confirmation (only if ≥1 dimension is
ambiguous).** Collect every ambiguous dimension across all libraries and
ask the user in a single prompt. Never fire per-dimension prompts.

> "Confirming Branch 1 property mappings for project `<id>` on
> event `<base_event>`:
> - Web → Platform: `$browser`, Country: `mp_country_code`, Source: `utm_source`, Device: `$device`
> - iOS → Version: `$app_version_string`, Country: `mp_country_code`, Device: `$model`
> - Android → (same as iOS)
>
> OK to proceed, or should I swap any of these?"

If no dimensions were ambiguous, skip the prompt entirely — fully
silent resolution.

**Cache writeback**: after resolution (with or without user confirmation),
write the mapping to the cache with schema:

```json
{
  "project_id": 2852656,
  "mappings": {
    "<base_event>": {
      "web": {"platform": "$browser", "country": "mp_country_code", ...},
      "ios": {"version": "$app_version_string", ...},
      "android": {...}
    }
  },
  "resolved_at": "<ISO timestamp>",
  "last_lexicon_update": "<ISO timestamp from Get-Events>"
}
```

Re-confirm only when the base event or its Lexicon entry changes.

### Cache location

Mixpanel MCP does not expose a durable filesystem to Claude, so the cache
is **scoped to the current conversation only**. Treat the cache as an
in-conversation scratchpad object with the schema above. If the
conversation ends, the cache is gone — the next `metric-rca` run on the
same project will re-resolve via Phase 2.

When Claude is run inside Claude Code or a similar environment with
filesystem access, the cache can persist as `cache/<project_id>.json`
in the skill working directory. That's a convenience, not a requirement.

---

## 2.5 Probe `$first_seen` availability

Branches 2 and 3 need to filter the metric by `$first_seen` (a user
property) to split new vs existing users and walk tenure buckets. Some
projects don't track `$first_seen` reliably — either because the SDK
never populated it, or because it got overwritten by an import.

Run **one** minimal probe: the base event with a `$first_seen is set`
user-property filter, counted in the drift window.

- If the count is ≥ 50% of the unfiltered base event count in the same
  window → set `rca_context.first_seen_available = true`. Branch 3 will
  run at full fidelity.
- If the count is < 50% or the query errors → set
  `rca_context.first_seen_available = false`. Record the reason in
  `rca_context.first_seen_skipped_reason`.

Downstream consequences:
- Branch 3 primary split (new vs existing): skips if `false`.
- Branch 3 tenure sub-decomposition: skips if `false`.
- Branch 2 (funnel / retention / ratio) is unaffected — none of those
  paths depend on `$first_seen`.

---

## The `rca_context` object — single source of truth

Every branch from Branch 0 onward reads from and writes to this single
object. **This schema is authoritative.** Individual branch files
reference these fields by name but do not re-specify their shape.

```
rca_context = {
  # From handoff block (Prerequisites of metric-rca.md)
  project_id, metric_name, metric_definition, metric_type,
  query_template, default_filters,
  verdict, verdict_magnitude, verdict_direction, verdict_shape,
  drift_window, baseline_window, analyse_metric_notes,

  # From Step 2 (pre-flight) — this file
  project_profile: {billing_filter, row_cap, email_exclusion, ...},
  ingestion_split: {client_sdk: 0.xx, track_api: 0.xx, import_api: 0.xx},
  ingestion_split_baseline: {...},          # for backfill check
  backfill_suspected: bool,
  branch_1_property_map: {
    web: {platform, country, source, device},
    ios: {version, country, device},
    android: {...},
    swift: {...},
  },
  missing_dimensions: [...],                # dimensions with no property resolved
  first_seen_available: bool,
  first_seen_skipped_reason: str | null,

  # From Step 3 (mode selection)
  mode: "quick" | "deep",

  # From Step 4 (Branch 0 — see branch-0-dq.md)
  dq_contribution: float,          # 0-100, max across all 6 checks
  dq_primary_check: str,           # name of the check that produced the max
  dq_findings: [...],              # every triggered check + its contribution
  dq_band: "severe" | "material" | "clean",   # ≥50 / 10–50 / <10
  dq_scaling_factor: float,        # 1.0 if clean, else (1 - dq_contribution/100)

  # From Step 5 (Branch 1 — see branch-1-dimensional.md)
  branch_1_findings: {
    exit_layer: int,               # 0, 1, or 2
    exit_reason: str,               # concentrated | broad_based | simpsons_paradox | truncation
    top_findings: [                 # top 3–5 segments, ranked by scaled contribution
      {
        layer: int,
        library: str | null,
        dimension: str,
        segment_value: str,
        volume_share_drift: float,
        metric_delta_pct: float,
        contribution_pct: float,
        contribution_pct_scaled: float,   # post-DQ scaling
      },
      ...
    ],
    simpsons_paradox_detected: bool,
    simpsons_paradox_details: dict | null,
    layer_2_truncations: [...],     # cardinality-cap issues
    libraries_swept: [...],
    dimensions_skipped: [...],
  },

  # From Step 6 (Branch 2 — see branch-2-structural.md)
  branch_2_findings: {
    path: "skipped" | "ratio" | "funnel" | "retention",
    skipped_reason: str | null,
    # path-specific fields: see branch-2-structural.md sections 6.1 / 6.2 / 6.3
    # ratio: num_delta_pct, den_delta_pct, classification, headline_component, supporting_components
    # funnel: step_deltas, causal_step, leading_indicators
    # retention: day_deltas, causal_day, interpretation_pattern
    headline_eligible: bool,
    contribution_pct_scaled: float,
  },

  # From Step 7 (Branch 3 — see branch-3-cohort.md)
  branch_3_findings: {
    skipped: bool,
    skipped_reason: str | null,
    cohort_boundary_days: 30,
    boundary_warning: str | null,
    new_cohort: {delta_pct, volume_share, contribution_scaled},
    existing_cohort: {delta_pct, volume_share, contribution_scaled},
    classification: "acquisition_driven" | "experience_driven" | "both_changed" | "mixed_direction" | null,
    tenure_sub_decomposition_skipped: bool,
    tenure_sub_decomposition_skipped_reason: str | null,
    tenure_buckets: [
      {bucket, delta_pct, volume_share, contribution_scaled},
      ...
    ],
    tenure_pattern: "onboarding_regression" | "activation_gate" | "established_fatigue" | "flat" | null,
    retention_carve_out_used: bool,
    headline_eligible: bool,
  },

  # From Step 8 (Branch 4 — see branch-4-temporal.md)
  branch_4_findings: {
    shape_from_handoff: str,        # original verdict_shape (including "unclassified")
    shape_final: str,                # same as shape_from_handoff — Branch 4 does NOT re-classify
    cause_hypothesis: str,
    actionability: "highest" | "medium" | "low" | "none",
    step_change_date: str | null,    # sourced from analyse_metric_notes when shape = step
    dow_contamination: bool,
    dow_weekday_delta_max_pct: float,
    dow_downgraded_confidence: bool,
    headline_eligible: bool,
  },

  # From Step 9 (Branch 5 — see branch-5-correlated.md; skipped in Quick)
  branch_5_findings: {
    skipped: bool,
    skipped_reason: str | null,
    candidates_total: int,
    candidates_post_floor: int,
    candidates_filtered: int,
    reportable_events: [...],           # capped at 5
    opposite_direction_events: [...],    # capped at 5, noted separately
    no_correlated_movement: bool,
    headline_eligible: bool,              # always false
  },

  # From Step 10 (Branch 6 — see branch-6-disclosure.md; always runs, 0 queries)
  branch_6_findings: {
    disclosure_categories: [...],        # 4 or 5 entries
    drift_window_tailored_events: [...], # Indian festivals, cricket finals, etc. matching drift dates
    customer_context_label: str,          # "the JioHotstar team" | "the customer"
  },
}
```

**Change-point date sourcing** (note for Branch 4): when
`verdict_shape = step`, `analyse-metric`'s Phase B6 records the
change-point date inside `analyse_metric_notes`. Branch 4 parses it out
of there — it does not re-detect.

---

## Worked example — pre-flight output for the Nykaa case

For the Nykaa session-to-order conversion case from
`analyse-metric.md` (12.4% drop with a change-point on March 18),
pre-flight would populate the `rca_context` object roughly like this
before Step 3 fires:

```
rca_context (after Step 2) = {
  # from handoff block
  project_id: 2852656,
  metric_name: "Session → Order conversion rate",
  metric_type: "ratio",
  verdict: "drift",
  verdict_magnitude: -12.4,
  verdict_direction: "down",
  verdict_shape: "step",
  drift_window: {start: "2026-03-20", end: "2026-04-19"},
  baseline_window: {start: "2026-02-18", end: "2026-03-20"},
  analyse_metric_notes: "Change-point detected on 2026-03-18; 16w/60d views agree on direction.",
  # ...

  # from Step 2
  project_profile: {billing_filter: null, row_cap: null, email_exclusion: null},
  ingestion_split: {client_sdk: 0.88, track_api: 0.04, import_api: 0.08},
  ingestion_split_baseline: {client_sdk: 0.89, track_api: 0.04, import_api: 0.07},
  backfill_suspected: false,
  branch_1_property_map: {
    web: {platform: "$browser", country: "mp_country_code", source: "utm_source", device: "$device"},
    ios: {version: "$app_version_string", country: "mp_country_code", device: "$model"},
    android: {version: "$app_version_string", country: "mp_country_code", device: "$model"},
  },
  missing_dimensions: [],
  first_seen_available: true,
  first_seen_skipped_reason: null,
}
```

Step 3 then prompts with "Client SDK 88%, Track 4%, Import 8%, no
backfill, `$first_seen` available, no missing dimensions" — the user
has real signal before picking mode.

Downstream, Branch 4 reads `verdict_shape: step` and parses the date
out of `analyse_metric_notes` → `step_change_date: "2026-03-18"`. Branch
1 Layer 2 runs the property sweep across web / ios / android using the
property map above. Branch 2 routes to the ratio path (6.1).
