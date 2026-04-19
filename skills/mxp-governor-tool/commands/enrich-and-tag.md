# Command — Enrich & Tag Lexicon

> **Session reads:** `event_list`, `event_details_cache`, `property_names`, `property_details_cache`, `volume_rank_map`
> **Session writes:** `event_list`, `event_details_cache`, `property_names`, `property_details_cache`

Single-pass enrichment: auto-generate display names, descriptions, and tags for events and properties in one combined preview. Writes happen sequentially after a single confirm: events (bulk) → tags (bulk) → properties (per-call). Execute silently.

**Fill-only-empty guarantee:** Every field write checks that the target field is currently null/empty before including it in the write payload. Existing metadata is never overwritten. This is a hard rule — no config flag bypasses it (use `reset-lexicon` first if the user wants to regenerate existing metadata).

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

Read `shared/schema-reader.md`, fetch/reuse schema. Build three gap lists:

**Event metadata gaps:** for each event, record which of these are empty:
- `description` (null/empty)
- `display_name` (null OR equals raw event name)

**Event tag gaps:** events where `tags` is null or empty array.

**Property metadata gaps:** properties where `description` is null/empty OR `display_name` is null/empty. If `property_details_cache` is empty, fetch top 30 event properties + all user properties first.

If all three lists are empty → output `✅ All events and properties already have descriptions, display names, and tags.` → return to router.

---

## Phase 2 — Generate Suggestions

Default casing is **Title Case** for display names and tags. (If the user wants a different casing, they can edit in the preview — no upfront config prompt.)

**For each event gap — display name:** Convert raw name from snake_case/camelCase/kebab-case. Strip prefixes (`mp_`, `$mp_`, `$`). System events (`$`-prefixed) get readable display names.

**For each event gap — description:** Infer purpose from name + schema context. 1–2 sentences, under 120 chars. Analytics-perspective framing.

**For each event tag gap — tags:** Assign 1–3 tags per event using these strategies combined:

*Prefix clustering:* `checkout_*` → "Checkout", `onboarding_*` → "Onboarding", `$mp_*`/`$ae_*` → "Mixpanel System".

*Functional domain:*
- purchase/order/cart/payment → "Commerce"
- login/signup/auth/register → "Authentication"
- view/page/screen/navigate → "Navigation"
- click/tap/button/cta → "Engagement"
- error/fail/crash → "Errors"
- search/filter/sort/query → "Search"
- share/invite/refer → "Virality"
- notification/push/email/sms → "Messaging"
- play/watch/stream/video → "Media"
- subscribe/plan/upgrade/downgrade → "Subscription"

**For each property gap — display name and description:** Same rules as events.

Process in internal batches of 10 for generation consistency.

---

## Phase 3 — Combined Preview

Show everything in one table. This is the first user-visible output:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ENRICH & TAG PREVIEW — [Project Name]
  Events: [N] metadata gaps, [N] tag gaps
  Properties: [N] metadata gaps
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EVENT METADATA  ([N])
  Event Name              │ New Display Name      │ New Description
  ────────────────────────┼───────────────────────┼──────────────────────
  user_signup_complete     │ User Signup Complete  │ User completes signup flow.
  ...

EVENT TAGS  ([N])
  Event Name              │ Current Tags │ New Tags
  ────────────────────────┼──────────────┼──────────────
  add_to_cart              │ —            │ Commerce
  user_signup_complete     │ —            │ Authentication, Onboarding
  ...

NEW TAGS TO CREATE: Commerce, Authentication, Navigation, Engagement, Onboarding

PROPERTY METADATA  ([N])
  Property Name    │ Type  │ New Display Name │ New Description
  ─────────────────┼───────┼──────────────────┼─────────────────────
  platform         │ Event │ Platform         │ Device platform (iOS, Android, Web).
  ...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

(a) Apply all   (b) Edit specific rows   (c) Cancel
```

**Edit flow:** User references by row number or name. Update in memory, re-display, re-confirm.

**Cancel:** Return to router.

---

## Phase 4 — Apply (sequential)

Execute in this order. If any step fails, log and continue — do not abort.

### Step 4a — Events: metadata (bulk)

Build the events array with **only the fields that were empty** for each event:

```
events = [
  { name: "event_1", display_name: "...", description: "..." },
  { name: "event_2", description: "..." },  // display_name already existed, omit
  ...
]
```

Call `Bulk-Edit-Events(project_id, events: [...])`. Chunk into calls of up to **50 events** each. Progress per chunk: `✅ Events: 50/112 metadata updated...`

### Step 4b — Tags: create missing tags

Compute the set of new tag names (from Phase 2 tag proposals not already in `existing_tags`). For each: `Create-Tag(project_id, name)`. Log failures, continue.

### Step 4c — Tags: assign to events (bulk, grouped)

`Bulk-Edit-Events` applies the same `tags` payload uniformly across the events list. So group events by **identical target tag set**, then one bulk call per group:

```
# group { events: [e1, e2], tags: ["Commerce"] }
Bulk-Edit-Events(
  project_id,
  events: [{name: "e1"}, {name: "e2"}],
  tags: { names: ["Commerce"], operation: "add" }
)
```

Use `operation: "add"` — never `"set"` — so we don't clobber any tags added manually. Chunk each group into calls of up to 50 events.

Progress: `✅ Tags: group 2/5 applied (Commerce → 18 events)...`

### Step 4d — Properties: metadata (per-call)

`Bulk-Edit-Properties` does NOT support `description` or `display_name`. Fall back to per-property calls:

```
Edit-Property(project_id, property_name, resource_type, display_name, description)
```

For each property gap, include **only the fields that were empty**. Sequential calls, batches of 10 with progress: `✅ Properties: 10/27 updated...`

---

## Phase 5 — Update Session Cache

After all writes succeed:
- For each updated event, merge new fields into `event_details_cache[event_name]`
- For each updated property, merge new fields into `property_details_cache[property_name]`
- Append new tags to `existing_tags`

---

## Phase 6 — Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✅ ENRICH & TAG COMPLETE — [Project Name]
  Event metadata:   [N]/[N]
  Event tags:       [N]/[N]  (new tags created: [N])
  Property metadata: [N]/[N]
  Failures: [N]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If failures > 0, list them (entity name + error). Return control to router.
