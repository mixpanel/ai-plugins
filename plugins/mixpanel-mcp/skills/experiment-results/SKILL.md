---
name: experiment-results
description: Interprets a Mixpanel experiment's results and health checks. Use when the user asks to read, interpret, or make a ship/iterate/kill/wait call on an experiment, asks why an experiment hasn't reached statistical significance, asks what an SRM or pre-experiment-bias verdict means, or wants to break results down by segment. Consumes the already-computed verdicts the platform returns — never recomputes thresholds. Do NOT use for experiment setup questions (sizing, metric selection, hypothesis framing, advanced-feature config) — those belong to the `experiment-setup` skill.
license: Apache-2.0
---

# Experiment Results Interpretation

You are helping a user read, interpret, or make a ship/iterate/kill/wait decision on a Mixpanel experiment. Use the decision tree below as the spine; open references only when a step needs depth.

## Requirements

- Access to Mixpanel (read experiment details and metrics; update experiment lifecycle for ship/kill decisions).
- This skill consumes the verdicts the platform already returns. **Never recompute thresholds** (SRM, significance, sufficient-exposures, etc.). If a field is missing, say so — do not synthesize a verdict from raw values.

## When to use this skill

Trigger when the user asks anything about reading an experiment's results or its health. Common phrasings:

- "What do these results mean?" / "Should we ship this?"
- "Is this experiment trustworthy?" / "Why is SRM failing?"
- "Why hasn't this hit statistical significance yet?"
- "Break this down by `<segment>`" / "What segments should I look at?"
- "What does this Retro A/A failure mean?"
- "Can you compare the session replays for control vs treatment?"

Do **not** trigger for experiment **setup** questions ("how should I size this?", "what metrics should I pick?") — those belong to the `experiment-setup` skill.

---

## How to read experiment-details output

Always request experiment details with `compute_exposures=true, compute_metrics=true`. The response has two parallel data paths — live and cached. **Always prefer live, fall back to cache, surface errors.**

| Concept                      | Live (preferred)                  | Cached fallback                             |
| ---------------------------- | --------------------------------- | ------------------------------------------- |
| Per-variant exposure counts  | `live_exposures`                  | `exposures_cache` (strip `$`-prefixed keys) |
| SRM check                    | `live_srm_analysis`               | `exposures_cache.$srm_analysis`             |
| Per-metric per-variant stats | `live_metrics[metricId][variant]` | `results_cache.metrics[metricId][variant]`  |
| Bucketed summary             | recompute from `live_metrics`     | `results_cache.summary`                     |

If `live_results_errors` is non-null, use the cache, caveat that data is stale, and surface the error — the underlying failure may need fixing before any decision. If **both** live and cache are empty for a metric, say "no result was computed" and recommend a re-sync. **Never** silently treat as "no effect."

The full field map is in [references/experiment-fields.md](references/experiment-fields.md).

---

## The decision tree

Run in order. **Stop at the first failure** — do not proceed if a step flags a problem.

1. **Trustworthiness gate** — SRM ok? Exposures sufficient? Retro A/A clean? Minimum duration met (~3 days)? No misconfig? If any fail → STOP and open [references/health-check-interpretation.md](references/health-check-interpretation.md).
2. **Statistical significance** — apply the polarity recipe (below) to each non-control variant × primary. If nothing significant on primaries → see [references/why-no-statsig.md](references/why-no-statsig.md).
3. **Guardrail check** — any guardrail significant in the wrong polarity? Regression → ITERATE not ship.
4. **Practical significance** — convert lift into absolute terms (`baseline_value × lift`). Statistically significant ≠ ships.
5. **Verdict** — see table below.

### Polarity recipe (load-bearing — keep in mind for every metric)

`summary.positive` and `summary.negative` are bucketed by **sign of lift**, NOT by business value. `metric.direction` ("up" / "down", defaults to "up") tells you which sign is good:

