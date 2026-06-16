# Command: interpret

Interpret a Mixpanel experiment's results and health checks. This command consumes the verdicts the platform already returns. **Never recompute thresholds** (SRM, significance, sufficient-exposures, etc.). If a verdict field is missing, say so — do not synthesize one from raw values.

The umbrella `SKILL.md` defines the shared glossary (Variant, Primary/Guardrail/Secondary metric, Direction, Lift, MDE, CUPED, Winsorization, Multiple-testing correction). Phase-specific terms below.

---

## Glossary (interpret-specific)

- **Polarity.** Whether a movement is _good for the business_. Combines sign of lift with the metric's `direction` ("up" = bigger is better; "down" = smaller is better). See the **Polarity recipe** in Components.
- **Significance.** The platform's per-row classification: significant-positive, significant-negative, or not-significant. Read it from the result — do not recompute.
- **SRM (Sample Ratio Mismatch).** Variants received traffic in proportions that disagree with the configured split. **Kohavi's #1 trustworthiness check** — when SRM fails, downstream lift, p-values, and CIs cannot be trusted.
- **Retro A/A (pre-experiment bias).** Re-runs the comparison on the pre-exposure period. A failure means cohorts already differed before treatment started.
- **Twyman's Law.** "Any unusually clean or unusually large result is more likely a bug than a discovery." Apply on lifts > ~30% — usually a changed-denominator artifact.
- **Trustworthiness gate.** The pre-flight check that runs before any results interpretation: SRM ok, Retro A/A clean, exposures sufficient, ≥3-day window, no misconfig. Failing any of these means **do not interpret results yet** — route to the health-check reference.

---

## Components (interpret-specific)

### Polarity recipe (load-bearing — apply on every metric row)

This is the **canonical polarity recipe** for the skill — the interpret references point back here instead of restating it.

The platform's result buckets (positive / negative / no-effect) classify by **sign of lift**, NOT by business value. Translate each row through the recipe before drawing any conclusion.

Given a row's lift and the metric's direction ("up" = bigger is better, "down" = smaller is better; defaults to "up"):

- Lift missing or exactly zero → **neutral** (no measurement / no effect respectively).
- Direction "up" → **positive** if lift > 0, else **negative**.
- Direction "down" → **positive** if lift < 0, else **negative**.

A positive-bucket row on a "down" metric is a **regression**, not a win. Always filter out the control row first — the platform marks which variant is control.

The platform auto-applies multiple-testing correction when the experiment is configured for Bonferroni or Benjamini-Hochberg — **don't re-correct**.

### Data-source fallback

Experiment-details has two parallel data paths — live (preferred) and cached. Always prefer live; if live computation failed, fall back to cache with a staleness caveat; if **both** are empty, say "no result was computed" and recommend a re-sync. **Never** silently treat missing data as "no effect."

### Verdict table

| Situation                                                              | Recommendation                                                                                                                                                                       |
| ---------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Trust ✓, primary polarity positive, guardrails ✓, magnitude meaningful | **SHIP.** Conclude the experiment via its decide lifecycle action, naming the winning variant and a rationale message. **Confirm with the user first — concluding is irreversible.** |
| Trust ✓, primary polarity positive, guardrail polarity negative        | **ITERATE.** Investigate the regression; do not auto-ship.                                                                                                                           |
| Trust ✓, primary polarity neutral after target sample reached          | **KILL or ITERATE.** Use the inconclusive-results playbook in [../references/why-no-statsig.md](../references/why-no-statsig.md).                                                    |
| Trust ✓, target sample/duration not yet reached                        | **WAIT** (or extend, or restart with more power — see [../references/why-no-statsig.md](../references/why-no-statsig.md)).                                                           |
| Trust ✗                                                                | **DO NOT DECIDE.** Report the failure and recommend remediation from [../references/health-check-interpretation.md](../references/health-check-interpretation.md).                   |

For multi-variant tests, the special success-without-a-single-variant choices (ship-without-a-variant, defer-the-decision), and the exact decide-call shape, see [../references/lifecycle-handoff.md](../references/lifecycle-handoff.md).

---

## Steps

