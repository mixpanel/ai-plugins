# Routing and setup

Pick the right flag-shaped tool, then configure it. Getting the routing wrong is unrecoverable without deleting the flag, so this is the highest-leverage decision in feature-flag work.

## Picking the flag type

`SKILL.md` covers the three-row routing table at a glance. The deeper rationale:

- **Feature Gate (`flagType: "feature_gate"`)**: on/off toggle with two boolean-valued variants. Kill switches, gradual rollouts, geo gates, internal-only enables. The control variant is **value-based** — whichever variant has `value: false` is treated as control.
- **Dynamic Config (`flagType: "dynamic_config"`)**: serves a payload (string or JSON object) per user without measurement. Copy variations, theme keys, configuration objects. Control is **positional** — the first variant in the list. Booleans and bare numbers are rejected; numbers belong inside a JSON object (e.g. `{"ttl": 3600}`).
- **Experiment (via `Create-Experiment`)**: variant comparison with statistical machinery — primary metric, SRM checks, significance verdict. Backing flag is auto-created and linked. `Create-Feature-Flag` rejects `flagType: "experiment"` precisely to prevent the degenerate "experiment flag without an experiment to drive it" path.

The product boundary between Dynamic Config and Experiment is about **measurement, not payload shape**. If the user wants to pick a winner with statistical significance, route to `Create-Experiment` regardless of how simple the variants look.

## Required and optional inputs by flag type

### Feature Gate

| Field         | Required?    | Notes                                                                                                                                                   |
| ------------- | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`        | yes          | Human-readable display name.                                                                                                                            |
| `flagType`    | yes          | `"feature_gate"`.                                                                                                                                       |
| `variants`    | **optional** | Omit and the tool auto-generates the canonical `On`/`Off` pair (control = `Off`). Only pass `variants` if the user wants custom keys.                   |
| `key`         | optional     | Auto-derived from `name` with a short random suffix when omitted (collision-safe).                                                                      |
| `description` | optional     | Short text. Add automatically when the user gave you a hypothesis-shaped reason for the flag — it's the only context post-launch maintainers will have. |

If the user passes custom variants for a Feature Gate, pass exactly two, with **boolean** `value` fields, splits summing to `1.0`:

```
[{"key": "On", "value": true, "split": 0.5},
 {"key": "Off", "value": false, "split": 0.5}]
```

### Dynamic Config

| Field         | Required? | Notes                                                                                                                          |
| ------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `name`        | yes       | Human-readable display name.                                                                                                   |
| `flagType`    | yes       | `"dynamic_config"`.                                                                                                            |
| `variants`    | **yes**   | Splits sum to `1.0`. Every `value` is either a `string` or a JSON object (dict) — pick one shape and use it for every variant. |
| `key`         | optional  | Auto-derived; same behavior as Feature Gate.                                                                                   |
| `description` | optional  | Strongly recommended — readers can't guess what arbitrary payloads mean.                                                       |

For a single value served to everyone, pass one variant with `split: 1.0`:

```
[{"key": "blue", "value": "blue", "split": 1.0}]
```

For structured config, pass a JSON object directly as the `value` — no string-wrapping required:

```
[{"key": "dark", "value": {"theme": "dark", "ttl": 3600}, "split": 0.5},
 {"key": "light", "value": {"theme": "light", "ttl": 7200}, "split": 0.5}]
