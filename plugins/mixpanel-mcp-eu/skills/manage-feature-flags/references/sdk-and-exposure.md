# SDK call patterns and exposure tracking

This reference covers how the SDK reads a flag, the exposure events it emits, and the diagnostic checklist for "no exposures after enable."

## SDK call shape

The SDK exposes two read entry points, returning different shapes:

- **Get the variant value only** (the value associated with the assigned variant — `true`/`false` for a Feature Gate, the payload for a Dynamic Config).
- **Get the full variant** (both the variant key and its value).

Branch on whatever shape the user actually needs in their code path. There is no entry point that returns only the key.

For exact per-language call signatures, point the user at the [Mixpanel feature-flags docs](https://docs.mixpanel.com/docs/featureflags) for their platform — call shapes evolve, and the docs are the source of truth.

A few sharp edges users hit:

- **The fallback variant is served if the SDK can't reach the flag service** (offline, request failure, or the current user is not in the rollout). **Pick a fallback that means "feature off"** so a network failure or a not-in-rollout default can't accidentally enable a half-shipped feature.
- **Sticky bucketing is by `distinct_id` by default.** A user with the same `distinct_id` sees the same variant across sessions. If the bucketing key is changed to a different identity property, users get re-bucketed — and exposures look like a flash mob to the analytics system.

## Exposure events

The SDK emits an exposure event each time a flag is evaluated via a **tracking** entry point. The event carries the flag key, the assigned variant key, and the variant value alongside the user's `distinct_id`. Non-tracking variant-lookup calls intentionally suppress exposure events.

Use exposure events to answer **"is the flag actually serving the variants I think it is?"** Group exposures by variant over the rollout window and confirm the split matches the configured rollout (within sampling noise).

A 50% rollout that shows a 60/40 split in exposures is either:

- Sampling noise (small denominator), or
- A bucketing problem — the bucketing key doesn't behave the way the user expects (e.g. anonymous users with rotating distinct_ids).

## "No exposures after enable" — diagnostic checklist

First rule out ingestion lag: exposure events are not instant. After enabling (and after real traffic has actually hit the flag's code path), give it a few minutes for events to land before treating a zero count as real. If exposures are still zero after that, work the checklist in order, most-likely cause first:

1. **Is the flag actually enabled?** Most common cause of zero exposures by a wide margin. A disabled flag serves control to everyone regardless of the rollout percentage, and no exposure events fire for users who would have been in the rollout. Read the flag's current state first.
2. **Does the SDK code path call the tracking entry point?** The non-tracking variant suppresses exposures by design. Also compare the flag key string exactly — typos are silent failures.
3. **Is the SDK initialized in the client?** Check for SDK init events. If the SDK never initializes (token missing, network blocked, error during boot), no flag events will ever fire.
4. **Are users in the targeted cohort?** If the rollout targets a cohort like `enterprise_paying` and no users are in that cohort yet, exposures will be zero.

## SDK convention summary

| Concern                             | Right answer                                                                                  |
| ----------------------------------- | --------------------------------------------------------------------------------------------- |
| Which entry point returns what?     | One returns the variant value; one returns the full variant (key + value). No key-only path.  |
| Fallback semantics                  | Pick a fallback that means "feature off" — covers offline, failure, and not-in-rollout.       |
| Sticky bucketing                    | By `distinct_id` by default; changing the bucketing key re-buckets users.                     |
| Track every evaluation?             | Use the tracking entry point. Use the non-tracking variant only when you don't want exposure. |
| Verify exposures match rollout?     | Group exposure events by variant and compare to the configured rollout.                       |
| Missing exposures diagnostic order? | Flag state → tracking entry point → SDK init → cohort/property bucket.                        |
