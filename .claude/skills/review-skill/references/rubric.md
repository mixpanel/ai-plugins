# Review Rubric

## Contents

- Dimension 1 — Spec Compliance (10%)
- Dimension 2 — Description & Triggers (15%)
- Dimension 3 — Structure & Readability (15%)
- Dimension 4 — DRY & Portability (20%)
- Dimension 5 — Safety & Data Integrity (10%)
- Dimension 6 — UX & Communication (10%)
- Dimension 7 — Domain Expertise (10%)
- Dimension 8 — Content Quality (10%)
- Scoring Formula

Apply the **Scoring discipline** from SKILL.md to every check: the burden of proof is on the skill, ties go to the lower rating, and every non-PASS rating must quote concrete evidence. WARN is for genuine partial compliance only — never a way to soften a FAIL.

## Dimension 1 — Spec Compliance (10%)

### Valid frontmatter — Major

SKILL.md starts with valid YAML frontmatter containing `name` and `description`.

- **PASS:** `---\nname: format-sql\ndescription: Formats SQL queries to the project style.\n---`
- **FAIL:** Missing frontmatter, invalid YAML, or missing required fields. Override: score capped at 0%.

### Name format and match — Major

`name` is 1-64 chars, lowercase alphanumeric + hyphens, no leading/trailing/consecutive hyphens. Must match the parent directory name exactly.

- **PASS:** `name: generate-changelog` in directory `generate-changelog/`.
- **FAIL:** `name: Generate_Changelog` (uppercase, underscore) or name does not match directory. Override: score capped at 40%.

### Description length — Major

`description` is 1-1024 characters and non-empty.

- **PASS:** A 150-300 character description that covers both what the skill does and when to use it.
- **WARN:** Under 40 characters, or covers only what it does with no "when to use" guidance.
- **FAIL:** Empty, or exceeds 1024 characters.

### Line limit

Main SKILL.md is lean. Brevity is a quality signal, not just a spec limit.

- **PASS:** SKILL.md at 200 lines or fewer.
- **WARN:** 201-400 lines.
- **FAIL:** Over 400 lines.

### Multi-variant sync — Major

If the skill is duplicated across multiple plugin variants (regional, partner, white-label), every shared file must be byte-identical across variants.

- **PASS:** Diffing the same skill across all variant directories returns no differences.
- **FAIL:** Any file differs between variants.
- **N/A:** Skill exists in exactly one location.

---

## Dimension 2 — Description & Triggers (15%)

### Action-oriented name

The skill name leads with a verb and signals an action, not a thing. A gerund (`processing-pdfs`) is fine but not required; a verb-noun form (`review-skill`, `format-sql`) is equally good.

- **PASS:** `review-skill`, `format-sql`, `generate-changelog`, `processing-pdfs` — any verb-led form.
- **WARN:** A clear but noun-led name such as `changelog-builder`.
- **FAIL:** `helper`, `utils`, `data-tools`, or any name that does not signal an action.

### Positive trigger examples — Major

The description includes specific examples of when the skill should activate — concrete user phrasings, keywords, or scenarios. Generic activation language is a FAIL. The description is how the skill is found, so it should carry the words a user would actually type — symptoms, synonyms, and literal error strings — not just tidy phrasings.

- **PASS:** "Use when the user asks to format a query, clean up SQL, or normalise indentation in a `.sql` file."
- **WARN:** A single vague scenario with no example phrasing.
- **FAIL:** "Use when appropriate", "Use for SQL tasks", or no trigger guidance.

### Negative trigger examples

The description includes explicit "Do NOT use for" cases that prevent false activation. Useful for niche cases, but it can be skipped for broad skills.

- **PASS:** "Do NOT use for: writing new queries from scratch, reviewing query performance."
- **FAIL:** No negative examples.

### Plain-language explanation

The description explains what the skill does in simple words — no meta-commentary about how skills work or implementation internals.

