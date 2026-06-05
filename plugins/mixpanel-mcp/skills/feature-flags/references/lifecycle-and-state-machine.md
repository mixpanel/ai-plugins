# Lifecycle and state machine

The three observable states a flag will ever expose are `disabled`, `enabled`, and `archived`. `restored` is a write-only verb — never a state you'll see when reading the flag back.

## Status state machine

Transitions are sent as the `status` value on a flag update:

```
   ┌──────────┐    "enabled"    ┌─────────┐
   │ disabled │ ──────────────▶ │ enabled │
   │  (new)   │ ◀────────────── │         │
   └─────┬────┘    "disabled"   └─────────┘
         │
         │ "archived"   (only from disabled)
         ▼
   ┌──────────┐
   │ archived │
   └─────┬────┘
         │ "restored"
         ▼
     (disabled)
```

`disabled` is the safe starting state. `enabled` is the active state. `archived` is read-only and terminal until you send `status="restored"`, which always lands the flag back in `disabled`.

## Archive precondition

The flag must be `disabled` before you can archive it. Setting `status="archived"` on an `enabled` flag returns `FAILED_PRECONDITION: Cannot archive an enabled flag`. Disable first, then archive — two updates: one to set `status="disabled"`, then one to set `status="archived"`.

This is intentional: archiving is a terminal cleanup action, and disabling first forces a moment of "are you sure traffic is off?" before the flag becomes read-only.

## `restored` is a write-only verb

`restored` only appears as a status-update input; the flag's read state will never be `restored`. It exists for "I archived this by mistake" recovery, not as a normal lifecycle state.

A restored flag lands back in `disabled`. It does **not** restore variants if you mutated them while archived (variants are immutable post-archive anyway).

## Flag-update call shapes — three short-circuit paths

A flag update routes through one of three paths depending on which fields you send. Picking the right call shape per intent prevents silent drops and unintended overwrites.

### 1. Archive or restore — short-circuit, drops everything else

A status update setting `status="archived"` or `status="restored"` routes straight to the dedicated archive/restore endpoint. **Any `name` / `description` / `ruleset` you pass alongside is silently dropped** — the short-circuit returns before the merge logic runs.

If you want to archive AND rename, do it as separate updates (rename first, then disable, then archive):

1. Update the flag's `name` (and/or `description`).
2. Update `status` to `"disabled"`.
3. Update `status` to `"archived"`.

### 2. Status-only flip — safe ruleset-preserving path

A status update with `status="enabled"` or `status="disabled"` **and no other fields** routes through a status-only path that avoids re-sending the ruleset, so it can't accidentally clobber it on a status-only flip.

This is the right shape for "enable the flag" and "kill the flag" — the common kill-switch case.

### 3. Generic merge — for everything else

Any other shape — `status="enabled"` or `status="disabled"` combined with `name`/`description`/`ruleset`, or any update that touches metadata/ruleset with no status change — falls through to the generic merge path, which is fully supported. The status change (if any) and the metadata edit are applied together, and unspecified fields are preserved by re-fetching the current flag and merging.

### Summary table

| Call shape                                                          | Path             | What happens                                            |
| ------------------------------------------------------------------- | ---------------- | ------------------------------------------------------- |
| `status="archived"` (alone or with others)                          | archive endpoint | Archives. **Other fields silently dropped.**            |
| `status="restored"` (alone or with others)                          | restore endpoint | Restores to `disabled`. **Other fields dropped.**       |
| `status="enabled"` or `"disabled"` alone                            | status-only      | Status flip only; ruleset preserved.                    |
| `status="enabled"` or `"disabled"` + `name`/`description`/`ruleset` | generic merge    | Status + metadata applied together; merge with current. |
| `name`/`description`/`ruleset` (no status)                          | generic merge    | Metadata/ruleset merged with current flag.              |

## Multi-rollout-group flags (UI-only)

The flag-update ruleset path supports flags with a **single** rollout group only. UI-created flags can have multiple rollout groups (e.g. cohort gates, geo splits, property targeting), and the single-rollout merge path collapses `ruleset.rollout` to a single-element list — silently destroying rollouts 2..N.

Before proposing a `ruleset` update on a flag the model didn't create, **inspect `len(ruleset.rollout)` on the flag**:

- `len(ruleset.rollout) == 1` → safe to update the ruleset.
- `len(ruleset.rollout) > 1` → the update path refuses with an actionable error pointing to the UI URL. Edit those flags in the Mixpanel UI; the single-rollout path can't safely express the multi-rollout shape.

Status-only flips (`status="enabled"|"disabled"|"archived"|"restored"` with no other fields) are still safe on multi-rollout flags — those paths don't re-send the ruleset, so no rollout groups are lost.

## Flag-update field reference

```
flag_id                      → Required: UUID of the flag
status                       → "enabled" | "disabled" | "archived" | "restored"
ruleset.rolloutPercentage    → Float in [0.0, 1.0] — the staged-rollout knob
ruleset.variants             → Replaces variants entirely; rare except in setup
name                         → Editable display name
description                  → Editable description; use for hand-off context
```

At least one field must be provided. Variants and rollout updates merge into the current ruleset (variants kept if not provided; rollout kept if not provided).

### Auto-injected by the session (do NOT ask the user)

```
project_id                   → Current Mixpanel project
workspace_id                 → Current workspace
```
