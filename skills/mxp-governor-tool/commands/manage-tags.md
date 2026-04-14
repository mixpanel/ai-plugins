# Command — Manage Tags

> **Session reads:** `event_list`, `event_details_cache`
> **Session writes:** `event_details_cache`

Rename or delete existing Lexicon tags. Execute silently.

---

## Phase 1 — Fetch Existing Tags

Read `shared/schema-reader.md`, fetch/reuse schema. Build:
- `existing_tags`: unique tag names from `event_details_cache`, each with event count

If zero tags → output `ℹ️ No tags found in this project.` → return to router.

Display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  TAGS — [Project Name]  ([N] tags)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  #  │ Tag Name          │ Events
  ───┼───────────────────┼────────
  1  │ Commerce           │ 12
  2  │ Navigation         │ 8
  ...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

(a) Rename a tag  (b) Delete a tag  (c) Done
```

---

## Phase 2 — Rename

User picks tag by number or name, provides new name.

**Confirm:** `Rename "[old]" → "[new]" across [N] events?`

Execute: For each event with the old tag, call `Edit-Event(project_id, event_name, tags: { names: [new_name, ...other_existing], operation: "set" })`. Batch of 10.

If a tag with the new name already exists → merge (deduplicate).

Update `event_details_cache`. Call `Rename-Tag(project_id, old_name, new_name)` if MCP supports it; otherwise tag assignment handles it.

---

## Phase 3 — Delete

User picks tag by number, name, or range ("1-3").

**Confirm:** `Delete tag "[name]"? This removes it from [N] events.`

Execute: For each event with the tag, call `Edit-Event(project_id, event_name, tags: { names: [remaining_tags], operation: "set" })`. Batch of 10.

Call `Delete-Tag(project_id, tag_name)`.

Update `event_details_cache`.

---

## Phase 4 — Loop or Exit

After each rename/delete, re-display the updated tag list and action prompt.

When user picks (c) Done → return control to SKILL.md router.
