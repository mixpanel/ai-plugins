# Feature flag SDK snippets

Per-platform init and evaluation code for Mixpanel feature flags. Standalone — consumable without the rest of the skill.

**Token substitution:** replace `YOUR_PROJECT_TOKEN` with the customer's real project token before surfacing any snippet.

**Region:** EU projects use `api-eu.mixpanel.com`, India projects `api-in.mixpanel.com`. Client SDKs set this through the SDK's standard API-host option; server SDKs set it in the flags config shown below. Getting this wrong returns no flags.

---

## Minimum SDK versions

Below these, flags return nothing and **no error is raised**. Check the installed version first.

| Platform | Flags minimum | Notes |
|---|---|---|
| JavaScript (web) | `v2.71.0` | `v2.79.0` for flag persistence and for `reset()` clearing flags |
| Swift (iOS) | `v5.1.3` | |
| Android | `v8.2.4` | |
| Flutter | `v2.5.0` | persistence on iOS/Android only; Web behaves as `networkOnly` |
| React Native | `v3.5.0` | |
| Node.js | `v0.20.0` | |
| Python | `v5.1.0` | |
| Go | `v2.0.0` | |
| Java | `1.6.0-SNAPSHOT` | snapshot build — confirm availability before committing to Java |
| Ruby | `v3.0.0` | beta |

---

## Client SDKs

Client SDKs fetch assignments at init, cache them in memory, and **deduplicate the exposure event per flag for the lifetime of the SDK instance**. A page reload or app restart is a new instance and will fire again.

### JavaScript (web)

```javascript
// Init — flags are OFF by default; this opts in
mixpanel.init('YOUR_PROJECT_TOKEN', {
  debug: true,
  flags: true,
});

// With a non-default assignment key and/or runtime targeting properties
mixpanel.init('YOUR_PROJECT_TOKEN', {
  flags: {
    context: {
      company_id: 'X',                    // required if the flag buckets on company_id
      custom_properties: { platform: 'web' },  // required for runtime-property targeting
    },
  },
});

// Feature Gate — boolean
const isEnabled = await mixpanel.flags.is_enabled('my-feature-flag', false);

// Experiment / Dynamic Config — variant value
const value = await mixpanel.flags.get_variant_value('my-feature-flag', 'control');

// Full variant object, including where the value came from
const variant = await mixpanel.flags.get_variant('my-feature-flag', { key: 'control', value: 'control' });
variant.value;
variant.variant_source;   // 'network' | 'persistence' | 'fallback'

// Sync variants — return the fallback if flags have not loaded yet
const v = mixpanel.flags.get_variant_value_sync('my-feature-flag', 'control');
const e = mixpanel.flags.is_enabled_sync('my-feature-flag', false);

// Reload
mixpanel.identify(newDistinctId);                       // triggers a flag reload
mixpanel.flags.update_context({ company_id: 'Y' });     // re-fetch with new context
mixpanel.reset();                                        // clears flags, refetches (v2.79.0+)
```

**Persistence** (v2.79.0+) — serve assignments when the network is slow or down:

```javascript
mixpanel.init('YOUR_PROJECT_TOKEN', {
  flags: {
    persistence: {
      variantLookupPolicy: 'networkFirst',   // or 'persistenceUntilNetworkSuccess'
      persistenceTtlMs: 12 * 60 * 60 * 1000, // default 24h
    },
  },
});
```

`networkOnly` (default) waits for the network every time. `networkFirst` waits, falling back to the persisted value on failure. `persistenceUntilNetworkSuccess` returns the persisted value immediately and refreshes in the background. Persisted data is scoped to the current `distinct_id`; `identify()` with a new ID or `reset()` clears it.

### Swift (iOS)

```swift
Mixpanel.initialize(token: "YOUR_PROJECT_TOKEN", options: MixpanelOptions(
    featureFlagsEnabled: true
))

// Gate
Mixpanel.mainInstance().flags.isEnabled("my-feature-flag", fallbackValue: false) { isEnabled in
    if isEnabled { showNewFeature() }
}

// Variant value
Mixpanel.mainInstance().flags.getVariantValue("my-feature-flag", fallbackValue: "control") { value in
    // branch on value
}

// Full variant — .source is .network, .persistence(persistedAt:), or .fallback
Mixpanel.mainInstance().flags.getVariant("my-feature-flag", fallback: fallback) { variant in }

// Sync — only behind a readiness check
let value = Mixpanel.mainInstance().flags.getVariantValueSync("my-feature-flag", fallbackValue: "control")
let enabled = Mixpanel.mainInstance().flags.isEnabledSync("my-feature-flag", fallbackValue: false)

// Manual reload
Mixpanel.mainInstance().flags.loadFlags()
```

