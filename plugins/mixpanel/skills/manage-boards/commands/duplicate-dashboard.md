# Command: Duplicate Dashboard

Creates a copy of an existing dashboard within the same project. Optionally renames and updates the description.

---

## Intake

Required:
1. **Dashboard ID** — the board to copy (accept by name or ID; match by ID first, then case-insensitive name)

Optional:
2. **New title** — defaults to "[Original Title] (Copy)"
3. **New description** — defaults to original description

If the user doesn't provide a dashboard, help them find it:
- If `dashboard_list_cache` is populated → show a quick picker from cache
- Otherwise → fetch the dashboard set (per the **Fetching the dashboard set** rule), show a table, let user pick

---

## Execution

1. **Preview source.** Read the source board's full layout to show the user what
   they're copying:
   ```
   Source: [Title] (ID: [dashboard_id])
   Reports: [N] | Rows: [M] | Description: [first 100 chars...]
   ```

2. **Confirm.** "Duplicate this dashboard?" (skip confirmation if the user already stated intent clearly)

3. **Duplicate** the source board within the session project, applying the new
   title/description if provided. (Duplication is same-project only — see
   `references/mcp-tool-reference.md`.)

4. **Post-duplicate metadata update.** If the duplicate operation doesn't apply
   the title/description overrides cleanly, follow up with a metadata update on
   the new board to set them.

5. **Verify** the new board per the **Validate every write** rule before reporting `✅`.

---

## Output

```
✅ Dashboard duplicated
   Source:  [original_title] (ID: [source_id])
   Copy:   [new_title] (ID: [new_id])
   Reports: [N] carried over
```

Return control to router.

---

## Error Handling

| Situation | Action |
|-----------|--------|
| Source dashboard not found | Error, help user find correct ID |
| Duplicate operation fails | Surface error, suggest retry |
| User cancels | "No changes made." Return. |
