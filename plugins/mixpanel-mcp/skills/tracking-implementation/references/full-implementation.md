## Full Greenfield Rollout (Phases 0--7)

Run all 8 phases in order. Each phase gates the next -- rushing past discovery leads to wasted implementation and data that is expensive to fix. Ask questions conversationally (1--2 at a time), acknowledge answers, then proceed.

### Full Implementation Context Block

After each phase, update a structured context block in your working notes. Reference it at the start of each phase rather than relying on conversational memory.

- **Company name:**
- **Business model:** (SaaS subscription / usage-based / transactional / freemium / marketplace / ad-supported)
- **Growth model:** (product-led / sales-led / marketing-led)
- **Customer type:** (B2B / B2C / B2B2C -- if B2B: who is the buyer vs. the user?)
- **Stage:** (pre-PMF / growth / scale)
- **Commercial priority:** (acquisition / activation / monetization / retention / expansion)
- **Product type:**
- **Platform(s):**
- **CDP in use:** (Segment / Rudderstack / mParticle / Snowflake / BigQuery / none)
- **Group Analytics:** yes / no
- **EU or CA users:** yes / no
- **Value Moment:**
- **KPIs (2--3):**
- **Dev project token:**
- **Prod project token:**
- **Tracking method:** server-side / client-side / CDP integration
- **Event 1:** `sign_up_completed` -- properties: [list]
- **Event 2:** [Value Moment event name] -- properties: [list]

Update this block at the end of every phase. Never start a phase without referencing it first.

### Phase 0 -- Discovery

**If Pre-Flight was run:** Skip the platform and product type questions -- these are already confirmed from the codebase scan. Lead with your assumptions summary and ask only the three remaining questions (CDP, Group Analytics, business questions). Do not ask what the codebase already answered.

**Step 1 -- Collect company name and URL (always, before anything else).**

Ask:

> "Before we dive in -- what's your company name, and do you have a website or product URL I can look at?"

Then run deep research using both the URL and company name. Do not ask the customer anything else until the research is complete.

**Step 2 -- Deep research protocol.**

Research across all available sources. The goal is to build a business model picture and understand what the company is commercially trying to drive -- not just what the product does.

**Time-box and stop conditions (required):**

- Time-box initial research to 10 minutes or 6 meaningful sources, whichever comes first.
- Stop early once you can confidently fill business model, growth model, customer type, stage, commercial priority, and candidate Value Moment.
- If sources are sparse, contradictory, private, or pre-launch: stop external research and switch to a short clarification set with the customer.

**Low-signal fallback (ask only these):**

1. "How do you make money today, and how do you expect that to evolve in the next 6-12 months?"
2. "Who is the buyer vs. daily user?"
3. "What user action most strongly predicts retention or expansion?"
4. "What compliance or consent constraints should we respect before any tracking starts?"

| Source | What to extract |
|---|---|
| Marketing site (homepage, product pages, pricing) | Core value proposition, target customer (B2B vs B2C, industry, company size), pricing model (subscription, usage-based, freemium, transactional), platform (web, iOS, Android) |
| Pricing page specifically | Plan tiers -> infer Mixpanel plan eligibility; free vs paid conversion funnel structure; whether Group Analytics is plausible |
| About / Team / Careers pages | Company stage, team size, open roles (reveal growth priorities and tech stack), founding story |
| Blog / Changelog / Product announcements | Recent feature launches -> candidate events; what the team is investing in; what they care about measuring |
| App Store / Play Store listings and reviews | User language for the value moment; what users love and what they complain about; platform confirmation |
| G2, Capterra, ProductHunt, Trustpilot | Third-party user language for the value moment and pain points; competitive context |
| Crunchbase / LinkedIn / TechCrunch | Funding stage and amount -> informs growth focus (acquisition vs activation vs retention); investor-implied growth model; team size trajectory |
| Job listings (LinkedIn, Greenhouse, Lever, their careers page) | Tech stack clues (engineering job descriptions list languages and frameworks); data/analytics maturity (do they have a data team?); growth-stage priorities |
| Source code hints (`<script>` tags, JS bundle names, framework meta tags) | Existing analytics tools (GA4, Amplitude, Segment); tech stack confirmation; whether Mixpanel is already partially implemented |

**Synthesize into a business model summary before asking any questions.** Carry this forward into all downstream phases:

