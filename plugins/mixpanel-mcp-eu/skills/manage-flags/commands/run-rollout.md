# Command: run-rollout

The conductor. Runs a progressive rollout one stage at a time. Two
distinct modes based on whether state exists:

- **First invocation** (no state): create or update the flag at stage
  1, write initial state, exit.
- **Re-invocation** (state exists): evaluate the current stage's
  metrics against thresholds, produce a verdict — **Advance**, **Hold**,
  or **Pause**.

Invocation-driven by design. The skill does **not** sleep or schedule.
The user re-invokes when they want to evaluate the current stage. This
keeps the skill self-serve with zero scheduling dependency.

Call `Get-Feature-Flag-Lifecycle-Guidance` on first invocation to
ground the staged-rollout posture in current Mixpanel best practice.

---

## Prerequisites

Steps 0 and 1 from `SKILL.md` must complete:

- Step 0 (flag resolution): a flag must exist *or* a targeting spec
  from `plan-rollout` must be supplied (in which case the flag is
  created in this command).
- Step 1 (project resolution).

Connector and project ID come from `config.md`.

---

## Phase 1 — Determine mode

Fetch the flag (if it exists) with `Get-Feature-Flag`. Look for the
rollout-state JSON in the description field.

| Condition | Mode |
|---|---|
| Flag doesn't exist, only a spec from `plan-rollout` | **First-invocation, create** |
| Flag exists, no state in description | **First-invocation, retro-attach** |
| Flag exists, state present, status is `active` or `dry_run` | **Re-invocation, evaluate** |
| Flag exists, state present, status is `paused` | **Resume request** (special handling) |
| Flag exists, state present, status is `complete` | Route to `analyze-impact` |

For **retro-attach**: the flag was created outside this skill. Before
proceeding, route through `attach-metrics` so a measurement plan
exists. Don't run a rollout against a flag with no metrics — surface
this and stop.

For **resume request**: the rollout was paused by an earlier guardrail
breach. Auto-resume is forbidden (see operating posture in `SKILL.md`).
Require an explicit "yes, resume" from the user, log the resume in
`history` with the original breach context preserved, then proceed as
re-invocation.

---

## Phase 2A — First invocation (create / update)

This phase runs only in first-invocation mode.

**Pre-flight checks:**

1. Metrics must be attached. If state has no `metric_ids`, route to
   `attach-metrics` and stop.
