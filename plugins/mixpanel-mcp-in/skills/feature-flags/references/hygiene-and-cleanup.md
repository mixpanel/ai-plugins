# Flag hygiene and cleanup

A healthy project has:

- A small number of long-lived **operational** flags (kill switches, geo-gates, plan tiers).
- A small number of in-flight **experimental** flags (active rollouts).
- **Zero** finished flags whose code has been deleted but whose entity lingers in the project.

Most flag debt is in the third category. This reference covers how to find it, how to triage it, and the discipline that prevents it from accumulating.

## Before any new flag — check for prior work

When a user asks to set up a flag for a feature, **always call `List-Feature-Flags` first** with `name=` (matches display name, partial) or `key=` (matches flag key, partial) seeded from the feature name. Surface anything you find:

- **Same feature already gated?** Ask whether they want to update the existing flag (`Update-Feature-Flag`) instead of creating a duplicate. Two flags controlling the same code path is a debugging nightmare.
- **Earlier flag from a now-shipped experiment?** Often safe to archive. Don't create a new flag whose key collides.
- **Flag with the same intended key?** Keys must be unique within a project. The system auto-suffixes to avoid collisions, but the user almost always wants the clean key — ask whether to retire the old one.

Skipping this check leads to flag debt: orphaned flags, ambiguous evaluation, and codepaths gated by stale or duplicate flags.

## Cleanup workflow

```
List-Feature-Flags(status="enabled")   # candidates for archive review
List-Feature-Flags(status="disabled")  # candidates for archive (likely abandoned)
```

For each disabled flag, ask: **is the SDK code that reads this flag still in the codebase?**

- **No** → archive.
- **Yes** → ask why the flag is disabled. There's an unresolved decision behind it.

For each enabled flag at 100%, ask: **is this an operational flag (permanent) or a shipped feature (cleanup)?**

- **Operational** (kill switch for a critical subsystem, geo-gate, plan tier) → leave enabled at `rolloutPercentage: 1.0`. **Document why in the description** so the next maintainer knows it's permanent.
- **Shipped feature** → schedule archive + code removal in the same engineering cycle.

## The "100% forever" anti-pattern

A common pattern: a flag was used to gate a feature that shipped to 100%, and the engineer never came back to clean up. The flag sits at `status: enabled, rollout: 1.0` indefinitely, doing nothing.

Archive these aggressively. Every stale flag is an SDK call that returns the same value forever, which is wasted complexity — and a future maintainer reading the codepath has to puzzle out whether the flag is load-bearing or not.

Sequence:

1. Confirm with the team that the feature is permanent and the flag is no longer load-bearing.
2. Delete the SDK call sites in the application code.
3. Once the deploy has rolled out and no production code reads the flag, archive:

```
Update-Feature-Flag(flag_id=<id>, status="disabled")
Update-Feature-Flag(flag_id=<id>, status="archived")
```

The flag must be `disabled` before `archived` — the API rejects archiving an `enabled` flag with `FAILED_PRECONDITION: Cannot archive an enabled flag`. See [lifecycle-and-state-machine.md](lifecycle-and-state-machine.md#archive-precondition) for the full state machine.

## Terminal states for every flag

When a flag's iteration is done, pick a terminal state explicitly. There are exactly three honest options:

- **Permanent operational flag**: leave enabled at `rolloutPercentage: 1.0`. Document why in the description.
- **Shipped feature, flag retired**: archive the flag and delete the flag-reading code in the same engineering cycle. The flag without code is harmless; the code without the flag is cleaner.
- **Reverted feature, flag retired**: archive the flag and delete the code. Same as ship, but the rollback decision is the trigger.

Letting a flag drift in `enabled, 100%` indefinitely without documentation is the fourth state, and it's the wrong one — that's how flag debt accumulates.

## Archive vs kill switch — they are different operations

- **Kill switch** (`status: "disabled"` on an actively-rolling flag) → instant, reversible, preserves rollout state. Use during debugging or when a regression appears. The flag is still readable, still listable, still investigatable.
- **Archive** (`status: "archived"` after disabling) → terminal cleanup. The flag is read-only, hidden from default `List-Feature-Flags` (unless `include_archived=True`), and the SDK stops evaluating it.

Archiving a flag that real users are actively being bucketed by is a **destructive operation**: the SDK starts serving control to everyone, and the rollout state is lost. If the user describes a live flag they want to "turn off," confirm whether they mean kill (disable) or end (archive). The default for ambiguous "turn it off" requests is disable, not archive.

## Naming hygiene — describe the gate, not the project

The `name` outlives the project codename or the calendar quarter that motivated it. Push back gently on names like:

- `q2_checkout_redesign_test` → `new_checkout_button_visible`
- `project_phoenix_rollout` → `enterprise_billing_v2_enabled`
- `alices_pricing_experiment` → `tiered_pricing_enabled`

A future maintainer reading the codepath should know what the flag gates from the name alone, without context about who created it or when.

## Ownership and description hygiene

The `description` field is the only context a post-launch maintainer will have when they encounter the flag for the first time. Two things worth putting there:

1. **Why the flag exists.** A one-line hypothesis or operational rationale. "Gates the redesigned checkout button while we collect baseline metrics" beats no description.
2. **Whether it's permanent or temporary.** A flag at 100% rollout with description "permanent kill switch for legacy auth" reads very differently from the same flag with no description (which reads as "probably stale, should investigate").

The MCP doesn't enforce ownership metadata, but the description is the cheapest available proxy. Use it.