- **PASS:** "Formats and normalises SQL queries to match the project's style rules."
- **FAIL:** "This skill is a router that dispatches to sub-commands based on intent matching."

### Intent-based phrasing — Major

The description is framed around user intent, not internal mechanics.

- **PASS:** "Use when the user asks to build, create, or design a report."
- **FAIL:** "Executes a sequence of API calls to construct report objects."

### Precise terminology — Major

Domain terms are either self-evident or defined in context.

- **PASS:** Standard, self-evident terms used in their ordinary sense.
- **FAIL:** "Runs the governor pipeline" or any coined term used without explanation.

---

## Dimension 3 — Structure & Readability (15%)

### Top-down readable layout — Major

The skill reads coherently from top to bottom. Components and concepts are defined before they are referenced in execution steps. The recommended pattern is: abstract, then components, then execution.

- **PASS:** Abstract → Components → Execution. Each concept is defined before it is referenced.
- **WARN:** Mostly top-down but with one forward reference to a concept not yet explained.
- **FAIL:** Execution steps reference components or rules that appear later; the reader must jump around. Override: score capped at 74%.

### Stable cross-references — Major

References use titles or inline context — never line numbers, rule numbers, or positional references that break when the file changes.

- **PASS:** "Write the audit log entry as described in the Behaviour rules section."
- **FAIL:** "See Rule 7", "per line 42", "as stated in item 3 above".

### Consistent rules — Major

Behaviour rules do not contradict each other. Each rule has exactly one clear interpretation.

- **PASS:** "Show progress during batched writes, but do not narrate each individual step" — both coexist because the boundary is explicit.
- **FAIL:** "Execute silently" combined with "Show progress during writes" without clarifying what IS shown vs suppressed.

### Correct rule scoping — Major

General rules live in SKILL.md. Command-specific rules live in command files. No duplication.

- **PASS:** Exclusion list defined once in SKILL.md. A command file says "apply the exclusions" without repeating the list.
- **FAIL:** The same instruction appears in SKILL.md and in one or more command files.
- **N/A:** Single-file skill.

### Lean file set

The skill directory does not contain README.md, CHANGELOG.md, or similar files when the information is evident from SKILL.md or git history.

- **PASS:** Skill directory contains only `SKILL.md` and the directories it actually needs (`commands/`, `references/`).
- **WARN:** A README.md exists but is genuinely necessary (e.g. build steps for a bundled script) and under 20 lines.
- **FAIL:** Any meta-file that restates what SKILL.md or git history already covers.

### Long reference files have a table of contents

Any reference file over 100 lines opens with a `## Contents` block listing its sections, so a partial read still reveals the full scope.

- **PASS:** A 300-line `references/rubric.md` that starts with a Contents list of every dimension.
- **FAIL:** A 250-line reference file with no contents block — a partial read misses half of it.
- **N/A:** No reference file exceeds 100 lines.

### References are one level deep

Every companion file links directly from SKILL.md; no reference points onward to a further file the reader must chase, since nested files get read only partially.

- **PASS:** SKILL.md links to `rubric.md` and `examples.md`; neither links onward to a third file.
- **FAIL:** SKILL.md → `workflow.md` → `checks.md`. The nested file may be read only partially.
- **N/A:** Single-file skill.

---

## Dimension 4 — DRY & Portability (20%)

### Centralised logic — Major

Shared instructions are centralised in SKILL.md or a single reference file. Command or reference files do not repeat the same instructions.

- **PASS:** Confirmation flow defined once in SKILL.md; every command file follows it without restating the steps.
- **WARN:** A single shared line (under 2 lines) duplicated once, with no maintenance risk.
- **FAIL:** The same multi-line instruction block appears in two or more files.

### Engine-agnostic language — Major

Instructions describe intent and outcomes, not specific tool, function, or API names. This makes the skill portable across AI engines.