- **Business model:** How they make money (SaaS subscription / usage-based / marketplace take rate / transactional / ad-supported / freemium-to-paid)
- **Growth model:** How they acquire and retain users (product-led growth / sales-led / marketing-led / community-led)
- **Customer type:** B2B (who is the buyer vs the user?) / B2C / B2B2C
- **Stage:** Pre-PMF / growth / scale (inferred from funding, team size, product maturity)
- **Commercial priority:** What the company is trying to drive right now -- acquisition, activation, monetization, retention, or expansion
- **Candidate Value Moment:** The specific action that signals a user got value, inferred from product descriptions, user reviews, and pricing structure
- **Candidate KPIs:** What a company at this stage and in this vertical would logically measure

**Step 3 -- Present assumptions, then ask only what research couldn't answer.**

Lead with the business model summary rather than raw product facts:

> "Based on what I found, here's how I'm thinking about your business: you're a B2B SaaS project management tool targeting mid-market engineering teams, subscription-based, currently in growth stage with Series B funding. Your likely Value Moment is a project reaching a milestone or a report being generated. Does that framing sound right?"

Then ask only the questions research couldn't answer:

| Remaining question | Decision It Drives |
|---|---|
| Do you use a CDP or data warehouse? (Segment, Rudderstack, mParticle, Snowflake, BigQuery) | If yes -> skip SDK installation; route through integration in Phase 6 |
| Do you have the Group Analytics add-on? (if not inferable from pricing page) | If yes -> surface Group Analytics in Phase 3 |
| What are the 2--3 most important business questions you want Mixpanel to answer? | Drives event selection, KPI design, and tracking plan in Phases 1--4 |

**If neither a codebase nor a URL is available**, ask all five questions conversationally:

| Question | Decision It Drives |
|---|---|
| What type of product? (SaaS, e-commerce, media, fintech, mobile game, marketplace, internal tool) | Vertical-specific event examples in Phase 4 |
| What platform(s)? (web, iOS, Android, React Native, Flutter, server-side only, combo) | SDK selection in Phase 6 |
| Do you use a CDP or data warehouse? (Segment, Rudderstack, mParticle, Snowflake, BigQuery) | If yes -> skip SDK installation; route through integration in Phase 6 |
| Do you have the Group Analytics add-on? (availability varies by plan) | If yes -> surface Group Analytics in Phase 3 |
| What are the 2--3 most important business questions you want Mixpanel to answer? | Drives event selection, KPI design, and tracking plan in Phases 1--4 |

Store all confirmed answers in the Context Block. They gate which content you surface in later phases.

**Output of this phase:** Business model summary (how they make money, growth model, customer type, stage, commercial priority) confirmed with customer. Product type, platform(s), CDP status, Group Analytics flag, and top 2--3 business questions captured in Context Block. Required before Phase 1.

### Phase 1 -- Analytics Strategy

**Before presenting any framework, ask:**

1. "What does success look like in the next 90 days -- acquisition, activation, engagement, or retention?"
2. "What is the single most important action a user can take that signals they're getting real value?"

**Then:**

- If the customer already has defined KPIs and a named value metric: skip the RAE framework introduction. Validate their existing KPIs against the 5M filter and confirm or refine their Value Moment name. Proceed once you have a confirmed Value Moment and 2--3 KPIs.
- For customers new to product analytics: select the **RAE Framework** (Reach / Activation / Engagement) -> see `reference.md Section Phase 1` for full framework
- Name the customer's **Value Moment** explicitly: `[Core Action] at [Natural Frequency]`
  - e.g. "Your Value Moment is `report_generated` -- weekly. This is one of the first two events we'll track."
- Help them apply the **5M filter** (Meaningful, Measurable, Manageable, Movable, Time-bound) to candidate KPIs
- Warn against vanity metrics (downloads, page views) and lagging-only metrics (churn, revenue)

**Output of this phase:** Named Value Moment + 2--3 KPIs. Required before Phase 4.

### Phase 2 -- Mixpanel Project Setup

**Ask:**

1. "Have you already created a Mixpanel account and project, or starting fresh?"
2. "Do you have a separate dev/staging environment?"
3. "Do you have users in the EU or California?" -- If yes, flag for a consent gate in Phase 6 before any initialization code is written.

**Steps in order:**

**A. Verify Simplified ID Merge** (non-negotiable first step)

- Project Settings -> Identity Management -> confirm "Simplified API"
- If it shows "Original API" and no data has been tracked yet: switch it before proceeding
- If data has already been tracked under Original API: do not switch without reading the migration guide

