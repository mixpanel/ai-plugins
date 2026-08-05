# Mixpanel engine — how skills reach Mixpanel

Skills in this plugin describe Mixpanel actions in plain language ("list the projects", "run the query", "create the board"). How an action executes depends on which **engine** is installed. Detect it once per session and cache the result:

1. **MCP server** — a Mixpanel MCP server is connected in this session (its tools are listed, or it's registered in the client's MCP config, e.g. the project's `.mcp.json`). Region comes from the server URL: `mcp.mixpanel.com` → US, `mcp-eu.mixpanel.com` → EU, `mcp-in.mixpanel.com` → India. Perform each action with the server tool whose description matches it. If no tool fits an action, say so — don't hand-build an API call.
2. **Headless SDK** — otherwise, if `mixpanel-headless` is importable in the project's Python (`python3 -c "import mixpanel_headless"` succeeds). Perform actions as Python calls following the [SDK docs](https://docs.mixpanel.com/docs/mixpanel-headless); the SDK is self-documenting (`mp --help`, docstrings on every method) and auth comes from its service-account environment variables. On `ImportError` or auth failure, stop and direct the user to `/mixpanel:install`.
3. **Custom integration** — otherwise, if the user (or the project's own agent instructions, e.g. `CLAUDE.md` / `AGENTS.md`) describes their own way to reach Mixpanel, follow those instructions as the engine. Assume the context they provide is sufficient — don't interrogate.
4. **None of the above** — stop. Tell the user Mixpanel isn't set up for this project and direct them to run `/mixpanel:install`. Never guess.

If more than one is available, prefer MCP unless the user says otherwise.

## Skill tag (CI-enforced)

Every SKILL.md declares in frontmatter whether it needs an engine:

```yaml
metadata:
  engine: required # or: optional | none
```

- `required` — the core flow queries or writes Mixpanel data; no engine → stop.
- `optional` — works without an engine; uses one when detected; never stops for a missing engine.
- `none` — never touches live Mixpanel data.

`required` and `optional` skills also carry a one-line pointer right under the title (frontmatter metadata is never loaded into model context, so the body line is what the model actually follows):

```markdown
> **Engine required** — resolve per [`ENGINE.md`](../../ENGINE.md) before any Mixpanel action; if none is detected, stop and run `/mixpanel:install`.
```

`scripts/check-engine-markers.sh` enforces both in CI.
