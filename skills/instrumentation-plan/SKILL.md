---
name: instrumentation-plan
description: >
  Build a Mixpanel instrumentation plan from product context — PRDs, user journeys,
  business questions, or feature briefs. For customers without tracking in code yet
  (or scoping a new feature) who need a plan before engineering starts. ALWAYS use
  when a customer or user asks to: build a tracking plan, design events for a new
  feature, plan instrumentation for a launch, set up Mixpanel from scratch, decide
  what to track, translate a PRD or user journey into events, or define an event
  taxonomy. Triggers: "what should we track", "design our events", "tracking plan
  for [X]", "starting fresh with Mixpanel", "instrumentation for [launch]", "events
  for the [X] flow", "translate this PRD into events", "set up tracking for", "plan
  our events". Also use when the customer pastes a PRD, user journey, feature brief,
  or business question and asks how to instrument it. Requires Mixpanel MCP. For
  auditing existing code against Lexicon, use `instrumentation-planner` instead.
compatibility: "Requires Mixpanel MCP. Customer must have their own Mixpanel project access."
---

# Instrumentation Plan

End-to-end planning workflow for a new Mixpanel instrumentation effort. Takes
product context as input — PRDs, user journeys, feature briefs, or business
questions — and produces a tracking plan, canonical SDK code templates, and
optional Lexicon write-back.

This skill is for **planning instrumentation that does not yet exist**. If the
customer already has tracking code and wants to find gaps, use
`instrumentation-planner` instead.

The customer owns their taxonomy. Never write to Lexicon without explicit
confirmation showing the exact diff.

---

## What this skill will and won't do

**Will:**
- Translate product context (PRD / user journey / business question) into a
  prioritized event list
- Detect and reuse existing Lexicon conventions to prevent naming drift
- Generate ready-to-paste SDK code templates against the customer's chosen SDK
- Produce a tracking plan as Markdown + XLSX
- Optionally write events and properties to Lexicon with explicit confirmation

**Won't:**
- Scan source code for existing tracking (use `instrumentation-planner`)
- Write to Lexicon without showing the exact diff and getting a "yes, proceed"
- Recommend tracking PII as event properties
- Generate raw SDK calls without flagging that a wrapper is the right pattern
- Decide priorities for the customer — it proposes, the customer approves

---

## MCP Tools Reference

Authoritative tool list. Do not invent tool names or parameters not listed here.

| Tool | Key Parameters | Notes |
|------|---------------|-------|
| `Get-Projects` | _(none)_ | Always call first — resolves project ID and workspace ID |
| `Get-Events` | `project_id`, `query` (substring), `event_names` (exact list), `include_details`, `workspace_id` | Two modes are mutually exclusive: `query` OR `event_names`, never both |
| `Get-Properties` | `project_id`, `resource_type` ("Event"\|"User"), `events` (list), `query`, `include_details`, `workspace_id` | Use `events=[]` to scope to specific events |
| `Get-Lexicon-URL` | `project_id`, `event` (string), `property` (string), `workspace_id` | Pass `event` OR `property`, not both |
| `Bulk-Edit-Events` | `project_id`, `events` (array of `{name, description, display_name}`), `tags`, `verified`, `workspace_id` — max 50/call | Batch if >50 events |
| `Bulk-Edit-Properties` | `project_id`, `resource_type`, `properties` (array of `{name, description, display_name, example_value}`), `sensitive`, `tags`, `workspace_id` — max 50/call | Same resource_type per call |

---

## Phase 0 — Orient & Verify

### Step 0A — MCP connectivity check (hard stop)

Call `Get-Projects` immediately. No parameters needed.

If it fails or returns no projects:
> "I need the Mixpanel MCP connected to run this workflow. Please connect it at
> mixpanel.com/settings and try again. Without it I can't pull your existing
> Lexicon conventions or write events back at the end."

Do not proceed past this point without a successful `Get-Projects` response.

