# Optional coding-agent setup

Use this checkpoint once, at the very start of `tracking-implementation`. Its purpose is to help the user add two optional coding-agent capabilities before implementation begins:

- **Mixpanel plugin** -- gives the coding agent the full set of Mixpanel skills, including implementation, analysis, dashboards, experiments, and governance workflows.
- **Mixpanel MCP server** -- lets the coding agent access the Mixpanel projects the user can access, subject to the user's Mixpanel permissions.

Neither is the Mixpanel application SDK. Neither is required to add tracking code. The setup offer is optional, but once the user accepts it, the selected setup becomes a hard gate. Do not touch application code until the gate passes or the user explicitly cancels setup and chooses to continue without it.

## 1. Detect existing setup

Use read-only checks where the client supports them.

### Plugin

Treat the plugin as installed when the current client exposes the `mixpanel` plugin or its namespaced skills. Invocation as `/mixpanel:tracking-implementation` is also sufficient evidence. A pasted or externally supplied copy of this skill is not evidence that the plugin is installed.

If plugin state cannot be determined safely, call it "not confirmed" rather than claiming it is missing.

### MCP

Treat MCP as connected when Mixpanel MCP tools are available in the current session. If the client exposes its MCP configuration through a read-only command or UI, that may also be checked. A configuration entry without usable tools is not a completed setup; it may still need OAuth or a client reload.

When both are already available, tell the user briefly, verify MCP with a successful project listing, and continue at **Resolve project context through MCP** without presenting a setup choice.

## 2. Make one optional offer

Offer only the missing or unconfirmed pieces. Keep the choice simple:

> "Before we implement tracking, I can optionally set up the Mixpanel plugin and Mixpanel MCP for your coding agent. The plugin adds Mixpanel workflows; MCP lets the agent work with your Mixpanel projects. Neither is required for tracking implementation. Would you like me to set up the missing tools now, or skip and continue?"

Add: "If you choose setup, I won't inspect or change application code until the selected tools are installed, connected, and verified."

If only one piece is missing, name only that piece. If the user asks to install only one of the two, honor that choice. Do not imply that skipping reduces the correctness of the SDK instrumentation.

An affirmative answer authorizes the ordinary setup steps described below, but not unrelated account, project, or application changes. Ask for any client-required approval immediately before a command or configuration write if approval was not already captured by the client.

If the user skips, return to the main skill and do not raise this offer again during the session.

## 3. Hold the setup gate

As soon as the user accepts setup, pause the rest of `tracking-implementation`. During the gate:

- Do not scan the application codebase or begin mode selection and implementation discovery.
- Do not create or edit application files, dependency manifests, environment files, or agent instructions.
- Do not install a Mixpanel application SDK. Plugin and MCP setup are the only permitted changes.
- Do not treat an attempted command, a saved configuration entry, or an opened OAuth page as success.

The gate passes only when every component the user selected is verified:

| Component | Required verification |
| --- | --- |
| Mixpanel plugin | The client reports the plugin installed and enabled, and its Mixpanel skills are available. |
| Mixpanel MCP | Authentication is complete, Mixpanel tools are usable, and a project-listing request succeeds for the signed-in user. |

If verification fails, report the exact failure and offer to retry. If a restart or new session is required, give the exact resume instruction and stop; the gate remains active in the resumed session. The only other exit is an explicit user instruction to cancel or skip setup. Never interpret silence, an error, or a restart as permission to continue into application code.

## 4. Set up the Mixpanel plugin when requested

Use the current coding client's supported plugin mechanism. Never invent installation commands for an unknown client.

### Claude Code

Run or guide the user through:

```bash
claude plugin marketplace add mixpanel/ai-plugins
claude plugin install mixpanel
```

Verify that the `mixpanel` plugin is installed and enabled and that its skills are listed. If the client requires a reload before newly installed skills appear, keep the gate active, tell the user exactly how to resume after reloading, and stop before touching application code.

### Cursor

Use the Mixpanel plugin from the Cursor marketplace. For managed teams, a team admin can import `https://github.com/mixpanel/ai-plugins` as a team marketplace from **Dashboard -> Settings -> Plugins -> Import**. Guide the user through the UI if the agent cannot perform the action directly, then verify that the Mixpanel skills appear in **Cursor Settings -> Rules** under **Agent Decides**.

### Other clients

Use the client's plugin or Agent Skills installer only when it has a documented way to install the Mixpanel plugin from `https://github.com/mixpanel/ai-plugins`. If no supported plugin mechanism is available, explain that limitation and ask the user whether to try another supported client or explicitly cancel the setup choice. Do not continue into tracking implementation automatically.

## 5. Set up Mixpanel MCP when requested

If the plugin is now available, use its `install` skill and explicitly choose the **Mixpanel MCP server** path. Otherwise, follow [`../../install/references/mcp-setup.md`](../../install/references/mcp-setup.md) directly.

1. Ask for the Mixpanel data region: US, EU, or India. If the user is unsure, infer it from the Mixpanel web address only: `eu.mixpanel.com` means EU, `in.mixpanel.com` means India, and `mixpanel.com` means US.
2. Register the regional MCP URL using the current client's supported setup path.
3. Let the user complete OAuth when prompted. Never request or store their password.
4. Verify that Mixpanel tools are usable by listing the signed-in user's accessible projects. A configuration entry, completed OAuth page, or nonempty tool list without a successful project request is not sufficient. No visible projects commonly indicates the wrong region, disabled organization access, or insufficient project permissions; keep the gate active and resolve that before continuing.

If setup requires a client restart or a new session, give the exact next action and stop. Do not continue implementation without MCP unless the user explicitly cancels the setup choice.

## 6. Resolve project context through MCP

After MCP verification and before any application-code work:

1. List the projects available to the signed-in Mixpanel user.
2. Ask the user to select the intended project when more than one is plausible. Never choose production based only on a name match.
3. Capture the confirmed project's name, ID, data region, and project token from the available project metadata. If both development and production projects will be used, confirm and capture each one separately.
4. If the project lookup does not expose a token, say so and ask the user to copy it from Project Settings. Do not invent or infer a token.

Project tokens are public identifiers rather than authorization secrets, but still place them in the application's existing environment configuration instead of hardcoding them in source files.

## 7. Resume reliably

Return to **Pre-Flight -- Codebase Scan** only after either:

- every selected setup component passes its verification, and project context has been resolved when MCP is connected, or
- the user explicitly cancels setup and asks to continue without it.

Preserve the selected project metadata and any other information already learned. Do not restart the conversation or repeat the setup offer.
