---
name: manage-feature-flags
description: "Coach the user through Mixpanel feature-flag work — picking the right flag-shaped product (Feature Gate vs Dynamic Config vs Experiment), naming and keying, staged rollouts, the kill switch, exposure debugging, archive and restore, and SDK call patterns. Use when the user wants to create, configure, ramp, kill, archive, restore, debug, or clean up a Mixpanel feature flag, or asks why exposures are zero, why a rollout-percentage change had no effect, whether to use a flag or an experiment, or how to clean up stale flags. Trigger on phrasings like 'create a feature flag', 'roll out X to 10%', 'kill the flag', 'why doesn't my flag work', 'archive these stale flags', 'is this a feature flag or an experiment', 'feature flag for the new checkout flow', or when the user names a specific feature they want to gate. Do NOT use for experiment design ('how should I size this A/B test?', 'what MDE can I detect?'), launch, mid-flight monitoring, or results interpretation ('should we ship?', 'what does this SRM failure mean?') — all of those belong to the `manage-experiment` skill."
license: Apache-2.0
---

# Manage Feature Flags

Coach the user through Mixpanel feature-flag work end-to-end: routing the request to the right flag-shaped product, ramping safely, killing fast when something goes wrong, and cleaning up when iteration is done.

The single most important idea: **a flag's on/off state and its rollout percentage are different levers.** The on/off state is the kill switch (instant). The rollout percentage is the throttle (gradient). Most flag bugs come from confusing the two; use the right lever for each step.

## Requirements

- Access to Mixpanel (read, create, update, list, and archive feature flags).
- For experiment-backed flags, the ability to create and update experiments — see [references/experiment-linked-flags.md](references/experiment-linked-flags.md).

## When to use this skill

Trigger when the user asks anything about creating, configuring, ramping, killing, archiving, debugging, or cleaning up Mixpanel feature flags. Common phrasings:

- "Create a feature flag for `<feature>`"
- "Roll this out to 10% of users"
- "Kill the flag" / "turn it off"
- "Why doesn't anyone see my flag?" / "I bumped the rollout but nothing changed"
- "Why are there zero exposure events?"
- "Should this be a feature flag or an experiment?"
- "Archive all our stale flags" / "what's our flag debt?"
- "Roll back to 0%" / "restore an archived flag"

Do **not** trigger for experiment design ("how should I size this A/B test?", "what's my MDE?"), launch, mid-flight monitoring, or results interpretation ("should we ship this experiment?", "what does this SRM failure mean?") — all of those belong to the `manage-experiment` skill.

---

## Glossary

- **Feature Gate** — an on/off toggle that serves one of two boolean variants per user. Kill switches, gradual rollouts, geo gates, internal-only enables. Control is the variant that means "feature off."
- **Dynamic Config** — a flag that serves a payload (string or structured object) per user without measurement. Copy variations, theme keys, configuration objects.
- **Experiment** — variant comparison with statistical machinery (primary metric, health checks, significance). Created via the experiment path; the backing flag is auto-created and linked.
- **Kill switch** — disabling an enabled flag to serve control to everyone, instantly, without losing the rollout configuration. Reversible.
- **Ramp** — bumping the rollout percentage upward through a staged cadence (typically `1% → 10% → 50% → 100%`).
- **Sticky bucketing** — a user assigned to a variant stays in that variant across sessions, keyed on a stable identity (by default `distinct_id`).
- **Exposure event** — the analytics event the SDK emits when a flag is evaluated via a tracking entry point. Used to confirm the rollout is serving variants in the proportions you configured.
- **Archive** — a terminal cleanup operation that hides the flag from default listings and stops SDK evaluation. Reversible via `restore`, but **destructive on a live flag** — archiving a flag that still has live traffic strips its rollout state.
- **Restore** — the un-archive verb. A restored flag lands back in the disabled state, never directly enabled.
- **Experiment-linked flag** — a flag whose lifecycle is owned by an experiment. Direct flag edits are accepted but get overwritten on the next experiment transition. Route changes through the experiment.

---

## Components

