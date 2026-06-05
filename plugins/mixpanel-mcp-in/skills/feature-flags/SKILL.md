---
name: feature-flags
description: "Coach the user through Mixpanel feature-flag work — picking the right flag-shaped tool (Feature Gate vs Dynamic Config vs Experiment), naming and keying, staged rollouts, the kill switch, exposure debugging, archive/restore, and SDK call patterns. Use when the user wants to create, configure, ramp, kill, archive, restore, debug, or clean up a Mixpanel feature flag, or asks why exposures are zero, why a `rolloutPercentage` change had no effect, whether to use a flag or an experiment, or how to clean up stale flags. Trigger on phrasings like 'create a feature flag', 'roll out X to 10%', 'kill the flag', 'why doesn't my flag work', 'archive these stale flags', 'is this a feature flag or an experiment', 'feature flag for the new checkout flow', or when the user names a specific feature they want to gate."
license: Apache-2.0
---

# Feature Flags

Coach the user through Mixpanel feature-flag work — creation, rollout, lifecycle, hygiene, and debugging. The single most important idea: **a flag's `status` and its `rolloutPercentage` are different levers.** `status` is the kill switch (on/off, instant). `rolloutPercentage` is the throttle (gradient, 0.00 → 1.00). Most flag bugs come from confusing the two; use the right lever for each step.

## Requirements

- Access to Mixpanel via the MCP server (the `List-Feature-Flags`, `Get-Feature-Flag`, `Create-Feature-Flag`, `Update-Feature-Flag` tools).
- For experiment-backed flags, also `Create-Experiment` and `Update-Experiment` — see [references/experiment-linked-flags.md](references/experiment-linked-flags.md).

## When to use this skill

Trigger when the user asks anything about creating, configuring, ramping, killing, archiving, debugging, or cleaning up Mixpanel feature flags. Common phrasings:

- "Create a feature flag for `<feature>`"
- "Roll this out to 10% of users"
- "Kill the flag" / "turn it off"
- "Why doesn't anyone see my flag?" / "I set rolloutPercentage to 50% but nothing changed"
- "Why are there zero `$feature_flag_called` events?"
- "Should this be a feature flag or an experiment?"
- "Archive all our stale flags" / "what's our flag debt?"
- "Roll back to 0%" / "restore an archived flag"

Do **not** trigger for experiment results interpretation ("should we ship this experiment?", "what does this SRM failure mean?") — those belong to the `experiment-results` skill. For experiment **setup** ("how should I size this A/B test?", "what's my MDE?"), use the `experiment-setup` skill.

---

## Spine 1: Routing — pick the right flag-shaped tool

Mixpanel has **three** flag-shaped products. Pick the right one before doing anything else. Getting the routing wrong is unrecoverable without deleting the flag.

| User intent                                                                                                                                                             | Tool                  | `flagType`                               |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------- | ---------------------------------------- |
| Toggle a feature on/off for some users (kill switch, gradual rollout, geo-gate, internal-only enable)                                                                   | `Create-Feature-Flag` | `"feature_gate"`                         |
| Serve different **configuration** values to different users (copy variations, theme keys, payload strings, or structured JSON-object payloads) — no measurement         | `Create-Feature-Flag` | `"dynamic_config"`                       |
| Compare variants and **measure** which performs better — hypothesis, primary metric, statistical significance, control vs treatment, traffic split aimed at measurement | `Create-Experiment`   | (auto-creates an experiment-backed flag) |

**Three rules that prevent the most common mistakes:**

1. **Experiment-backed flags MUST be created via `Create-Experiment`.** `Create-Feature-Flag` rejects `flagType: "experiment"`. Calling `Create-Feature-Flag` after `Create-Experiment` produces an unlinked duplicate orphan.
2. **"A/B test" or "split traffic to measure X"** is always an experiment, even if the user says "feature flag." Route to `Create-Experiment` (and the `experiment-setup` skill).
3. **"Roll this out to 10% of users"** without any mention of measurement is a Feature Gate with `rolloutPercentage = 0.10`. Route to `Create-Feature-Flag`.

