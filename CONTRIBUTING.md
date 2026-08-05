# Contributing

To propose a plugin, open a pull request — we prefer **one plugin per PR** so reviews stay focused, and we'll merge them as they're ready rather than batching.

## Editing skills

All skill development happens in **`plugins/mixpanel/skills/`**.

- Skills must stay **engine-agnostic**: no hardcoded MCP tool names or URLs. Describe Mixpanel actions in plain language and follow the conventions in [`plugins/mixpanel/ENGINE.md`](plugins/mixpanel/ENGINE.md).
- Every skill must declare `engine: required | optional | none` in its frontmatter `metadata`, and engine skills carry a one-line ENGINE.md pointer under the title (details in ENGINE.md). CI runs `scripts/check-engine-markers.sh` and fails skills that skip either.

## Marketplace invariants

- The marketplace `name` field (`mixpanel`) must never change, and the `renames` map is append-only — existing installs are keyed against them.
- `.claude-plugin/marketplace.json` and `.cursor-plugin/marketplace.json` must stay identical (CI-enforced).
- The `v0.1.1` tag is the pinned home of the retired legacy plugins — never move or delete it.

## Before opening the PR

1. Each skill lives in its own directory under `skills/` and must contain a `SKILL.md` with valid `name` and `description` frontmatter.
2. Follow the [Agent Skills specification](https://agentskills.io/specification) and [best practices](https://agentskills.io/skill-creation/best-practices).
3. Keep the main file under 500 lines — move detailed reference material to `references/`.
4. **Test the plugin end-to-end** before submission — confirm it triggers on the expected prompts and produces the output you expect.
5. **Include examples in the PR description** showing prompts the plugin handles and what it returns.
6. **Run `/review-skill <skill-name>`** and address any blocker or major issues before requesting review.
