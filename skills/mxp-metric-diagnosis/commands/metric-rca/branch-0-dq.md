# Branch 0 — Data quality gate (Step 4)

**Runs first, always. No exceptions.** Before any behavioral analysis,
verify the metric itself is trustworthy in the drift window.

Runs in both Quick and Deep modes. If Branch 0 concludes the movement
is primarily a data quality incident, the tree walk stops here and the
customer conversation becomes an instrumentation handoff — not a product
discussion.

Writes to `rca_context.dq_contribution`, `rca_context.dq_primary_check`,
`rca_context.dq_findings`, `rca_context.dq_band`,
`rca_context.dq_scaling_factor` (schema in `preflight.md`).

---

## 4.1 Checks

Six checks, grouped by cost. Run the cheap ones (1–2) first; they often
short-circuit the expensive ones.

| # | Check | Scope | What it detects | Cost |
|---|---|---|---|---|
| 1 | **Backfill flag** | All events | `rca_context.backfill_suspected` from Step 2.3 — if `$import=true` volume share shifted ≥5pp between windows, the customer ran a backfill mid-period | 0 queries (already resolved) |
| 2 | **Event volume sanity** | Base event of the metric | Did the underlying event's total count drift/anomaly in parallel with the metric? If the event dropped 40% and the metric dropped 40%, it's tracking, not behavior. | 1 query (total count of base event, drift window vs. baseline window) |
| 3 | **Property null rate shift** | Every property used in `default_filters` and the metric definition | For each filter property: has the `is set` rate shifted between windows? A property silently returning null for 20% of events will tank any ratio metric. | 2 queries per filter property (`is set` count + total count, each window — `timeComparison` handles the window pair), usually 2–6 total |
| 4 | **Type drift** | Every event and property used in the metric | Has a property's type drifted mid-window? | 1 query to `Get-Issues` scoped to the metric's base event + filter properties |
| 5 | **New event variants** | Lexicon | Fuzzy-match the base event name against the full Lexicon to find near-duplicates (e.g. `checkout_completed` vs `checkout_success`). For each near-duplicate, check its volume in the drift window — a variant with ≥10% of the base event's drift-window volume is a siphon suspect. | 1 `Get-Events` call + 1 `Run-Query` per suspect (usually 0–3 suspects) |
| 6 | **App-version schema change** | Client SDK libraries only | Break down the base event by `$app_version`. For each major version with ≥5% drift-window volume share, probe whether the metric's filter properties are `is set` at materially different rates versus baseline versions. A version where a filter property is `is set` <50% as often as in other versions is a schema-change suspect. | 1 query per client SDK library for the version breakdown + 1 `is set` probe per (version, metric filter property) pair. Typically 3–6 queries per library. |

**Scoping rules** (don't fire pointless queries):
- Check 6 only runs if `rca_context.ingestion_split.client_sdk` ≥ 20%.
  No app-version check for Track API or Import API events.
- Check 3 skips if the metric has no filter properties (pure count on
  the base event).
- Check 1 is free (data's already in context).

---

## 4.2 Per-check contribution math

Each check produces a `dq_contribution_pct` between 0 and 100. Math is
check-specific:

**Check 1 — Backfill flag:**
```
volume_share_import_drift  = ingestion_split.import_api
volume_share_import_base   = ingestion_split_baseline.import_api
dq_contribution = abs(volume_share_import_drift - volume_share_import_base) × 100
```
A 20pp shift in Import API share → 20% DQ contribution. Caps at 100.

**Check 2 — Event volume sanity:**
```
event_delta_pct  = (base_event_count_recent - base_event_count_prior) / base_event_count_prior
metric_delta_pct = rca_context.verdict_magnitude   # already signed %

# The fraction of the metric's movement that the underlying event's movement explains
dq_contribution = min(abs(event_delta_pct / metric_delta_pct), 1.0) × 100
```
If event dropped 40% and metric dropped 40% → 100%. If event dropped 5%
and metric dropped 40% → 12.5% (event stable-ish; metric movement is
behavioral).

**Check 3 — Property null rate shift:**
```
null_rate_shift_pp = null_rate_drift - null_rate_baseline   # percentage points
dq_contribution    = abs(null_rate_shift_pp)   # already in 0–100 range
```
For multiple filter properties: **max across properties**, not sum.

**Checks 4, 5, 6 — Binary-ish checks:**
Each returns 0 or a fixed contribution value when triggered, because
they don't produce a natural continuous magnitude:
- Type drift in a metric-relevant property: **50%** (severe — the
  metric definition itself is compromised)
- Near-duplicate event siphoning ≥10% of base event drift-window
  volume: **variant's drift-window volume share × 100** (e.g., variant
  takes 25% of base event volume → 25%)
- App-version schema change affecting metric-relevant events: **40%**
  if a high-share version shows a ≥50% drop in `is set` rate for any
  metric filter property versus other versions, **0%** otherwise

---

## 4.3 Combining into a single DQ contribution

**Take the max across all six checks, not the sum.** Summing would
double-count when two checks surface the same root cause (e.g., a new
app version that also drove type drift on its new properties).

```
rca_context.dq_contribution = max(c1, c2, c3, c4, c5, c6)
rca_context.dq_primary_check = <name of the check that produced the max>
rca_context.dq_findings      = [list of every triggered check + its contribution]
```

Store `dq_findings` even for sub-threshold checks — the final output
should still mention "we checked these 6 things, 2 triggered but
sub-threshold" so the CSA sees the scope of what was ruled out.

---

## 4.4 Exit rules

| `dq_contribution` | Action | Downstream effect |
|---|---|---|
| **≥50%** | **STOP the tree walk.** Skip all behavioral branches. Produce a data-quality-framed output, not a behavioral one. | Headline becomes "Movement is primarily a data quality incident: `<dq_primary_check>`." Customer conversation is an implementation/engineering handoff, not product. |
| **10%–50%** | **Proceed to behavioral branches.** Every downstream branch's `contribution_pct` gets scaled down by `(1 - dq_contribution/100)` so behavioral attribution doesn't double-count DQ-driven movement. | Final headline is prefixed: *"After accounting for `<X>%` data quality contribution, the remaining movement is..."*. Every segment finding notes its post-scaling magnitude. |
| **<10%** | **Proceed clean.** No scaling. | Final output includes a one-line "Data quality checked and cleared (`<list of checks run>`)" note in the disclosure section. |

Set `rca_context.dq_band` to `"severe" | "material" | "clean"` based on
the three rows above. Set `rca_context.dq_scaling_factor`:
- `clean` → `1.0`
- `material` → `1 - (dq_contribution / 100)`
- `severe` → `0.0` (moot — behavioral branches skipped)

---

## 4.5 Quick mode note

Branch 0 runs in full even in Quick mode — the 6 checks are cheap and
skipping them defeats the whole "rule out DQ first" principle. Quick mode
skips *behavioral* branches after Branch 1, not Branch 0 itself.
