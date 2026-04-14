# Command — Enrich Lexicon

> **Session reads:** `event_list`, `event_details_cache`, `property_names`, `property_details_cache`, `volume_rank_map`
> **Session writes:** `event_list`, `event_details_cache`, `property_names`, `property_details_cache`

Auto-generate display names and descriptions for events/properties missing them, write to Lexicon after confirmation. Execute silently.

---

## Exclusions

Apply before building gap lists. Excluded items never appear in suggestions or writes.

**Ignored events:**
- `$ae_first_open`, `$ae_updated`, `$ae_session`, `$ae_iap`, `$ae_crashed` — legacy auto-tracked mobile SDK events
- `$session_start`, `$session_end` — virtual events (project session definitions)

**Ignored properties:**
- Any property prefixed with `mp_` or `$` — Mixpanel-managed system properties

---

## Phase 1 — Identify Gaps

Read `shared/schema-reader.md`, fetch/reuse schema. Build gap lists:

**Event gaps:** events where `description` is null/empty OR `display_name` is null or equals raw name.

**Property gaps:** properties in `property_details_cache` where description/display_name is missing. If cache empty, fetch top 30 event properties + all user properties.

If zero gaps → output `✅ All events and properties already have metadata.` → return to router.

---

## Phase 2 — Configure

Ask once, concisely:

```
Enrichment config (defaults in brackets):
  Casing:  (a) Title Case [default]  (b) Sentence case  (c) Keep original
  Scope:   (d) Events + Properties [default]  (e) Events only  (f) Properties only
  Mode:    (g) Fill gaps only [default]  (h) Overwrite all
Enter to accept defaults, or type choices (e.g. "b, e, g"):
```

---

## Phase 3 — Generate Suggestions

For each entity in gap list:

**Display name:** Convert raw name from snake_case/camelCase/kebab-case to selected casing. Strip prefixes (`mp_`, `$mp_`, `$`). System events (`$`-prefixed) get readable display names.

**Description:** Infer purpose from name + schema context. 1–2 sentences, under 120 chars. Analytics-perspective framing.

Process in batches of 10 for consistency.

---

## Phase 4 — Preview & Confirm

Show the enrichment plan as a single table — this is the first user-visible output:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ENRICHMENT PREVIEW — [N] events, [N] properties
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EVENTS
  Event Name              │ Display Name          │ Description
  ────────────────────────┼───────────────────────┼──────────────────────
  user_signup_complete     │ User Signup Complete  │ User completes signup flow.
  ...

PROPERTIES
  Property Name    │ Type  │ Display Name    │ Description
  ─────────────────┼───────┼─────────────────┼─────────────────────
  platform         │ Event │ Platform        │ Device platform (iOS, Android, Web).
  ...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

(a) Apply all  (b) Edit specific rows  (c) Cancel
```

**Edit flow:** User references by row number or name. Update in memory, re-display, re-confirm.

**Cancel:** Return to router.

---

## Phase 5 — Apply

For events: `Edit-Event(project_id, event_name, display_name, description)`
For properties: `Edit-Property(project_id, property_name, resource_type, display_name, description)`

Batch of 10. Progress after each batch: `✅ Updated 10/47...`

On failure: log error, skip, continue. Report failures at end.

Update `event_details_cache` and `property_details_cache` with new values.

---

## Phase 6 — Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✅ ENRICHMENT COMPLETE — [Project Name]
  Events: [N]/[N]  |  Properties: [N]/[N]  |  Failures: [N]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If failures > 0, list them. Return control to router.
