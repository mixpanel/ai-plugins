# Branch 1 — Dimensional decomposition (Step 5)

**The workhorse branch.** Re-runs the metric broken down by high-signal
dimensions and measures each segment's contribution to total movement.

Writes to `rca_context.branch_1_findings` (schema in `preflight.md`).

Runs in three layers, each with its own exit rule. Layers cascade: if
Layer 0 concentrates the movement, we stop and don't touch Layer 1 or 2.
If Layer 1 concentrates, we skip Layer 2 for that library.

**Mode behavior differs significantly for this branch:**
- **Deep mode**: full sweep across all eligible libraries in Layer 2.
  On cross-platform customers (web + iOS + Android) with multiple
  eligible dimensions per library, this branch alone can produce 15–25
  queries before Branch 5's adjacency scan adds more.
- **Quick mode**: Layer 0 + Layer 1 + Layer 2 **only for the top library
  by volume share** (~5–7 queries total for this branch).

---

## 5.1 Layer 0 — Ingestion source breakdown

Start with the coarsest cut: ingestion source (Client SDK / Track API /
Import API) from `rca_context.ingestion_split`.

**Query**: One breakdown of the metric (not just the base event) by
`$import` × `mp_lib`, in the drift window and baseline window. This is
distinct from the Step 2.3 pre-flight query — that one was on the base
event volume; this one is on the metric itself.

**Math** (applied per segment at every layer of this branch):

```
volume_share_drift    = segment_volume_drift / total_volume_drift
metric_value_drift    = segment_metric_value_drift
metric_value_baseline = segment_metric_value_baseline
metric_delta_pct      = (metric_value_drift - metric_value_baseline) / metric_value_baseline

contribution_pct      = volume_share_drift × metric_delta_pct × 100
```

If Branch 0 found DQ contribution 10–50%, apply the scaling factor from
`rca_context.dq_scaling_factor` to every `contribution_pct` before
ranking. This prevents double-counting DQ-driven movement.

**Exit rules for Layer 0:**

