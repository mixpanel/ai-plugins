# Mixpanel Skills

A collection of Agent Skills for building with Mixpanel — covering event tracking, tracking plan design, Lexicon data governance, and product analytics queries.

Works with Claude Code, Cursor, and any agent platform that supports the skills format.

## Skills

Skills are contextual and auto-loaded based on your conversation:

| Skill | Description |
|-------|-------------|
| `mixpanel` | Core platform guidance: events, identity, SDKs, properties |
| `tracking-plan` | Designing and implementing tracking plans |
| `implement` | Adding Mixpanel tracking to a codebase — spec, SDK code, verification, Lexicon docs |
| `analysis` | Querying data: Insights, Funnels, Flows, Retention, Dashboards |
| `data-governance` | Lexicon management: descriptions, owners, tags, stale events |
| `pii-review` | Scanning event and user properties for PII |
| `issue-triage` | Triaging and resolving data quality issues |

## Commands

User-invocable slash commands:

| Command | Description |
|---------|-------------|
| `/mixpanel:audit-tracking` | Audit existing Mixpanel instrumentation in a codebase |
| `/mixpanel:design-tracking-plan` | Design a tracking plan for a feature or product area |
| `/mixpanel:top-users` | Find the top users for an event over a given time period |

## MCP Server

The Mixpanel MCP server gives agents live access to your Mixpanel project: querying events, running reports, managing Lexicon, and more.

**Regions** — use the server closest to your Mixpanel project's data residency:

| Region | URL |
|--------|-----|
| US (default) | `https://mcp.mixpanel.com/mcp` |
| EU | `https://mcp-eu.mixpanel.com/mcp` |
| India | `https://mcp-in.mixpanel.com/mcp` |

See [Installation](#installation) for how to configure your region.

## Installation

### Claude Code

Install from the Claude Code plugin marketplace, or manually:

```bash
# US (default)
claude mcp add mixpanel --transport http https://mcp.mixpanel.com/mcp

# EU
claude mcp add mixpanel --transport http https://mcp-eu.mixpanel.com/mcp

# India
claude mcp add mixpanel --transport http https://mcp-in.mixpanel.com/mcp
```

### Cursor

Install from the Cursor Marketplace, or add to your `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "mixpanel": {
      "type": "http",
      "url": "https://mcp.mixpanel.com/mcp"
    }
  }
}
```

Replace the URL with your region's endpoint if needed.

### Manual

Clone this repo and copy the `skills/` folders to your agent's skills directory.
