# Documentation Review Rubric

## Contents

- Dimension 1 — Accuracy & Currency (20%)
- Dimension 2 — Structure & Readability (15%)
- Dimension 3 — Conciseness & DRY (15%)
- Dimension 4 — Altitude & Scope (10%)
- Dimension 5 — Completeness & Navigability (10%)
- Dimension 6 — Clarity & Communication (10%)
- Dimension 7 — Consistency & Conventions (10%)
- Dimension 8 — Examples, Links & Commands (10%)
- Scoring Formula

Apply the **Scoring discipline** from SKILL.md to every check: the burden of proof is on the doc, ties go to the lower rating, and every non-PASS rating must quote concrete evidence (the doc text, plus the contradicting code for accuracy failures). WARN is for genuine partial compliance only — never a way to soften a FAIL.

## Dimension 1 — Accuracy & Currency (20%)

### Claims match the code — Major

Structural claims — architecture, component responsibilities, control flow, named files and symbols — match what the code actually does. Verify against the source; do not infer correctness from confident prose.

- **PASS:** Every named symbol, path, and described behaviour exists and behaves as written (you checked the code).
- **WARN:** A claim is broadly right but imprecise (names the right component but overstates its role).
- **FAIL:** A claim the code contradicts — e.g. "`BaseBehavior` runs the movement loop" when the loop lives in `CellMovementController`. Override: score capped at 74%.

### No stale references — Major

Every file path, symbol, config key, asset name, and menu path the doc names still exists.

- **PASS:** All references resolve in the current tree.
- **FAIL:** A referenced file/symbol/path was renamed or removed (e.g. a doc points to `OldManager.cs` that no longer exists).

### Current state, not history — Major

Docs describe what *is*, not what changed. History belongs in git, not the documentation.

- **PASS:** Present-tense description of the current system.
- **FAIL:** Changelog phrasing — "no longer owns X", "now forwards to Y", "replaces the old Z", "extracted from", "previously", "legacy" — used to narrate a past state.

### Values and defaults are sourced — Major

Specific values are either left to the code/assets, cite where they live, or are marked "verify current". Copied literals go stale silently.

- **PASS:** "Starting DNA lives on the Economy asset" or "default 30s (verify current)".
- **FAIL:** A hardcoded number stated as fact (e.g. "cells start at 50 happiness") that the code may have changed since.

---

## Dimension 2 — Structure & Readability (15%)

### Top-down, scannable layout — Major

Headings, short paragraphs, and tables/lists where they help; each concept is introduced before it is referenced.

- **PASS:** Logical heading hierarchy, scannable, no forward references.
- **WARN:** Mostly clean with one out-of-order concept.
- **FAIL:** Wall of text, or sections that assume concepts defined later.

### Reference by symbol, not line number or literal — Major

Code is referenced by file and symbol, never by line number or a copied literal value — both move.

- **PASS:** "see `CellMovementController.CanEnter`".
- **FAIL:** "see line 42", "as on line 187", or anchoring prose to a literal like "the `1.5` decay constant".

### Stable cross-references — Major

Links to other docs or sections use titles or anchors, not positional references.

- **PASS:** "[Testing](testing.md)" or "the Service layer section".
- **FAIL:** "the third section above", "see below".

### No contradictions

No two statements conflict without an explicit boundary that reconciles them.

- **PASS:** Apparent tensions are scoped ("usually X; for the editor flow, Y").
- **FAIL:** One section says the scene auto-spawns cells; another says spawning is click-only — with no reconciliation.

### Long docs open with a table of contents

A doc over ~100 lines opens with a brief contents list or overview, so a reader (or an agent reading partially) sees its full scope up front.

- **PASS:** A 200-line architecture doc that starts with a contents list of its sections.
- **FAIL:** A long reference doc that dives straight in with no overview of what it covers.
- **N/A:** No in-scope doc exceeds ~100 lines.

---

## Dimension 3 — Conciseness & DRY (15%)

### Single source of truth — Major

Each fact lives in one place; other docs link to it instead of restating it.

- **PASS:** The tunables table lives in one doc; the README links to it.
- **WARN:** One short shared line duplicated once, with no maintenance risk.
- **FAIL:** The same setup steps or table copied across two or more docs (they will drift).

### No filler

Every section earns its place. No restating generic concepts the reader already knows.

- **PASS:** Every section drives understanding of *this* project.
- **WARN:** Some sections longer than needed but still useful.
- **FAIL:** Large blocks explaining general concepts (what a coroutine is, what git does).