If successful, present the project list and ask the customer to confirm which
project. Note the `workspace_id` from the response — include it in all
subsequent MCP calls.

### Step 0B — Intake

Ask all of the following in a single message. Skip any already answered earlier
in the conversation.

```
1. Which project? (confirmed from Get-Projects above)

2. What kind of input are you bringing?
   A) PRD or feature spec — I'll paste it (or share a doc link)
   B) User journey — I'll describe the flow step by step
   C) Business question — I want to answer something (e.g. "where do users drop
      off in onboarding") and need events designed around that
   D) New feature launch — short brief, want events scoped to the launch
   E) Starting Mixpanel from scratch — no specific feature, want a foundation
   F) Mix of the above

3. What's the scope?
   A specific feature, flow, or product area. Examples: "onboarding",
   "checkout funnel", "AI assistant launch", "the whole consumer app".
   Narrower scope = sharper plan. If "the whole product", I'll focus on the
   top 1–2 user journeys first.

4. What's the core question this data should answer?
   One sentence. Examples: "Why do users drop off between sign-up and first
   action?" or "Which AI features actually drive retention?" If you don't have
   one yet, I'll help derive it from your input.

5. What's your stack?
   A) Web (browser JS / React / Vue)
   B) iOS (Swift)
   C) Android (Kotlin / Java)
   D) React Native / Flutter
   E) Server-side (Node / Python / Go / Ruby / Java)
   F) Mixed — multiple surfaces sending to this project
   G) Using a CDP (Segment / RudderStack / GTM)

6. Existing Mixpanel state?
   A) Greenfield — nothing tracked yet
   B) Some events exist — want this plan to fit alongside them
   C) Migration — moving from another tool, want a clean foundation

7. Engineering owner for this work?
   Name + contact (email or Slack). I'll stamp this on every event in the plan.
```

**For CDP stacks (option G on Q5):**
> "If you're routing through a CDP, the tracking plan from this skill maps to
> your CDP source schema, not directly to SDK calls. I'll generate the event
> taxonomy and properties — you'll register them in your CDP source and let it
> forward to Mixpanel. SDK code templates won't apply; Lexicon write-back still
> does."

Continue with the workflow but skip the SDK code generation step in Phase 4A.

---

## Phase 1 — Lexicon Pull & Convention Detection

Before designing any new events, understand what already exists in this project's
Lexicon. This prevents naming drift and surfaces conventions to follow.

### 1A — Pull existing Lexicon

Use targeted `query=` based on the scope from Phase 0 Q3. Example for "checkout":
```
Get-Events
  project_id: <id>
  workspace_id: <id>
  query: "checkout"
  include_details: true
```

If greenfield (Phase 0 Q6 = A) and Lexicon is empty, skip to 1C.

If existing events overlap the scope, pull their property structure:
```
Get-Properties
  project_id: <id>
  workspace_id: <id>
  resource_type: Event
  events: ["<existing event name>"]
  include_details: true
```

### 1B — Detect naming convention

From 5+ existing event names (if available), identify the pattern:
- `Object Action` — title case, past tense (most common Mixpanel convention,
  e.g. `Order Completed`, `Page Viewed`)
- `[Feature] Action` — bracket prefix
- `snake_case_event` — older or server-side
- `camelCaseEvent` — migration artifact, avoid extending this

If conventions are mixed, flag it explicitly and ask which to standardize on
before generating any new event names. Do not silently pick one.

If no events exist, default to `Object Action` (title case, past tense) and
state this explicitly when presenting the plan.

### 1C — Greenfield foundation

If Phase 0 Q6 = A (greenfield) and the customer's input doesn't already include
a structured journey, present canonical Mixpanel templates as a starting point:

**Default (general SaaS / consumer app)**
Core: `Sign Up`, `Sign In`, `Page Viewed`
Plus: feature-specific events derived from the customer's input.

