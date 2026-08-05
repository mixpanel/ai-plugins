# Mixpanel AI Plugins

Plugins that give AI agents Mixpanel expertise. Built on the [Agent Skills](https://agentskills.io) open standard.

The `mixpanel` plugin is **engine-agnostic**: its skills work through whichever engine you install — the [Mixpanel MCP server](https://docs.mixpanel.com/docs/mcp) (any region) or the [`mixpanel-headless`](https://docs.mixpanel.com/docs/mixpanel-headless) Python SDK. You set it up once with the `install` skill and every skill uses it from there.

## Getting Started

### Claude Code

```bash
claude plugin marketplace add mixpanel/ai-plugins
claude plugin install mixpanel
```

Then, in your project, run `/mixpanel:install` and pick your engine (and region). Every other skill detects that installation.

### Cursor

Install the plugin from the Cursor marketplace, or have a team admin import this GitHub repository as a team marketplace (Dashboard → Settings → Plugins → Import).

Once installed, skills appear in **Cursor Settings → Rules** under the **Agent Decides** section and can be invoked with `/skill-name` in chat. Run the `install` skill first to set up the engine.

## Skills

| Skill | Description |
| --- | --- |
| [`install`](plugins/mixpanel/skills/install/) | Sets up the Mixpanel engine for a project — MCP server (US/EU/India), mixpanel-headless SDK, or the user's own integration. The other skills detect whichever one is installed. |
| [`analyze-report`](plugins/mixpanel/skills/analyze-report/) | Reads and explains an existing Mixpanel report or chart — what it shows, what's notable, and what's worth a closer look. |
| [`create-dashboard`](plugins/mixpanel/skills/create-dashboard/) | Creates a well-designed Mixpanel dashboard with validated data, text cards, and narrative layout. |
| [`deep-research`](plugins/mixpanel/skills/deep-research/) | Conducts a structured metric investigation in Mixpanel. Use when a user asks _why_ a metric changed, what's driving a trend, or requests a deep dive or root cause analysis. |
| [`learn-mcp`](plugins/mixpanel/skills/learn-mcp/) | Onboards users to the Mixpanel MCP server through guided, interactive modules (applies when the installed engine is MCP). |
| [`manage-boards`](plugins/mixpanel/skills/manage-boards/) | Full lifecycle dashboard management — create, template, clone, clean up, inventory, and update dashboards across projects and teams. |
| [`manage-experiment`](plugins/mixpanel/skills/manage-experiment/) | Coaches an agent through any phase of a Mixpanel experiment — designing before launch (hypothesis, metrics, sizing, statistical model, advanced features, pre-launch checks) and interpreting after launch (read results, ship / iterate / kill / wait, health checks, segment breakdowns, session replays). |
| [`manage-feature-flags`](plugins/mixpanel/skills/manage-feature-flags/) | Coaches an agent through Mixpanel feature-flag work — picking the right flag-shaped tool (Feature Gate vs Dynamic Config vs Experiment), staged rollouts, the kill switch, exposure debugging, archive/restore, and SDK call patterns. |
| [`manage-lexicon`](plugins/mixpanel/skills/manage-lexicon/) | Audits, scores, enriches, and cleans up Lexicon metadata (events and properties) for a Mixpanel project. Supports scoring health, bulk-filling descriptions/tags, resetting metadata, triaging data quality issues, and managing tags. |
| [`monitor-metrics`](plugins/mixpanel/skills/monitor-metrics/) | Monitors and diagnoses a Mixpanel metric — anomaly detection, drift detection, and root-cause attribution with charts and a diagnosis board. |
| [`prepare-ai-readiness`](plugins/mixpanel/skills/prepare-ai-readiness/) | Sets up business context (org and project level) and delegates Lexicon enrichment so Mixpanel's AI assistants understand a customer's data. Supports status scoring, importing existing context, interview-based setup, and choosing org vs. project scope. |
| [`tracking-implementation`](plugins/mixpanel/skills/tracking-implementation/) | Guides an agent through Mixpanel analytics implementation. Supports Quick Start, Full Implementation, Add Tracking, and Audit modes. |

### Internal skills

| Skill | Description |
| --- | --- |
| [`review-skill`](.claude/skills/review-skill/) | Reviews a skill against a weighted quality rubric (8 dimensions, 27 checks) and produces a score with actionable issues. Run `/review-skill <skill-name>` before requesting a code review. |

## Legacy plugins (retired)

The original region-specific plugins — `mixpanel-mcp`, `mixpanel-mcp-eu`, and `mixpanel-mcp-in` — are retired in favor of `mixpanel`, where region is a configuration choice instead of a separate plugin.

- **Existing installs migrate automatically**: the marketplace maps the old names to `mixpanel` (via `renames`, Claude Code ≥ 2.1.193). On your next marketplace update you'll see a one-line rename notice; then run `/mixpanel:install` once to configure your engine and region.
- **To stay on the old plugins**, pin your marketplace to the pre-restructure state (tag [`v0.1.1`](https://github.com/mixpanel/ai-plugins/releases/tag/v0.1.1)):

```bash
claude plugin marketplace add mixpanel/ai-plugins@v0.1.1
```

Never move or delete the `v0.1.1` tag — it is the pinned home of the legacy plugins.

## Contributing

To propose a plugin, open a pull request — we prefer **one plugin per PR** so reviews stay focused, and we'll merge them as they're ready rather than batching.

### Editing skills

All skill development happens in **`plugins/mixpanel/skills/`**.

- The marketplace `name` field (`mixpanel`) must never change, and the `renames` map is append-only — existing installs are keyed against them.
- Skills must stay **engine-agnostic**: no hardcoded MCP tool names or URLs. Describe Mixpanel actions in plain language and follow the conventions in [`plugins/mixpanel/ENGINE.md`](plugins/mixpanel/ENGINE.md).
- Every skill must declare `engine: required | optional | none` in its frontmatter `metadata`, and engine skills carry a one-line ENGINE.md pointer under the title (details in ENGINE.md). CI runs `scripts/check-engine-markers.sh` and fails skills that skip either.

### Before opening the PR

1. Each skill lives in its own directory under `skills/` and must contain a `SKILL.md` with valid `name` and `description` frontmatter.
2. Follow the [Agent Skills specification](https://agentskills.io/specification) and [best practices](https://agentskills.io/skill-creation/best-practices).
3. Keep the main file under 500 lines — move detailed reference material to `references/`.
4. **Test the plugin end-to-end** before submission — confirm it triggers on the expected prompts and produces the output you expect.
5. **Include examples in the PR description** showing prompts the plugin handles and what it returns.
6. **Run `/review-skill <skill-name>`** and address any blocker or major issues before requesting review.

## License

Apache 2.0 — see [LICENSE](LICENSE).
