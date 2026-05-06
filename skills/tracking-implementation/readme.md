# Mixpanel Implementation Skill

Structured guidance for helping Mixpanel customers implement analytics correctly -- from a 15-minute Quick Start to a full production-ready rollout. Supports four modes: Quick Start, Full Implementation, Add Tracking, and Audit.

**This file is for human maintainers.** The agent reads `SKILL.md` at runtime -- not this file.

---

## Architecture

The skill follows the [Agent Skills specification](https://agentskills.io/specification) and uses progressive disclosure across multiple files:

| File | Role | When the agent reads it |
|---|---|---|
| `SKILL.md` | Mode selection, decision rules, guardrails, critical rules, phase exit checklists | Always, at the start of every session |
| `references/quick-start.md` | Complete Quick Start flow (7 steps), context block, handoff spec generation | When Quick Start mode is selected |
| `references/full-implementation.md` | Full Implementation phases (0--7), context block, handoff spec generation, governance | When Full Implementation mode is selected |
| `references/reference.md` | SDK snippets, deep playbooks, all SDK code, vertical-specific examples, QA checklists | On demand, when a mode or phase requires it |
| `assets/agents.md.template` | Template for customer codebase `AGENTS.md` | During wrap-up |

`SKILL.md` stays under 500 lines so it loads quickly and is easy to reason over. Mode-specific flows and SDK code live in `references/` and load on demand.

**Consequence for maintenance:** SDK or API changes -> update `references/reference.md`. Mode flow or phase structure changes -> update the relevant file in `references/`. Only touch `SKILL.md` if mode selection, guardrails, critical rules, or phase exit checklists change.

---

## File Map

- `SKILL.md` -- Mode selection (4 modes), compliance guardrails, Pre-Flight codebase scan, Add Tracking mode, Audit mode, phase exit checklists, communication habits, critical rules, and stubs pointing to detailed reference files
- `references/quick-start.md` -- Quick Start flow (7 steps): mandatory questions, context gathering, mini tracking plan, project setup, implementation + identity, Live View verification, wrap-up, Developer Handoff Spec generation, Context Block schema
- `references/full-implementation.md` -- Full Implementation phases (0--7): Discovery, Analytics Strategy, Project Setup, Data Model, Tracking Plan, Implementation, Identity Management, Data Governance, Developer Handoff Spec generation, Context Block schema
- `references/reference.md` -- Quick Start Reference (minimal SDK snippets per platform), full RAE Framework, all SDK code (JS, Python, Node.js, React Native, iOS Swift, Android Kotlin, Flutter, HTTP API), vertical event examples, tracking plan templates, CDP/warehouse integration notes, identity flow walkthroughs, governance pitfalls, ID Management QA checklist, and Developer Handoff Specification Template
- `assets/agents.md.template` -- Template for the `AGENTS.md` file that gets created in the customer's codebase during wrap-up. The agent fills in actual values (platform, SDK, events, file paths) from the session.
- `readme.md` -- This file; for maintainers only

---

## Modes

The skill asks the customer which mode fits their goal before doing anything else:

| Mode | What it covers | Success criteria |
|---|---|---|
| **Quick Start** | 7-step compressed flow: mandatory questions -> context -> mini tracking plan -> project setup -> implementation + identity -> Live View verification -> wrap-up | Two events live in Mixpanel with basic identity wired in |
| **Full Implementation** | All 8 phases (0--7) in order: Discovery -> Analytics Strategy -> Project Setup -> Data Model -> Tracking Plan -> Implementation -> Identity Management -> Data Governance | Complete production-ready analytics setup with governance |
| **Add Tracking** | Starts with "what do you want to track?" -> checks existing schema -> designs new events -> implements and verifies | New events live with correct naming and identity linkage |
| **Audit** | Diagnoses current state -> produces prioritized fixes -> executes fixes via Add Tracking or Full Implementation | Prioritized fix list with severity ranking |

Mode switching is always an offer, never automatic. Quick Start can escalate to Full Implementation if complexity surfaces. Full Implementation can downshift to Quick Start if the customer wants momentum first.

### No Codebase Access Path

Both **Quick Start** and **Full Implementation** modes support a **Developer Handoff Spec** path for when the user doesn't have codebase access:

- Before implementation (Step 5 / Phase 5), the agent asks: *"Do you have access to the codebase right now, or are you gathering specifications for a developer to implement later?"*
- If gathering specs -> generates `MIXPANEL_IMPLEMENTATION_SPEC.md` instead of writing code to files
- The spec contains: complete copy-paste ready code, business context (Value Moment, KPIs, priority), step-by-step verification guide, troubleshooting section
- **Target audience:** Human developers (not AI agents like `AGENTS.md`)
- **Tone:** Explanatory ("You should X because Y") with business impact of mistakes explained
- **Output:** Quick Start = 2-3 page spec (2-4 hour implementation) / Full Implementation = 10-12 page spec (1-2 day implementation)

---

## Full Implementation Phase Summary

These phases apply to Full Implementation mode only. Quick Start uses Live View verification as its primary gate.

| Phase | Goal | Hard gate |
|---|---|---|
| 0 -- Discovery | Business model, platform, CDP status, business questions | Must complete before Phase 1 |
| 1 -- Analytics Strategy | Named Value Moment + 2--3 KPIs passing the 5M filter | Must complete before Phase 4 |
| 2 -- Project Setup | Simplified ID Merge verified, dev + prod projects created, tokens stored | Must complete before Phase 3 |
| 3 -- Data Model | Customer aligned on events, properties, profiles, super properties | Must complete before Phase 4 |
| 4 -- Tracking Plan | Signed-off event schema for sign_up_completed + Value Moment | Must complete before Phase 5 |
| 5 -- Implementation | All tracking code written; at least one event confirmed in dev Live View | Must complete before Phase 6 |
| 6 -- Identity Management | identify/reset calls placed correctly; ID QA checklist passed in dev | Must complete before Phase 7 |
| 7 -- Data Governance | Lexicon populated, Data Standards enabled, Event Approval enabled | Implementation complete |

---

## Known Limitations

- **No live Mixpanel API access.** The skill cannot query the customer's Mixpanel account, verify project settings, or inspect actual ingested data. It relies on the customer describing their setup.
- **Account plan is unverifiable at runtime.** Feature availability (Group Analytics, Data Standards, Event Approval, warehouse connectors) varies by plan. The skill instructs the agent to verify these against current docs and the customer's account before asserting availability.
- **SDK code may lag behind releases.** Mixpanel ships SDK updates independently of this skill. Always check the current SDK changelog when writing production initialization code.
- **Not legal advice.** The compliance and privacy guardrails in `SKILL.md` are implementation defaults, not legal guidance. Customer policy and counsel are the authoritative source for consent and data residency requirements.
- **No enforcement mechanism.** The skill guides the agent to gate phases and reject shortcuts, but a customer who overrides the agent can bypass any guardrail. The skill documents the risk, not the enforcement.
- **Developer Handoff Spec is unverified.** When no codebase access is available, the generated specification cannot be tested for correctness. The agent fills the template with session context, but cannot verify the code compiles, runs, or produces events in Live View. The developer receiving the spec must validate it.