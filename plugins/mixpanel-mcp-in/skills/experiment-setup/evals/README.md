# Evals for `experiment-setup`

Eval fixtures seeded from the PRD's customer quotes. Each fixture represents a real user prompt the skill should handle competently end-to-end — they're not synthetic; they're the customer scenarios the skill was designed for.

## Fixture conventions

Each `.md` file in this directory is one fixture. The format is:

```markdown
---
fixture: <slug>
customer: <real customer name, if attributable from the PRD>
source: <PRD section or quote citation>
intent: <one of: experiment | feature_flag | ambiguous>
expected_outcome: <one-line summary of what the skill should produce>
---

## Prompt

<verbatim or paraphrased user prompt the skill receives>

## Context

<any structured context the skill would have at hand: project, prior experiments, baseline metrics, etc.>

## Expected behavior

A bulleted list of what the skill must do correctly. Each item is a specific, checkable behaviour:

- [ ] Routes correctly (XP vs FF).
- [ ] Coaches hypothesis if vague.
- [ ] Pulls baseline rate and variance from real data.
- [ ] Surfaces relevant pitfalls.
- [ ] Recommends correct testing model.
- [ ] etc.

## Failure modes to catch

What this fixture is specifically intended to catch — what the skill _would_ get wrong without explicit handling. Each item ties to a section of `SKILL.md` or a reference.

## Notes

Any non-obvious context the eval reviewer needs to understand the fixture.
```

## Running the evals

The eval harness lives outside this repo; this directory is just the fixture catalogue. The harness loads each fixture, drives the skill against a sandboxed Mixpanel project (mocked or sample-data-backed), and scores against the `Expected behavior` checklist.

The scoring rubric:

- **Pass** — every item in `Expected behavior` is observably satisfied.
- **Partial** — at least one expected behaviour is missed or partially satisfied.
- **Fail** — the skill produces an output that would actively mislead the user (wrong routing, wrong testing model recommendation, missed blocker pitfall, etc.).

## Coverage targets

The fixtures cover the workflow phases unevenly on purpose — XP-vs-FF routing and hypothesis-framing failures are by far the most common real-world misuses, so they get the most fixtures.

| Workflow phase                                   | Fixture count target | Current           |
| ------------------------------------------------ | -------------------- | ----------------- |
| XP-vs-FF routing                                 | 3                    | 1 (pelando.md)    |
| Hypothesis framing (vague → coached)             | 3                    | 1 (confetti.md)   |
| Sizing + advanced features (CUPED/Winsorization) | 2                    | 1 (polarsteps.md) |
| Pitfall detection (blockers + warnings)          | 2                    | 0                 |
| Multi-arm / multiple-testing-correction          | 1                    | 0                 |
| Prior-experiments reuse                          | 1                    | 0                 |

The three present fixtures are the seed set the PRD called out by name. Add more as the eval set grows.

## TODO for the engineer landing this skill

The fixtures in this directory are **scaffolded with placeholder customer quotes**. The bot that drafted this skill (mixpanel-claude-code-agent[bot]) did not have access to the PRD where the actual Pelando, Confetti, and Polarsteps quotes live. Before merging:

1. Open the PRD ("AI Experiment Setup Agent & Result Review Agent" project in Linear).
2. Locate the verbatim customer quotes.
3. Replace the `## Prompt` and `## Context` sections in `pelando.md`, `confetti.md`, and `polarsteps.md` with the real text.
4. Adjust `expected_outcome` / `Expected behavior` if the real quote shifts the expected skill behaviour from the placeholder.
5. Add the additional fixtures from the coverage table above (pitfall detection, multi-arm, prior-experiments) — these are not customer-quote-seeded; they can be authored against synthetic scenarios.
