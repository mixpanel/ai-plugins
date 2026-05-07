# Mixpanel AI Plugins

Plugins that give AI agents Mixpanel expertise. Built on the [Agent Skills](https://agentskills.io) open standard.

## Skills

| Skill | Description |
|---|---|
| [`tracking-implementation`](skills/tracking-implementation/) | Guides an agent through Mixpanel analytics implementation. Supports Quick Start, Full Implementation, Add Tracking, and Audit modes. |
| [`create-dashboard`](skills/create-dashboard/) | Creates a well-designed Mixpanel dashboard with validated data, text cards, and narrative layout. |
| [`deep-research`](skills/deep-research/) | Conducts a structured metric investigation in Mixpanel. Use when a user asks *why* a metric changed, what's driving a trend, or requests a deep dive or root cause analysis. |

## Getting Started

Add the Mixpanel marketplace and install the plugin:

```bash
claude plugin marketplace add mixpanel/ai-plugins
claude plugin install mixpanel-mcp
```

## Contributing

To propose a plugin, open a pull request — we prefer **one plugin per PR** so reviews stay focused, and we'll merge them as they're ready rather than batching.

Before opening the PR:

1. Each skill lives in its own directory under `skills/` and must contain a `SKILL.md` with valid `name` and `description` frontmatter.
2. Follow the [Agent Skills specification](https://agentskills.io/specification) and [best practices](https://agentskills.io/skill-creation/best-practices).
3. Keep the main file under 500 lines — move detailed reference material to `references/`.
4. **Test the plugin end-to-end** before submission — confirm it triggers on the expected prompts and produces the output you expect.
5. **Include examples in the PR description** showing prompts the plugin handles and what it returns.

## License

Apache 2.0 — see [LICENSE](LICENSE).
