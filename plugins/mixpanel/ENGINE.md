# Mixpanel plugin — engine guide

This plugin gives AI agents Mixpanel expertise: skills for analytics, dashboards, experiments, feature flags, lexicon, and tracking implementation. The skills describe Mixpanel actions in plain language ("list the projects", "run the query", "create the board") — **how** an action executes depends on the **engine** the project has installed.

## How skills work

Detect the engine once per session (first match wins, cache the result), then perform every Mixpanel action through it. If none is detected, stop and direct the user to run `/mixpanel:install` — never guess, never hand-build an API call. When more than one engine is available, prefer MCP unless the user says otherwise.

## Engines

1. **Mixpanel MCP server** — detected when a Mixpanel MCP server is connected in this session (its tools are listed, or it's registered in the client's MCP config, e.g. the project's `.mcp.json`). Region comes from the server URL: `mcp.mixpanel.com` → US, `mcp-eu.mixpanel.com` → EU, `mcp-in.mixpanel.com` → India. Perform each action with the server tool whose description matches it; if no tool fits, say so. Setup and docs: [`skills/install/references/mcp-setup.md`](skills/install/references/mcp-setup.md).
2. **mixpanel-headless SDK** — detected when `mixpanel-headless` is importable in the project's Python (`python3 -c "import mixpanel_headless"` succeeds). Perform actions as Python calls; the SDK is self-documenting (`mp --help`, docstrings on every method) and auth comes from its service-account environment variables. On `ImportError` or auth failure, stop and direct the user to `/mixpanel:install`. Setup and docs: [`skills/install/references/headless-setup.md`](skills/install/references/headless-setup.md).
3. **Custom integration** — detected when the user (or the project's own agent instructions, e.g. `CLAUDE.md` / `AGENTS.md`) describes their own way to reach Mixpanel. Follow those instructions as the engine; assume the context they provide is sufficient — don't interrogate.

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
