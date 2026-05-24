# Command — Review Issues

> **Session reads:** `event_list`, `volume_rank_map`, `event_details_cache`
> **Session writes:** `issues_list`, `event_list`, `volume_rank_map`

Fetch open data quality issues, triage by severity, produce a prioritised report. Execute silently.

---

## Phase 1 — Fetch Issues

Pull every open data quality issue for the project and normalise into `issues_list`.

Fetch the project's open issues in a single bulk call — no manual pagination.

If the response exceeds 200 entries, sort by timestamp descending and keep the top 200. This is a UX cap to keep the triage report navigable — the rest can be reviewed in subsequent runs as the top ones are dismissed.

Deduplicate on `(event_name, property_name, issue_type)` — keep the most recent timestamp.

Store as `issues_list`. Each entry: `{ id, issue_type, description, event_name, property_name, timestamp, status }`.

If zero issues → output `✅ No open data quality issues.` → return to Execution loop.

---

## Phase 2 — Triage

Group every issue by type, then assign a severity to each.

### Group by type (precedence order — first match wins)

Evaluate each issue against these patterns in order. Assign to the first group that matches:

1. **Type Drift** — issue_type contains "type" or "drift"
2. **Null Property Values** — issue_type contains "property" or "null"
3. **Volume Anomalies** — issue_type contains "volume" or "anomaly"
4. **Other** — everything else

### Assign severity

If `volume_rank_map` is not in session, fetch it now: run the payload in `assets/volume-ranking-query.json` and parse into `volume_rank_map: { event_name: { volume, rank } }`. If the query fails, proceed with `volume_rank_map = {}` — severity scoring below will skip the volume tiebreaker.

**Null Property Values:**
- High → property on top-20 event OR key dimension (`user_id`, `content_id`, `platform`, `plan_id`, `subscription_status`, `device_type`)
- Medium → property on active event (has 7-day volume)
- Low → on hidden / dropped / zero-volume event

**Type Drift:**
- High → key property OR affects >5 events
- Medium → 2–5 events
- Low → 1 event

**Volume Anomalies:**
- High → >50% drop on top-20 event
- Medium → >50% drop on any active event
- Low → spike (informational)

### Rank

Sort: High → Medium → Low. Within severity: highest event volume first.
Top 5 critical = first 5 High (fill from Medium if <5).

---

## Phase 3 — Output

Render the triage report directly.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ISSUES — [Project Name]
  Total: [N]  |  🔴 High: [N]  ⚠️ Med: [N]  ℹ️ Low: [N]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔴 TOP 5 CRITICAL
  1. [Type] — [Event] / [Property]
     Why: [1-line]  |  Fix: [specific action]
  2. ...

BY CATEGORY

Null Property Values ([N])
  #  │ Event             │ Property        │ Sev  │ Date
  ───┼───────────────────┼─────────────────┼──────┼──────────
  1  │ purchase_complete │ payment_method  │ 🔴   │ 2026-04-12
  ...

Type Drift ([N])
  ...

Volume Anomalies ([N])
  ...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

(a) Deep dive on an issue  (b) Dismiss issues  (c) Done
```

---

## Phase 4 — Interactive (only if user selects a/b)

Run deep-dive context queries or dismiss issues based on user choice.

### Deep Dive

User picks by number or event name. Run contextual query:
- Null values → Insights breakdown by null property, 30 days
- Type drift → Insights breakdown by drifting property, 30 days
- Volume anomaly → Insights trend, daily, 30 days

Display results. Then: `(a) Dismiss  (b) Another  (c) Done`

### Dismiss

User specifies by number, range ("1-5"), or "all low". **Confirm before each dismiss.**

Dismiss the matching issue(s) via the issues endpoint. Update `issues_list`. Show: `Dismissed [N]. [N] remaining.`

If any issues were dismissed in this session, append a summary to `data-governance-runs/[ISO-timestamp]-review-issues.json`:

```json
{
  "command": "review-issues",
  "project_id": "...",
  "timestamp": "2026-05-09T...",
  "dismissed": [{"event": "...", "property": "...", "issue_type": "..."}],
  "remaining": N
}
```

Loop back to the action prompt until user picks (c) Done.

---

On Done → return control to the Execution loop.
