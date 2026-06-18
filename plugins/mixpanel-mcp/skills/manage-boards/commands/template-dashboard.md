# Command: Template Dashboard

Reproduces a reference dashboard in another project, renames it, and optionally updates the description. This is the core enabler for standardized onboarding dashboard templates across accounts.

**Key API fact:** `Duplicate-Dashboard` only copies *within the source project* — it has no target-project parameter. So genuine cross-project templating cannot be done by duplicating. It is done by **reconstructing** the board in the target project: read the source layout, re-run each report's query in the target project to mint new `query_id`s, then `Create-Dashboard` in the target. This command does that.

---

## Intake

Required:
1. **Source dashboard ID** — the reference board to clone
2. **Source project ID** — where the reference lives (may differ from session `project_id`)
3. **Target project ID(s)** — where the clone(s) should land

Optional:
4. **New title** — defaults to "[Original Title]"
5. **New description** — defaults to original description with a "[Templated from [source]]" note appended
6. **Batch mode** — template to multiple target projects at once

If the user doesn't provide source/target explicitly, ask. Use `Get-Projects` from session cache to help them pick.

---

## Routing: same project vs. cross project

- **Target project == source project** → this is a plain copy. Use `Duplicate-Dashboard` (Path A). Fast, exact, preserves everything.
- **Target project != source project** → use the reconstruction flow (Path B). `Duplicate-Dashboard` cannot reach another project.

---

## Path A — Same-project copy (`Duplicate-Dashboard`)

1. **Validate source.** Call `Get-Dashboard(include_layout=true)`; preview title, description, report count, row count. If not found → error, stop.
2. **Duplicate.** Call `Duplicate-Dashboard` with `project_id` = source project, `dashboard_id` = source, plus `title`/`description` overrides if provided.
3. Report the new dashboard ID. Done.

---

## Path B — Cross-project reconstruction (the real templating path)

### Step 1 — Read the source

1. Call `Get-Dashboard(project_id=source, dashboard_id=source, include_layout=true)`.
   - Layout format: `[[row_id, [[cell_id, type, extra], ...]], ...]`.
   - For each **report** cell, capture `extra = {id, name}` — `id` is the source report/bookmark/query id — plus the cell's `description` if present.
   - For each **text** cell, capture `extra = {html_content}`.
   - Preserve row grouping and cell order so the rebuilt board matches the original layout.
2. Preview to the user: title, description, report count, text-card count, row count.

### Step 2 — Portability pre-check (important)

A report only renders in the target project if the events, properties, and cohorts it references **exist there**. Templating an onboarding board into a brand-new project where nothing is instrumented yet will produce empty charts.

- Identify the events/properties each source report depends on (read each report's query definition via the report/query id; use `Get-Report` / the query-schema tools as available).
- Check they exist in the target project (`Get-Query-Schema` / `Get-Events` / `List-Properties` against the target `project_id`).
- Classify each report: **portable** (all dependencies present in target) vs **at-risk** (missing events/props).
- Show the user the at-risk list before building:
  ```
  3 of 7 reports reference events not found in [Target Project]:
    - "Activation Funnel"  → missing: signup_completed, first_value_event
    - "Feature Adoption"   → missing: feature_used
  Proceed and create them anyway (they may stay empty until instrumented), skip them, or cancel?
  ```
- Default to asking. For a fresh-onboarding template this is expected — the user often wants the scaffold in place ahead of instrumentation, so "proceed anyway" is a valid choice, just an informed one.

### Step 3 — Re-mint query_ids in the target project

For each report to carry over, the query must be re-run **against the target project** to produce a target-valid `query_id` (a source project's query_id is not valid in another project):

1. Reconstruct the query for the report (from the source report/query definition).
2. Call `Run-Query(project_id=target, ..., skip_results=true)` to obtain a fresh `query_id`.
3. Fire in parallel where possible. If a `Run-Query` fails (e.g. unsupported by missing schema), mark that report skipped and continue.

### Step 4 — Build the board in the target project

1. Assemble `rows` preserving the source's grouping:
   - Report cells: `{"type": "report", "query_id": "[fresh target query_id]", "name": "[original name]", "description": "[original description]"}`
   - Text cells: `{"type": "text", "html_content": "[original html_content]"}` (≤ 2000 chars; allowed tags only)
   - Max 30 rows; max 4 cells per row; each row needs ≥ 1 cell.
2. Call `Create-Dashboard(project_id=target, title=[new title], description=[new description + templated-from note], rows=[...], time_filter=[carry over if source had one])`.
3. Capture the new dashboard ID.

### Step 5 — Verify

Call `Get-Dashboard(project_id=target, dashboard_id=new, include_layout=true)` and confirm report/row counts match expectations (minus any reports the user chose to skip).

---

## Batch template (multiple target projects)

1. Read + portability-check the source once.
2. For each target project, run Path B Steps 3–5 (re-mint query_ids per target — they cannot be shared across projects).
3. Show progress: `Templated 3/7...`
4. Final summary table:

```
Template Results — "[Source Dashboard Title]"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Project              | Status        | New ID | Reports carried / skipped
[Project A]          | ✅            | 12345  | 7 / 0
[Project B]          | ⚠️ partial    | 12346  | 4 / 3 (missing events)
[Project C]          | ❌ Error      | —      | Run-Query timeout
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Output (single, cross-project)

```
✅ Dashboard templated
   Source:  [source_title] (ID: [source_id], Project: [source_project])
   Clone:   [new_title] (ID: [new_id], Project: [target_project])
   Reports: [N carried over] | [M skipped — missing dependencies]
   Method:  Reconstructed (queries re-run in target project)
```

Return control to router.

---

## Error Handling

| Situation | Action |
|-----------|--------|
| Source dashboard not found | Error, ask user to re-check ID |
| Target project not accessible | Error, list available projects via `Get-Projects` |
| Same source & target project | Use Path A (`Duplicate-Dashboard`) instead |
| Report depends on events/props missing in target | Flag in portability pre-check; let user proceed / skip / cancel |
| `Run-Query` fails for a report in target | Skip that report, note in output, continue with the rest |
| `Create-Dashboard` fails | Surface full error, suggest retry |
