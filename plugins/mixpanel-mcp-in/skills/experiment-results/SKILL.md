---
name: experiment-results
description: Interprets a Mixpanel experiment's results and health checks. Use when the user asks to read, interpret, or make a ship/iterate/kill/wait call on an experiment, asks why an experiment hasn't reached statistical significance, asks what an SRM or pre-experiment-bias verdict means, or wants to break results down by segment. Consumes the already-computed verdicts the platform returns — never recomputes thresholds.
license: Apache-2.0
---

# Experiment Results Interpretation

You are helping a user read, interpret, or make a ship/iterate/kill/wait decision on a Mixpanel experiment. **Read the Decision Tree first** and use it as the spine of every interpretation. Drop into the deeper references only when the situation calls for it.

## Requirements

- Access to Mixpanel (read experiment details and metrics; update experiment lifecycle for ship/kill decisions).
- This skill reads the verdicts the platform's experiment-details response already returns. **Never recompute thresholds** (SRM, significance, sufficient-exposures, etc.). If a field is missing, say so — do not synthesize a verdict from raw values.

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
| When was this computed?      | "now"                             | `exposures_cache.$last_computed`            |

If `live_results_errors` is non-null, the live path failed. Use the cache, caveat that data is stale, and surface the error to the user — the underlying failure may need fixing before any decision.

If **both** live and cache are empty for a metric, say "no result was computed" and recommend a re-sync. **Never** silently treat as "no effect."

See [references/experiment-fields.md](references/experiment-fields.md) for the full field map and which fields drive each step below.

---

## The Decision Tree

This is the spine of every interpretation. Run the steps **in order**. **Stop at the first failure** — do not proceed to step N+1 if step N flags a problem.

```
┌─ Step 1: TRUSTWORTHINESS GATE ───────────────┐
│   SRM ok? → exposures sufficient? →          │
│   Retro A/A clean? → minimum duration met? → │
│   no misconfig?                              │
│        │                                     │
│      fail → STOP. See references/            │
│             health-check-interpretation.md   │
└──────────────┬───────────────────────────────┘
               ↓ pass
┌─ Step 2: STATISTICAL SIGNIFICANCE ───────────┐
│   For each non-control variant × primary,    │
│   apply the polarity recipe (sign-of-lift +  │
│   metric.direction). Significant + correct   │
│   polarity = "win"; significant + wrong      │
│   polarity = "loss".                         │
│        │                                     │
│   nothing significant on primaries →         │
│   see references/why-no-statsig.md           │
└──────────────┬───────────────────────────────┘
               ↓ at least one primary win
┌─ Step 3: GUARDRAIL CHECK ────────────────────┐
│   Any guardrail significant in the wrong     │
│   polarity? → regression → ITERATE not ship  │
└──────────────┬───────────────────────────────┘
               ↓ guardrails clean
┌─ Step 4: PRACTICAL SIGNIFICANCE ─────────────┐
│   Convert the lift on the primary into       │
│   absolute terms. Is it big enough to        │
│   matter to the business?                    │
│   Statistically significant ≠ ships.         │
└──────────────┬───────────────────────────────┘
               ↓ meaningful magnitude
┌─ Step 5: VERDICT ────────────────────────────┐
│   Trust ✓ + primary win + guardrails ✓ +     │
│   meaningful magnitude → SHIP                │
│   Trust ✓ + primary win + guardrail regress  │
│     → ITERATE                                │
│   Trust ✓ + primary neutral after target     │
│     → KILL or ITERATE                        │
│   Trust ✗                                    │
│     → DO NOT DECIDE; report failures         │
│   Hasn't reached target sample/duration      │
│     → WAIT (or extend, or restart with more  │
│       power — see why-no-statsig.md)         │
└──────────────────────────────────────────────┘
```

### Step 1 — Trustworthiness gate (consume the verdicts)

Read these fields. Treat the platform's verdict as authoritative — do not reapply thresholds yourself.

