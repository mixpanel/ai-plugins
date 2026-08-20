# Mixpanel SDK Implementation Snippets

**Purpose:** Standalone, per-language Mixpanel implementation code snippets. This file can be consumed directly by AI agents or developers without loading the rest of the tracking-implementation skill. The main skill reference ([reference.md](reference.md)) points here for all per-language code.

**Languages without snippets below:** See [SDK Documentation Links](#sdk-documentation-links) for all official SDKs. If Mixpanel has no SDK for your language, use the [HTTP API](#http-api-language-agnostic) — it works from any language that can make an HTTPS POST request.

**Token substitution:** When surfacing any code snippet below, replace `'YOUR_PROJECT_TOKEN'` with the real project token. Use the dev token in dev initialization blocks and the prod token in production initialization blocks. Never output the placeholder literal if real tokens are already in hand.

This file has two parts:

1. **Runtime Patterns** — three cross-cutting concerns that modify every snippet below. Read first.
2. **Quick Start Snippets** — minimal init + track + identify/reset per platform, for getting working code fast
3. **Full SDK Lifecycle Guide** — install → init → track event → super properties → user profile → identify → reset, per SDK

---

## Runtime Patterns -- Read Before Using Any Snippet Below

Three failure modes that the snippets below do not cover on their own. All three share a shape: they work in a developer's dev server and fail silently in production, so testing does not catch them.

### 1. Data residency -- `api_host`

An EU- or India-resident project left on the default host sends every event nowhere and reports no error. Mixpanel's docs are explicit that no data is ingested unless the SDK points at that region's endpoint.

| Residency | `api_host` |
| --- | --- |
| US (default) | `https://api.mixpanel.com` |
| EU | `https://api-eu.mixpanel.com` |
| India | `https://api-in.mixpanel.com` |

```javascript
mixpanel.init('YOUR_PROJECT_TOKEN', {
  api_host: 'https://api-eu.mixpanel.com',   // omit for US
});
```

The same config key exists across SDKs (`api_host`, or the server-URL equivalent). If you do not know the project's residency, **ask** -- you cannot detect a wrong host from the code, and the build will succeed either way. Docs: [EU](https://docs.mixpanel.com/docs/privacy/eu-residency), [India](https://docs.mixpanel.com/docs/privacy/in-residency).

### 2. Server-rendered frameworks -- initialize on the client only

`mixpanel-browser` imported at module scope in a server component throws. "Initialize the SDK on app boot" has no single meaning in Next.js App Router, Remix, SvelteKit, or Nuxt, so do not follow it literally.

Three requirements: a client-only boundary, a `typeof window` guard, and once-only execution that survives hot reload and client-side route changes.

```javascript
'use client';

import { useEffect, useRef } from 'react';
import mixpanel from 'mixpanel-browser';

// Module-level flag survives component remounts and Fast Refresh;
// a bare useEffect would re-init on every route change in dev.
let initialized = false;

export function MixpanelProvider({ children }) {
  const started = useRef(false);

  useEffect(() => {
    if (typeof window === 'undefined') return;
    if (initialized || started.current) return;
    initialized = true;
    started.current = true;

    mixpanel.init(process.env.NEXT_PUBLIC_MIXPANEL_TOKEN, {
      api_host: process.env.NEXT_PUBLIC_MIXPANEL_API_HOST, // undefined = US default
    });
  }, []);

  return children;
}
```

Mount this once, high in the tree (in `app/layout.tsx` for App Router). Any component that calls `mixpanel.track()` must itself be a client component. If a tracked action lives in a server action or route handler, use the **server** SDK there instead -- don't try to reach the browser instance.

This is the most likely place a build actually breaks rather than the tracking quietly misbehaving, so confirm the app still builds before moving on.

### 3. Server SDKs in short-lived processes -- flush before exit

Buffered consumers batch events and send when the batch fills. A process that exits before the batch fills drops those events **with no error**.

Affected: serverless functions (Lambda, Cloud Functions, Vercel/Netlify), cron jobs, CLI scripts, queue workers that exit per message, and any handler that returns immediately after tracking.

For **mixpanel-python**, the choice of consumer decides whether you need this. Verified against the SDK source:

- `Consumer` (the default) sends one request per call. Safe in short-lived processes; slower under high volume.
- `BufferedConsumer` batches up to 50 messages per endpoint and only sends when a buffer fills or you call `flush()`. **Anything still buffered at process exit is lost.**

```python
from mixpanel import Mixpanel, BufferedConsumer

consumer = BufferedConsumer()
mp = Mixpanel('YOUR_PROJECT_TOKEN', consumer=consumer)

try:
    mp.track(user_id, 'subscription_upgraded', {'plan': 'pro'})
finally:
    consumer.flush()   # REQUIRED -- without this the event never leaves the process
```

In a Lambda handler, flush before returning -- not in a background task, which the runtime may freeze mid-flight.

For other server SDKs, check that SDK's batching semantics before you ship: if it buffers at all, find its flush/shutdown call and `await` it before the process or handler returns. Add the flush when you write the code. This failure is invisible in a long-running dev server, so nobody finds it until data is already missing.

### Bonus: deterministic `$insert_id`

Server-side events need `$insert_id` for deduplication (see the HTTP API section below). A randomly generated value defeats the purpose -- a retried webhook produces a new key and a duplicate event. Derive it from the logical occurrence instead:

```python
insert_id = f"subscription_upgraded-{subscription_id}-{billing_period}"
```

Retried webhooks, at-least-once queues, and re-run jobs are exactly the traffic this protects.

---

## Quick Start Snippets -- Minimal (init + track + identify/reset)

Use this section to reach working code fast. Each platform has three blocks: **init**, **track**, and **identify/reset**. For the full SDK lifecycle (super properties, user profiles, advanced configuration), see the Full SDK Lifecycle Guide below.

### JavaScript (Browser) -- Quick Start

```javascript
// 1. Init -- add <script src="https://cdn.mxpnl.com/libs/mixpanel-2-latest.min.js"></script> first
mixpanel.init('YOUR_PROJECT_TOKEN', { debug: true });

// 2. Track
mixpanel.track('sign_up_completed', {
  sign_up_method: 'email',
  platform: 'web'
});

// 3. Identity
mixpanel.identify(user.id);                       // on login/signup
mixpanel.people.set({ $name: user.name, $email: user.email });
mixpanel.reset();                                  // on logout
```

**Consent gate (if EU/CA):**

```javascript
mixpanel.init('YOUR_PROJECT_TOKEN', { opt_out_tracking_by_default: true });
// After user consents:
mixpanel.opt_in_tracking();
```

### Python (Server-Side) -- Quick Start

```python
# pip install mixpanel
from mixpanel import Mixpanel
mp = Mixpanel('YOUR_PROJECT_TOKEN')

# Track
mp.track(user_id, 'sign_up_completed', {
    'sign_up_method': 'email',
    'platform': 'web',
    '$insert_id': unique_dedup_key
})

# Identity -- set user profile after signup
mp.people_set(user_id, {
    '$name': user.name,
    '$email': user.email
})
```

### Node.js (Server-Side) -- Quick Start

```javascript
// npm install mixpanel
const Mixpanel = require('mixpanel');
const mixpanel = Mixpanel.init('YOUR_PROJECT_TOKEN');

// Track
mixpanel.track('sign_up_completed', {
  distinct_id: userId,
  sign_up_method: 'email',
  platform: 'web',
  $insert_id: uniqueDedupKey
});

// Identity -- set user profile
mixpanel.people.set(userId, { $name: user.name, $email: user.email });
```

### React Native -- Quick Start

```javascript
// npm install mixpanel-react-native
import { Mixpanel } from 'mixpanel-react-native';
const mixpanel = new Mixpanel('YOUR_PROJECT_TOKEN', true);
await mixpanel.init();

// Track
mixpanel.track('sign_up_completed', { sign_up_method: 'email', platform: 'mobile' });

// Identity
mixpanel.identify(user.id);
mixpanel.getPeople().set({ $name: user.name, $email: user.email });
mixpanel.reset();  // on logout
```

### iOS (Swift) -- Quick Start

```swift
// Add Mixpanel via SPM or CocoaPods
import Mixpanel
Mixpanel.initialize(token: "YOUR_PROJECT_TOKEN", trackAutomaticEvents: true)

// Track
Mixpanel.mainInstance().track(event: "sign_up_completed", properties: [
    "sign_up_method": "email",
    "platform": "ios"
])

// Identity
Mixpanel.mainInstance().identify(distinctId: user.id)
Mixpanel.mainInstance().people.set(properties: ["$name": user.name, "$email": user.email])
Mixpanel.mainInstance().reset()  // on logout
```

### Android (Kotlin) -- Quick Start

```kotlin
// implementation 'com.mixpanel.android:mixpanel-android:7.+'
import com.mixpanel.android.mpmetrics.MixpanelAPI
val mixpanel = MixpanelAPI.getInstance(context, "YOUR_PROJECT_TOKEN", true)

// Track
val props = JSONObject()
props.put("sign_up_method", "email")
props.put("platform", "android")
mixpanel.track("sign_up_completed", props)

// Identity
mixpanel.identify(user.id)
mixpanel.people.set("\$name", user.name)
mixpanel.people.set("\$email", user.email)
mixpanel.reset()  // on logout
```

### Flutter -- Quick Start

```dart
// mixpanel_flutter: ^2.3.0 in pubspec.yaml
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
final mixpanel = await Mixpanel.init('YOUR_PROJECT_TOKEN', trackAutomaticEvents: true);

// Track
mixpanel.track('sign_up_completed', properties: {
  'sign_up_method': 'email',
  'platform': 'flutter'
});

// Identity
mixpanel.identify(user.id);
mixpanel.getPeople().set('\$name', user.name);
mixpanel.getPeople().set('\$email', user.email);
mixpanel.reset();  // on logout
```

### HTTP API -- Quick Start

```bash
# Track
curl -X POST https://api.mixpanel.com/track \
  -H 'Content-Type: application/json' \
  -d '[{
    "event": "sign_up_completed",
    "properties": {
      "token": "YOUR_PROJECT_TOKEN",
      "distinct_id": "user-123",
      "time": 1740000000,
      "$insert_id": "unique-dedup-key",
      "sign_up_method": "email",
      "platform": "web"
    }
  }]'

# Set user profile
curl -X POST https://api.mixpanel.com/engage \
  -H 'Content-Type: application/json' \
  -d '[{
    "$token": "YOUR_PROJECT_TOKEN",
    "$distinct_id": "user-123",
    "$set": { "$name": "Alice Smith", "$email": "alice@example.com" }
  }]'
```

---

## Full SDK Lifecycle Guide

Each section below covers the full implementation lifecycle for one SDK: **install -> init -> track event -> super properties -> user profile -> identify -> reset**.

### JavaScript (Browser)

**Install via CDN (paste before closing `</head>` tag):**

```html
<script type="text/javascript">
  (function (f, b) { if (!b.__SV) { var e, g, i, h; window.mixpanel = b; b._i = []; b.init = function (e, f, c) { function g(a, d) { var b = d.split("."); 2 == b.length && ((a = a[b[0]]), (d = b[1])); a[d] = function () { a.push([d].concat(Array.prototype.slice.call(arguments, 0))); }; } var a = b; "undefined" !== typeof c ? (a = b[c] = []) : (c = "mixpanel"); a.people = a.people || []; a.toString = function (a) { var d = "mixpanel"; "mixpanel" !== c && (d += "." + c); a || (d += -- (stub)"); return d; }; a.people.toString = function () { return a.toString(1) + ".people (stub)"; }; i = "disable time_event track track_pageview track_links track_forms track_with_groups add_group set_group remove_group register register_once alias unregister identify name_tag set_config reset opt_in_tracking opt_out_tracking has_opted_in_tracking has_opted_out_tracking clear_opt_in_out_tracking start_batch_senders people.set people.set_once people.unset people.increment people.append people.union people.track_charge people.clear_charges people.delete_user people.remove".split(-- ); for (h = 0; h < i.length; h++) g(a, i[h]); var j = "set set_once union unset remove delete".split(-- ); a.get_group = function () { function b(c) { d[c] = function () { call2_args = arguments; call2 = [c].concat(Array.prototype.slice.call(call2_args, 0)); a.push([e, call2]); }; } for ( var d = {}, e = ["get_group"].concat(Array.prototype.slice.call(arguments, 0)), c = 0; c < j.length; c++) b(j[c]); return d; }; b._i.push([e, f, c]); }; b.__SV = 1.2; e = f.createElement("script"); e.type = "text/javascript"; e.async = !0; e.src = "//cdn.mxpnl.com/libs/mixpanel-2-latest.min.js"; g = f.getElementsByTagName("script")[0]; g.parentNode.insertBefore(e, g); } })(document, window.mixpanel || []);
</script>
```

**Or install via npm:**

```bash
npm install mixpanel-browser
```

**Initialize:**

```javascript
import mixpanel from 'mixpanel-browser';

// Use localStorage for reliability (cookie is default but fragile cross-subdomain)
mixpanel.init('YOUR_PROJECT_TOKEN', {
  debug: process.env.NODE_ENV !== 'production', // logs all calls in dev
  track_pageview: true,     // auto-tracks Page View on every navigation -- OMIT THIS if autocapture: true is set (autocapture already fires page views; combining both produces duplicates)
  persistence: 'localStorage'
});
```

**Register Super Properties (call once at app load or after login):**

```javascript
mixpanel.register({
  platform: 'web',
  app_version: '2.4.1',
  plan_type: user.plan   // set after login
});
```

**Track an Event:**

```javascript
mixpanel.track('checkout_completed', {
  order_id: 'ORD-9821',
  order_total: 89.97,
  item_count: 3,
  payment_method: 'credit_card',
  is_first_purchase: true
});
```

**Set User Profile (call after identify):**

```javascript
mixpanel.people.set({
  $name: user.fullName,
  $email: user.email,
  $created: user.createdAt,
  plan_type: user.plan,
  company: user.company
});

// Use set_once for properties that should never be overwritten
mixpanel.people.set_once({
  first_sign_up_date: new Date().toISOString(),
  acquisition_source: utmSource
});
```

**Identify User (call on login and signup):**

```javascript
// On successful login or signup
mixpanel.identify(user.id);  // use your database user ID, not email
mixpanel.people.set({ $email: user.email, $name: user.name, plan_type: user.plan });
mixpanel.register({ plan_type: user.plan }); // also set as super property
```

**Reset on Logout:**

```javascript
// On logout -- clears local storage and generates a new $device_id
mixpanel.reset();
```

---

### Python (Server-Side)

**Install:**

```bash
pip install mixpanel
```

**Initialize (module-level singleton):**

```python
from mixpanel import Mixpanel

mp = Mixpanel('YOUR_PROJECT_TOKEN')
```

**Track an Event:**

```python
# distinct_id should be your user's database ID for identified users,
# or the $device_id (anonymous ID) for pre-login events
mp.track(user_id, 'checkout_completed', {
    'order_id': 'ORD-9821',
    'order_total': 89.97,
    'item_count': 3,
    'payment_method': 'credit_card',
    'is_first_purchase': True,
    'ip': request.remote_addr  # forward client IP for geolocation
})
```

**Track a Pre-Login (Anonymous) Event:**

```python
# Use $device_id and $user_id properties instead of setting distinct_id directly
# This enables Mixpanel's Simplified ID Merge to stitch sessions together
mp.track('', 'page_viewed', {
    '$device_id': session.get('anonymous_id'),  # UUID stored in cookie
    'page_name': '/pricing',
    'ip': request.remote_addr
})
```

**Track a Post-Login Event (linking anonymous to identified):**

```python
mp.track('', 'sign_up_completed', {
    '$device_id': session.get('anonymous_id'),  # the pre-login ID
    '$user_id': str(user.id),                   # the authenticated ID
    'sign_up_method': 'google',
    'ip': request.remote_addr
})
# After this call, Mixpanel merges the anonymous and authenticated sessions
```

**Set User Profile:**

```python
mp.people_set(str(user.id), {
    '$name': user.full_name,
    '$email': user.email,
    '$created': user.created_at.isoformat(),
    'plan_type': user.plan,
    '$ip': 0  # set to 0 to prevent overwriting geolocation with server IP
})
```

**Set Profile Properties Only Once:**

```python
mp.people_set_once(str(user.id), {
    'first_sign_up_date': user.created_at.isoformat(),
    'acquisition_source': user.utm_source
})
```

---

### Node.js (Server-Side)

**Install:**

```bash
npm install mixpanel
```

**Initialize:**

```javascript
const Mixpanel = require('mixpanel');
const mp = Mixpanel.init('YOUR_PROJECT_TOKEN');
```

**Track an Event:**

```javascript
mp.track('checkout_completed', {
  distinct_id: user.id,
  order_id: 'ORD-9821',
  order_total: 89.97,
  item_count: 3,
  payment_method: 'credit_card',
  is_first_purchase: true,
  ip: req.ip
});
```

**Track Anonymous Pre-Login Event:**

```javascript
mp.track('page_viewed', {
  $device_id: req.cookies.anonymous_id,
  page_name: '/pricing',
  ip: req.ip
});
```

**Link Anonymous to Authenticated (on login/signup):**

```javascript
mp.track('sign_up_completed', {
  $device_id: req.cookies.anonymous_id,
  $user_id: String(user.id),
  sign_up_method: 'email',
  ip: req.ip
});
```

**Set User Profile:**

```javascript
mp.people.set(String(user.id), {
  $name: user.fullName,
  $email: user.email,
  $created: user.createdAt.toISOString(),
  plan_type: user.plan,
  $ip: 0
});
```

---

### React Native

**Install:**

```bash
npm install mixpanel-react-native
npx pod-install  # iOS only
```

**Initialize (in App.js or your root component):**

```javascript
import { Mixpanel } from 'mixpanel-react-native';

const mixpanel = new Mixpanel('YOUR_PROJECT_TOKEN', true); // true = enable autocapture
await mixpanel.init();
```

**Register Super Properties:**

```javascript
mixpanel.registerSuperProperties({
  platform: Platform.OS,   // 'ios' or 'android'
  app_version: '2.4.1'
});
```

**Track an Event:**

```javascript
mixpanel.track('video_played', {
  video_id: 'VID-123',
  video_title: 'Getting Started Guide',
  duration_seconds: 342,
  quality: 'hd'
});
```

**Identify on Login:**

```javascript
mixpanel.identify(user.id);
mixpanel.getPeople().set({
  $name: user.fullName,
  $email: user.email,
  plan_type: user.plan
});
```

**Reset on Logout:**

```javascript
mixpanel.reset();
```

---

### iOS (Swift)

**Install via Swift Package Manager:**

In Xcode: File -> Add Packages -> `https://github.com/mixpanel/mixpanel-swift`

**Initialize in `AppDelegate.swift` or `App.swift`:**

```swift
import Mixpanel

// In application(_:didFinishLaunchingWithOptions:) or @main App init
Mixpanel.initialize(token: "YOUR_PROJECT_TOKEN", trackAutomaticEvents: true)
```

**Register Super Properties:**

```swift
Mixpanel.mainInstance().registerSuperProperties([
    "platform": "ios",
    "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
])
```

**Track an Event:**

```swift
Mixpanel.mainInstance().track(event: "checkout_completed", properties: [
    "order_id": "ORD-9821",
    "order_total": 89.97,
    "item_count": 3,
    "payment_method": "credit_card",
    "is_first_purchase": true
])
```

**Identify on Login:**

```swift
Mixpanel.mainInstance().identify(distinctId: user.id)
Mixpanel.mainInstance().people.set(properties: [
    "$name": user.fullName,
    "$email": user.email,
    "plan_type": user.plan
])
```

**Reset on Logout:**

```swift
Mixpanel.mainInstance().reset()
```

---

### Android (Kotlin)

**Add dependency to `build.gradle`:**

```groovy
implementation 'com.mixpanel.android:mixpanel-android:7.+'
```

**Initialize in `Application.onCreate()`:**

```kotlin
import com.mixpanel.android.mpmetrics.MixpanelAPI

class MyApplication : Application() {
    lateinit var mixpanel: MixpanelAPI

    override fun onCreate() {
        super.onCreate()
        mixpanel = MixpanelAPI.getInstance(this, "YOUR_PROJECT_TOKEN", true)
    }
}
```

**Register Super Properties:**

```kotlin
val superProps = JSONObject()
superProps.put("platform", "android")
superProps.put("app_version", BuildConfig.VERSION_NAME)
mixpanel.registerSuperProperties(superProps)
```

**Track an Event:**

```kotlin
val props = JSONObject()
props.put("order_id", "ORD-9821")
props.put("order_total", 89.97)
props.put("item_count", 3)
props.put("payment_method", "credit_card")
mixpanel.track("checkout_completed", props)
```

**Identify on Login:**

```kotlin
mixpanel.identify(user.id)
mixpanel.people.set("\$name", user.fullName)
mixpanel.people.set("\$email", user.email)
mixpanel.people.set("plan_type", user.plan)
```

**Reset on Logout:**

```kotlin
mixpanel.reset()
```

---

### Flutter

**Install (add to `pubspec.yaml`):**

```yaml
dependencies:
  mixpanel_flutter: ^2.3.0
```

Then run:

```bash
flutter pub get
```

**Initialize (in `main.dart` or your root widget):**

```dart
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

late Mixpanel mixpanel;

Future<void> initMixpanel() async {
  mixpanel = await Mixpanel.init(
    'YOUR_PROJECT_TOKEN',
    trackAutomaticEvents: true,
  );
}
```

**Register Super Properties:**

```dart
mixpanel.registerSuperProperties({
  'platform': 'flutter',
  'app_version': '2.4.1',
});
```

**Track an Event:**

```dart
mixpanel.track('checkout_completed', properties: {
  'order_id': 'ORD-9821',
  'order_total': 89.97,
  'item_count': 3,
  'payment_method': 'credit_card',
  'is_first_purchase': true,
});
```

**Identify on Login:**

```dart
mixpanel.identify(user.id);
mixpanel.getPeople().set('\$name', user.fullName);
mixpanel.getPeople().set('\$email', user.email);
mixpanel.getPeople().set('plan_type', user.plan);
```

**Set Profile Properties Only Once:**

```dart
mixpanel.getPeople().setOnce('first_sign_up_date', DateTime.now().toIso8601String());
```

**Reset on Logout:**

```dart
mixpanel.reset();
```

---

### HTTP API (Language-Agnostic)

Use the HTTP API when no SDK is available for your language, or for server-to-server integrations.

**Track an Event:**

```bash
curl --request POST \
  --url https://api.mixpanel.com/track \
  --header 'Content-Type: application/json' \
  --data '[{
    "event": "checkout_completed",
    "properties": {
      "token": "YOUR_PROJECT_TOKEN",
      "distinct_id": "user-12345",
      "time": 1740000000,
      "$insert_id": "unique-dedup-key-abc123",
      "order_id": "ORD-9821",
      "order_total": 89.97,
      "item_count": 3,
      "payment_method": "credit_card"
    }
  }]'
```

**Key fields for server-side HTTP API:**

| Field | Notes |
| --- | --- |
| `token` | Your project token (required) |
| `distinct_id` | The user identifier |
| `time` | Unix timestamp in seconds (required for server-side; auto-set by SDKs) |
| `$insert_id` | A unique ID for this event -- **always set this** to prevent duplicate ingestion on retries |
| `ip` | Forward the client's IP for correct geolocation |

**Set a User Profile:**

```bash
curl --request POST \
  --url https://api.mixpanel.com/engage \
  --header 'Content-Type: application/json' \
  --data '[{
    "$token": "YOUR_PROJECT_TOKEN",
    "$distinct_id": "user-12345",
    "$ip": "0",
    "$set": {
      "$name": "Alice Smith",
      "$email": "alice@example.com",
      "plan_type": "pro",
      "$created": "2026-02-20T10:00:00"
    }
  }]'
```

---

## SDK Documentation Links

All official Mixpanel SDKs, each linking to its documentation.

| SDK | Type | URL |
| --- | --- | --- |
| All SDKs (full list) | -- | https://docs.mixpanel.com/docs/tracking-methods/sdks.md |
| JavaScript | Client-side | https://docs.mixpanel.com/docs/tracking-methods/sdks/javascript.md |
| React Native | Client-side | https://docs.mixpanel.com/docs/tracking-methods/sdks/react-native.md |
| Android | Client-side | https://docs.mixpanel.com/docs/tracking-methods/sdks/android.md |
| iOS (Objective-C) | Client-side | https://docs.mixpanel.com/docs/tracking-methods/sdks/ios.md |
| iOS (Swift) | Client-side | https://docs.mixpanel.com/docs/tracking-methods/sdks/swift.md |
| Flutter | Client-side | https://docs.mixpanel.com/docs/tracking-methods/sdks/flutter.md |
| Unity | Client-side | https://docs.mixpanel.com/docs/tracking-methods/sdks/unity.md |
| Python | Server-side | https://docs.mixpanel.com/docs/tracking-methods/sdks/python.md |
| Node.js | Server-side | https://docs.mixpanel.com/docs/tracking-methods/sdks/nodejs.md |
| Ruby | Server-side | https://docs.mixpanel.com/docs/tracking-methods/sdks/ruby.md |
| PHP | Server-side | https://docs.mixpanel.com/docs/tracking-methods/sdks/php.md |
| Go | Server-side | https://docs.mixpanel.com/docs/tracking-methods/sdks/go.md |
| Java | Server-side | https://docs.mixpanel.com/docs/tracking-methods/sdks/java.md |
| HTTP API | Any language | https://developer.mixpanel.com/reference/track-event.md |
