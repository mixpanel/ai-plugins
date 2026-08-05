# Mixpanel MCP server setup

Source: **https://docs.mixpanel.com/docs/mcp** (per-client connection
instructions, regional URLs, OAuth and service-account auth, available tools,
rate limits).

The region → URL map lives in [`../../../ENGINE.md`](../../../ENGINE.md); use
the URL for the region the user chose.

## Claude Code

Native HTTP transport (preferred):

```bash
# project scope — stored in .mcp.json in the repo, shareable with the team
claude mcp add --transport http mixpanel <url> --scope project

# user scope — available in all the user's projects
claude mcp add --transport http mixpanel <url> --scope user
```

Fallback for clients/environments where native HTTP + OAuth doesn't work —
stdio via mcp-remote:

```bash
claude mcp add mixpanel --scope project -- npx -y mcp-remote <url>
```

After adding: authentication is OAuth — the user completes it via `/mcp`
(select the `mixpanel` server, follow the browser flow). Then verify the
server's tools are listed.

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

Cursor handles the OAuth flow when the server is first used. For user-wide
setup, use Cursor's global MCP settings instead of the project file.

## Other clients

Point the user at https://docs.mixpanel.com/docs/mcp — it documents
connection steps for Claude (web/desktop), ChatGPT, Notion, and others, plus
service-account auth (beta) for non-interactive/CI use.

## Verify

List the Mixpanel server's tools. A healthy connection exposes 50+ tools
(queries, dashboards, cohorts, experiments, flags, lexicon). If the listing is
empty or errors:
- OAuth not completed → finish the flow (`/mcp` in Claude Code) and retry.
- Wrong region → the server connects but the user's projects are missing;
  re-add with the correct URL.
- Corporate network/proxy issues → try the mcp-remote stdio fallback.