```

Mixing string values and JSON objects within a single flag is rejected; pick one shape per flag.

## Control variant: value-based for FG, positional for DC

This is the single subtlest rule in the API. Get it wrong and disabling the flag does the opposite of what disable should mean.

### Feature Gate: control = the `false`-valued variant

The Feature Gate convention is **value-based**, not positional: whichever variant has `value: false` is treated as control. Why this matters:

- Disabling the flag (`status: "disabled"`) serves the control variant to everyone. If your "control" had `value: true`, disabling the flag would silently turn the feature ON for all users — the opposite of what disable should mean.
- The FE renders the OFF variant on the safe side of the toggle UI.
- The rule is enforced server-side — passing custom variants with `value: false` not on the control variant triggers a misconfiguration the FE will surface.

Two-variant Feature Gates are the norm. The tool will accept more, but you're almost always better served by a Dynamic Config or an Experiment if you need three or more behaviors.

### Dynamic Config: control = the first variant (positional)

Pure positional. The first variant in the list is control. Order matters when reading results downstream — if you want a specific variant to be control, list it first.

### Split sum tolerance

Splits must sum to `1.0` within ±0.01. A 3-way even split — `0.33 + 0.33 + 0.33 = 0.99` or `0.34 + 0.33 + 0.33 = 1.00` — both pass. Anything outside `[0.99, 1.01]` is rejected.

## Naming and keying

Two practical rules:

1. **Don't ask the user for a `key` unless they mentioned one.** The system derives a slugified key from the name and appends a short random suffix to dodge collisions. The auto-key is almost always fine.
2. **Names should describe the gated behavior, not the experiment hypothesis.** `new_checkout_button_visible` will outlive `q2_checkout_redesign_test`. Push back gently if the user proposes a name tied to a calendar quarter, project codename, or person.

### Auto-key generation

The auto-key generator does, in order:

1. Pick the separator: `-` if the name contains a dash, otherwise `_`.
2. Tokenize the name with `re.findall(r"[A-Za-z0-9]+", name)` — strips every non-ASCII codepoint (so `café-naïve` becomes `caf-na-ve...`) and treats whitespace and punctuation as token boundaries. If no tokens survive (`!!!` → `[]`), the base falls back to the literal string `flag`.
3. Lowercase each token, join with the separator.
4. Append the separator and a 6-character base58 suffix (e.g. `_368fyv` or `-368fyv`).

The random suffix exists because flag keys are project-scoped and humans pick the same names independently. If the user explicitly wants a clean key (e.g. `new_checkout_v2` exact), pass it as `key` — but be aware that a collision causes the create to fail rather than silently suffix.

### Flag keys are immutable after creation

A user pattern to watch for: they ask for a flag, see the auto-key, then ask to "rename" it. **Flag keys are immutable.** The display `name` is editable via `Update-Feature-Flag`; the `key` is not. Tell the user this before they invest in a wrong key.

## Initial state — disabled by default

**Every newly created flag starts `disabled`.** The flag exists but the SDK serves the control variant to everyone. This is intentional — it gives the user one explicit step ("enable the flag") to gate the moment the rollout actually starts.

Do NOT pass `status: "enabled"` on creation as a shortcut. The right sequence is:

1. `Create-Feature-Flag` (status defaults to `disabled`)
2. Engineer ships SDK code that reads the flag (safe — flag returns control)
3. User explicitly calls `Update-Feature-Flag` with `status: "enabled"` once they're ready to ramp

For everything that happens after enable — staged rollout, kill switch, archival — see the lifecycle spine in `SKILL.md` and [staged-rollout.md](staged-rollout.md).

## Cohort targeting and advanced rollout (UI-only)

`Create-Feature-Flag` covers the common cases: a single rollout percentage applied uniformly to all targeted users. It does **not** cover:

- Cohort-based targeting (e.g. "only users in the `enterprise_paying` cohort")
- Multiple rollout rules (e.g. "100% in EU, 10% in US")
- User-property targeting (e.g. "users where `plan_tier == 'pro'`")
- Sticky-by-distinct-id-only (vs other identity properties)

For any of those, create the flag first via `Create-Feature-Flag`, then direct the user to the Mixpanel UI to configure advanced rollout — the URL is in the response from `Get-Feature-Flag`. Don't try to express advanced rollout via the MCP tool; the schema doesn't accept it.

## Setup field reference

Configure these on `Create-Feature-Flag` via the `flag` parameter payload.

### Required

```
flagType                     → "feature_gate" | "dynamic_config"
name                         → Human-readable display name
```

### Required by flag type

```
variants                     → Required for dynamic_config; optional for feature_gate
                                (auto-On/Off when omitted)
```

### Optional (safe defaults)

```
key                          → Auto-slugified from name with random suffix if omitted
description                  → Short text; recommended for dynamic_config
status                       → "disabled" (default; do not override on creation)
servingMethod                → "remote_or_local" (default) | "remote_only"
context                      → "distinct_id" (default)
rolloutPercentage            → 1.0 (100% of targeted traffic; cohort/property
                                targeting configured in UI)
```

### Variant shape (per variant)

```
key                          → Variant identifier; lowercase recommended
value                        → boolean (feature_gate only) | string OR JSON object (dynamic_config)
split                        → Fraction; must sum to 1.0 across variants
```

### Auto-injected by the session (do NOT ask the user)

```
project_id                   → Current Mixpanel project
workspace_id                 → Current workspace
```