| File                                                                                   | Purpose                                                                                                                                 |
| -------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| [references/routing-and-setup.md](references/routing-and-setup.md)                     | Picking Feature Gate vs Dynamic Config vs Experiment. Variant rules. The control-on-OFF rule for Feature Gates. Naming and key hygiene. |
| [references/staged-rollout.md](references/staged-rollout.md)                           | Standard / slow / fast ramp cadences. Kill-switch trigger conditions. The mid-stage ship / hold / roll-back decision.                   |
| [references/lifecycle-and-state-machine.md](references/lifecycle-and-state-machine.md) | The disabled ↔ enabled → archived state machine. The three flag-update call shapes and which silently drop fields.                     |
| [references/hygiene-and-cleanup.md](references/hygiene-and-cleanup.md)                 | Pre-creation duplicate check. The cleanup playbook for stale flags. Naming hygiene. The "100% forever" anti-pattern.                    |
| [references/sdk-and-exposure.md](references/sdk-and-exposure.md)                       | SDK call shapes. Exposure-event semantics. The "no exposures after enable" diagnostic checklist.                                        |
| [references/experiment-linked-flags.md](references/experiment-linked-flags.md)         | How to spot an experiment-linked flag, what transitions overwrite, and when to route to the `manage-experiment` skill.                  |

---

## Steps

Run in order. Each step's output is the next step's input. Skip the steps that don't apply to the user's request (e.g. a "kill the flag" turn only needs steps 1, 6, and 8).

**Identifying flags the user mentions.** Users refer to flags by display name (`"the checkout flag"`), not by UUID. When the user names a flag, search by key first (exact match), then by case-insensitive name. If more than one matches, list them with name + key and ask which one. Never ask the user for a UUID.

### 1. Route the request

Before doing anything, decide which flag-shaped product the user actually wants:

| User intent                                                                                                           | Use                     | Skill / path              |
| --------------------------------------------------------------------------------------------------------------------- | ----------------------- | ------------------------- |
| Toggle a feature on/off for some users (kill switch, gradual rollout, geo-gate, internal-only enable)                 | Create a Feature Gate   | This skill, step 3        |
| Serve different **configuration** values per user (copy variations, theme keys, structured payloads) — no measurement | Create a Dynamic Config | This skill, step 3        |
| Compare variants and **measure** which performs better — hypothesis, primary metric, statistical significance         | Create an experiment    | `manage-experiment` skill |

Three rules that catch the most common mis-routes:

1. **Experiment-backed flags must be created via the experiment path.** Direct flag creation rejects the experiment flag type. Creating a flag directly after creating an experiment produces an unlinked orphan.
2. **"A/B test" or "split traffic to measure X"** is always an experiment, even when the user says "feature flag." Route to `manage-experiment`.
3. **"Roll this out to 10% of users"** without measurement is a Feature Gate. Route to step 3 of this skill.

If the request is ambiguous (e.g. _"create a feature flag for the new checkout flow"_), ask **one** clarifying question: "Do you want a Feature Gate (on/off toggle), a Dynamic Config (different configuration values per user), or an Experiment (compare variants and measure a metric)?" One disambiguation, then proceed.

### 2. Check for prior work

When the user asks to set up a flag for a feature, **always list the project's existing flags first** with a partial-name or partial-key match seeded from the feature name. Surface anything you find:

- **Same feature already gated** → ask whether to update the existing flag instead of creating a duplicate.
- **Earlier flag from a now-shipped experiment** → usually safe to archive (after confirming SDK references are gone).
- **Intended key would collide** → the system auto-suffixes to avoid the collision, but the user almost always wants the clean key. Ask whether to retire the old one.

Skipping this check leads to flag debt: orphaned flags, ambiguous evaluation, codepaths gated by stale or duplicate flags. Full playbook in [hygiene-and-cleanup.md](references/hygiene-and-cleanup.md).

### 3. Create the flag

Apply the routing decision from step 1. See [routing-and-setup.md](references/routing-and-setup.md) for variant shapes, the control-on-OFF rule for Feature Gates, the auto-key generator, and naming hygiene. Two rules worth surfacing now:

- **Don't ask the user for a key unless they mentioned one.** The auto-key is almost always fine.
- **Names should describe the gated behavior**, not the experiment hypothesis or the calendar quarter. `new_checkout_button_visible` outlives `q2_checkout_redesign_test`.

