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

Set up how this project talks to Mixpanel. No config file is written — the installation itself is the memory: every other skill in this plugin detects the installed engine (a registered Mixpanel MCP server, or the `mixpanel-headless` SDK in the project's Python environment) and routes all Mixpanel actions through it. The shared convention (detection and per-engine rules) lives in [`../../ENGINE.md`](../../ENGINE.md) — read it before starting.

This skill is **interactive**: it asks the user to choose. If the session can't ask questions (non-interactive/CI run), stop and tell the user to run `/mixpanel:install` in an interactive session instead.

The bundled references defer to the live Mixpanel docs they cite — on any conflict, trust the live page.

---

## Step 0 — Detect existing state

Run the detection from ENGINE.md:

1. A Mixpanel MCP server already connected (or registered in the client's MCP config) → tell the user the MCP engine is already set up (name the region from the server URL) and ask whether to keep it or switch. If they keep it, stop here.
2. Otherwise, `mixpanel-headless` importable in the project's Python → same: report it and ask keep-or-switch.
3. Nothing detected → continue to Step 1.

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

1. Verify the Python environment, install the SDK, and set up service-account authentication following [`references/headless-setup.md`](references/headless-setup.md). Credentials go in environment variables — never in tracked files.
2. **Verify** with a trivial SDK call (import + a minimal authenticated operation). On failure, surface the exact error and fix auth before persisting.

## Step 2c — Own-integration path

Nothing to install and nothing to interrogate — assume the user provides the context needed to act (in the conversation, or in the project's agent instructions like `CLAUDE.md`). Acknowledge, and suggest they keep those instructions in the project so future sessions pick them up. Skip Step 3's verification.

## Step 3 — Confirm and wrap up

1. Re-run the verification for the chosen path and summarize what was installed (engine, region, where it lives — e.g. the repo's `.mcp.json` or the Python environment). Nothing else is persisted; the other skills detect this installation directly.
2. Suggest a next step: try a skill like `analyze-report`, `deep-research`, or `tracking-implementation`.