Swift and Android use **completion callbacks**, not async/await. Persistence is configured with `variantLookupPolicy: .networkFirst()` / `.persistenceUntilNetworkSuccess()` on `FeatureFlagOptions`, optionally `.networkFirst(persistenceTtl: 12 * 3600)`.

**`prefetchFlags: false`** stops flags loading at init — nothing is fetched until `identify()` or `loadFlags()`. If flags are unexpectedly empty at startup, check this first.

### Android

```java
// Init with feature flags enabled via FeatureFlagOptions on the builder

// Gate
mixpanel.flags.isEnabled("my-feature-flag", fallback, new FlagCompletionCallback<Boolean>() {
    @Override public void onComplete(Boolean isEnabled) {
        if (isEnabled) { showNewFeature(); }
    }
});

// Variant value
mixpanel.flags.getVariantValue("my-feature-flag", "control", new FlagCompletionCallback<Object>() {
    @Override public void onComplete(Object value) { }
});

// Full variant — MixpanelFlagVariant.source is Source.Network / Source.Persistence / Source.Fallback
mixpanel.flags.getVariant("my-feature-flag", fallback, new FlagCompletionCallback<MixpanelFlagVariant>() { });

// Sync — guard with areFlagsReady()
Object value = mixpanel.flags.getVariantValueSync("my-feature-flag", fallback);
boolean enabled = mixpanel.flags.isEnabledSync("my-feature-flag", fallback);

mixpanel.flags.loadFlags();
```

Persistence: `.variantLookupPolicy(VariantLookupPolicy.networkFirst())` on the `FeatureFlagOptions` builder, or `VariantLookupPolicy.networkFirst(ttlMs)`. `prefetchFlags(false)` behaves as on Swift.

### Flutter

```dart
Mixpanel mixpanel = await Mixpanel.init(
  'YOUR_PROJECT_TOKEN',
  trackAutomaticEvents: false,
  featureFlags: FeatureFlagsConfig(enabled: true),
);

final flags = mixpanel.flags;

bool isEnabled = await flags.isEnabled('my-feature-flag', false);
dynamic value = await flags.getVariantValue('my-feature-flag', 'control');
MixpanelFlagVariant variant = await flags.getVariant('my-feature-flag', fallback);

bool ready = await flags.areFlagsReady();
await flags.loadFlags();
await flags.updateContext({ 'company_id': 'Y' });

// Does NOT fire exposure events
Map<String, MixpanelFlagVariant> all = await flags.getAllVariants();
```

Persistence is configured with `variantLookupPolicy: VariantLookupPolicy.networkFirst()` on `FeatureFlagsConfig`, and is supported on **iOS and Android only** — on Web it behaves as `networkOnly` regardless of configuration.

### React Native

```javascript
await mixpanel.init(
  'YOUR_PROJECT_TOKEN',
  trackAutomaticEvents,
  optOutTrackingDefault,
  { enabled: true }              // featureFlagsOptions
);

const isEnabled = await mixpanel.flags.isEnabled('my-feature-flag', false);
const value = await mixpanel.flags.getVariantValue('my-feature-flag', 'control');
const variant = await mixpanel.flags.getVariant('my-feature-flag', fallback);
// variant.variant_source: 'network' | 'persistence' | 'fallback'
// persistence-sourced variants also carry persisted_at_in_ms

// Sync forms exist for all three: getVariantValueSync, isEnabledSync, getVariantSync

await mixpanel.flags.loadFlags();
await mixpanel.flags.updateContext({ company_id: 'Y' });

// Does NOT fire exposure events
const all = await mixpanel.flags.getAllVariants();
```

Persistence: `persistence: { variantLookupPolicy: 'networkFirst' }` inside `featureFlagsOptions`. The SDK also exposes snake_case aliases for every method (`get_variant_value`, `is_enabled`, …) — either casing works.

---

## Server SDKs

