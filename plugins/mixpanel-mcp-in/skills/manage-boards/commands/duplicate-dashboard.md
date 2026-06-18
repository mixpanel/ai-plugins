# Command: Duplicate Dashboard

Creates a copy of an existing dashboard within the same project. Optionally renames and updates the description.

---

## Intake

Required:
1. **Dashboard ID** — the board to copy

Optional:
2. **New title** — defaults to "[Original Title] (Copy)"
3. **New description** — defaults to original description

If the user doesn't provide a dashboard ID, help them find it:
- If `dashboard_list_cache` is populated → show a quick picker from cache
- Otherwise → call `List-Dashboards`, show table, let user pick

---

## Execution

1. **Preview source.** Call `Get-Dashboard` (with `include_layout=true`) to show the user what they're copying:
   ```
   Source: [Title] (ID: [dashboard_id])
   Reports: [N] | Rows: [M] | Description: [first 100 chars...]
   ```

2. **Confirm.** "Duplicate this dashboard?" (skip confirmation if user already stated intent clearly)

3. **Duplicate.** Call `Duplicate-Dashboard`:
   - `dashboard_id`: source ID
   - `project_id`: session project ID
   - `title`: new title if provided
   - `description`: new description if provided

4. **Post-duplicate metadata update.** If the Duplicate API response doesn't support title/description overrides cleanly, follow up with `Update-Dashboard` on the new board to set them.

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
| Duplicate API fails | Surface error, suggest retry |
| User cancels | "No changes made." Return. |
