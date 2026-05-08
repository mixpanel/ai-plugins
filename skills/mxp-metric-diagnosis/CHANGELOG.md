# Changelog

## 2026-04-30 — Tool-catalog alignment pass

Audit-driven edit pass aligning the skill with the live Mixpanel MCP tool
catalog. Fixes one correctness bug and unlocks one major RCA branch.

### Fixed
- **Step 1 ingestion path** (`SKILL.md`). Previously assumed `Get-Report`
  returned the underlying query definition — it does not (it returns
  metadata + native-granularity results only). Rewrote Step 1 so all input
  shapes converge on a single resolution path: confirm definition with
  the user, then build a fresh query body via `Get-Query-Schema` +
  `Run-Query`. `query_template` is now constructed from the schema, never
  lifted from a saved report's response.

### Added
- **Step 0a — `Get-Business-Context` first.** Added a session-level
  business-context call ahead of `Get-Projects`, per the MCP guidance
  for resolving project nicknames, acronyms, and org-specific metric
  vocabulary.
- **Search-Entities resolver in Step 1.** Dashboard or report referenced
  by name only (no URL/ID) now resolves via `Search-Entities` with the
  appropriate `entity_types`.
- **Branch 4 (cohort comparison) un-stubbed.** Cohorts ARE supported via
  `Search-Entities` with `entity_types=["cohort"]`. Branch 4 now discovers
  the project's cohorts (cap top 5 by popularity, or by user-named match),
  runs the metric filtered to each, and ranks them as candidate findings.
  Cohort important-finding threshold lowered to 30% concentration (vs
  default 40%) since cohorts are smaller slices than top-level properties.
- **Branch 3 optional Session Replay follow-up.** When top distinct_ids
  account for ≥10% of movement individually, offer to pull
  `Get-User-Replays-Data` for the flagged window. Opt-in only.
- **Step 1.5 instrumentation health check.** Added a `Get-Issues` call
  scoped to the events used by `query_template` over the diagnosis window.
  Issues are surfaced in the verdict card under contamination — separate
  signal from the statistical contamination check.

