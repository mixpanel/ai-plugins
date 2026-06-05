# Review Rubric

Checks marked **(x2)** count double in their dimension's weighted average.

## Severity reference

| Check | Severity | Override |
|-------|----------|----------|
| C1.1 | Blocker | Auto F |
| C1.2 | Blocker | |
| C1.3 | Major | |
| C1.4 | Minor | |
| C1.5 | Minor | |
| C1.6 | Major | |
| C2.1 | Minor | |
| C2.2 | Major | |
| C2.3 | Minor | |
| C2.4 | Minor | |
| C2.5 | Minor | |
| C2.6 | Suggestion | |
| C3.1 | Major | |
| C3.2 | Minor | |
| C3.3 | Major | |
| C3.4 | Major | |
| C3.5 | Minor | |
| C4.1 | Major | |
| C4.2 | Blocker | Grade capped at C |
| C4.3 | Major | |
| C4.4 | Minor | |
| C5.1 | Major | |
| C5.2 | Major | |
| C5.3 | Minor | |
| C5.4 | Minor | |
| C5.5 | Minor | |
| C5.6 | Minor | |
| C6.1 | Minor | |
| C6.2 | Minor | |
| C6.3 | Minor | |
| C6.4 | Minor | |
| C7.1 | Minor | |
| C7.2 | Major | |
| C7.3 | Major | |
| C7.4 | Minor | |
| C7.5 | Suggestion | |
| C8.1 | Minor | |
| C8.2 | Suggestion | |
| C8.3 | Suggestion | |
| C8.4 | Minor | |

---

## Dimension 1 — Spec Compliance (10%)

### C1.1 Valid frontmatter (x2)

SKILL.md starts with valid YAML frontmatter containing `name` and `description`.

- **FAIL:** Missing frontmatter, invalid YAML, or missing required fields.

### C1.2 Name format and match

`name` is 1-64 chars, lowercase alphanumeric + hyphens, no leading/trailing/consecutive hyphens. Must match the parent directory name.

- **FAIL:** `name: Data_Governance` (uppercase, underscore) or name does not match directory.

### C1.3 Description length

`description` is 1-1024 characters and non-empty.

- **WARN:** Under 20 characters (likely too vague).
- **FAIL:** Empty or exceeds 1024 characters.

### C1.4 License declared

`license` field present in frontmatter, set to `Apache-2.0` (per repository convention).

- **WARN:** License field present but not Apache-2.0.
- **FAIL:** No license field.

### C1.5 Line limit

Main SKILL.md is 500 lines or fewer.

- **WARN:** 501-600 lines.
- **FAIL:** >600 lines.

### C1.6 Multi-variant sync

If the skill is duplicated across multiple plugin variants (regional, partner, white-label), files must be identical across variants.

- **FAIL:** Files differ between variants.
- **N/A:** Skill is not part of a multi-variant plugin.

---

## Dimension 2 — Description & Triggers (15%)

### C2.1 Action-oriented name

The skill name follows a verb-noun or verb-object pattern.

- **PASS:** `manage-lexicon`, `create-dashboard`, `review-skill`.
- **WARN:** `deep-research` (noun-heavy but still clear).
- **FAIL:** `data-governance`, `analytics-helper`, `utils`.

### C2.2 Positive trigger examples (x2)

The description includes specific examples of when the skill should activate — user phrasings, keywords, or scenarios.

- **PASS:** "Use when the user asks why a metric changed, what's driving a trend, or requests a deep dive."
- **FAIL:** "Use when appropriate" or no trigger guidance.

### C2.3 Negative trigger examples (x2)

The description includes explicit "Do NOT use for" cases that prevent false activation.

- **PASS:** "Do NOT use for: deleting data, general code review."
- **FAIL:** No negative examples.

### C2.4 Plain-language explanation

The description explains what the skill does in simple words — no meta-commentary about how skills work or implementation internals.

- **FAIL:** "This skill is a router that dispatches to sub-commands based on intent matching."

### C2.5 Intent-based phrasing

The description is framed around user intent, not internal mechanics.

- **PASS:** "Use when the user asks to build, create, or design a dashboard."
- **FAIL:** "Executes a sequence of API calls to construct report objects."

### C2.6 Precise terminology

