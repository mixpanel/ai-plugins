# Audit Existing Mixpanel Tracking

Analyzes the current codebase for Mixpanel instrumentation, compares it against what's live in the project, and surfaces gaps, inconsistencies, and data quality issues.

## How to use

```
/mixpanel:audit-tracking
```

## What this command does

1. **Scans the codebase** for all Mixpanel SDK calls:
   - `mixpanel.track()` / `mp.track()` calls
   - `mixpanel.identify()` calls
   - `mixpanel.people.set()` / profile property calls
   - `mixpanel.register()` / super property calls

2. **Queries live Mixpanel data** using the MCP tools:
   - `Get-Events` — what events exist in the project
   - `Get-Issues` — open data quality issues
   - `Run-Segmentation-Query` — verify recent event volume for key events

3. **Produces an audit report** covering:
   - Events tracked in code but missing from Lexicon documentation
   - Events in Lexicon not found in codebase (possibly dead code or external sources)
   - Properties sent inconsistently (type drift, missing required props)
   - Open data quality issues from Lexicon
   - Identity management issues (e.g., `identify()` called before `track()`)

## Guidance files

- `skills/mixpanel/SKILL.md` — core concepts
- `skills/tracking-plan/SKILL.md` — naming conventions and best practices
- `skills/data-governance/SKILL.md` — Lexicon operations and data quality workflow

## Example output

```
## Tracking Audit Report

### Events in code (12 found)
✅ Purchase Completed — documented in Lexicon, active
✅ Signup Started — documented in Lexicon, active
⚠️  btn_click — not documented; consider renaming to "Button Clicked" with a context property
❌ Feature Used — tracked in code but 0 events in last 30 days; may be dead code

### Data Quality Issues (3 open)
- Type drift on `price` property: sending both string and number
- `user_id` property on `Login Completed` has 40% null rate
- Duplicate event names: `page_view` and `Page Viewed` (likely same event)

### Recommendations
1. Rename `btn_click` to `Button Clicked` with a `button_name` property
2. Fix `price` to always send as number
3. Consolidate `page_view` and `Page Viewed`
```