### Changed
- **Step 1.5 filter validation.** Replaced the "lightweight probe query"
  pattern with `Get-Properties` + `Get-Property-Values` metadata calls.
  Cheaper and produces a clearer error path ("filter value `premium`
  doesn't exist" beats "metric returned 0, who knows why").
- **Step 2 board creation** now calls `Create-Dashboard` directly instead
  of delegating to `mixpanel-dashboard-manager`. The single-board / N-reports
  / 1-text-card case is simple enough that the indirection didn't earn its
  weight. `mixpanel-dashboard-manager` is still the delegate for the Step 3
  append (which genuinely needs `Get-Dashboard` → `Update-Dashboard`
  orchestration).
- **Branch 1 funnel decomposition** now runs the funnel definition twice
  via `Run-Query` with `report_type=funnels` (recent vs baseline window)
  and computes step-pair conversion deltas from the native funnels
  response. Replaces the prior "pull each step as a standalone event
  count" approach, which ignored step ordering and step-level filters.

### Tools added to active use
`Get-Business-Context`, `Search-Entities`, `Get-Query-Schema`,
`Get-Properties`, `Get-Property-Values`, `Get-Issues`, `Create-Dashboard`,
`Get-User-Replays-Data` (optional).

---

## 2026-04-21 — `metric-rca` command + Step 3 post-RCA board append

Added the third command in the skill — root-cause attribution on top of
an existing anomaly or drift diagnosis — and the skill-level flow that
appends RCA findings to the diagnosis board.

### Added
- **`commands/metric-rca.md`.** Consumes the diagnosis payload from a
  prior `metric-anomaly` or `metric-drift` run; does not perform
  detection itself. Phase 1 fans out across five branches in parallel
  over the same date windows the source command used:
  - **Branch 1 (component decomposition)** — for `ratio`, `funnel`, and
    `retention` metrics only. Pulls numerator/denominator or step-pair or
    cohort/return events as standalone counts, and re-runs each component
    with every metric-definition filter applied independently (one filter
    at a time, not combinatorial).
  - **Branch 2 (default-property breakdowns)** — always runs.
    Level 1 is a two-dim breakdown on `mp_lib × $import` to isolate
    client-side / server-side / Import-API ingestion. Level 2 is a
    step-function geography cascade (`mp_country_code → $region → $city`)
    plus client-specific single-property breakdowns: `$device`,
    `utm_source`, `$browser` for web; `$app_version_string`, `$model`
    for android/iOS/swift. Cardinality discipline: flag exactly-rounded
    row counts (1k / 3k / 10k) as potentially truncated.
  - **Branch 3 (distinct_id outliers)** — anomaly payload only. Skipped
    if in-window distinct users >10k. Top-20 users by deviation in the
    flagged window; if top 5 account for >30% of movement, surface as
    strong user-driven signal.
  - **Branch 4 (cohort comparison)** — stubbed. Mixpanel MCP does not
    yet expose cohort definitions. Documented and skipped.
  - **Branch 5 (calendar context)** — runs only if the user provides a
    `business_context` string when asked. Uses `web_search` to look up
    region-specific festivals, launches, sale events, regulatory dates,
    and labels matches `strong` / `moderate` / `weak`. Framed as
    correlation, not causation.

  Phase 2 ranks every sub-segment by concentration score
  (share of total movement) and deviation score (segment deviation vs
  its own baseline). A finding is flagged **important** if concentration
  ≥ 40% or if segment deviation ≥ 1.5× the headline metric's deviation.
  Caps at 6 important findings. Renders a visualizer widget with one
  chart per important finding (two-line overlay for Branch 1,
  horizontal bar for Branches 2 and 3) and a structured findings card.
  Hands back an RCA payload containing `important_findings`,
  `rca_queries`, `findings_card`, and the source `diagnosis_board_id`.

- **`SKILL.md` Step 3 — Post-RCA board append.** Appends the findings
  card + up to 6 per-finding reports to the existing diagnosis board
  (the one created at Step 2). Delegates append mechanics to
  `mixpanel-dashboard-manager`. No second "save as board?" prompt —
  the user already opted in at Step 2. Fallback path: if no
  diagnosis board exists (user declined at Step 2), returns findings
  inline and asks once whether to create a combined diagnosis + RCA
  board then.

### Changed
- **`SKILL.md` skill description** now includes RCA trigger phrases
  ("what's driving the drop", "where is the movement coming from",
  "break this down", "run RCA on this metric") so the skill triggers
  on attribution framing, not just detection framing.
- **Top-of-SKILL blurb** expanded from two questions to three.
- **Commands list** adds `metric-rca` as the third command, with
  routing guidance for when the user opens with "why" or "where"
  (run detection first, then RCA — do not run cold).
- **Step 2 diagnosis payload** now carries `diagnosis_board_id` so
  `metric-rca` knows where to append. When the user creates a board
  at Step 2, the resulting board id is stored back onto the payload.
- **"When not to use this skill"** softened: root-cause investigation
  is now in-scope, but only on top of a prior detection run.

### Rationale
- The detection commands answer *what* happened but leave the CSA
  doing the attribution manually. On Indian enterprise accounts the
  attribution almost always lives in one of three places — a specific
  SDK source, a geography, or a calendar event — and the CSA was
  already running those breakdowns by hand after every detection run.
- Appending to the existing board instead of creating a new one keeps
  the customer-facing story in one place: verdict card, original
  charts, findings card, finding-level charts, all in the same
  dashboard. One link to share, one scroll to read.
- Branch 2's step-function cascade (country → region → city) rather
  than cross-product breakdowns is a direct response to the known
  3k cardinality truncation in large projects. Cross-product
  breakdowns on high-cardinality geography fields silently truncate
  and look clean, which is the worst failure mode.
- Branch 5 asks for `business_context` rather than inferring it.
  Guessing the market from project name or memory is how RCA becomes
  confidently wrong — a Swiggy project running a metric about Zomato
  traffic would be a disaster. Ask, use what the user gives, skip
  the branch if they don't.
- Branch 4 is stubbed rather than omitted so the skill's segmentation
  vocabulary matches Mixpanel's mental model (the CSA thinks in terms
  of cohorts) and the skill is trivially extensible when cohort MCP
  support ships.

---

## 2026-04-21 — Input validation + post-diagnosis board handoff

Added explicit input-validation gate and a post-Phase-3 handoff for board
creation and RCA caching.

### Added
- **`SKILL.md` Step 0 — Input validation.** Before anything else, both
  project and metric must be confirmed. Project: resolve via
  `Get-Projects` and confirm the project name back to the user. Metric:
  if a URL/bookmark is given, resolve and confirm the definition; if
  prose, confirm the definition; if missing, ask once. No guessing from
  memory or context.
