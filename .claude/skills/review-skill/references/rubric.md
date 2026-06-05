# Review Rubric

## Dimension 1 — Spec Compliance (10%)

### Valid frontmatter — Blocker

SKILL.md starts with valid YAML frontmatter containing `name` and `description`.

- **PASS:** `---\nname: create-dashboard\ndescription: Creates a well-designed Mixpanel dashboard.\n---`
- **FAIL:** Missing frontmatter, invalid YAML, or missing required fields. Override: score capped at 0%.

### Name format and match — Blocker

`name` is 1-64 chars, lowercase alphanumeric + hyphens, no leading/trailing/consecutive hyphens. Must match the parent directory name.

- **PASS:** `name: manage-lexicon` in directory `manage-lexicon/`.
- **FAIL:** `name: Data_Governance` (uppercase, underscore) or name does not match directory.

### Description length — Major

`description` is 1-1024 characters and non-empty.

- **PASS:** A 200-character description that covers what the skill does and when to use it.
- **WARN:** Under 20 characters (likely too vague).
- **FAIL:** Empty or exceeds 1024 characters.

### Line limit — Minor

Main SKILL.md is 500 lines or fewer.

- **PASS:** `create-dashboard/SKILL.md` at 85 lines.
- **WARN:** 501-600 lines.
- **FAIL:** >600 lines.

### Multi-variant sync — Major

If the skill is duplicated across multiple plugin variants (regional, partner, white-label), files must be identical across variants.

- **PASS:** `diff plugins/mixpanel-mcp/skills/foo plugins/mixpanel-mcp-eu/skills/foo` returns no differences.
- **FAIL:** Files differ between variants.
- **N/A:** Skill is not part of a multi-variant plugin.

---

## Dimension 2 — Description & Triggers (15%)

### Action-oriented name — Minor

The skill name follows a verb-noun or verb-object pattern.

- **PASS:** `manage-lexicon`, `create-dashboard`, `review-skill`.
- **WARN:** `deep-research` (noun-heavy but still clear).
- **FAIL:** `data-governance`, `analytics-helper`, `utils`.

### Positive trigger examples — Major

The description includes specific examples of when the skill should activate — user phrasings, keywords, or scenarios.

- **PASS:** "Use when the user asks why a metric changed, what's driving a trend, or requests a deep dive."
- **FAIL:** "Use when appropriate" or no trigger guidance.

### Negative trigger examples — Minor

The description includes explicit "Do NOT use for" cases that prevent false activation.

- **PASS:** "Do NOT use for: deleting data, general code review."
- **FAIL:** No negative examples.

### Plain-language explanation — Minor

The description explains what the skill does in simple words — no meta-commentary about how skills work or implementation internals.

- **PASS:** "Audits, scores, enriches, and cleans up Lexicon metadata for a Mixpanel project."
- **FAIL:** "This skill is a router that dispatches to sub-commands based on intent matching."

### Intent-based phrasing — Minor

The description is framed around user intent, not internal mechanics.

- **PASS:** "Use when the user asks to build, create, or design a dashboard."
- **FAIL:** "Executes a sequence of API calls to construct report objects."

### Precise terminology — Suggestion

Domain terms are either self-evident or defined in context.

- **PASS:** "Lexicon", "dashboard", "metric" — standard domain terms that need no definition.
- **FAIL:** "Runs the governor pipeline" without explaining what that means.

---

## Dimension 3 — Structure & Readability (15%)

### Top-down readable layout — Blocker

The skill reads coherently from top to bottom. Components and concepts are defined before they are referenced in execution steps. The recommended pattern is: abstract, then components, then execution.

- **PASS:** Abstract → Components (dimensions, scoring, severities) → Execution (steps 1-5). Each concept is defined before it is referenced.
- **WARN:** Mostly top-down but one or two forward references to concepts not yet explained.
- **FAIL:** Execution steps reference components or rules that appear later. Reader must jump around.

### Stable cross-references — Minor

