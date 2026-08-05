# Engine resolution — one convention for every skill in this plugin

Skills in this plugin are **engine-agnostic**: they describe *what* to do against
Mixpanel, never *how* to reach it. The "how" — the **engine** — is chosen once per
project with `/mixpanel:install` and persisted in `.claude/mixpanel.json`. Every
skill carries a short inline preamble with the resolution steps; this file holds
the shared detail: the config schema, the per-engine execution rules, and the
capability map.

A skill's only mode concern is **interactive vs non-interactive** (can it ask the
user questions right now?). Engine differences end at capability resolution.

## Skill marker convention (CI-enforced)

Every SKILL.md in this plugin must declare its engine dependency with exactly
one of these markers in the first 40 lines (right under the title):

```markdown
> **Requires a Mixpanel engine.** Resolve it per [`ENGINE.md`](../../ENGINE.md) before any Mixpanel action — if none is configured, stop and direct the user to `/mixpanel:install`.
```

or, for skills that never touch Mixpanel data:

```markdown
> **No Mixpanel engine required.**
```

Skills may append short skill-specific notes to the marker line (e.g.
monitor-metrics adds its `cap:*` rule). `scripts/check-engine-markers.sh`
enforces this in CI — a skill with neither marker fails, so a new skill can't
ship without engine resolution.

---

## Config file: `.claude/mixpanel.json`

Lives at the root of the user's project. Written by `/mixpanel:install`. Safe to
commit — it never contains credentials (those live in the MCP server's auth or in
environment variables).

```json
{
  "version": 1,
  "engine": "mcp",
  "region": "us",
  "mcp": { "serverName": "mixpanel", "scope": "project", "url": "https://mcp.mixpanel.com/mcp" },
  "headless": { "python": "python3", "package": "mixpanel-headless" },
  "custom": { "instructions": "" }
}
```

- Required: `version` (currently `1`), `engine` (`"mcp"` | `"headless"` | `"custom"`),
  `region` (`"us"` | `"eu"` | `"in"`), plus the block matching the chosen engine.
- Region → MCP URL map: `us` → `https://mcp.mixpanel.com/mcp`,
  `eu` → `https://mcp-eu.mixpanel.com/mcp`, `in` → `https://mcp-in.mixpanel.com/mcp`.

## Resolution algorithm

Do this **once per session**, before any skill's Step 0, and cache the result:

1. Read `.claude/mixpanel.json` from the project root.
2. **Present and valid** → use its `engine`. Done.
3. **Missing or unparseable** → if a Mixpanel MCP server is visibly connected in
   this session (its tools are listed), use `engine: mcp` for now and offer to
   persist that choice to `.claude/mixpanel.json`.
4. Otherwise **STOP**. Tell the user Mixpanel isn't configured for this project
   and direct them to run `/mixpanel:install`. Never guess an engine, never
   hardcode a tool name or URL to work around a missing config.

## Execution rules per engine

### `mcp`

Build a **session tool map** once: enumerate the configured Mixpanel MCP server's
tools in a single pass (tool search or the client's tool listing), then match each
capability key below to a live tool **by what the tool does** (description and
parameters), not by exact name — the "MCP hint" column is advisory only, names
change. Cache the map for the session. If a required capability has no matching
tool, stop and tell the user which capability is missing rather than guessing.
Resolve only against the server named in `mcp.serverName` — never another
Mixpanel connector.

### `headless`

Capabilities resolve to Python calls against the
[`mixpanel-headless`](https://docs.mixpanel.com/docs/mixpanel-headless) SDK,
executed via the shell (`headless.python` from config). Introspect the SDK
surface once per session (e.g. `python3 -c "import mixpanel_headless; help(...)"`
or the package's own discovery affordances) and map capability keys to SDK
calls. On `ImportError` or an auth failure, stop and direct the user to
`/mixpanel:install`. Prefer the live docs over any bundled notes if they
conflict.

### `custom`

The user brought their own integration. Follow `custom.instructions` from the
config verbatim; it describes how to perform Mixpanel actions in this project.
If an action can't be expressed through those instructions, say so — don't fall
back to another engine without asking.

## Capability map

Skills refer to actions by `cap:*` keys — never literal tool names. Hints are
last-known names, advisory only.

| Capability key | Action it performs | MCP hint | Headless hint |
|---|---|---|---|
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

When a skill says "run the query via `cap:run-query`", it means: perform that
action through whatever this session's engine resolved the capability to. If you
find yourself typing a literal Mixpanel tool name or hand-built API call into a
plan, stop and resolve the capability instead.
