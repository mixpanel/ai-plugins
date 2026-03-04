---
name: feature-flags
description: Create and manage feature flags for gradual rollouts, targeted releases, and operational control of features without redeployment.
---

# Feature Flags

Control who sees a feature and when — enable gradual rollouts, target specific users, instantly disable risky features, and serve experiment variants.

**See also:** [Mixpanel Feature Flags Documentation](https://docs.mixpanel.com/docs/featureflags)

## When to Use This Skill

| I want to...                      | Use this skill if...                               | Use another skill if...                      |
| --------------------------------- | -------------------------------------------------- | -------------------------------------------- |
| Gradually roll out a feature      | You need operational control (1% → 10% → 100%)     | You need to measure impact → `experiments`   |
| Target specific users or segments | You want feature access based on user properties   | You need statistical testing → `experiments` |
| Create a kill switch              | You need instant OFF capability for risky features | Just deploying code → standard deployment    |
| Serve variants for A/B test       | You're running an experiment                       | Just measuring without variants → `analysis` |
| Deploy without redeployment       | You need runtime configuration changes             | One-time config → environment variables      |

**Key distinction:** Feature flags control **who sees what**. Experiments measure **impact with statistics**.

**You can use both together:** Flags deliver variants, experiments measure impact.

## MCP Tool Reference

| Goal                        | Tool                                               |
| --------------------------- | -------------------------------------------------- |
| Browse existing flags       | `Get-Feature-Flags` (use filters for status, tags) |
| View flag details           | `Get-Feature-Flag-Details`                         |
| Create new flag             | `Create-Feature-Flag`                              |
| Update flag configuration   | `Update-Feature-Flag`                              |
| Enable, disable, or rollout | `Manage-Feature-Flag-State`                        |

For creating experiments that use flags, see the `experiments` skill.

## Core Concepts

### Feature Flags vs Experiments

| Aspect          | Feature Flag                           | Experiment                        |
| --------------- | -------------------------------------- | --------------------------------- |
| **Purpose**     | Control access and rollout             | Measure impact with statistics    |
| **Output**      | ON/OFF state, variant assignment       | Confidence intervals, p-values    |
| **When to use** | "Roll out to 10% of users"             | "Does this increase conversions?" |
| **Duration**    | Can be permanent or temporary          | Temporary (until significance)    |
| **Metrics**     | Optional (can track without measuring) | Required (primary + guardrails)   |

**Use both together:** Flag controls who sees variants (control vs treatment), experiment measures the statistical impact.

### Flag Types

| Type               | Purpose                                           | Example                                     |
| ------------------ | ------------------------------------------------- | ------------------------------------------- |
| **Feature Gate**   | Simple on/off toggle for phased rollouts          | Enable new checkout flow for 10% of users   |
| **Experiment**     | Multiple variants with statistical measurement    | Test 3 different onboarding flows           |
| **Dynamic Config** | JSON key-value payloads for runtime customization | Configure feature settings without redeploy |

**Most common:** Feature Gate for simple rollouts, Experiment for A/B testing.

### Targeting Options

**Audience Segmentation:**

- **User-based** (`distinct_id`): For logged-in users, consistent across devices
- **Device-based** (`device_id`): For pre-authentication flows, per-device
- **Group-based** (`account_id`, `company_id`): For organizational rollouts (B2B)

**Targeting Methods:**

- **Rollout percentage**: Control what % of users see the feature (1%, 10%, 50%, 100%)
- **Cohort targeting**: Target users in specific Mixpanel cohorts (refreshes every ~2 hours)
- **Runtime properties**: Target by platform, URL path, country, custom properties
- **Runtime events**: Target immediately upon specific user actions

**Best practice:** Start with small rollout (1-5%), monitor, then gradually increase.

### Flag States

| State        | Who sees feature | When to use                          |
| ------------ | ---------------- | ------------------------------------ |
| **Disabled** | Nobody           | Default for new flags, kill switch   |
| **Enabled**  | Targeted users   | Active rollout                       |
| **100%**     | Everyone         | Feature is stable, ready to hardcode |

**Lifecycle:** disabled → enabled (small %) → enabled (larger %) → 100% → remove from code

### Sticky Variants

**Sticky assignment** ensures users see the same variant even if rollout rules change later.

**How it works:**

- ✅ User sees variant A at 10% rollout → still sees variant A at 50% rollout
- ⚠️ Control variant is NOT sticky — users can move from control to treatment as rollout increases
- 🎯 Variant assignment key determines randomization unit (user_id, device_id, etc.)
- 📌 Once assigned to a treatment variant, user stays in that variant forever (unless you reset the flag)

**When to use sticky variants:**

Use sticky variants (DEFAULT - recommended for most cases):

- ✅ **User-facing features** — UI changes, new workflows, visual redesigns
- ✅ **Gradual rollouts** — features being rolled out incrementally over time
- ✅ **Consistent experience required** — e.g., onboarding flow, pricing display
- ✅ **Long-running flags** — features staying under flag for weeks/months
- ✅ **A/B tests** — users must stay in their assigned variant for valid results

**Why:** Prevents jarring UX when a user's experience suddenly changes between sessions. Users get consistent behavior.

**Example:** New checkout flow - if a user completes checkout with variant A, they should always see variant A, not randomly switch to variant B next time.

**When NOT to use sticky variants (advanced):**

Use non-sticky variants (requires explicit configuration):

- ✅ **Backend optimizations** — algorithm changes, caching strategies (user doesn't notice)
- ✅ **Temporary flags** — short-lived experiments or testing (< 1 week)
- ✅ **Infrastructure changes** — database queries, API endpoints (invisible to users)
- ✅ **Want variant re-randomization** — intentionally want users to move between variants

**Why:** Allows for true random sampling on each request, useful for load testing or when variant assignment doesn't impact user experience.

**Example:** Testing two different database query optimizations - users don't see any difference, and you want even distribution of load.

**Important caveats:**

- 🚨 **Most flags should use sticky variants** — non-sticky is an advanced use case
- ⚠️ **Control is never sticky** — users assigned to control can move to treatment as you increase rollout
- 🔄 **Resetting variants** — only way to unstick users is to create a new flag or reset the assignment key
- 🧪 **A/B tests require sticky** — statistical validity depends on users staying in their variant

**Default behavior:** Mixpanel feature flags use sticky variants by default. You typically don't need to configure anything special - sticky behavior is built in.

### Rollout Groups

Rollout groups are evaluated **sequentially** — users qualify for the **first matching group**.

Example:

1. Group 1: 100% of cohort "beta_testers"
2. Group 2: 10% of all users

Beta testers always match Group 1, so they're not included in the 10% random rollout of Group 2.

**Best practice:** Put specific targeting (cohorts, properties) before percentage rollouts.

### Fallback Values

If Mixpanel service is unavailable, your code receives the **fallback value** (default variant).

**Best practice:** Set fallback to safe default (usually control/disabled state).

## Workflow: Create and Deploy a Feature Flag

### Phase 1: Plan the Rollout

**1. Define the feature and rollout strategy**

- What feature are you gating?
- Who should see it first? (internal team, beta users, specific segment)
- What's the rollout plan? (1% → 10% → 50% → 100%)
- Is this temporary (for testing) or permanent (operational control)?

**2. Check for existing flags**

```
Get-Feature-Flags project_id=<id>
Get-Feature-Flags project_id=<id> query="checkout"  # filter by keyword
```

Avoid creating duplicate flags for the same feature.

**3. Choose flag type**

- **Feature Gate**: Simple on/off (most common)
- **Experiment**: Multiple variants with metrics
- **Dynamic Config**: Runtime configuration values

**4. Plan cleanup**

- **Temporary flags** (testing, experiments): Remove from code after 100% rollout
- **Permanent flags** (operational control, A/B tests): Keep for ongoing control

### Phase 2: Create the Flag

**1. Create flag in disabled state**

```
Create-Feature-Flag
  project_id: <id>
  name: "new_checkout_flow"
  description: "Enable redesigned 3-step checkout flow"
  type: "feature_gate"  # or "experiment" or "dynamic_config"
  state: "disabled"     # Start disabled for safety
  tags: ["checkout", "frontend", "q1-2026"]
```

**2. Configure targeting (optional)**

```
Update-Feature-Flag
  project_id: <id>
  flag_id: "<returned_id>"
  targeting:
    groups:
      - cohort: "internal_team"  # Group 1: 100% of internal team
        rollout: 100
      - rollout: 5                # Group 2: 5% of remaining users
```

**3. Review flag configuration**

```
Get-Feature-Flag-Details
  project_id: <id>
  flag_id: "<id>"
```

Verify:

- [ ] Flag is in disabled state
- [ ] Targeting is configured correctly (if applicable)
- [ ] Fallback value is set to safe default
- [ ] Tags are applied for organization

### Phase 3: Implement in Code

**1. Integrate Mixpanel SDK**

Different SDKs have different integration patterns — see [Mixpanel SDK docs](https://docs.mixpanel.com/docs/featureflags#implementation).

**2. Check flag in code**

```javascript
// JavaScript example
const variant = mixpanel.get_feature_flag("new_checkout_flow", "control");

if (variant === "enabled") {
  // Show new 3-step checkout
  render3StepCheckout();
} else {
  // Show old 5-step checkout (fallback)
  render5StepCheckout();
}
```

```python
# Python example
variant = mixpanel.get_feature_flag('new_checkout_flow', 'control')

if variant == 'enabled':
    # Show new checkout
    render_3_step_checkout()
else:
    # Show old checkout (fallback)
    render_5_step_checkout()
```

**3. Set fallback value**

Always provide a fallback (second parameter) for graceful degradation if Mixpanel is unavailable.

**4. Test flag locally**

- With flag disabled: Verify fallback behavior
- With flag enabled: Verify new feature works
- Test transitions: Verify no errors when flag state changes

### Phase 4: Deploy with Flag Disabled

**1. Deploy code to production**

Deploy with the flag check in place but flag still **disabled** in Mixpanel.

This ensures:

- No users see the new feature yet
- You can enable it instantly without redeployment
- Rollback is instant (just disable the flag)

**2. Verify flag is working**

```
Get-Feature-Flag-Details
  project_id: <id>
  flag_id: "<id>"
```

Check that the flag is being evaluated (requests are coming in).

### Phase 5: Enable and Rollout

**1. Start with small rollout**

```
Manage-Feature-Flag-State
  project_id: <id>
  flag_id: "<id>"
  action: "enable"
  rollout_percentage: 1  # Start with 1%
```

**2. Monitor early rollout**

- Watch for errors, crashes, or unexpected behavior
- Check metrics (if linked to experiment)
- Gather qualitative feedback from early users

**3. Gradually increase rollout**

```
# Increase to 10%
Manage-Feature-Flag-State
  project_id: <id>
  flag_id: "<id>"
  action: "set_rollout"
  rollout_percentage: 10

# Increase to 50%
...rollout_percentage: 50

# Increase to 100%
...rollout_percentage: 100
```

**Typical rollout schedule:**

- Day 1: 1% (monitor closely)
- Day 3: 10% (if stable)
- Week 1: 50% (if stable)
- Week 2: 100% (if stable)

**4. Handle issues**

If problems arise, instantly disable:

```
Manage-Feature-Flag-State
  project_id: <id>
  flag_id: "<id>"
  action: "disable"
```

### Phase 6: Cleanup (for temporary flags)

**1. When feature is stable at 100%**

- Remove flag checks from code
- Hardcode the new behavior
- Redeploy

**2. Archive or delete flag**

```
# Mark as no longer needed
Update-Feature-Flag
  project_id: <id>
  flag_id: "<id>"
  tags: ["archived", "cleanup-2026-q2"]
```

**Why cleanup matters:** Prevents flag sprawl, reduces technical debt, improves code clarity.

## Recommended Workflow

```
Phase 1: Plan
1. Get-Feature-Flags - Check for existing flags
   → Avoid duplicate flags for same feature
2. Define rollout strategy
   → Start small (1%), increase gradually

Phase 2: Create
3. Create-Feature-Flag with state="disabled"
   → Start with flag OFF for safety
4. Configure targeting (if needed)
   → Cohorts, properties, or percentage

Phase 3: Implement
5. Add flag check to code
   → Include fallback value for safety
6. Deploy code with flag disabled
   → Verify flag is working before enabling

Phase 4: Rollout
7. Manage-Feature-Flag-State action="enable" rollout=1%
   → Start with tiny rollout
8. Monitor and increase gradually
   → 1% → 10% → 50% → 100%

Phase 5: Cleanup
9. Remove flag from code (for temporary flags)
   → Hardcode behavior after 100% rollout
10. Archive flag
    → Prevent flag sprawl
```

## Common Pitfalls

### 1. Enabling flag before code is deployed

❌ Enable flag → deploy code with flag check → users see errors
✅ Deploy code → verify flag check → enable flag

### 2. Not setting fallback value

❌ `mixpanel.get_feature_flag('new_feature')` → errors if service down
✅ `mixpanel.get_feature_flag('new_feature', 'control')` → graceful degradation

### 3. Creating permanent flags for temporary features

❌ Launch experiment → keep flag forever → flag sprawl
✅ Launch experiment → reach 100% → remove flag from code

### 4. Not cleaning up old flags

❌ 100+ flags in project, half are unused
✅ Archive flags after 100% rollout and code removal

### 5. Conflicting flags

❌ Flag A + Flag B enabled = unexpected combined state
✅ Document flag dependencies, test combinations

### 6. Jumping to 100% too quickly

❌ Enable at 100% immediately → issues affect everyone
✅ Gradual rollout (1% → 10% → 50% → 100%)

### 7. Unclear flag names

❌ `flag_123`, `test_flag`, `new_thing`
✅ `new_checkout_flow`, `ai_recommendations_v2`

### 8. Not documenting flag purpose

❌ Flag created 6 months ago, nobody knows what it does
✅ Clear description, tags, owner information

### 9. Missing rollout groups order

❌ Group 1: 10% random, Group 2: 100% beta testers → beta testers in 10% pool
✅ Group 1: 100% beta testers, Group 2: 10% random → beta testers excluded from random

### 10. Ignoring sticky variants

❌ Assume users can move freely between variants or can "unstick" them easily
✅ Understand sticky behavior is permanent - once assigned to a variant, users stay there

**Common mistakes:**

- Expecting to move users from variant A to variant B by adjusting rollout percentages
- Not planning for users who get "stuck" in a buggy variant
- Forgetting that control users CAN move to treatment (control is not sticky)
- Using sticky variants for backend changes where you want random sampling

**How to handle stuck users:**

- Create a new flag with different key to re-randomize all users
- Use targeting rules to override specific users if needed
- For experiments: accept that variant assignment is permanent (this is correct for statistical validity)

## Best Practices

### Before Deployment

- ✅ **Start with flag disabled** — create flag in OFF state for safety
- ✅ **Use clear, descriptive names** — feature-based not implementation-based
- ✅ **Set fallback values** — always provide safe default in code
- ✅ **Tag flags** — by team, feature area, or cleanup date
- ✅ **Document purpose** — description should explain what flag controls and why
- ✅ **Test both states** — verify behavior with flag ON and OFF
- ✅ **Plan cleanup upfront** — decide if temporary or permanent
- ✅ **Use sticky variants (default)** — unless you have a specific reason for non-sticky (backend-only changes)

### During Rollout

- ✅ **Start small** — begin with 1-5% rollout
- ✅ **Monitor closely** — watch for errors, crashes, metrics
- ✅ **Increase gradually** — 1% → 10% → 50% → 100% over days/weeks
- ✅ **Use rollout groups wisely** — specific targeting before percentage
- ✅ **Have kill switch ready** — know how to disable instantly
- ✅ **Communicate with team** — let stakeholders know rollout status

### After 100% Rollout

- ✅ **Remove temporary flags** — don't let flags live forever
- ✅ **Hardcode behavior** — replace flag check with direct implementation
- ✅ **Archive flag** — tag as archived, document removal date
- ✅ **Monitor for lingering references** — ensure code cleanup is complete
- ✅ **Keep permanent flags** — for operational control or ongoing A/B tests

### Integration with Experiments

- ✅ **Use feature_flag collection method** — tight integration
- ✅ **Link flag to experiment** — measure statistical impact
- ✅ **Set up metrics** — define success criteria before launch
- ✅ **Wait for significance** — don't ship early based on trends
- ✅ **Clean up after experiment** — if shipping winner, remove flag

### Targeting Strategy

- ✅ **Cohort targeting refreshes every ~2 hours** — factor in delay
- ✅ **Runtime events trigger immediately** — use for instant targeting
- ✅ **Group-based for B2B** — use account_id for company-wide rollouts
- ✅ **User-based for cross-device** — use distinct_id for logged-in consistency
- ✅ **Device-based for pre-auth** — use device_id before login

## Example: Complete Feature Flag Workflow

**Goal:** Roll out new AI-powered recommendations feature

### Step 1: Check existing flags

```
Get-Feature-Flags project_id=3 query="recommendations"
→ Found: "recommendations_v1" (100%, can deprecate)
→ No conflicts
```

### Step 2: Create flag

```
Create-Feature-Flag
  project_id: 3
  name: "ai_recommendations_v2"
  description: "Enable ML-based product recommendations (replacing v1)"
  type: "feature_gate"
  state: "disabled"
  tags: ["ml", "recommendations", "frontend"]

→ Returns: { id: "flag-abc123", state: "disabled", ... }
```

### Step 3: Implement in code

```javascript
// Check flag with fallback
const useAIRecs = mixpanel.get_feature_flag("ai_recommendations_v2", false);

if (useAIRecs) {
  // Show ML-based recommendations
  displayAIRecommendations(userId);
} else {
  // Show rule-based recommendations (v1)
  displayRuleBasedRecommendations(userId);
}
```

### Step 4: Deploy code with flag disabled

```bash
# Deploy to production
git push origin main

# Verify flag is being evaluated
Get-Feature-Flag-Details project_id=3 flag_id="flag-abc123"
→ Requests: 0 → Wait for traffic
→ Requests: 1000+ → Flag check is working!
```

### Step 5: Enable for internal team first

```
# Start with internal team cohort
Manage-Feature-Flag-State
  project_id: 3
  flag_id: "flag-abc123"
  action: "enable"
  targeting:
    groups:
      - cohort: "internal_employees"
        rollout: 100

→ Internal team sees AI recommendations
→ Monitor Slack for feedback
```

### Step 6: Gradual rollout to all users

```
# Day 1: 1% of remaining users (after internal team)
Manage-Feature-Flag-State
  project_id: 3
  flag_id: "flag-abc123"
  action: "set_rollout"
  rollout_percentage: 1

→ Monitor: Error rate, CTR, load time

# Day 3: 10% (if stable)
...rollout_percentage: 10

# Week 1: 50% (if stable)
...rollout_percentage: 50

# Week 2: 100% (if stable)
...rollout_percentage: 100
```

### Step 7: Cleanup after 100%

```
# Remove flag check from code
- const useAIRecs = mixpanel.get_feature_flag('ai_recommendations_v2', false);
+ const useAIRecs = true;

# Or better: remove condition entirely
- if (useAIRecs) {
-   displayAIRecommendations(userId);
- } else {
-   displayRuleBasedRecommendations(userId);
- }
+ displayAIRecommendations(userId);

# Redeploy

# Archive flag
Update-Feature-Flag
  project_id: 3
  flag_id: "flag-abc123"
  tags: ["archived", "removed-2026-02"]

# Deprecate old flag
Update-Feature-Flag
  project_id: 3
  flag_id: "recommendations_v1"
  tags: ["deprecated", "replaced-by-v2"]
```

## Advanced Topics

### Using Flags with Experiments

```
# Create flag for experiment
Create-Feature-Flag
  project_id: 3
  name: "checkout_experiment_variants"
  type: "experiment"
  state: "disabled"

# Create experiment referencing flag
Create-Experiment
  project_id: 3
  name: "3-step vs 5-step checkout"
  settings:
    collectionMethod: "feature_flag"
    flagId: "checkout_experiment_variants"

# Enable flag to start experiment
Manage-Feature-Flag-State
  project_id: 3
  flag_id: "checkout_experiment_variants"
  action: "enable"
```

See `experiments` skill for full experiment workflow.

### Dynamic Config Example

```
# Create dynamic config flag
Create-Feature-Flag
  project_id: 3
  name: "search_config"
  type: "dynamic_config"
  config:
    max_results: 20
    enable_fuzzy: true
    boost_recent: 1.5

# Fetch config in code
const config = mixpanel.get_feature_flag_config('search_config', {
  max_results: 10,
  enable_fuzzy: false,
  boost_recent: 1.0
});

// Use config values
const results = search(query, { maxResults: config.max_results });
```

### Targeting by Multiple Criteria

```
Update-Feature-Flag
  project_id: 3
  flag_id: "<id>"
  targeting:
    groups:
      # Group 1: Premium users in US
      - cohort: "premium_users"
        properties:
          - name: "$country"
            operator: "equals"
            value: "US"
        rollout: 100

      # Group 2: 20% of free users
      - cohort: "free_users"
        rollout: 20
```

## Related Skills

- **experiments** — Create experiments that use feature flags for variant assignment
- **metrics** — Create saved metrics to track feature flag impact
- **analysis** — Query data to measure feature adoption and impact

## Further Reading

- [Mixpanel Feature Flags Documentation](https://docs.mixpanel.com/docs/featureflags)
- [Feature Flag Best Practices](https://docs.mixpanel.com/docs/featureflags#best-practices)
- [SDK Implementation Guides](https://docs.mixpanel.com/docs/featureflags#implementation)