**E-commerce**
Funnel: `Product Viewed` → `Product Added` → `Checkout Started` →
`Payment Info Entered` → `Order Completed`
Plus: `Order Refunded`, `Product Searched`, `Coupon Applied`

**AI product**
Core: `Sign Up`, `Launch AI`, `AI Prompt Sent`, `AI Response Received`,
`AI Feedback Submitted`
Properties on `AI Prompt Sent`: prompt length, model used, feature context.
Properties on `AI Response Received`: response time, response length,
feedback signal if available.

Use the template as the foundation, then layer scope-specific events from the
customer's input on top. Don't replace customer input with a template — augment.

---

## Phase 2 — Translate Input to Events

This is the heart of the skill. The translation pattern depends on which input
type the customer brought (Phase 0 Q2).

The output of this phase is a **draft event list** — not the final plan. It
becomes the proposal in Phase 3.

### 2A — From a PRD or feature spec

Read the document. For each user-facing action, state change, or system event
that represents meaningful product usage, propose a candidate event. Skip:
- UI noise (every hover, scroll, micro-animation)
- Pure system events the user doesn't drive (cron jobs, internal sync)
- Things already captured by an existing event (per Phase 1A)

For each candidate, capture:
```
Event name: <following detected convention>
Trigger: <exact condition that fires this event>
Properties: <what context is needed to make this event useful>
Why it matters: <one sentence tying back to the customer's core question>
```

### 2B — From a user journey

Walk the journey step by step. For each step, propose:
- A **state-transition event** if the step represents a meaningful change
  (`Onboarding Step Completed`, `Trial Started`, `Plan Upgraded`)
- An **action event** if the user takes a discrete action
  (`Search Submitted`, `Filter Applied`, `Item Added to Cart`)

Don't track every step as a separate event by default. Group small actions
under one event with a `step_name` or `action` property when sequence is the
analytical unit. Track separately when each step has distinct downstream
analysis value.

### 2C — From a business question

Reverse-engineer from the question. Example: "Where do users drop off between
sign-up and first action?"

Required events to answer this:
1. `Sign Up Completed` — funnel entry
2. Each meaningful step between sign-up and first action
3. `First Action Completed` — funnel exit (define what "first action" means)

Then add **dimensional properties** that let the customer slice the funnel:
acquisition channel, plan type, device, region. These often live as super
properties or user properties — flag which.

State the funnel explicitly so the customer can confirm the structure before
moving on:
> "To answer 'where do users drop off between sign-up and first action', the
> funnel I'd build is: A → B → C → D. Confirm this matches how you think about
> the journey, or tell me what's missing."

### 2D — From a new feature launch brief

Three questions to answer with launch instrumentation:
1. **Adoption** — who's using the feature at all? (`Feature Activated` or first-use event)
2. **Engagement depth** — how heavily? (action events within the feature)
3. **Outcome** — does it drive the intended downstream behavior? (the metric
   the launch is supposed to move)

Propose the minimum event set to answer all three. Resist the urge to track
every interaction inside the new feature — instrumenting for analysis is not
the same as instrumenting for debugging.

### 2E — Properties: design before code

For every proposed event, list properties using these rules:

**Include:**
- Context that distinguishes meaningful slices (plan type, region, source)
- Numeric values that quantify the action (item count, price, duration)
- Categorical values that drive funnel branching (payment method, channel)