**B. Determine project structure** (before creating anything)

| Scenario | Recommendation |
|---|---|
| Web + mobile, same product, same users | Single project |
| Completely separate products / user bases | Separate projects |
| Same product, different feature sets per platform | Single project + `platform` super property |

This determines how many projects to create in the next step.

**C. Create dev and production projects** (always at minimum two)

- Name clearly: `[Product] - Production` and `[Product] - Development`
- Set timezone to match primary business location (cannot change retroactively without affecting historical data)
- If step B determined multiple production projects are needed, create each with the same naming pattern
- Use environment-based config to switch tokens automatically -> see `reference.md Section Phase 2` for JS example

**D. Collect project tokens -- ask the customer to provide them now**

Once dev and production projects exist, ask:

> "Can you copy the project token for each project? You'll find them at mixpanel.com -> your project -> Project Settings -> Project Token. Paste both here and I'll inject them directly into the initialization code -- no manual search-and-replace needed."

| What to collect | Where the customer finds it |
|---|---|
| Production project token | mixpanel.com -> Production project -> Settings -> Project Token |
| Dev/staging project token | mixpanel.com -> Development project -> Settings -> Project Token |

**Store both tokens in the Context Block.** They are injected verbatim into every initialization code snippet produced in Phase 6. Do not use `'YOUR_PROJECT_TOKEN'` placeholders -- if the tokens are in hand, use them.

If the customer cannot provide tokens yet (e.g., someone else owns the Mixpanel account): proceed with placeholder values and flag that tokens must be substituted before any events are sent.

**E.** Assign minimum-necessary roles: Owner, Admin, Analyst, Consumer.

**Output of this phase:** Simplified ID Merge verified, project structure decided, dev and production projects created, both tokens stored in the Context Block, EU/CA flag noted, roles assigned. Required before Phase 3.

### Phase 3 -- Data Model

**Ask:** "Have you worked with an event-based analytics tool before, or is this your first time?"

- Yes -> brief orientation
- No -> full walkthrough from `reference.md Section Phase 3`

**Core concepts to convey:**

| Concept | Key fact |
|---|---|
| **Events** | Immutable, timestamped actions. Required fields: event name, distinct_id, timestamp. |
| **Event Properties** | Point-in-time; never change after ingestion. Send numerics without quotes or they become strings. |
| **User Profiles** | Mutable, current state. Join retroactively to events via distinct_id. Only create for identified users. |
| **Super Properties** | Auto-attached to every event. Use for: `app_version`, `platform`, `plan_type`, `experiment_group`. |

**Property type reminder:** If you send `price = "29.99"` (quoted), Mixpanel treats it as String -- cannot aggregate. Always send numeric values unquoted.

**User Profiles join to the latest state.** If you need "plan at time of event," track `plan_type` as an event property too.

**If Group Analytics confirmed in Phase 0:** Surface Group Analytics section from `reference.md Section Phase 3 -- Group Analytics`. Key call: `mixpanel.set_group("company_id", "acme-corp")` + set Group Profiles.

**Group Analytics late-discovery:** If the customer indicates during this phase that they need account-level analysis (e.g., "we sell to companies and need to see usage by account") and Group Analytics was not confirmed in Phase 0: ask directly whether they have the Group Analytics add-on. If yes, surface the Group Analytics section now before moving to Phase 4, and update the Group Analytics flag in the Context Block.

**CDP late-discovery:** If the customer mentions they use a CDP (Segment, Rudderstack, mParticle) at any point after Phase 0: note it in the Context Block. When you reach Phase 6, route through the integration path rather than SDK installation. The tracking plan design in Phase 4 remains valid -- only the implementation method changes.

**Output of this phase:** Customer aligned on the Mixpanel data model (events, properties, profiles, super properties). Group Analytics scope confirmed. Required before Phase 4.

### Phase 4 -- Tracking Plan

**If a codebase scan was run (Pre-Flight):** Do not start with open-ended questions. Instead, present the draft event list derived from routes, controllers, and models. Show proposed snake_case names, candidate properties sourced from model fields, and flag any naming inconsistencies found in existing logging code. Then ask the customer to:

1. Confirm which events actually matter for their KPIs (priority, not exhaustiveness)
2. Fill in business intent the code can't reveal ("what does a user completing this action tell you?")
3. Validate or correct property values and enumerations not visible in the schema

