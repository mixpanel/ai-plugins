# Command: metric-rca

Walk the root-cause decomposition tree against a metric that `analyse-metric`
has already flagged (or one the user has explicitly asked to investigate).

Produces a single-narrative attribution — what moved, how much it explains,
and what the customer conversation should be about. Does **not** prove
causation. Does **not** recommend fixes. Does **not** handle multi-metric
RCA: one metric at a time, run sequentially if multiple are flagged.

---

## Prerequisites — hard gate

`metric-rca` never runs cold. Two preconditions, both non-negotiable:

1. **`analyse-metric` must have run first** against the metric in the current
   conversation. RCA on a metric that hasn't been verified as anomalous or
   drifted wastes queries chasing noise.
2. **The handoff block from `analyse-metric` must be present** in the
   conversation. Schema in the next section.

If either is missing, do **not** attempt RCA. Route the user back to
`analyse-metric` first:

> "RCA needs the output of `analyse-metric` to know what drifted and when.
> Want me to run `analyse-metric` on this metric first?"

---

## Handoff contract: the `rca-context` block

`analyse-metric` emits a fenced markdown block at the end of its output with
this exact schema. `metric-rca` parses it as its sole source of input
context — no re-elicitation of project_id, metric definition, or windows.

````
```rca-context
project_id: <int>
metric_name: <str>
metric_definition: <one-sentence what-it-measures>
metric_type: count | unique_count | ratio | funnel | retention | unknown
query_template: <dict, reusable query body for Run-Query>
default_filters: <dict, filters baked into the saved report>
verdict: anomaly | drift | user_forced
verdict_magnitude: <signed %, e.g. -12.4>
verdict_direction: up | down | mixed
verdict_shape: step | slope | oscillating | spike | unclassified
drift_window: {start: YYYY-MM-DD, end: YYYY-MM-DD}
baseline_window: {start: YYYY-MM-DD, end: YYYY-MM-DD}
analyse_metric_notes: <free text, any caveats analyse-metric flagged>
```
````

If the parsed block has `metric_type: unknown`, the classifier fallback
in pre-flight Step 2.2 handles it. If the parsed block has `verdict_shape:
unclassified`, Branch 4 accepts that as-is — it does **not** re-classify.
`analyse-metric` owns shape classification end-to-end.

---

## Step 1 — Metric selection (only if multi-metric)

If `analyse-metric` flagged multiple metrics and the user hasn't chosen
one yet, ask which to investigate. RCA runs **sequentially per metric** —
no cross-metric synthesis. One output per metric.

If only one metric is flagged, or the user has already named one, skip
this step and proceed to Step 2.

Do **not** ask for mode (Quick vs Deep) yet. Mode selection happens in
Step 3, after pre-flight has produced signal the user can decide against.

---

## Step 2 — Pre-flight resolution (runs silently)

Five resolution tasks that populate the shared `rca_context` object every
downstream branch reads from.

**→ See `metric-rca/preflight.md`** for the full spec: five resolution
tasks (project profile, metric-type classification, ingestion-source
classifier, library-scoped property resolver, `$first_seen` probe) and
the complete `rca_context` schema that every branch writes into.

The `rca_context` schema in `preflight.md` is the **single source of
truth** for branch output shapes. Individual branch files reference it
rather than re-specifying their output structure.

---

## Step 3 — Mode selection (with pre-flight signal)

Only after pre-flight completes, ask the user which mode to run. Because
pre-flight has finished, the prompt carries real signal the user can
decide against, not a blind choice.

Prompt format:

> "Pre-flight done on `<metric_name>` (project `<project_id>`). Here's
> what I found:
> - Ingestion: `<X%>` Client SDK (`<libraries>`), `<Y%>` Track API, `<Z%>` Import API
> - Backfill suspected: `<yes/no>` *(only include line if true)*
> - `$first_seen` available: `<yes/no>` *(note if Branch 3 will be gated)*
> - Missing dimensions: `<list or "none">`
>
> Quick mode (Branch 0 + top-library Branch 1, ~5–8 queries) or Deep mode
> (full tree, ~25–40 queries on cross-platform customers)?"

