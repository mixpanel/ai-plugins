# Command: Cleanup Dashboards

Audits the dashboard estate in a project: identifies **stale** (not touched in a long time), duplicate, empty, and sparse boards. Recommends archive or delete.

Staleness is a first-class signal here — a board with many reports that nobody has touched in months is still a cleanup candidate. Do not equate "has reports" with "healthy."

---

## Execution

### Phase 1 — Fetch all dashboards (with recency)

1. Call `Search-Entities` with `entity_types=["dashboard"]` and `sort_by` on the most recent timestamp the API exposes (last-modified or last-viewed). `Search-Entities` is preferred over `List-Dashboards` because it returns richer metadata and supports sorting — both the tool itself and the MCP reference recommend it.
   - If `Search-Entities` is unavailable, fall back to `List-Dashboards`.
2. For each dashboard, extract whatever the response provides:
   - `id`, `title`, `description`
   - `last_modified` (a.k.a. modified/updated timestamp), `last_viewed` (if present), `created_at`
   - `creator` / `owner` (if available)
3. Cache in `dashboard_list_cache`.

**Recency field discovery (do this once, silently):** Inspect the first result object to see which timestamp fields are actually present. Prefer, in order: `last_viewed` → `last_modified`/`updated_at` → `created_at`. Record which field was used so the report can label it accurately (e.g. "Last modified" vs "Last viewed"). If NO timestamp field is present in the response, skip the Stale classification entirely and tell the user in the report header: "Recency data not available from the API — staleness not assessed; showing structural flags only."

### Phase 2 — Deep inspection

For each dashboard from Phase 1, call `Get-Dashboard` with `include_layout=true`.
Fire in parallel (batches of 5 to avoid rate limits). Skip any dashboard already in `dashboard_layout_cache`.

From the layout, derive and cache:
- **Report count:** number of cells with `type: "report"`
- **Text-only count:** number of cells with `type: "text"`
- **Total cells:** sum of all cells
- **Row count:** number of rows

### Phase 3 — Classification

Compute `days_since` from the chosen recency timestamp (today minus that date). Then classify. **Staleness and structure are independent axes** — evaluate both and a board may carry a structural flag *and* a stale flag.

> **Use the bundled helper for staleness and duplicate math.** Run `scripts/dashboard_utils.py` rather than re-deriving title normalization or recency arithmetic by hand each run — it is the single source of truth for `days_since(...)`, `normalize_title(...)`, and `is_probable_duplicate(...)`. This keeps results deterministic across runs.

**Structural flags** (from layout):

| Category | Criteria | Flag |
|----------|----------|------|
| **Empty** | 0 report cells AND 0 text cells (or only a single default text card) | 🟡 Empty |
| **Text-only** | 0 report cells but has text cards | 🟡 Text-only |
| **Sparse** | 1-2 report cells only | 🔵 Sparse |
| **Potential duplicate** | `is_probable_duplicate()` returns true vs. another board — i.e. normalized-title similarity ≥ 0.80 (difflib ratio) **or** one normalized title is contained in the other | 🟠 Possible dup |
| **Healthy** | 3+ report cells | ✅ Active |

**Recency flag** (from `days_since`, only if a timestamp was found):

| Category | Criteria | Flag |
|----------|----------|------|
| **Stale** | `days_since` ≥ 90 | 🔴 Stale ([N]d) |
| **Aging** | 60 ≤ `days_since` < 90 | 🟤 Aging ([N]d) |
| **Recent** | `days_since` < 60 | (no flag) |

> Default threshold is 90 days. If the user names a different window ("anything untouched for 6 months", "stale = 30 days"), use theirs. State the threshold in the report header.

**Cleanup priority** — order the action list by: 🔴 Stale **and** (Empty/Text-only/Sparse) first → 🔴 Stale + Active → 🟠 duplicates → 🟡 structural-only. The worst offenders are old *and* thin.

**Duplicate detection** — delegated to `scripts/dashboard_utils.py`:
- `normalize_title()` lowercases and strips trailing "(Copy)", "(N)", trailing dates, and surrounding whitespace.
- `is_probable_duplicate(a, b)` returns true when the difflib similarity ratio of the two normalized titles is ≥ 0.80, **or** one normalized title is a substring of the other (e.g. "KPI Dashboard" vs "KPI Dashboard v2").
- Run it pairwise across the board list; flag both members of any matching pair.

### Phase 4 — Report

Present the audit as a table. Include the recency column and label it with the actual field used.

```
Dashboard Audit — [Project Name] ([project_id])
Recency basis: Last modified | Stale threshold: 90 days
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID       | Title                     | Reports | Last modified | Status
---------|---------------------------|---------|---------------|------------------
1234567  | Onboarding Funnel         | 6       | 5d ago        | ✅ Active
1234568  | Onboarding Funnel (Copy)  | 6       | 142d ago      | 🔴 Stale · 🟠 dup
1234569  | Test Board                | 0       | 311d ago      | 🔴 Stale · 🟡 Empty
1234570  | Notes                     | 0       | 18d ago       | 🟡 Text-only
1234571  | Quick Metrics             | 1       | 96d ago       | 🔴 Stale · 🔵 Sparse
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Summary: 15 dashboards | 4 stale | 3 empty | 2 possible duplicates | 1 sparse | 8 active
Top cleanup candidates: #1234569 (stale + empty), #1234568 (stale + dup), #1234571 (stale + sparse)
```

If recency data was unavailable, drop the "Last modified" column and the stale flags, and note it in the header.

### Phase 5 — Action (interactive)

After showing the audit, ask what the user wants to do:

**Option A: Delete selected boards**
- User provides IDs to delete (comma-separated or range)
- Show confirmation with titles: "Delete these 3 dashboards? [Title A], [Title B], [Title C]"
- On confirm → call `Delete-Dashboard` for each, sequentially
- Show progress: `Deleted 2/3...`

**Option B: Delete all top cleanup candidates**
- List all boards flagged 🔴 Stale **and** structurally thin (Empty / Text-only / Sparse) — the safest bulk target.
- Require explicit confirmation with count: "Delete all 4 stale + thin dashboards?"
- Execute deletions

**Option C: Delete all flagged-empty boards**
- List all 🟡 Empty + 🟡 Text-only boards (regardless of age)
- Require explicit confirmation with count
- Execute deletions

**Option D: Skip — just wanted the audit**
- Return control to router

**Never auto-delete.** Always require explicit confirmation. Never propose deleting a 🔴 Stale board that is still 3+ reports without flagging that it may be a seasonal/quarterly board worth archiving rather than deleting.

**Verify deletions.** After running deletions, re-fetch the dashboard list (or attempt `Get-Dashboard` on each deleted ID and expect a not-found) to confirm each target is actually gone before reporting the count. Report any ID that still resolves as a failed deletion rather than a success.

---

## Output

After deletions (if any):

```
✅ Cleanup complete
   Deleted:  [N] dashboards
   Remaining: [M] dashboards
   Freed:    [list of deleted titles]
```

Return control to router.

---

## Error Handling

| Situation | Action |
|-----------|--------|
| `Search-Entities` unavailable | Fall back to `List-Dashboards` (no sort); recency still parsed if present |
| No timestamp field in response | Skip Stale/Aging classification, note in header, show structural flags only |
| `Search-Entities`/`List-Dashboards` returns empty | "No dashboards found in this project." Return. |
| `Get-Dashboard` fails for one board | Mark as "⚠️ Could not inspect", continue with others |
| `Delete-Dashboard` fails | Note the failure, continue with remaining deletions |
| User cancels deletion | "No dashboards deleted." Return. |
