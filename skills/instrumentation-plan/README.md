# Instrumentation Plan

A Mixpanel skill that turns product context — PRDs, user journeys, business questions, or feature briefs — into a structured tracking plan before any engineering work starts.

## What this skill does

Takes one of four input types from a customer:

1. **PRD or feature spec** — paste it, get an event list mapped to the spec
2. **User journey** — describe the flow, get state-transition + action events
3. **Business question** — "where do users drop off?" → reverse-engineered funnel events
4. **Launch brief** — short feature scope, get the minimum events to answer adoption / engagement / outcome

Then it pulls the customer's existing Mixpanel Lexicon to detect naming conventions, designs events and properties that fit alongside what's already there, and produces:

- A prioritized tracking plan (Markdown for engineering handoff, XLSX for team tracking)
- Ready-to-paste SDK code templates matching the customer's stack
- Optional Lexicon write-back with explicit confirmation

The customer owns their taxonomy. Nothing gets written to Lexicon without showing the exact diff and getting a "yes, proceed."

## When to use this skill

Triggers on phrases like:
- "What should we track?"
- "Design our events for [feature]"
- "Tracking plan for [product/feature]"
- "We're starting fresh with Mixpanel"
- "Instrumentation for [launch]"
- "Translate this PRD into events"

Also triggers when a customer pastes a PRD, user journey, feature brief, or business question and asks how to instrument it.

## When NOT to use this skill

- **Auditing existing tracking in code** → use `instrumentation-planner` instead. That skill scans a codebase and finds gaps. This skill plans tracking that doesn't exist yet.
- **Adding a single known event** → use the `implement` skill instead.

## How it's different from `instrumentation-planner`

| | `instrumentation-plan` | `instrumentation-planner` |
|---|---|---|
| **Input** | PRD / journey / question / brief | Source code |
| **Customer state** | No tracking yet, or new feature | Existing tracking in production |
| **Core output** | Tracking plan from scratch | Gap analysis + diff |
| **Phase 1 focus** | Lexicon convention detection | Code scan + Lexicon cross-reference |
| **Best for** | Greenfield, new launches, PRDs | Audits, cleanup, legacy projects |

The two skills are designed to be used together over an account's lifecycle: `instrumentation-plan` for the foundation, `instrumentation-planner` for the audit six months later.

## Requirements

- **Mixpanel MCP** connected to the customer's project
- Customer must have access to their own Mixpanel project
- For the SDK code generation step: customer needs to share what stack they're on (web / iOS / Android / server / CDP)

## Workflow at a glance

```
Phase 0 — Orient & Verify
  ├── MCP connectivity check (hard stop if MCP unavailable)
  └── Intake: project, input type, scope, core question, stack, owner

Phase 1 — Lexicon Pull & Convention Detection
  ├── Pull existing Lexicon (targeted query)
  ├── Detect naming convention from existing events
  └── Greenfield foundation (canonical templates) if Lexicon is empty

Phase 2 — Translate Input to Events
  ├── 2A: From a PRD
  ├── 2B: From a user journey
  ├── 2C: From a business question (reverse-engineer funnel)
  ├── 2D: From a launch brief
  ├── 2E: Properties design (with PII guardrails)
  ├── 2F: User profile properties (people.set)
  └── 2G: Super properties

Phase 3 — Present Plan & Confirm
  └── Customer picks: full pipeline / code only / Lexicon only / walk-through / hold

Phase 4 — Generate Code & Document
  ├── 4A: SDK code templates (skipped for CDP stacks)
  ├── 4B: Lexicon write-back (only if confirmed)
  └── 4C: Markdown + XLSX outputs
```

## Outputs

**Tracking plan markdown** — `TRACKING_PLAN.md` with:
- Question this plan answers
- Super properties table
- User profile properties table
- Events grouped by priority, with triggers, properties, and Lexicon URLs

**Tracking plan XLSX** — `tracking_plan.xlsx` with three sheets:
- Tracking Plan (one row per property, filterable)
- Super Properties
- User Profile Properties

**SDK code templates** — placement-specific, ready-to-paste calls matching the customer's SDK and (where applicable) their analytics wrapper.

## Guardrails built in

- **PII detection** — refuses to track email / full name / phone as event properties; flags PII appearing in customer input
- **Naming convention enforcement** — forces a decision before generating events when Lexicon has mixed conventions
- **Super property conflict prevention** — flags any proposed property that overlaps with a registered super property
- **No silent Lexicon writes** — every write requires explicit customer confirmation showing the exact diff
- **Wrapper preservation** — generated SDK code matches the customer's wrapper interface; never bypasses with raw SDK calls
- **Scope discipline** — pushes back on 30+ event plans for v1; recommends starting with 5–10 decision-relevant events

## Installation

1. Download `instrumentation-plan.skill`
2. In Claude.ai, go to Settings → Capabilities → Skills
3. Upload the `.skill` file
4. The skill will trigger automatically on relevant prompts; you can also invoke it explicitly by name

## Files in this package

- `instrumentation-plan.skill` — the installable skill bundle
- `SKILL.md` — the standalone skill definition (same content, unpacked)
- `README.md` — this file

## Author & maintenance

Built for the Mixpanel CSA team. Companion to `instrumentation-planner` (codebase audit skill). For questions, feedback, or issues, reach out to the CSA team.
