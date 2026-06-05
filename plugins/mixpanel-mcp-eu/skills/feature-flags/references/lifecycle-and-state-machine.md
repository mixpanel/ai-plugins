# Lifecycle and state machine

The three observable states `Get-Feature-Flag` will ever return are `disabled`, `enabled`, and `archived`. `restored` is a write-only verb — never a state you'll see when reading the flag back.

## Status state machine

Transitions are sent as the `status` value on `Update-Feature-Flag`:

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

The flag must be `disabled` before you can archive it. Calling `Update-Feature-Flag(status="archived")` on an `enabled` flag returns `FAILED_PRECONDITION: Cannot archive an enabled flag`. Disable first, then archive — two calls:

```
Update-Feature-Flag(flag_id=<id>, status="disabled")
Update-Feature-Flag(flag_id=<id>, status="archived")
```

This is intentional: archiving is a terminal cleanup action, and disabling first forces a moment of "are you sure traffic is off?" before the flag becomes read-only.

## `restored` is a write-only verb

`restored` only appears as an input to `Update-Feature-Flag`; `Get-Feature-Flag.status` will never be `restored`. It exists for "I archived this by mistake" recovery, not as a normal lifecycle state.

A restored flag lands back in `disabled`. It does **not** restore variants if you mutated them while archived (variants are immutable post-archive anyway).

## `Update-Feature-Flag` call shapes — three short-circuit paths

`Update-Feature-Flag` routes through one of three paths depending on which fields you send. Picking the right call shape per intent prevents silent drops and unintended overwrites.

### 1. Archive or restore — short-circuit, drops everything else

```
Update-Feature-Flag(flag_id=<id>, status="archived")
Update-Feature-Flag(flag_id=<id>, status="restored")
```

Routes straight to the dedicated archive/restore endpoint. **Any `name` / `description` / `ruleset` you pass alongside is silently dropped** — the short-circuit returns before the merge logic runs.

If you want to archive AND rename, do it as two calls (rename first, then archive):

```
Update-Feature-Flag(flag_id=<id>, name="new_name")
Update-Feature-Flag(flag_id=<id>, status="disabled")
Update-Feature-Flag(flag_id=<id>, status="archived")
```

### 2. Status-only flip — safe ruleset-preserving path

```
Update-Feature-Flag(flag_id=<id>, status="enabled")
Update-Feature-Flag(flag_id=<id>, status="disabled")
```

Status-only (no other fields) routes through the `set_flag_status` path, which avoids re-sending the ruleset and so can't accidentally clobber it on a status-only flip.

This is the right shape for "enable the flag" and "kill the flag" — the common kill-switch case.

### 3. Generic merge — for everything else

```
Update-Feature-Flag(flag_id=<id>, status="enabled", description="rolling to 100%")
Update-Feature-Flag(flag_id=<id>, ruleset={"rolloutPercentage": 0.10})
Update-Feature-Flag(flag_id=<id>, name="new_name", description="...")
```

Falls through to the generic merge path, which is fully supported. The status change (if any) and the metadata edit are applied together, and unspecified fields are preserved by re-fetching the current flag and merging.

### Summary table

| Call shape                                                          | Path              | What happens                                            |
| ------------------------------------------------------------------- | ----------------- | ------------------------------------------------------- |
| `status="archived"` (alone or with others)                          | archive endpoint  | Archives. **Other fields silently dropped.**            |
| `status="restored"` (alone or with others)                          | restore endpoint  | Restores to `disabled`. **Other fields dropped.**       |
| `status="enabled"` or `"disabled"` alone                            | `set_flag_status` | Status flip only; ruleset preserved.                    |
| `status="enabled"` or `"disabled"` + `name`/`description`/`ruleset` | generic merge     | Status + metadata applied together; merge with current. |
| `name`/`description`/`ruleset` (no status)                          | generic merge     | Metadata/ruleset merged with current flag.              |

## Multi-rollout-group flags (UI-only)

`Update-Feature-Flag(ruleset=...)` supports flags with a **single** rollout group only. UI-created flags can have multiple rollout groups (e.g. cohort gates, geo splits, property targeting), and the MCP merge path collapses `ruleset.rollout` to a single-element list — silently destroying rollouts 2..N.

Before proposing a `ruleset` update on a flag the model didn't create, **inspect `len(ruleset.rollout)` from `Get-Feature-Flag`**:

- `len(ruleset.rollout) == 1` → safe to update via `Update-Feature-Flag(ruleset=...)`.
- `len(ruleset.rollout) > 1` → the MCP refuses with an actionable error pointing to the UI URL. Edit those flags in the Mixpanel UI; the MCP can't safely express the multi-rollout shape.

Status-only flips (`Update-Feature-Flag(status="enabled"|"disabled"|"archived"|"restored")` with no other fields) are still safe on multi-rollout flags — those paths don't re-send the ruleset, so no rollout groups are lost.

## `Update-Feature-Flag` field reference

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
