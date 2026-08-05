# Engine resolution — one convention for every skill in this plugin

Skills in this plugin describe _what_ to do against Mixpanel, never _how_ to reach it. The "how" — the **engine** — is set up once per project with `/mixpanel:install`. There is **no config file**: the installation itself is the memory, and skills detect it (a registered Mixpanel MCP server, or an installed `mixpanel-headless` SDK). Every skill carries a short inline preamble with the resolution steps; this file holds the shared detail: the detection rules, the per-engine execution rules, and the capability map.

A skill's only mode concern is **interactive vs non-interactive** (can it ask the user questions right now?). Engine differences end at capability resolution.

## Skill tag convention (CI-enforced)

Every SKILL.md in this plugin declares whether it needs an engine, in frontmatter (the `metadata` field is part of the Agent Skills spec):

```yaml
metadata:
  engine: required   # or: optional | none
```

- `required` — the core flow queries or writes Mixpanel data; no engine → stop.
- `optional` — the core flow works without an engine; engine-enhanced steps use it when one is detected and fall back gracefully when not (never stop).
- `none` — the skill never touches live Mixpanel data.

The tag is always explicit — omitting it fails CI, so a forgotten tag can never be mistaken for a deliberate `none`.

When `required` (or `optional`), the body must also carry a one-line pointer right under the title — frontmatter metadata is never loaded into model context, so the body line is what the model actually follows:

```markdown
> **Engine required** — resolve per [`ENGINE.md`](../../ENGINE.md) before any Mixpanel action; if none is detected, stop and run `/mixpanel:install`.
```

Skills may append short skill-specific notes to that line (e.g. monitor-metrics adds its `cap:*` rule). `scripts/check-engine-markers.sh` enforces both in CI — a skill without the tag fails, so a new skill can't ship without deciding, and an engine skill whose body forgets the pointer fails too.

---

## Resolution algorithm (detection, not configuration)

Do this **once per session**, before any skill's Step 0, and cache the result:

1. **MCP server connected?** If a Mixpanel MCP server is visible in this session (its tools are listed, or it is registered in the client's MCP config, e.g. the project's `.mcp.json`), the engine is **`mcp`**. The **region** comes from the server's URL: `mcp.mixpanel.com` → US, `mcp-eu.mixpanel.com` → EU, `mcp-in.mixpanel.com` → India.
2. **Headless SDK installed?** Otherwise, if `mixpanel-headless` is importable in the project's Python environment (`python3 -c "import mixpanel_headless"` succeeds), the engine is **`headless`**. Auth and region come from the SDK's own configuration (service-account environment variables — see the SDK docs).
3. Otherwise **STOP**. Tell the user Mixpanel isn't set up for this project and direct them to run `/mixpanel:install`. Never guess an engine, never hardcode a tool name or hand-build an API call to work around a missing setup.

If both are present, prefer `mcp` unless the user says otherwise.

## Execution rules per engine

### `mcp`

Build a **session tool map** once: enumerate the detected Mixpanel MCP server's tools in a single pass (tool search or the client's tool listing), then match each capability key below to a live tool **by what the tool does** (description and parameters), not by exact name — the "MCP hint" column is advisory only, names change. Cache the map for the session. If a required capability has no matching tool, stop and tell the user which capability is missing rather than guessing. Resolve only against the detected Mixpanel server — never another Mixpanel connector.

### `headless`

