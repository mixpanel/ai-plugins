# Tool resolution — capabilities, not hardcoded names

MCP tool names change. This skill **never** hardcodes a Mixpanel tool name in
its logic. Instead it refers to **capabilities** (what an action does) and
resolves each one to the live tool name at runtime, against the tools the
connected Mixpanel connector actually exposes right now.

Every `cap:*` token used anywhere in this skill (SKILL.md, execution.md, and
the command files) is a capability key defined in the map below — not a literal
tool name. Resolve it to a real tool via the session tool map before calling.

> **Connector scope:** this skill operates exclusively against this plugin's Mixpanel
> connector (whichever region the plugin is configured for). Resolve every
> capability against that connector's tools only — never another Mixpanel
> connector.

---

## Step −1 — Build the session tool map (once per session)

Do this **once**, before Step 0, and cache the result for the whole session:

1. **Enumerate the Mixpanel connector's tools once.** List every tool this
   plugin's Mixpanel connector currently exposes (e.g. via a tool search over that
   connector, or the client's tool listing). Do this in a single pass — do not
   search per call site. This gives the skill the latest, authoritative tool
   names in one shot.
2. **Match each capability below to a live tool** by what the tool does (its
   description and parameters), not by an exact name match. The "last-known
   name" column is only a hint to speed matching — treat it as advisory. If a
   name has changed but a tool clearly performs the capability's action, use it.
3. **Cache the capability → tool-name map** in conversation memory for the
   session. Every later step calls the mapped tool for that `cap:*` key.
4. **If a required capability has no matching tool**, stop and tell the user
   which capability is missing (e.g. "this connector exposes no query-execution
   tool") rather than guessing a name.

`web-search` is **not** a Mixpanel capability — resolve it to whatever web
search the runtime provides (skip gracefully if none, per `metric-rca.md`).

---

## Capability map

| Capability key | Action it performs | Last-known tool name (hint only) |
|---|---|---|
| `cap:business-context` | Fetch org vocabulary / business context (project nicknames, acronyms, query conventions) | `Get-Business-Context` |
| `cap:list-projects` | List projects the user can access; resolve project id ↔ name | `Get-Projects` |
| `cap:find-metrics` | Search saved Metrics by name/query | `List-Metrics` |
| `cap:get-metric` | Fetch a saved Metric's full, replayable definition | `Get-Metric` |
| `cap:get-report` | Fetch a saved report's metadata + native-granularity results (no replayable query body) | `Get-Report` |
| `cap:get-dashboard` | Fetch a dashboard incl. layout / report cells | `Get-Dashboard` |
| `cap:search-entities` | Search saved entities (dashboards, insights, funnels, retention, flows) by name | `Search-Entities` |
| `cap:query-schema` | Fetch the query schema for a report type (insights/funnels/retention/flows) | `Get-Query-Schema` |
| `cap:run-query` | Execute a time-series / segmentation / funnels query and return results | `Run-Query` |
| `cap:list-properties` | Confirm a property exists on an event/user resource | `List-Properties` |
| `cap:property-values` | Return distinct values for a property | `Get-Property-Values` |
| `cap:data-issues` | Return instrumentation/data-quality issues for events in a window | `Get-Issues` |
| `cap:create-board` | Create a dashboard/board with report + text cells | `Create-Dashboard` |
| `cap:update-board` | Append cells to an existing board without disturbing layout | `Update-Dashboard` |
| `cap:session-replays` | Fetch session replay data for given distinct_ids and window | `Get-User-Replays-Data` |
| `web-search` | External web search (not a Mixpanel connector tool) | runtime-provided |

When any file says, e.g., "run the query via `cap:run-query`", it means: call
whatever tool this session's map resolved `cap:run-query` to. If you find
yourself typing a literal Mixpanel tool name into a call plan, stop and resolve
the capability instead.