Top-down: what to do, in order.

### 1. Fetch the experiment

The umbrella resolves the experiment in its step 2. If the user named one mid-command, hand back to the umbrella's experiment-resolution step rather than restating it here.

Request the experiment details with exposure and metric data included. The agent's tool layer maps that intent to the right parameters; don't hand-write API arguments.

Apply the **data-source fallback** rule from Components. If the live path fails and the cache is also empty, stop here and tell the user — there is nothing to interpret.

### 2. Run the trustworthiness gate (the Decision Tree)

Run steps 2a–2e in order. **Stop at the first failure** — do not proceed if a step flags a problem. The platform attaches verdict fields for each check; consume those verdicts rather than recomputing.

#### 2a. Trustworthiness

SRM ok? Retro A/A clean? Exposures sufficient? Minimum duration met (~3 days)? No misconfiguration? If any fail → STOP and open [../references/health-check-interpretation.md](../references/health-check-interpretation.md). The Misconfigurations section in that reference covers the warning-level signals (multiple-testing off, extreme winsorization, CUPED on new-users-only, etc.).

#### 2b. Statistical significance

Apply the **polarity recipe** from Components to each non-control variant × primary metric. If nothing is significant on primaries → see [../references/why-no-statsig.md](../references/why-no-statsig.md). For translating a single metric's lift / CI / p-value into a phrase, see [../references/per-metric-interpretation.md](../references/per-metric-interpretation.md).

#### 2c. Guardrail check

Any guardrail significant in the wrong polarity? A guardrail regression → **ITERATE**, not ship. Guardrail polarity uses the same recipe — a positive-bucket row for a "down" guardrail is still a regression.

#### 2d. Practical significance

Convert lift into absolute terms — multiply by the control baseline. Statistically significant ≠ ships. The per-metric reference covers the baseline-fetch fallback when `value` or `sampleSize` is missing, and the **Twyman's Law** check for any lift > ~30%.

#### 2e. Verdict

Look up the situation in the **Verdict table** in Components. If the recommendation is SHIP or KILL, surface the proposed decide-action parameters and **wait for explicit user confirmation** before executing — concluding an experiment is irreversible.

### 3. Going deeper (open references on demand)

| User asks about…                                                                    | Open                                                                                                   |
| ----------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| SRM failing, Retro A/A failing, exposures insufficient, or any trustworthiness fail | [../references/health-check-interpretation.md](../references/health-check-interpretation.md)           |
| "Translate this lift / CI / p-value into English"                                   | [../references/per-metric-interpretation.md](../references/per-metric-interpretation.md)               |
| "Why hasn't this hit statsig yet? Should we wait or stop?"                          | [../references/why-no-statsig.md](../references/why-no-statsig.md)                                     |
| "Which segments should I break this down on?"                                       | [../references/segment-of-interest-selection.md](../references/segment-of-interest-selection.md)       |
| "What does this segment-by-segment result mean?"                                    | [../references/segment-breakdown-interpretation.md](../references/segment-breakdown-interpretation.md) |
| "Can session replays help explain this result?"                                     | [../references/session-replay-analysis.md](../references/session-replay-analysis.md)                   |
| "How do I actually conclude this experiment? Multi-variant ship?"                   | [../references/lifecycle-handoff.md](../references/lifecycle-handoff.md)                               |

### 4. Output

Default to this shape unless the user asks for something else:

1. **Verdict** in one sentence — `SHIP`, `ITERATE`, `KILL`, `WAIT`, or `DO NOT DECIDE`.
2. **Why**, walking through the trustworthiness-gate steps that mattered (skip steps that were clearly fine).
3. **Per-metric breakdown** — winning primaries, losing primaries, guardrail status, each polarity-corrected. Include absolute-impact translation for any win.
4. **Caveats / what we don't know** — non-default confidence level, missing baselines, segments not yet checked, stale-cache caveat, etc.
5. **Suggested next action** — for SHIP / KILL, the proposed decide-action parameters **gated on user confirmation**; for ITERATE / WAIT, the investigation to run next.

If experiment details are unavailable or return errors, say so — do not invent a verdict.
