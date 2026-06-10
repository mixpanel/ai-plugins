---
name: manage-experiment
description: >
  Coach the user through any phase of a Mixpanel experiment — design (hypothesis
  framing, metric selection, sizing, statistical model choice, advanced features
  like CUPED / Winsorization / Bonferroni / Benjamini-Hochberg), launch (final
  pre-launch readiness check and the irreversible launch action), monitor
  (mid-flight safety: SRM, sample pace, guardrail-only peek, the don't-peek-on-
  Frequentist rule, terminate-early decisions), and interpret after the
  experiment is mature (read results, decide ship / iterate / kill / wait,
  interpret health checks like SRM and Retro A/A, break results down by segment,
  use session replays to explain a result). Use when the user mentions
  experiment, A/B test, ship/kill decision, MDE, minimum detectable effect,
  sample ratio mismatch, CUPED, sizing, statistical significance, lift, or any
  phrasing like "set up an experiment", "design an A/B test", "launch this
  experiment", "is it safe to keep this running", "is my experiment SRM-ing",
  "should I peek", "how did experiment X do", "should we ship", "why isn't this
  significant yet", "should this be sequential or fixed-horizon", "what's my
  MDE", "is this experiment configured correctly", "audit my experiment". Do
  NOT use for plain feature-flag rollouts with no measurement criterion — that
  belongs to the `manage-feature-flags` skill.
license: Apache-2.0
---

# Manage Experiment

This skill manages a Mixpanel experiment across its full lifecycle — **design**, **launch**, **monitor**, **interpret**. Four commands sit under the umbrella; pick by experiment phase.

The four commands map cleanly to experiment states:

- `DRAFT` (experiment doesn't exist or hasn't launched) → `design` or `launch`.
- `ACTIVE` (mid-flight, exposures accumulating) → `monitor`.
- `ACTIVE` (reached planned end) or `CONCLUDED` → `interpret`.

The skill runs as a single interactive session per experiment. Commands compose naturally across phases — designing produces a configuration that launching commits, monitoring watches for safety issues mid-flight, interpreting consumes the matured result — but they're rarely invoked in the same session (the lifecycle spans days to weeks).

---

# Components

The pieces the skill is built from. The Steps section below tells you how to use them.

## Canonical commands

Each command lives in its own file under `commands/` and is loaded on demand. Match commands explicitly (user names them) or implicitly (message matches a trigger phrase below).

| Command     | File                    | Match if message contains any of                                                                                                            |
| ----------- | ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `design`    | `commands/design.md`    | design, set up, configure, plan, sanity-check, hypothesis, MDE, sizing, sequential vs frequentist, CUPED, Winsorization                     |
| `launch`    | `commands/launch.md`    | launch, go live, start the experiment, ready to ship the experiment, pre-launch check, launch readiness                                     |
| `monitor`   | `commands/monitor.md`   | monitor, mid-flight, is it safe, should I peek, SRM mid-flight, sample pace, guardrail wobble, terminate early                              |
| `interpret` | `commands/interpret.md` | read results, ship, iterate, kill, wait, statsig, SRM, sample ratio mismatch, retro A/A, lift, polarity, segment breakdown, session replays |

If a message could route to more than one, use the **phase-derived** rule based on experiment state:

- `DRAFT`, configuration incomplete → `design`.
- `DRAFT`, configuration complete and user is ready to go → `launch`.
- `ACTIVE`, mid-flight (planned end not reached) → `monitor`.
- `ACTIVE`, reached planned end, or `CONCLUDED` → `interpret`.

If the experiment state is unknown or doesn't disambiguate (e.g. `DRAFT` could be either design or launch), ask the user.

## Command menu

Shown when no command was detected or inferred.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Manage Experiment — [Project Name] ([project_id])
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1. Design     — Hypothesis, metrics, sizing, statistical model, advanced features
  2. Launch     — Pre-launch readiness check, then launch (irreversible)
  3. Monitor    — Mid-flight safety: SRM, sample pace, guardrails, peeking discipline
  4. Interpret  — Read results, ship / iterate / kill / wait
  5. Exit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Shared glossary

Terms all four commands use without redefining. Phase-specific terms (hypothesis, polarity, SRM, peeking trap, etc.) live in their command files.

- **Variant.** One arm of the experiment. The variant treated as the baseline is the **control**; the others are **treatments**. The platform marks which key is the control.
- **Primary / Guardrail / Secondary metric.**
  - **Primary** — drives the ship decision. Cap at 3; the platform applies multiple-testing correction across primaries when configured.
  - **Guardrail** — must not regress; a guardrail regression vetoes a ship even when primaries win.
  - **Secondary** — exploratory / diagnostic only, never decisional, no correction applied.