**Exclude:**
- PII — email, full name, phone, address, government IDs (flag these as
  high-risk if the customer's input shows them)
- Anything already registered as a super property (these will be on every
  event automatically — re-tracking creates conflicts)
- Internal IDs that are useless without a join (raw DB row IDs, GUIDs the
  PM team won't recognize)

**Reuse over invent:**
If a property concept already exists in Lexicon (from Phase 1A — e.g. there's
already a `plan_type` property), reuse that exact name. Don't introduce
`subscription_tier` when `plan_type` exists. Synonym drift is the slow death
of a tracking plan.

### 2F — User profile properties

Some attributes belong on the user, not on every event. Flag these separately:
- Identity attributes: `name`, `email` (for People analytics, NOT events),
  `signup_date`, `user_id`
- Slow-changing context: `plan_type`, `account_role`, `company_size`
- Acquisition: `signup_source`, `signup_campaign`, `referrer`

These get set via `mixpanel.people.set()` (or the wrapper equivalent), not
via `track()` calls. Surface them in a dedicated section of the plan.

### 2G — Super properties

Identify candidates for `mixpanel.register()` — properties that should appear
on every event after a certain point in the session:
- `plan_type` (after auth)
- `app_version` (at app init)
- `experiment_variant` (if running A/B tests)
- `device_type`, `platform` (at app init)

Surface these separately so engineering registers them once and doesn't pass
them per-event.

---

## Phase 3 — Present Plan & Confirm

Show the complete proposal before generating any code or touching Lexicon.

### Present in this order:

**🎯 The question this plan answers**
One sentence — the customer's core question from Phase 0 Q4. Sets the lens for
everything below.

**🚨 Flags requiring attention**
Mixed naming conventions, PII risks in the input, scope conflicts with existing
Lexicon. These need resolution before the plan is finalized.

**📐 Conventions for this plan**
- Naming pattern (detected from Lexicon or defaulted)
- Casing rules
- Tense rule (past tense for completed actions)

**⚡ Super properties (register once, available everywhere)**
List with type, value source, and scope.

**👤 User profile properties (people.set)**
List with type and trigger condition.

**📊 Events**
Grouped by priority (High / Medium / Low). For each event:
- Name
- Trigger
- Properties (with types and reuse-vs-new flag)
- Why it matters (tied to the core question)

**🔍 Reuse from existing Lexicon**
Events from Phase 1A that the plan leverages without modification.

### Confirm path:

> Here's the full plan. How would you like to proceed?
>
> **A)** Generate SDK code + write Lexicon — full pipeline
> **B)** Generate SDK code only — I'll handle Lexicon separately
> **C)** Lexicon write only — engineering will write the code
> **D)** Walk through events one by one — I'll approve each
> **E)** Hold here — I want to review with my team first

Do not proceed to Phase 4 until the customer responds.

---

## Phase 4 — Generate Code & Document

### 4A — SDK code templates

For each approved event, produce a placement-specific call. Match the SDK
detected in Phase 0 Q5. If the customer mentioned an analytics wrapper, use
the wrapper's call signature — never bypass it with raw SDK calls.

Skip this section entirely for CDP stacks (Phase 0 Q5 = G) — those events get
registered in the CDP source, not in SDK code.

**JavaScript (browser):**
```js
// [Event Name] — [trigger condition]
// Place in: [suggested location, e.g. components/Checkout/handleSubmit.ts]
// Owner: [name from Phase 0]
mixpanel.track('[Event Name]', {
  property_name: value,    // (string) what this represents
  another_property: value, // (number) what this represents
  // Note: plan_type is a super property — do not pass here
})
```

**Pre-output checklist (run for every event before showing it):**
- [ ] Name matches the convention from Phase 3
- [ ] Name is specific and past tense (`Checkout Completed`, not `Checkout`)
- [ ] No dynamic segment in the event name — use a property instead
- [ ] No PII in properties
- [ ] No super properties re-tracked as per-event properties
- [ ] Property names match Lexicon conventions where the concept exists
- [ ] User profile attributes use `people.set()`, not `track()`

**User profile updates:**
```js
mixpanel.people.set({
  plan_type: 'pro',          // string — subscription tier
  signup_source: 'organic',  // string — acquisition channel at signup
})
```

**Super property registration:**
```js
mixpanel.register({
  plan_type: 'pro',
  app_version: '2.4.1',
})
```

**Setup note for greenfield customers:**
If they haven't installed the SDK yet, point to `mixpanel-wizard`:
```
npx @mixpanel/mixpanel-wizard --token YOUR_TOKEN --sdk <detected-sdk>
```

