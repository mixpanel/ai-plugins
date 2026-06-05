# Eval fixtures — `feature-flags`

Each fixture is a self-contained prompt + expected-behavior pair for the `feature-flags` skill. They are seeded from the most common failure modes in the canonical setup and lifecycle guidance (`guidance://feature-flags/best-practices`) — the points where users most often get the wrong answer without help.

The fixtures are not auto-runnable yet (no harness lives in this repo). They're written for two uses:

1. **Manual rehearsal** — a human (or another agent) can read the prompt, simulate the response the skill should produce, and check it against the `expected_behavior` field.
2. **Regression checkpoint when a runner exists** — when an eval harness is added in this repo, these prompts plug in directly: each YAML doc becomes one case, the `expected_behavior` field becomes the grader rubric.

When you change `SKILL.md`, walk these fixtures and confirm each one still produces the expected behavior. If a fixture starts failing, decide whether the skill regressed or the fixture itself needs updating.

---

## Fixtures

| Fixture                             | Failure mode it guards against                                                                | What it exercises                                                                   |
| ----------------------------------- | --------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| `routing-ambiguity.yaml`            | Picking the wrong tool when the user says "feature flag" but means "experiment"               | Spine 1 routing table; one-question disambiguation; deferral to `experiment-setup`  |
| `disabled-flag-zero-exposures.yaml` | Diagnosing zero exposures by reaching for SDK / `serving_method` instead of checking `status` | Diagnostic checklist order (status first); SDK convention summary                   |
| `stale-flag-cleanup.yaml`           | Treating "100% rollout forever" as healthy state                                              | Hygiene workflow; archive vs kill switch distinction; ownership/description hygiene |

Each YAML doc has the same shape:

```yaml
name: <slug>
trigger_phrase: <what the user types>
preconditions: <what state the agent should assume>
expected_behavior:
  must_do: [<actions / framings the skill must take>]
  must_not_do: [<failure modes the skill should avoid>]
  references_consulted: [<which reference files the skill should pull open>]
```