Server SDKs choose **remote** or **local** evaluation at init.

- **Remote** — network call per evaluation. Required for cohort targeting and sticky variants.
- **Local** — SDK polls for flag definitions and evaluates in-process (sub-millisecond). **Cohort targeting and sticky variants are not supported.**

Server SDKs do **not** deduplicate exposure events. See [exposure-correctness.md](exposure-correctness.md) before writing evaluation calls.

### Node.js

```javascript
const Mixpanel = require('mixpanel');

// Local evaluation
const mixpanel = Mixpanel.init('YOUR_PROJECT_TOKEN', {
  local_flags_config: {
    api_host: 'api.mixpanel.com',
    enable_polling: true,
    polling_interval_in_seconds: 60,
  },
});
await mixpanel.local_flags.startPollingForDefinitions();

// Remote evaluation
const mixpanel = Mixpanel.init('YOUR_PROJECT_TOKEN', {
  remote_flags_config: { api_host: 'api.mixpanel.com', request_timeout_in_seconds: 5 },
});

const userContext = {
  distinct_id: '1234',
  company_id: 'X',                          // if the flag buckets on company_id
  custom_properties: { platform: 'node' },  // if the flag uses runtime targeting
};

const value = mixpanel.local_flags.getVariantValue(flagKey, 'control', userContext);        // sync
const value = await mixpanel.remote_flags.getVariantValue(flagKey, 'control', userContext); // async

// Suppress automatic exposure — 4th positional argument
const v = await mixpanel.remote_flags.getVariantValue(flagKey, 'control', userContext, false);
mixpanel.remote_flags.trackExposureEvent(flagKey, selectedVariant, userContext);

// Evaluate everything at once — does NOT fire exposure
const variants = await mixpanel.remote_flags.getAllVariants(userContext);
```

### Python

```python
import mixpanel

# Local
local_config = mixpanel.LocalFlagsConfig(
    api_host="https://api.mixpanel.com", enable_polling=True, poll_interval=60
)
mp = mixpanel.Mixpanel("YOUR_PROJECT_TOKEN", local_flags_config=local_config)
mp.local_flags.start_polling_for_definitions()

# Remote
remote_config = mixpanel.RemoteFlagsConfig(api_host="https://api.mixpanel.com", request_timeout_in_seconds=5)
mp = mixpanel.Mixpanel("YOUR_PROJECT_TOKEN", remote_flags_config=remote_config)

user_context = {
    "distinct_id": "1234",
    "company_id": "X",
    "custom_properties": {"platform": "python"},
}

variant_value = mp.local_flags.get_variant_value(flag_key, "control", user_context)
```

**Suppressing exposure in Python is different from every other SDK.** `get_variant_value()` exposes **no** suppression parameter. Drop to `get_variant()`:

```python
from mixpanel import SelectedVariant

fallback = SelectedVariant(variant_value="control")
variant = mp.local_flags.get_variant(flag_key, fallback, user_context, report_exposure=False)
variant_value = variant.variant_value

mp.local_flags.track_exposure_event(flag_key, variant, user_context)
```

> The published docs show `report_exposure=False` for local evaluation and `reportExposure=False` for remote on the same page. Verify against the installed SDK's signature before relying on either spelling.

```python
# Does NOT fire exposure
variants = mp.remote_flags.get_all_variants(user_context)
```

### Go

```go
import (
    mixpanel "github.com/mixpanel/mixpanel-go"
    "github.com/mixpanel/mixpanel-go/flags"
)

localConfig := flags.LocalFlagsConfig{
    FlagsConfig:     flags.FlagsConfig{APIHost: "api.mixpanel.com"},
    EnablePolling:   true,
    PollingInterval: 60 * time.Second,
}
mp := mixpanel.NewApiClient("YOUR_PROJECT_TOKEN", mixpanel.WithLocalFlags(localConfig))
mp.LocalFlags.StartPollingForDefinitions(ctx)

// Remote requires an exposure tracker
remoteConfig := flags.RemoteFlagsConfig{FlagsConfig: flags.FlagsConfig{APIHost: "api.mixpanel.com"}}
mp := mixpanel.NewApiClient("YOUR_PROJECT_TOKEN",
    mixpanel.WithRemoteFlags(remoteConfig, mixpanel.DefaultFlagsExposureTracker))

userContext := flags.FlagContext{
    "distinct_id":       "1234",
    "company_id":        "X",
    "custom_properties": map[string]any{"platform": "go"},
}

variantValue, err := mp.LocalFlags.GetVariantValue(ctx, flagKey, "control", userContext)
isEnabled, err := mp.LocalFlags.IsEnabled(ctx, "new_feature", userContext)   // NOTE: no fallback param

variants, err := mp.RemoteFlags.GetAllVariants(ctx, userContext)             // no exposure
mp.RemoteFlags.TrackExposureEvent(ctx, flagKey, selectedVariant, userContext)
```