If the request is ambiguous (e.g. _"create a feature flag for the new checkout flow"_), ask **one** short clarifying question before you pick:

> "Do you want a Feature Gate (on/off toggle), a Dynamic Config (different configuration values per user), or an Experiment (compare variants and measure a metric)?"

One disambiguation, then proceed. See [references/routing-and-setup.md](references/routing-and-setup.md) for variant shape, naming/keying conventions, and the control-on-OFF rule for Feature Gates.

---

## Spine 2: Lifecycle — the 5-step rollout/cleanup decision tree

Run these in order. Each step's output is the next step's input — don't skip.

### Step 1 — Enable the flag (it ships disabled)

**Every flag created via `Create-Feature-Flag` starts with `status: "disabled"`.** While disabled, the SDK serves the control variant to everyone regardless of `rolloutPercentage`. Two consequences:

1. **Engineers can ship the SDK code first**, before you flip the switch — the flag is safe-by-default.
2. **You cannot ramp a disabled flag.** If the user reports "I set rolloutPercentage to 50% but no one sees the new behavior," the flag is almost certainly still `disabled`. Check `status` first.

```
Update-Feature-Flag(flag_id=<id>, status="enabled")
```

Never auto-enable as part of creation, and never roll enable + first-rollout-bump into the same turn without telling the user what you're doing. If the user says "ship it," confirm: are they enabling the flag (status flip) or ramping an already-enabled flag (rollout bump)? Wrong answer = unintended user impact.

### Step 2 — Ramp the rollout percentage incrementally

Default rollout for a newly-enabled flag is **1.0 (100%)**. That's almost never what you want for a real launch. Standard staged-rollout pattern:

| Stage  | `rolloutPercentage` | Wait before next stage |
| ------ | ------------------- | ---------------------- |
| Canary | `0.01` (1%)         | 24 hours minimum       |
| Early  | `0.10` (10%)        | 24–48 hours            |
| Mid    | `0.50` (50%)        | 24–72 hours            |
| Full   | `1.00` (100%)       | —                      |

```
Update-Feature-Flag(flag_id=<id>, ruleset={"rolloutPercentage": 0.10})
```

The tool merges this into the current ruleset — variants and other ruleset fields are preserved. You don't need to re-send variants to change rollout.

Higher-stakes flags (billing, auth, payments) deserve a slower cadence; pure server-side changes with monitoring can go faster. See [references/staged-rollout.md](references/staged-rollout.md) for both variants and the rationale behind the logarithmic ramp.

### Step 3 — Watch for the kill-switch trigger

A staged rollout exists so you can **kill fast** when something goes wrong. The kill switch is `status: "disabled"`, **not** `rolloutPercentage: 0`.

```
Update-Feature-Flag(flag_id=<id>, status="disabled")
```

Why disable instead of zeroing the percentage?

1. **Disable is instant and unambiguous.** Zeroing the rollout requires the SDK to re-evaluate the percentage, and depending on cache state, some users may briefly continue seeing the previous variant.
2. **Disable preserves the rollout configuration** so you can re-enable to the same percentage later without re-deciding what stage you were at.

