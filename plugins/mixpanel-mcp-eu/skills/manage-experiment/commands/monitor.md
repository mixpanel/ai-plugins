# Command: monitor

Mid-flight safety checks on a running experiment. This command answers **"is it safe to keep this experiment running?"** — distinct from `interpret`, which answers **"did the experiment work?"** Monitor is for the middle of the experiment, before there's enough signal to interpret. Peek only at what's safe to peek at; surface anything that warrants pause or termination.

The umbrella `SKILL.md` defines the shared glossary. Phase-specific terms below.

---

## Glossary (monitor-specific)

- **Peeking trap.** Looking at primary-metric results before the planned end of a Frequentist experiment and stopping early on a favorable peek inflates the false-positive rate. Sequential experiments are designed to make peeking safe; Frequentist experiments are not.
- **Sample pace.** The ratio of actual exposures accumulated to expected exposures at this point in the experiment's planned duration. A pace below 0.7 (≥30% slower than projected) suggests the experiment is underpowered relative to its design, or that something is wrong with exposure tracking.
- **Mid-flight SRM.** A Sample Ratio Mismatch detected during the experiment, before exposures are mature. Distinct from the SRM check at interpretation time — mid-flight SRM is a bucketing-bug early-warning, not a verdict on the result.
- **Guardrail-only peek.** Looking at guardrail metrics mid-flight is responsible (catches a regression early); looking at primary metrics mid-flight is the peeking trap. The asymmetry matters.

---

## Components (monitor-specific)

### What's safe to peek at, and what isn't

| Signal                            | Safe to peek mid-flight? | Why                                                                                                                    |
| --------------------------------- | ------------------------ | ---------------------------------------------------------------------------------------------------------------------- |
| SRM verdict                       | Yes                      | Bucketing health is independent of effect size. Detecting SRM early lets you stop before more exposure data is wasted. |
| Sample pace                       | Yes                      | A pacing problem is operational, not statistical. Detecting it early gives time to remediate.                          |
| Guardrail polarity                | Yes (with care)          | A guardrail regression mid-flight is a real safety signal. Stopping for a guardrail regression is not p-hacking.       |
| Primary metric lift (Sequential)  | Yes                      | Sequential testing makes peeking part of the design. The platform's stopping boundaries account for it.                |
| Primary metric lift (Frequentist) | **No**                   | Stopping early on a favorable Frequentist peek is the canonical peeking trap. The false-positive rate inflates fast.   |

The rule users get wrong most often: thinking they can "just check" the primary mid-flight on a Frequentist test "without acting on it." If the look influences any decision — even the decision to wait — it's a peek.

### Terminate-early decision rules

Three situations that justify ending a running experiment before its planned end:

1. **Trustworthiness failure.** SRM fails mid-flight, or a misconfiguration is discovered that invalidates the design. Terminate, fix, restart. The accumulated exposures are not salvageable.
2. **Guardrail regression beyond the design's tolerance.** A guardrail regresses by more than the >5% hard-gate threshold (or whatever the team agreed on), with a tight CI. Continuing exposes more users to a measurable harm. Terminate and route to `interpret` for the ship/iterate verdict.
3. **Sequential stopping boundary crossed (Sequential tests only).** The platform's sequential boundary fires. This is the by-design early stop — terminate and route to `interpret`.

What does **not** justify early termination:

- "It's been a week and the lift looks good" (peeking trap on Frequentist).
- "The team is tired of waiting" (sunk cost mid-flight is real but not a statistical reason).
- "Looks like it'll be inconclusive" (futility analysis exists but requires the right test design; don't improvise).
- A guardrail wobbling within its noise band.

---

## Steps

Top-down: what to do, in order.

### 1. Confirm the experiment is in scope for monitor

The umbrella resolves the experiment in its step 2. Verify it's in `ACTIVE` state. If it's `DRAFT`, route to `design` or `launch`. If it's `CONCLUDED`, route to `interpret`.

### 2. Read the safe signals

Fetch the experiment with exposure data included. Report:

- **Current state:** `ACTIVE` since [date], [N] days into a planned [N-or-date] window.
- **Sample pace:** actual vs expected exposures at this point. Flag if pace < 0.7.
- **Mid-flight SRM verdict** (from the platform). Flag if `FAIL`.
- **Guardrail summary** (polarity-corrected for each guardrail). Flag any with significant regressions.
- **Statistical model:** Sequential vs Frequentist. If Sequential, report whether the stopping boundary has been crossed.

### 3. Apply the don't-peek rule for primaries

If the experiment is **Frequentist** and the user asks about primary-metric results, push back politely:

> "This experiment is configured as Frequentist, which means peeking at the primary mid-flight inflates the false-positive rate even if you're just curious. Mid-flight, the safe signals are SRM, sample pace, and guardrails — happy to walk through those. The primary verdict is meaningful once the planned [N-day | N-sample] target is reached."

If the experiment is **Sequential**, peeking is by design. Report primary status and whether the sequential boundary fired.

### 4. Decide: keep running, pause, or terminate

Apply the **terminate-early decision rules** from Components.

- **Trustworthiness failure or guardrail regression beyond tolerance** → recommend terminate, name the specific signal that fired, route to `interpret` for the formal ship/kill/iterate call.
- **Sequential stopping boundary crossed** → recommend terminate, route to `interpret`.
- **Pace problem (slow sample accrual)** → recommend extending the planned duration if possible, or accepting a coarser MDE. Don't terminate for pace alone; pace means the design is wrong, not the experiment.
- **Everything within tolerance** → recommend continue, give the user a checkback recommendation (next milestone: mid-flight, 80% sample, or planned end).

For the SRM-failure remediation playbook, see [../references/health-check-interpretation.md](../references/health-check-interpretation.md). For the underpowered-experiment remediation playbook, see [../references/sizing.md](../references/sizing.md).

### 5. Output

Default to this shape:

```
*Mid-flight Status — [Experiment Name]*

*Safe to keep running:* YES | NO (with reason) | YES, but with caveats

*Signals:*
  • SRM:           ✅ PASS | 🛑 FAIL
  • Sample pace:    ✅ on track ([N]% of expected) | ⚠️ slow ([N]% of expected)
  • Guardrails:     ✅ flat | ⚠️ <name> regressed [X]%
  • Sequential boundary (if applicable): not crossed | CROSSED

*Recommendation:* continue | terminate (reason) | extend duration

*Next checkback:* [milestone — date or sample count]
```

If the user requested a primary-metric peek on a Frequentist test, lead with the don't-peek explanation before any other signals.

---

## Output style

- Lead with the verdict — safe to continue or not.
- Name the specific signal driving any "terminate" recommendation, never just "looks bad."
- Don't surface primary-metric lift on Frequentist tests, even if asked. Explain why, then offer the safe signals.
- Don't moralise about peeking — explain the math once, then route the user to safe signals.
- Treat "the team wants to ship now" as a separate conversation from "is the experiment ready to ship" — don't conflate.
