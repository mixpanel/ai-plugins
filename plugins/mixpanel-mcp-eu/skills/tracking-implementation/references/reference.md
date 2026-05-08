# Mixpanel Implementation Reference Guide

**Purpose:** This document is consumed by an agent skill that assists Mixpanel customers in setting up or extending their analytics implementation. It provides SDK code snippets, vertical-specific event examples, identity flows, governance guidance, and detailed phase-by-phase reference content.

---

## How to Use This Document

This document supports all four modes defined in SKILL.md:

- **Quick Start mode:** Start with the **Quick Start Reference** section below for minimal SDK snippets (init + track + identify/reset). Skip to Phase 5 SDK sections only if you need advanced configuration.
- **Full Implementation mode:** Work through the phases in order. Each phase has **AGENT PROMPT** callouts (questions to ask) and **Guidance** (knowledge, best practices, code snippets).
- **Add Tracking / Audit modes:** Jump to the relevant phase sections as needed.

The agent should be conversational, not mechanical. Ask one or two questions at a time. Acknowledge the customer's answers and reflect them back before moving on. Never surface code until the customer's tech stack has been confirmed.

---

## Quick Start Reference -- Minimal SDK Snippets

Use this section in Quick Start mode to reach working code fast. Each platform has three blocks: **init**, **track**, and **identify/reset**. For the full SDK lifecycle (super properties, user profiles, advanced configuration), see the corresponding section under Phase 5.

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

## Developer Handoff Specification Template

**Purpose:** When a user goes through Quick Start or Full Implementation but doesn't have codebase access, generate this specification for a human developer to implement. This differs from AGENTS.md (which is for AI agents) in tone, completeness, and support.

**When to use:** User completed discovery and planning but cannot write code directly (no codebase access, or in a planning/PM role).

**Quality bar:** A developer should be able to implement Mixpanel tracking without asking clarifying questions.

### Filling Instructions for Agent

1. **Replace ALL [bracketed placeholders]** with actual values from the session context
2. **Use complete code** (not patterns) with real tokens, event names, and property values
3. **Include business context** explaining WHY each event matters (Value Moment, KPIs, priority)
4. **Provide step-by-step verification** with expected outcomes in Mixpanel Live View
5. **Add troubleshooting guidance** for common failure modes
6. **Estimate implementation time** (Quick Start: 2-4 hours / Full: 1-2 days)

### Template Structure

```markdown
# Mixpanel Implementation Specification

**Generated:** [current date and time]
**Project:** [company name from context]
**Mode:** [Quick Start / Full Implementation]

---

## Executive Summary

This specification contains everything a developer needs to implement Mixpanel analytics for [company name].

**Why this matters:** [1-2 sentences explaining the Value Moment and what insights this tracking will unlock. Example: "Tracking when users generate their first report is critical -- 87% of users who reach this milestone convert from trial to paid."]

**Scope:** This is a [Quick Start: minimal 2-event foundation / Full Implementation: complete production-ready setup].

**Estimated implementation time:** [Quick Start: 2-4 hours / Full Implementation: 1-2 days]

---

## 1. Technical Foundation

### Platform & SDK

**Platform:** [e.g., Next.js, React Native, Python/Django]

**Mixpanel SDK:** [specific SDK name -- e.g., mixpanel-browser, Mixpanel iOS SDK, mixpanel Python]

**SDK version:** [e.g., ^2.50.0, latest stable]

**Installation command:**
```[language]
[exact installation command -- e.g., npm install mixpanel-browser@^2.50.0]
```

**Tracking method:** [client-side / server-side / CDP]

**CDP integration:** [none / Segment / RudderStack / mParticle]
[If CDP: Add note: --  IMPORTANT: Send all Mixpanel events through [CDP name], NOT the Mixpanel SDK directly. See implementation section for correct integration pattern."]

### Project Configuration

**Mixpanel Project Token:** [actual token OR clear instruction: "Get this from Project Settings -> Project Details in the Mixpanel dashboard"]

**Token storage location:** [e.g., .env -> NEXT_PUBLIC_MIXPANEL_TOKEN, config/settings.py -> MIXPANEL_TOKEN]

**Environment setup:**
[If dev/prod split:
- Dev project token: [token or instruction]
- Prod project token: [token or instruction]
- Use environment variable to switch: [example]]

### Compliance Requirements

**Consent required:** [Yes / No]

**User base:** [EU users / California users / Global / Other]

**Consent implementation required:** [If yes, provide exact pattern:]

  **CRITICAL:** If consent is required, NO Mixpanel events may fire before user consent is granted. Violations can result in GDPR fines up to 4% of annual revenue and require data deletion requests.

[If consent required, include exact initialization pattern with opt-out defaults]

---

## 2. Business Context -- What You're Building

### The Value Moment

**[Value Moment Name]** -- [Description of what this represents]

This is the single most important user action we're tracking. When a user does this, it means [business outcome].

**How this ties to company goals:**
[List 2-3 KPIs or business metrics this enables. Example:
- OKR Q1 2026: Increase activation rate from 40% to 55%
- Board Metric: Time to Value Moment (target: <7 days)
- Product Roadmap: Report generation drives 80% of retention]

### Event Priority Ranking

Not all events are equal. If engineering time is limited, implement in this order:

1. **[Value Moment Event]** -- HIGHEST priority. This is our Value Moment and powers [specific business metric].
2. **sign_up_completed** -- HIGH priority. Essential for measuring acquisition and identity linkage.
[If Quick Start, stop here. If Full Implementation, continue with priority-ranked events 3-N]

**Rationale:** Implementing these [2 / N] events first means we can measure [key metric] by [deadline/milestone].

---

## 3. Implementation Guide

### Step 1: Install SDK

[Platform-specific installation instructions with exact commands. Include any additional dependencies or configuration files needed.]

**For [platform]:**
```[language]
[exact installation command]
```

[If multi-platform (Full Implementation), provide subsections for each]

**Verification:** After installation, you should be able to import Mixpanel:
```[language]
[import statement]
```

---

### Step 2: Initialize Mixpanel

**Where to add this code:** [specific file path if known from Pre-Flight OR description like "your app entry point (e.g., _app.tsx, main.ts, application startup)"]

[If consent required:]
**  Consent Gate:** Mixpanel must be initialized with tracking disabled by default. Only enable after user consent.

**Complete initialization code:**
```[language]
[Complete initialization code with:
- Actual token reference (not placeholder)
- Consent gate if required (opt_out_tracking_by_default: true)
- Any other required configuration
- Comments explaining each option]
```

[If consent required, add opt-in flow:]
**After user consents:**
```[language]
[opt-in code]
```

**Do NOT:**
- Initialize Mixpanel in multiple places (creates duplicate instances)
- Hardcode the project token (use environment variable)
- Skip the consent gate if serving EU/CA users

---

### Step 3: Track Events

[One subsection per event]

#### Event 1: sign_up_completed

**When to track:** After user account is successfully created in your database (not on form submit, not on button click -- wait for DB confirmation)

**Why this matters:** This event establishes user identity and measures acquisition. Without it, we cannot link anonymous browsing events to authenticated user behavior.

**Where to add this code:** [file location if known, OR description: "in your signup handler, after the database INSERT succeeds"]

**Complete implementation:**
```[language]
[Complete, ready-to-use code with:
- Actual event name
- All required properties with real field names
- Comments explaining each property
- Example showing where user data comes from]

// Example:
mixpanel.track('sign_up_completed', {
  sign_up_method: user.authProvider,    // 'email', 'google', 'github'
  platform: 'web',                       // or 'ios', 'android', etc.
  is_first_time: true                    // always true for signup
});
```

**Properties explained:**
- `sign_up_method` (string, required): How the user signed up. Possible values: [enum list]. This helps us understand which auth methods drive the highest activation.
- `platform` (string, required): Where the signup occurred. Use: 'web', 'ios', 'android'. Powers platform-specific conversion analysis.
[Continue for each property with business meaning]

**Expected data in Mixpanel:**
After implementation, you should see in Live View:
- Event name: `sign_up_completed` (exact spelling, case-sensitive)
- Properties showing realistic values (not undefined/null)
- Appears within 60 seconds of test signup
- distinct_id is a device ID (before identify()) or user ID (after identify())

---

#### Event 2: [Value Moment Event Name]

**When to track:** [Detailed trigger description with timing specifics. Example: "After the report generation completes successfully (after the file is saved, not when the user clicks 'Generate')"]

**Why this matters:** [Business explanation. Example: "This is our Value Moment. Users who generate a report within 7 days of signup have an 87% conversion rate from trial to paid. This event powers our activation funnel and Time to Value metric."]

**Where to add this code:** [file location or description]

**Complete implementation:**
```[language]
[Complete code with all properties and comments]
```

**Properties explained:**
[Each property with data type, enum values if applicable, and business meaning]

**Expected data in Mixpanel:**
[What to verify in Live View with specific expected values]

---

[Repeat for each additional event in tracking plan. For Full Implementation, this could be 10-15 events.]

---

### Step 4: Set Up Identity Management

**The Identity Contract:**

Mixpanel needs to know when an anonymous user becomes a known user (login/signup), and when users log out. This is handled through two calls: `identify()` and `reset()`.

**Why this matters:**
- **Skipping `identify()`:** Events won't link to user profiles -> cohort analysis impossible, user-level metrics broken
- **Skipping `reset()`:** Next user's events merge with previous user's data -> major privacy violation, data corruption
- **Wrong timing:** Anonymous events won't bridge to authenticated identity -> fragmented user profiles

#### On Login/Signup (after database confirms user creation)

**Where to add:** [file location for login/signup handler]

```[language]
[Complete identify() call with actual user ID field reference]
[Complete people.set() call for profile properties]

