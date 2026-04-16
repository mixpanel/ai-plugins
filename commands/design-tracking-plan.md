# Design a Mixpanel Tracking Plan

Helps you design a complete tracking plan for a feature, product area, or entire application — from discovery questions through documented event definitions and implementation-ready code snippets.

## How to use

```
/mixpanel:design-tracking-plan
```

Optionally provide context:
```
/mixpanel:design-tracking-plan for the onboarding flow
/mixpanel:design-tracking-plan for a new checkout redesign
```

## What this command does

1. **Asks discovery questions** to understand what you need to measure:
   - What product decisions will this data inform?
   - What are your key conversion steps?
   - What user segments or properties matter?

2. **Checks existing tracking** using MCP tools:
   - `Get-Events` — avoid duplicating events that already exist
   - `Get-Property-Names` — reuse existing property names where appropriate

3. **Generates a tracking plan** including:
   - Event definitions (name, description, trigger, properties)
   - Property definitions (name, type, description, example values)
   - Naming convention recommendations
   - The key questions each event enables

4. **Produces implementation-ready code** for the detected SDK (JS, iOS, Android, Python, etc.)

5. **Registers definitions in Lexicon** using `Edit-Event` and `Edit-Property` tools (with confirmation)

## Guidance files

- `skills/tracking-plan/SKILL.md` — design principles and naming conventions
- `skills/mixpanel/SKILL.md` — events, properties, identity
- `skills/data-governance/SKILL.md` — documenting in Lexicon

## Example output

```
## Tracking Plan: Onboarding Flow

### Goal
Measure where users drop off between signup and first meaningful action.

### Events

| Event | Trigger | Key Properties |
|-------|---------|----------------|
| Signup Started | User lands on /signup | `source`, `referrer` |
| Signup Completed | Account created successfully | `signup_method`, `plan_name` |
| Onboarding Step Viewed | Each onboarding screen shown | `step_name`, `step_number` |
| Onboarding Step Completed | User advances past a step | `step_name`, `time_on_step` |
| Onboarding Skipped | User clicks "Skip" | `step_name`, `step_number` |
| First Action Completed | User completes the activation event | `action_type` |

### Key Funnels Enabled
- Signup Started → Signup Completed → First Action Completed

### Implementation (JavaScript)
\`\`\`js
// On signup form submit
mixpanel.track('Signup Started', {
  source: 'organic',
  referrer: document.referrer
})

// On successful account creation
mixpanel.identify(user.id)
mixpanel.people.set({ $email: user.email, plan_name: 'free' })
mixpanel.track('Signup Completed', {
  signup_method: 'email',
  plan_name: 'free'
})
\`\`\`
```