Trigger conditions and what does **not** justify a kill are covered in [references/staged-rollout.md](references/staged-rollout.md#kill-switch-triggers).

### Step 4 — Decide: full rollout, hold, or roll back

After mid-stage rollout (50%), the user has three honest choices. Reflect those back rather than defaulting to "ship it."

- **Ship to 100%** when guardrail metrics are flat or improved, behavior is consistent across cohorts, and enough time has passed (24–72 hours at 50%) to surface low-base-rate bugs.
- **Hold at current percentage** when the signal is real but smaller than expected, a specific cohort needs investigation, or an adjacent change is also rolling out.
- **Roll back (disable) and iterate** when a guardrail regressed (any size, any direction the user cares about), a cohort regressed even if averages look OK (Simpson's paradox is real), or the team hypothesis was falsified.

Don't conflate "no clear win" with "should ship anyway." A flag that doesn't help is also a flag that costs maintenance.

### Step 5 — Archive or convert to permanent

Every flag has a terminal state. Pick one explicitly:

- **Permanent operational flag** (kill switch for a critical subsystem, geo-gate, plan-tier toggle): leave enabled with `rolloutPercentage: 1.0` indefinitely. Document why in the description.
- **Shipped feature, flag retired**: archive the flag and delete the flag-reading code in the same engineering cycle.
- **Reverted feature, flag retired**: archive the flag and delete the code.

Archive requires `disabled` first — the API rejects `archive` on an `enabled` flag:

```
Update-Feature-Flag(flag_id=<id>, status="disabled")
Update-Feature-Flag(flag_id=<id>, status="archived")
```

Archived flags are read-only. To bring an archived flag back into use, send `status="restored"` — see [references/lifecycle-and-state-machine.md](references/lifecycle-and-state-machine.md) for the full state machine, archive precondition, and how status + metadata edits compose (or don't) in a single call.

**Archive ≠ kill switch.** Archive is for flags whose feature is no longer iterating. Kill switch is `status: disabled` while you debug. Archiving a live flag is destructive — the SDK starts serving control to everyone and rollout state is lost.

---

## Spine 3: Before any setup — check for prior work

When a user asks to set up a flag for a feature, **always call `List-Feature-Flags` first** with `name=` or `key=` seeded from the feature name. Surface anything you find:

- **Same feature already gated?** Ask whether to update the existing flag (`Update-Feature-Flag`) instead of creating a duplicate. Two flags controlling the same code path is a debugging nightmare.
- **Earlier flag from a shipped experiment?** Often safe to archive. Don't create a new flag whose key collides.
- **Flag with the same intended key?** Keys must be unique within a project. The system auto-suffixes to avoid collisions, but the user almost always wants the clean key — ask whether to retire the old one.

Skipping this check leads to flag debt: orphaned flags, ambiguous evaluation, and codepaths gated by stale or duplicate flags. See [references/hygiene-and-cleanup.md](references/hygiene-and-cleanup.md) for the full cleanup playbook.

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

---

## Common pitfalls (one-line reminders)

- ⛔ Picking the wrong tool — routing an A/B test to `Create-Feature-Flag`, or routing a kill switch to `Create-Experiment`.
- ⛔ Calling `Create-Feature-Flag` after `Create-Experiment` — the experiment already created the flag; a second call produces an unlinked orphan.
- ⛔ Setting `rolloutPercentage` while `status: disabled` and expecting users to see the variant — disabled overrides rollout.
- ⛔ Going straight from creation to 100% rollout — defeats the safety of staged rollout.
- ⛔ Using `rolloutPercentage: 0` as a kill switch instead of `status: "disabled"` — slower, ambiguous, loses rollout state.
- ⛔ Manually mutating an experiment-linked flag (`experiment_id` set) — the next experiment transition will overwrite your edits. Use `Update-Experiment` instead.
- ⛔ Combining `status: "archived"` (or `"restored"`) with `name`/`description`/`ruleset` in one call — archive/restore short-circuit and silently drop the other edits. Rename first, then archive.
- ⛔ Archiving a flag that real users are actively being bucketed by — instantly serves control to everyone, destroys rollout state.
- ⛔ Asking the user for a `key` they didn't mention — the auto-derived key is almost always correct.
- ⛔ Picking a flag name tied to a calendar quarter or project codename — the flag will outlive that context.
- ⛔ Calling `Update-Feature-Flag(ruleset=...)` on a flag with multiple rollout groups — the MCP refuses (or silently collapses). Edit multi-rollout flags in the UI.