- **`SKILL.md` Step 2 — Post-diagnosis handoff.** Both commands now
  return a structured `diagnosis payload` (command type, project,
  metric, queries with bodies + results, verdict card, headline, flags).
  The skill-level flow holds the payload in conversation memory for a
  future `metric-rca` command, and asks the user exactly once whether to
  persist the diagnosis as a Mixpanel board.
- **Board-creation branch.** If the user says yes, create a dashboard in
  the same project containing one saved report per Phase 1 query
  (named to match the chart titles) plus a text card with the full
  verdict card. Delegates board mechanics to `mixpanel-dashboard-manager`.
  Board name: `<metric_name> — <command> diagnosis (YYYY-MM-DD)`.

### Changed
- **Renumbered steps** in `SKILL.md`: old Step 0 → Step 1 (metric
  ingestion), old Step 0.5 → Step 1.5 (project profile resolution). New
  Step 0 is input validation, new Step 2 is post-diagnosis handoff.
- **Prerequisites in both commands** now reference Steps 0, 1, and 1.5.
- **Phase 3 in both commands** renamed "Summarise + charts + handoff"
  and now produces three things: charts, verdict card, diagnosis
  payload. The board prompt itself lives at the skill level, not inside
  either command, so back-to-back anomaly → drift runs don't ask twice.
- **"Root-cause investigation" line** in "When not to use this skill"
  softened to reflect the planned `metric-rca` command.

### Rationale
- The old Step 0 assumed a well-formed request. In practice users drop
  in prose like "what's going on with session conversion" without a
  project. The validation gate stops the skill from running on the
  wrong project or the wrong metric.
- Commands were producing a verdict and then ending. The dataset and
  queries built during diagnosis were the raw material a future
  `metric-rca` command will need — caching them in conversation memory
  is free and avoids re-querying. Offering a board at the same moment
  costs one prompt and leaves the customer with a live artifact
  attached to the diagnosis.

---

## 2026-04-21 — Split `analyse-metric` into two commands; remove `metric-rca`

Restructured the skill around two focused detection commands. Root-cause
attribution removed from scope.

### Changed
- **Split `commands/analyse-metric.md` into two commands:**
  - `commands/metric-anomaly.md` — point-in-time anomaly detection only.
    Phase 1: 7-day hourly + 30-day daily queries in parallel. Phase 2:
    time-bucketed Z-score + IQR. Phase 3: two stacked charts + compact
    verdict card. Time-bucketed approach preserved (hour-of-day × DoW for
    hourly, DoW for daily) to respect seasonality.
  - `commands/metric-drift.md` — trend-level drift detection only.
    Phase 1: 60-day daily + 16-week weekly queries in parallel. Phase 2:
    mean shift + variance ratio + lightweight 3σ contamination check
    (added so drift can run standalone without anomaly first). Phase 3:
    two stacked charts with drift-window banding + compact verdict card.
    Owns shape classification (step / slope / oscillating / unclassified).
- **Rewrote `SKILL.md`** around two commands. Updated description,
  trigger phrases, "choosing between the commands" section, and output
  contract. Removed handoff-block contract and all RCA-related routing.
