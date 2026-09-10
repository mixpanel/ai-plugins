# Mixpanel Plugin

Gives AI coding agents Mixpanel expertise: skills for the analytics work Mixpanel customers do most — implementing tracking, investigating metrics, building dashboards, and running experiments.

The plugin is engine-agnostic: its skills work through whichever engine you set up — the hosted [Mixpanel MCP server](https://docs.mixpanel.com/docs/mcp) (US, EU, or India) or the [`mixpanel-headless`](https://docs.mixpanel.com/docs/mixpanel-headless) Python SDK. See [ENGINE.md](ENGINE.md) for how skills resolve an engine.

## Installation

```bash
claude plugin marketplace add mixpanel/ai-plugins
claude plugin install mixpanel
```

Then, in your project, run `/mixpanel:install` once to set up an engine and region. If the Mixpanel MCP server is already connected in your session, the skills use it automatically.

## Requirements

- A [Mixpanel](https://mixpanel.com) account with access to at least one project
- For the MCP engine: MCP enabled for your organization — an org admin can enable it in **Settings → Org → Overview**. See [Permissions & Access](https://docs.mixpanel.com/docs/mcp#permissions--access).

You authenticate with your own Mixpanel credentials (OAuth for MCP, `mp login` for the headless SDK), so your existing project permissions and roles apply.

## Skills

Claude invokes these automatically based on your request, or you can call one directly with `/mixpanel:skill-name`.

| Skill | What it does |
| --- | --- |
| [`install`](skills/install/) | Sets up a Mixpanel engine for a project — MCP server (US/EU/India), mixpanel-headless SDK, or your own integration. |
| [`analyze-report`](skills/analyze-report/) | Reads and explains an existing Mixpanel report or chart — what it shows, what's notable, what's worth a closer look. |
| [`create-dashboard`](skills/create-dashboard/) | Builds a well-designed dashboard with validated reports, text cards, and narrative layout. |
| [`deep-research`](skills/deep-research/) | Runs a structured root-cause investigation into why a metric changed or what's driving a trend. |
| [`learn-mcp`](skills/learn-mcp/) | Onboards you to the MCP server through guided, interactive modules (applies when the engine is MCP). |
| [`manage-boards`](skills/manage-boards/) | Full dashboard lifecycle: create, template, clone, inventory, clean up, and standardize boards. |
| [`manage-experiment`](skills/manage-experiment/) | Coaches you through any phase of an experiment — design, launch, mid-flight monitoring, and interpreting results. |
| [`manage-feature-flags`](skills/manage-feature-flags/) | Creates, rolls out, debugs, and cleans up feature flags — feature gates, dynamic configs, staged rollouts, kill switches. |
| [`manage-lexicon`](skills/manage-lexicon/) | Audits, scores, enriches, and cleans up Lexicon metadata (events and properties) for a project. |
| [`monitor-metrics`](skills/monitor-metrics/) | Detects anomalies and drift in a metric and runs root-cause analysis on the movement. |
| [`prepare-ai-readiness`](skills/prepare-ai-readiness/) | Sets up business context and Lexicon metadata so Mixpanel's AI assistants understand your data. |
| [`tracking-implementation`](skills/tracking-implementation/) | Guides an analytics implementation: quick start, full production setup, adding tracking, or auditing an existing setup. |

## What the plugin can do on your behalf

Through its engine, the agent can **read and write** to Mixpanel: run queries, create and edit dashboards, manage cohorts and Lexicon metadata, and create experiments and feature flags. Access is scoped to the projects your Mixpanel user can already see. For the MCP engine, the full tool list and security considerations are in the [MCP server docs](https://docs.mixpanel.com/docs/mcp#available-tools).

## License

Apache 2.0 — see [LICENSE](../../LICENSE).
