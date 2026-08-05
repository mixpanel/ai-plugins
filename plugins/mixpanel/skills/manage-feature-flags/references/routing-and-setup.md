# Routing and setup

Pick the right flag-shaped product, then configure it. Getting the routing wrong is unrecoverable without deleting the flag, so this is the highest-leverage decision in feature-flag work.

## Picking the flag type

`SKILL.md` covers the three-row routing table at a glance. The deeper rationale:

- **Feature Gate**: on/off toggle with two boolean-valued variants. Kill switches, gradual rollouts, geo gates, internal-only enables. Control is the variant whose value means "feature off." Pick a Feature Gate when the user wants a single behavior gated; pick a Dynamic Config when they want to vary _what_ users see beyond on/off.
- **Dynamic Config**: serves a payload (string or JSON object) per user without measurement. Copy variations, theme keys, configuration objects. Control is the first variant in the list (positional, not value-based). Bare booleans and numbers are rejected; numbers belong inside a JSON object.
- **Experiment** (created via the experiment-creation path): variant comparison with statistical machinery — primary metric, health checks, significance verdict. The backing flag is auto-created and linked. Direct flag creation rejects the experiment flag type precisely to prevent the degenerate "experiment flag without an experiment to drive it" path.

The product boundary between Dynamic Config and Experiment is about **measurement, not payload shape**. If the user wants to pick a winner with statistical significance, route to experiment creation regardless of how simple the variants look.

## Variant shape — what to pass

### Feature Gate

The canonical pair is `On` / `Off`. Omit variants entirely on creation and the system generates this pair automatically with a 50/50 split — that's almost always the right call. Only pass custom variants when the user has explicitly asked for non-canonical keys.

If you do pass custom variants, the rules are:

- Exactly two variants.
- Each variant's value is a **boolean**.
- Splits sum to `1.0`.
- The "off" variant (value `false`) is what the system treats as control. See [Control variant](#control-variant-value-based-for-feature-gates-positional-for-dynamic-configs) below for why this matters.

### Dynamic Config

Variants are required — there's no sensible default. The rules:

- Splits sum to `1.0`.
- Every variant's value is either a string or a JSON object. Pick one shape per flag — mixing string variants and object variants in the same flag is rejected.
- For a single value served to everyone, pass one variant with split `1.0`.
- For structured config, pass JSON objects directly — no string-wrapping required (e.g. a variant value of `{"theme": "dark", "max_items": 20}`, versus string values like `"Buy now"` for a copy-variation flag).

### Split sum tolerance

Splits must sum to `1.0` within a small tolerance (currently ±0.01 — verify against the current API). A 3-way even split — `0.33 + 0.33 + 0.33 = 0.99` or `0.34 + 0.33 + 0.33 = 1.00` — both pass; anything well outside the band is rejected.

## Control variant: value-based for Feature Gates, positional for Dynamic Configs

This is the single subtlest rule in flag setup. Get it wrong and disabling the flag does the opposite of what disable should mean.

### Feature Gate: control is the `false`-valued variant

The Feature Gate convention is **value-based**, not positional: whichever variant's value is `false` is treated as control. Why this matters:

- Disabling the flag serves the control variant to everyone. If your "control" had value `true`, disabling would silently turn the feature ON for all users — the opposite of what disable should mean.
- The UI renders the OFF variant on the safe side of the toggle.
- The rule is enforced server-side (verify against the current API) — custom variants that put the false-valued variant on the non-control side surface a misconfiguration error.

Two-variant Feature Gates are the norm. The system will accept more, but if the user needs three or more behaviors, they almost certainly want a Dynamic Config or an Experiment instead.

### Dynamic Config: control is the first variant (positional)

Pure positional. The first variant in the list is control. Order matters when reading results downstream — if the user wants a specific variant to be control, list it first.

## Naming and keying

Two practical rules:

1. **Don't ask the user for a key unless they mentioned one.** The system derives a slugified key from the name and appends a short random suffix to avoid collisions. The auto-key is almost always fine.
2. **Names should describe the gated behavior, not the experiment hypothesis.** `new_checkout_button_visible` will outlive `q2_checkout_redesign_test`. Push back gently if the user proposes a name tied to a calendar quarter, project codename, or person.

### Auto-key generation — two sharp edges

The auto-key generator slugifies the name and appends a short random suffix for collision safety. Two surprises worth surfacing:

- **Non-ASCII characters are stripped.** A name like `café-naïve` produces a key like `caf-na-ve-<suffix>`. If the user cares about the key form, propose an ASCII version of the name up front.
- **The random suffix is always appended**, even with no collision. If the user wants a clean key (e.g. exactly `new_checkout_v2`), they need to pass it explicitly — but a collision will then cause the create to fail rather than silently suffix.

### Flag keys are immutable after creation

A user pattern to watch for: they ask for a flag, see the auto-key, then ask to "rename" the key. **Flag keys are immutable.** The display name is editable; the key is not. Surface this _before_ the user invests in the wrong key.

## Initial state — disabled by default

**Every newly created flag starts disabled.** The flag exists but the SDK serves the control variant to everyone. This is intentional — it gives the user one explicit step ("enable the flag") to gate the moment the rollout actually starts.

Don't try to shortcut this by passing an enabled status on creation. The right sequence is:

1. Create the flag (starts disabled).
2. Engineer ships SDK code that reads the flag (safe — flag returns control).
3. User explicitly enables the flag once they're ready to ramp.

For everything that happens after enable — staged rollout, kill switch, archival — see the lifecycle spine in `SKILL.md`, which links the staged-rollout reference.

## Cohort targeting and advanced rollout (UI-only)

The flag-creation path covers the common cases: a single rollout percentage applied uniformly to all targeted users. It does **not** cover:

- Cohort-based targeting (e.g. "only users in the `enterprise_paying` cohort")
- Multiple rollout rules (e.g. "100% in EU, 10% in US")
- User-property targeting (e.g. "users where `plan_tier == 'pro'`")
- Sticky-by-something-other-than-distinct-id

For any of those, create the flag first, then direct the user to the Mixpanel UI to configure advanced rollout — the URL is in the flag-details response. Don't try to express advanced rollout programmatically; the schema doesn't accept it.
