# Agent Skills

A collection of Agent Skills for building on Mixpanel.

## Quick Start

Each skill is a self-contained directory under `skills/`. To install a skill, copy its folder into the appropriate location for your coding agent.

### Claude Code

Copy the skill folder into your project's `.claude/skills/` directory:

```bash
cp -r skills/tracking-implementation .claude/skills/tracking-implementation
```

### Cursor

Copy the skill folder into your project's `.cursor/skills/` directory:

```bash
cp -r skills/tracking-implementation .cursor/skills/tracking-implementation
```

### Windsurf

Copy the skill folder into your project's `.windsurf/skills/` directory:

```bash
cp -r skills/tracking-implementation .windsurf/skills/tracking-implementation
```

### Codex

Copy the skill folder into your project's `.codex/skills/` directory:

```bash
cp -r skills/tracking-implementation .codex/skills/tracking-implementation
```

## Skills

| Skill | Description | When to Use |
|---|---|---|
| [tracking-implementation](skills/tracking-implementation/) | Guides you through implementing Mixpanel analytics correctly. Covers four modes: **Quick Start** (first events in one session), **Full Implementation** (complete production-ready setup), **Add Tracking** (extend an existing implementation), and **Audit** (review and diagnose an existing setup). | When you want to set up Mixpanel, add Mixpanel tracking, configure a new Mixpanel project, or audit an existing implementation. |

## Contributing

Contributions are welcome! To add a new skill or improve an existing one:

1. **Fork** this repository and create a new branch.
2. **Add your skill** under `skills/<skill-name>/` with at least a `SKILL.md` (agent-facing instructions) and a `readme.md` (human-facing documentation).
3. **Follow the existing structure** -- keep agent instructions in `SKILL.md` and detailed reference material in separate files to keep the skill fast to load.
4. **Update this README** -- add your skill to the Skills table above.
5. **Open a pull request** with a clear description of what the skill does and when it should be used.

## License

This project is licensed under the [MIT License](LICENSE). Use these skills freely in your projects, teams, and tools.
