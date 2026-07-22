# Command: Update Dashboard

Modifies an existing dashboard's metadata, rows, or cell layout. The most flexible command — it handles renames, description edits, adding/removing rows, reordering rows, and updating cell content.

---

## Contents

- Intake
- Execution (read layout → apply updates → confirm → execute & verify)
- Output
- Error Handling

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

If the user doesn't specify a dashboard, help them find it using `dashboard_list_cache` or by fetching the set (per the **Fetching the dashboard set** rule).

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
requires. Work at the level of intent — consult the update tool's own schema for
the exact operand order and payload shape.

| Intent | What to submit |
|--------|----------------|
| Rename / edit description | Set the board's title and/or description. |
| Add a new row | One add-row operation. |
| Add a text card | An add-row operation plus a create-cell operation of type `text` carrying the card's HTML. |
| Add a report cell | First mint a `query_id` (run its query with results skipped), then an add-row op plus a create-cell op of type `report` referencing that `query_id`. |
| Delete a row or cell | A delete operation targeting the **real** server ID (read it from the layout first). |
| Update a text or report cell | An update operation targeting the real cell ID with the new HTML or new `query_id`. |
| Reorder rows | A set-row-order operation listing the real row IDs in the desired order. |

New rows/cells use temporary placeholder IDs; the server assigns the real ones on
write. Text-card HTML must obey the tag whitelist and no-newline rule in
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
effect (per the **Validate every write** rule) and show the updated structure. If
the readback diverges from intent, surface what landed vs. what was requested
rather than reporting `✅`.

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
