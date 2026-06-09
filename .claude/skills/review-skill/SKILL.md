---
name: review-skill
description: >
  Reviews an Agent Skills skill against a strict, weighted quality rubric and
  produces a score (0-100%) with actionable issues. Use when asked to review,
  score, audit, or evaluate a skill or to check quality. Triggers on: "review
  this skill", "score the skill", "audit skill quality", "is this skill ready to
  merge". Do NOT use for general code review, reviewing pull requests of
  application code, or reviewing prompts that are not Agent Skills.
license: Apache-2.0
---

# Skill Review

Reviews a skill's quality against a rubric derived from the Agent Skills specification, team review standards, and community best practices. Produces a percentage score and a prioritised list of issues to fix.

This is a read-only, single-skill review. Do not modify the skill being reviewed.

The bar is high. A skill that merely "works" is not good enough — it must be portable, lean, unambiguous, and safe. Score conservatively (see Scoring discipline). Most first-draft skills should not score above 75%.

Conciseness is a first-order concern, not a nicety: every token a skill loads competes with live conversation context. Assume the agent is already capable — a skill should keep only what the agent cannot derive, and cut what it already knows.

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
| 5 | Safety & Data Integrity | 10% |
| 6 | UX & Communication | 10% |
| 7 | Domain Expertise | 10% |
| 8 | Content Quality | 10% |

## Scoring

Each check is scored **PASS** (1.0), **WARN** (0.5), **FAIL** (0.0), or **N/A** (excluded). All checks have equal weight within their dimension. See `references/rubric.md` for the full scoring formula and score caps.

| Score | Meaning |
|-------|---------|
| 95-100% | Ready for merge |
| 85-94% | Minor issues — address before merge |
| 70-84% | Significant issues — needs rework |
| 50-69% | Major structural problems |
| 0-49% | Fundamental redesign needed |

## Scoring discipline

The score must reflect a demanding reviewer, not a generous one. **Adopt the stance of a seasoned editor or investigative journalist:** assume the author is beside you and will push back, so go after the single weakest claim, not the average. Nothing earns praise by default; the skill earns each PASS. Apply these rules to every check:

- **Burden of proof is on the skill.** Score PASS only when the skill clearly and explicitly meets the check. Absence of evidence is not a PASS.
- **When uncertain between two ratings, pick the lower one.** Ambiguous → WARN, not PASS. Partially met → FAIL, not WARN, unless the gap is trivial.
- **WARN is for genuine partial compliance**, not "close enough". Do not use WARN to avoid giving a FAIL.
- **One real defect is enough to FAIL its check.** Do not average away a clear violation because the rest of the skill is good.
- **Quote the evidence.** Every non-PASS rating must cite the specific file and text that triggered it. A rating with no concrete evidence is invalid — re-score it.

## Issues

A check is tagged **Major** or left untagged. Major issues are the must-fix findings and carry equal priority — there is no ranking among them. Untagged checks are smaller quality findings.

## Output format

The report must include, in order:
1. **Header** — skill name, overall score %, one-line verdict from the score band
2. **Files reviewed** — each file with line count
3. **Dimension scores** — each dimension with score %, visual bar, and weight
4. **Issues** — in dimension order, each with: check name, file/location, what was found, how to fix
5. **Summary** — total issue count, and whether any score cap was applied

---

# Execution

Follow these steps in order.

## 1. Locate and read the skill

Accept the skill by name (search `plugins/*/skills/`, `.claude/skills/`, and `skills/`) or by path. Read every file in the skill directory tree — do not sample. Record the file list and line counts. Flag unexpected meta-documentation files (README.md, CHANGELOG.md).

## 2. Load rubric and evaluate

Read `references/rubric.md` for the full check definitions.

For each dimension, evaluate every check:
1. Determine if the check applies (mark N/A only when the check genuinely cannot apply — e.g., mutation checks for a read-only skill, multi-file checks for a single-file skill). Do not mark N/A to avoid a hard judgement.
2. Score the check: PASS, WARN, or FAIL, following the Scoring discipline.
3. Record a brief justification quoting the file and text where the issue was found.
4. If the check is not PASS, record it as an issue — a Major if the rubric tags the check Major, otherwise an untagged finding.

## 3. Compute scores

1. For each dimension: compute the weighted average of applicable checks (excluding N/A).
2. Compute the overall score: weighted sum of dimension scores using the weights in the dimension table.
3. Apply score caps if applicable (see `references/rubric.md`).

## 4. Present the report

Output the report using the format above. Issues are listed in dimension order.

## 5. Offer to review reference files

If the skill has files in `references/`, ask the user whether they also want each reference file reviewed. If the user agrees, start a separate agent for each reference file. Classify each file and pick the right reviewer:

- **Skill** — the file prescribes a behaviour or a set of instructions for the agent to follow (execution steps, decision logic, workflows). Run `/review-skill` on it.
- **Documentation** — the file provides context, reference material, or domain knowledge to be read and understood, not executed (rubrics, guides, templates, data files). Run `/review-document` on it.

Present each reference-file review as it completes.

## 6. Offer to help fix

After all reviews are done, offer to generate a prioritised fix plan if issues were found.