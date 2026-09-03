# Feature flag SDK reference

Per-platform init, evaluation, and exposure control for Mixpanel feature flags.

*Source: the Mixpanel feature-flags and SDK docs at docs.mixpanel.com. Call shapes, defaults and version floors change — for anything beyond the divergences below, treat the platform's own docs page as authoritative and verify before relying on a specific value.*

**Token substitution:** replace `YOUR_PROJECT_TOKEN` with the customer's real project token before surfacing any snippet.

## Contents

- [**Cross-SDK divergences — read this first**](#cross-sdk-divergences--read-this-first)
- [Minimum SDK versions](#minimum-sdk-versions)
- [Enabling flags at init](#enabling-flags-at-init) — the opt-in every platform needs
- [Evaluating a flag](#evaluating-a-flag)
- [Server SDKs: remote vs local evaluation](#server-sdks-remote-vs-local-evaluation)
- [Controlling exposure on server SDKs](#controlling-exposure-on-server-sdks)
- [Flag persistence (client SDKs)](#flag-persistence-client-sdks)
- [Regions](#regions)
- [OpenFeature](#openfeature)

---

## Cross-SDK divergences — read this first

This table is the reason this file exists. Everything in it is something an agent will get wrong by generalising from another SDK. The rest of the file carries the minimum init and getter shapes needed to opt into flags — routine in form, but the opt-in itself is the single most common thing left out, so it is reproduced here rather than deferred to each platform's docs.

| Concern | How it differs |
|---|---|
| **`isEnabled` fallback parameter** | Present on JavaScript, Swift, Android, Flutter, React Native. **Absent on Node, Python, Go, Java, Ruby** — those take only the flag key and context. |
| **Exposure suppression** | Node: a 4th argument to the getter. **Python: not available on `get_variant_value` at all** — you must call `get_variant`, and the keyword differs by mode: `local_flags` takes `report_exposure=False`, `remote_flags` takes `reportExposure=False` (camelCase — this is deliberate in the SDK, not a typo). Go: no per-call parameter; controlled by the tracker supplied at init. **Java and Ruby: no documented per-call suppression** — do not assume the Node or Python shape; verify against the installed SDK before promising first-exposure semantics. |
| **"All variants" method** | `getAllVariants` / `get_all_variants` / `GetAllVariants` on Node, Python, Go, Ruby, Flutter, React Native — but **Java is `getAllVariantsByFlag(context, boolean)`**, with a trailing boolean whose meaning is not documented upstream. On every SDK where it is documented, this call does **not** fire an exposure event; treat Java's boolean as unverified rather than assuming it matches the others. |
| **React Native init** | The token goes to the `Mixpanel` **constructor**, not to `init()`. On the instance `init()`, `featureFlagsOptions` is the **5th** positional argument — after `optOutTrackingDefault`, `superProperties`, `serverURL`, `useGzipCompression`. Passing it in any earlier position silently leaves flags disabled instead of erroring. |
| **Async model** | JavaScript, Flutter, React Native: promises, plus `*Sync` variants. **Swift and Android: completion callbacks, not async/await.** Server local evaluation: synchronous. Server remote: async on Node, synchronous on Python, Ruby and Java. |
| **Flag persistence** | Client SDKs only. **Flutter supports it on iOS and Android only** — on Web the policy is ignored and behaves as `networkOnly`. |
| **Local evaluation** | Server SDKs only, and **cohort targeting and sticky variants are not supported** in that mode — *sticky* meaning a user keeps the variant they were first assigned even if rollout or splits change afterwards (verify current — the gap narrows over time). |
| **Variant source field** | `variant_source` on JavaScript and React Native; `.source` on Swift, Android and Flutter. Not exposed on server SDKs. |

---

## Minimum SDK versions

Below these, flags return nothing and **no error is raised** — check the installed version before anything else.

**Verify against the SDK's own release notes before hard-gating on a row.** Floors move, and a stale floor here would block an implementation that would actually work.

| Platform | Flags minimum | Notes |
|---|---|---|
| JavaScript (web) | `v2.71.0` | `v2.79.0` for persistence, and for `reset()` clearing flags |
| Swift (iOS) | `v5.1.3` | |
| Android | `v8.2.4` | |
| Flutter | `v2.5.0` | persistence on iOS/Android only |
| React Native | `v3.5.0` | |
| Node.js | `v0.20.0` | |
| Python | `v5.1.0` | |
| Go | `v2.0.0` | |
| Java | no GA release at time of writing | confirm current status before committing to Java |
| Ruby | `v3.0.0` | beta |

---

## Enabling flags at init

**Flags are off by default in every SDK.** An existing Mixpanel install that tracks events happily will return no flags until init opts in. This is the single most common cause of "I added the code and nothing happened."

Two rules apply to every platform:

- If any flag in the project buckets on a key other than `distinct_id`/`device_id` (e.g. `company_id`), **that key must be in the init context.**
- If any flag uses runtime-property targeting, **those properties go in a `custom_properties` object nested inside the context.**

Omitting either is a silent no-match — the flag simply doesn't return.

```javascript
// JavaScript (web)
mixpanel.init('YOUR_PROJECT_TOKEN', {
  debug: true,
  flags: { context: { company_id: 'X', custom_properties: { platform: 'web' } } },
});
```

```swift
// Swift — initialize(options:) is the only overload that accepts MixpanelOptions;
// the token is a required field on MixpanelOptions itself.
let options = MixpanelOptions(
    token: "YOUR_PROJECT_TOKEN",
    featureFlagOptions: FeatureFlagOptions(
        enabled: true,
        context: ["company_id": "X", "custom_properties": ["platform": "ios"]]
    )
)
let mixpanel = Mixpanel.initialize(options: options)
```

```java
// Android — JSONObject.put throws a checked JSONException, so the context
// build has to be guarded or declared.
FeatureFlagOptions featureFlagOptions;
try {
    JSONObject customProperties = new JSONObject();
    customProperties.put("platform", "android");

    JSONObject flagContext = new JSONObject();
    flagContext.put("company_id", "X");
    flagContext.put("custom_properties", customProperties);

    featureFlagOptions = new FeatureFlagOptions.Builder()
        .enabled(true)
        .context(flagContext)
        .build();
} catch (JSONException e) {
    throw new IllegalStateException("Failed to build flag context", e);
}

MixpanelOptions options = new MixpanelOptions.Builder()
    .featureFlagOptions(featureFlagOptions)
    .build();

MixpanelAPI mixpanel = MixpanelAPI.getInstance(
    getApplicationContext(), "YOUR_PROJECT_TOKEN", false, options);
```

```dart
// Flutter
Mixpanel mixpanel = await Mixpanel.init(
  'YOUR_PROJECT_TOKEN',
  trackAutomaticEvents: false,
  featureFlags: FeatureFlagsConfig(
    enabled: true,
    context: {'company_id': 'X', 'custom_properties': {'platform': 'flutter'}},
  ),
);
```

```javascript
// React Native — the token goes to the constructor, and featureFlagsOptions is
// the 5th positional argument of the instance init().
const mixpanel = new Mixpanel('YOUR_PROJECT_TOKEN', false);
await mixpanel.init(false, undefined, undefined, undefined, {
  enabled: true,
  context: { company_id: 'X', custom_properties: { platform: 'rn' } },
});
```

Server SDK init is bound up with the evaluation-mode choice — see [Server SDKs](#server-sdks-remote-vs-local-evaluation).

**Mobile note:** Swift, Android and Flutter accept a `prefetchFlags` option (default `true`). With prefetch disabled, nothing is fetched at init and no flag is available until `identify()` or an explicit load call. If flags are unexpectedly empty at startup, check that first.

---

## Evaluating a flag

Match the call to the flag type: the **boolean check** for a Feature Gate, the **variant-value getter** for an Experiment or Dynamic Config. Both fire an exposure event; see [exposure-correctness.md](exposure-correctness.md) for what that means and when it doesn't.

```javascript
// JavaScript (web) — async is the safe default
const isEnabled = await mixpanel.flags.is_enabled('my-flag', false);
const value = await mixpanel.flags.get_variant_value('my-flag', 'control');

// Full variant object, including where the value came from
const variant = await mixpanel.flags.get_variant('my-flag', { key: 'control', value: 'control' });
```

Per-platform method names, with the fallback-parameter divergence noted in the table above:

| Platform | Boolean check | Variant value | Full variant |
|---|---|---|---|
| JavaScript | `flags.is_enabled` | `flags.get_variant_value` | `flags.get_variant` |
| React Native | `flags.isEnabled` | `flags.getVariantValue` | `flags.getVariant` |
| Swift | `flags.isEnabled` | `flags.getVariantValue` | `flags.getVariant` |
| Android | `flags.isEnabled` | `flags.getVariantValue` | `flags.getVariant` |
| Flutter | `flags.isEnabled` | `flags.getVariantValue` | `flags.getVariant` |
| Node.js | `<mode>.isEnabled` | `<mode>.getVariantValue` | `<mode>.getVariant` |
| Python | `<mode>.is_enabled` | `<mode>.get_variant_value` | `<mode>.get_variant` |
| Go | `<Mode>.IsEnabled` | `<Mode>.GetVariantValue` | — |
| Java | `get<Mode>().isEnabled` | `get<Mode>().getVariantValue` | — |
| Ruby | `<mode>.is_enabled?` | `<mode>.get_variant_value` | — |

`<mode>` is `local_flags` or `remote_flags` (`LocalFlags`/`RemoteFlags` on Go, `getLocalFlags()`/`getRemoteFlags()` on Java). JavaScript, React Native, Swift and Android also expose `*Sync` variants — those return the fallback if flags haven't loaded, so only use them behind a flags-ready check.

Reloading: `identify()` triggers a reload on client SDKs; an `updateContext` call re-fetches with new context; `reset()` clears assignments and refetches.

---

## Server SDKs: remote vs local evaluation

Chosen at init, and it changes the init shape.

- **Remote** — a network call per evaluation.
- **Local** — the SDK polls for flag definitions and evaluates in-process. Lower latency, but **no cohort targeting and no sticky variants**; either one requires remote.

```javascript
// Node.js — local evaluation
const Mixpanel = require('mixpanel');

const mp = Mixpanel.init('YOUR_PROJECT_TOKEN', {
  local_flags_config: {
    api_host: 'api.mixpanel.com',
    enable_polling: true,
    polling_interval_in_seconds: 60,
  },
});

const userContext = {
  distinct_id: '1234',
  company_id: 'X',
  custom_properties: { platform: 'node' },
};

async function main() {
  await mp.local_flags.startPollingForDefinitions();
  const value = mp.local_flags.getVariantValue('sample-flag', 'control', userContext);
  return value;
}
```

```javascript
// Node.js — remote evaluation
const Mixpanel = require('mixpanel');

const mp = Mixpanel.init('YOUR_PROJECT_TOKEN', {
  remote_flags_config: { api_host: 'api.mixpanel.com', request_timeout_in_seconds: 5 },
});

async function main() {
  const userContext = { distinct_id: '1234' };
  return await mp.remote_flags.getVariantValue('sample-flag', 'control', userContext);
}
```

```python
# Python — local evaluation
import mixpanel

local_config = mixpanel.LocalFlagsConfig(
    api_host="api.mixpanel.com", enable_polling=True, polling_interval_in_seconds=60
)
mp = mixpanel.Mixpanel("YOUR_PROJECT_TOKEN", local_flags_config=local_config)
mp.local_flags.start_polling_for_definitions()

user_context = {
    "distinct_id": "1234",
    "company_id": "X",
    "custom_properties": {"platform": "python"},
}

variant_value = mp.local_flags.get_variant_value("sample-flag", "control", user_context)
```

```go
// Go — local evaluation
package main

import (
	"context"
	"time"

	mixpanel "github.com/mixpanel/mixpanel-go"
	"github.com/mixpanel/mixpanel-go/flags"
)

func main() {
	localConfig := flags.LocalFlagsConfig{
		FlagsConfig:     flags.FlagsConfig{APIHost: "api.mixpanel.com"},
		EnablePolling:   true,
		PollingInterval: 60 * time.Second,
	}
	mp := mixpanel.NewApiClient("YOUR_PROJECT_TOKEN", mixpanel.WithLocalFlags(localConfig))

	ctx := context.Background()
	mp.LocalFlags.StartPollingForDefinitions(ctx)

	userContext := flags.FlagContext{
		"distinct_id":       "1234",
		"custom_properties": map[string]any{"platform": "go"},
	}

	_, _ = mp.LocalFlags.GetVariantValue(ctx, "sample-flag", "control", userContext)
	_, _ = mp.LocalFlags.IsEnabled(ctx, "sample-flag", userContext)
}
```

Java configures `LocalFlagsConfig`/`RemoteFlagsConfig` through a builder (`projectToken`, `apiHost` without protocol, `enablePolling`, `pollingIntervalSeconds`, `requestTimeoutSeconds`), starts polling with `getLocalFlags().startPollingForDefinitions()`, and **requires `close()` on shutdown** to stop polling. Ruby takes a `local_flags_config` / `remote_flags_config` hash on `Mixpanel::Tracker.new` and starts polling with `local_flags.start_polling_for_definitions!`. See each platform's docs page for the full builder surface.

---

## Controlling exposure on server SDKs

[exposure-correctness.md](exposure-correctness.md) owns exposure semantics — why every server-side evaluation fires one, what "once" has to mean, and how to store it. Read it first if you need first-exposure-only behaviour. This section covers only the per-language suppression shapes, which differ, and on two SDKs don't exist.

```javascript
// Node.js — suppress with a 4th argument, then track manually
async function evaluate(mp, flagKey, userContext) {
  const fallback = { variant_value: 'control' };
  const variant = await mp.remote_flags.getVariant(flagKey, fallback, userContext, false);
  // ...once the user is actually exposed. trackExposureEvent takes the variant
  // object, not the raw value, so suppress on getVariant rather than getVariantValue.
  mp.remote_flags.trackExposureEvent(flagKey, variant, userContext);
  return variant.variant_value;
}
```

```python
# Python — get_variant_value has NO suppression parameter; drop to get_variant
from mixpanel import SelectedVariant

def evaluate(mp, flag_key, user_context):
    fallback = SelectedVariant(variant_value="control")
    # local_flags takes report_exposure; remote_flags takes reportExposure.
    variant = mp.local_flags.get_variant(flag_key, fallback, user_context, report_exposure=False)
    # ...once the user is actually exposed:
    mp.local_flags.track_exposure_event(flag_key, variant, user_context)
    return variant.variant_value
```

**Go** has no per-call suppression. Exposure is sent by the tracker supplied at init: `DefaultFlagsExposureTracker` sends synchronously, and a custom tracker function can be passed instead to send asynchronously or drop events. Confirm the current constructor and tracker signature against the Go SDK's docs before wiring one — the shape is not stable enough to reproduce here.

**Java and Ruby** document no per-call suppression. Do not write suppression code for them by analogy with Node or Python. If a customer on Java or Ruby needs first-exposure-only semantics, verify against the installed SDK; if it isn't available, say so plainly and use the "accept repeat exposures" path in [exposure-correctness.md](exposure-correctness.md) rather than inventing an API.

**On every SDK, the all-variants call does not fire exposure** — if branching is driven by it, exposure must be tracked manually per flag.

---

## Flag persistence (client SDKs)

Serves a stored assignment when the network is slow or unavailable, instead of falling back. Configured with a `variantLookupPolicy` in the SDK's feature-flag options:

| Policy | Behaviour |
|---|---|
| `networkOnly` *(default)* | No persistence. Every lookup waits for the network. |
| `networkFirst` | Waits for the network; serves the persisted value if the call fails. |
| `persistenceUntilNetworkSuccess` | Serves the persisted value immediately; refreshes in the background. |

A TTL is configurable alongside the policy (24 hours by default — verify current). Persisted data is scoped to the current `distinct_id`: `identify()` with a new ID, or `reset()`, clears it and triggers a fresh fetch.

Exposure events from a persisted variant carry `$variant_source`, plus `$persisted_at_in_ms` and `$ttl_in_ms`. **Fallback variants fire no exposure event at all.**

---

## Regions

EU projects must point at `api-eu.mixpanel.com` and India projects at `api-in.mixpanel.com`. Client SDKs set this through the SDK's standard API-host option; server SDKs set it in the flags config (`api_host` / `APIHost` / `apiHost` in the examples under [Server SDKs](#server-sdks-remote-vs-local-evaluation)). A US host with an EU token returns no flags and no error.

---

## OpenFeature

Mixpanel ships OpenFeature providers for JavaScript, Node.js, Python, Go, Java, Ruby, Swift and Android. If the customer already uses OpenFeature, implement against the provider: their existing `getBooleanValue` / `getStringValue` call sites stay unchanged and only the provider registration changes. See the platform's `*-openfeature` docs page. For customers migrating from another vendor, [migration.md](migration.md) covers when this is the cheapest path.
