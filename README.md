# Mixpanel AI Plugins

Plugins that give AI agents Mixpanel expertise. Built on the [Agent Skills](https://agentskills.io) open standard.

## Skills

| Skill | Description |
|---|---|
| [`tracking-implementation`](plugins/mixpanel-mcp/skills/tracking-implementation/) | Guides an agent through Mixpanel analytics implementation. Supports Quick Start, Full Implementation, Add Tracking, and Audit modes. |
| [`create-dashboard`](plugins/mixpanel-mcp/skills/create-dashboard/) | Creates a well-designed Mixpanel dashboard with validated data, text cards, and narrative layout. |
| [`deep-research`](plugins/mixpanel-mcp/skills/deep-research/) | Conducts a structured metric investigation in Mixpanel. Use when a user asks *why* a metric changed, what's driving a trend, or requests a deep dive or root cause analysis. |

## Getting Started

### Claude Code

1. Add the Mixpanel marketplace, then install the plugin for your region:

```bash
claude plugin marketplace add mixpanel/ai-plugins
```

2. Install the plugin for your region:

**US**
```bash
claude plugin install mixpanel-mcp
```

**EU**
```bash
claude plugin install mixpanel-mcp-eu
```

**India**
```bash
claude plugin install mixpanel-mcp-in
```


### Cursor

Install the plugin from the Cursor marketplace, or have a team admin import this GitHub repository as a team marketplace (Dashboard → Settings → Plugins → Import).

Once installed, skills appear in **Cursor Settings → Rules** under the **Agent Decides** section and can be invoked with `/skill-name` in chat. The MCP server connects automatically.

## Contributing

To propose a plugin, open a pull request — we prefer **one plugin per PR** so reviews stay focused, and we'll merge them as they're ready rather than batching.

### Before opening the PR

1. Each skill lives in its own directory under `skills/` and must contain a `SKILL.md` with valid `name` and `description` frontmatter.
2. Follow the [Agent Skills specification](https://agentskills.io/specification) and [best practices](https://agentskills.io/skill-creation/best-practices).
3. Keep the main file under 500 lines — move detailed reference material to `references/`.
4. **Test the plugin end-to-end** before submission — confirm it triggers on the expected prompts and produces the output you expect.
5. **Include examples in the PR description** showing prompts the plugin handles and what it returns.

## License

Apache 2.0 — see [LICENSE](LICENSE).
