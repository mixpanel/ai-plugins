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