**If no codebase is available**, ask:

1. "Do you have existing screen flows, wireframes, or user journey maps? Sharing them helps translate them into events."
2. "What are the top 3 user actions where you'd say they're getting real value?"

Design the full tracking plan using the 7-step sequence below, then implement in two-event increments -- ship `sign_up_completed` and the Value Moment first, validate they are working, and add remaining events from the signed-off plan progressively.

**Start with exactly two events:**

- **Event 1:** `sign_up_completed` (or equivalent) -- with properties: `sign_up_method`, `referral_source`, `platform`
- **Event 2:** The Value Moment named in Phase 1

**Tracking plan sequence (do not skip steps):**

```
1. Define KPIs          -> Phase 1 output
2. Map KPIs to flows    -> user journeys that drive each KPI
3. Flows -> events       -> discrete actions within each journey
4. Events -> properties  -> context needed to analyze each action
5. Identify globals     -> properties on almost every event -> super properties
6. Identify profiles    -> attributes describing the user -> user properties
7. Document             -> write into tracking plan template before writing any code
```

**Naming -- enforce from day one (Mixpanel is case-sensitive):**

- Event names: `object_verb` in `snake_case` -> `checkout_completed`, `video_played`, `report_generated`
- Property names: `snake_case`, descriptive, no abbreviations -> `payment_method`, `plan_type`
- Property values: lowercase strings, consistent -> `"free"` not `"Free"` or `"FREE"`
- Never use `$` or `mp_` prefixes on custom properties

**Granularity test:** One event + its properties should answer your business question without needing a dozen filter conditions.

**Dynamic names:** Never construct event or property names at runtime -- creates thousands of unique names and can quickly exhaust practical event-name limits (verify current limits in docs/account plan).

**Null values:** Omit properties that don't apply; never send `null`, `""`, or `"N/A"`.

**Tracking plan templates by vertical** (from `reference.md Section Phase 4`):

- SaaS, E-Commerce, Media/Content, Fintech, Blank

**Vertical-specific event examples** are in `reference.md Section Phase 4 -- Vertical-Specific Event Examples`.

**When adding events to an existing project** (extending the tracking plan or Focused Remediation): Before designing new events, check existing schema -- see `reference.md Section Phase 4 -- Adding Events to an Existing Project`. Reuse event and property names where a similar event or property already exists; match established naming conventions and enum-like values.

**The tracking plan must be reviewed and signed off by product, engineering, and analytics before implementation begins.**

**Optional spec-first step (recommended before implementing each new event):** For each event (or next batch), you can write a short spec for quick sign-off before writing code. Offer: "I can either (A) write a spec first -- event name, trigger, properties, and types for your review -- or (B) go straight to code. Option A is recommended so we catch naming or typing issues early." If the customer chooses A, use this format and checklist:

**Spec format:**

```
Event: <Name>
Trigger: <Exact condition -- e.g. "user clicks Submit on /checkout">
Properties:
  - <property_name> (string|number|boolean) -- <what it represents>
  - ...
Reused from existing schema: <list any properties being reused>
New properties: <list any net-new properties>
Owner: <team or email>
```

**Spec checklist before finalizing:** Name matches project convention; name is past tense and specific; no dynamic values in the event name (use a property instead); no PII in properties; property names are `snake_case` and match existing names where possible; required properties will always be present on every call.

**Output of this phase:** Signed-off tracking plan with at minimum `sign_up_completed` and the Value Moment fully specified (name, trigger, properties). Required before Phase 6.

### Phase 5 -- Codebase Access Check

**Before proceeding to implementation, confirm codebase access:**

> "Do you have access to the codebase right now, or are you gathering specifications for a developer to implement later?"

**If user has codebase access:**
- Proceed with Phase 6 (Implementation)
- Write code directly into files
- Use Pre-Flight scan results if available

**If user is gathering specs for handoff:**
- Skip to Developer Handoff Spec Generation (after Phase 7)
- Collect any remaining technical details:
  - Specific file paths (if they know them)
  - Environment variable naming conventions
  - Code style preferences (async/await vs promises, TypeScript vs JavaScript, etc.)
- Do NOT attempt to write code to files
- Mark context with: `handoff_mode: true`

### Phase 6 -- Implementation

**Decision gate (from Phase 0 and Phase 2 answers):**

