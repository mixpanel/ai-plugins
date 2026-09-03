# Verification

How to test a flag before any rollout, how to prove the implementation works, and what to check when it doesn't.

*Source: the Mixpanel feature-flags docs at docs.mixpanel.com. Product behaviour and timings change — verify against current docs before relying on any specific value below.*

"The code compiles and returns a value" is not verification — the fallback is also a value, and a fully broken implementation returns it cleanly.

## Contents

- [Getting yourself served a variant](#getting-yourself-served-a-variant)
- [The verification loop](#the-verification-loop)
- [Always getting the fallback](#always-getting-the-fallback)
- [Wrong variant](#wrong-variant)
- [Correct variants, but zero exposures](#correct-variants-but-zero-exposures)
- [Skewed variant split](#skewed-variant-split)
- [What "verified" means](#what-verified-means)

The exposure event is named `$experiment_started` — that is what to search for in Live View.

---

## Getting yourself served a variant

**The flag must be enabled first.** A disabled flag serves control to everyone no matter what else is configured, so nothing below works until it is on. Enabling is the customer's call — ask them to do it rather than doing it yourself.

Three ways to get a variant, ordered least-invasive first.

### QA tester allowlist — the one this skill uses

Flags support an explicit allowlist of test users with a per-user choice of variant. No rollout percentage, no cohort, no code changes. **This is the option to reach for**, because it is the only one that doesn't require changing rollout configuration.

Two constraints:

- The user must have identified at least once with the identity being allowlisted, so there is a profile to match.
- On projects using the original ID-merge behaviour, the allowlist stores a **snapshot** of the user's identity when they were added and matches it exactly at evaluation. If the app's identification logic changes afterward, or the user moves between anonymous and identified states, the snapshot goes stale and the flag silently stops returning for them. **Fix: remove the QA tester and re-add them**, which re-snapshots. Projects on the newer simplified ID merge use a deterministic canonical ID and don't have this problem.

### The other two — customer-owned configuration

Both of these change rollout configuration, which the `manage-feature-flags` skill owns. Don't configure them yourself; describe what's needed and ask the customer to set it up.

- **A cohort of one** — a cohort containing just the test account, targeted at 100%. Works everywhere, but cohort membership refreshes on a periodic cadence (roughly every two hours at time of writing — treat that as an order of magnitude, not an SLA), so a user added moments ago will not match yet. This delay is the single most common "I set it up correctly and it still doesn't work" report. Wait, then retest.
- **A runtime property** — you pass `environment: "dev"` in `custom_properties` at init (that part is code, and this skill's job); the customer configures the rule that targets on it. Immediate, with no refresh delay. Note the parent skill defaults to separate projects per environment; this option suits customers who deliberately run one project.

---

## The verification loop

Run this before enabling for anyone real, and before launching any experiment.

### 1. Confirm the evaluation returns a real variant

Log the value at the call site. If it equals the fallback, the flag is not reaching this user — work [Always getting the fallback](#always-getting-the-fallback). Do not proceed.

### 2. Confirm the variant source is `network`

Client SDKs expose where the value came from — `variant_source` on JavaScript and React Native, `.source` on Swift, Android and Flutter (see [sdk-snippets.md](sdk-snippets.md) for the getter that returns it). `fallback` means no assignment arrived. `persistence` means a cached assignment was served, which is fine in production but can mask a broken network path during first verification — clear it by calling `identify()` with a different ID or `reset()`, then retest.

### 3. Confirm an exposure event arrived

Exercise the code path, then look for `$experiment_started` in Live View. Check three things on the event: the flag key matches, the variant matches what the code received, and the identity is the one you expect.

**Allow for ingestion lag before concluding anything is wrong.** Events usually surface within seconds, but SDK batching, server-side buffering, or a customer data platform in the path can stretch it. If Live View shows events arriving at all, don't wait for them to appear in a saved report. If Live View shows nothing, allow up to 24 hours before treating a zero as real.

### 4. Confirm the split, once traffic is real

Group exposures by variant and compare against the configured allocation. A 50/50 flag showing 60/40 is either a small denominator or a bucketing problem — see [Skewed variant split](#skewed-variant-split).

---

## Always getting the fallback

Ordered by what is cheapest to rule out against how often it is the cause — not strictly by cost. Work it top to bottom rather than jumping to the interesting hypothesis.

1. **Is the flag enabled?** A disabled flag serves control to everyone regardless of rollout percentage. The most common cause by a wide margin.
2. **Is the flag archived?** Archiving stops SDK evaluation outright, so an archived flag serves the fallback forever. It also hides the flag from default listings, which is why this is easy to miss when the key looks correct.
3. **Does the flag key in code match the key in Mixpanel exactly?** Not the display name — the key. Typos fail silently.
4. **Is the evaluation call actually reached?** Log at the call site. Dead code looks exactly like a broken flag, and this rules out the entire code path in seconds.
5. **Is the token the right project's?** With separate projects per environment, dev code pointing at the prod project (or the reverse) returns nothing for flags that exist only in the other one.
6. **Is the region host right?** EU and India projects must point at their regional host. A US host with an EU token returns nothing.
7. **Is the SDK version at or above the minimum?** Below it, flags never return and no error is raised. Versions are in [sdk-snippets.md](sdk-snippets.md).
8. **Does init actually enable flags?** Flags are off by default. An SDK that tracks events happily will still return no flags.
9. **On mobile: is prefetch disabled?** If flags aren't fetched at init, nothing is available until `identify()` or an explicit load call.
10. **Is every targeting input present in the context?** A flag bucketing on a key other than `distinct_id`/`device_id` needs that key in the context; runtime-property targeting needs those properties in `custom_properties`. Missing either is a silent no-match.
11. **Is the user in the rollout?** Rollout percentage, cohort membership, and targeting filters all gate assignment. Remember the cohort refresh delay.

**Web debugging shortcut:** inspect the flags network request in browser devtools. The response shows which flags were returned for this user, and lists the identities on the QA allowlist — compare those against the `distinct_id` the SDK is actually sending. A mismatch there explains most QA-tester failures. (Response shape is internal and may change; use it as a diagnostic, not a contract.)

---

## Wrong variant

The flag returns a variant, but not the one expected. Different causes from the fallback case.

1. **Is this identity on the QA tester allowlist?** The allowlist pins a chosen variant per user, which overrides normal bucketing — so the account being tested with is exactly the account most likely to report a "wrong" variant. Check it first.
2. **Is a stale persisted assignment being served?** Check the variant source. `persistence` means the value predates any recent config change. Clear with `identify()` on a different ID or `reset()`, then retest.
3. **Is the evaluation racing `identify()`?** Client SDKs reload flags on identify. Evaluating before it resolves buckets the user on their pre-identify identity, then re-buckets after — so the first render can differ from every later one.
4. **Was the variant assignment key changed?** It cannot be changed once the flag is enabled, but if the flag was recreated, previously-bucketed users land elsewhere.
5. **Are variant splits or rollout percentage recently changed?** Raising rollout alone does not re-bucket users, but changing splits, or lowering then raising rollout, can. Sticky variants override this.
6. **Is more than one flag gating the same branch?** Two flags on one code path produce results neither one explains.

---

## Correct variants, but zero exposures

1. **Have the events had time to arrive?** Rule this out before anything else — see the ingestion-lag bound in [Confirm an exposure event arrived](#3-confirm-an-exposure-event-arrived). A zero that is only minutes old is not yet a zero.
2. **Is the branching driven by an all-variants call?** Those never fire exposure. See [exposure-correctness.md](exposure-correctness.md).
3. **Is tracking opted out?** Exposure events are dropped while opted out and are not replayed on consent.
4. **Has the exposure event been reconfigured** to a custom event? Then look for that event, not `$experiment_started`.
5. **Is the fallback being served after all?** Fallbacks fire no exposure — if so, this is [Always getting the fallback](#always-getting-the-fallback) wearing a different hat.

---

## Skewed variant split

1. **Small denominator.** Check the absolute counts before concluding anything.
2. **QA testers in the population.** Allowlisted testers are pinned to a chosen variant rather than bucketed, so they skew the split hardest when overall volume is still low.
3. **Unstable bucketing key.** Anonymous users with rotating identifiers re-bucket constantly. Confirm the assignment key is stable for the population being measured.
4. **Evaluation racing identify.** As in [Wrong variant](#wrong-variant) — at population scale this shows up as a skewed split.
5. **Mixed environments in one project.** Dev and prod traffic on the same flag will blend, unless targeting separates them on an environment runtime property.

---

## What "verified" means

Say the implementation is verified only when a real evaluation returned a non-fallback variant, an `$experiment_started` event arrived with the correct flag key and identity, and the variant the code branched on matches the variant on that event.

Until all three hold, the correct status is **"implemented, not yet verified."** The distinction matters most right before an experiment launch, which is irreversible.
