# Command: Update Dashboard

Modifies an existing dashboard's metadata, rows, or cell layout. The most flexible command — it handles renames, description edits, adding/removing rows, reordering rows, and updating cell content.

---

## Intake

Required:
1. **Dashboard ID** — the board to update (accept by name or ID)

The user's intent determines the update path:
- **Rename** → title only
- **Update description** → description only
- **Add a section/row** → row + cell creation
- **Remove a row** → row deletion
- **Reorder rows** → row-order update
- **Update a report cell** → cell update with a new `query_id`
- **Update a text card** → cell update with new HTML
- **Bulk restructure** → a combination of the above

If the user doesn't specify a dashboard, help them find it using `dashboard_list_cache` or by fetching the set (Global Rule 9).

---

## Execution

### Step 1 — Read current layout

Always start by reading the board's full layout, then show the user a structural
summary so they can point at real rows/cells:

```
Dashboard: [Title] (ID: [dashboard_id])
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Row 1: [Report: "DAU Trend"] [Report: "WAU Trend"]
Row 2: [Text: "Engagement Section"]
Row 3: [Report: "Session Length"] [Report: "Retention"]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Layout cell/row IDs are opaque server-generated strings — read the real IDs from
this layout; use temporary placeholder IDs only for newly-added rows/cells (see
`references/mcp-tool-reference.md`).

### Step 2 — Apply updates

Submit a single update to the board carrying the operations the user's intent
requires. The operation shapes:

| Intent | Operation(s) to submit |
|--------|------------------------|
| Rename / edit description | Set `title` and/or `description` on the board |
| Add a new row | Row op: `["temp-row-1", "add"]` |
| Add a text card to a new row | Row op `["temp-row-1", "add"]` + cell op `["temp-cell-1", "create", "text", {row_id: "temp-row-1", html_content: "<h2>New Section</h2>"}]` |
| Add a report cell to a new row | First mint a `query_id` (run its query with results skipped), then row op `["temp-row-1", "add"]` + cell op `["temp-cell-1", "create", "report", {row_id: "temp-row-1", query_id: "...", name: "...", description: "..."}]` |
| Delete a row | Row op: `["<real_row_id>", "delete"]` |
| Delete a cell | Cell op: `["<real_cell_id>", "delete"]` |
| Update a text card | Cell op: `["<real_cell_id>", "update", "text", {html_content: "<h2>Updated</h2>"}]` |
| Update a report cell | Cell op: `["<real_cell_id>", "update", "report", {query_id: "<new>", name: "..."}]` |
| Reorder rows | Set row order: `["row_id_3", "row_id_1", "row_id_2"]` |

Temp IDs are placeholders for new items; the server assigns the real ones.
Text-card HTML must obey the tag whitelist and no-newline rule in
`references/mcp-tool-reference.md`.

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

Apply the update, then re-read the board's full layout to confirm the change took
effect (Global Rule 8) and show the updated structure. If the readback diverges
from intent, surface what landed vs. what was requested rather than reporting `✅`.

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
| Invalid row/cell ID | Re-read layout, map correct IDs |
| Update fails | Surface error with details |
| User cancels | "No changes made." Return. |
| A report's query fails to mint | Skip that report, note in output |
