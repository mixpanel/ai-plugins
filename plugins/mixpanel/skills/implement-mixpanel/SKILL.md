---
name: implement-mixpanel
description: Implement Mixpanel tracking for a product that does not yet have an established Mixpanel instrumentation pipeline. Starts from the product's value moment and key report, derives the minimum events and properties, implements them in the codebase, verifies development data, and organizes Lexicon. Use for greenfield Mixpanel implementation or a supplied tracking specification. Do not use to add, audit, or repair tracking in an established implementation; use maintain-mixpanel-tracking instead.
license: Apache-2.0
metadata:
  engine: optional
---

# Implement Mixpanel

> **Engine optional** — resolve an available engine per [`ENGINE.md`](../../ENGINE.md) and use it for project lookup, verification, Lexicon, and report work; implementation can continue without one and should offer `/mixpanel:install` when the customer chooses to connect MCP.

Create the smallest correct implementation that powers a report the customer
cares about. The visible conversation follows product → value moment → report →
events → properties → approval → implementation → verification.

Read [tracking implementation safety](../../references/tracking-safety.md)
before changing code. Read only the relevant platform section of the existing
[SDK snippets](../tracking-implementation/references/sdk-snippets.md) when a
concrete SDK pattern is needed; adapt it to the repository instead of pasting a
generic example.

## Entry rules

- Consume a `Mixpanel onboarding handoff` without re-running onboarding.
- When a supplied implementation specification already defines the events,
  properties, and project, skip product/report discovery that it answered.
- Always inspect the codebase before changing it. If an established Mixpanel
  implementation or pipeline is found, stop and route to
  `maintain-mixpanel-tracking`.
- Do not ask the customer to choose Quick Start versus Full Implementation.
  Scope the first implementation to the minimum events required for the agreed
  report; propose later expansion after that slice is verified.

## 1. Silent codebase preflight

Inspect route/page files, controllers or endpoints, data models, auth/session
flows, package manifests, environment conventions, and existing analytics. Use
the scan to determine:

- platform and runtime;
- whether a CDP, warehouse, tag manager, or analytics wrapper already owns the
  pipeline;
- candidate sources of truth for the product's core actions and properties;
- exact initialization, event, login/session-restore, and logout locations;
- whether browser code runs in an SSR framework.

Carry these findings forward as proposals. Ask only for business or policy facts
the repository cannot answer.

## 2. Confirm the product

If no onboarding handoff or supplied context answers it, ask:

> What does your product do?

Summarize the answer in one or two sentences and ask for correction. Do not run a
long business interview.

## 3. Strongly recommend MCP

If MCP is not already connected and verified, explain:

> Connect the Mixpanel MCP so I can select the right project, verify the events,
> update Lexicon, and create the report directly. We can still implement the
> code without it.

If the customer accepts, use `/mixpanel:install` and finish verification before
continuing. If they skip, do not offer again in the same session. Never treat
MCP as the Mixpanel application SDK.

## 4. Propose the value moment

Infer the action that demonstrates realized user value from the product context
and codebase. Lead with a recommendation rather than an open-ended question:

> Based on how the product works, the value moment appears to be **<action>**
> because **<reason>**. Does that sound right?

Revise until the customer confirms one observable action. Do not confuse a page
view, signup, or internal system activity with realized value unless that truly
is the product's value moment.

## 5. Design the key report first

Propose the first report that would reveal whether users reach the value moment.
State:

- the business question;
- report type (for example funnel, retention, or trend);
- start and success actions;
- population, time window, and useful breakdown;
- the decision the customer can make from it.

Then derive only the events required to power that report. Usually this includes
an entry/activation event and the confirmed value-moment event, but do not force
`sign_up_completed` into products where it is irrelevant.

Ask:

> This report would answer **<question>**, which requires **<events>**. How does
> that look?

Do not create the saved report before its underlying events have been observed.

## 6. Specify events and properties

For every proposed event, present:

| Field | Required detail |
| --- | --- |
| Event | Stable `snake_case` name |
| Trigger | Exact observable condition |
| Source | File/handler or external system that knows it happened |
| Properties | Name, type, allowed values, and why the report needs it |
| Identity | Anonymous or authenticated ID available at the trigger |

Classify anything without a source of truth as blocked or out of scope. Confirm
the event specification with the customer before editing code.

## 7. Resolve one-way-door facts and request approval

Use the preflight, handoff, and connected project first. Ask only unresolved
items, but always confirm the customer's consent requirement before SDK
initialization. Resolve:

- pipeline ownership (direct SDK versus CDP/wrapper);
- development project and token;
- data residency;
- consent gate;
- stable user ID plus login, session restore, logout, and account switching;
- Autocapture and Session Replay preference for supported web implementations.

Show the files and external Mixpanel changes you propose, then ask:

> Can I implement this approved plan in the codebase? After the events are
> verified, may I also update their Lexicon descriptions and create the agreed
> report in Mixpanel?

Record code approval and Mixpanel-write approval separately. Without code
access, generate a developer handoff specification instead of pretending to
implement.

## 8. Implement the approved slice

- Follow the repository's dependency, configuration, and wrapper conventions.
- Put tracking at the real source of truth, after the action succeeds.
- Implement initialization, consent, identity, and logout/session restoration
  required by the approved slice.
- Use the existing CDP/wrapper rather than installing another SDK when it owns
  the pipeline.
- Add or update meaningful tests around wrappers and trigger placement, then run
  the repository's relevant checks.

Do not expand into unapproved events merely because nearby actions are easy to
instrument.

## 9. Verify and organize

1. Send representative sample traffic only to the confirmed development
   project.
2. Confirm every implemented event in Live View or an equivalent live query,
   including properties, types, identity, and residency/project.
3. With Mixpanel-write approval and a capable engine, add clear Lexicon
   descriptions for the verified events and properties. Without it, return the
   proposed descriptions for manual application.
4. Create the agreed report only after the events are visible. If report
   creation is unavailable, return an exact report specification.

Do not report success based only on a build or unit test.

## Completion report

Cover the entire approved plan:

| Item | Status | Evidence or next action |
| --- | --- | --- |
| Each event | Instrumented / blocked / omitted | File and trigger or reason |
| Development data | Verified / unverified | What was observed |
| Identity | Verified / partial / unverified | Flows exercised |
| Lexicon | Updated / proposed / skipped | Project or handoff |
| Key report | Created / specified / blocked | Link or configuration |
| MCP | Connected / skipped / unavailable | Verification result |

End with the next smallest useful tracking slice, not a broad analytics roadmap.