### 4B — Lexicon write-back (if customer selected A or C)

Only after explicit confirmation in Phase 3. Never auto-write.

Document events (max 50 per call):
```
Bulk-Edit-Events
  project_id: <id>
  workspace_id: <id>
  events: [
    { name: "Event Name", description: "Fires when [trigger]. Used to understand [goal]." },
    { name: "Another Event", description: "..." }
  ]
  tags: { names: ["<feature-tag>", "planned"], operation: "add" }
```

Tag with `planned` (or similar) so the team can distinguish events that exist
in Lexicon as documentation from events that are firing in production. Some
teams remove the `planned` tag and add `verified` once the event is live.

Document properties (max 50 per call, same resource_type per call):
```
Bulk-Edit-Properties
  project_id: <id>
  workspace_id: <id>
  resource_type: Event
  properties: [
    { name: "property_name", description: "What value represents. Valid values: A, B, C if enum." }
  ]
  sensitive: false    # true for any PII-adjacent fields
```

Then resolve Lexicon URLs for each written event:
```
Get-Lexicon-URL
  project_id: <id>
  workspace_id: <id>
  event: "Event Name"
```

Include these URLs in the final outputs so the customer can click straight
through to verify each event in Lexicon.

### 4C — Outputs

Produce both. Markdown = engineering handoff or commit to repo. XLSX = team
tracking and implementation management.

**Markdown (`TRACKING_PLAN.md`):**

```markdown
# Tracking Plan — [Feature/Scope] — [Date]
**Project:** [name] | **Owner:** [name, contact] | **SDK:** [name] | **Convention:** [pattern]

## Question this plan answers
[One sentence from Phase 0 Q4]

## Summary
- [N] new events recommended
- [M] super properties to register
- [K] user profile properties to set

## ⚡ Super Properties (register once, applied to all subsequent events)
| Property | Type | Value Source | Scope |
|----------|------|--------------|-------|
| plan_type | string | After login / subscription change | All events post-login |

## 👤 User Profile Properties (people.set)
| Property | Type | Trigger |
|----------|------|---------|
| signup_source | string | On Sign Up Completed |

## 🚨 Flags
[Mixed conventions, PII risks, anything else from Phase 3]

## Events

### [Event Name] — [High / Medium / Low]
- **Trigger:** [exact condition]
- **Suggested location:** [file/component]
- **Owner:** [name, contact]
- **Why it matters:** [tied to the core question]
- **Properties:**
  | Property | Type | Description | Reused from Lexicon? |
  |----------|------|-------------|----------------------|
  | property_name | string | what it means | ✅ Yes / 🆕 New |
- **Lexicon URL:** [populated after write-back]

## 🔍 Reused from Lexicon
| Event Name | Notes |
|------------|-------|
| Existing Event | Plan leverages this without modification |
```

**XLSX (`tracking_plan.xlsx`) — build with openpyxl:**

Two sheets: `Tracking Plan` and `Super Properties`.

