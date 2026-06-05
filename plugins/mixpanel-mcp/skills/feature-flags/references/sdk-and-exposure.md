# SDK call patterns and exposure tracking

This reference covers how the SDK reads a flag, the `$feature_flag_called` exposure event the SDK emits, and the diagnostic checklist for "no exposures after enable."

## SDK call shape

The standard SDK call is:

```javascript
mixpanel
  .getFeatureFlag("<flag_key>", { fallback: "<default_variant_key>" })
  .then((variant) => {
    // variant is the variant.key string ("On", "Off", "treatment", etc.)
    if (variant === "treatment") {
      /* show new behavior */
    }
  });
```

A few sharp edges users hit:

- **The SDK returns a variant key (string), not the variant value.** For a Feature Gate, the key is `"On"` or `"Off"`; the value is `true` or `false`. **Branch on key, not on value**, unless you've explicitly set custom variants and you know what the values mean.
- **The fallback variant is served if the SDK can't reach the flag service** (offline, request failure). **Pick a fallback that means "feature off"** so a network failure can't accidentally enable a half-shipped feature.
- **Sticky bucketing is by `distinct_id` by default.** A user with the same `distinct_id` sees the same variant across sessions. If you change the flag's `context` to a different identity property, users get re-bucketed — and exposures look like a flash mob to the analytics system.

## `$feature_flag_called` exposure events

The SDK emits an event each time a flag is evaluated via the tracking entry point (`getFeatureFlag` / `is_feature_enabled` etc.):

```
{
  "event": "$feature_flag_called",
  "properties": {
    "$feature_flag_key": "new_checkout_button",
    "$feature_flag_variant": "treatment",
    "$feature_flag_variant_value": true,
    "distinct_id": "user_123",
    ...
  }
}
```

Use these events to answer **"is the flag actually serving the variants I think it is?"** Group `$feature_flag_called` by `$feature_flag_variant` over the rollout window and confirm the split matches the configured `rolloutPercentage` (within sampling noise).

A 50% rollout that shows a 60/40 split in `$feature_flag_called` is either:

- Sampling noise (small denominator), or
- A bucketing problem (the `context` field doesn't behave the way the user expects — e.g. anonymous users with rotating distinct_ids).

## "No exposures after enable" — diagnostic checklist

Work the checklist in order, most-likely cause first:

1. **Is `status: enabled`?** Most common cause of zero exposures by a wide margin. A flag at `disabled` serves the control variant to everyone regardless of `rolloutPercentage`, and no `$feature_flag_called` events fire for users who would have been in the rollout. Read the flag's current state first.
2. **Does the SDK code path actually call the tracking entry point?** `mixpanel.getFeatureFlag('<key>')` etc. Calls to the no-track variants (`getFeatureFlagWithoutTracking`) intentionally suppress `$feature_flag_called`. Compare the key string exactly — typos are silent failures.
3. **Is the SDK initialized in the client?** Check for SDK init events. If the SDK never initializes (token missing, network blocked, error during boot), no flag events will ever fire.
4. **Are users in the targeted cohort/property bucket?** Check the `context` field of the flag and any cohort-based targeting configured in the UI. If the rollout targets `enterprise_paying` and no users are in that cohort yet, exposures will be zero.
5. **`serving_method` is NOT the cause.** `serving_method` (`remote_or_local` vs `remote_only`) controls how the SDK fetches flag definitions, **not whether exposures are emitted** — neither value disables `$feature_flag_called`. Don't blame this field for missing exposures.

## `serving_method` — what it does and doesn't do

- `remote_or_local` (default): the SDK may evaluate flags locally when definitions are cached, otherwise queries the server.
- `remote_only`: the SDK always queries the server for each evaluation.

Neither setting affects exposure tracking. The `$feature_flag_called` event is emitted by the **tracking call site** (`getFeatureFlag` vs `getFeatureFlagWithoutTracking`), independent of how the SDK got the definition.

When users blame `serving_method` for missing exposures, the real cause is almost always either `status: disabled` or a no-track SDK call site. Redirect them to the diagnostic checklist above.

## SDK convention summary

| Concern                             | Right answer                                                                                                        |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| Branch on what?                     | `variant.key` (string), not `variant.value`                                                                         |
| Fallback semantics                  | Pick a fallback that means "feature off"                                                                            |
| Sticky bucketing                    | By `distinct_id` by default; changing `context` re-buckets users                                                    |
| Track every evaluation?             | Use `getFeatureFlag` (tracks). Use `getFeatureFlagWithoutTracking` only when you don't want `$feature_flag_called`. |
| Verify exposures match rollout?     | Query `$feature_flag_called` grouped by `$feature_flag_variant`                                                     |
| Missing exposures diagnostic order? | status → tracking entry point → SDK init → cohort/property bucket → (not `serving_method`)                          |
