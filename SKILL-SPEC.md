# Skill Specification

This document defines the structure and conventions for skills in this repository.

## File Structure

```
skill-name/
├── SKILL.md              # Required. Entry point. Claude reads this first.
├── commands/             # Optional. Sub-workflows loaded on demand.
│   ├── command-a.md
│   └── command-b.md
├── references/           # Optional. Templates, schemas, shared config.
│   ├── template.md
│   └── schema.md
└── shared/               # Optional. Reusable logic across commands.
    └── shared-module.md
```

## SKILL.md Frontmatter

Every `SKILL.md` starts with YAML frontmatter:

```yaml
---
name: skill-name
description: >
  One paragraph. First sentence = what the skill does. Remaining sentences =
  trigger phrases (when should Claude activate this skill?). Include both
  natural language triggers ("score my Lexicon") and keyword triggers
  ("governance tool", "data quality"). End with required MCP dependencies.
compatibility:
  tools:
    - Mixpanel MCP
---
```

### Description Guidelines

The `description` field is how Claude decides whether to activate the skill. Write it for recall, not readability:
- Name the skill's purpose in the first sentence
- List 5–10 trigger phrases users might say
- Include synonyms and abbreviations
- Keep it under 100 words total

## Design Principles

### Progressive Loading

Skills should load files on demand, not all at once. The `SKILL.md` acts as a router — it reads command/reference files only when the user's intent requires them. This keeps context window usage efficient.

### Silent Execution

Skills should not narrate their steps. No "I'm now going to fetch your events..." — just fetch them and show results. The user sees: menus, confirmation prompts, progress indicators during batch operations, errors, and final output. Nothing else.

### Session State

Skills can define session variables that persist across commands within a conversation. This avoids redundant MCP calls. Document what each command reads and writes.

### Validation Before Writes

Any operation that mutates Mixpanel data (Lexicon edits, tag creation, issue dismissal) must show a preview and get explicit confirmation before executing. Batch writes should process in groups of 10 with progress indicators.

### Graceful Failure

Surface MCP errors explicitly — never silently skip a failed call. If a query fails, retry once using `Get-Query-Schema` for schema guidance. If a batch write partially fails, report which items succeeded and which failed.

## Naming Convention

- Skill folders: `mxp-[name]` (e.g., `mxp-governor-tool`)
- Command files: `[verb]-[noun].md` (e.g., `score-lexicon.md`, `enrich-lexicon.md`)
- Reference files: descriptive names (e.g., `skill-output-template.md`)
- Shared files: `[noun].md` (e.g., `schema-reader.md`)

## Templates

Starter templates are available in [`/templates`](../templates/):
- `SKILL-TEMPLATE.md` — blank skill entry point
- `COMMAND-TEMPLATE.md` — blank command file
