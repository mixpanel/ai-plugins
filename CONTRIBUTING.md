# Contributing

We welcome contributions — new skills, improvements to existing ones, bug fixes, and documentation.

## Before You Start

1. Read [SKILL-SPEC.md](SKILL-SPEC.md) to understand the skill structure
2. Check [open issues](https://github.com/mixpanel/skills/issues) for existing requests or known problems
3. For new skills, open an issue first to discuss scope and avoid duplicate work

## Submitting a Skill

### Structure

Your skill must follow the conventions in `SKILL-SPEC.md`:
- `SKILL.md` with valid frontmatter (name, description, compatibility)
- Progressive loading — don't require Claude to read everything upfront
- Silent execution — no narration of internal steps
- Preview before any Mixpanel writes

### Validation

Before submitting, verify:
- [ ] All MCP tool names match the current Mixpanel MCP API
- [ ] The `description` field triggers correctly (test with a few natural prompts)
- [ ] No hardcoded project IDs, customer names, or account-specific data
- [ ] Commands handle empty/error responses gracefully

### Pull Request Process

1. Fork the repo
2. Create a branch: `add-[skill-name]` or `fix-[skill-name]-[issue]`
3. Place your skill in `skills/mxp-[name]/`
4. Submit a PR with a description of what the skill does and example prompts that trigger it

## Improving Existing Skills

- Bug fixes and error handling improvements are always welcome
- For behavioral changes (new commands, altered scoring logic), open an issue first
- Keep PRs focused — one logical change per PR

## Style

- Markdown files use ATX-style headers (`#`, `##`)
- Code blocks specify language (```yaml, ```json, ```bash)
- Tables use pipes with header separators
- Line length: no hard limit, but break at ~120 chars for readability
