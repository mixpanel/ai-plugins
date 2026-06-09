---
name: review-document
description: >
  Reviews project documentation (README, CLAUDE.md, docs/, guides, references/) against a
  strict, weighted quality rubric and produces a score (0-100%) with actionable
  issues — checking that docs are accurate against the code, current (no
  changelog phrasing), concise, and well structured. Use when asked to review,
  audit, score, or quality-check documentation, or to verify the docs still
  match the code. Triggers on: "review the docs", "audit the README", "is this
  doc still accurate", "check the docs against the code", "score the
  documentation". Do NOT use for: reviewing Agent Skills (use review-skill),
  reviewing application code or pull-request diffs (use code-review / simplify),
  or writing new documentation from scratch.
license: Apache-2.0
---

# Documentation Review

Reviews a documentation set against a rubric and produces a percentage score plus a prioritised list of issues to fix.

The first duty of docs is to be *true*: a confident, well-written page that misdescribes the code is worse than no page. So accuracy against the actual code is weighted highest and is **verified, not assumed** — every concrete claim is checked against the source.

This is a read-only review. Do not modify the docs being reviewed; report, then offer a fix plan.

The bar is high. Docs that merely "read well" are not good enough — they must be accurate, current, concise, and navigable. Score conservatively (see Scoring discipline).

Conciseness is a first-order concern, not a nicety: keep only what is specific to this project, and cut what the reader already knows. Every paragraph that restates the obvious competes with the one that carries the load.

---

# Components

## Rubric dimensions

The rubric evaluates 8 weighted dimensions. Read `references/rubric.md` for the full check definitions when running the evaluation.

| # | Dimension | Weight |
|---|-----------|--------|
| 1 | Accuracy & Currency | 20% |
| 2 | Structure & Readability | 15% |
| 3 | Conciseness & DRY | 15% |
| 4 | Altitude & Scope | 10% |
| 5 | Completeness & Navigability | 10% |
| 6 | Clarity & Communication | 10% |
| 7 | Consistency & Conventions | 10% |
| 8 | Examples, Links & Commands | 10% |

Dimensions 3 and 4 carry the `/simplify` lens — duplication, filler, and wrong-altitude detail — applied to prose.

## Scoring

Each check is scored **PASS** (1.0), **WARN** (0.5), **FAIL** (0.0), or **N/A** (excluded). All checks have equal weight within their dimension. See `references/rubric.md` for the full scoring formula and score caps.

| Score | Meaning |
|-------|---------|
| 95-100% | Accurate and polished — ready to publish |
| 85-94% | Minor issues — fix before publishing |
| 70-84% | Significant issues — needs rework |
| 50-69% | Major gaps or inaccuracy |
| 0-49% | Largely stale or misleading — rewrite |

## Scoring discipline

The score must reflect a demanding reviewer, not a generous one. **Adopt the stance of a seasoned editor or investigative journalist:** assume the author is beside you and will push back, so go after the single weakest claim, not the average. Nothing earns praise by default; the doc earns each PASS. Apply these to every check:

- **Burden of proof is on the doc.** Score PASS only when the doc clearly meets the check. For accuracy, that means you read the code and confirmed the claim — the absence of a known problem is not proof of correctness.
- **When uncertain between two ratings, pick the lower one.** Ambiguous → WARN; partially met → FAIL unless the gap is trivial.
- **One real defect FAILs its check.** A single wrong path, stale symbol, or "no longer / now / replaces" changelog phrase fails its check — do not average it away because the surrounding prose is good.
- **Quote the evidence.** Every non-PASS rating must cite the doc file and exact text; for an accuracy failure, also cite the code file/symbol that contradicts it. A rating with no concrete evidence is invalid — re-score it.

## Issues

A check is tagged **Major** or left untagged. Major issues are the must-fix findings and carry equal priority — there is no ranking among them. Untagged checks are smaller quality findings.

## Output format

The report must include, in order:
1. **Header** — doc set reviewed, overall score %, one-line verdict from the score band
2. **Files reviewed** — each doc with line count
3. **Dimension scores** — each dimension with score %, a visual bar, and weight
4. **Issues** — in dimension order, each with: check name, doc location, what was found (quote it), and how to fix
5. **Summary** — total issue count, and whether any score cap applied

---

# Execution

Follow these steps in order.

## 1. Scope the review

Accept the docs by path, glob, or name. If none is given, confirm the target with the user rather than guessing — the whole `docs/` tree, a single file, or the repo's top-level docs. Record the file list and line counts.

## 2. Read the docs and the code they describe

Read every in-scope file in full — do not sample. Then, for each concrete claim a doc makes (a path, a symbol, a behaviour, a default value, a command), locate the corresponding code or asset and confirm it still exists and behaves as described; accuracy cannot be judged from the prose alone. If a referenced symbol, path, or behaviour cannot be located in the code, that is itself the finding (a stale reference or an unverifiable claim) — never score such a claim PASS. If the repo documents its own doc conventions (for example a CLAUDE.md "Conventions" section), read them — Dimension 7 scores against them.

## 3. Load rubric and evaluate

Read `references/rubric.md` for the full check definitions. For each dimension, evaluate every check: decide whether it applies (mark N/A only when it genuinely cannot), score PASS / WARN / FAIL per the Scoring discipline, and record a justification quoting the doc text (and the contradicting code for accuracy issues). A non-PASS is a Major if the rubric tags the check Major, otherwise an untagged finding.

## 4. Compute scores

For each dimension, average its applicable checks (PASS=1, WARN=0.5, FAIL=0, N/A excluded). Combine with the dimension weights for the overall score, then apply score caps (see `references/rubric.md`).

## 5. Present the report and offer to fix

Output the report in the format above, issues in dimension order. After the report, offer to apply the fixes — the smallest accurate edit per issue, preserving each doc's voice — but make no changes until asked.
