---
name: tracking-plan
description: Guidance for designing, implementing, and maintaining Mixpanel tracking plans — from discovery through code instrumentation.
---

# Tracking Plan

A tracking plan defines what events and properties your application sends to Mixpanel, why each is tracked, and who owns it.

## When to use MCP tools

Before designing new events, ground yourself in what already exists:

```
Get-Events project_id=<id>                              # full event list
Get-Events project_id=<id> query="signup"               # filter to relevant events
Get-Property-Names resource_type=Event event="..."   # properties on a specific event
Get-Property-Values resource_type=Event event="..." property="..." # known values
Get-Issues project_id=<id> limit=20                     # open data quality issues
```

After designing, register definitions in Lexicon:
```
Edit-Event   event_name="New Event" description="..." tags=[...] contact_emails=[...]
Edit-Property property_name="new_prop" resource_type="Event" description="..."
```

## Tracking Plan Anatomy

Every event definition should capture:

| Field | Description | Example |
|-------|-------------|---------|
| Event name | Past tense, title case | `Form Submitted` |
| Description | What triggered it, why it matters | "User clicked submit on checkout form" |
| Trigger | Exact UI/code condition | "On `form.submit` in `/checkout`" |
| Owner | Team or email | `growth@company.com` |
| Properties | List with type + description | see below |
| Status | `active`, `deprecated`, `planned` | `active` |

### Property Definition

| Field | Description |
|-------|-------------|
| Name | snake_case preferred |
| Type | `string`, `number`, `boolean`, `list`, `datetime` |
| Description | What the value represents |
| Example values | 2-3 real values |
| Required | Whether it must always be present |

## Design Principles

**1. Track actions, not views**
Prefer `Button Clicked` over `Page Viewed` when you care about intent. Use `Viewed report` for funnel entry steps.

**2. Be specific in names**
`Upgrade Button Clicked` is better than `Button Clicked`. Include location or context when the same action happens in multiple places.

**3. Normalize property names across events**
Pick one name per concept and use it everywhere:
- `user_id` not `userId` or `UserId`
- `plan_type` not `subscription_type` for the same concept
- Prefix context-specific properties: `checkout_step`, `checkout_item_count`

**4. Never use dynamic values in event names**
```js
// Bad — creates unbounded event names
mixpanel.track(`Viewed Product ${productId}`)

// Good — one event, property captures the variable
mixpanel.track('Product Viewed', { product_id: productId })
```

**5. Design for the questions you need to answer**
Before adding an event, write the Mixpanel query it enables:
- "What % of users who start checkout complete it?" → needs `Checkout Started` + `Purchase Completed`
- "Which features drive 2nd-week retention?" → needs feature events + `Run-Retention-Query`

## Naming Conventions

### Events
- Format: `[Object] [Verb]` — title case, past tense
- Good: `Signup Completed`, `Dashboard Loaded`, `Export Triggered`
- Avoid: `click_button`, `userSignedUp`, `event_123`

### Properties
- Format: `snake_case`
- Good: `plan_type`, `item_count`, `is_trial`, `signup_type`
- Avoid: `planType`, `Plan Name`, `p1`

**Note:** Many projects mix conventions — `Title Case`, `[Feature] Action Taken`, or `snake_case`. Always check existing event names before adding new ones and match whatever style is already in use.

## Implementation Checklist

When instrumenting a new event:
- [ ] Event name matches tracking plan exactly (Mixpanel is case-sensitive)
- [ ] All required properties are present on every call
- [ ] `identify()` has been called before any `people.set()` calls
- [ ] No PII in event properties (email, phone, SSN, etc.)
- [ ] Event verified in Mixpanel Events live view
- [ ] Confirm event appears via `Run-Segmentation-Query` (use a 1-day window)
- [ ] Event documented in Lexicon via `Edit-Event`
- [ ] All new properties documented via `Edit-Property`

## Verify Instrumentation with MCP

After deploying, confirm data is flowing:

```
Run-Segmentation-Query:
  event:     "New Event Name"
  from_date: "today"
  to_date:   "today"
  unit:      "day"

Get-Property-Values:
  resource_type: "Event"
  event:         "New Event Name"
  property:      "new_property_name"
```

Zero results from segmentation = event not firing or wrong event name.