| Finding | Action |
|---|---|
| One ingestion source contributes ≥70% (and it's Client SDK) | **Exit Branch 1 early.** Report as "movement concentrated in Client SDK events" and go to Branch 2. |
| One ingestion source contributes ≥70% and it's **Track API** or **Import API** | **Stop the whole tree walk.** This is effectively a DQ finding that Branch 0 under-weighted. Escalate to the DQ output format with a note: "Movement is concentrated in [Track API / Import API] events — recommend implementation review." |
| Multiple sources contribute, no single one ≥70% | **Continue to Layer 1.** Cascade into per-library breakdown across Client SDK events only. Track API / Import API contributions stay in the report but aren't decomposed further. |

Run the Simpson's paradox check on this breakdown (see 5.4).

---

## 5.2 Layer 1 — Library breakdown (Client SDK events only)

Scoped to `$import = false` AND `mp_lib` is present. The three (or more)
libraries — web, ios, android, swift — get compared.

**Query**: One breakdown of the metric by `mp_lib`, Client SDK events
only, drift window vs. baseline window.

Rank libraries by absolute `contribution_pct`. Report top 3.

**Exit rules for Layer 1:**

| Finding | Action |
|---|---|
| One library contributes ≥70% | **Exit Layer 1 early.** Report as "movement concentrated on [library]" and proceed to Layer 2 **for that library only**. |
| 2–3 libraries contribute ≥70% combined | **Proceed to Layer 2 for those libraries** (skip libraries below the threshold in Quick mode; sweep all of them in Deep mode). |
| No library concentrates | **Broad-based movement across libraries** — a meaningful finding itself. Proceed to Layer 2 per the mode rules (top library only in Quick, all eligible in Deep). |

Simpson's check runs here too — especially relevant, because metric
direction shifts between libraries are common (iOS drops, Android rises,
total looks flat or mixed).

---

## 5.3 Layer 2 — Library-specific property sweep

For each eligible library (determined by mode + Layer 1 exit rule), run
the library's property map from `rca_context.branch_1_property_map`.

**Dimension order per library** (sweep in this order; stop when one
dimension in this library explains ≥70% of that library's contribution):

| # | Dimension | Applicable libraries | Why this rank |
|---|---|---|---|
| 1 | **Platform** | All (but library-aware: `$browser` for web, `$os` for native) | Highest-signal for most metrics |
| 2 | **App version** | Native only (`$app_version_string`) | Release regressions are the most actionable finding — skip for web |
| 3 | **Country** (cascading) | All | Surfaces localization, regional outages, payment gateway issues |
| 4 | **Source** | Web only (`utm_source` chain) | Catches traffic-mix drift; native SDK events rarely carry source |
| 5 | **Device** | All (`$model` for native, `$device` → `$model` for web) | Catches form-factor or low-end-device issues |

**Adaptive reordering when Branch 2 has classified first**: the dimension
order above is the default, but if the tree walk has already completed
Branch 2 and produced a ratio classification, adjust Layer 2 ordering:

- **Branch 2 = denominator-driven** → bump Country to rank 1 (denominator
  movement is often geo-mix: fewer / more people landing from a
  particular country), and Source to rank 2 for web libraries. Platform
  drops to rank 3.
- **Branch 2 = numerator-driven** → keep the default order (Platform
  first is fine — behavior shifts concentrate on platform most often).
- **Branch 2 = both moved** → keep default.

In practice Branch 2 runs *after* Branch 1 in the standard tree walk, so
this reordering only applies when a tree is re-walked after Branch 2
produces a signal (e.g., a user-driven deeper pass). Leave the default
order for first-pass runs.

For each dimension, run **one** two-level breakdown query: the metric
broken down by `mp_lib = [library]` + the dimension property. Drift
window vs. baseline window.

**Per-segment ranking**: rank dimension values by absolute
`contribution_pct`. Report top 3–5 per dimension.

### Cascading Country drill-down

Country is the one exception to "one query per dimension." It cascades:

1. First query: breakdown by `mp_country_code`. If one country
   contributes ≥70% within this library, drill into step 2.
2. Second query: breakdown by `$region` within the top country.
   If one region contributes ≥70% within that country, drill into step 3.
3. Third query: breakdown by `$city` within the top region.

Stop at whatever level concentrates. If no level concentrates, stop at
country and report the top 3 countries. **Never run all three in
parallel** — it's a drill-down, not a flat sweep.

Each drill-down level is a separate two-level breakdown query, so they
all need the truncation guard below.

### Cardinality / truncation guard

Every two-level breakdown in this layer needs a truncation check.
Mixpanel two-level breakdowns can silently truncate on high-cardinality
dimensions. Treat any result set whose row count lands on a suspiciously
round number (exactly 1,000 / 3,000 / 10,000 rows, with no clear tail of
low-volume segments) as potentially truncated.

- **Do not silently truncate**. Flag in `rca_context.branch_1_findings.layer_2_truncations`
  with the dimension name and library.
- **Attempt a recovery query**: pre-filter to the top 10 values of the
  dimension by volume, then re-break by the metric. This gives a
  representative attribution without hitting the cap.
- If recovery succeeds, use the recovered data and note "top-N filtered
  due to cardinality cap" in the output.
- If recovery fails or isn't feasible, output the truncated result with
  an explicit warning: "Attribution may be incomplete — dimension may
  have exceeded the project's two-level breakdown cap."

Silent truncation is the worst failure mode for this branch. Always check.

### Exit rules for Layer 2

| Finding within a library | Action |
|---|---|
| One dimension value contributes ≥70% of that library's movement | Exit that library's sweep. Record finding. |
| 2–3 dimension values together contribute ≥70% | Exit that library's sweep with a concentrated-drift finding. |
| No dimension concentrates | Record "broad-based within this library" and move to the next library (or exit Branch 1 if no more libraries). |

---

## 5.4 Simpson's paradox check (runs on every breakdown)

Fires **after every breakdown query in all three layers**. Not optional.

**Detection**:
- The overall metric moved in direction D (from `rca_context.verdict_direction`).
- For each segment in the current breakdown, compute `metric_delta_pct`
  with its sign.
- Flag Simpson's paradox if: ≥80% of segments (weighted by volume share)
  moved in the opposite direction from D, or were within ±2% of flat.

**What this means**: the overall movement isn't coming from segment
behavior — it's coming from **mix shift** (the composition of segments
changed, not what they did individually). This is a fundamentally
different customer conversation.

**Action when detected**:
- Tag the finding as `simpsons_paradox_detected: true`.
- Output phrasing overrides the normal segment-concentration language:
  *"Users didn't change — the mix of users did. [Metric] moved because
  [high/low]-value segment's share of volume changed from X% to Y% between
  windows."*
- Still record the segment-level contribution data for the appendix, but
  the headline treats this as a compositional finding, not a behavioral one.

---

## 5.5 Exit rules for Branch 1 as a whole

Branch 1 writes to `rca_context.branch_1_findings` (schema in
`preflight.md`) and exits per the table below.

| Finding | Headline-eligible? | Continue to Branch 2? |
|---|---|---|
| Layer 0 concentrated on non-Client-SDK ingestion | No (already escalated as DQ) | No — tree walk stopped |
| Simpson's paradox at any layer | Yes — compositional headline | Yes — Branch 2 may add signal |
| Layer 1 concentrated ≥70% on one library | Yes — "movement concentrated on [library]" | Yes |
| Layer 2 concentrated ≥70% on one dimension value | Yes — the most common headline | Yes, unless metric_type = count (then to Branch 3) |
| Broad-based across all layers | Yes — honest finding, flag for Branch 2/3 to potentially add signal | Yes |

Proceed to Branch 2 unless the tree walk was stopped by a DQ escalation
in Layer 0.
