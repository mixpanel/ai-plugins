---
name: review-skill
description: >
  Reviews an Agent Skills skill against a weighted quality rubric and produces
  a score (0-100%) with actionable issues. Use when asked to review, score,
  audit, or evaluate a skill or to check quality. Triggers on: "review this skill", "score the skill",
  "audit skill quality", "is this skill ready to merge".
license: Apache-2.0
---

# Skill Review

Reviews a skill's quality against a rubric derived from the Agent Skills specification, team review standards, and community best practices. Produces a percentage score, letter grade, and a prioritised list of issues to fix.

This is a read-only, single-skill review. Do not modify the skill being reviewed.

---

# Components

## Rubric dimensions

The rubric evaluates 8 weighted dimensions. Read `references/rubric.md` for the full check definitions when running the evaluation.

| # | Dimension | Weight |
|---|-----------|--------|
| 1 | Spec Compliance | 10% |
| 2 | Description & Triggers | 15% |
| 3 | Structure & Readability | 15% |
| 4 | DRY & Portability | 20% |
| 5 | Safety & Data Integrity | 15% |
| 6 | UX & Communication | 10% |
| 7 | Domain Expertise | 10% |
| 8 | Content Quality | 5% |

## Scoring

Each check is scored **PASS** (1.0), **WARN** (0.5), **FAIL** (0.0), or **N/A** (excluded). Some checks count double (marked in the rubric). See `references/rubric.md` for the full scoring formula and blocker overrides.

| Grade | Score | Meaning |
|-------|-------|---------|
| A | 90-100% | Ready for merge |
| B | 75-89% | Minor issues — address before merge |
| C | 60-74% | Significant issues — needs rework |
| D | 40-59% | Major structural problems |
| F | 0-39% | Fundamental redesign needed |

## Issue severities

| Severity | Meaning |
|----------|---------|
| Blocker | Cannot merge — spec violation or portability failure |
| Major | Should not merge — causes user harm, data risk, or quality regression |
| Minor | Should fix — quality or polish issue |
| Suggestion | Optional improvement |

## Output format

The report must include, in order:
1. **Header** — skill name, overall score %, letter grade
2. **Files reviewed** — each file with line count
3. **Dimension scores** — each dimension with score %, visual bar, and weight
4. **Issues** — sorted by severity (blockers first), each with: check ID, file/location, what was found, how to fix
5. **Summary** — issue counts by severity

---

# Execution

Follow these steps in order.

## 1. Locate and read the skill

Accept the skill by name (search `plugins/*/skills/` and `skills/`) or by path. Read every file in the skill directory tree. Record file list and line counts. Flag unexpected meta-documentation files (README.md, CHANGELOG.md).

## 2. Load rubric and evaluate

Read `references/rubric.md` for the full check definitions.

For each dimension, evaluate every check:
1. Determine if the check applies (mark N/A if not — e.g., mutation checks for read-only skills, hub-spoke checks for single-file skills).
2. Score the check: PASS, WARN, or FAIL.
3. Record a brief justification and the file/location where the issue was found.
4. If the check fails, classify the issue severity (Blocker, Major, Minor, Suggestion).

## 3. Compute scores

1. For each dimension: compute the weighted average of applicable checks (excluding N/A).
2. Compute the overall score: weighted sum of dimension scores using the weights in the dimension table.
3. Determine the letter grade from the score.
4. Apply blocker overrides if applicable.

## 4. Present the report

Output the report using the format above. Issues are sorted by severity (blockers first), then by dimension order within each severity level.

## 5. Offer to help fix

After the report, offer to generate a prioritised fix plan if issues were found.