When the user has given a hypothesis-shaped reason for the flag, populate the description with it — it's the only context a post-launch maintainer will have when they encounter the flag for the first time.

Every newly created flag starts disabled. Enabling is a separate, deliberate step (step 4).

### 4. Enable

A newly created flag is off until you enable it. Enabling does not start the rollout — the rollout percentage is a separate knob (step 5).

"I bumped the rollout to 50% but no one sees the new behavior" is, almost always, a still-disabled flag. Read the flag's current state when debugging zero exposures.

### 5. Ramp

A newly-enabled flag starts at 0% rollout — you'll always need to bump it manually. A recommended cadence that works for most flags is `1% → 10% → 50% → 100%` with at least 24h between stages — calibrate to product risk and the monitoring you actually have. Higher-stakes flags want a slower cadence with denser steps; lower-stakes flags can move faster only if monitoring will catch a regression in minutes, not hours.

Cadence variants and the rationale for each are in [staged-rollout.md](references/staged-rollout.md).

### 6. Hold the kill switch

When something looks wrong, **disable the flag**. Disable serves control to everyone, instantly, and preserves the rollout configuration so you can re-enable to the same percentage once the issue is fixed.

Zeroing the rollout percentage is the wrong lever — it's slower to take effect (the SDK has to re-evaluate the percentage), and it destroys the rollout-stage information. Trigger conditions for a kill, and what doesn't justify a kill, are in [staged-rollout.md](references/staged-rollout.md#kill-switch-triggers).

### 7. Make the call after mid-stage

Around 50% rollout, three honest choices:

- **Ship** if guardrails are flat and cohorts are consistent.
- **Hold** if the signal is smaller than expected or a cohort needs investigation.
- **Roll back** if a guardrail regressed (any size) or a cohort regressed (Simpson's paradox is real; the average can look fine while a specific segment is harmed).

Don't conflate "no clear win" with "should ship anyway." A small positive effect at 50% is the same small positive effect at 100%, and the maintenance cost of the flag is now the dominant question.

### 8. Pick a terminal state

Every flag ends up in one of three honest terminal states:

- **Permanent operational flag** (kill switch for a critical subsystem, geo gate, plan tier) → leave enabled at 100%. **Document why in the description** so the next maintainer knows it's permanent.
- **Shipped feature, flag retired** → archive the flag and delete the SDK call sites in the same engineering cycle.
- **Reverted feature, flag retired** → archive the flag and delete the SDK call sites. Same as ship, but the rollback decision is the trigger.

Letting a flag drift in "enabled, 100%" indefinitely without documentation is the fourth state, and it's the wrong one — that's how flag debt accumulates.

**Archive is destructive on a live flag** — the SDK starts serving control to everyone and the rollout configuration is lost. Before archiving, confirm with the user that traffic is off and SDK call sites have been removed. The state machine requires disabling first; full lifecycle in [lifecycle-and-state-machine.md](references/lifecycle-and-state-machine.md), cleanup playbook in [hygiene-and-cleanup.md](references/hygiene-and-cleanup.md).

---

## Quick lookups

| User question                                                                        | Where to look                                                                          |
| ------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------- |
| "How do I pick a flag type?" / "Custom variants?" / "Naming and keying?"             | [references/routing-and-setup.md](references/routing-and-setup.md)                     |
| "Staged rollout cadence?" / "When to kill?"                                          | [references/staged-rollout.md](references/staged-rollout.md)                           |
| "Archive vs delete?" / "How do I clean up stale flags?" / "What's our flag debt?"    | [references/hygiene-and-cleanup.md](references/hygiene-and-cleanup.md)                 |
| "How do I call this from the SDK?" / "Why are exposures zero?" / "Sticky bucketing?" | [references/sdk-and-exposure.md](references/sdk-and-exposure.md)                       |
| "What does restore do?" / "Why did my archive call drop my rename?"                  | [references/lifecycle-and-state-machine.md](references/lifecycle-and-state-machine.md) |
| "Why can't I edit this flag's variants?" / "Why did my flag config get overwritten?" | [references/experiment-linked-flags.md](references/experiment-linked-flags.md)         |