- `lift is None` or `lift == 0` → **neutral**
- `direction == "up"` → **positive** if `lift > 0`, else **negative**
- `direction == "down"` → **positive** if `lift < 0`, else **negative**

A metric in `summary.positive` with `direction: "down"` is a **regression**, not a win. Filter out the control row first (use `settings.controlKey`). The platform auto-applies multiple-testing correction when `settings.multipleTestingCorrection` is `"bonferroni"` or `"benjamini-hochberg"` — **don't re-correct**.

Per-metric phrasing (translating lift + CI + p-value into "small win" / "large regression" / "noise") is in [references/per-metric-interpretation.md](references/per-metric-interpretation.md). The same reference covers the changed-denominator check (Twyman's Law) for any lift >~30%, and how to query the baseline if `value` or `sampleSize` is `null`.

### Verdict table

| Situation                                                              | Recommendation                                                                                                                                               |
| ---------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Trust ✓, primary polarity positive, guardrails ✓, magnitude meaningful | **SHIP.** Use the experiment's `decide` action with `success=true`, `variant=<winner>`, and a `message` rationale.                                           |
| Trust ✓, primary polarity positive, guardrail polarity negative        | **ITERATE.** Investigate the regression; do not auto-ship.                                                                                                   |
| Trust ✓, primary polarity neutral after target sample reached          | **KILL or ITERATE.** Use the inconclusive-results playbook in [references/why-no-statsig.md](references/why-no-statsig.md).                                  |
| Trust ✓, target sample/duration not yet reached                        | **WAIT** (or extend, or restart with more power — see [references/why-no-statsig.md](references/why-no-statsig.md)).                                         |
| Trust ✗                                                                | **DO NOT DECIDE.** Report the failure and recommend remediation from [references/health-check-interpretation.md](references/health-check-interpretation.md). |

For multi-variant tests, the `decide`-call shape, and special variant constants (`__no_variant_shipped__`, `__defer_variant_decision__`), see [references/experiment-fields.md](references/experiment-fields.md) §Lifecycle hand-off. `message` is required on every `decide` call.

---

## Going deeper

Open the relevant reference on demand:

| User asks about…                                                                | Open                                                                                             |
| ------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| SRM failing, Retro A/A failing, exposures insufficient, or any Step 1 fail      | [references/health-check-interpretation.md](references/health-check-interpretation.md)           |
| "Translate this lift / CI / p-value into English"                               | [references/per-metric-interpretation.md](references/per-metric-interpretation.md)               |
| "Why hasn't this hit statsig yet? Should we wait or stop?"                      | [references/why-no-statsig.md](references/why-no-statsig.md)                                     |
| "Which segments should I break this down on?"                                   | [references/segment-of-interest-selection.md](references/segment-of-interest-selection.md)       |
| "What does this segment-by-segment result mean?" (when platform support exists) | [references/segment-breakdown-interpretation.md](references/segment-breakdown-interpretation.md) |
| "Can session replays help explain this result?"                                 | [references/session-replay-analysis.md](references/session-replay-analysis.md)                   |
| "Which field in the experiment-details response has X?"                         | [references/experiment-fields.md](references/experiment-fields.md)                               |

---

## Output

Default to this shape unless the user asks for something else:

1. **Verdict** in one sentence — `SHIP`, `ITERATE`, `KILL`, `WAIT`, or `DO NOT DECIDE`.
2. **Why**, walking through the decision tree steps that mattered (skip the steps that were clearly fine).
3. **Per-metric breakdown** — winning primaries, losing primaries, guardrail status, with the polarity-corrected reading of each. Include the absolute-impact translation for any win.
4. **Caveats / what we don't know** — non-default confidence level, missing baselines, segments not yet checked, etc.
5. **Suggested next action** — the experiment-decide action to take, or the deeper investigation to run.

If experiment details are unavailable or return errors, say so — do not invent a verdict.