### Lean

The doc is as short as it can be while staying complete. Brevity is a quality signal.

- **PASS:** Covers its purpose with no padding.
- **FAIL:** Repetition, throat-clearing intros, or content that could be a single linked sentence.

---

## Dimension 4 — Altitude & Scope (10%)

### Right depth for the doc — Major

Overview docs stay high-level; deep detail lives in the doc that owns it. Detail at the wrong altitude is as harmful as missing detail.

- **PASS:** A README summarises and links to `architecture.md` for the deep dive.
- **FAIL:** Line-level implementation detail, or a full per-field value table, dropped into a top-level overview.

### Values live in code/assets, not docs

Balance numbers and config values are referenced by their home, not mirrored into prose where they rot.

- **PASS:** "Edit the field on the `CellMovementEngineConfig` asset."
- **FAIL:** A table of literal speed/accel/friction numbers copied from the code.

---

## Dimension 5 — Completeness & Navigability (10%)

### Covers the reader's need — Major

The doc answers what its stated audience needs, with no critical gap for its purpose.

- **PASS:** A "getting started" that actually gets the reader to a running app.
- **FAIL:** A setup guide that stops before the run/verify step.

### Cross-linked and discoverable

The doc links out to deeper material and is reachable from an entry point (README or index).

- **PASS:** Linked from the README and links onward to related docs.
- **FAIL:** An orphan doc with no inbound or outbound links.

### Navigation stays shallow

Key material is reachable within about one hop of an entry point (README or index), not buried down a chain of doc-to-doc links the reader must follow in sequence.

- **PASS:** The README links directly to the setup, architecture, and testing docs.
- **FAIL:** README → overview → guide → setup, where the reader must chase three hops to find how to run the project.
- **N/A:** Single-doc set.

---

## Dimension 6 — Clarity & Communication (10%)

### Plain, active language

Clear, active voice; unambiguous antecedents; no needless jargon.

- **PASS:** Short, direct sentences a newcomer can follow.
- **FAIL:** Dense passive constructions or vague "it/this" with no clear referent.

### Domain terms defined or linked

Coined or project-specific terms are defined or linked on first use.

- **PASS:** "the *dropper* (a DNA-cost UI button that spawns a cell)".
- **FAIL:** Unexplained project jargon used as if universal.

---

## Dimension 7 — Consistency & Conventions (10%)

### Follows the repo's documented conventions — Major

If the repo states documentation conventions (e.g. a CLAUDE.md "Conventions" section), the docs obey them.

- **PASS:** Docs follow the repo's stated rules (reference by symbol, current-state, values in code).
- **FAIL:** A doc violates a stated convention — e.g. CLAUDE.md says "reference by symbol, not line number" yet a doc cites line numbers.
- **N/A:** The repo documents no doc conventions.

### Consistent voice, tense, and formatting

Heading levels, tense, terminology, and table/list style are consistent across the set.

- **PASS:** One voice and tense; a term is spelled and cased the same everywhere.
- **FAIL:** Mixed tense, or the same concept named two different ways across docs.

---

## Dimension 8 — Examples, Links & Commands (10%)

### Internal links resolve — Major

Every relative link to a file or anchor points at something that exists.

- **PASS:** All `[text](path)` targets and `#anchor` links resolve.
- **FAIL:** A link to a moved or renamed file/section.

### Examples and commands are correct — Major

Code snippets and shell/CLI commands are valid and match the current API, flags, and paths. Where a point is easier shown than told, prefer one concrete, runnable example over an abstract description.

- **PASS:** Snippets compile against the current symbols; commands use current flags; a concrete example illustrates the usage.
- **FAIL:** A command with a removed flag, or a snippet calling a renamed/removed method; or an abstract "configure the options as needed" where a short example would be clearer.

---

## Scoring Formula

### Within each dimension

```
dimension_score = sum(check_scores) / count(applicable_checks)
```

Where PASS=1.0, WARN=0.5, FAIL=0.0. All checks have equal weight. N/A checks are excluded from numerator and denominator.

### Overall score

```
overall = (D1 x 0.20) + (D2 x 0.15) + (D3 x 0.15) + (D4 x 0.10)
        + (D5 x 0.10) + (D6 x 0.10) + (D7 x 0.10) + (D8 x 0.10)
```

### Score caps

Apply after computing the score. The lowest applicable cap wins.

- "Claims match the code" FAIL → capped at 74% (a doc that misdescribes the system can never be "ready to publish").