// Example:
mixpanel.identify(user.id);  // Use stable internal ID, NOT email
mixpanel.people.set({
  $name: user.name,
  $email: user.email,
  account_type: user.accountType,  // custom property
  sign_up_date: user.createdAt
});
```

**Critical:** Use your internal user ID (database primary key, UUID), NOT email addresses. Emails change; IDs don't.

#### On Session Restore (if user is already logged in)

**Where to add:** [file location for session initialization / app startup]

```[language]
[identify() call on session restore]

// If user is already authenticated on app load:
if (currentUser) {
  mixpanel.identify(currentUser.id);
}
```

#### On Logout

**Where to add:** [file location for logout handler]

```[language]
[Complete reset() call]

// Example:
mixpanel.reset();  // Clears distinct_id, generates new anonymous ID
```

**  Do not skip this.** Failing to call `reset()` on logout causes User A's events to merge with User B's profile after User B logs in on the same device. This is a privacy violation and corrupts your data.

---

## 4. Verification & Testing

### Pre-Deployment Checklist

Before considering this complete:

- [ ] SDK installed and imports work without errors
- [ ] Mixpanel initializes on app startup (check console/logs for init confirmation)
- [ ] [If consent required] Tracking is disabled until opt-in (verify no network requests to api.mixpanel.com before consent)
- [ ] Each event fires in the correct location (after action succeeds, not before)
- [ ] Identity calls placed in login, logout, and session restore handlers
- [ ] Environment variable for project token is set (not hardcoded)

### Live View Verification (Step-by-Step)

**How to test:**

1. **Open Mixpanel Live View**
   - Go to: [Mixpanel project URL if known, OR: "Mixpanel dashboard -> Project Settings -> Implementation -> Live View"]
   - Keep this tab open while testing

2. **Test Event 1: sign_up_completed**
   - In your dev/staging environment: [trigger action -- e.g., "create a new user account"]
   - Expected result in Live View (within 60 seconds):
     - Event name: `sign_up_completed` (exact spelling)
     - Properties: `sign_up_method`, `platform` with realistic values
     - distinct_id: a device ID or anonymous ID (before identify())

3. **Test Event 2: [Value Moment Event]**
   - In your dev/staging environment: [trigger action]
   - Expected result in Live View (within 60 seconds):
     - Event name: `[event_name]` (exact spelling)
     - Properties: [list expected property names and example values]
     - distinct_id: matches the user who triggered it

[Repeat for each event]

4. **Test Identity Flow**
   - Sign up -> verify distinct_id changes from device ID to user ID after identify() call
   - Check Users tab: user profile should exist with $name and $email
   - Log out -> verify reset() clears distinct_id
   - Log back in -> verify events link to same user profile (not fragmented)

**Expected results:**
- Events appear in Live View within 60 seconds
- Event names match exactly (case-sensitive)
- Properties show realistic values (no undefined/null/empty strings)
- After login, user profile appears in Users tab with correct properties
- After logout and re-login, events continue linking to same user profile

### Troubleshooting Common Issues

**Problem: Events don't appear in Live View**

Possible causes:
1. **Wrong project token** -> Verify token matches Project Settings -> Project Details
2. **Initialization failed** -> Check browser console / server logs for Mixpanel errors
3. **Event fired before init** -> Ensure mixpanel.init() runs before any track() calls
4. **Network blocked** -> Check network tab: POST to api.mixpanel.com/track should return 200
5. **Consent gate blocking** -> If opt_out_tracking_by_default is true, verify opt_in_tracking() was called

**Debug steps:**
```[language]
// Add before track() call to verify event is reached:
console.log('About to track event:', eventName, properties);
mixpanel.track(eventName, properties);
```

**Problem: Event names or properties are wrong**

Possible causes:
1. **Typo in event name** -> Event names are case-sensitive: `sign_up_completed`   `Sign_Up_Completed`
2. **Properties undefined** -> Verify property values exist at the moment track() is called
3. **Wrong data type** -> Check Mixpanel Lexicon for expected types

**Debug steps:**
- Log the full event object before sending
- Check Mixpanel Live View for actual values received
- Compare against expected schema in this spec

**Problem: Identity not linking**

Possible causes:
1. **identify() called before user exists** -> Wait for DB confirmation before calling identify()
2. **identify() called with email instead of user ID** -> Use stable internal ID
3. **reset() not called on logout** -> Next user's events merge with previous user
4. **identify() called multiple times with different IDs** -> Always call reset() first before switching users

**Debug steps:**
- Check distinct_id in Live View before and after login
- Verify user profile exists in Users tab
- Check that all events after login show same distinct_id as user ID

**Problem: Duplicate events**

Possible causes:
1. **Multiple Mixpanel instances** -> Initialize once, import singleton elsewhere
2. **Event fired in loop** -> Move track() call outside loop or use server-side batching
3. **No deduplication key** -> Add $insert_id property for server-side events

---

## 5. Naming Conventions & Standards

All future Mixpanel events MUST follow these rules to maintain data quality:

### Event Names

**Format:** `snake_case`

**Structure:** past_tense_verb + noun

**Examples:**
- ... `report_generated`, `item_added_to_cart`, `video_played`
-  `Generate Report`, `add-item`, `videoPlay`

### Property Names

**Format:** `snake_case`

**Booleans:** `is_` prefix (e.g., `is_first_time`, `is_premium`)

**No abbreviations:** Write full words
- ... `subscription_type`
-  `sub_type`

### Why Standards Matter

Inconsistent naming creates:
- Duplicate metrics (users track both `user_signup` and `sign_up_completed` for the same action)
- Broken reports (queries fail when casing changes)
- Unusable Lexicon (analysts can't find events)
- Wasted engineering time (re-instrumenting to fix naming)

**Standard now, avoid refactoring later.**

---

## 6. What NOT to Do

" **Do not introduce other analytics tools.** This project uses Mixpanel exclusively. All tracking goes through Mixpanel. Do not add Google Analytics, Amplitude, Segment (unless as CDP), or custom analytics without explicit approval.

" **Do not track PII as event properties.**

Never include in event properties:
- Email addresses
- Full names
- Phone numbers
- IP addresses
- Payment details
- Social security numbers

**Why:** PII in event properties cannot be easily deleted and may violate GDPR/CCPA.

**Instead:** Use `mixpanel.people.set()` for user profile properties (name, email). Profiles can be deleted on request.

" **Do not fire events before actions succeed.**

Track `report_generated` AFTER the report exists in your database, not when the user clicks "Generate Report."

**Why:** If you track on button click and the action fails (network error, validation failure), your metrics will be inflated with phantom events.

" **Do not skip `mixpanel.reset()` on logout.**

**Why:** Failing to reset causes User A to log out, User B to log in on the same device, and User B's events to merge with User A's profile. This is both a privacy violation and data corruption.

" **Do not call `identify()` with email addresses.**

Use stable internal user IDs (database ID, UUID).

**Why:** Emails change (user updates email, or uses multiple emails). If you identify with email, user profiles fragment.

" **Do not track events inside loops.**

Each `mixpanel.track()` call is a network request.

```[language]
//  WRONG:
items.forEach(item => {
  mixpanel.track('item_processed', { item_id: item.id });
});