Domain terms are either self-evident or defined in context.

- **FAIL:** "Runs the governor pipeline" without explaining what that means.

---

## Dimension 3 — Structure & Readability (15%)

### C3.1 Top-down readable layout (x2)

The skill reads coherently from top to bottom. Components and concepts are defined before they are referenced in execution steps. The recommended pattern is: abstract, then components, then execution.

- **WARN:** Mostly top-down but one or two forward references to concepts not yet explained.
- **FAIL:** Execution steps reference components or rules that appear later. Reader must jump around.

### C3.2 No brittle cross-references

References use titles or inline context — never line numbers, rule numbers, or positional references.

- **PASS:** "Write the audit log entry as described in the Behaviour rules section."
- **FAIL:** "See Rule 7", "per line 42", "as stated in item 3 above".

### C3.3 No contradictory rules

Behaviour rules do not contradict each other. Each rule has one clear interpretation.

- **FAIL:** "Execute silently" combined with "Show progress during writes" without clarifying what IS shown vs suppressed.

### C3.4 Correct rule scoping

General rules live in SKILL.md. Command-specific rules live in command files. No duplication.

- **FAIL:** The same instruction appears in SKILL.md and in 3 command files.
- **N/A:** Single-file skill.

### C3.5 No unnecessary meta-documentation

The skill directory does not contain README.md, CHANGELOG.md, or similar files when the information is evident from SKILL.md or git history.

- **WARN:** README.md exists but is very short (under 20 lines).
- **FAIL:** Meta-files that restate what SKILL.md already covers.

---

## Dimension 4 — DRY & Portability (20%)

### C4.1 No duplicated logic (x2)

Shared instructions are centralised in SKILL.md or a single reference file. Command files do not repeat the same instructions.

- **WARN:** Minor duplication (1-2 lines) that does not cause maintenance burden.
- **FAIL:** The same multi-line instruction block appears in 2+ files.

### C4.2 Engine-agnostic language (x2)

Instructions describe intent and outcomes, not specific tool or API names. This makes the skill portable across AI engines.

- **PASS:** "List all projects in the workspace and show them in a table."
- **FAIL:** "Call the `list_projects` MCP tool." or "Use `mp_query_insights` with these parameters."

### C4.3 No tool-documentation files

The skill does not include files that re-document tool parameters, response formats, API schemas, or explain how to interpret tool responses. The agent already has tool descriptions.

- **FAIL:** Files like "MCP Cheatsheet", "API Reference", "schema-reader.md", "response-format.md".

### C4.4 Reference files contain non-obvious domain knowledge

Every file in `references/` adds domain-specific knowledge the agent cannot derive from tool descriptions or general training — scoring formulas, exclusion lists, templates with business logic.

- **FAIL:** Reference files that explain general concepts the agent already knows.
- **N/A:** Skill has no reference files.

---

## Dimension 5 — Safety & Data Integrity (15%)

### C5.1 Validate before building (x2)

If the skill creates output based on data, it validates that the data exists and is meaningful before building. Probe queries, schema checks, or equivalent validation steps are present.

- **PASS:** "Run probe queries to confirm data exists before building."
- **FAIL:** Skill builds output assuming inputs exist without checking.
- **N/A:** Skill does not create data-dependent output.

### C5.2 Preview before writes (x2)

If the skill mutates data, it shows a preview of what will change and requires explicit confirmation.

- **FAIL:** Writes directly without showing what will change.
- **N/A:** Skill is read-only.

### C5.3 Efficient confirmations

For grouped writes, the skill uses a single confirmation for the group — not one per sub-operation.

- **WARN:** One confirmation per logical group — acceptable if groups are meaningfully different.
- **FAIL:** One confirmation per individual item in a batch.
- **N/A:** Skill is read-only.

### C5.4 Simple error handling

Error handling is clear and simple. Does not over-engineer retry logic that the underlying tools already handle.

- **FAIL:** Multi-step retry flowcharts or error-code-specific handling that duplicates tool-level retry logic.

### C5.5 Audit trail for mutations

If the skill performs write operations, it logs what was changed for traceability.

- **WARN:** Mentions logging but does not specify format or location.
- **FAIL:** No audit trail for destructive operations.
- **N/A:** Skill is read-only.

