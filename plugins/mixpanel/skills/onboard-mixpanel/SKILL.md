---
name: onboard-mixpanel
description: Onboard a customer before Mixpanel tracking work by understanding the product, checking for existing projects, data, and instrumentation, helping connect the Mixpanel plugin or MCP, and routing to greenfield implementation or maintenance. Use when a customer is starting Mixpanel onboarding or their implementation state is unknown. Do not use when a complete tracking specification is already supplied or when the user explicitly asks to change an established implementation.
license: Apache-2.0
metadata:
  engine: optional
---

# Onboard Mixpanel

> **Engine optional** — resolve an available engine per [`ENGINE.md`](../../ENGINE.md) and use it for read-only Mixpanel checks; onboarding continues without one and should offer `/mixpanel:install` when the customer wants MCP or another engine.

Establish enough context and tooling to route the customer. Do not install an
application SDK, edit application code, design a full tracking plan, or mutate a
Mixpanel project in this skill.

## Outcome

Finish with one compact handoff and one route:

- `implement-mixpanel` when no established Mixpanel implementation exists.
- `maintain-mixpanel-tracking` when code, live data, or an established schema
  already exists.

Do not make the customer choose between skills. Determine the route from
evidence, explain it in one sentence, and continue with the selected skill when
it is available.

## 1. Reuse supplied context

If the request includes a product description, implementation specification,
project details, or prior onboarding output, use it. Do not ask the customer to
repeat information already present.

A complete implementation specification should bypass this skill and go
directly to `implement-mixpanel`, unless the codebase or project already has an
established implementation.

## 2. Build a read-only readiness snapshot

Use available evidence before asking questions:

- In the codebase, search manifests, analytics wrappers, environment config,
  initialization, and tracking calls for Mixpanel, CDPs, or other analytics
  systems.
- With an available Mixpanel engine, list accessible projects and inspect only
  enough schema/volume metadata to distinguish an empty project from an active
  implementation.
- Detect whether the Mixpanel plugin and MCP tools are usable in the current
  client. A saved MCP configuration is not a successful connection; verification
  requires a project lookup.

Do not write files or change Mixpanel while taking this snapshot.

## 3. Understand the product

Ask `What does your product do?` only when the answer is not already supplied or
reliably available from a connected source. Capture a concise description of:

- the customer and problem the product serves;
- the core workflow that delivers value;
- the business model or account model when it affects analytics design.

Import existing context before interviewing. If the customer wants persistent
Mixpanel AI business context rather than a session handoff, route that work to
`prepare-ai-readiness`; do not duplicate its write workflow here.

## 4. Strongly recommend MCP

Explain the concrete benefit:

> Connect the Mixpanel MCP so I can inspect the intended project, verify incoming
> data, organize events and properties in Lexicon, and create the final report
> directly. We can still plan and implement code without it.

- If MCP is already usable, verify it with a project lookup and do not ask again.
- If the customer accepts setup and the plugin is installed, use
  `/mixpanel:install` and choose the MCP path. Complete authentication and
  verification before continuing.
- If this skill was supplied as a standalone raw file and the plugin is absent,
  offer the current client's supported plugin installation first. If the client
  has no plugin mechanism, help connect MCP directly using documented setup.
- If the customer skips, record `MCP: skipped` and continue without pressure.
- If setup requires a restart, give an exact resume instruction and stop. Do not
  claim the connection succeeded before a project lookup works.

## 5. Route from evidence

Use this order:

1. Existing Mixpanel initialization/tracking calls or an established analytics
   wrapper feeding Mixpanel → `maintain-mixpanel-tracking`.
2. Meaningful existing event data or an established Lexicon schema →
   `maintain-mixpanel-tracking`, even if this repository has no tracking code.
3. No implementation and no meaningful data → `implement-mixpanel`.
4. Conflicting evidence → prefer maintenance so the next skill reconciles code
   and project state before adding anything.

Do not use a newly created empty project or a single onboarding test event as
proof of an established implementation.

## 6. Produce the handoff

Pass this block to the selected skill and retain unknowns explicitly:

```markdown
## Mixpanel onboarding handoff
- Product: <one-paragraph description>
- Context source: <customer / supplied document / codebase / connected source>
- Plugin: <available / unavailable / unknown>
- MCP: <connected and verified / skipped / unavailable>
- Mixpanel project: <name + id, or unresolved>
- Data residency: <US / EU / India / unknown>
- Existing project data: <none / onboarding-only / established / unknown>
- Existing code pipeline: <none / Mixpanel SDK / CDP or wrapper / unknown>
- Codebase platform: <stack or unknown>
- Recommended route: <implement-mixpanel / maintain-mixpanel-tracking>
- Evidence: <short list supporting the route>
- Open questions: <only unresolved facts the next skill actually needs>
```

When the selected skill is not installed, tell the customer to install the
Mixpanel plugin or load the corresponding skill:

- [`implement-mixpanel`](https://github.com/mixpanel/ai-plugins/blob/main/plugins/mixpanel/skills/implement-mixpanel/SKILL.md)
- [`maintain-mixpanel-tracking`](https://github.com/mixpanel/ai-plugins/blob/main/plugins/mixpanel/skills/maintain-mixpanel-tracking/SKILL.md)

The receiving skill must consume this handoff without repeating onboarding.