| Check                    | Field to read                                                                                          | What "fail" looks like                                                                                                                                         |
| ------------------------ | ------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| SRM                      | `live_srm_analysis` (or `exposures_cache.$srm_analysis`)                                               | Platform flags as failing — do not compute the chi-square yourself.                                                                                            |
| Sufficient exposures     | `live_exposures` per variant                                                                           | Platform-flagged "insufficient." If unflagged but per-variant counts look suspicious, route the user to the health-check reference; do not invent a threshold. |
| Retro A/A (pre-exp bias) | `settings.preExperimentBias` enabled, then the analysis                                                | Platform flags a significant pre-period difference.                                                                                                            |
| Minimum elapsed time     | `end_date - start_date`                                                                                | Less than ~3 days regardless of sample size — interpretation is unreliable.                                                                                    |
| Ran for planned duration | `start_date`, `end_date`, `settings.endAfterDays`/`sampleSize`/`endCondition`, `settings.testingModel` | Frequentist: ended before reaching configured target = peeking. Sequential: early stop on significance is allowed.                                             |
| Misconfiguration         | See [references/experiment-fields.md](references/experiment-fields.md) §Misconfig                      | Any flagged misconfig invalidates analysis.                                                                                                                    |

If any of these fail, **stop**. Tell the user explicitly that results are not trustworthy. Open [references/health-check-interpretation.md](references/health-check-interpretation.md) for the per-failure root-cause checklists, recommended actions, and the Kohavi framing ("SRM is the #1 trustworthiness check; Twyman's Law: any unusually clean result is more likely a bug than a discovery").

### Step 2 — Statistical significance with polarity

**Critical**: `summary.positive` and `summary.negative` are bucketed by **sign of lift**, NOT by whether the lift is good for the business. You MUST apply the polarity recipe using each metric's `direction` before declaring a winner.

#### Polarity recipe

`metric.direction` is `"up"` or `"down"` (defaults to `"up"` if unset on the source metric).

- `lift is None` or `lift == 0` → **neutral**.
- `direction == "up"` → **positive** if `lift > 0`, else **negative**.
- `direction == "down"` → **positive** if `lift < 0`, else **negative**.

A metric in `summary.positive` with `direction: "down"` is a **regression**. A metric in `summary.negative` with `direction: "down"` is a **win**. Never trust the bucket name as the business verdict.

#### How to read the summary

1. **Filter out the control row.** Use `settings.controlKey` (typically `"control"`; may be empty). Control-vs-control always has lift 0 and inflates the "no effect" count. If `controlKey` is empty, identify control by: (a) the variant literally named `"control"`, (b) the variant whose lift is uniformly 0 across all metrics, or (c) ask the user.
2. For each non-control variant, look up the metric in `summary.positive` / `summary.negative` / `summary.no`. **Trust the bucket name as the significance signal** — the `significance` field on each item may be `null` even when the bucket is meaningful.
3. Apply the polarity recipe using `metric.direction` to translate sign-of-lift into win/loss.
4. If `lift is None` in a summary item, **the calculation failed** for that variant — surface it. Do not interpret as "no effect."

The platform auto-applies multiple-testing correction when `settings.multipleTestingCorrection` is set to `"bonferroni"` or `"benjamini-hochberg"` (across primaries × non-control variants). **Don't re-correct.**

Turning the per-metric numbers into a plain-language verdict (lift + CI + p-value → "small win," "large regression," "noise") is in [references/per-metric-interpretation.md](references/per-metric-interpretation.md).

If nothing on the primaries is significant and the user is asking "why hasn't this hit statsig?", route to [references/why-no-statsig.md](references/why-no-statsig.md).

### Step 3 — Guardrail check

Apply the polarity recipe to every guardrail metric (`metric.type == "guardrail"`).

- A small primary win + a clear guardrail regression → usually **iterate, do not ship**.
- "Not significant" on a guardrail does NOT mean "no regression." It means the experiment couldn't _detect_ one at the chosen confidence. If the guardrail is critical (latency, error rate, retention), flag whether it was powered to detect a meaningful regression.
- Polarity matters here too: a guardrail named "errors" with `direction: "down"` and lift `+5%` (significant) is a regression even though it lands in `summary.positive`.

### Step 4 — Practical significance

Statistical significance ≠ business impact. For every primary metric that won:

1. Read the **baseline value** from the control variant: `live_metrics[metricId][controlKey].value`.
2. Read the **lift** from the winning variant's row.
3. Compute absolute lift: `baseline_value × lift`.
4. Project to population per period: ask the user for traffic estimates if not in context.

A 5% lift on a 20% baseline metric serving 1M users/week is enormous. A 5% lift on a 0.1% baseline metric serving 1k users/week is noise. Always ground the user in absolute terms before declaring a win meaningful.

**Twyman's Law check**: before celebrating any lift > ~30%, ask: did the treatment change who is _exposed_ to this metric, not just how they behave? See the changed-denominator notes in [references/per-metric-interpretation.md](references/per-metric-interpretation.md).

If `value` or `sampleSize` is `null` (common when live computation timed out), run a query on the metric scoped to the control variant over the experiment date range to fetch the baseline. Match the metric's aggregation — `unique` → conversion rate; `total` → per-exposure average (raw total ÷ exposures), not the raw total.

### Step 5 — Verdict

| Situation                                                              | Recommendation                                                                                                                                               |
| ---------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Trust ✓, primary polarity positive, guardrails ✓, magnitude meaningful | **SHIP.** Use the experiment's `decide` action with `success=true`, `variant=<winner>`, and a `message` rationale.                                           |
| Trust ✓, primary polarity positive, guardrail polarity negative        | **ITERATE.** Investigate the regression; do not auto-ship.                                                                                                   |
| Trust ✓, primary polarity neutral after target sample reached          | **KILL or ITERATE.** Use the inconclusive-results playbook in [references/why-no-statsig.md](references/why-no-statsig.md).                                  |
| Trust ✓, target sample/duration not yet reached                        | **WAIT** (or extend, or restart with more power — see [references/why-no-statsig.md](references/why-no-statsig.md)).                                         |
| Trust ✗                                                                | **DO NOT DECIDE.** Report the failure and recommend remediation from [references/health-check-interpretation.md](references/health-check-interpretation.md). |

For **multi-variant tests**, pivot the summary by variant and evaluate each treatment independently against control. The winner is the variant with the most polarity-corrected primary wins, zero guardrail regressions, and the largest practical impact. If multiple qualify, prefer the simpler / lower-risk variant. If none qualify, recommend kill or iterate.

`message` is required on every `decide` call — include the rationale, the metrics evaluated, and any tradeoffs accepted.

Special variant constants when `success=true`:

- `__no_variant_shipped__` — ship the change without picking a variant
- `__defer_variant_decision__` — defer (status becomes `SUCCESS_DEFERRED` in UI)

For a kill, pass `success=false`.

---

## Going deeper

Once the spine is clear, the user often asks one of these follow-ups. Open the relevant reference on demand:

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

---

## Common pitfalls (cheat sheet)

- ⛔ **Skipping Step 1** because the lifts look exciting (Twyman's Law)
- ⛔ **Recomputing thresholds** instead of consuming the verdicts the platform already returned
- ⛔ **Not applying polarity** — reading `summary.positive` as "good" without checking `metric.direction`
- ⛔ Trusting a >30% lift without checking whether the **denominator changed**
- ⛔ **Including the control row** when counting wins/losses (filter by `settings.controlKey`)
- ⛔ Treating a `null` lift as "no effect" — it means computation failed
- ⛔ Treating a missing primary (in `metrics[]` but not in `live_metrics`/`results_cache.metrics`) as "no effect" — it's "no measurement"
- ⛔ Interpreting a `< 3 day` experiment instead of refusing
- ⛔ Forgetting to call out a **non-default `confidenceLevel`** (0.9 inflates false positives; 0.99 is conservative)
- ⛔ Treating **secondary-metric significance** as decisional (it isn't, ever)
- ⛔ Conflating **statistical significance** with **practical significance**
- ⛔ Ignoring **guardrail regressions** because the primary won
- ⛔ Calling a single significant primary with multiple-testing correction off a "win" — look at the aggregate, or enable correction
- ⛔ Concluding "no effect" from an underpowered inconclusive result (route to [references/why-no-statsig.md](references/why-no-statsig.md))
