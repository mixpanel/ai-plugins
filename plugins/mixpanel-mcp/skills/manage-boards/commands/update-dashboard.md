# Command: Update Dashboard

Modifies an existing dashboard's metadata, rows, or cell layout. This is the most flexible command — it handles renames, description edits, adding/removing rows, reordering rows, and updating cell content.

---

## Intake

Required:
1. **Dashboard ID** — the board to update

The user's intent determines which update path to take:
- **Rename** → title update only
- **Update description** → description update only
- **Add a section/row** → row + cell creation
- **Remove a row** → row deletion
- **Reorder rows** → rows_order update
- **Update a report cell** → cell update with new query_id
- **Update a text card** → cell update with new html_content
- **Bulk restructure** → combination of the above

If the user doesn't specify a dashboard ID, help them find it using `dashboard_list_cache` or `List-Dashboards`.

---

## Execution

### Step 1 — Fetch current layout

Always start by calling `Get-Dashboard` with `include_layout=true`.

Parse the layout to understand current structure:
```
Layout format: [[row_id, [[cell_id, type, extra], ...]], ...]
```

Where:
- `row_id` — string ID of each row
- `cell_id` — string ID of each cell
- `type` — "report" or "text"
- `extra` — for reports: `{id, name}`; for text: `{html_content}`

Show the user a structural summary:
```
Dashboard: [Title] (ID: [dashboard_id])
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Row 1: [Report: "DAU Trend"] [Report: "WAU Trend"]
Row 2: [Text: "Engagement Section"]
Row 3: [Report: "Session Length"] [Report: "Retention"]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 2 — Apply updates

Based on user intent, construct the `Update-Dashboard` call.

**Metadata only (title/description):**
```
Update-Dashboard(
  project_id, dashboard_id,
  title="New Title",
  description="New description"
)
```

**Add a new row with content:**
```
Update-Dashboard(
  project_id, dashboard_id,
  rows=[["temp-row-1", "add"]],
  cells=[
    ["temp-cell-1", "create", "text", {
      "row_id": "temp-row-1",
      "html_content": "<h2>New Section</h2>"
    }]
  ]
)
```

**Add a report cell to a new row (requires Run-Query first):**
1. Call `Run-Query` with `skip_results=true` to get `query_id`.
2. Then:
```
Update-Dashboard(
  project_id, dashboard_id,
  rows=[["temp-row-1", "add"]],
  cells=[
    ["temp-cell-1", "create", "report", {
      "row_id": "temp-row-1",
      "query_id": "[from Run-Query]",
      "name": "Report Name",
      "description": "What this report shows"
    }]
  ]
)
```

**Delete a row:**
```
Update-Dashboard(
  project_id, dashboard_id,
  rows=[["[real_row_id]", "delete"]]
)
```

**Delete a cell:**
```
Update-Dashboard(
  project_id, dashboard_id,
  cells=[["[real_cell_id]", "delete"]]
)
```

**Update a text card:**
```
Update-Dashboard(
  project_id, dashboard_id,
  cells=[["[real_cell_id]", "update", "text", {
    "html_content": "<h2>Updated Section Header</h2><p>New description</p>"
  }]]
)
```

**Reorder rows:**
```
Update-Dashboard(
  project_id, dashboard_id,
  rows_order=["row_id_3", "row_id_1", "row_id_2"]
)
```

### Step 3 — Confirm before applying

For destructive operations (deleting rows/cells, major restructures), show a before/after preview:

```
Changes to apply:
  - Title: "Old Title" → "New Title"
  - Delete Row 3: [Report: "Unused Chart"]
  - Add Row: [Text: "New Section Header"]

Proceed?
```

For simple renames or description updates, skip confirmation unless the user seems uncertain.

### Step 4 — Execute and verify

1. Call `Update-Dashboard` with the assembled parameters.
2. Call `Get-Dashboard` again to verify the update took effect.
3. Show the updated structure.

---

## HTML Content Guidelines

When creating or updating text cards, use only allowed HTML tags:
`a`, `blockquote`, `br`, `code`, `em`, `h1`, `h2`, `h3`, `hr`, `li`, `mark`, `ol`, `p`, `s`, `strong`, `u`, `ul`

Other tags are stripped by the API. Do not include newlines in the HTML string — each HTML element creates a new line.

---

## Output

```
✅ Dashboard updated
   ID:      [dashboard_id]
   Title:   [title]
   Changes: [summary of what changed]
```

Return control to router.

---

## Error Handling

| Situation | Action |
|-----------|--------|
| Dashboard not found | Error, help user find correct ID |
| Invalid row/cell ID | Re-fetch layout, map correct IDs |
| Update API fails | Surface error with details |
| User cancels | "No changes made." Return. |
| Run-Query fails (for adding reports) | Skip that report, note in output |
