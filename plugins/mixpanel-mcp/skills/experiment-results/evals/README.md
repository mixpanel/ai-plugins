# Eval fixtures — `experiment-results`

Each fixture is a self-contained prompt + expected-behavior pair for the `experiment-results` skill. They are seeded from PRD customer quotes — the customer pain that motivated this skill in the first place.

The fixtures are not auto-runnable yet (no harness lives in this repo). They're written for two uses:

1. **Manual rehearsal** — a human (or another agent) can read the prompt, simulate the response the skill should produce, and check it against the `expected_behavior` field.
2. **Regression checkpoint when a runner exists** — when an eval harness is added in this repo, these prompts plug in directly: each YAML doc becomes one case, the `expected_behavior` field becomes the grader rubric.

When you change `SKILL.md`, walk these fixtures and confirm each one still produces the expected behavior. If a fixture starts failing, decide whether the skill regressed or the fixture itself needs updating.

---

## Fixtures

| Fixture                         | PRD source quote                                                                                                         | What it exercises                                                                              |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------- |
| `pelando-plus-2-others.yaml`    | Pelando — _"+2 others"_ (results too noisy for the user to triage which results to act on)                               | Decision tree spine + per-metric polarity; ship/iterate verdict against multi-variant noise.   |
| `confetti-8-metrics.yaml`       | Confetti — _"8 metrics for new visitors"_ (many primaries; user wants segment-of-interest selection on new vs returning) | Segment-of-interest selection; multiple-testing correction warning; per-metric interpretation. |
| `polarsteps-no-workaround.yaml` | Polarsteps — _"no documented workaround"_ (user wants to understand SRM failure with no canned path forward)             | Health-check interpretation; Kohavi framing; ordered-causes recommendation.                    |

Each YAML doc has the same shape:

```yaml
name: <slug>
prd_source: <one-line attribution>
trigger_phrase: <what the user types>
get_experiment_summary: <key fields the skill would see; not full response — just enough for the eval>
expected_behavior:
  verdict: <SHIP | ITERATE | KILL | WAIT | DO_NOT_DECIDE>
  must_mention: [<phrases / framings the skill must cover>]
  must_not_do: [<failure modes the skill should avoid>]
  references_consulted: [<which reference files the skill should pull open>]
```
