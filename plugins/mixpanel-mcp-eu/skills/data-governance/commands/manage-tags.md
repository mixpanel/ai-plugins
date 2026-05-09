# Command — Manage Tags

> **Session reads:** `event_list`, `event_details_cache`
> **Session writes:** `event_details_cache`

Rename or delete existing Lexicon tags. Execute silently.

> Apply exclusions per `references/exclusions.md`. Use chunk sizes, fallback paths, and tag operation semantics from `references/mcp-cheatsheet.md`.

---

## Phase 1 — Fetch Existing Tags

Read `references/schema-reader.md`, fetch/reuse schema. Build:
- `existing_tags`: unique tag names from `event_details_cache`, each with event count

If zero tags → output `ℹ️ No tags found in this project.` → return to router.

Display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  TAGS — [Project Name]  ([N] tags)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  #  │ Tag Name          │ Events
  ───┼───────────────────┼────────
  1  │ Commerce          │ 12
  2  │ Navigation        │ 8
  ...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

(a) Rename a tag  (b) Delete a tag  (c) Done
```

---

## Phase 2 — Rename

User picks tag by number or name, provides new name.

**Confirm:** `Rename "[old]" → "[new]" across [N] events?`

Execute: single atomic call — `Rename-Tag(project_id, old_name, new_name)`. Propagates to all events server-side. No per-event loop.

**Merge case:** if a tag with the new name already exists, `Rename-Tag` may error (see `references/gotchas.md`). On error, fall back to:
1. For each event with the old tag → `Edit-Event(project_id, event_name, tags: { names: [new_name, ...other_existing_minus_old], operation: "set" })`. Batches of 10.
2. `Delete-Tag(project_id, old_name)` to remove the now-unused tag.

Update `event_details_cache` to reflect the renamed/merged tag.

---

## Phase 3 — Delete

User picks tag by number, name, or range ("1-3").

**Confirm:** `Delete tag "[name]"? This removes it from [N] events.`

Execute: single atomic call — `Delete-Tag(project_id, tag_name)`. Removes the tag from all events automatically.

Update `event_details_cache` — remove the deleted tag from every event's `tags` array.

---

## Phase 4 — Audit Trail

After each rename or delete, append a one-line summary to `data-governance-runs/[ISO-timestamp]-manage-tags.json`:

```json
{
  "command": "manage-tags",
  "project_id": "...",
  "timestamp": "2026-05-09T...",
  "action": "rename" | "delete",
  "old_name": "...",
  "new_name": "...",
  "events_affected": N,
  "fallback_used": false
}
```

---

## Phase 5 — Loop or Exit

After each rename / delete, re-display the updated tag list and action prompt.

When user picks (c) Done → return control to SKILL.md router.
