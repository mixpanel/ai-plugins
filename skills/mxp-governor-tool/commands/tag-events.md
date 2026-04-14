# Command — Tag Events

> **Session reads:** `event_list`, `event_details_cache`, `volume_rank_map`
> **Session writes:** `event_list`, `event_details_cache`

Auto-categorize events into Lexicon tags by name patterns. Write after confirmation. Execute silently.

---

## Phase 1 — Fetch & Inventory

Read `shared/schema-reader.md`, fetch/reuse schema. Build:
- `existing_tags`: unique tag names currently in use
- `untagged_events`: events with null/empty tags
- `tagged_events`: events with current tag assignments

If all tagged → ask: `(a) Re-categorize with new tags  (b) Return to menu`

---

## Phase 2 — Generate Tag Proposals

Analyze all event names using three strategies (combine — each event gets 1–3 tags):

**Prefix clustering:** Group by common prefixes.
- `checkout_*` → "Checkout", `onboarding_*` → "Onboarding", `$mp_*`/`$ae_*` → "Mixpanel System"

**Functional domain (primary):**
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

**Volume tier (optional — only if user opts in):**
- Top 10 → "High Volume", Bottom 20% with >0 → "Low Volume", Zero → "Inactive"

---

## Phase 3 — Configure & Preview

Single combined prompt — config + preview together. This is the first user-visible output:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  TAG PLAN — [N] events, [N] proposed tags
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Config (defaults in brackets):
  Casing:      (a) Title Case [default]  (b) Sentence  (c) UPPER
  Mode:        (d) Add to existing [default]  (e) Replace existing
  Volume tags: (f) Include  (g) Skip [default]
  Enter to accept defaults.

PROPOSED TAGS
  Tag Name         │ Count │ Samples
  ─────────────────┼───────┼──────────────────────
  Commerce          │ 12    │ add_to_cart, purchase_complete
  Navigation        │ 8     │ page_view, screen_view
  ...

NEW TAGS TO CREATE: [list]

PER-EVENT
  Event Name              │ Current Tags │ New Tags
  ────────────────────────┼──────────────┼──────────────
  add_to_cart              │ —            │ Commerce
  user_signup_complete     │ —            │ Authentication, Onboarding
  ...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

(a) Apply all  (b) Edit  (c) Cancel
```

**Edit:** Rename tags, merge, add/remove per-event. Re-display, re-confirm.

---

## Phase 4 — Apply

**Step 1 — Create tags:** `Create-Tag(project_id, name)` for each new tag. Log failures, continue.

**Step 2 — Assign:** `Edit-Event(project_id, event_name, tags: { names: [...], operation: "add"|"set" })` based on mode.

Batch of 10. Progress per batch.

Update `event_details_cache` after completion.

---

## Phase 5 — Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✅ TAGGING COMPLETE — [Project Name]
  Tags created: [N]  |  Events tagged: [N]/[N]  |  Failures: [N]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Return control to SKILL.md router.
