# Optional coding-agent setup

Use this checkpoint once, at the very start of `tracking-implementation`. Its purpose is to help the user add two optional coding-agent capabilities before implementation begins:

- **Mixpanel plugin** -- gives the coding agent the full set of Mixpanel skills, including implementation, analysis, dashboards, experiments, and governance workflows.
- **Mixpanel MCP server** -- lets the coding agent access the Mixpanel projects the user can access, subject to the user's Mixpanel permissions.

Neither is the Mixpanel application SDK. Neither is required to add tracking code. Do not make setup a prerequisite.

## 1. Detect existing setup

Use read-only checks where the client supports them.

### Plugin

Treat the plugin as installed when the current client exposes the `mixpanel` plugin or its namespaced skills. Invocation as `/mixpanel:tracking-implementation` is also sufficient evidence. A pasted or externally supplied copy of this skill is not evidence that the plugin is installed.

If plugin state cannot be determined safely, call it "not confirmed" rather than claiming it is missing.

### MCP

Treat MCP as connected when Mixpanel MCP tools are available in the current session. If the client exposes its MCP configuration through a read-only command or UI, that may also be checked. A configuration entry without usable tools is not a completed setup; it may still need OAuth or a client reload.

When both are already available, tell the user briefly and continue to the codebase scan without presenting a setup choice.

## 2. Make one optional offer

Offer only the missing or unconfirmed pieces. Keep the choice simple:

> "Before we implement tracking, I can optionally set up the Mixpanel plugin and Mixpanel MCP for your coding agent. The plugin adds Mixpanel workflows; MCP lets the agent work with your Mixpanel projects. Neither is required for tracking implementation. Would you like me to set up the missing tools now, or skip and continue?"

If only one piece is missing, name only that piece. If the user asks to install only one of the two, honor that choice. Do not imply that skipping reduces the correctness of the SDK instrumentation.

An affirmative answer authorizes the ordinary setup steps described below, but not unrelated account, project, or application changes. Ask for any client-required approval immediately before a command or configuration write if approval was not already captured by the client.

If the user skips, return to the main skill and do not raise this offer again during the session.

## 3. Set up the Mixpanel plugin when requested

Use the current coding client's supported plugin mechanism. Never invent installation commands for an unknown client.

### Claude Code

Run or guide the user through:

```bash
claude plugin marketplace add mixpanel/ai-plugins
claude plugin install mixpanel
```

Verify that the `mixpanel` plugin or its skills are listed. If the client requires a reload before newly installed skills appear, say so explicitly; the already-loaded tracking skill can still continue in the current conversation.

### Cursor

Use the Mixpanel plugin from the Cursor marketplace. For managed teams, a team admin can import `https://github.com/mixpanel/ai-plugins` as a team marketplace from **Dashboard -> Settings -> Plugins -> Import**. Guide the user through the UI if the agent cannot perform the action directly, then verify that the Mixpanel skills appear in **Cursor Settings -> Rules** under **Agent Decides**.

### Other clients

Use the client's plugin or Agent Skills installer only when it has a documented way to install the Mixpanel plugin from `https://github.com/mixpanel/ai-plugins`. If no supported plugin mechanism is available, explain that limitation and continue with MCP setup or tracking implementation. Do not block.

## 4. Set up Mixpanel MCP when requested

If the plugin is now available, use its `install` skill and explicitly choose the **Mixpanel MCP server** path. Otherwise, follow [`../../install/references/mcp-setup.md`](../../install/references/mcp-setup.md) directly.

1. Ask for the Mixpanel data region: US, EU, or India. If the user is unsure, infer it from the Mixpanel web address only: `eu.mixpanel.com` means EU, `in.mixpanel.com` means India, and `mixpanel.com` means US.
2. Register the regional MCP URL using the current client's supported setup path.
3. Let the user complete OAuth when prompted. Never request or store their password.
4. Verify that Mixpanel tools are usable and, when possible, that the user's expected projects are visible. A connected server with no expected projects commonly indicates the wrong region or insufficient project permissions.

If setup requires a client restart or a new session, give the exact next action and continue the implementation without MCP unless the user prefers to reconnect first.

## 5. Resume reliably

After setup succeeds, is skipped, or cannot be completed, return to **Pre-Flight -- Codebase Scan** in the main skill. Preserve any information already learned. Do not restart the conversation or repeat the setup offer.
