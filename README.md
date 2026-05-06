# Mixpanel Agent Skills

A collection of [Agent Skills](https://agentskills.io) for building on Mixpanel. Skills are reusable, filesystem-based resources that give AI agents domain-specific expertise and workflows.

## Skills

| Skill | Description |
|---|---|
| [`tracking-implementation`](skills/tracking-implementation/) | Guides a coding agent through Mixpanel analytics implementation. Supports Quick Start, Full Implementation, Add Tracking, and Audit modes. |
| [`deep-research`](skills/deep-research/) | Conducts a structured metric investigation in Mixpanel. Use when a user asks *why* a metric changed, what's driving a trend, or requests a deep dive or root cause analysis. |

## Usage

These skills follow the [Agent Skills open standard](https://agentskills.io/specification) and work with any compatible agent client (Claude Code, Cowork, and others). Install them by pointing your agent client at this repository or copying individual skill folders into your skills directory.

## Contributing

1. Each skill lives in its own directory under `skills/` and must contain a `SKILL.md` file with valid frontmatter (`name` and `description` are required).
2. Follow the [Agent Skills specification](https://agentskills.io/specification) and [best practices](https://agentskills.io/skill-creation/best-practices).
3. Keep `SKILL.md` under 500 lines — move detailed reference material to `references/`.
4. Include a `readme.md` (for human maintainers) documenting architecture decisions and known limitations.

## License

Apache 2.0 — see [LICENSE](LICENSE).