- **Updated every command's "What this isn't" footer** to point to the
  sibling command (anomaly → "run drift"; drift → "run anomaly first if
  contamination flagged").

### Removed
- **`commands/analyse-metric.md`** — replaced by `metric-anomaly.md` +
  `metric-drift.md`.
- **`commands/metric-rca.md` + `commands/metric-rca/` (9 files)** —
  `metric-rca` removed from scope. Root-cause investigation is no longer
  part of this skill. Users who want to investigate a flagged drift or
  anomaly do so manually using the verdict as a starting point.
- **`rca-context` handoff block emission** from both new commands. No
  cross-command structured handoff anymore — the verdict card is the
  product.
- **Handoff contract section** from `SKILL.md`.
- **Funnel/retention classification fallback routing** to `metric-rca`
  Step 2.2 (no longer exists).

### Migration notes
- Any conversation that was mid-way through the `analyse-metric → metric-rca`
  flow should be restarted with `metric-anomaly` or `metric-drift`.
- If a user asks "why did [metric] drop?", the skill answers *what* dropped
  (via drift or anomaly verdict) and explicitly notes that *why* is out of
  scope. The CSA investigates manually from the verdict.
- Weekly drift window (8 vs 8 weeks) no longer feeds a handoff block — it's
  reported in the verdict card alongside the daily view.

---

## 2026-04-20 — Post-eval revisions (split, dedupe, shape ownership)

Acting on the skill evaluation checklist. Five required changes applied;
optional suggestions deferred.

### Changed
- **Split `commands/metric-rca.md`** (was 1,665 lines) into 9 files.
  Main file is now a ~200-line router. Branch content lives under
  `commands/metric-rca/` — one file per branch plus `preflight.md` and
  `synthesis.md`. This unblocks iteration on individual branches without
  reloading the entire tree, and makes Quick mode's file footprint
  roughly half of Deep mode's.
- **Deduplicated the `rca_context` schema.** `preflight.md` is now the
  single source of truth for the full schema. Individual branch files
  reference field names but do not re-specify their shape. Saved ~150
  lines of duplication; single point of maintenance going forward.
- **Consolidated shape classification ownership in `analyse-metric`.**
  `metric-rca` Branch 4 no longer re-runs the shape classifier when the
  handoff says `unclassified` — it now treats `unclassified` as an
  honest finding and produces a "shape unclear" interpretation. Removes
  the subtle failure mode where the handoff block and Branch 4 could
  disagree on shape.
- **Removed funnel/retention classification from SKILL.md Step 0.**
  Each command now owns its own metric-type classification
  (`analyse-metric` in Prerequisites, `metric-rca` in Step 2.2).
  SKILL.md Step 0 is now deliberately narrow: resolve the metric into
  a normalized series object, nothing more.
- **Query budgets now reflect actual floors.** Quick mode restated as
  ~5–8 queries (was ~5); Deep mode restated as ~25–40 queries on
  cross-platform customers (was ~15–25). The old ~15–25 was optimistic
  for cross-platform accounts where Branch 1 Layer 2 sweeps 3 libraries
  × multiple dimensions and Branch 5 can fire up to 22 candidate
  queries.

### Cache location clarified
- Property-map resolver cache (Step 2.4 Phase 3) is now explicitly
  scoped to the current conversation by default. Persists as
  `cache/<project_id>.json` only when the execution environment
  provides a durable filesystem (Claude Code).

### Worked example
- `preflight.md` now includes a Nykaa worked example showing the
  `rca_context` object populated after Step 2, so the handoff →
  pre-flight → branches path can be traced end-to-end.

### Not changed (deferred)
- S2 (R² threshold for slope classification), S3 (adaptive Branch 1
  Layer 2 order — partial note added), S4 (non-standard `compatibility`
  frontmatter).

---

## 2026-04-20 — MCP-feasibility rework

Audited every branch of `metric-rca` + `analyse-metric` against what
the Mixpanel MCP surface actually supports today. Patched branches to
only depend on primitives that are fully supported or supported with
well-understood cost. Gaps that relied on non-existent primitives were
reworked or removed.

### Removed
- **Project-specific gotchas** — all references to project 3 and project 1297132
  were dropped from both SKILL.md and metric-rca.md. Profile resolution
  now comes from `Get-Report` on the saved metric, not a hardcoded
  registry.
- **User-level data probe (`$distinct_id` breakdown)** — this probe assumed
  a capability Mixpanel MCP doesn't expose. Replaced with a
  `$first_seen` availability probe (Step 2.5), which gates on the
  filter `$first_seen is set` and is cleanly supported.
- **Distribution shape test (analyse-metric Phase B3 Test 3)** — KS / PSI
  require per-user or per-segment values not retrievable at practical
  cost via MCP. Rationale for its removal is kept in the file pointing
  to Branch 1 Simpson's paradox check as the feasible substitute.
- **Schema adjacency (Branch 5)** — "events that share a property with the
  base event" has no efficient MCP primitive; enumerating every event's
  property list is not practical inside an RCA run. Dropped from the
  adjacency definition, with a note explaining why.
- **Hardcoded 3,000-row truncation cap** — softened to "suspiciously round
  result sizes" to avoid claiming a limit we can't live-verify.

### Changed
- **Behavioral adjacency (Branch 5)** — reworked around Mixpanel Flows
  (`Run-Query(report_type='flows')`) returning top path steps before
  and after the base event. This is explicitly labeled as an
  approximation of ±24h co-occurrence, not a true co-occurrence query.
- **Branch 0 Check 5 (new event variants)** — `Get-Events` has no
  `created_after` parameter. Reworked around fuzzy-matching the base
  event name against the full Lexicon.
- **Branch 0 Check 6 (app-version schema change)** — rewritten to reflect
  realistic query cost: breakdown by version + `is set` probes per
  metric-filter property per high-share version (3–6 queries per
  library, not 1).
- **Branch 0 Check 3 (null rate shift)** — clarified the real cost: 2
  queries per filter property (`is set` count + total count).
- **Branch 3.3 primary split (new vs existing)** — clarified as two
  insights runs with `DatetimePropertyFilter` on `$first_seen`
  (resource: user), using `timeComparison` for the window pair.
- **Branch 3.4 tenure sub-decomposition** — rewritten from "one breakdown
  by tenure bucket" to "4 filtered queries", and moved to Deep-mode
  only (Quick mode's ~5-query budget can't absorb it).
- **Analyse-metric Phase B3** — reduced from 3 tests to 2 (mean shift +
  variance ratio), both operating on aggregate daily series.

### Renamed (for internal consistency)
- `user_level_available` → `first_seen_available`
- `user_level_skipped_reason` → `first_seen_skipped_reason`
- Dropped `user_level_noted` from Branch 2 output (no longer used)

### Synthesis
- Scope section Branch 3 reason updated to
  `"$first_seen coverage below 50%"`.
- Confidence calibration "Low" condition updated to reference
  `$first_seen` unavailability instead of user-level data.

---

## 2026-04-20 — Full `metric-rca` spec + handoff contract

Major update: root-cause decomposition command fully specified end-to-end.

### New
- **`commands/metric-rca.md`** — 11-step spec covering pre-flight, mode
  selection, Branches 0–6, and synthesis. Replaces the prior stub file.
  - Step 1: metric selection (multi-metric case)
  - Step 2: pre-flight resolution — project profile, metric-type classification,
    ingestion-source classifier (`$import` × `mp_lib`), library-scoped property
    resolver (with cascading country drill-down), user-level data probe
  - Step 3: mode selection (Quick vs Deep) with pre-flight signal
  - Step 4: Branch 0 — data quality gate (6 checks, max across checks, 3 exit bands)
  - Step 5: Branch 1 — dimensional decomposition (3 layers: ingestion → library → library-specific properties), with Simpson's paradox check on every breakdown and a 3,000-row truncation guard
  - Step 6: Branch 2 — structural decomposition (ratio / funnel / retention paths; skips for count)
  - Step 7: Branch 3 — cohort decomposition (30-day boundary, tenure sub-decomposition always-on, retention carve-out when user-level data unavailable)
  - Step 8: Branch 4 — temporal pattern (trusts handoff's verdict_shape; DoW contamination recheck free)
  - Step 9: Branch 5 — correlated event scan (union of behavioral + schema + structural adjacency; skipped in Quick mode)
  - Step 10: Branch 6 — external factor disclosure (always-on, zero queries, India-context aware)
  - Step 11: Synthesis — 7-priority headline ladder, top-3 supporting bullets cap, finding-adaptive chart, confidence calibration

### Changed
- **`commands/analyse-metric.md`**:
  - Added `metric_type` classification to Prerequisites (new)
  - Explicitly named `drift_window` / `baseline_window` in Prerequisites
  - Added **Phase B6** — "Resolve verdict for handoff" — produces all five
    verdict fields (`verdict`, `verdict_magnitude`, `verdict_direction`,
    `verdict_shape`, `analyse_metric_notes`) for the handoff block
  - Added worked example of an emitted `rca-context` block (Nykaa ratio metric)
  - Handoff block emission added to both C1 (compact) and C2 (expanded)
    output modes, conditional on Phase A or B flagging something
- **`SKILL.md`**:
  - Updated `metric-rca` command description to reflect the Step 1/2/3 structure and hard-gate prerequisites
  - Added "Cross-command handoff: the `rca-context` block" subsection to the Output contract section
  - Updated the files manifest

### Open for tuning (pending real-world calibration)

All threshold values in the spec are starter values. The first real runs
against customer data will tell us if they need adjustment:
- 70% concentration thresholds across Branches 0–3
- 10% / 3% / 5pp / 80% thresholds scattered through branch logic
- 30-day cohort boundary (Branch 3)
- 1,000-event volume floor and 20-candidate cap (Branch 5)
- 60% variance explained / R² ≥ 0.5 / autocorrelation ≥ 0.5 (B6 shape classifier)

### Suggested first-run approach

1. Validate the handoff block end-to-end first: run `analyse-metric` on a
   known-drifted metric, inspect the emitted `rca-context` block, confirm
   every field has a sensible value.
2. Start with Quick mode (Branch 0 + Branch 1) before attempting Deep.
3. Log threshold firings to build tuning data.
4. Most likely-to-break: library-scoped property resolver in Step 2.4, and
   Simpson's paradox detection in Branch 1.