**Mode defaults (suggest, don't auto-run):**
- **Deep** when the user invoked `metric-rca` directly.
- **Quick** when `metric-rca` was chained from a portfolio sweep
  (e.g. `weekly-pulse` follow-up).
- **Suggest Quick** (regardless of entry point) if Track API + Import
  API combined ≥ 70% of volume — the Deep tree will have thin coverage
  anyway because most behavioral branches depend on client SDK data.
- **Suggest Deep** if `backfill_suspected = true` — Branch 0 has real
  work to do and the customer conversation will want the full picture.

The default is the **recommended** option; the user can still override.

Once the user picks, store in `rca_context.mode` and proceed to the
branch walk.

**Query budgets are honest estimates, not ceilings.** Cross-platform
customers (web + iOS + Android) with many eligible Branch 1 dimensions
and a full Branch 5 candidate list can push Deep mode toward the upper
end. A customer with one active library and a clean candidate list lands
at the lower end.

---

## Branch walk — tree structure

Steps 4–10 walk the decomposition tree. Each branch has its own file.
Load only the branch files relevant to the current run — Quick mode
skips Branch 5 entirely and skips Branch 3 tenure sub-decomposition.

| Step | Branch | File | Runs in Quick? |
|---|---|---|---|
| 4 | **Branch 0 — Data quality gate** | `metric-rca/branch-0-dq.md` | Yes (full) |
| 5 | **Branch 1 — Dimensional decomposition** | `metric-rca/branch-1-dimensional.md` | Yes (top library only) |
| 6 | **Branch 2 — Structural decomposition** | `metric-rca/branch-2-structural.md` | Yes |
| 7 | **Branch 3 — Cohort decomposition** | `metric-rca/branch-3-cohort.md` | Yes (primary split only) |
| 8 | **Branch 4 — Temporal pattern** | `metric-rca/branch-4-temporal.md` | Yes |
| 9 | **Branch 5 — Correlated event scan** | `metric-rca/branch-5-correlated.md` | **Skip** |
| 10 | **Branch 6 — External factor disclosure** | `metric-rca/branch-6-disclosure.md` | Yes (0 queries) |

**Tree-walk control flow:**

- Branch 0 can **halt the tree walk** if `dq_band = "severe"` (≥50%). Synthesis produces a DQ-framed output and behavioral branches are skipped.
- Branch 1 Layer 0 can **halt the tree walk** if ingestion concentrates on Track API / Import API (escalate as DQ).
- Branch 2 is **conditional** — skips entirely for `count` / `unique_count` metrics.
- Branch 3 is **gated** on `first_seen_available` (except retention — carve-out applies).
- Branches 4, 5, 6 never halt; they inform the narrative but don't close it.

DQ scaling applies across Branches 1–3: if `dq_contribution` is 10–50%,
every downstream `contribution_pct` is scaled by
`(1 - dq_contribution/100)` before ranking. See `branch-0-dq.md` for the
exact rule.

---

## Step 11 — Synthesis

Collapse all branch findings into a single narrative for the CSA.

**→ See `metric-rca/synthesis.md`** for the full spec: headline priority
ladder, supporting-finding cap, final output structure, finding-adaptive
chart, confidence calibration, scope section, and the hard never-produce
rules.

Synthesis is where the whole tree becomes one output. No branch's raw
findings make it to the user unmediated — synthesis decides what
surfaces, in what order, and what drops.

---

## File layout

```
commands/
  metric-rca.md                    ← this file — routing + Step 1/3/11 pointers
  metric-rca/
    preflight.md                   ← Step 2 (five tasks, rca_context schema)
    branch-0-dq.md                 ← Step 4 (6 DQ checks, exit rules)
    branch-1-dimensional.md        ← Step 5 (3 layers, Simpson's, truncation guard)
    branch-2-structural.md         ← Step 6 (ratio / funnel / retention paths)
    branch-3-cohort.md             ← Step 7 (new/existing, tenure, retention carve-out)
    branch-4-temporal.md           ← Step 8 (shape interpretation, DoW check)
    branch-5-correlated.md         ← Step 9 (adjacency, candidate filter, language rules)
    branch-6-disclosure.md         ← Step 10 (4–5 category template)
    synthesis.md                   ← Step 11 (headline ladder, chart, confidence)
```

In Quick mode the files actually needed are `preflight.md`, `branch-0-dq.md`,
`branch-1-dimensional.md`, `branch-2-structural.md`, `branch-3-cohort.md`,
`branch-4-temporal.md`, `branch-6-disclosure.md`, and `synthesis.md` —
skip `branch-5-correlated.md` entirely.
