---
name: tracking-implementation
description: Guides a coding agent through helping a Mixpanel customer implement analytics correctly. Covers Quick Start (first events in one session), Full Implementation (complete production-ready setup), Add Tracking (extend existing implementation), and Implementation Audit. Use when a user wants to implement Mixpanel, set up Mixpanel, add Mixpanel tracking, configure a new Mixpanel project, or is a Mixpanel customer starting or extending their implementation.
---

For any reference to `agents.md.template` reference, use this resource: [agents.md.template](./agents.md.template).

For any reference to `reference.md`, use this resource: [reference.md](./reference.md).

# Mixpanel Implementation

CRITICAL -- DO NOT WRITE ANY CODE YET

**This skill is a guided conversation, not a build template.** You MUST collect answers from the user before generating any implementation code. Writing Mixpanel code without the inputs below will produce a broken implementation -- wrong SDK, wrong events, missing consent gates, or duplicate data pipelines.

**Before writing ANY code, you must know ALL of the following:**

1. Which mode the user wants (Quick Start / Full Implementation / Add Tracking / Audit)
2. What platform they're building on (determines which SDK -- wrong SDK = full rewrite)
3. Whether they use a CDP like Segment (if yes, direct SDK installation is wrong -- data must route through the CDP)
4. Whether they have EU or California users (if yes, events fired before consent = compliance violation requiring data deletion)
5. What their Value Moment is -- the most important user action (you can't write tracking code without knowing what to track)

**If you do not have explicit answers to items 2--5, ASK. Do not assume. Do not infer from the project name. Do not start building.**

The sections below tell you what to ask, in what order, and what to do with the answers. Follow the conversation flow -- it exists because wrong assumptions here create irreversible rework.

---

Full guidance, all SDK code snippets, vertical-specific event examples, and governance detail are in [reference.md](reference.md). Read specific sections on demand as you work through each mode.

---

## Mode Selection -- Ask First

Before doing anything else, ask the customer which mode fits their goal:

> "What brings you here today?"
> 1. **Quick Start** -- Get your first events into Mixpanel in one session
> 2. **Full Implementation** -- Build a complete, production-ready analytics setup from scratch
> 3. **Add Tracking** -- Extend an existing Mixpanel implementation with new events
> 4. **Audit** -- Review and diagnose an existing implementation

State the selected mode explicitly and offer to switch at any point.

### Mode mapping

| Mode | What it covers | Detail section |
|---|---|---|
| **Quick Start** | 7-step compressed flow: mandatory questions -> context -> mini tracking plan -> project setup -> implementation + identity -> Live View verification -> wrap-up | Quick Start Flow (below) |
| **Full Implementation** | All 8 phases (0--7) in order: Discovery -> Analytics Strategy -> Project Setup -> Data Model -> Tracking Plan -> Implementation -> Identity Management -> Data Governance | Full Greenfield Rollout (below) |
| **Add Tracking** | Starts with "what do you want to track?" -> checks existing schema -> designs new events -> implements and verifies | Add Tracking Mode (below) |
| **Audit** | Diagnoses current state -> produces prioritized fixes -> executes fixes via Add Tracking or Full Implementation | Implementation Audit Mode (below) |

### Mode switching rules

- If Quick Start surfaces high identity complexity, consent risk, or CDP/warehouse usage -> offer to escalate to Full Implementation.
- If Full Implementation user says "can we just get something working first?" -> offer to switch to Quick Start.
- If you discover missing prerequisites (e.g., no tracking plan), pause and backfill the required earlier phase before proceeding.
- If risk is high (identity merge, consent, or production governance), escalate to Full mode even if the customer started in a lighter mode.
- Escalation is always an offer, never automatic. The user decides.
- At the end of each mode, summarize what was completed, what remains, and which next steps are recommended.

---

## Compliance and Privacy Guardrails

This skill is implementation guidance, not legal advice. Use customer policy and counsel as source of truth when there is conflict.

| Scenario | Default behavior |
|---|---|
| Region includes EU/EEA/UK/CH or CA users | Treat consent as required before non-essential tracking; apply consent gate pattern before SDK initialization |
| Region is unknown | Ask once; if still unknown, use conservative consent-gated behavior until clarified |
| Server-side geolocation enrichment | Only forward IP when customer policy permits; if restricted, omit IP and document reduced geo resolution |
| Identity/profile enrichment | Track minimum required attributes only; avoid sensitive categories unless explicitly approved in policy |

**Fail-safe:** if consent status is unknown in a regulated context, delay tracking initialization and collect clarification first.

---

## Pre-Flight -- Codebase Scan

**Run this before any mode if you have access to the codebase. Do not ask the customer anything yet.**

Read the codebase silently and build a working picture to carry into all downstream work. This replaces most discovery questions and produces a grounded draft tracking plan before the first conversation turn.

| What to read | What to extract |
|---|---|
| Route/page files, controllers, API endpoints | Candidate events -- every meaningful user-initiated action (`POST /projects`, `PUT /subscriptions/upgrade`, checkout handler, etc.) |
| Database models or schema files | Candidate properties and their types; User Profile fields; Group entity fields if B2B |
| Auth / session files (login, signup, logout handlers) | Where to place `.identify()`, `.people.set()`, and `.reset()`; whether anonymous browsing exists |
| Existing analytics, logging, or third-party tracking calls (GA4, Amplitude, Segment, `console.log`) | First-draft event names; naming inconsistencies to fix; properties already being collected |
| Package files (`package.json`, `requirements.txt`, `build.gradle`, `Package.swift`, `pubspec.yaml`) | Exact tech stack and framework -> SDK selection; confirms platform |
| Environment config files (`.env`, `config/`, `settings.py`) | Where tokens should be injected; whether a dev/prod split already exists |

**After scanning, carry forward:**

- Confirmed tech stack (eliminates the platform question)
- A draft list of candidate events with proposed snake_case names
- Candidate properties sourced from model fields and existing logging
- The exact files and line locations where Mixpanel initialization and tracking calls will be written
- The auth file locations and login/logout/re-open patterns (for identity)

Present assumptions to the customer rather than asking from scratch. Only ask what the codebase cannot answer.

---

## Quick Start Flow

**Success criteria:** A Quick Start session is successful when:
- Two events (`sign_up_completed` + Value Moment) are defined with a mini tracking plan
- Tracking code is written and placed
- At least one event is confirmed in Live View
- Basic identity (identify on login, reset on logout) is wired in
- Any hard blockers (consent, CDP routing) have been surfaced

### Fast-Path Rules

In Quick Start mode:

**Do not require before implementation:**
- Company name or URL research
- Deep external research (Crunchbase, job listings, G2, etc.)
- Business model synthesis
- RAE framework, 5M filter, or formal KPI design
- Broad event taxonomy or tracking plan beyond the first 2 events
- Cross-functional sign-off on tracking plan
- Dev/prod project split
- Simplified ID Merge verification (it's the default since April 2024)
- Role assignment or governance setup
- Full data model education

**Do require before implementation:**
- Platform confirmation (one-way door: wrong SDK = rewrite)
- CDP/warehouse status (one-way door: SDK when CDP exists = duplication)
- EU/CA consent status (one-way door: events before consent = compliance violation)
- Value Moment identification (can't track without knowing what to track)
- Mini tracking plan for 2 events (structured enough for clean implementation)
- One valid project token

**Do include during implementation:**
- Consent gate if EU/CA users (before SDK init)
- Basic identity (identify on login/signup, reset on logout)
- Live View verification

**Surface after implementation (as next steps, not gates):**
- Expanded tracking plan
- Full identity QA (especially if complexity flags raised)
- Dev/prod project split
- Analytics strategy and KPI framework
- Data governance (Lexicon, Data Standards, Event Approval)
- Group Analytics setup (if B2B)

### Quick Start Context Block

Maintain this minimal context during Quick Start:

- **Platform(s):**
- **Tracking method:** client-side / server-side / CDP
- **CDP in use:** none / [name]
- **EU or CA users:** yes / no
- **Value Moment:**
- **Event 1:** `sign_up_completed` -- properties: [list]
- **Event 2:** [Value Moment event] -- properties: [list]
- **Project token:**
- **Identity complexity flags:** [none / anonymous browsing / multi-device / shared devices / account switching]

### Step 1 -- Mandatory Questions (No One-Way Doors Only)

Ask only the questions where a wrong assumption creates irreversible rework:

**Question 1: "What platform are you building on?"**
(web, iOS, Android, React Native, Flutter, server-side, combination)
- **Why mandatory:** Determines SDK selection. Wrong SDK = rewrite.
- **Can be inferred from Pre-Flight:** Yes -- skip if codebase scan already answered this.

**Question 2: "Are you sending data through a CDP or warehouse tool already?" (Segment, Rudderstack, mParticle, Snowflake, BigQuery)**
- **Why mandatory:** If yes, the entire implementation path changes. SDK installation gets skipped; routing goes through the integration. Building direct SDK when a CDP exists = duplication and architectural mismatch.
- **Can be inferred from Pre-Flight:** Sometimes (package.json may reveal Segment/Rudderstack).

**Question 3: "Do you have users in the EU or California?"**
- **Why mandatory:** If yes, consent must gate SDK initialization. Shipping events before consent = compliance violation that requires data deletion.
- **Can be inferred from Pre-Flight:** No -- this is a business/legal fact, not a code fact.

**Question 4: "What's the most important action a user takes in your product?"**
- **Why mandatory:** This names the Value Moment event. Without it, we don't know what to track.
- **Can be inferred from Pre-Flight:** Partially -- the agent can propose candidates from route/controller analysis, but the user confirms.

That's it. Four questions maximum (fewer if Pre-Flight answers some).

**What about Group Analytics and identity complexity?** These are important but not one-way doors in the Quick Start context:

- **Group Analytics:** Can be added later without rework. The events tracked in Quick Start don't become invalid if Group Analytics is added afterward. Defer to "what's next" recommendations.
- **Identity complexity:** Basic identify/reset is correct for both simple and complex cases. The risk is that complex cases need *more* identity work -- but the basic work isn't *wrong*. Surface it as a flag, not a gate (see Step 6 identity section below).

### Step 2 -- Context Gathering (Research or Pre-Flight)

The agent uses whatever input is available, in priority order:

| Available input | What the agent does | Time budget |
|---|---|---|
| **Codebase access** | Pre-Flight scan (unchanged). Extracts tech stack, candidate events, auth flow, existing analytics. | No time limit -- this is the highest-value accelerator |
| **Company URL** | Light Research: homepage + pricing page + login/signup page. Extract product type, B2B/B2C signal, candidate Value Moment, sign_up_method values. Cap at 3 pages, under 2 minutes. | 2 minutes max |
| **Neither** | Skip research entirely. Use the 4 mandatory questions above. | 0 minutes |

**Rules for Light Research:**
- Stop as soon as the agent can confidently fill: product type, platform confirmation, B2B vs B2C, candidate Value Moment
- Do NOT research: Crunchbase, job listings, G2/Capterra, blog, LinkedIn, TechCrunch
- Do NOT require company name or URL before proceeding -- if the user doesn't offer one, skip research and ask the questions
- If the homepage and pricing page answer everything, stop there

**After context gathering, present assumptions:**
> "Based on [what I found / what you told me], here's what I'm working with: [platform], [tracking method], [Value Moment candidate]. Sound right?"

One confirmation, then move on.

### Step 3 -- Mini Tracking Plan (2 Events)

For each of the two events, capture:

**Event 1: `sign_up_completed`**
```
Event name:    sign_up_completed
Trigger:       User completes account creation (after DB write, after identify)
Where it fires: [signup handler / endpoint identified in Pre-Flight or asked]
Required properties:
  - sign_up_method (string): "email", "google", "apple", "sso"
  - platform (string): "web", "ios", "android"
Optional properties:
  - referral_source (string): UTM source or referral code if available
Duplication notes: Do not fire on social auth redirect -- only on final account creation
```

**Event 2: [Value Moment event]**
```
Event name:    [inferred from Step 1, e.g. report_generated]
Trigger:       [specific user action]
Where it fires: [handler / endpoint]
Required properties:
  - [2-3 properties inferred from codebase or vertical defaults]
Optional properties:
  - [1-2 additional if obvious]
Duplication notes: [any edge cases]
```

Present both to the user for confirmation. This is a lightweight review, not a formal sign-off -- but it's structured enough that the implementation has clear specs.

### Step 4 -- Project Setup (Minimal)

For Quick Start:
- Confirm the user has one Mixpanel project with a token
- If they can't find it: direct them to mixpanel.com -> Project Settings -> Project Token
- Store the token in the Context Block
- Move on

**Do NOT require for Quick Start:**
- Dev/prod project split (recommend as follow-up)
- Simplified ID Merge verification (it's the default since April 2024)
- Role assignment
- Timezone verification
- Project structure decisions

**One project is acceptable for session one.** Dev/prod split is surfaced in "what's next."

### Step 5 -- Codebase Access Check

**Before proceeding to implementation, confirm codebase access:**

> "Do you have access to the codebase right now, or are you gathering specifications for a developer to implement later?"

**If user has codebase access:**
- Proceed with Step 6 (Implementation + Identity)
- Write code directly into files
- Use Pre-Flight scan results if available

**If user is gathering specs for handoff:**
- Skip to Developer Handoff Spec Generation (after Step 7)
- Collect any remaining technical details:
  - Specific file paths (if they know them)
  - Environment variable naming conventions
  - Code style preferences (async/await vs promises, TypeScript vs JavaScript, etc.)
- Do NOT attempt to write code to files
- Mark context with: `handoff_mode: true`

### Step 6 -- Implementation + Identity

This is the core of Quick Start. The agent writes real code, placed in specific files if Pre-Flight was run.

**Implementation covers:**
1. SDK initialization (with real token from Step 4)
2. Consent gate if EU/CA users flagged in Step 1
3. `sign_up_completed` event call
4. Value Moment event call
5. Basic identity: `identify()` on login/signup, `reset()` on logout

**Use the Quick Start Reference section at the top of `reference.md`** for minimal SDK snippets (init + track + identify/reset) for each platform. These provide the fastest path to working code without navigating the full SDK lifecycle guide.

**Token injection:** Use the real project token from Step 4 -- never write `'YOUR_PROJECT_TOKEN'` if the token is in hand.

**If a codebase scan was run (Pre-Flight):** Do not produce generic code snippets. Write implementation code directly into the specific files identified during the scan.

**Identity approach -- inline with escalation flag:**

For Quick Start, identity is NOT a separate phase. The agent wires in three calls as part of implementation:

```
On signup:  create user in DB -> identify(user.id) -> people.set() -> track('sign_up_completed')
On login:   identify(user.id)
On logout:  reset()
```

This is correct for all complexity levels. It doesn't become *wrong* if complexity is high -- it just becomes *incomplete*.

**The escalation flag:** After wiring basic identity, the agent checks for complexity signals (from Pre-Flight or conversation):

| Signal | What it means |
|---|---|
| Anonymous browsing exists before login | Anonymous-to-authenticated bridging needed |
| Multi-device or multi-platform usage | Cross-device identity testing needed |
| Shared devices or account switching | Reset logic needs careful placement |
| SSO with multiple identity providers | Identity source needs to be stable |

If any signals are present, the agent says:
> "Your basic identity is wired and will work correctly. But I noticed [signal] -- that means there are edge cases we should test before production. Want to do a full identity QA pass now, or come back to it?"

This is an offer, not a gate. The user decides.

### Step 7 -- Verify in Live View

- Deploy to dev environment (or local if no dev exists)
- Open Mixpanel Live View
- Trigger both events
- Confirm they appear with correct properties
- Confirm identity is linking events to the user

**Do not proceed to "what's next" until at least one event is confirmed in Live View.**

### Developer Handoff Spec Generation (No Codebase Access Mode)

**When to use:** User went through Quick Start discovery and planning but doesn't have codebase access (marked with `handoff_mode: true` at Codebase Access Check).

**Generate:** `MIXPANEL_IMPLEMENTATION_SPEC.md` using the template in `reference.md Section Developer Handoff Specification Template`.

**Required content (from Quick Start Context Block):**
- All context gathered during Steps 1-4
- Platform, SDK, tracking method, CDP, consent requirements
- Complete tracking plan: `sign_up_completed` + Value Moment event with full property schemas
- SDK installation commands
- Complete initialization code (with consent gate if required)
- Complete code snippets for both events (not patterns -- actual ready-to-use code with real token)
- Identity flow: where and when to call identify() and reset() with file location hints
- Business context: Value Moment explanation, why it matters, priority
- Step-by-step verification guide with expected Live View results
- Troubleshooting section for common issues

**Fill in the template with:**
- Actual project token (from Step 4)
- Real event names and properties (from Step 3)
- Complete SDK initialization code with platform-specific syntax
- Identity flow code with file hints ("in your auth callback / logout handler")
- Business context for why Value Moment matters
- Next steps recommendations (expand tracking, full ID QA, dev/prod split, governance)

**Save to:** User's current working directory (or ~/Downloads if working directory is unclear).

**Presentation:**
> "I've created a complete implementation specification at [absolute path]. This contains:
> - Complete, copy-paste ready code with your actual project token
> - Step-by-step testing instructions with expected Live View results
> - Business context explaining why [Value Moment] matters
> - Troubleshooting guide for common issues
>
> Share this with your developer -- they won't need any context from our conversation. The spec includes everything needed to implement in 2-4 hours."

**Optional additional artifacts:**
- CSV export of tracking plan (for product managers who prefer spreadsheets)
- Code-only snippets file (for quick reference)

**After generating spec:**
- Skip Step 7 (Verify in Live View) -- developer will do this after implementation
- Skip AGENTS.md creation in Step 8 (it's included in the handoff spec as a template)
- Present next steps modified for handoff context: "After your developer implements this..."

### Step 8 -- Quick Start Wrap-Up

**If codebase access was available (normal implementation path):**

Summarize what was shipped:
> "You now have two events live in Mixpanel -- `sign_up_completed` and `[Value Moment]` -- with basic identity wired in."

**Add Mixpanel tracking guidance to `AGENTS.md` in the project root.** Check if an `AGENTS.md` already exists. If it does, append the Mixpanel analytics section from `AGENTS.md.template` -- do not overwrite existing content from other tools or conventions. If no `AGENTS.md` exists, create one using the full template. In either case, fill in actual values from this session (platform, SDK, token location, events, identity file paths, consent status). This ensures future AI agents know that Mixpanel is the analytics tool and how to add tracking correctly.

Present prioritized next steps:

1. **Add more events** -- Expand tracking plan from the 2-event foundation
2. **Full identity QA** -- Test anonymous bridging, multi-device, edge cases (especially if complexity flags were raised)
3. **Dev/prod project split** -- Create a separate dev project before sending production traffic
4. **Analytics strategy** -- Define KPIs and measurement framework (RAE framework available)
5. **Data governance** -- Set up Lexicon, Data Standards, and Event Approval as you scale

**If Developer Handoff Spec was generated (no codebase access path):**

Confirm the spec location:
> "Your implementation specification is saved at [absolute path]."

Offer additional support:

1. **Generate additional formats?**
   - CSV export of tracking plan (for sharing with product team)
   - Code-only snippets file (for quick developer reference)

2. **Answer implementation questions?**
   - "Which events should the developer prioritize if time is limited?"
   - "What's the expected implementation time?"
   - "How will we verify this is working correctly?"

3. **Schedule follow-up?**
   - After your developer implements, we can:
     - Verify events in Live View together
     - Walk through any issues they encountered
     - Set up Lexicon and Data Standards

Present prioritized next steps (modified for handoff context):

1. **After your developer implements** -- Schedule a follow-up to verify events in Live View
2. **Add more events** -- Expand tracking plan from the 2-event foundation (can create another handoff spec)
3. **Full identity QA** -- Test anonymous bridging, multi-device, edge cases (spec includes ID QA checklist)
4. **Dev/prod project split** -- Create a separate dev project before sending production traffic
5. **Data governance** -- Set up Lexicon, Data Standards, and Event Approval as you scale (included in spec as post-implementation checklist)

Each next step maps to content that already exists in the Full Implementation flow. The user can come back for any of them.

---

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

## Add Tracking Mode

Use when the customer has an existing Mixpanel implementation and wants to extend it with new events.

**Start with:** "What do you want to track? What question are you trying to answer?"

**Then:**

1. **Check existing schema** -- Before designing any new events, review what's already in the project. Check Lexicon or query existing events to understand current naming conventions, existing properties, and enum values. See `reference.md Section Phase 4 -- Adding Events to an Existing Project`.

2. **Design new events** -- Follow the same naming and spec conventions as Phase 4. Reuse existing property names where the same concept applies. Match established naming patterns.

3. **Spec review** -- Present the spec (event name, trigger, properties, types) for the customer's review before writing code.

4. **Implement** -- Write tracking calls using the same SDK and patterns already present in the codebase. If Pre-Flight was run, place code in the exact handler/endpoint files.

5. **Verify** -- Confirm events in Live View with correct properties and identity linkage.

6. **Document** -- Add Lexicon descriptions for all new events and properties. Update `AGENTS.md` in the project root with the new Mixpanel events (add rows to the tracking plan table).

**Mode switching:** If the existing implementation has fundamental issues (identity bugs, naming chaos, missing consent gates), recommend switching to Audit mode first, then returning to Add Tracking.

---

## Implementation Audit Mode

Use when the customer has an existing Mixpanel setup and wants to assess its quality or diagnose issues.

**Diagnose current state:**

1. Review existing events in Lexicon -- check naming consistency, descriptions, volume patterns
2. Check identity setup -- are `identify()` and `reset()` placed correctly?
3. Review tracking plan (if one exists) -- are all planned events implemented? Any gaps?
4. Check for common issues: duplicate events, inconsistent naming, missing super properties, numeric values sent as strings, dynamic event names
5. Check compliance posture -- is consent gated if EU/CA users exist?

**Produce prioritized fixes:**

Rank issues by severity:
- **Critical** (data corruption): identity bugs, consent violations, wrong ID merge mode
- **High** (data quality): duplicate events, naming inconsistencies, missing properties
- **Medium** (maintainability): missing Lexicon descriptions, no governance process
- **Low** (optimization): missing super properties, suboptimal tracking method

**Execute fixes** via Add Tracking mode (for individual events) or Full Implementation mode (for structural overhaul).

---

## Phase Exit Checklists (Gate Review)

These checklists apply to Full Implementation mode. Quick Start uses Live View verification as its primary gate.

**Phase 0 exit**

- Business model summary confirmed with customer.
- CDP/warehouse status, Group Analytics flag, and top business questions captured in Context Block.
- Platform and product type captured from codebase or confirmed via questions.

**Phase 1 exit**

- One named Value Moment confirmed.
- 2-3 KPIs pass the 5M filter.
- KPI-to-business-question linkage is explicit.

**Phase 2 exit**

- Simplified ID Merge setting verified.
- Dev and production projects exist with correct timezone.
- EU/CA (or stricter) consent flag documented.

**Phase 3 exit**

- Customer can distinguish events, event properties, user profiles, and super properties.
- Group Analytics scope confirmed or explicitly out of scope.

**Phase 4 exit**

- `sign_up_completed` and Value Moment event fully specified (trigger + properties).
- Naming conventions validated (`snake_case`, stable values).
- Tracking plan reviewed and approved by product, engineering, and analytics.

**Phase 6 exit**

- Initialization and event calls implemented in codebase.
- At least one event observed in dev Live View.
- Tracking path (SDK/CDP/warehouse) matches discovery decisions.

**Phase 7 exit**

- `identify`, `reset`, and profile/super-property ordering validated.
- ID Management QA checklist passed in dev.
- Multi-device and anonymous-to-auth flows tested where applicable.

**Phase 8 exit**

- Lexicon entries populated for shipped events.
- Data Standards and Event Approval enabled.
- Governance roles named and quarterly review owner assigned.

---

## Communication Habits

**Concrete over generic.** Use the customer's product name, Value Moment name, and their two events (`sign_up_completed` and the Value Moment event) in summaries and next steps. In code and specs, use event and property names from their signed-off tracking plan -- no placeholders once those names are defined. Refer to specific files or flows identified in Pre-Flight when giving implementation guidance.

**Cite docs when recommending a capability.** When you suggest a Mixpanel feature (Lexicon, super properties, Data Standards, Event Approval, consent pattern, warehouse connector, etc.), point to the specific Mixpanel doc or the relevant section in reference.md so the customer can act on it. New customers don't know the product; a link or section reference makes the recommendation actionable.

---

## Current-Docs Verification (Before Hard Assertions)

Before stating hard limits, plan entitlements, or irreversible settings, verify against current Mixpanel docs and the customer's account plan.

Quick verification checklist:

1. Confirm feature availability (Group Analytics, governance features, connectors) for the active plan.
2. Confirm any numeric limits (event names, property constraints, rate limits) from current docs.
3. Confirm irreversible settings (identity mode, timezone implications) before implementation.
4. Record what was verified and source links in working notes when decisions depend on it.

---

## Critical Rules -- Highest-Stakes Implementation Decisions

Get these wrong and the data is permanently corrupted or very expensive to fix. **These rules apply to ALL modes.**

**Project setup:**

- Never track to production before creating and verifying a separate dev/staging project
- Verify Simplified ID Merge is enabled BEFORE sending a single event -- cannot safely change after data exists
- Set project timezone correctly at creation -- cannot change retroactively without affecting historical data

**Identity management:**

- Always call `.identify(user.id)` on EVERY login AND every app re-open while the user is already logged in
- Always call `.reset()` on logout -- failing to do so merges the next user's session with the previous user
- Never use email as `$user_id` -- emails change; use your database primary key
- Never call `.identify()` before creating the user in your database
- Never call `.people.set()` before `.identify()` -- profiles set before identify may not merge correctly
- Track the `sign_up_completed` event AFTER `.identify()`, not before
- Never merge two `$user_id` values -- not supported in Simplified API; use one stable ID from the start
- Do not create User Profiles for anonymous users

**Data model:**

- Never send numeric values as quoted strings -- they become non-aggregatable strings
- Never construct event or property names dynamically at runtime -- creates thousands of unique names
- Never use `$` or `mp_` prefixes on custom event or property names
- Omit properties entirely when they have no applicable value -- do not send `null` or `""`
- Mixpanel is case-sensitive: `checkout_completed` !=  `Checkout_Completed` -- enforce snake_case from day one
- **One event, one meaning** -- do not reuse one event name for two different user actions (e.g. the same "Button Clicked" for nav and checkout); use a specific event per action
- **Avoid duplicate events** -- before creating a new event, check existing events in Lexicon or the project; extend an existing event with a property when possible
- **Property shape** -- prefer flat properties for reporting; avoid nested objects unless the tracking plan explicitly uses list/object types
- **Server + client** -- if the same event can fire from both server and client, ensure consistent `distinct_id`/identity or you will get identity graph issues

**Compliance and privacy:**

- If consent is required and status is unknown, do not initialize non-essential tracking
- Do not forward IP or sensitive attributes when customer policy disallows them
- Prefer data minimization: collect only properties needed to answer agreed business questions

**Governance:**

- Do not begin implementation without a reviewed and signed-off tracking plan (Full Implementation mode)
- Hide events before dropping them -- dropping is irreversible and stops new data ingestion immediately
- Never drop data without a quarter of observation after hiding it

---

## Reference

All detailed guidance is in [reference.md](reference.md), organized by phase heading.

Key sections:

- **Quick Start Reference** -- Minimal SDK snippets (init + track + identify/reset) for each platform
- **Phase 0** -- Discovery questions and gate logic
- **Phase 1** -- Full RAE Framework, Value Moment formula, 5M filter, KPI tables
- **Phase 2** -- Project setup steps, token-switching code, role permissions
- **Phase 3** -- Full data model, property types, Group Analytics code
- **Phase 4** -- Tracking plan methodology, vertical-specific events, template links
- **Phase 5** -- Codebase Access Check
- **Phase 6** -- All SDK code (JS, Python, Node.js, React Native, iOS Swift, Android, HTTP API), CDP/warehouse integration
- **Phase 7** -- Full identity flows (client-side and server-side), QA checklist
- **Phase 8** -- Governance framework, pitfalls table, tracking plan column schema
- **Reference table** -- All key Mixpanel documentation URLs