Go controls exposure through a custom `TrackerBuilder` rather than a per-call flag. `DefaultFlagsExposureTracker` sends synchronously; supply your own via `WithLocalFlagsAndTracker` to send asynchronously.

### Java

```java
LocalFlagsConfig localConfig = LocalFlagsConfig.builder()
    .projectToken("YOUR_PROJECT_TOKEN")
    .apiHost("api.mixpanel.com")          // no protocol
    .enablePolling(true)
    .pollingIntervalSeconds(60)
    .requestTimeoutSeconds(10)
    .build();

MixpanelAPI mixpanel = new MixpanelAPI(localConfig);
mixpanel.getLocalFlags().startPollingForDefinitions();

Map<String, Object> userContext = new HashMap<>();
userContext.put("distinct_id", "1234");
userContext.put("custom_properties", customProperties);

String value = mixpanel.getLocalFlags().getVariantValue(flagKey, "control", userContext);
boolean enabled = mixpanel.getLocalFlags().isEnabled(flagKey, userContext);   // NOTE: no fallback param

Map<String, SelectedVariant<Object>> all =
    mixpanel.getLocalFlags().getAllVariantsByFlag(userContext, true);          // note the distinct method name

mixpanel.close();   // stops polling; always call on shutdown
```

Java documents no per-call exposure suppression. If the customer needs manual exposure control on Java, verify against the installed SDK rather than assuming the Node/Python shape.

### Ruby

```ruby
require 'mixpanel-ruby'

local_config = { api_host: 'api.mixpanel.com', enable_polling: true, polling_interval_in_seconds: 60 }
tracker = Mixpanel::Tracker.new('YOUR_PROJECT_TOKEN', local_flags_config: local_config)
tracker.local_flags.start_polling_for_definitions!

user_context = {
  'distinct_id' => '1234',
  'company_id' => 'X',
  'custom_properties' => { 'platform' => 'ruby' }
}

variant_value = tracker.local_flags.get_variant_value(flag_key, 'control', user_context)

if tracker.local_flags.is_enabled?('new_feature', user_context)   # NOTE: no fallback param
  # ...
end

variants = tracker.remote_flags.get_all_variants(user_context)     # no exposure
tracker.remote_flags.track_exposure_event(flag_key, selected_variant, user_context)
```

---

## Cross-SDK differences worth checking before you write

Do not generalize a call shape from one SDK to another. The differences that actually bite:

| Concern | Varies how |
|---|---|
| `isEnabled` fallback parameter | Present on JS, Swift, Android, Flutter, React Native. **Absent** on Go, Java, Ruby. |
| Exposure suppression | Node: 4th positional `false`. Python: not on `get_variant_value` at all — use `get_variant(..., report_exposure=False)`. Go: custom tracker. Java, Ruby: undocumented. |
| "All variants" method | `getAllVariants` / `get_all_variants` / `GetAllVariants` — but Java is `getAllVariantsByFlag(context, bool)`. **None fire exposure.** |
| Async model | JS/Flutter/RN: promises, plus `*Sync` forms. Swift/Android: completion callbacks. Server local: synchronous. Server remote: async in Node, synchronous in Python/Ruby/Java. |
| Persistence | Client SDKs only. Flutter: iOS/Android only. |
| Local evaluation | Server SDKs only; no cohort targeting, no sticky variants. |

---

## OpenFeature

Mixpanel ships OpenFeature providers for JavaScript, Node.js, Python, Go, Java, Ruby, Swift, and Android. If the customer already uses OpenFeature, implement against the provider rather than the native flag API — their existing `getBooleanValue` / `getStringValue` call sites stay unchanged and only the provider registration changes. See the `*-openfeature` page for the platform in the Mixpanel SDK docs.
