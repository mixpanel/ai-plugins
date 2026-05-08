# Shared — Schema Reader

Reusable schema fetching logic. All commands reference this. **Always reuse session-cached data — only fetch what's missing.**

The Mixpanel MCP exposes Lexicon metadata in bulk reads — one for events, two for properties (split by `resource_type`). There is no per-entity fetch tool. All metadata (description, display_name, tags, verified, hidden) comes back in those bulk responses.

---

## Fetch Events + Metadata

If `event_list` AND `event_details_cache` exist → skip.

Otherwise: `Get-Events(project_id)` — returns full metadata for every event in one call (name, description, display_name, tags, verified, hidden status).

Populate both:
- `event_list` — array of event names
- `event_details_cache` — `event_name → metadata` map, fully populated from the same response

Empty result → error.

> No per-event detail loop. The single `Get-Events` call is the source of truth.

---

## Volume Ranking

If `volume_rank_map` exists → skip. Otherwise run:

```json
{
  "name": "Event Volume Ranking",
  "metrics": [{ "eventName": "$all_events", "measurement": { "type": "basic", "math": "total" } }],
  "chartType": "table",
  "unit": "day",
  "dateRange": { "type": "relative", "range": { "unit": "day", "value": 7 } },
  "breakdowns": [{ "property": { "name": "$event_name", "resourceType": "events" }, "typeCast": null }]
}
```

Parse into `volume_rank_map`: `{ event_name: { volume, rank } }`.

If `Run-Query` fails → call `Get-Query-Schema`, retry once. If retry fails → log, proceed with empty `volume_rank_map` (downstream commands degrade gracefully).

---

## Fetch Properties + Metadata

If `property_names` AND `property_details_cache` exist → skip.

Otherwise issue **two calls** (one per resource_type), since `Get-Properties` and the corresponding write tool `Bulk-Edit-Properties` are both single-resource-type:

1. `Get-Properties(project_id, resource_type: "Event")`
2. `Get-Properties(project_id, resource_type: "User")`

Each call returns full metadata (name, description, display_name) for every property of that type. Merge into:
- `property_names` — `{ event: [...], user: [...] }`
- `property_details_cache` — `(resource_type, property_name) → metadata` map, fully populated

> No 30-property sample, no stratification, no per-property fetch loop. Bulk reads return everything.

---

## Notes on what's *not* fetched here

- **Property values** (`Get-Property-Values`) — not needed for governance audits. Only fetch if a specific command (e.g., a future RCA workflow) calls for it.
- **Issues** — fetched separately by `commands/review-issues.md` via `Get-Issues`.
- **Business context** — fetched separately by `commands/enrich-and-tag.md` via `Get-Business-Context`.
