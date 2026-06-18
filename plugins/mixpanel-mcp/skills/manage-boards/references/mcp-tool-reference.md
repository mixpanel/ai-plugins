# Dashboard MCP Tool Reference

Quick reference for all dashboard-related Mixpanel MCP tools used by this skill.

---

## Tool Schemas

### Get-Projects
```
Params: (none)
Returns: list of {id, name, workspaces, context}
```
Use to validate project IDs and list available projects.

### List-Dashboards
```
Params:
  project_id: integer (required)
  query: string (optional) — title substring filter, case-insensitive
  workspace_id: integer (optional)
Returns: list of dashboard summaries
```
Note: `Search-Entities` with `entity_types=["dashboard"]` is preferred for filtered searches — it supports sort_by and richer results.

### Get-Dashboard
```
Params:
  project_id: integer (required)
  dashboard_id: integer (required)
  include_layout: boolean (default: false)
Returns: dashboard metadata + layout (if requested)
```
**Layout format:** `[[row_id, [[cell_id, type, extra], ...]], ...]`
- `type`: "report" or "text"
- `extra` for report: `{id, name}` (id = bookmark_id / report_id)
- `extra` for text: `{html_content}`

Always use `include_layout=true` when you need to inspect contents, update cells, or count reports.

### Create-Dashboard
```
Params:
  project_id: integer (required)
  title: string (required)
  rows: array of row objects (required)
  description: string (optional)
  is_private: boolean (default: false)
  is_restricted: boolean (default: false)
  time_filter: object (optional)
  workspace_id: integer (optional)
```

**Row schema:**
```json
{
  "contents": [
    {"type": "text", "html_content": "<h1>Title</h1>"},
    {"type": "report", "query_id": "abc-123", "name": "Report Name", "description": "..."}
  ]
}
```
- Max 30 rows per dashboard.
- Max 4 items per row.
- Report cells require a `query_id` from a prior `Run-Query` call.
- Allowed HTML tags in text cards: `a`, `blockquote`, `br`, `code`, `em`, `h1`, `h2`, `h3`, `hr`, `li`, `mark`, `ol`, `p`, `s`, `strong`, `u`, `ul`.

**Time filter schema:**
```json
{
  "dateRange": {
    "type": "in the last",           // or "since" or "between"
    "window": {"unit": "day", "value": 30},  // for "in the last"
    "from": "2024-01-01",            // for "since" or "between"
    "to": "2024-03-31"              // for "between" only
  },
  "displayText": "Last 30 days"
}
```

### Update-Dashboard
```
Params:
  project_id: integer (required)
  dashboard_id: integer (required)
  title: string (optional)
  description: string (optional)
  rows: array (optional) — add/delete rows
  rows_order: array of string (optional) — reorder rows
  cells: array (optional) — create/update/delete cells
```

**Row operations:**
- Add: `["temp-row-id", "add"]`
- Delete: `["real-row-id", "delete"]`

**Cell operations:**
- Create: `["temp-cell-id", "create", "text"|"report", {row_id, ...content}]`
- Update: `["real-cell-id", "update", "text"|"report", {...content}]`
- Delete: `["real-cell-id", "delete"]`

**Critical:** Always call `Get-Dashboard` with `include_layout=true` first to get real row/cell IDs. Use temp IDs only for new rows/cells.

### Delete-Dashboard
```
Params:
  project_id: integer (required)
  dashboard_id: integer (required)
```
**Always confirm with user before calling.** This is irreversible.

### Duplicate-Dashboard
```
Params:
  project_id: integer (required)
  dashboard_id: integer (required)
  title: string (optional) — override title of the copy
  description: string (optional) — override description of the copy
```
Creates a copy **in the same project** as the source. Cross-project duplication is not supported by the API.

---

## API Constraints & Gotchas

1. **Duplicate is same-project only.** The API cannot duplicate a dashboard into a different project. For cross-project templating, you either duplicate in-place and inform the user, or recreate via Create-Dashboard.

2. **Report cells need query_ids.** You can't create a dashboard with report cells without first running `Run-Query` (with `skip_results=true`) to generate query_ids.

3. **Layout IDs are opaque strings.** Don't try to construct them — always read them from `Get-Dashboard` responses.

4. **Max 30 rows.** The Create-Dashboard API enforces this limit.

5. **HTML tag whitelist.** Text cards strip any tags not in the allowed list. No `<div>`, `<span>`, `<img>`, `<table>`.

6. **No newlines in html_content.** Each HTML element implicitly creates a line break. Use `<br>` for explicit breaks.

7. **List-Dashboards vs Search-Entities.** `Search-Entities` with `entity_types=["dashboard"]` is more flexible (supports `sort_by`, richer results). Use `List-Dashboards` when you need all dashboards without filtering.