// ... CORRECT:
mixpanel.track('batch_processed', {
  item_count: items.length,
  item_ids: items.map(i => i.id).join(',')
});
```

" **Do not hardcode the Mixpanel project token.**

Read it from environment config (.env, settings file).

**Why:** Hardcoded tokens get committed to git, leak in logs, and require code changes to switch environments.

---

## 7. Post-Implementation

### Documentation Requirements

After implementation is complete:

1. **Add Lexicon descriptions in Mixpanel**
   - Go to: Data Management -> Lexicon
   - For each event, add a one-sentence description: "Fired when [trigger] to measure [business outcome]"
   - For each property, add expected values and meaning

2. **Create `AGENTS.md` in your codebase**
   - This file documents Mixpanel tracking for future AI agents who work on your codebase
   - Place it in your project root
   - Use the template below

3. **[If Full Implementation] Enable governance**
   - Data Standards: Project Settings -> Data Governance -> Enable Data Standards
   - Event Approval: Project Settings -> Data Governance -> Enable Event Approval
   - Assign Data Owner role: [role/person from session context]

### AGENTS.md Template for Your Codebase

Create this file in your project root so future AI agents understand Mixpanel is the analytics tool:

```markdown
[Insert filled AGENTS.md.template content here with actual values:
- Platform, SDK, version, tracking method, CDP, consent
- Initialization file path
- Identity management file paths
- Complete tracking plan table
- Naming conventions
- Anti-patterns]
```

### Next Steps (Priority Order)

[If Quick Start:]
Now that you have basic tracking live, recommended next steps:

1. **Expand tracking plan** -- Add events for [suggestions based on Value Moment and product type]
2. **Set up funnels** -- Create funnel in Mixpanel: signup -> [setup steps] -> Value Moment
3. **Enable cohort analysis** -- Build cohorts based on Value Moment completion
4. **Dashboard creation** -- Build dashboard with: activation rate, Time to Value, weekly active users
5. **Data governance** -- Add Lexicon descriptions, enable Data Standards

[If Full Implementation:]
Now that you have complete tracking live, critical next steps:

1. **Governance setup** -- Populate Lexicon, enable Data Standards and Event Approval (see Section 3 above)
2. **Dashboard creation** -- Build dashboards for: [KPIs from session context]
3. **Alerting** -- Set up alerts for: [critical metric drops, unusual event volumes]
4. **Regular reviews** -- Schedule quarterly data quality audits with [Data Owner role]

### Schedule Follow-Up (Recommended)

After implementation, schedule a follow-up session to:
- Verify all events appearing in Live View with correct properties
- Walk through Lexicon and Data Standards setup together
- Run through the ID Management QA checklist (reference.md Section Phase 6)
- Review first 7 days of data for anomalies

---

## 8. Support Resources

**Questions or issues during implementation?**

- **Mixpanel Documentation:** https://docs.mixpanel.com
- **SDK-specific docs:** [link to relevant SDK docs based on platform]
[If CDP:] - **[CDP] + Mixpanel integration guide:** [link]
- **Mixpanel Community:** https://community.mixpanel.com

**Common questions:**

- **"How do I test without polluting production data?"** -> Use separate dev/staging project tokens, or use Mixpanel's test mode
- **"Can I send historical data?"** -> Yes, set the `time` property to a Unix timestamp
- **"How do I delete test data?"** -> Contact Mixpanel support for data deletion (cannot be done via UI)
- **"What if I need to change event names later?"** -> Use Lexicon aliases to map old names to new names (no code changes required)

---

## 9. Appendix: Full Tracking Plan Reference

[Complete table of all events with property schemas]

| Event Name | Trigger | Properties | Data Types | Required | Business Purpose |
|------------|---------|------------|------------|----------|------------------|
| sign_up_completed | User account created in DB | sign_up_method, platform, is_first_time | string, string, boolean | Yes, Yes, No | Measures acquisition, establishes identity |
| [value_moment_event] | [trigger] | [properties] | [types] | [required flags] | [business purpose] |
[... continue for all events]

### Property Enums

**sign_up_method:** 'email', 'google', 'github', 'apple', 'sso'
**platform:** 'web', 'ios', 'android', 'api'
[... continue for all enum properties]

---

**This specification was generated using the Mixpanel Implementation Skill.**

**Last updated:** [timestamp]

**Questions?** [contact info or escalation path if available]
```

---

## Phase 0 -- Pre-Implementation Discovery

> **AGENT PROMPT -- Phase 0**
>
> Ask these questions before doing anything else. Collect all answers before proceeding to Phase 1. Ask them conversationally, not as a bulleted list dump.
>
> 1. "What type of product are you building?" (e.g., SaaS, e-commerce, media/content, fintech, mobile game, marketplace, internal tool)
> 2. "What platform(s) does your product run on?" (e.g., web browser, iOS, Android, React Native, Flutter, server-side API only, or some combination)
> 3. "Do you already use a Customer Data Platform or data warehouse?" (e.g., Segment, Rudderstack, mParticle, Snowflake, BigQuery -- if yes, this changes the implementation approach significantly)
> 4. "Do you have the Group Analytics add-on on your Mixpanel plan?" (This is available on Growth and Enterprise plans. If unsure, they can check under their plan settings. This matters for B2B products that need account-level analysis.)
> 5. "What are the two or three most important business questions you're hoping Mixpanel will help you answer?" (This drives everything -- event selection, tracking plan, and KPI design.)
>
> Store these answers mentally. They gate which subsections of later phases are surfaced.

### Why Discovery Comes First

Every implementation decision downstream -- which SDK to use, which events to track, how to handle identity, whether to track at group level -- flows from the answers above. A customer who already has Segment routes events through an integration rather than writing SDK calls. A B2B SaaS customer with Group Analytics needs a different data model than a consumer app. A customer targeting EU users needs to know their data residency options before they create their project.

Rushing past discovery leads to wasted implementation effort and messy data that is expensive to fix.

---

## Phase 1 -- Analytics Strategy Before You Write Any Code

> **AGENT PROMPT -- Phase 1**
>
> Before presenting any framework, ask:
> 1. "What does success look like for your product in the next 90 days -- are you focused on user acquisition, activation, engagement, or retention?"
> 2. "What is the single most important action a user can take in your product that signals they are getting real value from it?"
>
> Use the answers to select the most relevant vertical examples below and name the customer's Value Moment specifically before moving on.

### Why Strategy Comes Before Implementation

The most common mistake new Mixpanel customers make is going straight to instrumentation -- adding `.track()` calls wherever they can -- without first deciding what they actually need to measure. This produces noisy, hard-to-use data. A week of strategic planning before writing a single line of tracking code produces years of clean, trusted analytics.

### The RAE Framework (Recommended Starting Point)

For customers new to product analytics, the **RAE Framework** is the fastest path to meaningful measurement. RAE stands for **Reach**, **Activation**, and **Engagement**.

```
Reach       -> How many users have used your product recently?
Activation  -> Are new users reaching the moment where they get value?
Engagement  -> How deeply and frequently are active users engaging?
```

These three dimensions translate directly into the events and funnels you need to build in Mixpanel. They are intentionally simple -- the goal is to identify 2--3 KPIs quickly, not to create an exhaustive metric taxonomy.

#### Reach

Reach is the total number of users who have interacted with your product in a defined time window.

- **Consumer apps:** users who opened the app in the last 30 days
- **SaaS:** users who logged in or created at least one record in the last 30 days
- **E-commerce:** users who browsed or purchased in the last 90 days

Reach sets the upper bound of who could possibly become activated or engaged. Tracking reach requires a `sign_up_completed` event and a session-start or login event.

#### Activation

Activation is the process of taking a user from sign-up to the first time they experience your product's core value proposition -- the **Aha moment**.

Activation has three stages:

| Stage | Definition | Example |
|---|---|---|
| Setup | User completes the minimum configuration needed to discover value | Created first project, connected data source |
| Aha | User experiences the core value for the first time | Generated first report, sent first message |
| Habit | User returns and experiences value again within a defined window | Used core feature 3+ times in 7 days |

The key question: **What is the minimum set of actions a user must take before they can experience value?** Those actions are your setup events. The moment value is experienced is your Aha event.

#### Engagement

Engagement measures depth of activity -- how many users are experiencing value moments, how often, and at what intensity.

A practical segmentation model:

| Tier | Definition |
|---|---|
| Power users | Perform the core value action at or above the expected natural frequency |
| Core users | Perform it somewhat less frequently but consistently |
| Casual users | Perform it rarely or sporadically |
| Dormant users | Have not performed it within the retention window |

The goal is always to move users from casual -> core -> power.

#### Engagement Strategies

- **Add use cases:** Move users to adopt additional features (e.g., Uber Rides -> Uber Eats)
- **Increase feature breadth:** Raise the percentage of features a user actively uses
- **Increase frequency:** Get users to the value action more often per time window
- **Increase intensity:** More depth per session (more time, more spend, more actions)

### Defining Value Moments

A **Value Moment** is the specific action -- at a specific natural frequency -- where a user is getting real value from your product.

**Formula:** `[Core Action] at [Natural Frequency]`

Examples by vertical:

| Vertical | Value Moment Example |
|---|---|
| SaaS / Productivity | Document created -- weekly |
| Media / Content | Article read or video watched -- daily |
| E-Commerce | Purchase completed -- monthly |
| Social / Community | Post created or message sent -- daily |
| Fintech | Transaction initiated or report reviewed -- weekly |
| Mobile Game | Game session completed -- daily |

> **AGENT PROMPT:** Once the customer answers what their most important user action is, name their Value Moment explicitly. For example: "Based on what you've told me, your Value Moment is `report_generated` -- weekly. This will be one of the first two events we track in Mixpanel."

### Crafting Metrics That Are Actually Useful

When helping the customer define their KPIs, use the **5M filter**:

| Filter | Question to Ask |
|---|---|
| **Meaningful** | Does this align with the product's core value and business strategy? |
| **Measurable** | Can it be quantified and tracked over time in Mixpanel? |
| **Manageable** | Is it within the product team's ability to influence? |
| **Movable** | Can it actually be improved through targeted product work? |
| **Time-bound** | Does it have a defined measurement window? |

Avoid:

- **Vanity metrics:** total downloads, total page views (they measure output, not value)
- **Lagging metrics only:** churn rate, total revenue (these tell you what happened, not what to do next). Pair them with leading metrics like activation rate and feature adoption rate.

### Recommended Starting KPIs (by Phase of Growth)

