---
name: install
description: >
  Set up Mixpanel for this project — pick and install the engine the
  other Mixpanel skills will use (Mixpanel MCP server, mixpanel-headless
  Python SDK, or the user's own integration). Use whenever the user asks to set up, install,
  configure, or connect Mixpanel, switch Mixpanel engine or region, or
  when any Mixpanel skill finds no engine set up. Trigger phrases:
  "set up mixpanel", "configure mixpanel", "connect mixpanel", "install
  mixpanel", "switch mixpanel region", "use mixpanel headless", "change
  mixpanel engine". Do NOT use for adding Mixpanel tracking code to an
  application (use tracking-implementation) or for running analytics
  queries. Interactive — asks the user to choose; do not run in
  non-interactive sessions.
compatibility: "Works in any project. Configures the engine all other Mixpanel skills use."
metadata:
  engine: none
---

# Mixpanel Install

> **No engine required** — this skill is what _configures_ the engine.

Set up how this project talks to Mixpanel. Every other skill in this plugin defaults to the Mixpanel MCP server unless the user's instructions name another engine; this skill installs an engine and can save that preference. The shared convention (per-engine rules, preference locations) lives in [`../../ENGINE.md`](../../ENGINE.md) — read it before starting.

This skill is **interactive**: it asks the user to choose. If the session can't ask questions (non-interactive/CI run), stop and tell the user to run `/mixpanel:install` in an interactive session instead.

The bundled references defer to the live Mixpanel docs they cite — on any conflict, trust the live page.

---

## Step 0 — Detect existing state

1. Mixpanel MCP tools listed in this session → tell the user the MCP engine is already set up (name the region if the server URL is visible) and ask whether to keep it or switch. If they keep it, stop here.
2. Otherwise run `mp --version` (one command). Success → the headless SDK is installed: ask **"MCP is not available — how should we proceed?"** with two options: (a) install MCP, (b) use headless. Installing MCP → Step 2a. Using headless → verify auth (Step 2b's verify) and jump to Step 3, including the preference note.
3. Neither → continue to Step 1.

## Step 1 — Choose an engine

Ask with the client's multiple-choice question UI (one question, three options):

1. **Mixpanel MCP server** _(recommended for interactive analytics)_ — a remote server exposing Mixpanel tools; OAuth login; best when a person is in the loop.
2. **Headless SDK** — the [`mixpanel-headless`](https://docs.mixpanel.com/docs/mixpanel-headless) Python package; the full Mixpanel platform as a Python object; best for scripted, CI, or coding-agent workflows.
3. **I have my own integration** — the user already has their own way to reach Mixpanel.

## Step 2a — MCP path

1. Ask the **region**: US / EU / India (URL map in [`references/mcp-setup.md`](references/mcp-setup.md)). If the user is unsure, their Mixpanel URL tells them (`eu.mixpanel.com` → EU, `in.mixpanel.com` → India; otherwise US).
2. Register the server with the current client following [`references/mcp-setup.md`](references/mcp-setup.md) — the standard recipe per client, plus the fallback transport. No further questions; just run the standard installation.
3. **Verify**: list the server's tools. If authentication is pending, have the user complete the client's OAuth flow (per the reference), then re-check.

## Step 2b — Headless path

1. Run the one-line availability check from [`references/headless-setup.md`](references/headless-setup.md); install the SDK if it's missing.
2. Authenticate per the reference: run `mp login` yourself — it picks the right flow from the environment (opens the user's browser for OAuth, or uses service-account / bearer-token env vars when set). Don't ask the user to run it; just tell them to complete the login in the browser. Credentials never go in tracked files.
3. **Verify** with `mp account test`. On failure, surface the exact error and fix auth before wrapping up.

## Step 2c — Own-integration path

Nothing to install and nothing to interrogate — assume the user provides the context needed to act (in the conversation, or in the project's agent instructions like `CLAUDE.md`). Acknowledge, skip Step 3's verification, but do offer Step 3's preference note so future sessions pick the integration up.

## Step 3 — Confirm and wrap up

Always complete all three points — even when this skill was triggered mid-task by another skill, finish them **before** resuming the original request.

1. Re-run the verification for the chosen path and summarize what was installed (engine, region, where it lives — e.g. the repo's `.mcp.json` or the Python environment).
2. **Preference note** — if the user ended on a non-default engine (headless or their own integration), ask: "Want me to leave a note of this preference so you don't have to specify it each time?" If yes, ask where — project level or user level — and append one plain line (e.g. `For Mixpanel, use the headless SDK.`) to the matching file per [`../../ENGINE.md`](../../ENGINE.md): project → the project's `CLAUDE.md` (or `AGENTS.md` in Cursor); user → `~/.claude/CLAUDE.md` (in Cursor, point them to Settings → Rules). Never write without asking. MCP needs no note — it's the default.
3. Suggest a next step: try a skill like `analyze-report`, `deep-research`, or `tracking-implementation`. If the headless engine was installed, also mention the SDK's companion plugin (see [`references/headless-setup.md`](references/headless-setup.md)).
