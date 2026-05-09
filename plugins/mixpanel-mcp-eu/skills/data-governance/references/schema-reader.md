# Reference — Schema Reader

Reusable schema-fetching contract. All commands route through this file. **Always reuse session-cached data — only fetch what's missing.**

The Mixpanel MCP exposes Lexicon metadata in bulk reads — one call for events, two calls for properties (split by `resource_type`). There is no per-entity fetch tool. All metadata (description, display_name, tags, verified, hidden) comes back in those bulk responses.

For chunk sizes, fallback paths, and resource-type semantics, see `references/mcp-cheatsheet.md`. For ignored entities, see `references/exclusions.md`.

---

## Fetch Events + Metadata

If `event_list` AND `event_details_cache` exist in session → skip.

Otherwise: `Get-Events(project_id)` — returns full metadata for every event in one call.

Populate both:
- `event_list` — array of event names
- `event_details_cache` — `event_name → metadata` map, fully populated from the same response

Empty result → error.

> No per-event detail loop. The single `Get-Events` call is the source of truth.

---

## Volume Ranking

If `volume_rank_map` exists → skip. Otherwise call `Run-Query` with the canonical payload from `assets/volume-ranking-query.json` (substitute the project context as required by the MCP).

Parse the response into `volume_rank_map`: `{ event_name: { volume, rank } }`.

If `Run-Query` fails → call `Get-Query-Schema`, retry once. If retry fails → log, proceed with empty `volume_rank_map`. Downstream commands degrade gracefully (see `references/gotchas.md`).

---

## Fetch Properties + Metadata

If `property_names` AND `property_details_cache` exist → skip.

Otherwise issue **two calls**, one per resource type — `Get-Properties` is single-resource-type:

1. `Get-Properties(project_id, resource_type: "Event")`
2. `Get-Properties(project_id, resource_type: "User")`

Each call returns full metadata for every property of that type. Merge into:
- `property_names` — `{ event: [...], user: [...] }`
- `property_details_cache` — `(resource_type, property_name) → metadata` map, fully populated

> No 30-property sample, no stratification, no per-property fetch loop.

---

## Notes on what's *not* fetched here

- **Property values** (`Get-Property-Values`) — not needed for governance audits. Only fetch if a specific command (e.g., a future RCA workflow) calls for it.
- **Issues** — fetched separately by `commands/review-issues.md` via `Get-Issues`.
- **Business context** — fetched separately by `commands/enrich-and-tag.md` via `Get-Business-Context`.
