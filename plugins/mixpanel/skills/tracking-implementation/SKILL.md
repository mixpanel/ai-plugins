---
name: tracking-implementation
description: Guides a coding agent through helping a Mixpanel customer implement analytics correctly. Covers Quick Start (first events in one session), Full Implementation (complete production-ready setup), Add Tracking (extend existing implementation), and Implementation Audit. Use when a user wants to implement Mixpanel, set up Mixpanel, add Mixpanel tracking, configure a new Mixpanel project, or is a Mixpanel customer starting or extending their implementation.
license: Apache-2.0
metadata:
  engine: optional
---

For any reference to `agents.md.template`, use this resource: [agents.md.template](assets/agents.md.template).

For any reference to `reference.md`, use this resource: [reference.md](references/reference.md).

For any reference to `sdk-snippets.md`, use this resource: [sdk-snippets.md](references/sdk-snippets.md).

# Mixpanel Implementation

> **Engine optional** — the core flow (SDK code generation, Live View verification) needs no engine. When schema lookups or post-deploy query checks come up, use an available engine per [`ENGINE.md`](../../ENGINE.md); otherwise use the documented fallbacks (direct the customer to Mixpanel Reports and Lexicon). Never stop for a missing engine.

CRITICAL -- DO NOT WRITE ANY CODE YET

**This skill is a guided conversation, not a build template.** You MUST collect answers from the user before generating any implementation code. Writing Mixpanel code without the inputs below will produce a broken implementation -- wrong SDK, wrong events, missing consent gates, or duplicate data pipelines.

