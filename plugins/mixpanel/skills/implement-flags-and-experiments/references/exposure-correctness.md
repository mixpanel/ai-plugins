# Exposure correctness

The exposure event is what makes a flag measurable. Nearly every experiment-invalidating bug is an exposure bug, and most of them are silent — the feature works, the code looks right, and the analysis is wrong.

Read this before writing evaluation calls on a server SDK, before wiring an experiment, and before implementing anything behind a consent gate.

---

## Assignment is not exposure

- **Assignment** — the flag service decides which variant this user gets. Happens at init (client) or at evaluation (server).
- **Exposure** — the user actually reached the code path that uses the variant. Recorded as an `$experiment_started` event.

Analysis is built on exposure, not assignment. This is why the placement of the evaluation call matters: it should sit where the variant changes what the user sees. Evaluate at app boot for a flag that gates a checkout button and you have declared every user who opened the app as "exposed to the checkout experiment," including everyone who never reached checkout. The experiment then measures a diluted effect and may never reach significance.

The inverse error is rarer but worse: evaluating so deep in the funnel that only converting users are exposed. Lift then looks enormous and meaningless.

---

## Client SDKs deduplicate. Server SDKs do not.

**Client SDKs** deduplicate the exposure event per flag for **the lifetime of the SDK instance**. Calling the getter in a render loop does not produce thousands of exposures. But note the scope — a page reload, an app restart, or a new session is a new instance and will fire again. That is correct and expected; downstream analysis handles repeat exposures per user.

**Server SDKs do not deduplicate.** Every evaluation call fires an exposure event. A flag checked once per request will emit one exposure per request — thousands per user per day.

This matters in three ways:

1. **Analysis.** Exposure counts stop being user counts.
2. **Volume.** Exposure events are events. High-traffic server paths generate a lot of them.
3. **Correctness.** The intended semantic is one exposure per user per experiment, on first exposure. On a server SDK that is the implementer's job, not the SDK's.

### Implementing first-exposure-only on a server SDK

Suppress automatic exposure at evaluation, then fire it yourself exactly once when the user is genuinely exposed:

1. Evaluate with exposure suppressed (the API differs by language — see [sdk-snippets.md](sdk-snippets.md)).
2. Branch on the variant as normal.
3. On the path where the user actually sees the variant, check your own store for whether this user has already been exposed to this flag.
4. If not, call the SDK's exposure-tracking method and record that you did.

The "have I already exposed this user" store is application state — a session flag, a cache key, or a column, depending on how durable it needs to be. There is no SDK-provided equivalent.

**If that is more machinery than the customer wants**, the honest fallback is to leave automatic exposure on and accept repeat exposures. Say so explicitly rather than letting them assume one-per-user semantics they don't have. Repeat exposures do not invalidate an experiment on their own — Mixpanel attributes events to a user's exposure — but the customer should know which semantics they're operating under.

---

## Calls that fire exposure, and calls that don't

**Fire exposure:** the variant-value getters, the boolean checks, and the full-variant getters — in both their async and sync forms.

**Does not fire exposure:** the "evaluate all flags at once" method, on every SDK that has one (`getAllVariants`, `get_all_variants`, `GetAllVariants`, `getAllVariantsByFlag`).

This is the single most likely way to end up with a live experiment collecting nothing. The pattern looks efficient — one call, all flags, no per-flag network cost — and it is, but it is an *assignment* API, not an *exposure* API. If a customer uses it to drive real branching, they must call the exposure-tracking method themselves for each flag the user is actually exposed to.

**Fallback variants never fire exposure.** When the flag service is unreachable, or the user isn't in any rollout group, the fallback is returned and no `$experiment_started` is emitted. So "zero exposures" and "everyone is getting the fallback" are the same symptom.

---

## Exposure fires even when no experiment is running

Evaluating a flag emits `$experiment_started` whether or not that flag is attached to an active experiment. A plain feature gate that has been at 100% for a year is still emitting exposure events on every evaluation.

Two consequences:

- Exposure volume is driven by evaluation volume, not by how many experiments are running.
- This is a reason to actually remove flag code once a flag reaches a terminal state, rather than leaving the branch in place forever.

---

## Consent gating

If the SDK is opted out of tracking, an evaluation still returns a variant but the exposure event is **dropped, not queued**. It is not replayed when consent is granted later in the session.

This breaks the common consent pattern: page loads, code evaluates the flag to decide what to render, user accepts the cookie banner several seconds later. The variant was served; the exposure was lost. The experiment under-counts, and it under-counts *non-uniformly* — biased toward users who consent slowly or not at all.

Options, in order of preference:

1. **Evaluate after consent.** Move the evaluation behind the consent gate so it never runs while opted out. Cleanest, but only viable if the gated feature isn't needed on first paint.
2. **Re-fire exposure after consent.** Keep the evaluation early, and once consent is granted, explicitly track the exposure for the variant that was served. Requires holding the variant in memory across the consent transition.
3. **Accept the loss** and document it. Only defensible if consent rates are high and uniform, which is rarely true.

On web, persistence and the opt-in gate are the same switch — an opted-out instance is not persisting assignments either. There is no client-side equivalent of the server SDKs' manual exposure-tracking method, so option 2 requires re-invoking the evaluation after opt-in rather than replaying a stored event.

---

## Using your own exposure event

Mixpanel can be configured to treat a different event as the exposure event instead of `$experiment_started`. Customers do this when they need control over exactly when exposure is recorded.

If a customer goes this route, the substitute event must carry the same shape the automatic one does — flag key, variant key, and the identity the flag buckets on — or the experiment cannot attribute results. Reproducing this by hand is easy to get subtly wrong, and the failure mode is an experiment that reports nothing with no error.

**Prefer the SDK's own exposure tracking.** It is correct by construction, and on server SDKs the suppress-then-track-manually path already gives full control over timing without hand-rolling the event.

---

## Runtime targeting: events are client-side only

Two runtime targeting mechanisms, easy to confuse:

- **Runtime properties** — key/value attributes your app passes in `custom_properties` inside the evaluation context. Available on **client and server** SDKs.
- **Runtime events** — targeting on Mixpanel events the user has triggered. **Client-side only.**

A server-side implementation cannot use runtime-event targeting. The equivalent is to compute the condition in your own application and pass it as a runtime property — e.g. send `has_added_to_cart: true` in `custom_properties` and target on that property instead. The application owns that state.

Also: only events fired **after** the flag is enabled count toward runtime-event activation. Historical events do not retroactively qualify a user.

---

## Checklist before wiring an experiment

An experiment launch is irreversible and locks the variants, statistical model, and cohort. Confirm all of these first:

- [ ] The evaluation call sits at the point where the variant changes the user experience.
- [ ] The fallback value means "feature off."
- [ ] On a server SDK, first-exposure semantics are either implemented or explicitly accepted as not implemented.
- [ ] Branching is not driven by an all-variants call without manual exposure tracking.
- [ ] Consent gating, if present, does not silently drop exposures.
- [ ] A real exposure event has been observed in Mixpanel with the right flag key and variant — see [verification.md](verification.md).

The last one is not optional. An experiment launched against code that never evaluates the flag will pass every configuration check, go active, lock its settings, and accrue nothing.