| Growth Stage | Focus | KPIs to Track |
|---|---|---|
| Early (pre-product-market fit) | Activation | Aha rate, time-to-value, sign-up to value conversion |
| Growth | Engagement | DAU/WAU/MAU ratio, core feature usage rate |
| Scale | Retention | D7, D30 retention; churn prediction signals |

---

## Phase 2 -- Mixpanel Project Setup

> **AGENT PROMPT -- Phase 2**
>
> 1. "Have you already created a Mixpanel account and project, or are you starting from scratch?"
> 2. "Do you have a separate development/staging environment for your product, or do you test on the same environment as production?"
>
> If they have already created a project, confirm whether Simplified ID Merge is enabled (instructions below). If they are starting fresh, walk them through the setup steps below.

### Step 1 -- Confirm Simplified ID Merge Is Enabled

Since April 2024, all newly created Mixpanel organizations default to the **Simplified ID Merge API**. This is the correct setting and the one all guidance in this document assumes.

To verify:
1. Go to **Project Settings** (gear icon, top right)
2. Select **Identity Management**
3. Confirm it is set to **Simplified API**

If it shows **Original API**, and no data has been tracked yet, switch it to Simplified before proceeding. If data has already been tracked under the Original API, do not switch without reading the migration guide.

> This setting cannot be changed after data is tracked without risk of identity fragmentation. Get it right before sending a single event.

### Step 2 -- Create Separate Development and Production Projects

**Always create at minimum two projects: one for development, one for production.**

This is non-negotiable for data hygiene. Development data contaminates production reports and is nearly impossible to remove cleanly after the fact.

To create a project:
1. Go to **Organization Settings -> Projects**
2. Click **Create Project**
3. Name it clearly: e.g., `[Product Name] - Production` and `[Product Name] - Development`
4. Choose **United States** for data storage unless there is a specific non-US compliance requirement
5. Set the **timezone** to match your primary business location (this affects all report date calculations and cannot be changed retroactively without affecting historical data)

Each project has its own **Project Token** -- a public identifier used when initializing Mixpanel SDKs. Use the development token in your dev/staging environment and the production token in your live environment. Use environment-based configuration to switch between them automatically:

```javascript
// JavaScript example -- dynamic token switching
const productionHost = 'yourdomain.com';
const devToken = 'YOUR_DEV_TOKEN';
const prodToken = 'YOUR_PROD_TOKEN';

if (window.location.hostname.toLowerCase().includes(productionHost)) {
  mixpanel.init(prodToken, { debug: false });
} else {
  mixpanel.init(devToken, { debug: true }); // debug: true logs all calls to console
}
```

### Step 3 -- Single Project vs. Multiple Production Projects

If the product runs on multiple platforms (e.g., web + iOS + Android), the default recommendation is to **send all platforms into one production project**. This enables cross-platform user journey analysis.

Use this heuristic:

| Scenario | Recommendation |
|---|---|
| Web + mobile, same product, same users | Single project |
| Completely separate products with different user bases | Separate projects |
| Same product, drastically different feature sets per platform | Single project with platform property for segmentation |

For cross-platform projects, ensure:
- Events that represent the same action across platforms use **identical event names** (capitalization matters: `purchase_completed`   `Purchase_Completed`)
- User identity is consistent across platforms (covered in Phase 6)
- A `platform` or `app_source` property is added as a super property to distinguish web vs. iOS vs. Android events

### Step 4 -- Add Team Members and Assign Roles

Mixpanel project roles and their permissions:

| Role | Can Do |
|---|---|
| **Owner** | Full access including deleting the project, dropping data in Lexicon |
| **Admin** | Full access except deleting the project; can manage users |
| **Analyst** | Can create reports, boards, and cohorts; cannot manage users or governance settings |
| **Consumer** | Can view reports and boards; cannot create or edit anything |

Assign the minimum role necessary. Engineers who only need to validate tracking data during implementation can be Analysts. Stakeholders who only view dashboards should be Consumers.

---

## Phase 3 -- Understanding the Mixpanel Data Model

> **AGENT PROMPT -- Phase 3**
>
> Before presenting the data model, check whether the customer is B2B (identified in Phase 0):
> - If they answered **yes to Group Analytics**: surface the Group Analytics section at the end of this phase.
> - If they answered **no or unsure**: skip the Group Analytics section.
>
> Ask: "Before we design your tracking plan, I want to make sure we're aligned on how Mixpanel stores data. Have you worked with an event-based analytics tool before, or is this your first time?"
>
> If yes -> give a brief orientation. If no -> do the full walkthrough below.

### The Three Core Concepts

Mixpanel's data model has exactly three building blocks. Everything else is built on top of them.

```
Events       -> What happened (immutable, timestamped)
User Profiles -> Who did it (mutable, current state)
Properties   -> Details about the what and who
```

Every event has three required fields:
- **Event Name** -- a string describing the action (`checkout_completed`)
- **Distinct ID** -- Mixpanel's identifier for the user who performed the action
- **Timestamp** -- when it happened (auto-set by SDKs; must be set manually in server-side tracking)

### Events

Events are **immutable** -- once recorded, they cannot be edited. They represent a historical snapshot of a user action at a point in time. This is intentional: it preserves the truthfulness of the record.

**What makes a good event:**
- Represents a discrete, meaningful user action
- Is named at the right level of specificity (not too broad, not too narrow -- covered in Phase 4)
- Is tied to a business question or KPI you actually care about

**What to avoid:**
- Tracking every click or page scroll just because it's possible
- Creating events for system/infrastructure actions that have no user intent attached
- Creating separate events for variations of the same action (use properties instead)

### Event Properties

Event properties are **point-in-time attributes** that describe the event as it happened. They are attached at the moment of the event and never change -- even if the same attribute has a different value later.

**Supported data types:**

| Type | Use Case | Example |
|---|---|---|
| `String` | Text categories, names, labels | `plan_type = "pro"`, `button_name = "checkout"` |
| `Numeric` | Quantities, prices, scores | `price = 29.99`, `items_in_cart = 3` |
| `Boolean` | Binary flags | `is_first_purchase = true` |
| `Date` | ISO 8601 datetime strings | `delivery_date = "2026-03-15T00:00:00"` |
| `List` | Arrays of values | `tags = ["mobile", "checkout", "upsell"]` |
| `Object` | Nested key-value pairs | `experiments = {"onboarding_v2": "control"}` |
| `List of Objects` | Arrays of structured items | `cart_items = [{"name": "Shirt", "price": 29.99}]` |

**Max 255 properties per event.** Soft limit of 5,000 distinct event names in a project -- stay well under this by being intentional about what you track.

**Important:** Property data types are inferred from the values sent. If you send `price = "29.99"` (quoted), Mixpanel treats it as a String and you cannot aggregate it numerically. Always send numeric values without quotes.

### User Profiles

User Profiles are **mutable** -- they represent the user's current state and can be updated at any time. They are stored in a separate table from events and joined at query time via the Distinct ID.

**Key implications:**
- All events join to the **latest** state of a User Profile. If a user upgrades from Free to Pro, their historical events will now appear associated with a Pro user in reports. If you need to analyze behavior relative to the plan the user was on *at the time*, track `plan_type` as an **event property** too.
- User Profiles join retroactively. You can start tracking events before you set up profiles -- they'll join correctly as long as the Distinct ID matches.
- **Only create profiles for identified (logged-in) users.** Anonymous users should not have profiles. Wait until after `.identify()` is called.

