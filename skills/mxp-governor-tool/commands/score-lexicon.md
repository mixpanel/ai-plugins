# Command — Score Lexicon

> **Session reads:** `event_list`, `event_details_cache`, `property_names`, `volume_rank_map`
> **Session writes:** `event_list`, `event_details_cache`, `property_names`, `property_details_cache`, `volume_rank_map`

Audit Lexicon metadata coverage and compute a health score (0–100). Self-contained pipeline: fetch → audit → score → report. Execute silently — no phase announcements.

---

## Exclusions

Apply before auditing. Excluded items are silently removed from the working set — they do not count toward coverage scores or gap lists.

**Ignored events:**
- `$ae_first_open`, `$ae_updated`, `$ae_session`, `$ae_iap`, `$ae_crashed` — legacy auto-tracked mobile SDK events
- `$session_start`, `$session_end` — virtual events (project session definitions)

**Ignored properties:**
- Any property prefixed with `mp_` or `$` — Mixpanel-managed system properties

---

## Phase 1 — Fetch Schema

Read `shared/schema-reader.md` and execute. Reuse any session-cached data. Fetch only what's missing:
1. Events → `event_list`
2. Volume ranking → `volume_rank_map`
3. Event details for working set (top 50 by volume, or all if ≤50)
4. Property names → `property_names`
5. Property details — stratified sample up to 30

No progress commentary unless a batch exceeds 20 sequential calls (then one line: "Fetching event details... [N]/[total]").

---

## Phase 2 — Audit Event Metadata

For each event in working set, evaluate:

| Field | Pass condition |
|-------|---------------|
| `description` | Non-null, non-empty |
| `display_name` | Non-null AND differs from raw event name |
| `verified` | `true` |
| `tags` | Non-empty array |
| `hygiene` | Zero 7-day volume → must be hidden/dropped. If not → ⚠️ |

Compute per-field coverage: `(pass count) / (working set size) × 100`.

Collect **zero-metadata events** (all four of description, display_name, verified, tags fail).

---

## Phase 3 — Audit Property Metadata

For each property in sample, evaluate:

| Field | Pass condition |
|-------|---------------|
| `description` | Non-null, non-empty |
| `display_name` | Non-null AND differs from raw name |

Compute coverage for event properties and user properties separately.

---

## Phase 4 — Compute Score

Weighted average of sub-scores (each 0–100):

| Sub-score | Weight |
|-----------|--------|
| Event description coverage | 20% |
| Event display name coverage | 8% |
| Event verified coverage | 15% |
| Event tagging coverage | 10% |
| Property description coverage | 20% |
| Property display name coverage | 7% |
| Dropped/hidden hygiene | 10% |
| Data quality issues | 10% |

**Issues sub-score:** If `issues_list` in session → `max(0, 100 - (open_count × 2))`. Otherwise redistribute 10% weight to other six.

| Score | Grade |
|-------|-------|
| 90–100 | A — Excellent |
| 75–89 | B — Good |
| 60–74 | C — Needs work |
| 40–59 | D — Poor |
| 0–39 | F — Critical |

---

## Phase 5 — Output

Render the score report directly:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  LEXICON SCORE — [Project Name]
  Score: [XX]/100 ([Grade])
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Event descriptions      [XX]%    (wt 20%)
  Event display names     [XX]%    (wt 8%)
  Event verified           [XX]%    (wt 15%)
  Event tags               [XX]%    (wt 10%)
  Property descriptions   [XX]%    (wt 20%)
  Property display names  [XX]%    (wt 7%)
  Hygiene (hide/drop)     [XX]%    (wt 10%)
  Data quality issues     [XX]/100 (wt 10%)
───────────────────────────────────────────────

TOP GAPS
  1. [N] events — no description
  2. [N] events — no tags
  3. [N] zero-volume events not hidden
  4. [N] properties — no description

ZERO-METADATA EVENTS
  [event_1], [event_2], ...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Phase 6 — Auto-Offer Bulk Enrichment

After rendering the score report, check if any of these gap conditions are true:
- Event description coverage < 100%
- Event display name coverage < 100%
- Event tag coverage < 100%
- Property description coverage < 100%
- Property display name coverage < 100%

**If yes →** append this prompt immediately after the score block:

```
[N] total metadata/tag gaps detected.

(a) Run bulk enrichment on gaps  (b) Return to menu
```

Selection handling:
- **(a)** → Read `commands/enrich-and-tag.md` and execute. Session cache (event/property details, volume rank) is already populated by the score fetch — `enrich-and-tag` will reuse it with no re-fetching.
- **(b)** → Return control to router.

**If no gaps →** no handoff prompt. Return control to router.
