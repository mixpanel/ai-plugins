# Command: launch

Launch a designed Mixpanel experiment. This is the irreversible transition from `DRAFT` to `ACTIVE` — once exposures start, variants are locked, the statistical model is fixed, and mid-flight configuration changes invalidate the test. This command exists to give that transition a deliberate seam.

The umbrella `SKILL.md` defines the shared glossary. Phase-specific terms below.

---

## Glossary (launch-specific)

- **Pre-launch pitfall check.** The deterministic configuration validation that runs against the designed experiment before launch. Categorized as blockers (stop launch), warnings (explain trade-off, proceed if user accepts), fyi.
- **Allocation lock.** The moment the variant percentages stop being editable. After launch, the only safe per-variant change is the post-conclude ship action.
- **Cohort lock.** The moment the targeting cohort stops being editable. Changing the cohort mid-flight changes _who_ is being measured, which silently invalidates the comparison.

---

## Components (launch-specific)

### The irreversibility rule

A launched experiment cannot be "un-launched" without losing the exposure data accumulated to that point. The only operations the post-launch state supports are:

- **Monitor** mid-flight (the `monitor` command in this skill).
- **Conclude** at the end (the `interpret` command's decide action).
- **Pause / resume** via the underlying feature flag (handled by the `manage-feature-flags` skill) — rarely the right move; usually masks a design problem.

There is no "edit the variants" or "change the statistical model" operation post-launch that preserves the result's validity. Surface this constraint to the user before launching — if there's any ambiguity about whether the configuration is final, send them back to `design`.

### Launch readiness checklist

Run this against the experiment about to launch. Surface only what fires; order blockers → warnings → fyi.

| Severity | Check                                                                                                                                                                                                        |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Blocker  | Pre-launch pitfall catalogue (insufficient duration, cohort too small) reports a blocker — see [../references/pitfalls.md](../references/pitfalls.md).                                                       |
| Blocker  | The experiment has no primary metric.                                                                                                                                                                        |
| Blocker  | The configured allocation doesn't sum to 100% across variants.                                                                                                                                               |
| Warning  | The pre-launch pitfall catalogue reports a warning.                                                                                                                                                          |
| Warning  | No guardrail metrics configured. Without guardrails, the regression hard-gate (see umbrella Cross-command policies) cannot protect the ship decision.                                                        |
| Warning  | A primary metric has `direction` unset (defaults to `up`); cancel / error / latency / abandon / refund metrics need `down` set explicitly. Fixable in place via the metric-update tool — no recreate needed. |
| Warning  | `srm.enabled` is false or `excludeQA` is unset — both are easily lost to a partial settings edit (see the umbrella's read-merge-write rule); re-confirm before the allocation locks.                         |
| FYI      | The experiment isn't linked back to a prior experiment on the same feature, even though prior experiments exist. Recommend adding the link before launch.                                                    |

The pitfall catalogue itself lives in [../references/pitfalls.md](../references/pitfalls.md) — don't duplicate the rules here; run them and report results.

---

## Steps

Top-down: what to do, in order.

### 1. Confirm the experiment is ready

The umbrella resolves the experiment in its step 2. Verify it's in `DRAFT` state. If it's already `ACTIVE` or `CONCLUDED`, this command is the wrong one — route to `monitor` or `interpret`.

### 2. Run the launch readiness checklist

Apply the catalogue from Components against the current experiment configuration. Surface results in this order:

```
*Launch Readiness — [Experiment Name]*

🛑 Blockers (must fix before launch)
  • [blocker description]
⚠️ Warnings (recommend addressing)
  • [warning description]
ℹ️  FYI
  • [fyi description]
```

If any blockers fire, **stop**. Tell the user what to fix and route them back to `design` to update the configuration. Don't offer to launch past a blocker.

If warnings fire, name each trade-off explicitly. Don't just list them — explain what risk the user is accepting by launching anyway.

If only FYIs fire (or nothing fires), proceed to step 3.

### 3. Present the launch confirmation

Surface the launch summary and **wait for explicit confirmation** before invoking the launch action. The summary should match what the user saw at the end of `design`, with any post-design edits reflected:

```
*Launch Summary — [Experiment Name]*

• *Hypothesis:* If <change>, then <metric> will <direction> by ≥<MDE>, because <mechanism>.
• *Primary metrics:* <name> (direction), …
• *Guardrails:* <name> (direction), …
• *Variants:* control <X>% / treatment <Y>% (or as configured)
• *Statistical model:* sequential | frequentist
• *End condition:* sample-based (per-arm <N>) | date-based (<N> days)
• *Confidence level:* <X>
• *Multiple testing correction:* benjamini-hochberg | bonferroni | off
• *Advanced features:* CUPED on/off · Winsorization on/off (percentile <P>)
• *Expected duration on current traffic:* <D> days

*After launch:*
  • Variants are locked.
  • Statistical model is locked.
  • Cohort targeting is locked.
  • The only safe operations are monitor (mid-flight) and conclude (at the end).

Reply CONFIRM to launch. Anything else cancels.
```

The literal `CONFIRM` requirement matches the irreversibility-confirmation discipline in `manage-lexicon` and `manage-feature-flags`.

### 4. Launch

On `CONFIRM`, invoke the launch action. If the launch fails, surface the platform's error verbatim — don't paraphrase. The user needs to know whether the failure is a transient platform issue (retry) or a configuration issue (back to `design`).

### 5. Hand off to monitor

After a successful launch, recommend the user check back in 24h via the `monitor` command. Surface two things they should set up as follow-ups (don't interrupt the launch flow to do them inline):

1. **A tracking dashboard** for the primary and guardrail metrics — gives the user a single place to watch the experiment without re-opening the skill every time. Recommend running `create-dashboard` in a follow-up session.
2. **A calendar reminder** for the canary check (24h) and the mid-flight check (~halfway through the planned duration). Concrete phrasing the agent can use: _"Worth scheduling two check-ins: 24h from now for the canary, and at the midpoint of your N-day window for the mid-flight read. Both run through the `monitor` command."_

Print `✅ Launched.` and return control to the umbrella.

---

## Output style

- Lead with the readiness verdict — pass, warnings, or blockers — before showing the summary.
- For blockers, name the specific configuration field the user needs to change.
- For warnings, name the trade-off, not just the rule.
- Don't moralise about launching with warnings — surface them, get explicit acceptance, proceed.
- Don't launch without `CONFIRM`. Treat any other response (including "yes", "ok", "sure") as cancel-and-clarify.
