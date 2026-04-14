# Mixpanel Skills

Community skills for [Mixpanel MCP](https://docs.mixpanel.com/docs/mcp) on Claude.ai. Each skill teaches Claude a structured workflow for working with your Mixpanel data — governance, query standards, customer intelligence, and more.

## What's a Skill?

A skill is a set of markdown files that Claude reads before executing a task. Think of it as a runbook: it tells Claude what MCP tools to call, in what order, how to validate results, and how to present output. Skills live in your Claude.ai profile and activate automatically when your prompt matches their trigger description.

Every skill has:
- **`SKILL.md`** — the entry point Claude reads first (router, rules, execution flow)
- **`commands/`** — sub-workflows loaded on demand (optional)
- **`references/`** — templates, schemas, shared logic (optional)
- **`shared/`** — reusable components across commands (optional)

## Available Skills

| Skill | What it does |
|---|---|
| [mxp-governor-tool](mxp-governor-tool/) | Lexicon governance — score health, enrich metadata, auto-tag events, triage data quality issues, manage tags |
| [mxp-skill-creator](mxp-skill-creator/) | Guided wizard to create validated Mixpanel query skills for any customer or team |

## Installation

1. Download the skill folder (or clone this repo)
2. In Claude.ai, go to **Settings → Skills**
3. Upload the skill folder
4. The skill activates automatically when your prompt matches its trigger phrases

## Prerequisites

All skills require **Mixpanel MCP** connected in Claude.ai. Some skills additionally benefit from Slack MCP for output delivery.

To connect Mixpanel MCP:
1. In Claude.ai, open the **Tools** menu (puzzle icon)
2. Search for "Mixpanel" and connect
3. Authenticate with your Mixpanel credentials

## Skill Anatomy

See [SKILL-SPEC.md](SKILL-SPEC.md) for the full specification of how skills are structured, including frontmatter format, file conventions, and design principles.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on submitting new skills or improvements.

## License

[Apache 2.0](LICENSE)