- Customer uses Segment/Rudderstack/mParticle -> use CDP integration, no new SDK -> see `reference.md Section Phase 8 -- Integration Pointers`
- Customer uses Snowflake/BigQuery -> see `reference.md Section Phase 8 -- Warehouse Connectors`
- EU or CA users flagged in Phase 2 -> surface the consent pattern from `reference.md Section Phase 8 -- Consent and Opt-In Tracking` before writing any initialization code
- Otherwise, ask: "Do you want to track from the server (backend), browser/app (client), or both?" -- or skip this question if the codebase scan already made the answer obvious

**Tracking method recommendation:**

| Method | Use When | Key Tradeoff |
|---|---|---|
| **Server-side** (preferred) | Any event observable on your backend | Reliable; must manage IDs and parse User-Agent manually |
| **Client-side web** | Anonymous behavior pre-login; UI interactions | 15--30% event loss to ad blockers; use a proxy to mitigate |
| **Client-side mobile** | Native iOS/Android/RN/Flutter | Old app versions persist; harder to fix bugs |

**Token injection:** Use the real project tokens collected in Phase 2 -- never write `'YOUR_PROJECT_TOKEN'` if the tokens are already in hand. If a dev/prod split exists, emit both initializations with the correct token for each environment.

**Then surface the relevant SDK section(s) from `reference.md Section Phase 8 -- SDK Implementation Guide`:**

| Platform | Reference Section |
|---|---|
| JavaScript (Browser) | `reference.md Section JavaScript (Browser)` |
| Python (server) | `reference.md Section Python (Server-Side)` |
| Node.js (server) | `reference.md Section Node.js (Server-Side)` |
| React Native | `reference.md Section React Native` |
| iOS Swift | `reference.md Section iOS (Swift)` |
| Android Kotlin | `reference.md Section Android (Kotlin)` |
| Flutter | `reference.md Section Flutter` |
| HTTP API | `reference.md Section HTTP API (Language-Agnostic)` |

Each SDK section in reference.md covers the full lifecycle: install -> init -> track event -> super properties -> user profile -> identify -> reset.

**If a codebase scan was run (Pre-Flight):** Do not produce generic code snippets. Write implementation code directly into the specific files identified during the scan:

- Initialization code -> the app entry point or config file already identified
- Super property registration -> immediately after init, or after the login handler
- Event tracking calls -> inside the exact controller, handler, or component functions where the action occurs
- Environment token switching -> use the existing env config pattern already present in the codebase

Place each `track()` call as close to the triggering action as possible -- in the event handler, form submit callback, or API endpoint that represents the action.

**Server-side:** Forward client IP (`ip`) only when policy and consent rules permit geolocation enrichment. Always set `$insert_id` for deduplication. Parse User-Agent manually for `$browser`, `$os`, `$device`.

**QA gate -- verify before proceeding to Phase 7:** Ask the customer to deploy their current changes to the dev environment, open Mixpanel Live View (mixpanel.com -> dev project -> Live View), and confirm at least one event appears. Do not proceed to identity management until basic event ingestion is confirmed working. Debugging initialization and identity at the same time makes root-cause analysis very difficult.