Capabilities resolve to Python calls against the [`mixpanel-headless`](https://docs.mixpanel.com/docs/mixpanel-headless) SDK, executed via the shell using the project's Python environment. Introspect the SDK surface once per session (e.g. `python3 -c "import mixpanel_headless; help(...)"` or the package's own discovery affordances) and map capability keys to SDK calls. On `ImportError` or an auth failure, stop and direct the user to `/mixpanel:install`. Prefer the live docs over any bundled notes if they conflict.

## Capability map

Skills refer to actions by `cap:*` keys — never literal tool names. Hints are last-known names, advisory only.

| Capability key | Action it performs | MCP hint | Headless hint |
| --- | --- | --- | --- |
| `cap:business-context` | Fetch org vocabulary / business context (project nicknames, acronyms, conventions) | `Get-Business-Context` | SDK context/metadata accessor |
| `cap:update-business-context` | Update org/project business context | `Update-Business-Context` | SDK context/metadata writer |
| `cap:list-projects` | List projects the user can access; resolve project id ↔ name | `Get-Projects` | SDK project listing |
| `cap:list-organizations` | List organizations the user belongs to | `List-Organizations` | SDK org listing |
| `cap:find-metrics` | Search saved Metrics by name/query | `List-Metrics` | SDK metrics listing |
| `cap:get-metric` | Fetch a saved Metric's full, replayable definition | `Get-Metric` | SDK metric accessor |
| `cap:save-metric` | Create or update a saved Metric | `Create-Metric` / `Update-Metric` | SDK metric writer |
| `cap:get-report` | Fetch a saved report's metadata + native-granularity results | `Get-Report` | SDK report accessor |
| `cap:get-dashboard` | Fetch a dashboard incl. layout / report cells | `Get-Dashboard` | SDK board accessor |
| `cap:list-dashboards` | List dashboards/boards | `List-Dashboards` | SDK board listing |
| `cap:create-board` | Create a dashboard/board with report + text cells | `Create-Dashboard` | SDK board writer |
| `cap:update-board` | Append cells to an existing board without disturbing layout | `Update-Dashboard` | SDK board writer |
| `cap:delete-board` | Delete or duplicate a board | `Delete-Dashboard` / `Duplicate-Dashboard` | SDK board writer |
| `cap:search-entities` | Search saved entities (boards, insights, funnels, retention, flows) by name | `Search-Entities` | SDK entity search |
| `cap:query-schema` | Fetch the query schema for a report type (insights/funnels/retention/flows) | `Get-Query-Schema` | SDK query-builder docs/introspection |
| `cap:run-query` | Execute a time-series / segmentation / funnels query and return results | `Run-Query` | SDK query engine |
| `cap:list-events` | List events with metadata (volume, description) | `Get-Events` | SDK lexicon/event listing |
| `cap:list-properties` | Confirm a property exists on an event/user resource | `List-Properties` | SDK property listing |
| `cap:property-values` | Return distinct values for a property | `Get-Property-Values` | SDK property values |
| `cap:edit-metadata` | Edit event/property metadata (descriptions, tags, hidden/dropped state), single or bulk | `Edit-Event` / `Edit-Property` / `Bulk-Edit-Events` / `Bulk-Edit-Properties` | SDK lexicon writer |
| `cap:manage-tags` | Create / rename / delete Lexicon tags | `Create-Tag` / `Rename-Tag` / `Delete-Tag` | SDK tag management |
| `cap:data-issues` | Return instrumentation/data-quality issues for events in a window | `Get-Issues` | SDK data-quality accessor |
| `cap:manage-cohorts` | List / get / create / update / delete cohorts | `List-Cohorts` / `Get-Cohort` / `Create-Cohort` / `Update-Cohort` | SDK cohort management |
| `cap:manage-experiments` | List / get / create / update experiments; pre-launch checks; results guidance | `List-Experiments` / `Get-Experiment` / `Create-Experiment` / `Update-Experiment` | SDK experiment management |
| `cap:manage-flags` | List / get / create / update feature flags | `List-Feature-Flags` / `Get-Feature-Flag` / `Create-Feature-Flag` / `Update-Feature-Flag` | SDK flag management |
| `cap:session-replays` | Fetch session replay data for given distinct_ids and window | `Get-User-Replays-Data` | SDK replay accessor |
| `web-search` | External web search (not a Mixpanel capability) | runtime-provided | runtime-provided |

When a skill says "run the query via `cap:run-query`", it means: perform that action through whatever this session's engine resolved the capability to. If you find yourself typing a literal Mixpanel tool name or hand-built API call into a plan, stop and resolve the capability instead.
