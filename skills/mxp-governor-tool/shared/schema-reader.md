# Shared — Schema Reader

Reusable schema fetching logic. All commands reference this. **Always reuse session-cached data — only fetch what's missing.**

---

## Fetch All Events

If `event_list` exists → skip. Otherwise: `Get-Events(project_id)` with no filter. Store as `event_list`. Empty result → error.

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

## Fetch Event Details

For each event (or subset), call `Get-Event-Details(project_id, event_name)`. Skip if already in `event_details_cache`.

- ≤50 events → fetch all
- >50 → top 50 by volume rank + any user-requested

Sequential calls. Progress note only if >20 calls: `Fetching details... [N]/[total]`

Cache in `event_details_cache`.

## Fetch All Property Names

If `property_names` exists → skip. Otherwise: `Get-Property-Names(project_id)`. Split into event/user lists.

## Fetch Property Details

For target properties, call `Get-Property(project_id, property_name, resource_type)`. Skip cached. Cap at 50. Cache in `property_details_cache`.
