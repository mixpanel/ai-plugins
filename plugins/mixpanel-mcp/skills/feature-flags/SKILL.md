---
name: feature-flags
description: "Coach the user through Mixpanel feature-flag work — picking the right flag-shaped product (Feature Gate vs Dynamic Config vs Experiment), naming and keying, staged rollouts, the kill switch, exposure debugging, archive/restore, and SDK call patterns. Use when the user wants to create, configure, ramp, kill, archive, restore, debug, or clean up a Mixpanel feature flag, or asks why exposures are zero, why a `rolloutPercentage` change had no effect, whether to use a flag or an experiment, or how to clean up stale flags. Trigger on phrasings like 'create a feature flag', 'roll out X to 10%', 'kill the flag', 'why doesn't my flag work', 'archive these stale flags', 'is this a feature flag or an experiment', 'feature flag for the new checkout flow', or when the user names a specific feature they want to gate. Do NOT use for experiment results interpretation ('should we ship?', 'what does this SRM failure mean?') — that belongs to the `experiment-results` skill. Do NOT use for experiment setup ('how should I size this A/B test?', 'what MDE can I detect?') — that belongs to the `experiment-setup` skill."
license: Apache-2.0
---

# Feature Flags

Coach the user through Mixpanel feature-flag work — creation, rollout, lifecycle, hygiene, and debugging. The single most important idea: **a flag's `status` and its `rolloutPercentage` are different levers.** `status` is the kill switch (on/off, instant). `rolloutPercentage` is the throttle (gradient, 0.00 → 1.00). Most flag bugs come from confusing the two; use the right lever for each step.

## Requirements

- Access to Mixpanel (read, create, update, list, and archive feature flags).
- For experiment-backed flags, the ability to create and update experiments — see [references/experiment-linked-flags.md](references/experiment-linked-flags.md).

## When to use this skill

Trigger when the user asks anything about creating, configuring, ramping, killing, archiving, debugging, or cleaning up Mixpanel feature flags. Common phrasings:

- "Create a feature flag for `<feature>`"
- "Roll this out to 10% of users"
- "Kill the flag" / "turn it off"
- "Why doesn't anyone see my flag?" / "I set rolloutPercentage to 50% but nothing changed"
- "Why are there zero `$experiment_started` events?"
- "Should this be a feature flag or an experiment?"
- "Archive all our stale flags" / "what's our flag debt?"
- "Roll back to 0%" / "restore an archived flag"

Do **not** trigger for experiment results interpretation ("should we ship this experiment?", "what does this SRM failure mean?") — those belong to the `experiment-results` skill. For experiment **setup** ("how should I size this A/B test?", "what's my MDE?"), use the `experiment-setup` skill.

---

## Spine 1: Routing — pick the right flag-shaped product

Mixpanel has **three** flag-shaped products. Pick the right one before doing anything else. Getting the routing wrong is unrecoverable without deleting the flag.

| User intent                                                                                                                                                             | Use                  | `flagType`                               |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------- | ---------------------------------------- |
| Toggle a feature on/off for some users (kill switch, gradual rollout, geo-gate, internal-only enable)                                                                   | Create a flag        | `"feature_gate"`                         |
| Serve different **configuration** values to different users (copy variations, theme keys, payload strings, or structured JSON-object payloads) — no measurement         | Create a flag        | `"dynamic_config"`                       |
| Compare variants and **measure** which performs better — hypothesis, primary metric, statistical significance, control vs treatment, traffic split aimed at measurement | Create an experiment | (auto-creates an experiment-backed flag) |

Three rules that prevent the most common mistakes:

1. **Experiment-backed flags must be created via the experiment creation path.** Direct flag creation rejects `flagType: "experiment"`. Creating a flag directly after creating an experiment produces an unlinked duplicate orphan.
2. **"A/B test" or "split traffic to measure X"** is always an experiment, even if the user says "feature flag." Route to experiment creation (and the `experiment-setup` skill).
3. **"Roll this out to 10% of users"** without measurement is a Feature Gate with `rolloutPercentage = 0.10`. Route to flag creation.

If ambiguous (e.g. _"create a feature flag for the new checkout flow"_), ask **one** clarifying question: "Do you want a Feature Gate (on/off toggle), a Dynamic Config (different configuration values per user), or an Experiment (compare variants and measure a metric)?" One disambiguation, then proceed.

