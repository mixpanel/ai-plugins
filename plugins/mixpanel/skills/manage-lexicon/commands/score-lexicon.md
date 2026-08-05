# Command — Score Lexicon

> **Session reads:** `event_list`, `event_details_cache`, `property_names`, `volume_rank_map`
> **Session writes:** `event_list`, `event_details_cache`, `property_names`, `property_details_cache`, `volume_rank_map`

Audit Lexicon metadata coverage and compute a health score (0–100). Self-contained pipeline: fetch → audit → score → report. Execute silently — no phase announcements.

---

## Phase 1 — Fetch Schema

Load the events, properties, and volume ranking the audit needs.

Ensure the required Session reads are loaded; load any that aren't.

- **Events + metadata.** Load event metadata for the full project.
- **Volume ranking.** Run the payload in `assets/volume-ranking-query.json`. Parse the response into `volume_rank_map: { event_name: { volume, rank } }`. If the query fails, proceed with `volume_rank_map = {}` — downstream degrades gracefully (the score still renders; severity scoring in `review-issues` skips the volume tiebreaker).
- **Properties + metadata.** Load property metadata for event properties and user properties separately. Merge into `property_names: { event: [...], user: [...] }` and `property_details_cache`.

---

## Phase 2 — Audit Event Metadata

Score every event in the working set against the four metadata fields plus hygiene.

| Field | Pass condition |
|---|---|
| `description` | Non-null, non-empty |
| `display_name` | Non-null AND differs from raw event name |
| `verified` | `true` |
| `tags` | Non-empty array |
| `hygiene` | Zero 7-day volume → must be hidden/dropped. If not → ⚠️ |

Compute per-field coverage: `(pass count) / (working set size) × 100`.

Collect **zero-metadata events** (all four of description, display_name, verified, tags fail).

---

## Phase 3 — Audit Property Metadata

Score every property against description and display name.

For each property in `property_details_cache` (full set, post-exclusions):

| Field | Pass condition |
|---|---|
| `description` | Non-null, non-empty |
| `display_name` | Non-null AND differs from raw name |

Compute coverage for event properties and user properties separately.

---

## Phase 4 — Compute Score

Combine the sub-scores into a single weighted 0–100 score and grade.

Weighted average (each sub-score 0–100):

| Sub-score | Weight |
|---|---|
| Event description coverage | 20% |
| Event display name coverage | 8% |
| Event verified coverage | 15% |
| Event tagging coverage | 10% |
| Property description coverage | 20% |
| Property display name coverage | 7% |
| Dropped/hidden hygiene | 10% |
| Data quality issues | 10% |

**Issues sub-score:** if `issues_list` is in session → `max(0, 100 - (open_count × 2))`. Otherwise redistribute that 10% weight across the other six sub-scores. Do not display a `0/100` issues row when no data is available.

| Score | Grade |
|---|---|
| 90–100 | A — Excellent |
| 75–89 | B — Good |
| 60–74 | C — Needs work |
| 40–59 | D — Poor |
| 0–39 | F — Critical |

---

## Phase 5 — Output

Render the score report directly.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  LEXICON SCORE — [Project Name]
  Score: [XX]/100 ([Grade])
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Event descriptions      [XX]%    (wt 20%)
  Event display names     [XX]%    (wt 8%)
  Event verified          [XX]%    (wt 15%)
  Event tags              [XX]%    (wt 10%)
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

Offer the bulk enrich handoff if the score report surfaced any actionable gaps.

Gap conditions (any of):
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
- **(a)** → Read `commands/enrich-and-tag.md` and execute. Session cache is already populated — `enrich-and-tag` reuses it with no re-fetching.
- **(b)** → Return control to the Execution loop.

**If no gaps →** no handoff prompt. Return control to the Execution loop.

---

## Phase 7 — Audit Trail

Read-only command. No audit log required.
