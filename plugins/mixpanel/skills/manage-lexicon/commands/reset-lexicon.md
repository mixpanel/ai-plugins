# Command — Reset Lexicon

> **Session reads:** `event_list`, `event_details_cache`, `property_names`, `property_details_cache`
> **Session writes:** `event_details_cache`, `property_details_cache`

Clear descriptions, display names, and/or tags from events and properties. Destructive — always preview, then require literal `CONFIRM` before any writes. Execute silently.

---

## Phase 1 — Scope Prompt

Ask the user what to clear.

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

Build the lists of entities that will actually have something cleared.

Ensure the required Session reads are loaded; load any that aren't.

For each scope item, build the target list — only include entities where the field is currently **non-empty** (no point "clearing" an already-empty field):

- Event descriptions → events with non-empty `description`
- Event display names → events where `display_name` is non-null AND differs from raw event name
- Event tags → events with non-empty `tags` array
- Property descriptions → properties with non-empty `description`
- Property display names → properties with non-empty `display_name`

If all selected lists are empty → output `✅ Nothing to reset — selected fields are already empty.` → return to Execution loop.

---

## Phase 3 — Preview

Show the user what's about to be cleared and capture their confirmation.

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
- **Literal `EXPORT`** → write the preview payload to `data-governance-runs/[ISO-timestamp]-reset-preview.json`, confirm path, return to Execution loop. No writes to Mixpanel.
- **Anything else** → cancel, return to Execution loop.

---

## Phase 4 — Apply

Execute the clears in order. If any step fails partially, log and continue — don't abort.

### Step 4a — Events: descriptions and display names

Clear the selected fields on every affected event. Only the fields the user selected in Phase 1.

Progress: `✅ Events metadata cleared: 50/112...`

### Step 4b — Events: tags

If event-tag reset is in scope, clear the tag arrays on every affected event.

Progress: `✅ Event tags cleared: 50/112...`

### Step 4c — Properties: descriptions and display names

Clear the selected fields on every affected property. Update event properties and user properties separately.

Progress: `✅ Properties cleared: 50/120...`

---

## Phase 5 — Audit Trail

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

## Phase 6 — Output

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

## Phase 7 — Auto-Offer Re-Enrichment

Symmetric with the Score → Enrich handoff. If the user reset any of: event descriptions, event display names, event tags, property descriptions, property display names — append:

```
Reset complete. The cleared fields are now empty across [N] events and [N] properties.

(a) Run Enrich & Tag now  (b) Return to menu
```

Selection handling:
- **(a)** → Read `commands/enrich-and-tag.md` and execute. Session cache already reflects the cleared state, so `enrich-and-tag` picks them up as gaps and regenerates.
- **(b)** → Return control to the Execution loop.

If the user only ran a "no-op" reset (nothing actually got cleared) → no handoff. Return control to the Execution loop.
