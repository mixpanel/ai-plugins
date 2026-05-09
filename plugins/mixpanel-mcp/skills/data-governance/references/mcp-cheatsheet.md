# Reference — Mixpanel MCP Cheatsheet

Centralised summary of every MCP-call quirk this skill depends on. **Edit this file (and only this file) if the Mixpanel MCP changes.** All commands route through these conventions.

---

## Bulk read tools

| Tool | Returns | Notes |
|---|---|---|
| `Get-Events(project_id)` | Full metadata for every event (name, description, display_name, tags, verified, hidden, 7-day volume) | One call returns everything. No per-event detail loop. |
| `Get-Properties(project_id, resource_type)` | Full metadata for every property of one resource type (name, description, display_name) | Single-resource-type. Issue twice — once for `Event`, once for `User`. |
| `Get-Issues(project_id)` | All open data quality issues | One response. Cap at 200 (sort timestamp desc) if exceeded. |
| `Get-Business-Context(project_id)` | Company name, product domain, business model, key user flows | Used by `enrich-and-tag` to seed description / tag generation. Fall back to name-based generation if empty / fails. |

## Bulk write tools

| Tool | Chunk size | Notes |
|---|---|---|
| `Bulk-Edit-Events(project_id, events: [...])` | **50 events per call** | Each entry supports per-event `description` and `display_name`. The `tags` field on the call applies **uniformly** to the events list — group events by identical target tag set, then issue one call per group. |
| `Bulk-Edit-Properties(project_id, resource_type, properties: [...])` | **50 properties per call** | Single-resource-type per call — split gaps by `Event` vs `User`. Each entry supports per-property `description` and `display_name`. |

## Per-call tools (used as fallback or atomic action)

| Tool | When to use | Batch size |
|---|---|---|
| `Edit-Event` | Fallback if a `Bulk-Edit-Events` chunk errors | 10 per batch, show progress |
| `Edit-Property` | Fallback if a `Bulk-Edit-Properties` chunk errors | 10 per batch |
| `Create-Tag(project_id, name)` | Creating new tags before assigning them | 10 per batch |
| `Delete-Tag(project_id, name)` | Atomic delete; removes the tag from all events automatically | Single call |
| `Rename-Tag(project_id, old, new)` | Atomic rename across all events | Single call. **May error on merge** (target name exists) — fall back to per-event `Edit-Event` + `Delete-Tag(old)`. |
| `Dismiss-Issues(project_id, …)` | Dismissing data quality issues | Per-issue, confirm each |
| `Run-Query` | Custom Insights queries (volume rank, deep dives) | Falls back to `Get-Query-Schema` retry once on failure |

---

## Tag operation semantics — read this carefully

The `tags` field on `Bulk-Edit-Events` takes an `operation`:

| Operation | Effect | Use for |
|---|---|---|
| `add` | Adds the listed tags to existing tags on each event | **Default for `enrich-and-tag`.** Do NOT clobber tags added manually. |
| `set` | Replaces existing tags entirely | Only `reset-lexicon` (when clearing tags by passing `names: []`). |

**Do not use `set` in `enrich-and-tag`.** Use `add` even if `existing_tags` is empty for an event — the semantics are correct.

---

## Resource type splitting

`Bulk-Edit-Properties` is single-resource-type per call. To enrich both Event and User properties:

```
Bulk-Edit-Properties(project_id, resource_type: "Event", properties: [...])
Bulk-Edit-Properties(project_id, resource_type: "User", properties: [...])
```

Same for `Get-Properties`. There is no combined call.

---

## Failure handling

| Failure | Action |
|---|---|
| `Get-Projects` tool-not-found | Tell user to connect Mixpanel MCP, stop. |
| `Run-Query` error | Call `Get-Query-Schema`, retry once. If still fails: log, proceed with empty data; downstream degrades gracefully. |
| `Bulk-Edit-*` chunk error | Fall back to per-entity `Edit-*` for that chunk only. Log, continue with the next chunk. |
| `Rename-Tag` error (likely merge) | Fall back to per-event `Edit-Event(tags: { names: [new, …existing-minus-old], operation: "set" })` in batches of 10, then `Delete-Tag(old)`. |
| Any non-fatal write failure | Log entity name + error. Continue. Surface in the final summary. |
| Non-fatal read failure | Log, proceed with empty data; surface in the report. |

---

## Progress reporting format

For any batched operation, emit one line per chunk:

```
✅ Events: 50/112 metadata updated...
✅ Tags: group 2/5 applied (Commerce → 18 events)...
✅ Properties: 50/120 metadata updated...
```

No other narration during the loop.