```python
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment

wb = Workbook()

# Sheet 1: Tracking Plan
ws1 = wb.active
ws1.title = "Tracking Plan"

headers = [
    "Event Name", "Trigger", "Suggested Location", "Priority", "Owner",
    "Property Name", "Property Type", "Property Description",
    "PII", "Reused from Lexicon", "Status", "Lexicon URL", "Implementation Status"
]
ws1.append(headers)
for cell in ws1[1]:
    cell.font = Font(bold=True, color="FFFFFF")
    cell.fill = PatternFill("solid", start_color="7856FF")  # Mixpanel purple
    cell.alignment = Alignment(horizontal="center", wrap_text=True)

# One row per property. Repeat Event Name in each row rather than merging cells
# (merging breaks filtering). Status: New / Reused. Implementation Status: To Do / In Progress / Done

ws1.column_dimensions['A'].width = 25
ws1.column_dimensions['B'].width = 35
ws1.column_dimensions['C'].width = 30
ws1.column_dimensions['D'].width = 12
ws1.column_dimensions['E'].width = 20

# Sheet 2: Super Properties
ws2 = wb.create_sheet("Super Properties")
super_headers = ["Property Name", "Type", "Example Value", "Value Source", "Scope", "Notes"]
ws2.append(super_headers)
for cell in ws2[1]:
    cell.font = Font(bold=True, color="FFFFFF")
    cell.fill = PatternFill("solid", start_color="7856FF")
    cell.alignment = Alignment(horizontal="center", wrap_text=True)

# Sheet 3: User Profile Properties (optional — include if any defined)
ws3 = wb.create_sheet("User Profile Properties")
profile_headers = ["Property Name", "Type", "Trigger", "Notes"]
ws3.append(profile_headers)
for cell in ws3[1]:
    cell.font = Font(bold=True, color="FFFFFF")
    cell.fill = PatternFill("solid", start_color="7856FF")
    cell.alignment = Alignment(horizontal="center", wrap_text=True)

wb.save("tracking_plan.xlsx")
# Save to /mnt/user-data/outputs/tracking_plan.xlsx in Claude.ai;
# project root in Claude Code/Cursor.
```

---

## Common Pitfalls

**Tracking too much on day one is worse than tracking too little.** A plan with
40 events that ships beats a plan with 80 events that gets argued for three
months. Resist the urge to instrument everything — start with the events that
answer the core question, layer the rest later.

**Naming debt compounds fast.** A wrong convention chosen on day one shapes
every event added for the next two years. If conventions are mixed in existing
Lexicon, force a decision before generating new names.

**Don't track PII in events.** Email, phone, full name, address, government IDs.
These belong on the user profile (and only some of those — email is fine for
identity, full name and phone often aren't). Flag any PII showing up in the
customer's input as a hard stop.

**Properties are where plans die.** Customers obsess over event names and
under-spec properties. The properties are what make the events analytically
useful. Push hard on property design in Phase 2E.

**Super properties are global — don't pass them per event.** If `plan_type` is
a super property, every `track()` call automatically gets it. Adding it as a
property on individual events creates two sources of truth and they will diverge.

**Wrappers are load-bearing.** If the customer mentions a centralized analytics
wrapper, all generated code uses it. Wrappers often contain consent checks,
environment guards, batching. Bypassing them silently breaks those guarantees.

**Greenfield ≠ no Lexicon check.** Even on a fresh project, do a Lexicon pull
in Phase 1A. If someone on another team already created events, you want to
know before adding conflicting ones.

**Focused > exhaustive.** A 10-event plan that ships and answers the question
beats a 30-event plan that sits in a doc.

---

## Error Handling

| Situation | Response |
|-----------|----------|
| `Get-Projects` fails | Hard stop — tell customer to connect Mixpanel MCP before proceeding |
| Project ID ambiguous | Show project list from `Get-Projects`; let customer confirm |
| Customer has no PRD/journey/question | Help derive a core question from their goals before proceeding |
| Stack is CDP (option G) | Skip SDK code generation; produce taxonomy-only plan and Lexicon write |
| Existing Lexicon has 100+ events | Scope with targeted `query=` per feature area; don't dump all |
| Mixed naming conventions in Lexicon | Stop and force a convention decision before generating events |
| PII appears in customer's input | Flag explicitly; refuse to add PII as event properties |
| Customer wants 30+ events on day one | Push back; recommend the 5–10 most decision-relevant for v1 |
| Customer hasn't confirmed before Lexicon write | Stop; re-present plan; require explicit go-ahead |
| `Bulk-Edit-Events` >50 events | Batch into sequential calls of ≤50 |
| MCP tool fails mid-workflow | Report failure; surface partial findings; never fabricate Lexicon state |
| workspace_id unknown | Always resolve from `Get-Projects` response before any other MCP call |
| Customer asks for code scan | Redirect to `instrumentation-planner` — that's the audit skill |
