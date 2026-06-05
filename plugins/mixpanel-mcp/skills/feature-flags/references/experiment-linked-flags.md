# Experiment-linked flags

When a flag has an associated `experiment_id`, the recommended lifecycle path is the experiment, not direct flag updates. The API will not block direct flag edits — but the experiment owns the canonical state and the next experiment transition will overwrite anything you set manually.

## The policy boundary

`experiment_id` set on a flag is a **policy boundary, not a server-side block**. Flag updates succeed against an experiment-linked flag — but the next experiment transition (`launch` / `conclude` / `decide`) overwrites your manual edits.

Treat the experiment as the only safe lifecycle path for these flags; route all status, ruleset, and variant changes through experiment updates instead. The check is on you, not the API.

## How experiment transitions overwrite the flag

| Experiment transition             | Flag change                                                             |
| --------------------------------- | ----------------------------------------------------------------------- |
| DRAFT → ACTIVE (launch)           | `status: enabled`, `is_experiment_active: true`                         |
| ACTIVE → CONCLUDED (conclude)     | `status: disabled` (no longer serving)                                  |
| CONCLUDED → SUCCESS (ship winner) | Ruleset replaced: winning variant gets `split: 1.0`, all others removed |
| CONCLUDED → FAIL (kill)           | `status: disabled`, `is_experiment_active: false`                       |

The table is the **contract the experiment will eventually re-impose**, even if you manually mutate the flag in the meantime.

## Three implications for lifecycle operations

### 1. Don't enable an experiment-linked flag manually

Use the experiment's `launch` action instead. The API allows the manual enable, but the experiment will still think it's DRAFT and the next transition will reconcile state — typically by flipping the flag back.

The symptom users hit: "I enabled the flag but the dashboard shows the experiment as not started." That's the canonical-state divergence; route through the experiment update to fix.

### 2. Don't mutate the ruleset of an experiment-linked flag

Variant additions/removals are accepted by the API but will be overwritten when the experiment concludes or makes a decision. Don't waste a turn updating variants the experiment is going to overwrite.

### 3. You cannot change variants after the experiment is launched

This is a hard limitation — modifying variants invalidates the exposure data and the statistical analysis. To restructure variants, conclude the experiment and create a new one. There is no shortcut.

## Stopping new exposures while preserving bucketing

If you want to **stop new exposures while preserving the current bucketing for users already exposed**, that's the experiment's `conclude` action, not a flag-level operation. `status: "disabled"` on the flag serves control to everyone (including users who'd already been bucketed), which is the opposite of what you want for preserving the exposure cohort.

## How to spot an experiment-linked flag

Read the flag's current state first. If `experiment_id` is non-null:

- The flag is governed by an experiment lifecycle.
- Status, ruleset, and variant changes should route through the linked experiment's actions, not direct flag updates.
- For experiment-side concerns (interpretation, ship/kill decisions, setup guidance), defer to the `experiment-results` and `experiment-setup` skills.

If `experiment_id` is null, the flag is standalone and the lifecycle covered in `SKILL.md` and the other references applies directly.

## When the user is asking experiment questions, not flag questions

If the user's actual question is about reading results, deciding ship/kill, or interpreting health checks for an experiment-linked flag, route to the **`experiment-results`** skill — that's where the verdict logic lives. This skill (`feature-flags`) covers the flag-side lifecycle; it does not interpret experiment outcomes.

Similarly, for experiment setup questions ("how should I size this A/B test?", "what's my MDE?"), use the **`experiment-setup`** skill. This skill covers the routing decision (FF vs XP) but defers the actual experiment design to the dedicated skill.
