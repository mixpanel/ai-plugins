---
name: implement
description: Implement Mixpanel tracking for new events and properties. Discovers existing schema, designs spec, writes SDK code, verifies instrumentation, and documents in Lexicon.
---

# Implement Mixpanel Tracking

Add new Mixpanel tracking to a codebase by grounding the implementation in existing schema, following project conventions, and documenting the result in Lexicon.

## Phase 1: Discover Existing Schema

Before designing anything, check what already exists. Reusing established names prevents fragmentation.

**Check for similar events:**
```
Get-Events project_id=<id> query="<keyword>"
```
If a similar event exists, consider extending it with a new property rather than creating a new event.

**Check properties on related events:**
```
Get-Property-Names resource_type=Event event="<similar event>"
```
Reuse property names that already exist — e.g. if `plan_type` is used on 10 events, don't introduce `planType` or `subscription_type`.

**Check established values for enum-like properties:**
```
Get-Property-Values resource_type=Event event="<event>" property="<property>"
```

**Detect naming conventions in use:**
Look at the existing event names to identify the project's convention:
- `[Feature] Action Taken` — bracket prefix style
- `Object Action` — title case, past tense
- `snake_case_event` — older or server-side convention

Match whatever convention the project already uses.

## Phase 2: Design the Spec

Ask the user whether to proceed with a written spec first or go straight to code:

> I can either:
> **A) Write a spec first** (recommended) — define the event name, trigger, properties, and types for your review before touching any code. Easier to catch naming issues early.
> **B) Go straight to code** — generate the SDK call directly based on what you've described.
>
> Which would you prefer?

**Recommend option A.** A spec review takes 30 seconds and prevents a Mixpanel event name being baked into production with a typo or naming inconsistency that's painful to change later.

### Spec format

```
Event: <Name>
Trigger: <Exact condition — e.g. "user clicks Submit on /checkout">
Properties:
  - <property_name> (string) — <what it represents>
  - <property_name> (number) — <what it represents>
  - ...
Reused from existing schema: <list any properties being reused>
New properties: <list any net-new properties>
Owner: <team or email>
```

Apply these checks before finalizing the spec:

- [ ] Name matches project convention (bracket prefix / title case / etc.)
- [ ] Name is past tense and specific (`Checkout Completed`, not `Checkout` or `Button Clicked`)
- [ ] No dynamic values in the event name — use a property instead
- [ ] No PII in properties (email, name, phone, address)
- [ ] Property names are `snake_case` and match existing names where possible
- [ ] Required properties will always be present on every call

## Phase 3: Implement

Infer the SDK from the project's language and framework. Do not ask — detect from file extensions, `package.json`, `requirements.txt`, `build.gradle`, `Package.swift`, or other project signals.

### SDK detection guide

| Signal | SDK |
|--------|-----|
| `package.json` with `mixpanel-browser` | JavaScript browser |
| `package.json` with `mixpanel` (no `-browser`) | Node.js |
| `requirements.txt` / `pyproject.toml` with `mixpanel` | Python |
| `Package.swift` or `.xcodeproj` | iOS (Swift) |
| `build.gradle` or `AndroidManifest.xml` | Android (Kotlin/Java) |
| No client project, just server files | Use server SDK for detected language |

### Track call placement

Place the `track()` call as close to the triggering action as possible — in the event handler, form submit callback, or API endpoint that represents the action.

```js
// JavaScript example — adapt syntax to project language
mixpanel.track('Event Name', {
  property_name: value,
  another_property: value,
})
```

### Identity checklist

- [ ] Has `identify(userId)` been called earlier in the session (on login/signup)?
- [ ] Are you using `people.set()` for user profile properties, not `track()`?
- [ ] Is `identify()` called once per session, not on every page load?
- [ ] Are you using a stable unique ID (not email, not device ID)?

### Super properties

If a property needs to appear on every future event (e.g. `plan_type` after upgrade), use `register()` rather than passing it to every `track()` call:

```js
mixpanel.register({ plan_type: 'pro' })
```

## Phase 4: Verify

After deploying, confirm the event is flowing:

```
Run-Segmentation-Query:
  event:     "<Event Name>"
  from_date: "<today>"
  to_date:   "<today>"
  unit:      "day"
  type:      "general"
```

Zero results = event not firing, or event name has a typo (Mixpanel is case-sensitive).

Check that property values are populating:
```
Get-Property-Values:
  resource_type: "Event"
  event:         "<Event Name>"
  property:      "<property_name>"
```

## Phase 5: Document in Lexicon

Register the event and all new properties once verified:

```
Edit-Event:
  project_id:     <id>
  event_name:     "<Event Name>"
  description:    "<trigger condition and why this event is tracked>"
  verified:       true
  contact_emails: ["<owner>"]
  tags:           ["<relevant tags>"]
```

For each new property:
```
Edit-Property:
  project_id:    <id>
  resource_type: "Event"
  property_name: "<property_name>"
  description:   "<what the value represents, valid values if enum>"
  sensitive:     false   # set true if PII
```

## Common Pitfalls

- **Event names are case-sensitive.** `Checkout Completed` ≠ `checkout completed`. The name in your code must match Lexicon exactly.
- **Don't create a new event if one already exists.** Check `Get-Events` first — a duplicate event with a slightly different name is one of the most common Mixpanel debt problems.
- **Don't reuse an event for two different actions.** If `Button Clicked` is already tracked for the nav bar, don't also fire it for the checkout CTA. Use a specific name.
- **Don't pass objects or arrays as property values** unless you intend a `list` type. Nested objects are not supported — flatten them.
- **Server-side and client-side calls can conflict.** If both fire the same event, ensure `user_id` / `distinct_id` are consistent, or you'll get identity graph issues.