### C5.6 Safe context switching

The skill does not change context (project, scope) unless the user explicitly asks.

- **FAIL:** "Never switch projects mid-session" (too rigid) or no guidance at all (too loose).
- **N/A:** Skill does not have persistent context.

---

## Dimension 6 — UX & Communication (10%)

### C6.1 No phase narration

The skill does not announce what it is about to do. It shows actionable output: results, progress, errors, confirmations.

- **FAIL:** "First I will analyze your data, then I will..." pattern throughout.

### C6.2 Parallelism declared

The skill explicitly states whether it can be invoked in parallel or must run as a single session.

- **N/A:** Skill is stateless and single-operation (no persistent context or file mutations).

### C6.3 Session state contracts

If the skill uses a hub-spoke pattern with multiple commands, each command declares what session state it reads and writes.

- **WARN:** Session state exists but is not formally declared (no vocabulary table or explicit key list).
- **FAIL:** Commands implicitly share state with no declaration.
- **N/A:** Single-file skill or no command pattern.

### C6.4 Human-friendly identifiers

The skill supports human-friendly identifiers (names, not just system IDs).

- **PASS:** "Accept project by name or ID. Match by ID first, then by case-insensitive name."
- **FAIL:** "Enter the project_id to continue."
- **N/A:** Skill does not take entity identifiers as input.

---

## Dimension 7 — Domain Expertise (10%)

### C7.1 Business context first

The skill understands the user's goal before diving into technical execution. Discovery or scoping happens before action.

- **FAIL:** Skill jumps straight into technical operations without understanding the goal.

### C7.2 Claims are verifiable

The skill does not make assertions about product capabilities without qualification. Claims are either self-evident, cite a source, or are marked as assumptions.

- **FAIL:** "The SDK automatically retries failed events" stated as fact without source or qualification.

### C7.3 Defaults are sourced

Default values and behaviours mentioned in the skill reference official docs or are marked "verify current."

- **FAIL:** "Default rollout is 100%" stated as fact when the actual default may differ.

### C7.4 Qualified recommendations

Recommendations include necessary context. No blanket advice without considering the user's situation.

- **PASS:** "Server-side changes can go faster — if there is sufficient monitoring in place."
- **FAIL:** "Always roll out to 100% immediately."

### C7.5 Sharp edges highlighted

Common mistakes and frequently misunderstood concepts are highlighted where relevant.

- **WARN:** Skill handles edge cases but does not explicitly call them out.

---

## Dimension 8 — Content Quality (5%)

### C8.1 Adds what the agent lacks

The skill contains domain-specific conventions, non-obvious edge cases, or product-specific workflows — not general concepts the agent already knows.

- **FAIL:** Explains what events are, how APIs work, or generic best practices the agent can derive from training.

### C8.2 Defaults, not menus

When multiple approaches could work, the skill picks a default and mentions alternatives briefly.

- **FAIL:** "You can use library A, B, C, or D..." presented as equal options.
- **N/A:** Skill does not present tool/approach choices.

### C8.3 Prescriptiveness matches fragility

The skill is prescriptive for fragile operations and flexible for creative work.

- **FAIL:** Every step is rigidly prescribed even when the task tolerates variation, or fragile operations are loosely described.

### C8.4 Concise

Every section earns its place. No verbose explanations of things the agent already knows.

- **WARN:** Some sections are longer than needed but contain useful content.
- **FAIL:** Large blocks restating obvious concepts.

---

## Scoring Formula

### Within each dimension

```
dimension_score = sum(check_score x check_weight) / sum(check_weight)
```

Where: PASS=1.0, WARN=0.5, FAIL=0.0. Weight is 2 for (x2) checks, 1 for others. N/A checks excluded from both numerator and denominator.

### Overall score

```
overall = (D1 x 0.10) + (D2 x 0.15) + (D3 x 0.15) + (D4 x 0.20)
        + (D5 x 0.15) + (D6 x 0.10) + (D7 x 0.10) + (D8 x 0.05)
```

### Blocker overrides

Apply after computing the grade (A=90-100, B=75-89, C=60-74, D=40-59, F=0-39):
- C1.1 FAIL → automatic F
- C4.2 FAIL → grade capped at C
