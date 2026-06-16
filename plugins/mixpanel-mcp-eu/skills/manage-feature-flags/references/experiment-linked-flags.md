# Experiment-linked flags

This is the playbook for flags governed by an experiment — how to spot one, which edits the experiment will overwrite, and when to hand off to the `manage-experiment` skill.

When a flag is linked to an experiment, the recommended lifecycle path is the experiment, not direct flag updates. The API will not block direct flag edits — but the experiment owns the canonical state, and the next experiment transition will overwrite anything you set manually.

## The policy boundary

The link between a flag and its experiment is a **policy boundary, not a server-side block**. Flag updates succeed against an experiment-linked flag — but the next experiment transition (launch, conclude, ship-winner, kill) overwrites manual edits.

Treat the experiment as the only safe lifecycle path for these flags; route all status, ruleset, and variant changes through experiment updates instead. The check is on you, not the API.

## How experiment transitions overwrite the flag

| Experiment transition         | Flag change                                                                |
| ----------------------------- | -------------------------------------------------------------------------- |
| Launch (draft → active)       | Flag is enabled and marked as actively serving an experiment               |
| Conclude (active → concluded) | Flag is disabled (no longer serving)                                       |
| Ship winner (pick a variant)  | Ruleset is replaced — winning variant gets 100% of traffic, others removed |
| Kill (active → failed)        | Flag is disabled and unmarked as an experiment                             |

The table is the state the experiment re-imposes on its next transition (verify against current experiment behavior), even if you manually mutate the flag in the meantime.

## Three implications for lifecycle operations

### 1. Don't enable an experiment-linked flag manually

Use the experiment's launch action instead. The API allows the manual enable, but the experiment will still think it's in draft and the next transition will reconcile state — typically by flipping the flag back.

The symptom users hit: "I enabled the flag but the dashboard shows the experiment as not started." That's the canonical-state divergence; route through the experiment update to fix.

### 2. Don't mutate the ruleset of an experiment-linked flag

Variant additions or removals are accepted by the API but will be overwritten when the experiment concludes or ships a winner. Don't waste a turn updating variants the experiment is going to overwrite.

### 3. You cannot change variants after the experiment is launched

This is a hard limitation — modifying variants invalidates the exposure data and the statistical analysis. To restructure variants, conclude the experiment and create a new one. There is no shortcut.

## Stopping new exposures while preserving bucketing

If you want to **stop new exposures while preserving the current bucketing for users already exposed**, that's the experiment's conclude action, not a flag-level operation. Concluding disables the flag *through the experiment*, which preserves the exposure cohort — this is not the same as a manual flag disable, which serves control to everyone (including users who'd already been bucketed) and is the opposite of what you want here.

## How to spot an experiment-linked flag

Read the flag's current state first. If the flag has an associated experiment:

- The flag is governed by an experiment lifecycle.
- Status, ruleset, and variant changes should route through the linked experiment's actions, not direct flag updates.
- For experiment-side concerns (design, launch, mid-flight monitoring, results interpretation, ship/kill decisions), defer to the `manage-experiment` skill.

If the flag has no experiment link, it's standalone and the lifecycle covered in `SKILL.md` and the other references applies directly.

## When the user is asking experiment questions, not flag questions

If the user's actual question is about experiment design, launch, mid-flight monitoring, results interpretation, or the ship/kill/iterate/wait decision for an experiment-linked flag, route to the **`manage-experiment`** skill. This skill (`manage-feature-flags`) covers the flag-side lifecycle and the routing decision (Feature Flag vs Experiment); it does not own the experiment lifecycle.
