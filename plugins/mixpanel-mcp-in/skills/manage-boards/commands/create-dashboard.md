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
4. **Visibility** — private or shared (default: shared)
5. **Time filter** — if the user mentions a date range, set it; otherwise omit

---

## Execution

### Path A: Empty Dashboard (no reports specified or no query_ids available)

If the user just wants a board created without pre-built reports:

1. Create the dashboard with the session `project_id`, the extracted title and
   description, the chosen visibility, and at minimum one row holding a single
   text card, e.g. `<h1>Dashboard Title</h1><p>Description here. Add reports to populate.</p>`.
2. Return the dashboard ID and confirm.

### Path B: Dashboard with Reports

If the user wants specific charts, each report needs a `query_id` minted first.
The flow:

1. For each desired report, run its query with results skipped to mint a
   `query_id`. Read the query schema first if unsure about available
   events/properties. Fire queries in parallel where possible.
2. Assemble the rows, observing the layout limits and grouping rules in
   `references/mcp-tool-reference.md`. Group related reports in the same row;
   use text cards as section headers between logical groups.
3. Create the dashboard with the assembled rows.
4. Return the dashboard ID, title, and a summary of what was created.

### Path C: Dashboard from a description (AI-inferred layout)

When the user gives a loose description like "build me a product health dashboard":

1. Infer 4-8 logical report categories from the description.
2. Create the dashboard with text-card section headers for each category and a
   placeholder description.
3. Tell the user: "Created [Title] with section scaffolding. Reports need to be
   added manually or by minting queries — want me to populate any sections?"

---

## Time Filter

If the user specifies a date range, set a time filter. Common mappings:
- "last 7 days" → last 7 days
- "last month" → last 1 month
- "last quarter" → last 3 months
- Specific range → a "between" range with `from`/`to` dates (YYYY-MM-DD)

---

## Output

```
✅ Dashboard created
   ID:      [dashboard_id]
   Title:   [title]
   Reports: [N reports] | Empty (scaffold only)
   Access:  Shared | Private
```

Then re-read the board to confirm the write landed (see Global Rule 8) before
reporting `✅`. Return control to router.

---

## Error Handling

| Situation | Action |
|-----------|--------|
| A report's query fails to mint | Skip that report, note in output, continue with others |
| Dashboard creation fails | Surface full error to user |
| User description too vague | Create scaffold with text-card sections, explain next steps |
