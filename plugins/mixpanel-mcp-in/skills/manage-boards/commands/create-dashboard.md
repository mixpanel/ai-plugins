# Command: Create Dashboard

Creates a new dashboard from a natural language description.

---

## Intake

The user provides either:
- **A description** — e.g. "create a dashboard tracking onboarding funnel metrics"
- **A structured spec** — title, description, specific reports to include

Extract:
1. **Title** (required) — infer from description if not stated
2. **Description** (optional) — a 1-2 line summary
3. **Report intent** (optional) — what charts/reports the user wants on the board
4. **Visibility** — private or shared (default: shared, i.e. `is_private=false`)
5. **Time filter** — if user mentions a date range, set it; otherwise omit

---

## Execution

### Path A: Empty Dashboard (no reports specified or no query_ids available)

If the user just wants a board created without pre-built reports:

1. Call `Create-Dashboard` with:
   - `project_id`: from session
   - `title`: extracted or generated
   - `description`: if provided
   - `rows`: at minimum one row with a text card:
     ```json
     [{"contents": [{"type": "text", "html_content": "<h1>Dashboard Title</h1><p>Description here. Add reports to populate.</p>"}]}]
     ```
   - `is_private`: as specified

2. Return dashboard ID and confirm.

### Path B: Dashboard with Reports

If the user wants specific charts, this requires `Run-Query` calls first to generate `query_id` values. The flow:

1. For each desired report, call `Run-Query` with `skip_results=true` to get a `query_id`.
   - To build the query, read the query schema first: call `Get-Query-Schema` if unsure about available events/properties.
   - Fire queries in parallel where possible.

2. Assemble the `rows` array. Layout rules:
   - Max 30 rows per dashboard.
   - Max 4 items (text cards or reports) per row.
   - Group related reports in the same row.
   - Use text cards as section headers between logical groups.

3. Call `Create-Dashboard` with the assembled rows.

4. Return dashboard ID, title, and a summary of what was created.

### Path C: Dashboard from a description (AI-inferred layout)

When the user gives a loose description like "build me a product health dashboard":

1. Infer 4-8 logical report categories from the description.
2. Create the dashboard with text-card section headers for each category and a placeholder description.
3. Tell the user: "Created [Title] with section scaffolding. Reports need to be added manually or via Run-Query — want me to populate any sections?"

---

## Time Filter

If the user specifies a date range, set `time_filter`:

```json
{
  "dateRange": {
    "type": "in the last",
    "window": {"unit": "day", "value": 30}
  },
  "displayText": "Last 30 days"
}
```

Common mappings:
- "last 7 days" → `{"unit": "day", "value": 7}`
- "last month" → `{"unit": "month", "value": 1}`
- "last quarter" → `{"unit": "month", "value": 3}`
- Specific range → use `"type": "between"` with `"from"` and `"to"` dates (YYYY-MM-DD)

---

## Output

```
✅ Dashboard created
   ID:      [dashboard_id]
   Title:   [title]
   Reports: [N reports] | Empty (scaffold only)
   Access:  Shared | Private
```

Return control to router.

---

## Error Handling

| Situation | Action |
|-----------|--------|
| `Run-Query` fails for a report | Skip that report, note in output, continue with others |
| `Create-Dashboard` fails | Surface full error to user |
| User description too vague | Create scaffold with text-card sections, explain next steps |