**Post-deploy verification (after each new event or batch):** Beyond Live View, confirm the event appears in Reports for the expected date range (e.g. run a segmentation or Insights query filtered by the event name and today's date). Check that key properties are populating with expected values. Event and property names are case-sensitive -- zero results often mean a typo or casing mismatch. See `reference.md Section Phase 8 -- Post-Deploy Verification` for details.

**Output of this phase:** All tracking and initialization code written and placed in the codebase. At least one event confirmed arriving in Mixpanel Live View. Customer ready to wire up identity calls.

### Phase 7 -- Identity Management

**If a codebase scan was run (Pre-Flight):** The login, signup, logout, and session-restore handlers are already located. Do not ask whether anonymous browsing exists -- read the auth flow to determine it directly. Place `.identify()`, `.people.set()`, `.register()`, and `.reset()` calls in the exact locations already identified. Only ask if something in the auth flow is ambiguous (e.g., whether a middleware handles re-authentication on page load).

**If no codebase is available, ask:**

1. "Does your product have anonymous browsing before login, or do users authenticate immediately?"
2. "Do users access your product on multiple devices or platforms?"

If anonymous browsing exists or multi-device usage is likely: cover this phase in full.
If users always authenticate immediately (e.g., SSO-only internal tool): anonymous bridging section can be skipped.

**The three required calls (client-side):**

```
On login or signup     -> mixpanel.identify(user.id)
On app re-open         -> mixpanel.identify(user.id)  [if already logged in]
On logout              -> mixpanel.reset()
```

**How Simplified ID Merge works:** When an event contains both `$device_id` and `$user_id` for the first time, Mixpanel merges all past and future events under the `$user_id` as canonical `distinct_id`.

**Correct signup flow order:**

1. Create user in database
2. Call `.identify(user.id)`
3. Set profile properties via `.people.set()`
4. Update super properties via `.register()`
5. Track `sign_up_completed` event (AFTER identify -- so it's attributed correctly)

**Server-side identity:** SDKs do not auto-generate `$device_id`. Store a UUID in a cookie. Pass `$device_id` on every pre-login event. Pass both `$device_id` and `$user_id` on the first post-login event. See `reference.md Section Phase 8 -- Server-Side Identity Flow` for full Python example.

**Full client-side flow** (signup -> logout -> re-open) is in `reference.md Section Phase 8 -- Client-Side Identity Flow`.

**Identity checklist (quick validation):** Before proceeding, confirm: `identify()` was called on login/signup; profile attributes use `people.set()` not `track()`; `identify()` on re-open when already logged in (not every page load); stable unique ID (not email/device). Full checklist and QA: `reference.md Section Phase 8`.

**QA before production:** Run the ID Management QA Checklist from `reference.md Section Phase 8`.

**Output of this phase:** Identity calls (`identify`, `reset`) placed in the correct locations. ID Management QA checklist passed in dev before any production deployment. Required before Phase 8.

### Developer Handoff Spec Generation (No Codebase Access Mode)

**When to use:** User went through Full Implementation (Phases 0-4) but doesn't have codebase access (marked with `handoff_mode: true` at Codebase Access Check).

**Generate:** `MIXPANEL_IMPLEMENTATION_SPEC.md` using the template in `reference.md Section Developer Handoff Specification Template`.

**Required content (from Full Implementation Context Block):**
- All context gathered during Phases 0-4
- Platform(s), SDK(s), tracking method, CDP, consent requirements
- Complete tracking plan: all events with full property schemas (not just 2 events)
- SDK installation commands for each platform
- Complete initialization code (with consent gate if required)
- Complete code snippets for all events (not patterns -- actual ready-to-use code with real tokens)
- Identity flow: where and when to call identify() and reset() with file location hints
- Business context: Value Moment, KPIs, OKRs, commercial priority
- Event priority ranking (what to implement first if time-limited)
- Step-by-step verification guide with expected Live View results
- Troubleshooting section for common issues
- Governance setup instructions (Lexicon, Data Standards, Event Approval, roles)

**Fill in the template with:**
- Actual project tokens (dev + prod from Phase 2)
- Real event names and properties from full tracking plan (Phase 4)
- Complete SDK initialization code with platform-specific syntax
- Identity flow code with file hints
- Business context: Value Moment rationale, KPI alignment, priority ranking
- Group Analytics setup if applicable (Phase 0 context)
- Multi-platform integration if applicable
- Governance checklist with role assignments (Phase 8 preparation)

**Save to:** User's current working directory (or ~/Downloads if working directory is unclear).

**Presentation:**
> "I've created a complete implementation specification at [absolute path]. This contains:
> - Complete, copy-paste ready code for [N] events with your actual project tokens
> - Priority ranking: implement these [X] events first, then these [Y], then these [Z]
> - Step-by-step testing instructions with expected Live View results
> - Business context explaining how each event ties to your [OKR/KPIs/Value Moment]
> - Governance setup checklist (Lexicon, Data Standards, Event Approval, role assignments)
> - Troubleshooting guide for common issues
>
> Share this with your developer -- they won't need any context from our conversation. The spec includes everything needed to implement in 1-2 days."

**Optional additional artifacts:**
- CSV export of complete tracking plan (for product managers who prefer spreadsheets)
- Code-only snippets file (for quick reference)

**After generating spec:**
- Skip Phase 6 implementation (developer will do this)
- Skip Phase 7 identity verification (included in spec as implementation steps)
- Skip AGENTS.md creation (it's included in the handoff spec as a template)
- Modify Phase 8 presentation: explain that governance setup is included in the spec but should happen AFTER developer implements

### Phase 8 -- Data Governance

**Ask:**

1. "Who will be responsible for keeping event names and properties consistent over time -- a data engineer, PM, analyst, or all three?"
2. "Do you have a shared internal wiki (Notion, Confluence, Google Drive) for your tracking plan and governance docs?"

**Assign roles before implementation:**

| Role | Responsibility |
|---|---|
| **Data Owner** | Approves new events before they go live |
| **Analyst / PM** | Documents use cases; verifies events match tracking plan |
| **Engineer** | Implements only reviewed and approved events |
| **Data Governor** | Oversees Lexicon; enforces naming standards; runs quarterly reviews |

**Set up Lexicon immediately** (Data Management -> Lexicon):
For every event shipped, add: Description (one sentence: what triggers it, what it represents), Tags (domain/team), Example property values.

**Enable Data Standards** (Project Settings -> Data Standards):

- Require `snake_case` for all event and property names
- Require descriptions before events appear in reports

**Enable Event Approval** (Project Settings -> Event Approval):

- Unreviewed event names go to a pending queue until a Data Owner approves them
- Prevents test events, typos, and undocumented tracking from polluting production

**Hiding vs. Dropping:**

- **Hide** -> still stored, just removed from UI dropdowns. Use for deprecated events you may still need historically.
- **Drop** -> stops ingesting new data. Cannot be undone. Hide first, observe one quarter, then drop.

**Merging divergent events:** Lexicon -> select both events -> Merge -> choose canonical name -> update future tracking.

**Quarterly review:** Audit zero-volume events, check for missing Lexicon descriptions, validate naming conventions on new events.

See `reference.md Section Phase 8` for: governance pitfalls table, tracking plan column schema, naming change management process.

**Close:** After Phase 8, summarize the full implementation.

**If codebase access was available (normal implementation path):**

Summarize the full implementation plan back to the customer:

1. Their Value Moment and top 2--3 KPIs
2. Their starting events and properties (all events from tracking plan)
3. Tracking method (server-side / client-side / CDP)
4. Identity management approach
5. Governance roles and responsibilities

**Add Mixpanel tracking guidance to `AGENTS.md` in the project root.** Check if an `AGENTS.md` already exists. If it does, append the Mixpanel analytics section from `AGENTS.md.template` -- do not overwrite existing content from other tools or conventions. If no `AGENTS.md` exists, create one using the full template. In either case, fill in actual values from the implementation (platform, SDK, token location, full event list, identity file paths, consent status). This ensures future AI agents know that Mixpanel is the analytics tool and how to add tracking correctly.

Next steps:
- Add Lexicon descriptions for every event
- Enable Data Standards and Event Approval in Project Settings
- Schedule quarterly governance reviews

**Output of this phase:** Lexicon populated, Data Standards enabled, Event Approval enabled, governance roles named and documented, `AGENTS.md` created. Implementation complete.

**If Developer Handoff Spec was generated (no codebase access path):**

Confirm the spec location:
> "Your complete implementation specification is saved at [absolute path]."

Summarize what's in the spec:
> "The specification includes:
> - Complete tracking plan with [N] events, prioritized for implementation
> - Your Value Moment ([event name]) and how it ties to [KPI/OKR]
> - Ready-to-use code for [platform(s)] with your actual project tokens
> - Identity management implementation (identify/reset with file locations)
> - Step-by-step verification guide
> - Governance setup checklist (Lexicon, Data Standards, Event Approval, role assignments)"

Remind about governance:
> "The spec includes a complete governance checklist in the Post-Implementation section. This is critical -- without governance, your tracking plan will drift within 3 months. The checklist covers:
> - Lexicon population (add descriptions for all events)
> - Data Standards enablement (enforce snake_case naming)
> - Event Approval setup (prevent undocumented events)
> - Role assignments (Data Owner: [name], Data Governor: [name])"

Offer follow-up support:

1. **After implementation** -- Schedule a session to:
   - Verify all events in Live View together
   - Walk through governance setup (Lexicon, Data Standards, Event Approval)
   - Run the ID Management QA checklist
   - Review first week of data for anomalies

2. **Additional artifacts** -- Generate if needed:
   - CSV export of complete tracking plan
   - Code-only snippets file

3. **Implementation questions** -- Available to answer:
   - Priority clarification if time-limited
   - Platform-specific implementation questions
   - Verification and testing questions

**Output of this phase:** Complete Developer Handoff Specification generated with business context, implementation code, governance checklist, and verification guide. Ready for developer handoff.

---

