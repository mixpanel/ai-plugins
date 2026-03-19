---
name: mixpanel
description: Core Mixpanel platform guidance — MCP tool reference, core concepts, skill routing, and common pitfalls.
---

# Mixpanel

Mixpanel is a product analytics platform for tracking user behavior, measuring conversion, and understanding retention across web and mobile applications.

## Which Skill to Use

| I want to...                                                        | Use skill         |
| ------------------------------------------------------------------- | ----------------- |
| Design and run A/B tests or experiments                             | `experiments`     |
| Create feature flags for gradual rollouts                           | `feature-flags`   |
| Create saved metrics for experiments or dashboards                  | `metrics`         |
| Add tracking to my codebase                                         | `implement`       |
| Design a tracking plan for a new feature                            | `tracking-plan`   |
| Query data — trends, funnels, retention, dashboards                 | `analysis`        |
| Audit and manage Lexicon — descriptions, owners, tags, stale events | `data-governance` |
| Scan for PII in event and user properties                           | `pii-review`      |
| Triage and fix data quality issues                                  | `issue-triage`    |

## MCP Tool Reference

### Experiments & Feature Flags

| Goal                        | Tool                        |
| --------------------------- | --------------------------- |
| List experiments            | `Get-Experiments`           |
| View experiment details     | `Get-Experiment-Details`    |
| Create experiment           | `Create-Experiment`         |
| Update experiment           | `Update-Experiment`         |
| Launch/conclude experiment  | `Manage-Experiment-State`   |
| List feature flags          | `Get-Feature-Flags`         |
| View feature flag details   | `Get-Feature-Flag-Details`  |
| Create feature flag         | `Create-Feature-Flag`       |
| Update feature flag         | `Update-Feature-Flag`       |
| Enable/disable feature flag | `Manage-Feature-Flag-State` |

### Metrics

| Goal                   | Tool                 |
| ---------------------- | -------------------- |
| List saved metrics     | `Get-Metrics`        |
| View metric definition | `Get-Metric-Details` |
| Create saved metric    | `Create-Metric`      |
| Update saved metric    | `Update-Metric`      |
| Delete saved metric    | `Delete-Metric`      |

### Events & Properties

| Goal                             | Tool                                                       |
| -------------------------------- | ---------------------------------------------------------- |
| Discover what events exist       | `Get-Events` (use `query` to filter)                       |
| Get properties for an event      | `Get-Property-Names` (resource_type: Event, event: "Name") |
| Get user profile properties      | `Get-Property-Names` (resource_type: User)                 |
| Get sample values for a property | `Get-Property-Values`                                      |
| Document events/properties       | `Edit-Event`, `Edit-Property`                              |

### Queries & Reports

| Goal                       | Tool                                                  |
| -------------------------- | ----------------------------------------------------- |
| Trend / segmentation query | `Run-Segmentation-Query` or `Run-Query` (insights)    |
| Funnel conversion          | `Run-Funnels-Query` or `Run-Query` (funnels)          |
| User path analysis         | `Run-Query` (flows)                                   |
| Retention / return rate    | `Run-Retention-Query` or `Run-Query` (retention)      |
| Engagement frequency       | `Run-Frequency-Query`                                 |
| Build a dashboard          | `Run-Query` (skip_results: true) → `Create-Dashboard` |
| Get query schema           | `Get-Query-Schema` (insights/funnels/flows/retention) |

### Data Governance

| Goal                | Tool              |
| ------------------- | ----------------- |
| Data quality issues | `Get-Issues`      |
| Lexicon deep-link   | `Get-Lexicon-URL` |

For complex queries with breakdowns, formulas, or multiple metrics, call `Get-Query-Schema` first — it returns the full JSON schema for the chosen report type.

## Core Concepts

### Events

An event is a discrete user action. Each event has:

- **Event name** — what happened (e.g. `Form Submitted`, `Dashboard Loaded`)
- **Properties** — context about the event (`plan_type`, `item_count`)
- **Distinct ID** — who did it
- **Timestamp** — when it happened

Event names are **case-sensitive**. `Form Submitted` ≠ `form submitted`.

### Identity

- Users start anonymous with a random `distinct_id`
- On login or signup, call `identify(userId)` to link anonymous → authenticated
- Call `identify()` once per session, not on every page load
- Never identify with a non-unique value (email, device ID)
- Use `people.set()` for persistent user profile attributes after `identify()`

### Property Types

| Type                  | Description                                          | Example                  |
| --------------------- | ---------------------------------------------------- | ------------------------ |
| Event property        | Context for a specific event                         | `plan_type: "pro"`       |
| User profile property | Persistent attribute on the user                     | `$email`, `company_size` |
| Super property        | Auto-appended to every future event via `register()` | `$browser`, `$os`        |

### Data Types

`string`, `number`, `boolean`, `list` (array of strings), `datetime` (ISO 8601)

## Common Pitfalls

- **Event names are case-sensitive.** The name in your SDK call must match Lexicon exactly.
- **Don't use high-cardinality values in event names.** Use a property: `track('Product Viewed', { product_id: id })` not `track('Viewed Product ' + id)`.
- **Don't track PII** in event properties. Mark sensitive properties in Lexicon via `Edit-Property` (sensitive: true).
- **Call `identify()` once per session** after login — not on every page load or API call.
- **`$distinct_id_before_identity`** is set automatically by the SDK after `identify()` — never set it manually.
- **Don't reuse an event name for two different actions.** A generic name like `Button Clicked` used for multiple buttons creates unresolvable ambiguity.
