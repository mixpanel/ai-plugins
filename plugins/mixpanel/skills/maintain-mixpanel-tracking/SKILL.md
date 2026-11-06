---
name: maintain-mixpanel-tracking
description: Audit, extend, or repair an established Mixpanel tracking implementation by reconciling application code with live project schema, preserving existing conventions, making approved fixes or additions, and verifying the result. Use when Mixpanel is already implemented, events already exist, or the user wants to add tracking, diagnose data quality, or review implementation health. Do not use for a first-time greenfield implementation.
license: Apache-2.0
metadata:
  engine: optional
---

# Maintain Mixpanel Tracking

> **Engine optional** — resolve an available engine per [`ENGINE.md`](../../ENGINE.md) and use it to inspect and update the Mixpanel project; code-only review can continue without one and should offer `/mixpanel:install` when live project access would materially improve the work.

Change an established implementation without creating duplicate pipelines or
silently breaking its schema. Read [tracking implementation
safety](../../references/tracking-safety.md) before changing code or Mixpanel.
Use the relevant platform section of the existing [SDK
snippets](../tracking-implementation/references/sdk-snippets.md) only when a
runtime-specific correction is needed.

## Entry rules

- Consume the onboarding handoff and existing tracking plan when supplied. Do
  not repeat general product onboarding.
- Infer whether the user wants an **audit**, **extension**, or **repair** from
  their request. Ask only when the requested outcome is genuinely ambiguous.
- Audits and diagnoses are read-only. Do not implement a fix until the user asks
  for changes or approves a proposed patch.
- If no established pipeline or meaningful project data exists, route to
  `implement-mixpanel`.

## 1. Reconcile code and project state

Inspect both sides before recommending work.

### Codebase

- SDK/CDP/wrapper initialization and environment routing;
- every relevant tracking call and its trigger;
- auth, session restoration, logout, and account switching;
- consent handling;
- client/server overlap, retries, and delivery completion;
- tests and local tracking documentation.

### Mixpanel project

When an engine is available, inspect the intended project's event/property
schema, Lexicon descriptions, recent volume patterns, identity indicators, and
existing reports relevant to the request. Use names, types, enum values, and
project conventions as constraints—not suggestions.

If MCP is absent, strongly recommend it because maintenance depends on comparing
code with live data. Allow the customer to continue with a code-only review and
label live-project conclusions unverified.

## 2. Preserve existing contracts

- Reuse event/property names and allowed values for the same concept.
- Treat renames as migrations, not cleanup. Show affected reports, cohorts,
  dashboards, and downstream consumers when known.
- Do not add a direct SDK beside a CDP or wrapper that already owns delivery.
- Do not change identity mode, project residency, or production routing as an
  incidental fix.
- Never hide, merge, or drop data without a separate impact review and explicit
  confirmation.

## Audit

Use when the user asks for review, assessment, or implementation health.

1. Compare planned events, code triggers, and live schema.
2. Check duplicate paths, unstable/dynamic names, type drift, missing required
   properties, and fictional placeholder values.
3. Review identity across signup/login, session restoration, logout, account
   switching, anonymous-to-authenticated use, and client/server events.
4. Review consent gating, data minimization, residency, and dev/prod routing.
5. Check Lexicon coverage and whether important reports can be built from the
   actual data.

Return findings prioritized as:

- **Critical** — data corruption, consent exposure, wrong production routing,
  or identity merges.
- **High** — duplicates, missing events, wrong triggers, or property type drift.
- **Medium** — inconsistent schema or missing documentation/governance.
- **Low** — optimizations that do not compromise current data.

Include evidence and a scoped remediation for every finding. Stop after the
report unless fixes were requested.

## Extend

Use when the customer wants new events, properties, or a report.

1. Start with the business question and propose the report that answers it.
2. Inspect existing schema and reports before defining anything new.
3. Prefer extending an existing event with a meaningful property when its
   semantics remain unchanged; otherwise define a specific new event.
4. Present the event trigger, source of truth, properties/types, identity, and
   exact code locations.
5. Confirm the specification and request code approval plus separate approval
   for Lexicon/report writes.
6. Implement through the established pipeline, run relevant repository checks,
   and verify representative development traffic.
7. Update Lexicon and create/update the report only after verification and only
   within the approved external-write scope.

## Repair

Use when events are missing, duplicated, mis-typed, misidentified, or sent to
the wrong project.

1. Reproduce or trace the failure from trigger to ingestion.
2. Name the root cause and distinguish observed evidence from inference.
3. Present the smallest patch and its impact on historical versus future data.
4. Get approval before code or Mixpanel changes.
5. Apply the patch, test the affected runtime path, and verify new development
   events in Mixpanel.
6. State what the repair cannot retroactively correct. Do not imply a code fix
   rewrites historical data.

## Completion report

Report every reviewed or approved item:

| Item | Before | Change | Verification |
| --- | --- | --- | --- |
| Event/property/identity flow | Observed state | Fixed / added / unchanged / blocked | Code and live-data evidence |

Also state:

- whether the result is code-only or reconciled with live Mixpanel data;
- which external Mixpanel objects were changed;
- which historical issues remain;
- the next smallest recommended maintenance action.
