# Command — Manage Tags

> **Session reads:** `event_list`, `event_details_cache`
> **Session writes:** `event_details_cache`, `existing_tags`

Rename or delete existing Lexicon tags. Execute silently.

---

## Phase 1 — Fetch Existing Tags

Build `existing_tags` and show the user the current tag list with event counts.

Ensure the required Session reads are loaded; fetch any that aren't. A single bulk events read returns full metadata including tags.

Build `existing_tags`: unique tag names from `event_details_cache`, each with event count.

If zero tags → output `ℹ️ No tags found in this project.` → return to Execution loop.

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

Rename a tag with an atomic-then-merge-fallback pattern.

User picks tag by number or name, provides new name.

**Confirm:** `Rename "[old]" → "[new]" across [N] events?`

**Atomic path (preferred):** call the project's rename-tag endpoint. Propagates to all events server-side. No per-event loop.

**Merge fallback:** if a tag with the new name already exists, the atomic rename may error (the new name is already in use). On error, run:

1. For each event with the old tag → per-event edit with `tags: { names: [new_name, ...other_existing_minus_old], operation: "set" }`. Batches of 10.
2. Delete the now-unused old tag.

Update `event_details_cache` and `existing_tags` to reflect the renamed/merged tag.

---

## Phase 3 — Delete

Delete a tag with a single atomic call.

User picks tag by number, name, or range ("1-3").

**Confirm:** `Delete tag "[name]"? This removes it from [N] events.`

Execute the delete via the project's delete-tag endpoint. Single atomic call — removes the tag from all events automatically.

Update `event_details_cache` — remove the deleted tag from every event's `tags` array. Update `existing_tags`.

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

Re-display and offer the next action until the user is done.

After each rename / delete, re-display the updated tag list and action prompt.

When user picks (c) Done → return control to the Execution loop in SKILL.md.
