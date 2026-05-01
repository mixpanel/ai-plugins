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

Execute: Single atomic call — `Rename-Tag(project_id, old_name, new_name)`. This propagates to all events with the tag in one operation. No per-event loop.

**Merge case:** If a tag with the new name already exists, `Rename-Tag` may error. On error, fall back to:
1. For each event with the old tag → `Edit-Event(project_id, event_name, tags: { names: [new_name, ...other_existing_minus_old], operation: "set" })`. Batches of 10.
2. `Delete-Tag(project_id, old_name)` to remove the now-unused tag.

Update `event_details_cache` to reflect the renamed/merged tag.

---

## Phase 3 — Delete

User picks tag by number, name, or range ("1-3").

**Confirm:** `Delete tag "[name]"? This removes it from [N] events.`

Execute: Single atomic call — `Delete-Tag(project_id, tag_name)`. This removes the tag from all events automatically. No per-event loop.

Update `event_details_cache` — remove the deleted tag from every event's `tags` array.

---

## Phase 4 — Loop or Exit

After each rename/delete, re-display the updated tag list and action prompt.

When user picks (c) Done → return control to SKILL.md router.
