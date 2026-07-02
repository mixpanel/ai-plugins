# Command: Template Dashboard

Reproduces a reference dashboard in another project, renames it, and optionally updates the description. This is the core enabler for standardized onboarding dashboard templates across accounts.

**Key API fact:** duplication only copies *within the source project* — it has no target-project parameter. So genuine cross-project templating cannot be done by duplicating. It is done by **reconstructing** the board in the target project: read the source layout, re-mint each report's query in the target project, then create the board there. This command does that.

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

If the user doesn't provide source/target explicitly, ask. Use the session's projects list to help them pick. Accept projects and boards by name or ID.

---

## Routing: same project vs. cross project

- **Target project == source project** → this is a plain copy. Use Path A. Fast, exact, preserves everything.
- **Target project != source project** → use the reconstruction flow (Path B). Duplication cannot reach another project.

---

## Path A — Same-project copy

1. **Validate source.** Read its full layout; preview title, description, report count, row count. If not found → error, stop.
2. **Duplicate** within the source project, applying `title`/`description` overrides if provided.
3. Verify (Global Rule 8) and report the new dashboard ID. Done.

---

## Path B — Cross-project reconstruction (the real templating path)

### Step 1 — Read the source

1. Read the source board's full layout (from the source project).
   - For each **report** cell, capture its report/query reference and name, plus the cell's description if present.
   - For each **text** cell, capture its HTML content.
   - Preserve row grouping and cell order so the rebuilt board matches the original layout.
2. Preview to the user: title, description, report count, text-card count, row count.

### Step 2 — Portability pre-check (important)

A report only renders in the target project if the events, properties, and cohorts it references **exist there**. Templating an onboarding board into a brand-new project where nothing is instrumented yet will produce empty charts.

- Identify the events/properties each source report depends on (from each report's query definition).
- Check they exist in the target project (inspect the target project's schema — its events and properties).
- Classify each report: **portable** (all dependencies present in target) vs **at-risk** (missing events/props).
- Show the user the at-risk list before building:
  ```
  3 of 7 reports reference events not found in [Target Project]:
    - "Activation Funnel"  → missing: signup_completed, first_value_event
    - "Feature Adoption"   → missing: feature_used
  Proceed and create them anyway (they may stay empty until instrumented), skip them, or cancel?
  ```
- Default to asking. For a fresh-onboarding template this is expected — the user often wants the scaffold in place ahead of instrumentation, so "proceed anyway" is a valid, informed choice.

### Step 3 — Re-mint queries in the target project

For each report to carry over, its query must be re-run **against the target project** to produce a target-valid `query_id` (a source project's `query_id` is not valid elsewhere — see `references/mcp-tool-reference.md`):

1. Reconstruct the query from the source report/query definition.
2. Run it against the target project with results skipped to obtain a fresh `query_id`.
3. Fire in parallel where possible. If a query fails (e.g. unsupported by missing schema), mark that report skipped and continue.

### Step 4 — Build the board in the target project

1. Assemble the rows preserving the source's grouping — report cells referencing
   their fresh target `query_id` and original name/description, text cells carrying
   their original HTML. Observe the layout limits and content rules in
   `references/mcp-tool-reference.md`.
2. Create the board in the target project with the new title, the new description
   plus a templated-from note, and the assembled rows (carry over the source's
   time filter if it had one).
3. Capture the new dashboard ID.

### Step 5 — Verify

Re-read the new board's full layout in the target project and confirm report/row counts match expectations (minus any reports the user chose to skip). See Global Rule 8.

---

## Batch template (multiple target projects)

1. Read + portability-check the source once.
2. For each target project, run Path B Steps 3–5 (re-mint queries per target — they cannot be shared across projects).
3. Show progress: `Templated 3/7...`
4. Final summary table:

```
Template Results — "[Source Dashboard Title]"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Project              | Status        | New ID | Reports carried / skipped
[Project A]          | ✅            | 12345  | 7 / 0
[Project B]          | ⚠️ partial    | 12346  | 4 / 3 (missing events)
[Project C]          | ❌ Error      | —      | Query timeout
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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
| Target project not accessible | Error, list available projects |
| Same source & target project | Use Path A instead |
| Report depends on events/props missing in target | Flag in portability pre-check; let user proceed / skip / cancel |
| A query fails to mint in target | Skip that report, note in output, continue with the rest |
| Board creation fails | Surface full error, suggest retry |
