# Command: Dashboard Inventory

Lists all dashboards in a project with report counts, ownership, and metadata. Produces a governance-ready catalog. Read-only.

---

## Execution

### Phase 1 — Fetch all dashboards

Fetch the dashboard set per Global Rule 9, reusing `dashboard_list_cache` if it
is already populated (e.g. from a prior cleanup command). Only re-fetch if the
cache is empty.

### Phase 2 — Enrich with layout data

For each dashboard, read its full layout. Fire in parallel (batches of 5).

Extract per dashboard:
- **Report count:** number of report cells
- **Report names:** the name of each report cell
- **Text card count:** number of text cells
- **Row count**
- **Total cells**

Cache layouts in `dashboard_layout_cache`.

### Phase 3 — Build catalog

Present as a structured table:

```
Dashboard Inventory — [Project Name] ([project_id])
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID       | Title                     | Reports | Rows | Description
---------|---------------------------|---------|------|------------------
1234567  | Onboarding Funnel         | 6       | 4    | Tracks new user...
1234568  | Product Health             | 8       | 5    | Core KPIs for...
1234569  | Engagement Weekly          | 4       | 3    | Weekly active...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total: 12 dashboards | 54 reports | Avg 4.5 reports/board
```

### Phase 4 — Optional detail drill-down

After showing the catalog, if the user asks about a specific dashboard, show
full details: all report names, description, text card contents. This data is
already in `dashboard_layout_cache` — no additional calls needed.

### Phase 5 — Optional export

If the user wants a downloadable version, offer to produce a Markdown or CSV file with the full catalog.

---

## Output

The catalog table above, plus the summary line. Return control to router.

---

## Error Handling

| Situation | Action |
|-----------|--------|
| Fetch returns empty | "No dashboards in this project." Return. |
| Layout read fails for one board | Show row with "⚠️ Could not inspect" in Reports column |
| Large project (50+ dashboards) | Process in batches of 5, show progress: "Inspecting 15/52..." |
