# Mixpanel plugin — engine guide

This plugin gives AI agents Mixpanel expertise: skills for analytics, dashboards, experiments, feature flags, lexicon, and tracking implementation. The skills describe Mixpanel actions in plain language ("list the projects", "run the query", "create the board") — **how** an action executes depends on the **engine** the project has installed.

## How skills work

When the user or their loaded instructions (`CLAUDE.md` / `AGENTS.md`) explicitly name an engine, skills use it directly — no availability checks first. Otherwise skills use the **Mixpanel MCP server** — the default, available whenever its tools are listed in the session, no matter where it was configured (project or user scope). If it's not available, never guess and never hand-build an API call — offer to run `/mixpanel:install`, which detects what's installed and negotiates the alternatives. Resolve once per session and stick with the result.

## Engines

1. **Mixpanel MCP server** — detected when its tools are listed in the current session; the config location (project or user scope) doesn't matter. Region comes from the server URL: `mcp.mixpanel.com` → US, `mcp-eu.mixpanel.com` → EU, `mcp-in.mixpanel.com` → India. Perform each action with the server tool whose description matches it; if no tool fits, say so. Setup and docs: [`skills/install/references/mcp-setup.md`](skills/install/references/mcp-setup.md).
2. **mixpanel-headless SDK** — used when the user's instructions ask for it (e.g. "for Mixpanel use headless") or when chosen through the install skill; installed if `mp --version` succeeds. Perform actions as Python calls or `mp` CLI commands; the SDK ships its own agent instructions (`mixpanel_headless/CLAUDE.md` in the installed package) and is self-documenting (`mp --help`, docstrings on every method); auth is set up with `mp login`. On `ImportError` or auth failure, stop and ask the user whether to run `/mixpanel:install`. Setup and docs: [`skills/install/references/headless-setup.md`](skills/install/references/headless-setup.md).
3. **Custom integration** — used when the user (or the project's own agent instructions, e.g. `CLAUDE.md` / `AGENTS.md`) describes their own way to reach Mixpanel. Follow those instructions as the engine; assume the context they provide is sufficient — don't interrogate.

## Engine preference

A preference is one plain instruction line — e.g. `For Mixpanel, use the headless SDK.` — that future sessions read automatically. Where it lives:

- **Project level**: the project's `CLAUDE.md` (Claude Code) or `AGENTS.md` (Cursor) — append to whichever the project already has.
- **User level**: `~/.claude/CLAUDE.md` (Claude Code); in Cursor there is no user-level file — the user adds a User Rule under Settings → Rules.

Always ask before writing to any of these files. The install skill offers to leave this note whenever the user picks a non-default engine, so they don't have to specify it each time.

## Skill tag (CI-enforced)

Every SKILL.md declares in frontmatter whether it needs an engine:

```yaml
metadata:
  engine: required # or: optional | none
```

- `required` — the core flow queries or writes Mixpanel data; no engine → stop.
- `optional` — works without an engine; uses one when detected; never stops for a missing engine.
- `none` — never touches live Mixpanel data.

`required` and `optional` skills also carry a one-line marker right under the title (frontmatter metadata is never loaded into model context, so the body line is what the model actually follows):

```markdown
> **Engine required** — unless explicitly told otherwise (then just use the named engine — no availability checks), use the Mixpanel MCP server; if it's not available, offer to run `/mixpanel:install`.
```

`scripts/check-engine-markers.sh` enforces both in CI.
