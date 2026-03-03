---
name: data-governance
description: Manage Mixpanel Lexicon — audit event and property metadata, batch-update descriptions and owners, clean up stale events, and maintain tag taxonomy.
---

# Data Governance

Lexicon is Mixpanel's event catalog — the layer where you document, verify, and manage event and property metadata. Use it to keep your data discoverable and trustworthy.

## Key Tools

| Task | Tool |
|------|------|
| List events | `Get-Events` (use `query` to scope) |
| List event properties | `Get-Property-Names` (resource_type: Event, event: "Name") |
| List user profile properties | `Get-Property-Names` (resource_type: User) |
| Update event metadata | `Edit-Event` |
| Update property metadata | `Edit-Property` |
| Create / rename / delete tag | `Create-Tag`, `Rename-Tag`, `Delete-Tag` |
| Deep-link to Lexicon UI | `Get-Lexicon-URL` — returns a relative path; prepend `https://mixpanel.com` |

> `Get-Event-Details` returns errors in some projects. Use `Get-Events` + `Get-Property-Names` as a substitute.

## Metadata Audit Workflow

### 1. Pull events and score for gaps

```
Get-Events project_id=<id>
```

For each event, check:

| Field | Passing |
|-------|---------|
| `description` | Non-empty |
| `contact_emails` or `team_contact_names` | At least one |
| `tags` | At least one |
| `verified` | `true` |

Build a gap list: `{ event_name, missing: [...fields] }`.

For full metadata visibility, use the Lexicon UI — `Get-Lexicon-URL` returns the direct link.

### 2. Batch-update

```
Edit-Event:
  project_id:     <id>
  event_name:     "<event>"
  description:    "<what triggered this event and why it matters>"
  verified:       true
  contact_emails: ["owner@yourcompany.com"]
  tags:           ["<tag>"]
```

```
Edit-Property:
  project_id:    <id>
  resource_type: "Event"
  property_name: "<property>"
  description:   "<what this value represents; valid values if enum>"
```

### 3. Handle stale events

Confirm volume before acting:
```
Run-Segmentation-Query:
  event:     "<event>"
  from_date: "<90 days ago>"
  to_date:   "<today>"
  unit:      "month"
  type:      "general"
```

| Situation | Action |
|-----------|--------|
| Replaced by a renamed event | `hidden: true` + tag `deprecated` |
| Permanently retired | `dropped: true` ⚠️ irreversible — confirm first |
| Still used by some teams | Add description noting reduced usage |

## Hiding vs. Dropping

| | `hidden: true` | `dropped: true` |
|-|----------------|-----------------|
| Data stored | Yes | No — future data discarded |
| Reversible | Yes | No |
| Use when | Noisy/internal events | Events you never want again |

Always confirm `dropped: true` with the event owner before setting it.

## Hygiene Checklist

- [ ] All active events have a description
- [ ] All active events have at least one owner
- [ ] High-value events are `verified: true`
- [ ] Events with 0 volume in 90+ days are hidden or dropped
- [ ] Deprecated events are tagged `deprecated` and hidden
- [ ] Internal events analysts shouldn't see are `hidden: true`

## Tag Taxonomy

Consistent tags make Lexicon filterable. Suggested conventions:

| Tag | Applies to |
|-----|------------|
| `onboarding` | Signup, first-use flows |
| `conversion` | Checkout, upgrade, purchase |
| `engagement` | Core feature usage |
| `retention` | Return-visit, re-engagement |
| `deprecated` | Events no longer active |
| `[team-name]` | Per-squad ownership |