Variant shape, naming/keying conventions, the disabled-by-default rule, and the control-on-OFF rule for Feature Gates are in [references/routing-and-setup.md](references/routing-and-setup.md).

---

## Spine 2: Lifecycle — the 5-step rollout/cleanup decision tree

Run in order. Each step's output is the next step's input.

1. **Enable.** Every newly created flag starts `disabled` — the SDK serves control to everyone regardless of `rolloutPercentage`. Update `status` to `"enabled"` as a deliberate, separate step from creation. "I set rolloutPercentage to 50% but no one sees the new behavior" is almost always a still-disabled flag.
2. **Ramp incrementally.** A newly-enabled flag starts at `0%` rollout — you'll always need to manually bump it. Standard cadence: `1% → 10% → 50% → 100%` with 24h+ holds. Update `ruleset.rolloutPercentage`; the merge preserves variants and other ruleset fields. Higher-stakes flags want slower; ramps can move faster only if there's sufficient monitoring in place to catch issues quickly — see [references/staged-rollout.md](references/staged-rollout.md).
3. **Kill switch.** Use `status: "disabled"`, **not** `rolloutPercentage: 0`. Disable is instant, unambiguous, and preserves rollout state for re-enable. Trigger conditions and what doesn't justify a kill in [references/staged-rollout.md](references/staged-rollout.md#kill-switch-triggers).
4. **After 50%: ship / hold / roll back.** Three honest choices — ship if guardrails are flat and cohorts consistent; hold if signal is smaller than expected or a cohort needs investigation; roll back if a guardrail regressed (any size) or a cohort regressed (Simpson's paradox is real). Don't conflate "no clear win" with "should ship anyway."
5. **Archive or convert to permanent.** Permanent operational flag → leave enabled at `1.0` and document why. Shipped or reverted → archive the flag and delete the SDK call sites in the same cycle. Archive requires `disabled` first — disable, then archive (two updates). Set `status` to `"restored"` to bring an archived flag back. Full state machine and the three update-call shapes in [references/lifecycle-and-state-machine.md](references/lifecycle-and-state-machine.md). The cleanup playbook for stale flags is in [references/hygiene-and-cleanup.md](references/hygiene-and-cleanup.md).

**Archive ≠ kill switch.** Archive is for flags whose feature is no longer iterating. Kill switch is `status: disabled` while you debug. Archiving a live flag is destructive — the SDK starts serving control to everyone and rollout state is lost.

---

## Spine 3: Before any setup — check for prior work

When a user asks to set up a flag for a feature, **always list the project's existing flags first** with a partial-name or partial-key match seeded from the feature name. Surface anything you find: a duplicate-feature flag (update the existing one instead), an earlier flag from a shipped experiment (usually safe to archive), or a key collision (the system auto-suffixes, but the user usually wants the clean key — ask whether to retire the old one).

Skipping this check leads to flag debt: orphaned flags, ambiguous evaluation, and codepaths gated by stale or duplicate flags. Full cleanup playbook in [references/hygiene-and-cleanup.md](references/hygiene-and-cleanup.md).

---

## Quick lookups

| User question                                                                        | Where to look                                                                          |
| ------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------- |
| "How do I pick a flag type?" / "Custom variants?" / "Naming and keying?"             | [references/routing-and-setup.md](references/routing-and-setup.md)                     |
| "Staged rollout cadence?" / "When to kill?"                                          | [references/staged-rollout.md](references/staged-rollout.md)                           |
| "Archive vs delete?" / "How do I clean up stale flags?" / "What's our flag debt?"    | [references/hygiene-and-cleanup.md](references/hygiene-and-cleanup.md)                 |
| "How do I call this from the SDK?" / "Why are exposures zero?" / "Sticky bucketing?" | [references/sdk-and-exposure.md](references/sdk-and-exposure.md)                       |
| "What does status='restored' do?" / "Why did my archive call drop my rename?"        | [references/lifecycle-and-state-machine.md](references/lifecycle-and-state-machine.md) |
| "Why can't I edit this flag's variants?" / "Why did my flag config get overwritten?" | [references/experiment-linked-flags.md](references/experiment-linked-flags.md)         |
