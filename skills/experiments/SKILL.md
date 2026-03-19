---
name: experiments
description: Design, create, and manage experiments (A/B, A/A, multivariate tests) to measure the impact of product changes with statistical rigor.
---

# Experiments

Run experiments (A/B, A/A, multivariate tests) to measure the impact of product changes on user behavior with statistical confidence.

**See also:** [Mixpanel Experiments Documentation](https://docs.mixpanel.com/docs/experiments)

## When to Use This Skill

| I want to...                           | Use this skill if...                       | Use another skill if...                       |
| -------------------------------------- | ------------------------------------------ | --------------------------------------------- |
| Test multiple product variants (A/B/C) | You need statistical measurement of impact | Just gradual rollout → `feature-flags`        |
| Measure conversion impact              | You have a hypothesis to validate          | Just query existing data → `analysis`         |
| Validate feature value                 | You need confidence intervals and p-values | Just ship to % of users → `feature-flags`     |
| Test instrumentation (A/A test)        | You need to verify tracking is working     | Just verify events exist → `analysis`         |
| Create experiment metrics              | You're setting up the experiment           | Building reusable metrics library → `metrics` |

**Key distinction:** Experiments measure impact with statistics. Feature flags control who sees what.

## MCP Tool Reference

| Goal                                | Tool                                             |
| ----------------------------------- | ------------------------------------------------ |
| Browse existing experiments         | `Get-Experiments` (use filters for status, tags) |
| View experiment details and results | `Get-Experiment-Details`                         |
| Create new experiment               | `Create-Experiment`                              |
| Launch, pause, or stop experiment   | `Manage-Experiment-State`                        |
| List available metrics              | `Get-Metrics`                                    |
| View metric definition              | `Get-Metric-Details`                             |
| Create metric for experiment        | `Create-Metric`                                  |
| Update existing metric              | `Update-Metric`                                  |

For building metric queries, see the `metrics` skill.

## Upfront Configuration Checklist

**Before creating any experiment, always ask or confirm the following with the user:**

| Setting | Options | Default | Guidance |
| --- | --- | --- | --- |
| **Statistical model** | `sequential` (recommended) or `frequentist` | sequential | Always surface this choice |
| **Confidence level** | `0.90`, `0.95`, `0.99` | 0.95 | Always confirm explicitly |
| **Traffic split** | e.g. 50/50, 33/33/33 | 50/50 | Confirm if not obvious |
| **SRM detection** | enabled / disabled | enabled | Recommend enabled |
| **Bonferroni correction** | enabled / disabled | disabled | Ask if >1 primary metric |
| **End condition** | `days` (frequentist only) or significance | — | Ask if frequentist |
| **Workspace** | Which workspace to use | project default | Ask if project has multiple |
| **Tags** | For organization | none | Suggest based on feature area / quarter |

Do not silently assume defaults — surface these decisions so the user can make informed choices before creation.

## Prior Experiment Check

**Always search for prior experiments on the same feature before creating a new one.** Use `Get-Experiments` with a keyword search. If found:

- Pull details with `Get-Experiment-Details` — prior experiments often contain relevant event names, metric definitions, hypothesis patterns, and variant structures you can reuse
- Note which metrics were used, what the results were, and what variants were tested
- Surface this context to the user before proposing a new design

```
Get-Experiments project_id=<id> name="datepicker"
→ Found prior experiment → Get-Experiment-Details → reuse metric definitions
```

## Core Concepts

### Experiments vs Feature Flags

| Aspect          | Experiment                        | Feature Flag               |
| --------------- | --------------------------------- | -------------------------- |
| **Purpose**     | Measure impact with statistics    | Control rollout and access |
| **Output**      | Confidence intervals, p-values    | ON/OFF state, targeting    |
| **When to use** | "Does this increase conversions?" | "Roll out to 10% of users" |
| **Duration**    | Temporary (until significance)    | Can be permanent           |
| **Metrics**     | Required (primary + guardrails)   | Optional                   |

**You can use both together:** Feature flag controls who sees variants, experiment measures the impact.

### Feature Flag Auto-Creation

When `collectionMethod: "feature_flag"` is used with `featureFlagKey` in `Create-Experiment`, **the experiment automatically creates and links a feature flag**. You do NOT need to call `Create-Feature-Flag` separately first.

```
Create-Experiment
  settings:
    collectionMethod: "feature_flag"
    featureFlagSettings:
      featureFlagKey: "my_new_flag"   ← auto-creates flag

→ Returns featureFlagId in settings — flag created and linked
→ Launching the experiment also enables the flag automatically
```

Only use `Create-Feature-Flag` separately for standalone flags (no experiment), or when you need to pre-configure complex rollout rules before linking.

### Hypothesis-Driven Testing

Every experiment should start with a clear hypothesis:

```
"Changing [X] will increase [Y] because [Z]"
```

**Examples:**

- ✅ "Adding social proof to checkout will increase conversion by 5% because it reduces purchase anxiety"
- ✅ "Simplifying onboarding from 5 steps to 3 will improve activation rate because users get value faster"
- ❌ "Let's test a new button color" (no clear expected outcome or mechanism)

### Metric Types

| Type          | Purpose                                             | Example                           | Limits                                |
| ------------- | --------------------------------------------------- | --------------------------------- | ------------------------------------- |
| **Primary**   | Success criteria — what you're trying to improve    | Conversion rate, Revenue per user | Keep as few as possible (ideally 1-3) |
| **Guardrail** | Metrics that must not regress                       | Page load time, Error rate        | Typically 2-5                         |
| **Secondary** | Exploratory — interesting but not decision criteria | Time on page, Feature usage       | Maximum 30                            |

**Best practice:** 1-3 primary metrics, 2-5 guardrails, up to 30 secondary.

**Multiple primary metrics:** Each additional primary metric increases the chance of false positives. To compensate:

- Enable **Bonferroni correction** in experiment settings (reduces statistical power but prevents false positives)
- Or keep primary metrics to 1-2 and move others to secondary

### Statistical Models

Mixpanel supports two statistical testing approaches:

| Model           | When to use                    | How it works                                                   | Trade-offs                                 |
| --------------- | ------------------------------ | -------------------------------------------------------------- | ------------------------------------------ |
| **Sequential**  | Most experiments (recommended) | Continuously monitors results, stops when significance reached | Can peek anytime, adaptive sample size     |
| **Frequentist** | Fixed-duration experiments     | Fixed sample size determined upfront, test at end              | Clear stopping rules, traditional approach |

**Recommendation:** Start with **sequential** testing for most experiments. It allows you to monitor results continuously and stops automatically when statistical significance is reached, saving time and traffic.

**Key differences:**

- **Sequential:** Dynamically adjusts as data arrives, safe to check results anytime, may reach conclusion faster
- **Frequentist:** Pre-determined sample size, check results only at the end, more traditional approach

See [Mixpanel's statistical models documentation](https://docs.mixpanel.com/docs/experiments#statistical-testing-models) for details.

### Sample Size & Confidence

**For sequential testing:** Sample size adjusts dynamically based on observed data.

**For frequentist testing:** Calculate required sample size upfront using:

- **Baseline rate:** Current conversion rate (use `analysis` skill to query existing data)
- **Minimum detectable effect (MDE):** Smallest change you care about (e.g., 10% relative improvement)
- **Confidence level:** Typically 95% (5% chance of false positive)
- **Statistical power:** Typically 80% (20% chance of false negative)
- **Number of variants:** 2 for A/B test, 3+ for multivariate

**Calculate sample size:** Use [Mixpanel's Sample Size Calculator](https://mixpanel.com/platform/experiments/sample-size-calculator/?baseline=25&mde=10&significance=95&power=80&variants=2&hypothesis=two-sided)

- Adjust URL parameters: `baseline`, `mde`, `significance`, `power`, `variants`
- Returns: Required sample size per variant

**Rule of thumb:** Smaller effects require larger samples. A 1% lift needs 10x more users than a 10% lift.

### Collection Methods

| Method              | How it works                                           | When to use                                        |
| ------------------- | ------------------------------------------------------ | -------------------------------------------------- |
| **feature_flag**    | Users assigned to variants via Mixpanel feature flag   | Most experiments (recommended)                     |
| **exposure_events** | Users assigned to variants by tracking exposure events | Custom variant assignment in your application code |

**Recommendation:** Use `feature_flag` method for most experiments. Pass `featureFlagKey` in settings to auto-create the flag — no separate `Create-Feature-Flag` call needed.

**Exposure events setup:** If you're manually assigning variants in your application code, use `exposure_events` collection method. Track an event with the variant information when a user is exposed to the experiment. Mixpanel will use these events to segment users and measure metrics.

### SRM (Sample Ratio Mismatch)

SRM detects when variant assignment is imbalanced (e.g., 52% control vs 48% treatment instead of 50/50).

**Always enable SRM detection** — it catches instrumentation bugs early.

## Workflow: Create and Run an Experiment

### Phase 0: Gather Configuration Upfront

**Before doing anything else, confirm the following with the user** (or make explicit decisions and state them clearly):

1. **Statistical model:** Sequential (recommended) or frequentist?
2. **Confidence level:** 90%, 95%, or 99%?
3. **Traffic split:** 50/50? Unequal?
4. **Workspace:** Which workspace if the project has multiple?
5. **Tags:** What tags should organize this experiment?
6. **Minimum run time:** At least 2 weeks recommended to avoid novelty effects

Surface these as questions if not provided. Do not silently pick defaults.

### Phase 1: Research & Design

**1. Check for prior experiments on the same feature**

```
Get-Experiments project_id=<id> name="<feature keyword>"
→ If found: Get-Experiment-Details to pull metric definitions and prior results
→ Reuse event names and metric patterns where applicable
```

**2. Write a clear hypothesis**

Start with: "Changing [X] will increase [Y] because [Z]"

**3. Check for existing metrics**

```
Get-Metrics project_id=<id>
```

Review the list to find metrics you can reuse.

**4. Create or validate metrics**

If no suitable metric exists, create one:

```
# See full metric definition
Get-Metric-Details project_id=<id> metric_id=<id>

# Create new metric
Create-Metric
  project_id: <id>
  name: "Purchase Conversion Rate"
  description: "% of users who complete purchase"
  definition: { ... }
```

**Why use saved metrics?**

- ✅ Reusable across multiple experiments
- ✅ Consistent definitions (no drift)
- ✅ Simpler experiment creation (just reference by ID)

**5. Identify metric roles**

- **Primary:** 1-3 metrics that determine success/failure
- **Guardrails:** 2-5 metrics that must not regress (errors, performance, core flows)
- **Secondary:** Up to 30 exploratory metrics

### Phase 2: Create the Experiment

**Create experiment — this also auto-creates the linked feature flag:**

```
Create-Experiment
  project_id: <id>
  workspace_id: <id>
  name: "Experiment Name"
  hypothesis: "Changing X will increase Y because Z"
  description: "Implementation details, target audience"
  primary_metric_ids: [<id>]
  guardrail_metric_ids: [<id>, <id>]
  settings:
    collectionMethod: "feature_flag"
    featureFlagSettings:
      featureFlagKey: "my_flag_key"    ← auto-creates flag, no separate Create-Feature-Flag needed
    confidenceLevel: 0.95             ← confirm with user
    testingModel: "sequential"        ← confirm with user
    srm: { enabled: true }
    bonferroni: { enabled: false }    ← enable if >1 primary metric
  tags: ["feature-area", "q1-2026"]

→ Returns: { id: "exp-abc123", featureFlagId: "flag-xyz", status: "draft" }
```

### Phase 3: Implement & Launch

**1. Implement the flag in code (JS SDK example)**

```javascript
// Exposure tracked automatically when getFeatureFlag is called
const variant = mixpanel.getFeatureFlag('my_flag_key');

if (variant === 'treatment') {
  return <NewComponent />;
}
// 'control' or null (flag disabled / user not bucketed) — always have fallback
return <CurrentComponent />;
```

**Key implementation notes:**
- Call `mixpanel.identify(userId)` before `getFeatureFlag` — flag uses `distinct_id` context by default
- Call `getFeatureFlag` at the exact render point of the feature — exposure timing must match actual user experience
- `null` return means flag is disabled or user not bucketed — always have a safe fallback

**2. Test both variants manually before launch**

**3. Launch**

```
Manage-Experiment-State
  project_id: <id>
  experiment_id: "<id>"
  action: "launch"

→ Experiment goes ACTIVE, feature flag enabled automatically
```

### Phase 4: Monitor and Conclude

**Check results:**

```
Get-Experiment-Details
  project_id: <id>
  experiment_id: "<id>"
  compute_metrics: true    ← live results with statistical analysis
  compute_exposures: true  ← live exposure counts
```

**Conclude:**

```
Manage-Experiment-State action="conclude"   ← ends experiment

Manage-Experiment-State
  action: "decide"
  success: true
  variant: "treatment"    ← if shipping winner
```

## Common Pitfalls

### 1. Not checking for prior experiments

❌ Design from scratch without checking history
✅ Always run `Get-Experiments` with a keyword search first

### 2. Silently assuming statistical defaults

❌ Create experiment with 0.95 / sequential without asking
✅ Surface confidence level, testing model, and traffic split decisions explicitly before creating

### 3. Creating the feature flag separately

❌ `Create-Feature-Flag` → `Create-Experiment` → link manually
✅ `Create-Experiment` with `featureFlagKey` → flag auto-created and linked

### 4. Not using saved metrics

❌ Define metrics inline → can't reuse in future experiments
✅ Use `primary_metric_ids`, `guardrail_metric_ids`, `secondary_metric_ids`

### 5. SRM violations

❌ Ignore imbalanced assignment
✅ Always enable SRM detection, investigate violations immediately

### 6. Insufficient sample size

❌ Run for 2 days, conclude "no effect"
✅ Calculate required sample size upfront, run until reached

### 7. Multiple testing problem

❌ Run 20 experiments simultaneously
✅ Limit concurrent experiments, enable Bonferroni if multiple primary metrics

### 8. Moving goalposts

❌ Primary shows no effect, pivot to secondary metric
✅ Decide success criteria before launching

### 9. Novelty effects

❌ Ship after 1 week of positive results
✅ Run at least 2 weeks to let novelty effects stabilize

### 10. Calling getFeatureFlag too early

❌ Check flag on app init before user sees the feature
✅ Call at the exact render point — exposure timing must match the actual user experience

## Best Practices

### Before Launch

- ✅ **Confirm statistical settings explicitly** — confidence level, model, split before creating
- ✅ **Check prior experiments** — search for existing experiments on the same feature
- ✅ **Write hypothesis first** — be explicit about expected outcome and mechanism
- ✅ **Use saved metrics** — reference by ID for consistency and reusability
- ✅ **Set both primary and guardrails** — know what success looks like and what can't break
- ✅ **Calculate sample size** — ensure you can reach significance in reasonable time
- ✅ **Enable SRM detection** — catch instrumentation bugs early
- ✅ **Test variants manually** — verify both control and treatment work before launch

### During Experiment

- ✅ **Don't peek and ship early** — resist the urge to act on early trends
- ✅ **Monitor guardrails** — stop if core metrics regress significantly
- ✅ **Check for SRM** — imbalanced assignment invalidates results
- ✅ **Document observations** — note any unexpected patterns for future experiments

### After Experiment

- ✅ **Wait for significance** — even if trending positive, wait for statistical confidence
- ✅ **Consider long-term effects** — novelty effects fade, does lift persist?
- ✅ **Ship with confidence** — if significant and guardrails stable, ship it
- ✅ **Share learnings** — document what you learned, not just the result
- ✅ **Clean up** — update feature flag to 100% or remove, archive experiment

## Related Skills

- **metrics** — Create and validate saved metrics for experiments
- **feature-flags** — Set up standalone feature flags (not needed for experiment-linked flags)
- **analysis** — Build complex metric queries with breakdowns and filters
- **data-governance** — Document experiment learnings in Lexicon

## Further Reading

- Statistical significance calculator
- Sample size determination guide
- A/B testing best practices
- Common statistical pitfalls in experiments
