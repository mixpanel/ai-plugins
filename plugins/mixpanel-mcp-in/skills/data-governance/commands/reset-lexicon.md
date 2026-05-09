# Command — Reset Lexicon

> **Session reads:** `event_list`, `event_details_cache`, `property_names`, `property_details_cache`
> **Session writes:** `event_details_cache`, `property_details_cache`

Clear descriptions, display names, and/or tags from events and properties. Destructive — always preview + explicit confirmation. Execute silently.

> Apply exclusions per `references/exclusions.md`. Use chunk sizes, fallback paths, and tag operation semantics from `references/mcp-cheatsheet.md`.

---

## Phase 1 — Scope Prompt

Ask once:

```
Reset what?  (select one or more, comma-separated)
  (a) Event descriptions
  (b) Event display names
  (c) Event tags
  (d) Property descriptions
  (e) Property display names
  (f) All of the above
```

Parse selection. Store as `reset_scope` set.

---

## Phase 2 — Identify Targets

Read `references/schema-reader.md`, fetch/reuse schema.

For each scope item, build the target list — only include entities where the field is currently **non-empty** (no point "clearing" an already-empty field):

- Event descriptions → events with non-empty `description`
- Event display names → events where `display_name` is non-null AND differs from raw event name
- Event tags → events with non-empty `tags` array
- Property descriptions → properties with non-empty `description`
- Property display names → properties with non-empty `display_name`

If all selected lists are empty → output `✅ Nothing to reset — selected fields are already empty.` → return to router.

---

## Phase 3 — Preview

Show counts and a representative sample:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  RESET PREVIEW — [Project Name]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

WILL CLEAR
  Event descriptions:    [N] events
  Event display names:   [N] events
  Event tags:            [N] events  ([N] distinct tags)
  Property descriptions: [N] properties
  Property display names: [N] properties

SAMPLE (first 10 affected entities)
  Entity                  │ Field           │ Current Value
  ────────────────────────┼─────────────────┼──────────────────────
  user_signup_complete     │ description     │ User completes signup...
  add_to_cart              │ tags            │ Commerce, Engagement
  platform                 │ display_name    │ Platform
  ...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  This is destructive. Cleared metadata cannot be recovered.

Type "CONFIRM" to proceed, "EXPORT" to save the preview as JSON without writing,
or anything else to cancel:
```

- **Literal `CONFIRM`** (case-sensitive) → proceed to Phase 4.
- **Literal `EXPORT`** → write the preview payload to `data-governance-runs/[ISO-timestamp]-reset-preview.json`, confirm path, return to router. No writes to Mixpanel.
- **Anything else** → cancel, return to router.

---

## Phase 4 — Apply

Execute in order. Log failures, continue.

### Step 4a — Events: descriptions and display names (bulk)

If either event-description or event-display-name reset is in scope, build the events array with empty strings for the selected fields:

```
events = [
  { name: "event_1", description: "", display_name: "" },  // both in scope
  { name: "event_2", description: "" },                    // only description in scope
  ...
]
```

Call `Bulk-Edit-Events(project_id, events: [...])`. Chunks of 50. Progress: `✅ Events metadata cleared: 50/112...`

### Step 4b — Events: tags (bulk, uniform)

If event-tag reset is in scope, group all affected events and clear tags uniformly:

```
Bulk-Edit-Events(
  project_id,
  events: [{name: "e1"}, {name: "e2"}, ...],
  tags: { names: [], operation: "set" }
)
```

`set` is correct here — this is the only command that uses it (see `references/gotchas.md`). Chunks of 50 events per call. Progress: `✅ Event tags cleared: 50/112...`

### Step 4c — Properties: descriptions and display names (bulk)

`Bulk-Edit-Properties` is single-resource-type. Split targets by `Event` vs `User` and pass empty strings for each field in scope:

```
Bulk-Edit-Properties(
  project_id,
  resource_type: "Event",
  properties: [
    { name: "platform", description: "", display_name: "" },  // both in scope
    { name: "source", description: "" },                      // only description in scope
    ...
  ]
)
```

Chunks of up to 50 per call. Progress: `✅ Properties cleared: 50/120...`

If a bulk call fails, fall back to per-property `Edit-Property` for that chunk only; log and continue.

---

## Phase 5 — Update Session Cache

For each cleared entity, set the affected fields to `""` or `[]` in `event_details_cache` and `property_details_cache`.

---

## Phase 6 — Audit Trail

Append a one-line summary to `data-governance-runs/[ISO-timestamp]-reset.json`:

```json
{
  "command": "reset-lexicon",
  "project_id": "...",
  "timestamp": "2026-05-09T...",
  "scope": ["event_descriptions", "event_tags", ...],
  "event_descriptions_cleared": N,
  "event_display_names_cleared": N,
  "event_tags_cleared": N,
  "property_descriptions_cleared": N,
  "property_display_names_cleared": N,
  "failures": []
}
```

---

## Phase 7 — Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✅ RESET COMPLETE — [Project Name]
  Event descriptions cleared:     [N]/[N]
  Event display names cleared:    [N]/[N]
  Event tags cleared:             [N]/[N]
  Property descriptions cleared:  [N]/[N]
  Property display names cleared: [N]/[N]
  Failures:                       [N]
  Audit log:                      data-governance-runs/[file].json
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If failures > 0, list them.

---

## Phase 8 — Auto-Offer Re-Enrichment

Symmetric with Score → Enrich handoff. If the user reset any of: event descriptions, event display names, event tags, property descriptions, property display names — append:

```
Reset complete. The cleared fields are now empty across [N] events and [N] properties.

(a) Run Enrich & Tag now  (b) Return to menu
```

Selection handling:
- **(a)** → Read `commands/enrich-and-tag.md` and execute. Session cache is already updated (cleared fields show as empty), so `enrich-and-tag` will pick them up as gaps and regenerate.
- **(b)** → Return control to router.

If the user only ran a "no-op" reset (nothing actually got cleared) → no handoff. Return control to router.
