---
name: install
description: >
  Set up Mixpanel for this project — pick and configure the engine the
  other Mixpanel skills will use (Mixpanel MCP server, mixpanel-headless
  Python SDK, or your own integration) and persist the choice to
  .claude/mixpanel.json. Use whenever the user asks to set up, install,
  configure, or connect Mixpanel, switch Mixpanel engine or region, or
  when any Mixpanel skill finds no engine configured. Trigger phrases:
  "set up mixpanel", "configure mixpanel", "connect mixpanel", "install
  mixpanel", "switch mixpanel region", "use mixpanel headless", "change
  mixpanel engine". Do NOT use for adding Mixpanel tracking code to an
  application (use tracking-implementation) or for running analytics
  queries. Interactive — asks the user to choose; do not run in
  non-interactive sessions.
compatibility: "Works in any project. Configures the engine all other Mixpanel skills use."
---

# Mixpanel Install

Configure how this project talks to Mixpanel. The choice — the **engine** — is
written to `.claude/mixpanel.json` at the project root; every other skill in
this plugin reads that file and routes all Mixpanel actions through it. The
shared convention (config schema, region→URL map, per-engine rules, capability
map) lives in [`../../ENGINE.md`](../../ENGINE.md) — read it before starting.

This skill is **interactive**: it asks the user to choose. If the session can't
ask questions (non-interactive/CI run), stop and tell the user to run
`/mixpanel:install` in an interactive session instead.

The bundled references defer to the live Mixpanel docs they cite — on any
conflict, trust the live page.

---

## Step 0 — Detect existing state

1. Read `.claude/mixpanel.json` from the project root.
   - **Present** → summarize the current engine (and region), then ask whether
     to reconfigure or keep it. If they keep it, stop here.
2. Check whether a Mixpanel MCP server is already connected in this session
   (its tools appear in the tool listing).
   - If yes and there is no config file, offer the shortcut: persist
     `engine: mcp` for that server — after asking the user to confirm which
     region it points at. Then jump to Step 3.

## Step 1 — Choose an engine

Ask with the client's multiple-choice question UI (one question, three
options):

1. **Mixpanel MCP server** *(recommended for interactive analytics)* — a
   remote server exposing Mixpanel tools; OAuth login; best when a person is
   in the loop.
2. **Headless SDK** — the [`mixpanel-headless`](https://docs.mixpanel.com/docs/mixpanel-headless)
   Python package; the full Mixpanel platform as a Python object; best for
   scripted, CI, or coding-agent workflows.
3. **I have my own integration** — the user already has a way to reach
   Mixpanel (their own MCP server, internal API wrapper, agent, or scripts).

## Step 2a — MCP path

1. Ask the **region**: US / EU / India (URL map in ENGINE.md). If the user is
   unsure, their Mixpanel URL tells them (`eu.mixpanel.com` → EU,
   `in.mixpanel.com` → India; otherwise US).
2. Ask the **scope**: user (all their projects) or project (this repo,
   shareable with the team).
3. Register the server with the current client following
   [`references/mcp-setup.md`](references/mcp-setup.md) — it has the exact
   recipe per client and the fallback transport.
4. **Verify**: list the server's tools. If authentication is pending, have the
   user complete the client's OAuth flow (per the reference), then re-check.

## Step 2b — Headless path

1. Verify the Python environment, install the SDK, and set up
   service-account authentication following
   [`references/headless-setup.md`](references/headless-setup.md).
   Credentials go in environment variables — never in tracked files.
2. **Verify** with a trivial SDK call (import + a minimal authenticated
   operation). On failure, surface the exact error and fix auth before
   persisting.

## Step 2c — Own-integration path

Ask the user to describe, in a few sentences, how Mixpanel actions should be
performed in this project (what to call, where it lives, any constraints).
Store that text verbatim as `custom.instructions`. Ask for the region too —
skills still use it for URLs and docs links.

## Step 3 — Preview, persist, confirm

1. Show the user the exact JSON that will be written to
   `.claude/mixpanel.json` (schema in ENGINE.md — `version`, `engine`,
   `region`, plus the block for the chosen engine only) and ask for one
   confirmation.
2. On confirm, write the file (create the `.claude/` directory if needed).
   Note it is safe to commit — no credentials are ever stored in it.
3. Suggest a next step: try a skill like `analyze-report`, `deep-research`, or
   `tracking-implementation`.