- **PASS:** "List every project in the workspace and show them in a table."
- **WARN:** Mostly intent-based, but names a tool in a single aside.
- **FAIL:** Steps instruct calling named tools/functions/endpoints (e.g. "Call the `list_projects` tool", "POST to `/v2/reports`"). Override: score capped at 60%.

### Tool-docs stay in the tool — Major

The skill does not include files that re-document tool parameters, response formats, API schemas, or how to interpret tool responses. The agent already has tool descriptions. An MCP server advertises its own input/output schema — the skill must not restate the shape of a tool's arguments or its response. Likewise an external dependency (a package, a CLI, an API) is referenced by name and pointed at its own docs, not re-documented.

- **PASS:** "Call the search tool and use the results" — no schema restated; `references/` holds a scoring rubric or domain formulas, not tool parameter docs.
- **FAIL:** A "Tool I/O reference" listing each MCP tool's parameters and JSON response shape; files like "Tool Cheatsheet", "API Reference", "schema-reader.md", "response-format.md"; or a file re-explaining a library's API the agent already knows.

### Reference files contain non-obvious domain knowledge — Major

Every file in `references/` adds domain-specific knowledge the agent cannot derive from tool descriptions or general training — scoring formulas, exclusion lists, templates with embedded business logic. A reference file that restates general knowledge is dead weight.

- **PASS:** A reference file with domain-specific formulas, exclusion lists, or product-specific rules.
- **FAIL:** Reference files that explain general concepts the agent already knows.
- **N/A:** Skill has no reference files.

---

## Dimension 5 — Safety & Data Integrity (10%)

### Validate before building — Major

If the skill creates output based on data, it validates that the data exists and is meaningful before building. Probe queries, schema checks, or equivalent validation steps are present.

- **PASS:** "Confirm the input exists and is non-empty before building."
- **FAIL:** Skill builds output assuming inputs exist without checking.
- **N/A:** Skill does not create data-dependent output.

### Preview before writes — Major

If the skill mutates data or files, it shows a preview of what will change and requires explicit confirmation.

- **PASS:** "Show a before/after table of all changes. Type CONFIRM to apply or EXPORT to save as JSON."
- **FAIL:** Writes directly without showing what will change — especially when the write is destructive or irreversible.
- **N/A:** Skill is read-only.

### Efficient confirmations

For grouped writes, the skill uses a single confirmation for the group — not one per sub-operation.

- **PASS:** "Preview all groups, then a single CONFIRM applies everything."
- **WARN:** One confirmation per logical group — acceptable only if the groups are meaningfully different.
- **FAIL:** One confirmation per individual item in a batch.
- **N/A:** Skill is read-only.

### Simple error handling

Error handling is clear and simple. It does not over-engineer retry logic that the underlying tools already handle.

- **PASS:** "If a step cannot complete, explain what failed and what the user can try."
- **FAIL:** Multi-step retry flowcharts or error-code-specific handling that duplicates tool-level retry logic.

---

## Dimension 6 — UX & Communication (10%)

### Actionable output

The skill's output is useful: results, progress, errors, confirmations, and brief context about what comes next. Avoid verbose internal narration that adds no value.

- **PASS:** "Scanned 42 files... Done. 3 issues found. Want the fix plan?"
- **FAIL:** Multi-paragraph explanations of internal reasoning before every step.

### Human-friendly identifiers

The skill supports human-friendly identifiers (names, not just system IDs).

- **PASS:** "Accept the target by name or ID. Match by ID first, then by case-insensitive name."
- **FAIL:** "Enter the numeric ID to continue."
- **N/A:** Skill does not take entity identifiers as input.

---

## Dimension 7 — Domain Expertise (10%)

### Scoped before execution

The skill scopes the task (what target, what goal, what constraints) before executing. Ambiguity is resolved through clarifying questions, not assumptions.

- **PASS:** A first phase confirms target, scope, and constraints before doing work.
- **FAIL:** Skill dives into operations without confirming scope first.

### Claims are verifiable — Major