References use titles or inline context — never line numbers, rule numbers, or positional references.

- **PASS:** "Write the audit log entry as described in the Behaviour rules section."
- **FAIL:** "See Rule 7", "per line 42", "as stated in item 3 above".

### Consistent rules — Major

Behaviour rules do not contradict each other. Each rule has one clear interpretation.

- **PASS:** "Show progress during batched writes, but do not narrate each individual step" — both rules coexist because the boundary is explicit.
- **FAIL:** "Execute silently" combined with "Show progress during writes" without clarifying what IS shown vs suppressed.

### Correct rule scoping — Major

General rules live in SKILL.md. Command-specific rules live in command files. No duplication.

- **PASS:** Exclusion list defined once in SKILL.md. `commands/enrich-and-tag.md` says "apply exclusions" without repeating the list.
- **FAIL:** The same instruction appears in SKILL.md and in 3 command files.
- **N/A:** Single-file skill.

### Lean file set — Minor

The skill directory does not contain README.md, CHANGELOG.md, or similar files when the information is evident from SKILL.md or git history.

- **PASS:** Skill directory contains only `SKILL.md` and `commands/`. No README.md or CHANGELOG.md.
- **WARN:** README.md exists but is very short (under 20 lines).
- **FAIL:** Meta-files that restate what SKILL.md already covers.

---

## Dimension 4 — DRY & Portability (20%)

### Centralised logic — Major

Shared instructions are centralised in SKILL.md or a single reference file. Command files do not repeat the same instructions.

- **PASS:** Confirmation flow defined in SKILL.md. Five command files all follow it without restating the steps.
- **WARN:** Minor duplication (1-2 lines) that does not cause maintenance burden.
- **FAIL:** The same multi-line instruction block appears in 2+ files.

### Engine-agnostic language — Blocker

Instructions describe intent and outcomes, not specific tool or API names. This makes the skill portable across AI engines.

- **PASS:** "List all projects in the workspace and show them in a table."
- **FAIL:** "Call the `list_projects` MCP tool." or "Use `mp_query_insights` with these parameters."

### Tool-docs stay in the tool — Major

The skill does not include files that re-document tool parameters, response formats, API schemas, or explain how to interpret tool responses. The agent already has tool descriptions.

- **PASS:** `references/` contains a scoring rubric with domain formulas — no tool parameter docs.
- **FAIL:** Files like "MCP Cheatsheet", "API Reference", "schema-reader.md", "response-format.md".

### Reference files contain non-obvious domain knowledge — Minor

Every file in `references/` adds domain-specific knowledge the agent cannot derive from tool descriptions or general training — scoring formulas, exclusion lists, templates with business logic.

- **PASS:** A reference file with domain-specific scoring formulas or exclusion lists based on product knowledge.
- **FAIL:** Reference files that explain general concepts the agent already knows.
- **N/A:** Skill has no reference files.

---

## Dimension 5 — Safety & Data Integrity (15%)

### Validate before building — Major

If the skill creates output based on data, it validates that the data exists and is meaningful before building. Probe queries, schema checks, or equivalent validation steps are present.

- **PASS:** "Run probe queries to confirm data exists before building."
- **FAIL:** Skill builds output assuming inputs exist without checking.
- **N/A:** Skill does not create data-dependent output.

### Preview before writes — Major

If the skill mutates data, it shows a preview of what will change and requires explicit confirmation.

- **PASS:** "Show a before/after table of all changes. Type CONFIRM to apply or EXPORT to save as JSON."
- **FAIL:** Writes directly without showing what will change.
- **N/A:** Skill is read-only.

### Efficient confirmations — Minor

For grouped writes, the skill uses a single confirmation for the group — not one per sub-operation.

- **PASS:** "Preview all 3 groups (events, tags, properties), then one CONFIRM applies everything."
- **WARN:** One confirmation per logical group — acceptable if groups are meaningfully different.
- **FAIL:** One confirmation per individual item in a batch.
- **N/A:** Skill is read-only.

### Simple error handling — Minor

