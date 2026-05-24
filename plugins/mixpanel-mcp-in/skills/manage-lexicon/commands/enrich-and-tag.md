# Command — Enrich & Tag Lexicon

> **Session reads:** `event_list`, `event_details_cache`, `property_names`, `property_details_cache`, `volume_rank_map`
> **Session writes:** `event_list`, `event_details_cache`, `property_names`, `property_details_cache`, `existing_tags`

Auto-generate display names, descriptions, and tags for events and properties that are missing them. One combined preview, one confirmation, then three sequential bulk writes: events → tags → properties. Execute silently.

---

## Phase 1 — Identify Gaps

Find events and properties without descriptions, display names, or tags.

Ensure the required Session reads are loaded; fetch any that aren't. Properties are split by resource type — fetch event properties and user properties separately and merge.

Build three gap lists:

**Event metadata gaps:** for each event, record which of these are empty:
- `description` (null/empty)
- `display_name` (null OR equals raw event name)

**Event tag gaps:** events where `tags` is null or empty array.

**Property metadata gaps:** properties where `description` is null/empty OR `display_name` is null/empty.

If all three lists are empty → output `✅ All events and properties already have descriptions, display names, and tags.` → return to Execution loop.

---

## Phase 2 — Generate Suggestions

Generate the new values for every gap found in Phase 1.

### General rules

- **Seed with business context.** Before generating, fetch the project's business context (company name, product domain, business model, key user flows). Pass it into every description and tag prompt so enrichment matches the actual product instead of generic guesses from event names. Fall back to name-based generation if business context is unavailable.
- **Default casing:** Title Case for display names and tags. The user can override in the preview — no upfront config prompt.

### Display names (events and properties)

Convert raw names from snake_case / camelCase / kebab-case into a human-readable form. Strip prefixes (`mp_`, `$mp_`, `$`). System events (`$`-prefixed) still get readable display names.

### Descriptions (events and properties)

Infer purpose from the entity name plus schema and business context. One to two sentences, under 120 characters. Use analytics-perspective framing.

### Tags (events only)

Assign one to three tags per event, combining two strategies:

*Prefix clustering:* group events by name prefix when the cluster maps cleanly to a product area. Examples: `checkout_*` → "Checkout", `onboarding_*` → "Onboarding", `$mp_*` / `$ae_*` → "Mixpanel System".

*Functional domain:* match the event verb/noun to the customer's product domain. Pull domain naming from the business context above. Baseline patterns: commerce events (purchase, cart, payment) → "Commerce"; auth events (login, signup, register) → "Authentication"; engagement events (click, view, navigate) → "Engagement"; errors (error, fail, crash) → "Errors". These are starting points — propose domain-fitting tags from the business context when the defaults don't match (e.g., fintech transactions, healthtech consults, gaming sessions).

---

## Phase 3 — Combined Preview

Show every proposed change in one table so the user confirms once for all three write groups.

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

(a) Apply all   (b) Edit specific rows   (c) Cancel   (d) Export preview as JSON
```

**Apply all (a):** single confirmation covering all three write groups in Phase 4. Proceed.

**Edit (b):** user references rows by number or name. Update in memory, re-display, re-confirm.

**Cancel (c):** return to Execution loop.

**Export (d):** write the preview payload (events + tag groups + properties) to `data-governance-runs/[ISO-timestamp]-enrich-preview.json` in the working directory. Confirm path to user. No writes to Mixpanel. Return to Execution loop.

---

## Phase 4 — Apply (sequential)

Execute the three write groups in order. One user confirmation already gave consent for all three; do not re-prompt between groups. If any step fails, log and continue — do not abort.

**Bulk write conventions used below:**
- Bulk-edit calls (events and properties) accept up to 50 entries per call. Split larger payloads into 50-chunks.
- If a bulk chunk errors, fall back to per-entity edits for that chunk in batches of 10. Log the failure and continue.
- Each entry should include **only fields that need updating** — partial payloads are correct.

### Step 4a — Events: metadata (bulk)

Build the events array with only the fields that were empty for each event:

```
events = [
  { name: "event_1", display_name: "...", description: "..." },
  { name: "event_2", description: "..." },  // display_name already existed, omit
  ...
]
```

Issue the bulk events edit in chunks of up to 50. Progress: `✅ Events: 50/112 metadata updated...`

### Step 4b — Tags: create missing tags

Compute the set of new tag names (Phase 2 proposals not already in `existing_tags`). Create each one. Log failures, continue.

### Step 4c — Tags: assign to events (bulk, grouped)

A single bulk-edit-events call applies its `tags` payload uniformly to every event in the call (see Behaviour rules in SKILL.md). Group events by identical target tag set, then issue one bulk call per group:

```
# group { events: [e1, e2], tags: ["Commerce"] }
events: [{name: "e1"}, {name: "e2"}]
tags:   { names: ["Commerce"], operation: "add" }
```

Always use `operation: "add"` here — never `"set"`. `set` clobbers tags the customer added manually outside this tool. Chunk each group into calls of up to 50 events.

Progress: `✅ Tags: group 2/5 applied (Commerce → 18 events)...`

### Step 4d — Properties: metadata (bulk)

Property bulk-edits are single-resource-type per call — the request will be rejected if event and user properties are mixed. Split gaps by `Event` vs `User` and issue two calls (chunked to 50 each):

```
resource_type: "Event"
properties: [
  { name: "platform", display_name: "Platform", description: "..." },
  { name: "source", description: "..." },  // display_name already existed, omit
  ...
]
```

Progress: `✅ Properties: 50/120 metadata updated...`

If a bulk call fails, fall back to per-property edits for that chunk in batches of 10. Log and continue.

---

## Phase 5 — Audit Trail

Append a one-line summary to `data-governance-runs/[ISO-timestamp]-enrich.json`:

```json
{
  "command": "enrich-and-tag",
  "project_id": "...",
  "timestamp": "2026-05-09T...",
  "event_metadata_writes": N,
  "event_tag_writes": N,
  "property_metadata_writes": N,
  "new_tags_created": ["Commerce", "Authentication"],
  "failures": []
}
```

---

## Phase 6 — Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✅ ENRICH & TAG COMPLETE — [Project Name]
  Event metadata:    [N]/[N]
  Event tags:        [N]/[N]  (new tags created: [N])
  Property metadata: [N]/[N]
  Failures:          [N]
  Audit log:         data-governance-runs/[file].json
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If failures > 0, list them (entity name + error). Return control to the Execution loop.