- **Direction.** Whether bigger is better for a metric (`up`) or smaller is better (`down`). Cancel / error / latency / abandon / refund metrics need `down` set explicitly — leaving the default silently flips polarity at interpretation.
- **Lift.** `(treatment_mean − control_mean) / control_mean`. The sign of lift is mechanical (up/down); it is not by itself a verdict.
- **MDE (Minimum Detectable Effect).** The smallest lift the experiment is sized to detect. Set during design, enforced at interpretation.
- **CUPED.** Variance-reduction technique using pre-exposure baseline. Cuts required sample 30–70% when the metric correlates with pre-exposure behaviour. Inert on new-user-only cohorts.
- **Winsorization.** Outlier capping applied pooled across variants. The `percentile` field is the **tail width** to cap on each side (default `5` caps below the 5th and above the 95th — i.e. the 5% tails). The schema rejects `percentile` ≥ 50. Cuts variance on heavy-tailed continuous metrics; meaningless on Bernoulli metrics.
- **Multiple-testing correction.** Adjusts per-test significance threshold when several primaries or several non-control variants are tested together. Default Benjamini-Hochberg; Bonferroni for strict family-wise control.

## Reference files

Each command file links into these on demand. The map is here so the skill has a single index of what `references/` contains.

| File                                                                                             | Used by                      | Purpose                                                                                                                       |
| ------------------------------------------------------------------------------------------------ | ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| [references/routing-xp-vs-ff.md](references/routing-xp-vs-ff.md)                                 | design                       | Experiment vs Feature Flag disambiguation — when each is the right tool and the hand-off rules.                               |
| [references/hypothesis-framing.md](references/hypothesis-framing.md)                             | design                       | The four properties of a good hypothesis, rubric, common misalignment patterns, worked good/bad examples.                     |
| [references/metric-selection.md](references/metric-selection.md)                                 | design                       | Picking primaries, guardrails, and secondaries. Guardrails-by-domain table. Lagging-indicator and changed-denominator traps.  |
| [references/sizing.md](references/sizing.md)                                                     | design + monitor + interpret | Sample-size and MDE formulas, Kohavi's inversion, baseline-by-rate lookup, the five remediations for underpowered tests.      |
| [references/statistical-model.md](references/statistical-model.md)                               | design                       | Sequential vs frequentist, end-condition choice, confidence level, multiple-testing correction. Peeking-trap math.            |
| [references/advanced-features.md](references/advanced-features.md)                               | design                       | When CUPED and Winsorization help, when each is wrong, and the common misconfigurations.                                      |
| [references/prior-experiments.md](references/prior-experiments.md)                               | design                       | How to look up and fold-in prior experiments on the same feature.                                                             |
| [references/pitfalls.md](references/pitfalls.md)                                                 | design + launch              | The pre-launch pitfall catalogue: blockers (stop launch), warnings (explain trade-off), fyi.                                  |
| [references/health-check-interpretation.md](references/health-check-interpretation.md)           | monitor + interpret          | Reading SRM, Retro A/A, exposures-sufficient, and misconfiguration verdicts. The trustworthiness gate's remediation playbook. |
| [references/per-metric-interpretation.md](references/per-metric-interpretation.md)               | interpret                    | Translating a single metric's lift / CI / p-value into a plain-language verdict, with the Twyman's Law guard.                 |
| [references/why-no-statsig.md](references/why-no-statsig.md)                                     | interpret                    | Wait / extend / boost power / narrow / accept-null decision tree when nothing's significant.                                  |
| [references/segment-of-interest-selection.md](references/segment-of-interest-selection.md)       | interpret                    | How to pick the 3–5 segments worth breaking results down on, before slicing every dimension.                                  |
| [references/segment-breakdown-interpretation.md](references/segment-breakdown-interpretation.md) | interpret                    | Reading per-segment results: heterogeneity vs Simpson's paradox vs noise; the "ship to segment X" requirements.               |
| [references/session-replay-analysis.md](references/session-replay-analysis.md)                   | interpret                    | Turning a quantitative experiment result into a behavior story using session replays.                                         |
| [references/lifecycle-handoff.md](references/lifecycle-handoff.md)                               | interpret                    | The decide-action call shape, multi-variant ship semantics, special variant constants.                                        |

## Cross-command policies

Rules that apply across more than one command. Defined here once so all commands reference the same threshold and don't drift.

### Guardrail hard-gate (5% relative regression)

A **5% relative regression on any guardrail blocks ship**, even when the primary wins. The threshold lives here, not in any one command:

- `design` warns if no guardrails are configured (the gate has nothing to enforce).
- `launch` blocks-or-warns based on guardrail configuration in the readiness check.
- `monitor` uses the threshold to decide when a mid-flight guardrail regression justifies termination.
- `interpret` uses the threshold for the ITERATE vs SHIP decision.

If a team agrees on a different threshold (3% for high-volume billing, 10% for early experiments), change it here and the commands inherit it.

### Peek-safety table