Error handling is clear and simple. Does not over-engineer retry logic that the underlying tools already handle.

- **PASS:** "If a command cannot complete, explain what failed and what the user can try."
- **FAIL:** Multi-step retry flowcharts or error-code-specific handling that duplicates tool-level retry logic.

---

## Dimension 6 — UX & Communication (10%)

### Actionable output — Minor

The skill's output is useful to the user: results, progress, errors, confirmations, and brief context about what comes next. Avoid verbose internal narration that adds no value.

- **PASS:** "Scoring 42 events... ✅ Done. Score: 78%. Want to bulk-enrich the gaps?"
- **FAIL:** Multi-paragraph explanations of internal reasoning before every step.

### Human-friendly identifiers — Minor

The skill supports human-friendly identifiers (names, not just system IDs).

- **PASS:** "Accept project by name or ID. Match by ID first, then by case-insensitive name."
- **FAIL:** "Enter the project_id to continue."
- **N/A:** Skill does not take entity identifiers as input.

---

## Dimension 7 — Domain Expertise (10%)

### Scoped before execution — Minor

The skill scopes the task (what project, what goal, what constraints) before executing. Ambiguity is resolved through clarifying questions, not assumptions.

- **PASS:** Phase 1 confirms project, events, and scope before running queries.
- **FAIL:** Skill dives into technical operations without confirming scope first.

### Claims are verifiable — Major

The skill does not make assertions about product capabilities without qualification. Claims are either self-evident, cite a source, or are marked as assumptions.

- **PASS:** "Check the current docs for rate limits" or claims that are self-evident from the product.
- **FAIL:** "The SDK automatically retries failed events" stated as fact without source or qualification.

### Defaults are sourced — Major

Default values and behaviours mentioned in the skill reference official docs or are marked "verify current."

- **PASS:** "Default rollout is 0% (verify current)" or references official docs.
- **FAIL:** "Default rollout is 100%" stated as fact when the actual default may differ.

### Qualified recommendations — Minor

Recommendations include necessary context. No blanket advice without considering the user's situation.

- **PASS:** "Server-side changes can go faster — if there is sufficient monitoring in place."
- **FAIL:** "Always roll out to 100% immediately."

---

## Dimension 8 — Content Quality (5%)

### Adds what the agent lacks — Minor

The skill contains domain-specific conventions, non-obvious edge cases, or product-specific workflows — not general concepts the agent already knows.

- **PASS:** Exclusion lists based on product knowledge, domain-specific scoring formulas, project-specific validation patterns.
- **FAIL:** Explains what events are, how APIs work, or generic best practices the agent can derive from training.

### Defaults, not menus — Suggestion

When multiple approaches could work, the skill picks a default and mentions alternatives briefly.

- **PASS:** "Use pdfplumber. For scanned documents, fall back to pdf2image with pytesseract."
- **FAIL:** "You can use library A, B, C, or D..." presented as equal options.
- **N/A:** Skill does not present tool/approach choices.


### Concise — Minor

Every section earns its place. No verbose explanations of things the agent already knows.

- **PASS:** `create-dashboard` covers its full workflow in 85 lines — no filler, every section drives execution.
- **WARN:** Some sections are longer than needed but contain useful content.
- **FAIL:** Large blocks restating obvious concepts.

---

## Scoring Formula

### Within each dimension

```
dimension_score = sum(check_scores) / count(applicable_checks)
```

Where: PASS=1.0, WARN=0.5, FAIL=0.0. All checks have equal weight. N/A checks excluded from both numerator and denominator.

### Overall score

```
overall = (D1 x 0.10) + (D2 x 0.15) + (D3 x 0.15) + (D4 x 0.20)
        + (D5 x 0.15) + (D6 x 0.10) + (D7 x 0.10) + (D8 x 0.05)
```

### Blocker overrides

Apply after computing the score:
- "Valid frontmatter" FAIL → score capped at 0%
- "Engine-agnostic language" FAIL → score capped at 74%
