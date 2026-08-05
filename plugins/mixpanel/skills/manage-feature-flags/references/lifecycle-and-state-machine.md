# Lifecycle and state machine

This is the flag state machine plus the rules for which update calls preserve which fields. Read it before any update that touches `status` or `ruleset` — picking the wrong call shape silently drops fields.

The three observable states a flag will ever expose are **disabled**, **enabled**, and **archived**. **Restored** is a write-only verb — never a state you'll see when reading the flag back.

## State machine

```
   ┌──────────┐    enable    ┌─────────┐
   │ disabled │ ────────────▶│ enabled │
   │  (new)   │◀──────────── │         │
   └─────┬────┘    disable   └─────────┘
         │
         │ archive  (only from disabled)
         ▼
   ┌──────────┐
   │ archived │
   └─────┬────┘
         │ restore
         ▼
     (disabled)
```

**Disabled** is the safe starting state. **Enabled** is the active state. **Archived** is read-only and terminal until you restore the flag, which always lands it back in disabled.

## Archive precondition

The flag must be disabled before you can archive it. Archiving an enabled flag is rejected — disable first, then archive (two updates).

This is intentional: archiving is a terminal cleanup action, and disabling first forces a moment of "are you sure traffic is off?" before the flag becomes read-only. **Before proposing the archive update, confirm with the user that traffic is off and the SDK call sites have been removed** — archiving a flag that real users are actively being bucketed by silently serves control to all of them.

## Restore is a write-only verb

You can restore an archived flag, but the flag's read state will never be "restored." Restore exists for "I archived this by mistake" recovery, not as a normal lifecycle state.

A restored flag lands back in **disabled**. It does **not** restore variants that were mutated while the flag was archived (variants are immutable post-archive anyway).

## Three update-call shapes — what gets dropped silently

A flag update routes through one of three paths depending on what you send. Picking the wrong call shape silently drops fields. Picking the right one prevents the most common "I sent the update and X disappeared" surprise. The routing behavior below reflects the current update path — if an update drops or preserves a field differently than described, re-confirm against the flag-update tool rather than assuming this still holds.

### 1. Archive or restore — short-circuit, drops everything else

An update that flips status to archived or restored routes straight to the archive/restore endpoint. **Any name, description, or ruleset you pass alongside is silently dropped** — the archive/restore path doesn't apply the other edits.

If the user wants to archive _and_ rename, do it as separate updates:

1. Update the flag's name (and/or description).
2. Disable the flag.
3. Archive the flag.

### 2. Status-only flip — safe ruleset-preserving path

An update that flips status to enabled or disabled **and sends no other fields** routes through a status-only path that doesn't touch the ruleset. The right shape for "enable the flag" and "kill the flag" — the common kill-switch case.

### 3. Generic merge — for everything else

Any other shape — a status change combined with metadata or ruleset edits, or any update that touches metadata/ruleset with no status change — falls through to the generic merge path, which is fully supported. The status change (if any) and the metadata edit are applied together, and unspecified fields are preserved by re-fetching the current flag and merging.

### Summary

| Call shape                                       | What happens                                             |
| ------------------------------------------------ | -------------------------------------------------------- |
| Archive (alone or combined with other edits)     | Archives. **Other fields silently dropped.**             |
| Restore (alone or combined with other edits)     | Restores to disabled. **Other fields silently dropped.** |
| Enable/disable alone                             | Status flip only; ruleset preserved.                     |
| Enable/disable combined with metadata or ruleset | Status + metadata applied together; merge with current.  |
| Metadata or ruleset edits (no status change)     | Metadata/ruleset merged with current flag.               |

## Multi-rollout-group flags (UI-only)

The programmatic ruleset path supports flags with a **single** rollout group. Flags created in the Mixpanel UI can have multiple rollout groups (e.g. cohort gates, geo splits, property targeting). The programmatic merge path can't safely express the multi-rollout shape — it would collapse the rollout to a single group, silently destroying groups 2..N.

Before proposing a ruleset edit on a flag you didn't create, **read the flag first and inspect how many rollout groups it has**:

- One rollout group → safe to update the ruleset programmatically.
- More than one → the update path refuses with an actionable error pointing to the UI URL. Edit those flags in the Mixpanel UI instead.

Status-only flips (enable, disable, archive, restore with no other fields) are still safe on multi-rollout flags — those paths don't re-send the ruleset, so no rollout groups are lost.