The **peeking trap**: stopping early on a favorable Frequentist peek inflates the false-positive rate because each look at the data is another chance to cross the significance threshold by chance. Sequential testing is built to make peeking safe (the stopping boundaries account for repeated looks); Frequentist testing is not.

The table below is what's safe to look at mid-flight, and what isn't. Used by `monitor` directly; referenced from `design` (when picking sequential vs frequentist) and `interpret` (when deciding whether a mid-flight peek invalidates a verdict).

| Signal                            | Safe to peek mid-flight? | Why                                                                                                                    |
| --------------------------------- | ------------------------ | ---------------------------------------------------------------------------------------------------------------------- |
| SRM verdict                       | Yes                      | Bucketing health is independent of effect size. Detecting SRM early lets you stop before more exposure data is wasted. |
| Sample pace                       | Yes                      | A pacing problem is operational, not statistical. Detecting it early gives time to remediate.                          |
| Guardrail polarity                | Yes (with care)          | A guardrail regression mid-flight is a real safety signal. Stopping for a guardrail regression is not p-hacking.       |
| Primary metric lift (Sequential)  | Yes                      | Sequential testing makes peeking part of the design. The platform's stopping boundaries account for it.                |
| Primary metric lift (Frequentist) | **No**                   | Stopping early on a favorable Frequentist peek is the canonical peeking trap. The false-positive rate inflates fast.   |

The rule users get wrong most often: thinking they can "just check" the primary mid-flight on a Frequentist test "without acting on it." If the look influences any decision — even the decision to wait — it's a peek.

### Output emoji conventions

All four commands use the same visual vocabulary so multi-command sessions read consistently:

- ✅ — pass / ok / nothing to flag
- ⚠️ — warning / attention needed (proceed if user accepts)
- 🛑 — blocker / fail / stop (do not proceed)
- ℹ️ — fyi / informational

## Behaviour rules

1. **Irreversible actions require explicit confirmation.** Creating an experiment (in `design`), launching one (in `launch`), terminating one mid-flight (in `monitor`), and concluding one (in `interpret`) are all irreversible. Show the proposed action, wait for the user to confirm with literal `CONFIRM` for the destructive ones.
2. **If a command can't complete, explain why.** Tell the user what failed and what they can try. Don't fail silently.
3. **Experiment switching.** If the user wants to operate on a different experiment mid-session, ask which one and reset experiment-scoped context.
4. **Project switching.** If the user wants to operate on a different project mid-session, suggest starting a new conversation first. If they insist, resolve the new project and continue with that `project_id`.

---

# Steps

Follow these steps in order.

## 1. Set project

Resolve which Mixpanel project the user wants to operate on.

- **User named a project (name or ID):** list all projects in the workspace. Match by ID first, then by case-insensitive name. If one match → `✅ [Project Name] ([project_id])`, proceed.
- **Multiple name matches:** show the matches in a numbered list, ask the user to pick.
- **No match:** tell the user what wasn't found, offer to `list` (which re-fetches the project list and shows the table).
- **User named nothing:** ask which project. `list` → fetch projects → show table.

If the project listing fails with tool-not-found, tell the user to connect the Mixpanel MCP and stop.

## 2. Set experiment (if one is named)

If the user named an experiment, resolve it now — try ID first, then case-insensitive name match. Multiple matches → numbered picker. No match → tell the user what wasn't found.

If the user is starting a new experiment from scratch (no existing experiment to name), skip this step — `design` will handle setup.

## 3. Pick the command

Apply these rules in order; the first match wins.

1. **Explicit:** user names a phase (`/design`, "launch this experiment", "monitor experiment X", "interpret the results") → use that command.
2. **Implicit:** message matches one canonical trigger phrase from the Components table → use that command.
3. **Phase-derived (only when an experiment was resolved in step 2):**
   - `DRAFT` + configuration incomplete or user is iterating on it → `design`.
   - `DRAFT` + configuration complete and user is ready → `launch`.
   - `ACTIVE` and planned end not reached → `monitor`.
   - `ACTIVE` and planned end reached, or `CONCLUDED` → `interpret`.
     If `DRAFT` doesn't disambiguate between design and launch, ask: "Is the configuration final, or are you still iterating on it?"
4. **Ambiguous verbs** ("audit", "check", "review") — apply phase-derived routing if an experiment is in context, otherwise fall through to the menu.
5. **Otherwise:** show the Command menu, take the user's choice.

## 4. Load and execute the command

If the command file is not already in context, read `commands/[command].md`. Follow the instructions in that file. Reuse the project and experiment context resolved in steps 1–2 — never re-ask.

## 5. Complete

Print `✅ Done.` Return to step 3 if the user wants to chain another command. Typical chains:

- Same session: `design` → `launch` (the user finalized the design and is ready to go live).
- Across sessions: `launch` → (wait 24h+) → `monitor` → (wait to planned end) → `interpret`.