2. Recommend (don't require) that `plan-rollout` has been run. If not,
   surface a one-line prompt: "Want to run `plan-rollout` first? It's
   a 30-second pre-flight." Proceed if the user declines.

**Confirm the ramp schedule:**

- Default from `config.md` is `[10, 25, 50, 100]`.
- User may override. Validate: must be ascending, must end at 100, all
  values in `[1, 100]`.
- Warn if the schedule is more aggressive than 3 stages — fewer stages
  means less signal between flips.

**Confirm guardrail thresholds:**

- Default from `config.md`.
- Surface the defaults; let the user override per-metric if they want
  tighter thresholds on the counter-metric.

**Confirm dry-run vs live:**

- Ask the user explicitly. Dry-run does everything except call
  `Update-Feature-Flag` with non-zero rollout %. State writes still
  happen so the user can walk through stages.
- Set `status: "dry_run"` or `status: "active"` accordingly.

**Create or update the flag:**

- If creating: `Create-Feature-Flag` with the targeting spec and stage
  1 rollout %.
- If updating an existing flag: `Update-Feature-Flag` to set rollout %
  to stage 1.

**Write initial state:**

```json
{
  "version": 1,
  "skill": "manage-flags",
  "owner_email": "<calling PM>",
  "metric_ids": { ... from attach-metrics ... },
  "ramp_schedule": [10, 25, 50, 100],
  "current_stage_index": 0,
  "stage_started_at": "<now>",
  "guardrail_thresholds": { ... },
  "min_dwell_hours": 24,
  "baselines": { ... from attach-metrics ... },
  "status": "active",
  "history": []
}
```

Write back via `Update-Feature-Flag`, preserving any human-readable
description above the state markers.

**Output:** "Stage 1 (10%) committed. Re-invoke `run-rollout` after at
least 24 hours to evaluate."

---

## Phase 2B — Re-invocation (evaluate)

This phase runs only when state exists and status is `active` or
`dry_run`.

**Step 1: Check dwell time.**

If `now - stage_started_at < min_dwell_hours` (default 24h), the stage
hasn't dwelled long enough to evaluate. Output the remaining time and
stop. Don't evaluate prematurely.

User can override with explicit "evaluate now anyway" — log the
override in `history`.

**Step 2: Pull current metric values.**

For each metric in `metric_ids`:

- `Get-Metric(metric_id)` to get the definition (used to scope the
  query).
- `Run-Query` to compute the current value scoped to the **exposed
  cohort** (users currently flipped on by the flag), over a window
  starting from `stage_started_at`.

If Mixpanel's compute returns an error or null result for a metric:
- **Critical metric (success or any guardrail) with no value:** verdict
  is **Hold**. Surface the compute issue. Don't advance, don't pause.
- This matches the passthrough posture from `config.md` — never
  hand-roll stats.

**Step 3: Evaluate thresholds.**

For each guardrail metric:

```
relative_change = (current_value - baseline_value) / baseline_value * 100
```

If `relative_change` is more negative than the metric's threshold
(e.g., threshold is `-2.0%` and observed is `-3.5%`), the guardrail is
**breached**.

For the success metric, no threshold gates advance — but track the
direction. Surface it in the output.

**Step 4: Apply the decision tree.**

| Condition | Verdict | Action |
|---|---|---|
| All guardrails clean, success metric ≥ neutral | **Advance** | Move to next stage |
| All guardrails clean, success metric clearly negative | **Hold** | Surface to user; recommend extending dwell or pausing |
| Any guardrail breached | **Pause** | Set status to `paused`, surface breach, do not auto-resume |
| Sample size too small for any metric | **Hold** | Extend dwell |
| At final stage (100%) and all clean | **Complete** | Set status to `complete`, recommend `analyze-impact` after stabilization buffer |

**Step 5: Execute the verdict.**

- **Advance:**
  - If next stage exists: `Update-Feature-Flag` to next rollout %.
    Increment `current_stage_index`, set new `stage_started_at`, append
    snapshot to `history`.
  - If at the last stage (100%): set `status: "complete"`, append
    final snapshot to `history`.
- **Hold:** Update `last_eval_at` and `last_eval_verdict: "hold"`. No
  flag change. Append a hold entry to `history` with reasoning.
- **Pause:**
  - `Update-Feature-Flag` to set rollout % to 0 (or hold at current
    stage — surface both options to the user, default to 0 for safety).
  - Set `status: "paused"`. Append the breach to `history` with the
    breaching metric, the threshold, and the observed value.
  - **Do not auto-resume** even if the breach normalizes later.

**Step 6: Write state.**

Always update `last_eval_at`, `last_eval_verdict`, and append to
`history`. Write back via `Update-Feature-Flag`.

---

## Phase 3 — Output

### First-invocation output

```markdown
## Rollout Started — <flag name>

**Mode:** Live (or Dry run)
**Stage 1:** 10% rollout — committed at <timestamp>
**Ramp schedule:** [10, 25, 50, 100]
**Min dwell:** 24h per stage

**Bound metrics:**
- Success: `checkout_conversion_v2` (baseline 14.2%)
- Guardrail: `revenue_per_session` (baseline $4.18, business KPI)
- Guardrail: `post_checkout_cancellation_rate` (baseline 1.8%, counter)
- Guardrail: `error_rate_checkout_surface` (baseline 0.18%)

**Next step:** Re-invoke `run-rollout` after 24h to evaluate stage 1
and decide on advance.
```

### Re-invocation (Advance) output

```markdown
## Stage 1 → Stage 2 — <flag name>

**Verdict:** ✅ Advance
**Action taken:** Rollout % updated to 25%
**Stage started at:** <timestamp>

**Metric snapshot (Stage 1, exposed cohort):**
| Metric | Baseline | Current | Δ | Status |
|---|---|---|---|---|
| `checkout_conversion_v2` (success) | 14.2% | 14.9% | +4.9% | 🟢 |
| `revenue_per_session` | $4.18 | $4.21 | +0.7% | ✅ |
| `post_checkout_cancellation_rate` (counter) | 1.8% | 1.8% | 0% | ✅ |
| `error_rate_checkout_surface` | 0.18% | 0.17% | -5.6% | ✅ (improved) |

**Next step:** Re-invoke `run-rollout` after 24h to evaluate stage 2.
```

### Re-invocation (Pause) output

```markdown
## Rollout Paused — <flag name>

**Verdict:** 🔴 Pause
**Action taken:** Rollout % set to 0
**Stage at pause:** Stage 2 (25%)

**Breach detected:**
- `error_rate_checkout_surface`: baseline 0.18%, current 0.31%,
  relative change **+72%**. Threshold is +2% relative — clearly
  exceeded.

**Other metrics (for context):**
| Metric | Baseline | Current | Δ |
|---|---|---|---|
| `checkout_conversion_v2` (success) | 14.2% | 14.7% | +3.5% |
| `revenue_per_session` | $4.18 | $4.20 | +0.5% |
| `post_checkout_cancellation_rate` (counter) | 1.8% | 1.9% | +5.6% |

**The skill will not auto-resume.** To proceed:
- Investigate the error rate spike with the team that owns the
  checkout surface.
- If the issue is fixed, re-invoke `run-rollout` and explicitly confirm
  resume. The original breach will remain in history.
- If the issue is fundamental, consider rollback (manual via Mixpanel UI).
```

### Re-invocation (Complete) output

```markdown
## Rollout Complete — <flag name>

**Final stage:** 100% — committed at <timestamp>
**Status:** complete

**Total ramp duration:** 8 days (4 stages, 2 days each)

**Next step:** Run `analyze-impact` after the stabilization buffer
(default 7 days) to produce the retrospective readout.
```

---

## What this command does NOT do

- **Sleep or schedule.** Invocation-driven only. The user re-invokes
  when they want to evaluate.
- **Auto-resume after a pause.** Pause requires explicit human resume.
- **Auto-rollback.** Pause yes; rollback is a one-click human decision
  in the Mixpanel UI.
- **Compute confidence intervals.** Passthrough posture — Mixpanel
  computes, the skill compares.
- **Skip dwell time silently.** Override only via explicit user
  request, logged in history.
- **Pair the flag with a Mixpanel Experiment.** If randomized rigor is
  needed, route to `manage-experiments`.
