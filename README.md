# Mixpanel AI Plugins

Plugins that give AI agents Mixpanel expertise. Built on the [Agent Skills](https://agentskills.io) open standard.

The `mixpanel` plugin is **engine-agnostic**: its skills work through whichever engine you set up — the [Mixpanel MCP server](https://docs.mixpanel.com/docs/mcp) (any region) or the [`mixpanel-headless`](https://docs.mixpanel.com/docs/mixpanel-headless) Python SDK. Run the `install` skill once; every other skill takes it from there.

## Getting started

### Claude Code

```bash
claude plugin marketplace add mixpanel/ai-plugins
claude plugin install mixpanel
```

Then, in your project, run `/mixpanel:install` to set up an engine and region.

### Cursor

Install the plugin from the Cursor marketplace, or have a team admin import this GitHub repository as a team marketplace (Dashboard → Settings → Plugins → Import).

Skills appear in **Cursor Settings → Rules** under **Agent Decides** and can be invoked with `/skill-name` in chat. Run the `install` skill first to set up an engine.

## Skills

| Skill | Description |
| --- | --- |
| [`install`](plugins/mixpanel/skills/install/) | Sets up a Mixpanel engine for a project — MCP server (US/EU/India), mixpanel-headless SDK, or your own integration. |
| [`analyze-report`](plugins/mixpanel/skills/analyze-report/) | Reads and explains an existing report or chart — what it shows, what's notable, what's worth a closer look. |
| [`create-dashboard`](plugins/mixpanel/skills/create-dashboard/) | Creates a well-designed dashboard with validated data, text cards, and narrative layout. |
| [`deep-research`](plugins/mixpanel/skills/deep-research/) | Structured metric investigation — why a metric changed, what's driving a trend, root-cause deep dives. |
| [`learn-mcp`](plugins/mixpanel/skills/learn-mcp/) | Guided, interactive onboarding to the Mixpanel MCP server (applies when the engine is MCP). |
| [`manage-boards`](plugins/mixpanel/skills/manage-boards/) | Full dashboard lifecycle — create, template, clone, clean up, inventory, and update across projects and teams. |
| [`manage-experiment`](plugins/mixpanel/skills/manage-experiment/) | Coaches through every phase of an experiment — design (hypothesis, metrics, sizing, statistical model) and interpretation (results, ship/iterate/kill, health checks, segments, replays). |
| [`manage-feature-flags`](plugins/mixpanel/skills/manage-feature-flags/) | Feature-flag guidance — Feature Gate vs Dynamic Config vs Experiment, staged rollouts, kill switch, exposure debugging, SDK patterns. |
| [`manage-lexicon`](plugins/mixpanel/skills/manage-lexicon/) | Audits, scores, enriches, and cleans up Lexicon metadata — descriptions, tags, resets, data-quality triage. |
| [`monitor-metrics`](plugins/mixpanel/skills/monitor-metrics/) | Monitors and diagnoses a metric — anomaly detection, drift detection, and root-cause attribution with charts and a diagnosis board. |
| [`prepare-ai-readiness`](plugins/mixpanel/skills/prepare-ai-readiness/) | Sets up business context and delegates Lexicon enrichment so Mixpanel's AI assistants understand your data. |
| [`tracking-implementation`](plugins/mixpanel/skills/tracking-implementation/) | Guides analytics implementation — Quick Start, Full Implementation, Add Tracking, and Audit modes. |

### Internal skills

| Skill | Description |
| --- | --- |
| [`review-skill`](.claude/skills/review-skill/) | Reviews a skill against a weighted quality rubric and produces a score with actionable issues. Run `/review-skill <skill-name>` before requesting a code review. |

## Migrating from the legacy plugins

The region-specific plugins — `mixpanel-mcp`, `mixpanel-mcp-eu`, `mixpanel-mcp-in` — are retired: region is now a configuration choice inside `mixpanel`.

**Most users** — run `/plugin marketplace update mixpanel`. Your install is renamed to `mixpanel` automatically (Claude Code ≥ 2.1.193). The old plugin's bundled MCP server doesn't carry over, so run `/mixpanel:install` once to reconnect your engine and region.

**Seeing `plugin-not-found`?** Your Claude Code predates rename support. Update it, or migrate by hand:

```
/plugin uninstall mixpanel-mcp@mixpanel   # or mixpanel-mcp-eu / mixpanel-mcp-in
/plugin install mixpanel@mixpanel
/mixpanel:install
```

**Prefer the old plugins?** Pin the pre-restructure state (tag [`v0.1.1`](https://github.com/mixpanel/ai-plugins/releases/tag/v0.1.1)):

```bash
claude plugin marketplace add mixpanel/ai-plugins@v0.1.1
```

## Contributing

Contributions are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Apache 2.0 — see [LICENSE](LICENSE).