**Reserved user profile property names** (use these for standard attributes so Mixpanel's UI displays them correctly):

| Property | Meaning |
|---|---|
| `$name` | Full name |
| `$email` | Email address (also used for cohort syncs) |
| `$phone` | Phone number |
| `$avatar` | URL to profile image |
| `$created` | Account creation timestamp |

### Super / Global Properties

Super properties are event properties that are **automatically attached to every event** you send, without having to pass them manually each time. Set them once at initialization or on login.

Use super properties for context that applies to all or almost all events:

- `app_version`
- `platform` (web / ios / android)
- `user_id` (for troubleshooting)
- `plan_type` (current plan at time of event)
- `experiment_group` (for A/B test context)

Super properties are stored in browser local storage (or device storage on mobile) and persist across sessions. Update them when the underlying value changes (e.g., after a plan upgrade).

### Default vs. Reserved Properties

**Default Properties** are automatically collected by Mixpanel's client-side SDKs. You do not need to instrument them:

- `$city`, `$region`, `$country_code`
- `$browser`, `$browser_version`
- `$os`, `$os_version`
- `$device`
- `$screen_height`, `$screen_width`
- `$referrer`, `$referring_domain`
- UTM parameters (`utm_source`, `utm_medium`, `utm_campaign`, `utm_content`, `utm_term`)
- `mp_lib` (which SDK was used)

> Note: Default properties are **only** auto-collected by client-side SDKs. Server-side implementations must parse and attach them manually (covered in Phase 5).

**Reserved Properties** are property names Mixpanel uses for special system functions. Some are auto-populated; some must be set manually. **Avoid naming your own properties with `$` or `mp_` prefixes.**

Common reserved properties to know:
- `$distinct_id` -- the user identifier
- `time` -- event timestamp (auto-set by client SDKs; must be set in Unix seconds for server-side)
- `$insert_id` -- deduplication key (set this on server-side events to prevent duplicate ingestion)
- `$email`, `$name`, `$phone` -- on user profiles only

### Group Analytics (B2B / Account-Level Analysis)

> **Surface this section only if the customer confirmed Group Analytics in Phase 0.**

Group Analytics allows you to analyze behavior at a **group level** (e.g., company, account, team) in addition to the individual user level. It is essential for B2B products where one account contains many users and you need to answer questions like "Which accounts have the highest feature adoption?" or "What is the churn risk of accounts in this segment?"

**Core concepts:**

| Concept | Definition |
|---|---|
| **Group Key** | The event property you designate as the group identifier (e.g., `company_id`) |
| **Group ID** | The specific value of that property for a given group (e.g., `"acme-corp"`) |
| **Group Profile** | Like a User Profile, but for a group -- stores group-level attributes (industry, plan, seat count) |

**How it works:**

1. Add the Group Key property (e.g., `company_id`) to every event
2. Set Group Profiles with group-level attributes
3. Mixpanel can then aggregate events across all users who share the same `company_id`

**System limits:**
- 1 million Group Profiles per Group Key
- 1 million events per day per Group ID

```javascript
// JavaScript -- Set group on a user (links user to group)
mixpanel.set_group("company_id", "acme-corp");

// Set Group Profile properties
mixpanel.get_group("company_id", "acme-corp").set({
  "company_name": "Acme Corp",
  "industry": "Manufacturing",
  "plan": "enterprise",
  "seat_count": 45
});

// Track event with group context (group property auto-attached after set_group)
mixpanel.track("Report Generated", {
  "report_type": "revenue",
  "company_id": "acme-corp"
});
```

---

## Phase 4 -- Building the Tracking Plan

> **AGENT PROMPT -- Phase 4**
>
> Before starting the tracking plan, ask:
> 1. "Do you have any existing screen flows, user journey maps, or wireframes in a tool like Figma, Miro, or Notion? If so, sharing them would help me guide you through translating them into events."
> 2. "What are the top 3 user actions in your product that, if a user does them, you'd say they're getting real value?"
>
> Use their answers to name specific events in the tracking plan template walkthrough below. Make it concrete to their product, not generic.
>
> At the end of this phase, direct the customer to copy the appropriate Mixpanel Tracking Plan template for their vertical and begin filling it in together.

### Start With Exactly Two Events

Before designing a comprehensive tracking plan, start with just two events. This gets data flowing quickly and builds momentum.

**Event 1: `sign_up_completed`** (or equivalent onboarding completion event)
- Answers: "How many new users am I acquiring per day/week/month?"
- Recommended properties: `sign_up_method` (email/google/apple), `referral_source`, `platform`

**Event 2: Your Value Moment** (identified in Phase 1)
- Answers: "How many users are experiencing value in my product? Are they coming back for it?"
- Properties depend on the value moment -- see the table below

Once these two events are live and data is flowing, iterate to add more.

### Tracking Plan Methodology

Follow this sequence -- do not jump to writing code without completing each step:

```
Step 1: Define KPIs          -> What does success look like? (Phase 1 output)
Step 2: Map KPIs to Flows    -> What user journeys drive each KPI?
Step 3: Flows -> Events       -> What are the discrete actions within each journey?
Step 4: Events -> Properties  -> What context do you need to analyze each action?
Step 5: Identify Globals     -> Which properties appear on almost every event? (' super properties)
Step 6: Identify Profiles    -> What attributes describe the user, not the action? (' user properties)
Step 7: Document             -> Write it all into the tracking plan template before implementation
```

### Choosing the Right Event Granularity

This is the most common design mistake: events that are either **too broad** or **too specific**.

**Too Broad -- avoid:**
```
Button Clicked        -> tells you nothing about which button or why it matters
Page Viewed           -> acceptable, but only if paired with a page_name property
Item Interacted With  -> too vague to analyze
```

**Too Specific -- avoid:**
```
Add Shirt to Cart     -> create one "Add to Cart" event with item_type property instead
Clicked Blue Button   -> irrelevant; the color is not a business question
Searched for "Nike"   -> create one "Search Performed" event with query property
```

**Right level of granularity -- aim for:**
```
add_to_cart            -> with properties: item_name, item_category, item_price, quantity
search_performed       -> with properties: query, result_count, filters_applied
checkout_completed     -> with properties: order_total, item_count, payment_method, coupon_used
```

**The test:** Can you answer your top business questions using this event + its properties, without needing to create a dozen filter conditions? If yes, the granularity is right.

### Naming Conventions (Non-Negotiable)

**Mixpanel is case-sensitive.** `sign_up_completed`, `Sign_Up_Completed`, and `SignUpCompleted` are three different events.

Adopt **snake_case** for everything -- event names, property names, and property values -- and enforce it from day one. Mixing conventions makes data impossible to use reliably.

**Event name format:** `object_verb` (noun first, then action)

```
... sign_up_completed
... checkout_initiated
... video_played
... report_generated
... account_deleted

 SignupCompleted     (wrong case format)
 completed_sign_up   (verb first -- inconsistent with other events)
 btn_checkout_click  (abbreviations, platform-specific jargon)
 $purchase           (reserved prefix)
 mp_checkout         (reserved prefix)
```

**Property name format:** `snake_case`, descriptive, no abbreviations

```
... payment_method
... item_category
... plan_type
... is_first_purchase

 pmtMethod          (camelCase, abbreviation)
 cat                 (unclear abbreviation)
 $plan               (reserved prefix)
```

**Property value format:** lowercase strings, consistent across all events

```
... plan_type = "free" | "pro" | "enterprise"
 plan_type = "Free" | "PRO" | "Enterprise"   (inconsistent casing -> three separate values in Mixpanel)
```

### Avoid Dynamic Event or Property Names

Never construct event names or property names dynamically at runtime.

```javascript
//  BAD -- creates thousands of unique event names
mixpanel.track(`Purchase_${itemName}_${date}`);

// ... GOOD -- one event, properties carry the variation
mixpanel.track("purchase_completed", {
  item_name: itemName,
  purchase_date: date
});
```

Mixpanel has a soft limit of 5,000 distinct event names. Exceeding it causes indexing failures and UI degradation.

### Handling Null and Unavailable Values

Do not send null, empty string, `"N/A"`, or `"-"` as property values. If a property is not applicable for a given event, **omit the property entirely** rather than sending an empty value.

```javascript
//  BAD
mixpanel.track("checkout_completed", {
  coupon_code: null,
  gift_wrap: ""
});

// ... GOOD -- only send properties that have real values
const props = {
  order_total: 49.99,
  item_count: 2,
  payment_method: "credit_card"
};
if (couponApplied) props.coupon_code = couponCode;
if (giftWrapSelected) props.gift_wrap = true;
mixpanel.track("checkout_completed", props);
```

### Adding Events to an Existing Project (Extending the Tracking Plan)

When adding new events to a project that already has tracking (e.g. after greenfield rollout or in Focused Remediation), check existing schema first so new events don't fragment naming or duplicate semantics.

**Before designing a new event:**

1. **Check for similar events** -- In Lexicon or the project's event list, search for events that might already represent this action. If a similar event exists, consider extending it with a new property rather than creating a new event (e.g. add `checkout_surface` to `checkout_completed` instead of creating `checkout_completed_mobile`).
2. **Reuse property names** -- Look at properties on related events. If `plan_type`, `payment_method`, or `referral_source` already exist with consistent naming, use those exact names. Do not introduce `planType`, `subscription_type`, or other variants.
3. **Reuse enum-like values** -- For properties that have established value sets (e.g. `plan_type` = "free" | "pro"), match existing values. Check Lexicon or Reports for current property values so new tracking doesn't create duplicate value variants (e.g. "Free" vs "free").
4. **Match naming conventions** -- The project may use a consistent style (e.g. `snake_case` event names, bracket-prefix, or title case). Match whatever convention is already in use so new events don't stand out as inconsistent.

If you have access to tools that query the project (e.g. list events by keyword, list property names for an event, list property values), use them to ground the design. Otherwise, direct the customer to Lexicon and Reports to list existing events and property names for the relevant domain before finalizing the new event spec.

### Vertical-Specific Event Examples

Use the customer's vertical (from Phase 0) to make recommendations concrete:

**SaaS**
```
sign_up_completed        plan_type, sign_up_method, referral_source
onboarding_step_completed step_name, step_number, time_spent_seconds
project_created          project_type, template_used
invite_sent              invitee_role, invite_method
feature_used             feature_name, surface, plan_type
subscription_upgraded    from_plan, to_plan, trigger_surface
```

**E-Commerce**
```
sign_up_completed        sign_up_method, referral_source
product_viewed           product_id, product_name, category, price
add_to_cart              product_id, product_name, category, price, quantity
checkout_initiated       cart_total, item_count
checkout_completed       order_id, order_total, item_count, payment_method, is_first_purchase
review_submitted         product_id, rating, has_text_review
```

**Media / Content**
```
sign_up_completed        sign_up_method, referral_source, content_viewed_before_signup
content_viewed           content_id, content_type, category, author
content_completed        content_id, content_type, completion_percentage, duration_seconds
content_shared           content_id, share_method, destination_platform
subscription_started     plan_type, trial_started
```

**Fintech**
```
sign_up_completed        sign_up_method, referral_source
account_linked           account_type, institution_name
transaction_viewed       transaction_id, transaction_type, amount
report_generated         report_type, date_range, export_format
alert_set                alert_type, threshold_amount
```

### Tracking Plan Templates

Direct the customer to copy the appropriate Mixpanel template and begin filling it in:

- [SaaS Template](https://docs.google.com/spreadsheets/d/1A5wm5MKzRfSOZfUfCAg8YpePiz8Jn3Ar_u8KBo5lD6g/#gid=1641519238)
- [Retail & E-Commerce Template](https://docs.google.com/spreadsheets/d/1Kyys37m_GEL79_1BKKEnU5KxK91NF04kY-L_bFfcfqE/#gid=1641519238)
- [Media & Entertainment Template](https://docs.google.com/spreadsheets/d/1K9t53kJJjaBG36kCIbZn_qKjXR9Iy306zYZAqDrv_AM/#gid=1641519238)
- [Financial Services Template](https://docs.google.com/spreadsheets/d/1oGv6vbIFiYbima9IX4ItpBJvuChs-zzh83MRt_dSPgg/#gid=1641519238)
- [Blank Template](https://docs.google.com/spreadsheets/d/1ZdOZ6TMtRPxy7qRxiLsvH9HWcHJM6nZydWKoThRxFKc/edit#gid=1641519238)

The tracking plan should document: event name, trigger (what user action causes it), all properties and their data types, which properties are super properties or user properties, and the owning team member.

**The tracking plan must be reviewed and signed off by product, engineering, and analytics stakeholders before any implementation begins.** Implementation without a reviewed tracking plan produces data no one trusts.

---

## Phase 5 -- Choosing a Tracking Method and Implementation

> **AGENT PROMPT -- Phase 5**
>
> Refer back to Phase 0 answers:
> - If the customer is already using a **CDP** (Segment, Rudderstack, mParticle): direct them to the Integration section at the bottom of this phase. They should route events through their existing CDP rather than adding a second SDK.
> - If the customer is using a **data warehouse** (Snowflake, BigQuery): direct them to the Warehouse Connectors section.
> - Otherwise, ask: "For your primary platform -- [platform from Phase 0] -- do you want to track events from the server (backend), the browser/app (client), or both?"
>
> Then surface only the relevant SDK subsection(s) below.

### Tracking Method Decision Guide

The choice of tracking method has a permanent impact on data quality. Make the right choice before writing the first event call.

**Primary recommendation: Track from your server wherever possible.**

Client-side tracking on web loses between 15--30% of events due to ad blockers and browser tracking protection. Server-side tracking is always reliable.

| Method | When to Use | Tradeoffs |
|---|---|---|
| **Server-side** | Any event you can observe on your backend (sign-ups, purchases, API calls, subscriptions) | Cannot automatically track anonymous users; must manage IDs manually; must parse User-Agent manually |
| **Client-side (Web JS)** | Anonymous browsing behavior before login; UI interactions not reflected in backend calls; session replay | Susceptible to ad blockers (use a proxy to mitigate); harder to fix mistakes post-deployment |
| **Client-side (Mobile)** | Native iOS / Android / React Native / Flutter apps | Old app versions persist on devices; hard to fix bugs quickly; must synchronize with server-side identity |
| **CDP Integration** | Already have Segment, Rudderstack, or mParticle | No new SDK; route through integration; may have a data delay depending on CDP plan |
| **Warehouse Connector** | Already have clean event data in Snowflake or BigQuery | Best for historical backfills or when all data lives in the warehouse |

### Server-Side Best Practice: Additional Properties

Server-side SDKs do not auto-collect the browser/device/geolocation properties that client-side SDKs collect. Add them manually:

```python
# Python example -- parse User-Agent and forward client IP
from ua_parser import user_agent_parser

def enrich_event_properties(request, properties):
    parsed = user_agent_parser.Parse(request.headers.get("User-Agent", ""))
    properties.update({
        "$browser": parsed["user_agent"]["family"],
        "$os": parsed["os"]["family"],
        "$device": parsed["device"]["family"],
        "ip": request.remote_addr  # Mixpanel uses this for geolocation
    })
    # Parse UTM parameters from query string
    utm_keys = ["utm_source", "utm_medium", "utm_campaign", "utm_content", "utm_term"]
    for key in utm_keys:
        if key in request.args:
            properties[key] = request.args[key]
    # Parse referrer
    if "Referer" in request.headers:
        properties["$referrer"] = request.headers["Referer"]
    return properties
```

---

### SDK Implementation Guide

Infer the SDK from the project's language and framework. Do not ask the customer -- detect from file extensions and dependency files.

| Signal | SDK |
|--------|-----|
| `package.json` with `mixpanel-browser` | JavaScript (browser) |
| `package.json` with `mixpanel` (no `-browser`) | Node.js (server) |
| `requirements.txt` or `pyproject.toml` with `mixpanel` | Python (server) |
| `Package.swift` or `.xcodeproj` | iOS (Swift) |
| `build.gradle` or `AndroidManifest.xml` | Android (Kotlin/Java) |
| `pubspec.yaml` with `mixpanel` | Flutter |
| No client project, only server files | Use server SDK for the detected language |

Each subsection below covers the full implementation lifecycle for one SDK: **install -> init -> track event -> super properties -> user profile -> identify -> reset**.

**Token substitution:** When surfacing any code snippet below, replace `'YOUR_PROJECT_TOKEN'` with the real project tokens collected in Phase 2. Use the dev token in dev initialization blocks and the prod token in production initialization blocks. Never output the placeholder literal if real tokens are already in hand.

### Post-Deploy Verification

After deploying a new event (or batch), verify it is flowing correctly beyond a single Live View sighting:

1. **Confirm the event in Reports** -- In the dev project, run an Insights or Segmentation report filtered by the exact event name and a date range that includes the deploy (e.g. today). Zero results usually mean the event is not firing, or there is a typo or casing mismatch (Mixpanel event names are case-sensitive).
2. **Validate property values** -- In Lexicon or Reports, check that key properties on the event are populating with expected values. If a property is missing or shows unexpected values, the trigger or property names may be wrong (property names are also case-sensitive).

If you have access to a segmentation or query tool (e.g. Run-Segmentation-Query, Get-Property-Values), use it to confirm event volume and property value distribution. Otherwise, direct the customer to Mixpanel Reports and Lexicon to run these checks.

---

#### JavaScript (Browser)

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
  track_pageview: true,     // auto-tracks Page View on every navigation
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

#### Python (Server-Side)

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

#### Node.js (Server-Side)

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

#### React Native

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

#### iOS (Swift)

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

#### Android (Kotlin)

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

#### Flutter

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

#### HTTP API (Language-Agnostic)

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
|---|---|
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

### Consent and Opt-In Tracking

> **Surface this section only if EU or California users were confirmed in Phase 2.**

Client-side analytics in the EU (GDPR) and California (CCPA) require user consent before any tracking begins. Mixpanel's SDKs provide built-in opt-in and opt-out APIs to handle this.

**Recommended pattern -- opt out by default, opt in after consent:**

```javascript
// Initialize with tracking disabled by default
mixpanel.init('YOUR_PROJECT_TOKEN', {
  opt_out_tracking_by_default: true,
  debug: process.env.NODE_ENV !== 'production'
});

// After user accepts consent (e.g., on cookie banner confirmation)
function onConsentAccepted() {
  mixpanel.opt_in_tracking();
  // Now safe to call mixpanel.identify() and mixpanel.track()
}

// If user declines or withdraws consent
function onConsentDeclined() {
  mixpanel.opt_out_tracking();
}

// Check consent state before firing events programmatically
if (mixpanel.has_opted_in_tracking()) {
  mixpanel.track('checkout_completed', { /* ... */ });
}
```

**Key APIs:**

| API | Effect |
|---|---|
| `mixpanel.opt_in_tracking()` | Enables tracking for this user. Persists in local storage. |
| `mixpanel.opt_out_tracking()` | Disables tracking and clears stored user data. |
| `mixpanel.has_opted_in_tracking()` | Returns `true` if user has opted in. Use to gate manual track calls. |
| `mixpanel.has_opted_out_tracking()` | Returns `true` if user has opted out. |
| `opt_out_tracking_by_default: true` | Init option -- starts all new users as opted-out until they explicitly consent. |

**Important notes:**
- Call `opt_in_tracking()` only after the user explicitly accepts -- not after they simply dismiss the banner
- Use `mixpanel.people.delete_user()` if a user requests deletion under GDPR Article 17
- Server-side tracking does not use these APIs -- consent must be managed at the application layer. Only call `mp.track()` for users who have given consent; store consent state in your database and check it before every tracking call.
- The `opt_out_tracking_by_default` pattern works for client-side SDKs (JavaScript, iOS, Android, React Native, Flutter). For pure server-side implementations, skip this and manage consent in your own user record.

---

### Integration Pointers (CDP / Existing Infrastructure)

#### Segment

If the customer already uses Segment, direct them to install the **Mixpanel (Actions)** destination in the Segment UI. No additional Mixpanel SDK installation is needed.

- [Segment -> Mixpanel Actions Docs](https://segment.com/docs/connections/destinations/catalog/actions-mixpanel/)
- Map Segment's `track()` calls to Mixpanel events
- Map Segment's `identify()` calls to Mixpanel user profiles
- Ensure `userId` in Segment maps to the same identifier used as `distinct_id` in Mixpanel

#### Rudderstack

- [Rudderstack -> Mixpanel Destination](https://rudderstack.com/integration/mixpanel/)
- Same principle as Segment: existing `track` / `identify` / `group` calls route to Mixpanel

#### Google Tag Manager

- Use the [Mixpanel GTM Template](https://github.com/mixpanel/mixpanel-gtm-template) from the Mixpanel GitHub
- Events configured in GTM fire Mixpanel track calls without modifying application code
- Best for marketing/growth teams that own tagging independently of engineering

#### Warehouse Connectors (Snowflake / BigQuery)

For customers whose event data already lives in a cloud data warehouse:
- Navigate to **Project Settings -> Warehouse Connectors**
- Connect the warehouse, specify the events table schema, and configure a sync schedule
- Mixpanel reads directly from the warehouse -- no SDK instrumentation needed for historical data
- Useful for backfilling historical data or when the engineering team prefers keeping all tracking logic in the warehouse

---

## Phase 6 -- Identity Management

> **AGENT PROMPT -- Phase 6**
>
> Ask:
> 1. "Does your product have anonymous browsing before login, or do users authenticate immediately?"
> 2. "Do your users access your product on multiple devices or platforms?"
>
> If anonymous browsing exists or multi-device usage is likely, this phase is critical and must be covered in full. If users always authenticate immediately (e.g., an internal tool with SSO), the anonymous identity bridging section can be skipped.

### Why Identity Management Is the Highest-Risk Step

Poor identity management is the most common cause of corrupted Mixpanel data. It results in:

- Duplicate user profiles (one anonymous, one identified -- showing as two different users)
- Broken funnel analysis (pre-login events not associated with the conversion)
- Inflated user counts
- Lost pre-signup attribution (impossible to know which marketing channel drove the signup)

Get this right before going to production. It is very difficult to fix retroactively.

### The Simplified ID Merge API

Mixpanel uses two identifiers to stitch user sessions together:

| Identifier | What It Is |
|---|---|
| `$device_id` | An anonymous ID assigned to a device or browser session. Auto-generated by client SDKs. Must be generated manually in server-side tracking. |
| `$user_id` | The authenticated identifier -- your database user ID. Set by calling `.identify()`. |

When an event contains **both** `$device_id` and `$user_id` for the first time, Mixpanel creates an identity cluster merging the two. All past and future events associated with either ID are now attributed to the same user, with `$user_id` as the canonical `distinct_id`.

### Client-Side Identity Flow

**The three required calls:**

```
1. On login or signup   -> mixpanel.identify(user.id)
2. On app re-open       -> mixpanel.identify(user.id)  (if user is already logged in)
3. On logout            -> mixpanel.reset()
```

**Full example flow:**

```javascript
// Anonymous browsing -- SDK auto-generates and persists $device_id
mixpanel.track('pricing_page_viewed', { page: '/pricing' });
mixpanel.track('trial_cta_clicked', { cta_location: 'hero' });

// User signs up
async function handleSignup(user) {
  await createUserInDatabase(user);

  // 1. Identify -- links $device_id to $user_id
  mixpanel.identify(user.id);

  // 2. Set profile properties
  mixpanel.people.set({
    $name: user.fullName,
    $email: user.email,
    $created: new Date().toISOString(),
    plan_type: 'free'
  });
  mixpanel.people.set_once({
    first_sign_up_date: new Date().toISOString(),
    acquisition_source: utmSource
  });

  // 3. Update super properties
  mixpanel.register({ plan_type: 'free', user_id: user.id });

  // 4. Track the signup event (comes AFTER identify so it's attributed correctly)
  mixpanel.track('sign_up_completed', {
    sign_up_method: user.authMethod,
    referral_source: utmSource
  });
}

// User logs out
function handleLogout() {
  mixpanel.track('session_ended');
  mixpanel.reset();  // clears storage, generates new $device_id
}

// App re-opens / page re-loads while user is logged in
function onAppLoad() {
  if (currentUser) {
    mixpanel.identify(currentUser.id);  // re-establishes the link
    mixpanel.register({ plan_type: currentUser.plan });
  }
}
```

### Server-Side Identity Flow

Server-side SDKs do not auto-generate `$device_id`. You must manage it yourself.

```python
import uuid

def get_or_create_anonymous_id(request):
    """Generate a UUID and store it in a cookie for the user's session."""
    anon_id = request.cookies.get('mp_device_id')
    if not anon_id:
        anon_id = str(uuid.uuid4())
    return anon_id

def track_to_mp(request, event_name, properties):
    anon_id = get_or_create_anonymous_id(request)
    properties['$device_id'] = anon_id

    # If user is authenticated, add $user_id to enable ID merge
    if request.user.is_authenticated:
        properties['$user_id'] = str(request.user.id)

    # Pass empty string as distinct_id -- Mixpanel will determine it from $device_id/$user_id
    mp.track('', event_name, properties)

# Set the cookie in your response
def set_anonymous_id_cookie(response, anon_id):
    response.set_cookie('mp_device_id', anon_id, max_age=60*60*24*365, httponly=True, samesite='Lax')
```

### Critical Rules

| Rule | Reason |
|---|---|
| Always call `.identify(user.id)` on **every** login and app re-open while logged in | Ensures every session is correctly attributed to the identified user |
| Always call `.reset()` on logout | Prevents sessions from different users on the same device being merged |
| Never call `.identify()` with an email address | Emails change; if they do, you get a new user in Mixpanel with no history |
| Never merge two `$user_id` values | Not supported in Simplified API -- use a single stable database ID from the start |
| Do not create User Profiles for anonymous users | Wasted profile slots; profiles don't carry over when identity is linked |
| Always use your database primary key as `$user_id` | Stable, unique, never reassigned |

### Identity Checklist (Quick Validation)

Before moving on, confirm:

- [ ] `identify(userId)` has been called earlier in the session (on login/signup) -- not only on the current action
- [ ] User profile attributes are set via `people.set()` (or equivalent), not via `track()` -- event properties describe the action; profile properties describe the user
- [ ] `identify()` is called once per session when the user is already logged in (e.g. on app re-open), not on every page load without need
- [ ] The identifier used for `$user_id` is a stable unique ID (e.g. database primary key), not email and not device ID

### ID Management QA Checklist

Before going to production, verify:

- [ ] Anonymous events (pre-login) appear in the user's event history after they log in
- [ ] Signing up on web and then logging in on mobile creates **one** user profile, not two
- [ ] Logging out creates a new anonymous session -- the next user on the same device does not inherit the previous user's identity
- [ ] User profile properties are set **after** `.identify()` is called, not before
- [ ] `.identify()` is called on every app re-open / page reload when the user is already logged in
- [ ] No duplicate profiles appear after a round-trip of: anonymous browsing -> signup -> logout -> login on a new device

---

## Phase 7 -- Data Governance from Day One

> **AGENT PROMPT -- Phase 7**
>
> Ask:
> 1. "Who on your team will be responsible for making sure event names and properties stay consistent over time -- a data engineer, a product manager, an analyst, or all three?"
> 2. "Do you have a shared internal wiki or document store (Notion, Confluence, Google Drive) where your team would keep a tracking plan and governance documentation?"
>
> Use their answers to frame ownership and tooling recommendations below.

### Why Governance Starts at Launch, Not Later

The impulse is to treat governance as a future problem -- something to set up once the product is bigger and the team is larger. This is backwards. Every event name you ship without a description, every property added without a convention review, every duplicate event created because two engineers didn't check the tracking plan first -- these accumulate into a state that becomes expensive and disruptive to clean up.

Start with governance structures in place on day one. It takes one hour of setup and saves weeks of cleanup.

### The Governance Framework

Mixpanel's recommended governance model has five components:

1. **Ownership** -- who is responsible for data quality
2. **Taxonomy** -- a shared vocabulary for events and properties
3. **Change management** -- how naming changes are handled without breaking reports
4. **Continuous maintenance** -- ongoing review cycles
5. **Documentation and training** -- keeping the whole team aligned

### Governance Roles

Assign these roles before implementation begins:

| Role | Responsibilities |
|---|---|
| **Data Owner** | Approves new events before they go live; ensures correctness and alignment with KPIs |
| **Analyst / PM** | Documents use cases for each event; verifies that implemented events match the tracking plan |
| **Engineer** | Implements tracking only for events that have been reviewed and approved |
| **Data Governor** | Oversees Lexicon; enforces naming standards; runs quarterly reviews |

In small teams, one person may hold multiple roles. The critical thing is that the roles and their responsibilities are **explicitly named** -- not assumed.

### Setting Up Lexicon from Day One

**Lexicon** is Mixpanel's data dictionary. It is the source of truth for what every event and property means.

Navigate to: **Data Management (top nav) -> Lexicon**

For every event you ship, immediately add to Lexicon using this structured checklist:

**Per event:**
| Field | Purpose |
|-------|---------|
| **Description** | One sentence: what triggers the event and what it represents |
| **Verified** | Mark as verified once the event has been confirmed in Live View or Reports |
| **Owner / contact** | Team or email responsible for this event |
| **Tags** | Team or domain tags (e.g. `onboarding`, `payments`, `mobile`) |
| **Example property values** | At least one example value for each property (for analyst reference) |

**Per property (for each event):**
| Field | Purpose |
|-------|---------|
| **Description** | What the value represents; if enum-like, list valid values |
| **Sensitive** | Set to true if the property contains PII or other sensitive data (so it can be restricted in exports or reports) |

Example Lexicon description for `checkout_completed`:
> "Fires when a user successfully completes a purchase and the order is confirmed. Includes the order total, item count, payment method, and whether this is the user's first purchase. Triggered server-side by the order confirmation webhook."

Descriptions in Lexicon are visible to everyone on the team and appear directly in the report builder. They prevent the constant "what does this event mean?" questions that slow down analysis.

### Data Standards Enforcement

Mixpanel's **Data Standards** feature lets you define formatting rules that all new events and properties must meet before being accepted.

Enable and configure at: **Project Settings -> Data Standards**

Recommended rules to set:
- All event names must use `snake_case`
- All event names must have a description before they appear in reports
- All property names must use `snake_case`

### Event Approval

**Event Approval** prevents unreviewed tracking calls from appearing in your Mixpanel project. When enabled, any event name not on the approved list is held in a pending queue until a Data Owner approves or rejects it.

Enable at: **Project Settings -> Event Approval**

Workflow:
1. Engineer adds a new event to the tracking plan
2. Data Owner reviews and approves the event name in Mixpanel
3. Event begins appearing in reports once approved

This prevents "accidental" events -- test events, typos, or undocumented tracking -- from polluting your data.

### Hiding vs. Dropping Data

As your product evolves, you will accumulate events and properties that are no longer useful. Use Lexicon to manage them:

| Action | Effect | When to Use |
|---|---|---|
| **Hide** | Event/property no longer appears in dropdowns but data is still stored and queryable | Use for deprecated events you may still need to reference historically |
| **Drop** | Stops ingesting new data for this event/property (existing data remains) | Use for events you are certain you will never need again; **cannot be undone** |

> Never drop data impulsively. Hide it first, observe for one quarter, then drop if it is never queried.

### Merging Divergent Events

If two events represent the same user action but have different names (e.g., web team sent `Purchase` and mobile team sent `purchase_item`), use **Lexicon -> Merge** to unify them into a single event for reporting.

Merging does not modify raw data -- it creates a logical alias. Reports that reference either event will now show combined data.

Steps:
1. In Lexicon, select both events
2. Click **Merge**
3. Choose which event name is the canonical one going forward
4. Update all future tracking to use the canonical name

### Managing Naming Changes

When you need to rename a raw event (not just the display name), treat it as a breaking change:

1. **Communicate first** -- notify all affected teams (product, analytics, engineering) before implementing
2. **Use merge** in Lexicon to maintain continuity between old and new names in reports
3. **Update dashboards** to reference the new name after the merge
4. **Document the change** in your governance log with the date, the old name, the new name, and the reason

### Quarterly Governance Review

Schedule a 30-minute review every quarter with your Data Governor and Analyst:

- Use the **Mixpanel Monitoring Dashboard** (available in project) to identify events with very low or zero volume
- Use Lexicon to audit properties for redundancy or missing descriptions
- Hide or drop events that are no longer relevant
- Review the tracking plan and update it to reflect any product changes since the last review
- Validate that naming conventions are being followed in any new events added since the last review

### Governance Pitfalls Reference

| Pitfall | Impact | Fix |
|---|---|---|
| No clear ownership | No one approves new events; naming drifts; cleanup never happens | Formally assign Data Owner and Data Governor roles |
| Inconsistent naming | Same action tracked as `Sign Up`, `sign_up`, and `signup` -- three separate events in reports | Enable Data Standards; add descriptions to Lexicon immediately |
| No cleanup process | Deprecated events clutter dropdowns and confuse analysts | Schedule quarterly reviews; hide first, then drop |
| No documentation | New engineers repeat old mistakes; onboarding takes weeks | Store tracking plan in a shared wiki; link it from Mixpanel Boards |
| Tracking everything | Thousands of event names; 5,000-name limit approached; noise overwhelms signal | Return to tracking plan methodology -- only track what ties to a KPI |
| One event reused for two actions | Same event name (e.g. "Button Clicked") used for nav and checkout -> reports conflate different behaviors | One event, one meaning -- use a specific event name per distinct user action |
| Duplicate events | New event created when a similar one already exists -> fragmented schema, duplicate reports | Check Lexicon/project for existing events before creating; extend with a property when possible |
| Nested objects as properties | Complex nested objects hard to query and report on; some tooling expects flat properties | Prefer flat properties; flatten or use list/object types only when explicitly in the tracking plan |
| Same event from server and client, inconsistent IDs | Events from backend and frontend merge incorrectly or create duplicate users | Ensure consistent `distinct_id`/identity (e.g. same `$user_id` and `$device_id` strategy) across both |

### Tracking Plan as a Living Document

The tracking plan should never be considered "done." Every product release may add, change, or deprecate events. Treat it like your codebase: versioned, reviewed before changes are merged, and accessible to everyone.

Recommended storage: Google Sheets (using the Mixpanel template), Notion database, or Confluence page.

Required columns:
- Event Name (raw, snake_case)
- Display Name (human-readable)
- Trigger (what user action or system event causes this)
- Properties (name, data type, example value, required/optional)
- Super Property? (yes/no)
- User Property? (yes/no)
- Owning Team
- Status (active / deprecated / planned)
- Date Added / Date Deprecated

> **AGENT PROMPT -- Close**
>
> Once Phase 7 is complete, summarize the full implementation plan back to the customer:
> 1. Confirm their Value Moment and top 2--3 KPIs
> 2. Confirm their two starting events and their properties
> 3. Confirm the tracking method (server-side, client-side, or CDP)
> 4. Remind them to verify Simplified ID Merge is enabled before sending the first event
> 5. Remind them to add Lexicon descriptions for every event they ship
> 6. Point them to the tracking plan template for their vertical
>
> Offer to help them write the first event call for their specific stack.

---

## Reference: Key Mixpanel Documentation Links

| Topic | URL |
|---|---|
| What to Track | https://docs.mixpanel.com/docs/what-to-track |
| Choosing a Tracking Method | https://docs.mixpanel.com/docs/tracking-methods/choosing-the-right-method |
| JavaScript SDK | https://docs.mixpanel.com/docs/tracking-methods/sdks/javascript |
| Python SDK | https://docs.mixpanel.com/docs/tracking-methods/sdks/python |
| Node.js SDK | https://docs.mixpanel.com/docs/tracking-methods/sdks/nodejs |
| iOS Swift SDK | https://docs.mixpanel.com/docs/tracking-methods/sdks/swift |
| Android SDK | https://docs.mixpanel.com/docs/tracking-methods/sdks/android |
| React Native SDK | https://docs.mixpanel.com/docs/tracking-methods/sdks/react-native |
| Flutter SDK | https://docs.mixpanel.com/docs/tracking-methods/sdks/flutter |
| HTTP API | https://developer.mixpanel.com/reference/track-event |
| Identifying Users (Simplified) | https://docs.mixpanel.com/docs/tracking-methods/id-management/identifying-users |
| Events & Properties | https://docs.mixpanel.com/docs/data-structure/events-and-properties |
| User Profiles | https://docs.mixpanel.com/docs/data-structure/user-profiles |
| Group Analytics | https://docs.mixpanel.com/docs/data-structure/group-analytics |
| Default Properties | https://docs.mixpanel.com/docs/data-structure/property-reference/default-properties |
| Reserved Properties | https://docs.mixpanel.com/docs/data-structure/property-reference/reserved-properties |
| Server-Side Best Practices | https://docs.mixpanel.com/docs/tracking-best-practices/server-side-best-practices |
| Developer Environments | https://docs.mixpanel.com/docs/tracking-best-practices/developer-environments |
| Lexicon | https://docs.mixpanel.com/docs/data-governance/lexicon |
| Data Standards | https://docs.mixpanel.com/docs/data-governance/data-standards |
| Event Approval | https://docs.mixpanel.com/docs/data-governance/event-approval |
| Segment Integration | https://segment.com/docs/connections/destinations/catalog/actions-mixpanel/ |
| Rudderstack Integration | https://rudderstack.com/integration/mixpanel/ |
| GTM Template | https://github.com/mixpanel/mixpanel-gtm-template |
| Warehouse Connectors | https://docs.mixpanel.com/docs/tracking-methods/warehouse-connectors |

---

*This document was synthesized from Mixpanel's official documentation, Mixpanel onboarding learning path materials, and internal tracking plan best practice guides. It reflects Mixpanel's recommended practices as of March 2026.*