The skill does not assert product or tool capabilities without qualification. Claims are either self-evident, cite a source, or are marked as assumptions.

- **PASS:** "Check the current docs for limits" or claims self-evident from the domain.
- **FAIL:** "The framework automatically retries failed requests" stated as fact without source or qualification.

### Defaults are sourced — Major

Default values and behaviours mentioned in the skill cite official docs or are marked "verify current".

- **PASS:** "Default timeout is 30s (verify current)" or a reference to official docs.
- **FAIL:** "The default timeout is 30s" stated as fact when the actual default may differ.

### Qualified recommendations

Recommendations include necessary context. No blanket advice that ignores the user's situation.

- **PASS:** "Changes can ship faster — if there is sufficient monitoring in place."
- **FAIL:** "Always apply changes immediately."

### Instruction freedom matches task fragility

The skill matches how prescriptive it is to how fragile the task is. Think of a narrow bridge with cliffs (one safe path → low freedom) versus an open field (many paths → high freedom):

- **High freedom** (prose, heuristics) when several approaches are valid and the right one depends on context — e.g. "analyse the structure, check edge cases, suggest improvements".
- **Medium freedom** (a template or parameterised script) when a preferred pattern exists but some variation is fine.
- **Low freedom** (an exact script, few or no parameters) when the task is fragile, destructive, or order-critical — e.g. "Run exactly this; do not add flags."

Score against this fit:

- **PASS:** A judgement-heavy step is left to prose; a destructive migration gives the exact command and forbids modifying it.
- **FAIL:** A fragile or irreversible operation written as loose prose (too much freedom), or a simple judgement call locked into a rigid script (too little).

---

## Dimension 8 — Content Quality (10%)

### Adds what the agent lacks — Major

The skill contains domain-specific conventions, non-obvious edge cases, or project-specific workflows — not general concepts the agent already knows. A skill that only restates general knowledge has no reason to exist.

- **PASS:** Exclusion lists based on project knowledge, domain-specific formulas, project-specific validation patterns.
- **FAIL:** Explains general concepts, common tool usage, or generic best practices the agent can derive from training.

### Defaults, not menus

When multiple approaches could work, the skill picks a default and mentions alternatives briefly.

- **PASS:** "Use approach A. For the scanned-document case, fall back to approach B."
- **FAIL:** "You can use A, B, C, or D..." presented as equal options.
- **N/A:** Skill does not present tool/approach choices.

### Concise

Every section earns its place. No verbose explanations of things the agent already knows.

- **PASS:** A skill that covers its full workflow with no filler — every section drives execution.
- **WARN:** Some sections are longer than needed but contain useful content.
- **FAIL:** Large blocks restating obvious concepts.

### Reusable reference, not narrative or dated

The skill reads as a reusable technique, not a story about one session, and carries no expiring content. Dated material lives in an "old patterns" aside.

- **PASS:** "Exclude test accounts before aggregating."
- **FAIL:** "In the 2025-10-03 run we found empty dirs broke this" (narrative); "before August 2025 use the v1 API" (dated — belongs in an old-patterns aside).

---

## Scoring Formula

### Within each dimension

```
dimension_score = sum(check_scores) / count(applicable_checks)
```

Where: PASS=1.0, WARN=0.5, FAIL=0.0. All checks have equal weight. N/A checks are excluded from both numerator and denominator.

### Overall score

```
overall = (D1 x 0.10) + (D2 x 0.15) + (D3 x 0.15) + (D4 x 0.20)
        + (D5 x 0.10) + (D6 x 0.10) + (D7 x 0.10) + (D8 x 0.10)
```

### Score caps

Apply after computing the score. The lowest applicable cap wins.

- "Valid frontmatter" FAIL → capped at 0%.
- "Name format and match" FAIL → capped at 40%.
- "Engine-agnostic language" FAIL → capped at 60%.
- "Top-down readable layout" FAIL → capped at 74%.