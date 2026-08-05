# Mixpanel MCP server setup

Source: **https://docs.mixpanel.com/docs/mcp** (per-client connection instructions, regional URLs, OAuth and service-account auth, available tools, rate limits).

## Regional URLs

Use the URL for the region the user chose (same map as [`../../../ENGINE.md`](../../../ENGINE.md)):

| Region | URL                               |
| ------ | --------------------------------- |
| US     | `https://mcp.mixpanel.com/mcp`    |
| EU     | `https://mcp-eu.mixpanel.com/mcp` |
| India  | `https://mcp-in.mixpanel.com/mcp` |

If the user is unsure of their region, their Mixpanel web address tells them: `eu.mixpanel.com` → EU, `in.mixpanel.com` → India, otherwise US.

Substitute the chosen URL for `<url>` in every recipe below, and walk the user through the steps — run the commands for them where the client allows it, and confirm each step succeeded before moving on.

## Claude Code

Native HTTP transport (preferred):

```bash
claude mcp add --transport http mixpanel <url> --scope project
```

This stores the server in `.mcp.json` in the repo, shareable with the team. (Only if the user explicitly wants it available across all their projects, use `--scope user` instead.)

Fallback for clients/environments where native HTTP + OAuth doesn't work — stdio via mcp-remote:

```bash
claude mcp add mixpanel --scope project -- npx -y mcp-remote <url>
```

After adding: authentication is OAuth — the user completes it via `/mcp` (select the `mixpanel` server, follow the browser flow). Then verify the server's tools are listed.

## Cursor

Add to `.cursor/mcp.json` in the project (create the file if missing):

```json
{
  "mcpServers": {
    "mixpanel": {
      "url": "<url>"
    }
  }
}
```

Cursor handles the OAuth flow when the server is first used.

## Other clients

Point the user at https://docs.mixpanel.com/docs/mcp — it documents connection steps for Claude (web/desktop), ChatGPT, Notion, and others, plus service-account auth (beta) for non-interactive/CI use.

## Verify

List the Mixpanel server's tools. A healthy connection exposes 50+ tools (queries, dashboards, cohorts, experiments, flags, lexicon). If the listing is empty or errors:

- OAuth not completed → finish the flow (`/mcp` in Claude Code) and retry.
- Wrong region → the server connects but the user's projects are missing; re-add with the correct URL.
- Corporate network/proxy issues → try the mcp-remote stdio fallback.