**One exception:** if the request already arrived with a finished tracking plan (events, properties, and a project token -- typically in a context block from Mixpanel's in-product onboarding), the answers below were already collected elsewhere. Take them from the spec instead of asking, and go to **Implement From Spec Mode**. Consent (item 4) is the one input that is still always asked, because the in-product flow deliberately does not collect it.

**Before writing ANY code, you must know ALL of the following:**

1. Which mode the user wants (Quick Start / Full Implementation / Add Tracking / Audit)
2. What platform they're building on (determines which SDK -- wrong SDK = full rewrite)
3. Whether they use a CDP like Segment (if yes, direct SDK installation is wrong -- data must route through the CDP)
4. Whether they have EU or California users (if yes, events fired before consent = compliance violation requiring data deletion)
5. What their Value Moment is -- the most important user action (you can't write tracking code without knowing what to track)
6. For web/JavaScript platforms: whether they want Autocapture and/or Session Replay enabled -- if Autocapture is on, do NOT also set `track_pageview: true` or write manual page view events (duplicates)

**If you do not have explicit answers to items 2--6, ASK. Do not assume. Do not infer from the project name. Do not start building.** (Item 6 applies only when the platform is web/JavaScript -- skip it otherwise.)

The sections below tell you what to ask, in what order, and what to do with the answers. Follow the conversation flow -- it exists because wrong assumptions here create irreversible rework.

---

Full guidance, vertical-specific event examples, and governance detail are in [reference.md](references/reference.md). All per-language SDK code snippets are in [sdk-snippets.md](references/sdk-snippets.md). Read specific sections on demand as you work through each mode.

---

## Mode Selection -- Ask First

### Skip Mode Selection entirely if a spec already arrived

**Check this before asking anything.** If the incoming request already carries a tracking plan -- a list of events with properties, plus a project token, typically inside a context block -- then discovery has already happened somewhere else (usually Mixpanel's in-product onboarding). Do not run Mode Selection. Do not run Phases 0--4. Go to **Implement From Spec Mode** below.

Signals that a spec arrived:

- A context block with fields like `Value Moment`, `CDP in use`, `Tracking method`, `Prod project token`
- An explicit instruction not to re-run discovery
- A named event list with property types and allowed values already specified

Re-interrogating one of these users is the single worst failure mode of this skill. They came to their coding agent specifically to stop answering questions.

### Otherwise, ask which mode fits their goal:

> "What brings you here today?"
>
> 1. **Quick Start** -- Get your first events into Mixpanel in one session
> 2. **Full Implementation** -- Build a complete, production-ready analytics setup from scratch
> 3. **Add Tracking** -- Extend an existing Mixpanel implementation with new events
> 4. **Audit** -- Review and diagnose an existing implementation

State the selected mode explicitly and offer to switch at any point.

### Mode mapping

| Mode | What it covers | Detail section |
| --- | --- | --- |
| **Quick Start** | 7-step compressed flow: mandatory questions -> context -> mini tracking plan -> project setup -> implementation + identity -> Live View verification -> wrap-up | Quick Start Flow (below) |
| **Full Implementation** | All 8 phases (0--7) in order: Discovery -> Analytics Strategy -> Project Setup -> Data Model -> Tracking Plan -> Implementation -> Identity Management -> Data Governance | Full Greenfield Rollout (below) |
| **Add Tracking** | Starts with "what do you want to track?" -> checks existing schema -> designs new events -> implements and verifies | Add Tracking Mode (below) |
| **Audit** | Diagnoses current state -> produces prioritized fixes -> executes fixes via Add Tracking or Full Implementation | Implementation Audit Mode (below) |
| **Implement From Spec** | Not user-selectable -- entered automatically when a tracking plan arrives with the request. Pre-Flight -> Phase 6 -> Phase 7 -> Live View -> Phase 8. Skips Mode Selection and Phases 0--4. | Implement From Spec Mode (below) |

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
| --- | --- |
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
| --- | --- |
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

## Implement From Spec Mode

Use when a tracking plan arrived with the request (see the entry check under Mode Selection). Discovery already happened in another surface. Your job is implementation and honest reporting, not re-design.

**Flow:** Pre-Flight codebase scan -> the three questions below -> Phase 6 (Implementation) -> Phase 7 (Identity) -> Live View verification -> Phase 8 (`AGENTS.md`).

Every phase you need already exists elsewhere in this skill. This mode is an entry point, not new content. Read the referenced phase sections as you reach them.

### Do not re-ask what the spec answered

Take whatever the context block provides -- typically Value Moment, CDP status, data residency, and tokens -- and do not re-ask it.

**The block may be partial, and that is normal, not an error.** Resolve any absent field in this order:

1. **Pre-Flight** -- if the codebase scan already answered it (platform, existing analytics tools, framework)
2. **This skill's own default** -- Simplified ID Merge follows the org-default rule in Critical Rules; Group Analytics is out of scope unless the plan's events reference a group key
3. **Ask** -- data residency (a wrong host fails silently), Autocapture and Session Replay on web platforms (the customer's call, and the answer changes the init config -- when asking, explain the value using the "Autocapture and Session Replay check" script in [quick-start.md](references/quick-start.md), don't just name the features), and consent (always asked regardless, below)

Never treat a missing field as something to guess, and never stall the whole mode because the block is thin. A spec with just an event list and a token is enough to start.

### Three questions you MUST still ask

These are facts about the codebase and about the business that no upstream product flow can know.

**1. Consent -- ALWAYS ask, no exceptions.**

Mixpanel's in-product onboarding deliberately does not collect this, so the context block will not carry it. Whether the field is absent, `not collected`, or `unknown`: **stop and ask before you initialize the SDK.**

> "Do you have users in the EU, UK, or California?"

Do not infer it from the codebase, the company name, or the domain TLD. If the customer doesn't know, treat the answer as yes and apply the consent gate. Events fired before consent are a compliance violation requiring data deletion -- this is the one question in this mode that has a legal consequence, and the "do not re-run discovery" instruction never overrides it.

**2. Is another analytics tool already installed?**

Check for Segment, GTM, RudderStack, PostHog, Amplitude, or an existing Mixpanel install. If you find one, **stop and ask** rather than adding a second parallel pipeline. Two pipelines to the same project produce duplicate events and an unfixable identity graph.

**3. Is this server-rendered?**

Determines whether browser SDK initialization needs a client-only boundary. See the SSR rule in Critical Rules -- getting this wrong breaks the build, not just the tracking.

### Which events have no source of truth here?

Before writing anything, classify every event in the spec against the codebase:

| Classification | Meaning |
| --- | --- |
| **Implementable here** | A handler, route, or lifecycle hook in this repo fires at the right moment |
| **Backend confirmation** | The trigger is a server-side or out-of-band confirmation (a job, a webhook, a crawler, a beacon) that may live in a different service entirely |
| **No source of truth** | Nothing in this repo knows when this happens |

Specs generated from a product conversation routinely contain events of the second and third kind -- "backend confirms serving," "integration test passed," "experience published." Wiring the client-triggerable subset and reporting the full list as done is the most common failure in this mode. Do not do it.

Same rule for properties: if a property has no source of truth, omit it. Do not send `"unknown"`, `""`, `null`, `0`, or `-1`. Six correct events beat ten where four are fiction.

### Required closing report

End the mode with a table covering **every** event in the spec -- no silent omissions:

| Event | Status | Detail |
| --- | --- | --- |
| `sign_up_completed` | Instrumented | `app/auth/signup.ts:47` |
| `experience_seen` | Blocked | Backend confirms serving; no such handler in this repo |
| `installation_method` | Omitted | No source of truth for this property |

Plus one of:

- **Live View confirmed** -- you ran the app, triggered at least three events, and saw them arrive. Paste what you saw.
- **Could not run the app** -- say so explicitly, and say why.

Never report success on a compile. A build that compiles is fully compatible with a wrong token, a wrong region host (see the data residency rule), and an ad-blocked SDK.

---

## Quick Start Flow

7-step compressed flow: mandatory questions -> context -> mini tracking plan -> project setup -> implementation + identity -> Live View verification -> wrap-up. Success = two events live in Mixpanel with basic identity wired in.

**Read [quick-start.md](references/quick-start.md) for the complete Quick Start flow.**

---

## Full Greenfield Rollout (Phases 0--7)

All 8 phases in order: Discovery -> Analytics Strategy -> Project Setup -> Data Model -> Tracking Plan -> Implementation -> Identity Management -> Data Governance. Each phase gates the next. Includes Context Block schema, Developer Handoff Spec generation for no-codebase-access scenarios, and full close/wrap-up.

**Read [full-implementation.md](references/full-implementation.md) for all phases.**

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

- Simplified ID Merge setting verified. (Feasible here because Phase 2 is where projects get created -- this is a Full Implementation gate, not a universal one. Quick Start and Implement From Spec use the default instead; see Critical Rules.)
- Dev and production projects exist with correct timezone.
- EU/CA (or stricter) consent flag documented.

**Phase 3 exit**

- Customer can distinguish events, event properties, user profiles, and super properties.
- Group Analytics scope confirmed or explicitly out of scope.

**Phase 4 exit**

- `sign_up_completed` and Value Moment event fully specified (trigger + properties).
- Naming conventions validated (`snake_case`, stable values).
- Tracking plan reviewed and approved by product, engineering, and analytics.

**Phase 5 exit**

- Codebase access status confirmed and communicated to the user.
- If access confirmed: explicitly stated "Phase 5 done -- moving to Phase 6: Implementation."
- If no access: explicitly stated "Phase 5 done -- skipping Phases 6 and 7, generating Developer Handoff Spec instead." Handoff details (file paths, env conventions, code style) collected and `handoff_mode: true` marked in Context Block.

**Phase 6 exit**

- Initialization and event calls implemented in codebase.
- At least one event observed in dev Live View.
- Tracking path (SDK/CDP/warehouse) matches discovery decisions.
- If web platform and Autocapture enabled: `autocapture: true` set in init; `track_pageview` omitted; no manual page view `track()` calls written.
- If Session Replay enabled: `record_sessions_percent` set; at least one session observed in Mixpanel Session Replay in dev.

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
- **Simplified ID Merge** is the default for **organizations** created after April 2024. Do not block implementation to verify it. Stop and confirm before sending events only if: the organization predates April 2024, the project already contains event data, or the context block says `Simplified ID Merge: not verified`. The Identity API version cannot be changed once any data exists in the project, and it is org-scoped -- a project created today inside an older org can still be on Original ID Merge. ([docs](https://docs.mixpanel.com/docs/tracking-methods/id-management))
- Set project timezone correctly at creation -- cannot change retroactively without affecting historical data
- **Data residency** -- an EU- or India-resident project left on the default host sends every event nowhere and reports no error. Set `api_host` to match the project's residency:

  | Residency | `api_host` |
  | --- | --- |
  | US (default) | `https://api.mixpanel.com` |
  | EU | `https://api-eu.mixpanel.com` |
  | India | `https://api-in.mixpanel.com` |

  If residency is unknown, ask. A wrong host fails silently -- you cannot detect this from the code, and "it compiles" tells you nothing. Mixpanel's own docs are explicit: no data is ingested into a residency project unless the SDK points at that region's endpoint. ([EU](https://docs.mixpanel.com/docs/privacy/eu-residency), [India](https://docs.mixpanel.com/docs/privacy/in-residency))

**Platform and runtime -- the failures that only appear in production:**

- **SSR and bundling** -- `mixpanel-browser` imported at module scope in a server component throws at build or render time. "Initialize on app boot" has no single meaning in a server-rendered framework, so do not treat it as an instruction you can follow literally. In Next.js App Router, Remix, SvelteKit, Nuxt, or any SSR setup you must: (1) put initialization behind a client-only boundary (`'use client'`, a dynamic import with `ssr: false`, or the framework's equivalent), (2) guard with `typeof window !== 'undefined'`, and (3) make init run **once** -- module-level flag or a ref -- so HMR and client-side route changes don't re-init. This is the most likely place the build actually breaks rather than the tracking quietly misbehaving.

- **Server SDK flush in short-lived processes** -- server SDKs buffer events and flush on an interval. Any process that exits before the interval elapses drops those events **with no error**: serverless functions (Lambda, Cloud Functions, Vercel/Netlify functions), cron jobs, CLI scripts, queue workers that exit per message, and request handlers that return immediately. Always `await` an explicit flush before the process or handler returns. This works fine in a long-running dev server and fails silently in production, which makes it nearly invisible in testing -- so add the flush when you write the code, not after someone notices missing data.

- **Deterministic `$insert_id` on server-side events** -- `$insert_id` is already required for server-side deduplication elsewhere in this skill, but a random value defeats it. Derive it deterministically from the logical occurrence, so a retry of the same logical event produces the same key: `` `subscription_upgraded-${subscription_id}-${billing_period}` ``, not a UUID generated at call time. Retried webhooks, at-least-once queues, and re-run jobs are exactly the traffic that needs this.

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
- Mixpanel is case-sensitive: `checkout_completed` != `Checkout_Completed` -- enforce snake_case from day one
- **One event, one meaning** -- do not reuse one event name for two different user actions (e.g. the same "Button Clicked" for nav and checkout); use a specific event per action
- **Avoid duplicate events** -- before creating a new event, check existing events in Lexicon or the project; extend an existing event with a property when possible
- **Autocapture and page views are mutually exclusive** -- if `autocapture: true` is set in the JS SDK init, do NOT also set `track_pageview: true` and do NOT write manual `track('page_viewed', ...)` calls; autocapture already fires page view events and combining them produces duplicates
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

All detailed guidance is in [reference.md](references/reference.md), organized by phase heading.

Key sections:

- **Quick Start Reference** -- Points to [sdk-snippets.md](references/sdk-snippets.md) for minimal SDK snippets (init + track + identify/reset) for each platform
- **Phase 0** -- Discovery questions and gate logic
- **Phase 1** -- Full RAE Framework, Value Moment formula, 5M filter, KPI tables
- **Phase 2** -- Project setup steps, token-switching code, role permissions
- **Phase 3** -- Full data model, property types, Group Analytics code
- **Phase 4** -- Tracking plan methodology, vertical-specific events, template links
- **Phase 5** -- Tracking method selection, SDK detection, consent patterns, CDP/warehouse integration; all per-SDK code (JS, Python, Node.js, React Native, iOS Swift, Android, Flutter, HTTP API) is in [sdk-snippets.md](references/sdk-snippets.md)
- **Phase 6** -- Full identity flows (client-side and server-side), QA checklist
- **Phase 7** -- Governance framework, pitfalls table, tracking plan column schema
- **Reference table** -- All key Mixpanel documentation URLs
