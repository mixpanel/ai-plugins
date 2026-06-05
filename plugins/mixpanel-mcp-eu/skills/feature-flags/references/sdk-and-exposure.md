# SDK call patterns and exposure tracking

This reference covers how the SDK reads a flag, the `$experiment_started` exposure event the SDK emits, and the diagnostic checklist for "no exposures after enable."

## SDK call shape

The SDK exposes two read entry points, returning different shapes:

- **Get the variant value only** (the value associated with the assigned variant — `true`/`false` for a Feature Gate, the payload for a Dynamic Config).
- **Get the full variant** (both the variant `key` and its `value`).

Branch on whatever shape the user actually needs in their code path. There is no entry point that returns only the key.

For exact per-language call signatures, point the user at the Mixpanel SDK docs for their platform (https://docs.mixpanel.com/docs/feature-flags) — call shapes evolve, and the docs are the source of truth.

A few sharp edges users hit:

- **The fallback variant is served if the SDK can't reach the flag service** (offline, request failure, or the current user is not in the rollout). **Pick a fallback that means "feature off"** so a network failure or a not-in-rollout default can't accidentally enable a half-shipped feature.
- **Sticky bucketing is by `distinct_id` by default.** A user with the same `distinct_id` sees the same variant across sessions. If you change the flag's `context` to a different identity property, users get re-bucketed — and exposures look like a flash mob to the analytics system.

## `$experiment_started` exposure events

The SDK emits a `$experiment_started` event each time a flag is evaluated via a tracking entry point. The event carries the flag key, the assigned variant key, and the variant value alongside the user's `distinct_id`.

Use these events to answer **"is the flag actually serving the variants I think it is?"** Group `$experiment_started` by variant over the rollout window and confirm the split matches the configured `rolloutPercentage` (within sampling noise).

A 50% rollout that shows a 60/40 split in `$experiment_started` is either:

- Sampling noise (small denominator), or
- A bucketing problem (the `context` field doesn't behave the way the user expects — e.g. anonymous users with rotating distinct_ids).

## "No exposures after enable" — diagnostic checklist

Work the checklist in order, most-likely cause first:

1. **Is `status: enabled`?** Most common cause of zero exposures by a wide margin. A flag at `disabled` serves the control variant to everyone regardless of `rolloutPercentage`, and no `$experiment_started` events fire for users who would have been in the rollout. Read the flag's current state first.
2. **Does the SDK code path actually call a tracking entry point?** Non-tracking variant-lookup calls intentionally suppress `$experiment_started`. Compare the flag key string exactly — typos are silent failures.
3. **Is the SDK initialized in the client?** Check for SDK init events. If the SDK never initializes (token missing, network blocked, error during boot), no flag events will ever fire.
4. **Are users in the targeted cohort/property bucket?** Check the `context` field of the flag and any cohort-based targeting configured in the UI. If the rollout targets `enterprise_paying` and no users are in that cohort yet, exposures will be zero.

## SDK convention summary

| Concern                             | Right answer                                                                                  |
| ----------------------------------- | --------------------------------------------------------------------------------------------- |
| Which entry point returns what?     | One returns the variant value; one returns the full variant (key + value). No key-only path.  |
| Fallback semantics                  | Pick a fallback that means "feature off" — covers offline, failure, and not-in-rollout.       |
| Sticky bucketing                    | By `distinct_id` by default; changing `context` re-buckets users                              |
| Track every evaluation?             | Use the tracking entry point. Use the non-tracking variant only when you don't want exposure. |
| Verify exposures match rollout?     | Query `$experiment_started` grouped by the variant key                                        |
| Missing exposures diagnostic order? | status → tracking entry point → SDK init → cohort/property bucket                             |
