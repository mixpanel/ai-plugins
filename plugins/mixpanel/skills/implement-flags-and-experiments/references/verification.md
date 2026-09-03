# Verification

How to test a flag locally before any rollout, how to prove the implementation works, and what to check when it doesn't.

"The code compiles and returns a value" is not verification — the fallback is also a value, and a fully broken implementation returns it cleanly.

---

## Testing locally, before any rollout

The customer's first question is usually "how do I see the variant on my machine without shipping it to anyone?" Three options, best first.

### QA tester allowlist

Flags support an explicit allowlist of test users, selected by their `$email` user profile property, with a per-user choice of which variant they receive. This is the intended mechanism: no rollout percentage, no cohort, no code changes.

Two constraints worth stating up front:

- The user must have identified at least once with the email/identity being allowlisted, so there is a profile to match against.
- On projects using the original ID-merge behaviour, the allowlist stores a **snapshot** of the user's identity at the moment they were added, and matches it exactly at evaluation time. If the app's identification logic changes afterward, or the user moves between anonymous and identified states, the snapshot goes stale and the flag silently stops returning for them. **Fix: remove the QA tester and re-add them**, which re-snapshots. Projects on the newer simplified ID merge use a deterministic canonical ID and don't have this problem.

### A cohort of one

Create a cohort containing just the developer's test account and target the flag at it with 100% rollout. Works everywhere, but cohort membership refreshes on a periodic cadence (roughly every two hours) — a user added to a cohort moments ago will not match yet. This is the single most common "I set it up correctly and it still doesn't work" report. Wait, then retest.

### Runtime property

Pass something like `environment: "dev"` in `custom_properties` and target on it. Immediate — no refresh delay — and useful when the same project serves multiple environments. Requires the property to be in the evaluation context on every call.

---

## The verification loop

Run this before enabling for anyone real, and before launching any experiment.

**1. Confirm the evaluation returns a real variant.**

Log the value at the call site. If it equals the fallback, the flag is not reaching this user — go to the diagnostic checklist below. Do not proceed.

**2. Confirm the variant source is `network`.**

Where the SDK exposes it (client SDKs, via the full-variant getter), check the source field. `fallback` means no assignment was received. `persistence` means a cached assignment was served — fine in production, but during first verification it can mask a broken network path, so clear persisted state and retest.

**3. Confirm an exposure event actually arrived.**

Exercise the code path, then look for the exposure event in Mixpanel — Live View is the fastest surface. Confirm three things on the event: the flag key matches, the variant matches what the code received, and the identity is the one you expect.

**Allow for ingestion lag before concluding anything is wrong.** Events usually surface within seconds, but SDK batching, server-side buffering, or a CDP in the path can stretch that. If Live View shows events arriving at all, don't wait on the report.

**4. Confirm the split, once traffic is real.**

After the flag is serving real users, group exposures by variant and compare against the configured allocation. A 50/50 flag showing 60/40 is either a small denominator or a bucketing problem — see below.

---

## Diagnostic checklist

Work in order. Cheapest and most likely first.

### Always getting the fallback

1. **Is the flag enabled?** A disabled flag serves control to everyone regardless of rollout percentage. The most common cause by a wide margin.
2. **Does the flag key in code match the key in Mixpanel exactly?** Not the display name — the key. Typos fail silently.
3. **Is the SDK version at or above the minimum?** Below it, flags never return and no error is raised. Versions are in [sdk-snippets.md](sdk-snippets.md).
4. **Does init actually enable flags?** Flags are off by default. An SDK that tracks events happily will still return no flags.
5. **Is every targeting input present in the context?** If the flag buckets on a key other than `distinct_id`/`device_id`, that key must be in the init/evaluation context. If it uses runtime-property targeting, those properties must be in `custom_properties` inside the context. Missing either is a silent no-match.
6. **Is the user in the rollout?** Check rollout percentage, cohort membership, and targeting filters. Remember the cohort refresh delay.
7. **Is the region host right?** EU and India projects must point at their regional host. A US host with an EU token returns nothing.
8. **On mobile: is prefetch disabled?** If flags aren't fetched at init, nothing is available until `identify()` or an explicit load call.
9. **Is the evaluation call actually reached?** Log at the call site. Dead code looks exactly like a broken flag.

**Web debugging shortcut:** inspect the `/flags/` network request in browser devtools. The response shows which flags were returned for this user, and the payload's test-user field lists the identities on the QA allowlist — compare those against the `distinct_id` the SDK is actually sending. A mismatch there explains most QA-tester failures.

### Correct variants, but zero exposures

1. **Is the branching driven by an all-variants call?** Those never fire exposure. See [exposure-correctness.md](exposure-correctness.md).
2. **Is tracking opted out?** Exposure events are dropped while opted out and are not replayed on consent.
3. **Has the exposure event been reconfigured** to a custom event? Then look for that event, not the default one.
4. **Is the fallback being served?** Fallbacks fire no exposure — this is the always-fallback case above wearing a different hat.

### Skewed variant split

1. **Small denominator.** Check the absolute counts before concluding anything.
2. **Unstable bucketing key.** Anonymous users with rotating identifiers re-bucket constantly. Confirm the assignment key is stable for the population being measured.
3. **Evaluation racing identify.** If the flag is evaluated before `identify()` resolves, the user is bucketed on their pre-identify identity and re-bucketed after. Client SDKs reload flags on identify — evaluation must happen after.
4. **Mixed environments in one project.** Dev and prod traffic in the same project with the same flag will blend.

---

## What "verified" means

Say the implementation is verified only when all of these are true:

- A real evaluation returned a non-fallback variant.
- An exposure event arrived in Mixpanel with the correct flag key, variant, and identity.
- The variant the code branched on matches the variant in the exposure event.

Until then the correct status is "implemented, not yet verified." The distinction matters most right before an experiment launch, which is irreversible.
