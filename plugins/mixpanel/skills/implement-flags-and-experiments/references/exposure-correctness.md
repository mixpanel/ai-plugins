# Exposure correctness

The exposure event is what makes a flag measurable. Nearly every experiment-invalidating bug is an exposure bug, and most of them are silent — the feature works, the code looks right, and the analysis is wrong.

Read this before writing evaluation calls on a server SDK, before wiring an experiment, and before implementing anything behind a consent gate.

*Source: the Mixpanel feature-flags and SDK docs at docs.mixpanel.com. Claims about SDK behaviour below are marked where they could not be confirmed against a documented statement — verify those against the installed SDK before betting an experiment on them.*

## Contents

- [Assignment is not exposure](#assignment-is-not-exposure)
- [Client SDKs deduplicate. Server SDKs do not.](#client-sdks-deduplicate-server-sdks-do-not)
- [Implementing first-exposure-only on a server SDK](#implementing-first-exposure-only-on-a-server-sdk)
- [Calls that fire exposure, and calls that don't](#calls-that-fire-exposure-and-calls-that-dont)
- [Exposure fires even when no experiment is running](#exposure-fires-even-when-no-experiment-is-running)
- [Consent gating](#consent-gating)
- [Using your own exposure event](#using-your-own-exposure-event)
- [Runtime targeting: events are client-side only](#runtime-targeting-events-are-client-side-only)
- [Checklist before wiring an experiment](#checklist-before-wiring-an-experiment)

The exposure event Mixpanel records is named `$experiment_started`. Search for that name when verifying in Live View.

---

## Assignment is not exposure

- **Assignment** — the flag service decides which variant this user gets. Happens at init (client) or at evaluation (server).
- **Exposure** — the user actually reached the code path that uses the variant. Recorded as `$experiment_started`.

Analysis is built on exposure, not assignment. This is why the placement of the evaluation call matters: it should sit where the variant changes what the user sees. Evaluate at app boot for a flag that gates a checkout button and you have declared every user who opened the app "exposed to the checkout experiment," including everyone who never reached checkout. The experiment then measures a diluted effect and may never reach significance.

The inverse error is rarer but worse: evaluating so deep in the funnel that only converting users are exposed. Lift then looks enormous and meaningless.

---

## Client SDKs deduplicate. Server SDKs do not.

**Client SDKs** deduplicate the exposure event per flag for the lifetime of the SDK instance. Calling the getter in a render loop does not produce thousands of exposures. Note the scope — a page reload, an app restart, or a new session is a new instance and will fire again. That is expected; analysis handles repeat exposures per user.

**Server SDKs do not deduplicate.** Every evaluation call fires an exposure event. A flag checked once per request emits one exposure per request — thousands per user per day.

**Confirm this before relying on it.** The dedupe scope is falsifiable in about a minute: call the getter twice in one page session and watch Live View. One `$experiment_started` means dedupe is active; two means it isn't, and your implementation needs to handle it.

Why the difference matters:

1. **Analysis.** Exposure counts stop being user counts.
2. **Volume.** Exposure events are events. High-traffic server paths generate a lot of them.
3. **Correctness.** The intended semantic is one exposure per user per experiment, on first exposure. On a server SDK that is the implementer's job.

---

## Implementing first-exposure-only on a server SDK

**Check availability first — this is not possible on every SDK.**

Node and Python have a per-call parameter. Go controls exposure through the tracker supplied at init. **Java and Ruby document neither.** The exact per-language shapes — including Python's keyword differing between local and remote evaluation — are in [sdk-snippets.md](sdk-snippets.md#controlling-exposure-on-server-sdks).

On Go, wire the tracker at init rather than reaching for a per-call flag. On Java and Ruby, do not write suppression code by analogy with Node or Python — the parameter may not exist. Verify against the installed SDK; if it isn't there, use the accept-repeat-exposures path below and tell the customer which semantics they have.

Where suppression is available, the shape is: suppress at evaluation, then fire exposure yourself exactly once.

```python
# Python. Node's equivalent is getVariant(key, fallback, ctx, false)
# followed by trackExposureEvent(key, variant, ctx).
# SelectedVariant is not re-exported at the package root — import it from flags.types.
from mixpanel.flags.types import SelectedVariant, VariantSource

def variant_for(mp, flag_key, user_context, already_exposed):
    fallback = SelectedVariant(variant_value="control")
    variant = mp.local_flags.get_variant(flag_key, fallback, user_context, report_exposure=False)

    # A fallback means no assignment arrived. track_exposure_event does not check
    # this itself — it will happily emit an exposure with a null variant name — so
    # the caller has to guard it.
    if variant.variant_source == VariantSource.FALLBACK:
        return variant.variant_value

    # Fire exposure only where the user actually sees the variant, and only once.
    if not already_exposed.seen(user_context["distinct_id"], flag_key):
        mp.local_flags.track_exposure_event(flag_key, variant, user_context)
        already_exposed.record(user_context["distinct_id"], flag_key)

    return variant.variant_value
```

**The "already exposed" store has a hard requirement:** it must be keyed on **`distinct_id` + flag key** and persist for **the whole experiment**, not the request or the session. Key it on `distinct_id` even when the flag buckets on something coarser — exposure is recorded per user, so deduping on a `company_id` assignment key would log one exposure for the entire company and silently drop every other user in it. A per-request store gives you no deduplication at all. A session store gives you one exposure per session per user, which is not first-exposure-only — and a reader who picks it will believe they implemented something they didn't. In practice that means a database column or a durable cache with no TTL shorter than the experiment, not an in-memory flag.

**If that is more machinery than the customer wants**, the honest fallback is to leave automatic exposure on and accept repeat exposures. Say so explicitly rather than letting them assume semantics they don't have. Repeat exposures do not invalidate an experiment on their own — Mixpanel attributes a user's subsequent events to their exposure, so extra exposures for an already-exposed user don't add users to the denominator — but the customer should know which semantics they're operating under, and exposure counts will not equal user counts.

---

## Calls that fire exposure, and calls that don't

**Fire exposure:** the variant-value getters, the boolean checks, and the full-variant getters — in both their async and sync forms.

**Does not fire exposure:** the "evaluate all flags at once" method, on every SDK where the behaviour is documented (`getAllVariants`, `get_all_variants`, `GetAllVariants`).

This is the most likely way to end up with a live experiment collecting nothing. The pattern looks efficient and is, but it is an *assignment* API, not an *exposure* API. If a customer uses it to drive real branching, they must call the exposure-tracking method themselves for each flag the user is actually exposed to.

**Java is the exception to verify:** its form is `getAllVariantsByFlag(context, boolean)`, and that trailing boolean is not documented upstream. In Node the same-position boolean is the exposure switch, so do not assume Java's call fires nothing — check it, or you may double-count by adding manual tracking on top of a call that already fired.

**Fallback variants never fire exposure.** When the flag service is unreachable, or the user isn't in any rollout group, the fallback is returned and no `$experiment_started` is emitted. So "zero exposures" and "everyone is getting the fallback" are the same symptom.

---

## Exposure fires even when no experiment is running

Evaluating a flag emits `$experiment_started` whether or not that flag is attached to an active experiment. A plain feature gate that has been at 100% for a year is still emitting exposure events on every evaluation.

Two consequences: exposure volume is driven by evaluation volume rather than by how many experiments are running; and this is a reason to actually remove flag code once a flag reaches a terminal state, rather than leaving the branch in place forever.

---

## Consent gating

If the SDK is opted out of tracking, an evaluation still returns a variant but the exposure event is **dropped, not queued**. It is not replayed when consent is granted later.

This breaks the common consent pattern: page loads, code evaluates the flag to decide what to render, user accepts the cookie banner several seconds later. The variant was served; the exposure was lost. The experiment under-counts, and it under-counts *non-uniformly* — biased toward users who consent slowly or not at all.

Two workable options:

1. **Evaluate after consent.** Move the evaluation behind the consent gate so it never runs while opted out. Cleanest, and the right default — but only viable if the gated feature isn't needed on first paint.
2. **Re-evaluate after consent.** Keep the early evaluation for rendering, then call the getter again once consent is granted so the exposure fires from an opted-in instance.

Option 2 has a caveat you must check rather than assume: client SDKs deduplicate exposure per flag for the SDK instance's lifetime, and it is **not documented** whether an exposure suppressed by opt-out still marks that flag as exposed. If it does, the second call fires nothing and the fix is a no-op. Test it — evaluate while opted out, opt in, evaluate again, and confirm an `$experiment_started` appears in Live View. If it doesn't, option 1 is the only reliable path.

There is no client-side manual exposure-tracking method, so a dropped exposure cannot be replayed from a stored value — re-invoking the evaluation is the only lever.

---

## Using your own exposure event

Mixpanel can be configured to treat a different event as the exposure event instead of `$experiment_started`. Customers do this when they need control over exactly when exposure is recorded.

The substitute event must carry the same shape the automatic one does — flag key, variant key, and the identity the flag buckets on — or the experiment cannot attribute results. Reproducing this by hand is easy to get subtly wrong, and the failure mode is an experiment that reports nothing with no error.

**Prefer the SDK's own exposure tracking.** It is correct by construction, and on server SDKs the suppress-then-track-manually path already gives full control over timing without hand-rolling the event.

---

## Runtime targeting: events are client-side only

Two runtime targeting mechanisms, easy to confuse:

- **Runtime properties** — key/value attributes your app passes in `custom_properties` inside the evaluation context. Available on **client and server** SDKs.
- **Runtime events** — targeting on Mixpanel events the user has triggered. **Client-side only.**

A server-side implementation cannot use runtime-event targeting. The equivalent is to compute the condition in your own application and pass it as a runtime property — send `has_added_to_cart: true` in `custom_properties` and target on that property instead. The application owns that state.

Only events fired **after** the flag is enabled count toward runtime-event activation; historical events do not retroactively qualify a user.

---

## Checklist before wiring an experiment

- [ ] The evaluation call sits where the variant changes the user experience — not at boot, not deep in the funnel.
- [ ] The fallback value means "feature off."
- [ ] On a server SDK, first-exposure semantics are implemented, or explicitly accepted as not implemented and communicated.
- [ ] Branching is not driven by an [all-variants call](#calls-that-fire-exposure-and-calls-that-dont) without manual exposure tracking.
- [ ] [Consent gating](#consent-gating), if present, does not silently drop exposures.
- [ ] A real `$experiment_started` event has been observed with the right flag key and variant — see [verification.md](verification.md).

The last one is not optional. An experiment launched against code that never evaluates the flag will pass every configuration check, go active, lock its settings, and accrue nothing. The `manage-experiment` skill owns the launch gate itself; this checklist covers only the implementation side of it.
