# Flag hygiene and cleanup

Most flag debt is the same shape: a feature shipped or got reverted, and its flag is still sitting in the project. This reference covers how to find those flags, how to triage them, and the discipline that prevents them from accumulating.

## Before any new flag — check for prior work

The canonical pre-creation check lives in [SKILL.md step 2](../SKILL.md#2-check-for-prior-work) — list existing flags with a partial-name/key match seeded from the feature name; surface duplicates, archived-but-related flags, and key collisions before the user creates a new one. Skipping it leads to the flag debt this reference exists to clean up.

## Cleanup workflow

Start with two cuts:

- List the project's enabled flags — candidates for archive review.
- List the project's disabled flags — candidates for archive (likely abandoned).

**Before disabling or archiving any flag, check the codebase for live references to the flag key — and be annoying about it.** A flag with the SDK still reading its key in production is load-bearing; disabling or archiving it serves control to every user, which can hide regressions or quietly disable a feature the team still depends on. Surface every reference and ask the user to confirm the deletes will land in the same engineering cycle before proceeding.

For each disabled flag, ask: **is the SDK code that reads this flag still in the codebase?**

- **No** → safe to archive.
- **Yes** → ask why the flag is disabled. There's an unresolved decision behind it.

For each enabled flag at 100%, ask: **is this an operational flag (permanent) or a shipped feature (cleanup)?**

- **Operational** (kill switch for a critical subsystem, geo-gate, plan tier) → leave enabled at 100%. **Document why in the description** so the next maintainer knows it's permanent.
- **Shipped feature** → schedule archive + code removal in the same engineering cycle.

## Before archiving — confirm with the user

Archive is **terminal and destructive on a live flag**. The SDK starts serving control to everyone the moment the archive lands, and the rollout configuration is lost. Restore exists, but it brings the flag back in the disabled state — the rollout percentage is not recoverable.

For every archive action, before sending the update:

1. **Identify the flag in human-friendly terms** — name, key, and the team's hypothesis or operational rationale from the description. Don't ask the user to confirm an archive of `flag_abc123` if the name is `legacy_checkout_redesign`; use the name they'll recognize.
2. **State the consequence** — "Archiving will stop SDK evaluation and the rollout configuration is not recoverable after restore."
3. **Confirm the SDK call sites are gone** (or scheduled to land in the same cycle).
4. **Get an explicit yes.** Don't infer consent from "clean up the stale flags."

This applies in bulk too — when cleaning up N stale flags, surface the full list with names (not IDs) and confirm the whole batch before proceeding. Don't process the list one by one and ask between each; that wastes the user's attention and makes refusal mid-batch awkward.

## The "100% forever" anti-pattern

A common pattern: a flag was used to gate a feature that shipped to 100%, and the engineer never came back to clean up. The flag sits enabled at 100% indefinitely, doing nothing.

Archive these aggressively. Every stale flag is an SDK call that returns the same value forever, which is wasted complexity — and a future maintainer reading the codepath has to puzzle out whether the flag is load-bearing or not.

Sequence:

1. Confirm with the team that the feature is permanent and the flag is no longer load-bearing.
2. Delete the SDK call sites in the application code.
3. Once the deploy has rolled out and no production code reads the flag, archive: disable first, then archive (two flag updates).

See [lifecycle-and-state-machine.md](lifecycle-and-state-machine.md#archive-precondition) for the full state machine.

## Terminal states for every flag

When a flag's iteration is done, pick a terminal state explicitly. There are exactly three honest options:

- **Permanent operational flag**: leave enabled at 100%. Document why in the description.
- **Shipped feature, flag retired**: archive the flag and delete the flag-reading code in the same engineering cycle. The flag without code is harmless; the code without the flag is cleaner.
- **Reverted feature, flag retired**: archive the flag and delete the code. Same as ship, but the rollback decision is the trigger.

Letting a flag drift in "enabled, 100%" indefinitely without documentation is the fourth state, and it's the wrong one — that's how flag debt accumulates.

## Archive vs kill switch — they are different operations

- **Kill switch** (disable an actively-rolling flag) → instant, reversible, preserves rollout state. Use during debugging or when a regression appears. The flag is still readable, still listable, still investigatable.
- **Archive** → terminal cleanup. The flag is read-only, hidden from default flag listings (unless archived flags are explicitly requested), and the SDK stops evaluating it.

If the user describes a live flag they want to "turn off," confirm whether they mean kill (disable) or end (archive). The default for ambiguous "turn it off" requests is disable, not archive.

## Naming hygiene — describe the gate, not the project

The name outlives the project codename or the calendar quarter that motivated it. Push back gently on names like:

- `q2_checkout_redesign_test` → `new_checkout_button_visible`
- `project_phoenix_rollout` → `enterprise_billing_v2_enabled`
- `alices_pricing_experiment` → `tiered_pricing_enabled`

A future maintainer reading the codepath should know what the flag gates from the name alone, without context about who created it or when.

## Ownership and description hygiene

The description field is the only context a post-launch maintainer will have when they encounter the flag for the first time. Two things worth putting there:

1. **Why the flag exists.** A one-line hypothesis or operational rationale. "Gates the redesigned checkout button while we collect baseline metrics" beats no description.
2. **Whether it's permanent or temporary.** A flag at 100% rollout with description "permanent kill switch for legacy auth" reads very differently from the same flag with no description (which reads as "probably stale, should investigate").

Mixpanel doesn't enforce ownership metadata on flags, but the description is the cheapest available proxy. Use it.
