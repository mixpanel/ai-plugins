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

We welcome new skills. To propose one, open a pull request — we prefer **one skill per PR** so reviews stay focused, and we'll merge them as they're ready rather than batching.

Before opening the PR:

1. Each skill lives in its own directory under `skills/` and must contain a `SKILL.md` file with valid frontmatter (`name` and `description` are required).
2. Follow the [Agent Skills specification](https://agentskills.io/specification) and [best practices](https://agentskills.io/skill-creation/best-practices).
3. Keep `SKILL.md` under 500 lines — move detailed reference material to `references/`.
4. **Test the skill end-to-end** before submission — confirm it triggers on the phrasings in your `description` and produces the output you expect.
5. **Include examples in the PR description** showing prompts the skill should handle and what it returns. Real examples make the skill much easier to review and to maintain later.

## License

Apache 2.0 — see [LICENSE](LICENSE).
