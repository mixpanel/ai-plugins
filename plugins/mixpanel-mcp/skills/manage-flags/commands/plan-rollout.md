# Command: plan-rollout

The pre-flight. Three jobs in one pass:

1. **Decide:** should this be a flag rollout, or does it actually want
   to be an experiment?
2. **Target:** translate the PM's behavioral description into a concrete
   cohort/property spec with a resolved user count.
3. **Risk-check:** compute the exposed user count at the chosen rollout
   %, surface overlap with high-value or churn-risk segments.

Output is a single one-page spec that feeds directly into
`attach-metrics` (the metric plan) and `run-rollout` (the actual ramp).
If the decision is *experiment*, the spec hands off to
`manage-experiments > design-experiment` with the targeting pre-filled.

---

## Prerequisites

Steps 0 and 1 from `SKILL.md` apply, with one nuance: `plan-rollout`
doesn't need a flag yet — the user is *deciding* whether to create one.
Project ID resolution is still required.

Connector and project ID come from `config.md`.

---

## Phase 1 — Flag-vs-experiment decision

Before designing anything, ask the upfront question. This is two
sub-questions in a row:

**Q1: Do you need a randomized comparison, or do you just want to
ship-and-watch?**

- Randomized comparison (A vs B, with stats) → experiment
- Ship-and-watch (turn it on for a segment, ramp if metrics hold) →
  flag rollout

**Q2: Does the success of this change depend on a single primary
metric you'd defend in a product review?**

- Yes, with a defined hypothesis and a magnitude expectation →
  experiment is the cleaner home
- No, "we want this in front of users and we want to know if anything
  catastrophic happens" → flag rollout

If either answer points to experiment, **stop** and route to
`manage-experiments > design-experiment`. Pass the targeting description
forward so the PM doesn't restart from zero.

If both answers point to flag rollout, continue.

Call `Get-Feature-Flag-Setup-Guidance` once at this phase to ground the
recommendation in current Mixpanel best practice — surface any
guidance-driven nuance to the user.

---

## Phase 2 — Targeting design

Take the PM's behavioral description ("power users in India", "new
users on iOS", "enterprise tier customers in production") and translate
it into a concrete targeting spec.

**Step 1: Surface existing cohorts first.**

Call `Search-Entities` with the PM's description as the query. If a
saved cohort matches, propose reuse before defining anything new.
Duplicates pollute the customer's cohort library.

**Step 2: Resolve user properties.**

For each attribute in the description:

- "Power users" → derived behavioral property (events per week,
  feature adoption depth). Surface the candidate property; if multiple
  exist, ask which one.
- "In India" → user property (country). Call `Get-Property-Values` to
  confirm valid values.
- "New users" → time-based property (signup within N days).
- "iOS" → device/platform property. Call `Get-Property-Values` to
  confirm.
- "Enterprise tier" → account property (plan tier). Call
  `Get-Property-Values`.

**Step 3: Resolve to a user count.**

`Run-Query` to count distinct users matching the spec over a recent
window (default last 30 days, active users only). Report the count.

If the count is too small (< 1,000 users) or too large (> 50% of MAU),
surface that and ask if the PM wants to tighten or widen the spec.

---

## Phase 3 — Blast radius

Given the targeting spec and the proposed rollout %, compute who
actually gets exposed.

**Step 1: Apply the rollout %.**

```
exposed_count = matching_users * rollout_percentage / 100
```

Surface both numbers.

**Step 2: Overlap with high-risk segments.**

Where the project has the relevant properties available, check overlap
with:

- **High-value users** (top revenue contributors, paying tier, enterprise
  account size). Property-based. If `Get-Business-Context` exposes a
  business-defined "high-value" cohort, prefer that.
- **Churn-risk users** (declining activity, recent support escalations,
  saved cohort if one exists).
- **Beta program users** (if a cohort exists with that label).

For each overlap: report the count and the % of the exposed cohort.

**Step 3: Risk-flag the spec.**

| Condition | Flag |
|---|---|
| Exposed cohort > 20% high-value users at stage 1 | 🟡 Caution — consider lower stage 1 % |
| Exposed cohort > 5% churn-risk users at stage 1 | 🟡 Caution — pause-on-regression critical |
| Exposed cohort overlaps an active escalation cohort | 🔴 Hold — talk to support first |
| All overlaps within normal ranges | 🟢 Proceed |

The flag is informational, not blocking. The PM can override; surface
the override path explicitly.

---

## Phase 4 — Output the spec

Produce a single Markdown spec the PM can paste into a doc or hand off
to `attach-metrics`:

```markdown
## Rollout Plan — <feature name>

### Decision
- **Type:** Flag rollout (not experiment)
- **Reasoning:** Ship-and-watch posture; no defined primary metric the
  PM would defend in a product review.

### Targeting
- **Description:** Power users in India on iOS
- **Resolved cohort:**
  - `events_per_week_last_30d` ≥ 50
  - `country` = "India"
  - `platform` = "iOS"
- **Cohort match (last 30d active users):** 24,800 users
- **Reused saved cohort:** `india_power_ios_active_v2` (matched 96%)

### Blast radius at stage 1 (10%)
- **Exposed:** ~2,480 users
- **High-value overlap:** 312 users (12.6% of exposed) — within normal range
- **Churn-risk overlap:** 41 users (1.7% of exposed) — within normal range
- **Active escalation overlap:** 0 users
- **Risk flag:** 🟢 Proceed

### Next step
→ Run `attach-metrics` to bind the success and guardrail metrics
before starting the rollout.
```

---

## What this command does NOT do

- **Create the flag.** Flag creation happens in `run-rollout` after
  metrics are attached. `plan-rollout` produces the spec, nothing else.
- **Define metrics.** That's `attach-metrics`. Do not propose metric
  IDs here.
- **Decide stage 1 percentage automatically.** Default is 10%; the PM
  can override before this command runs. Don't tune it silently.
- **Override the user's flag-vs-experiment decision.** If the PM
  insists on a flag rollout when an experiment is cleaner, surface the
  reasoning once, then defer to the PM's call.
- **Build a cross-project cohort.** Single-project scope.
