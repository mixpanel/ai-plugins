---
name: issue-triage
description: Surface, categorize, and bulk-dismiss Mixpanel data quality issues by type, event, and property. Generates a prioritized remediation report.
---

# Issue Triage

Systematically surface and resolve open data quality issues in Mixpanel Lexicon.

## When to Use

- Periodic data quality audits (weekly / monthly)
- After a major instrumentation change
- Before presenting analytics to stakeholders
- When event or property data looks inconsistent

## Known API Constraints

- `status` and `event_name` filters cause HTTP 500 — never use them
- Working filters: `limit`, `offset`, `query`, `issue_type`
- `issue_type="type_drift"` is the most common type and the highest-signal starting point
- Stop paginating when `count < limit`

## Triage Workflow

### Phase 1: Fetch Issues

Start with `type_drift` — it accounts for the vast majority of issues in most projects:

```
Get-Issues project_id=<id> issue_type="type_drift" limit=50
Get-Issues project_id=<id> issue_type="type_drift" limit=50 offset=50  # if count == 50
```

Then do a second pass without `issue_type` to catch other issue types:

```
Get-Issues project_id=<id> limit=50
```

Deduplicate against the first pass by `id`.

### Phase 2: Group by Property First

The most important grouping is **by `property_name`**, not by event. A single property sending the wrong type across 10 events is one root cause, one fix.

For each unique `property_name`:
- Count how many events are affected
- Note the drift directions (e.g. "from string" across all → canonical type is string)
- Rank by event count descending

**Reading drift direction:** `"from string"` means string was the established type and something new is drifting away from it. The canonical type to normalize to is almost always the "from" type.

### Phase 3: Prioritize

| Signal | Priority |
|--------|----------|
| Property affects 5+ events | 🔴 Critical — systemic SDK mismatch |
| Property is a core identity or context field | 🔴 Critical — breaks filtering and funnels |
| Property is used in key reports or funnels | 🟠 High |
| Property is on internal or performance-monitoring events only | 🟡 Low — fix but not urgent |
| Property is auto-captured by the SDK | 🟢 Dismiss candidate |
| Property is structurally polymorphic by design | 🟢 Dismiss candidate |

For high-priority events where volume context matters, confirm activity before escalating:

```
Run-Segmentation-Query:
  event:     "<event_name>"
  from_date: "<30 days ago>"
  to_date:   "<today>"
  unit:      "day"
  type:      "general"
```

Skip volume checks for obviously internal events (performance telemetry, SDK auto-instrumented events, opt-in/opt-out events).

### Phase 4: Identify Quick-Dismiss Candidates

Some drift is expected by design — dismiss without a code fix:

| Pattern | Why it's safe to dismiss |
|---------|--------------------------|
| SDK auto-captured properties | SDK controls the type; not instrumented by your team |
| Properties that are polymorphic by design | e.g. a value that is a string for single-select and a list for multi-select |
| Properties on deprecated or hidden events | Event is no longer active; issue is noise |
| Known intentional schema change | Confirmed with owner; document in Lexicon first, then dismiss |

### Phase 5: Remediate

**Fix in code** (correct approach for systemic type_drift):
- Identify all SDK call sites sending the wrong type
- Normalize to the canonical "from" type before calling `mixpanel.track()`
- Common pattern: client-side code pulls a value from a URL param or DOM attribute (always a string); server-side code pulls the same value from a database (often a number). Pick one and cast consistently.
- After deploying, re-run `Get-Issues` after ~24h to confirm the issue stops recurring

**Update Lexicon docs** to document the resolved type:

```
Edit-Property:
  project_id:    <id>
  resource_type: "Event"
  property_name: "<property>"
  description:   "Type: <type>. <what the value represents>."
```

**Dismiss resolved or intentional issues:**

```
Dismiss-Issues:
  project_id:           <id>
  issue_type:           "type_drift"
  property_name:        "<property>"
  dismiss_all_matching: true   # required if multiple issues match
```

> ⚠️ `Dismiss-Issues` is destructive. Confirm dismiss candidates with the user before bulk-dismissing. Dismissing removes the Lexicon flag but does not fix the underlying data.

### Phase 6: Generate Remediation Report

**Header stats:**

| Metric | Count |
|--------|-------|
| Total issues | X |
| Unique properties affected | X |
| Systemic (3+ events per property) | X |
| Quick-dismiss candidates | X |
| Require code fix | X |

**Systemic issues table** (property-grouped, sorted by event count):

| Property | Events affected | Drift from | Canonical type | Recommended action |
|----------|----------------|------------|----------------|--------------------|
| `<property>` | N | string | string | Normalize all SDK call sites |
| `<property>` | N | number | number | Check client vs. server path |

**One-off issues table:**

| Property | Event | Drift | Recommended action |
|----------|-------|-------|--------------------|
| `<property>` | `<event>` | from boolean | Dismiss — SDK auto-captured |
| `<property>` | `<event>` | from list | Dismiss — polymorphic by design |

**Next steps:** deploy fixes → re-run `Get-Issues` in 24–48h to confirm resolution
