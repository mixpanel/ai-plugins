# Mixpanel AI Plugins

Plugins that give AI agents Mixpanel expertise. Built on the [Agent Skills](https://agentskills.io) open standard.

## Skills

| Skill | Description |
|---|---|
| [`tracking-implementation`](plugins/mixpanel-mcp/skills/tracking-implementation/) | Guides an agent through Mixpanel analytics implementation. Supports Quick Start, Full Implementation, Add Tracking, and Audit modes. |
| [`create-dashboard`](plugins/mixpanel-mcp/skills/create-dashboard/) | Creates a well-designed Mixpanel dashboard with validated data, text cards, and narrative layout. |
| [`deep-research`](plugins/mixpanel-mcp/skills/deep-research/) | Conducts a structured metric investigation in Mixpanel. Use when a user asks *why* a metric changed, what's driving a trend, or requests a deep dive or root cause analysis. |

## Prerequisites

The **deep-research** and **create-dashboard** skills require the [Mixpanel MCP server](https://docs.mixpanel.com/docs/mcp) to be connected and authenticated. Before using these skills:

1. An org admin must enable MCP in your Mixpanel organization (Settings → Organization Settings → Overview).
2. Connect the Mixpanel MCP server in your AI tool (see setup instructions below).

The **tracking-implementation** skill works without the MCP server.

## Getting Started

### Claude Code

Add the Mixpanel marketplace and install the plugin:

```bash
claude plugin marketplace add mixpanel/ai-plugins
claude plugin install mixpanel-mcp
```

This installs all three skills. Type `/` in Claude Code to see them listed.

To connect the Mixpanel MCP server (required for deep-research and create-dashboard):

```bash
claude mcp add mixpanel -- npx -y mcp-remote https://mcp.mixpanel.com/mcp
```

You will be prompted to authenticate with your Mixpanel credentials on first use.

<details>
<summary>Regional endpoints</summary>

| Region | Endpoint |
|---|---|
| US (default) | `https://mcp.mixpanel.com/mcp` |
| EU | `https://mcp-eu.mixpanel.com/mcp` |
| IN | `https://mcp-in.mixpanel.com/mcp` |

</details>

### Cursor

Install the plugin from the Cursor marketplace or have a team admin import this GitHub repository as a team marketplace (Dashboard → Settings → Plugins → Import).

Once installed, skills appear in **Cursor Settings → Rules** under the **Agent Decides** section and can be invoked with `/skill-name` in chat.

To connect the Mixpanel MCP server (required for deep-research and create-dashboard), add the following to `.cursor/mcp.json` in your project root (create the file if it doesn't exist):

```json
{
  "mcpServers": {
    "mixpanel": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://mcp.mixpanel.com/mcp"]
    }
  }
}
```

Replace the URL with your [regional endpoint](#regional-endpoints) if needed.

Restart Cursor for the MCP server to connect. You will be prompted to authenticate with your Mixpanel credentials on first use.

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
