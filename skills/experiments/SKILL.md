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
| Update experiment settings          | `Update-Experiment`                              |
| Launch, pause, or stop experiment   | `Manage-Experiment-State`                        |
| List available metrics              | `Get-Metrics`                                    |
| View metric definition              | `Get-Metric-Details`                             |
| Create metric for experiment        | `Create-Metric`                                  |
| Update existing metric              | `Update-Metric`                                  |

For building metric queries, see the `metrics` skill.

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

**Recommendation:** Use `feature_flag` method for most experiments. Create the feature flag using the `feature-flags` skill or `Create-Feature-Flag` tool.

**Exposure events setup:** If you're manually assigning variants in your application code, use `exposure_events` collection method. Track an event with the variant information when a user is exposed to the experiment. Mixpanel will use these events to segment users and measure metrics.

### SRM (Sample Ratio Mismatch)

SRM detects when variant assignment is imbalanced (e.g., 52% control vs 48% treatment instead of 50/50).

**Always enable SRM detection** — it catches instrumentation bugs early.

## Workflow: Create and Run an Experiment

### Phase 1: Define Hypothesis & Metrics

**1. Write a clear hypothesis**

Start with: "Changing [X] will increase [Y] because [Z]"

**2. Check for existing metrics**

```
Get-Metrics project_id=<id>
Get-Metrics project_id=<id> query="conversion"  # filter by keyword
```

Review the list to find metrics you can reuse.

**3. Create or validate metrics**

If no suitable metric exists, create one:

```
# See full metric definition
Get-Metric-Details project_id=<id> metric_id=<id>

# Create new metric (see 'metrics' skill for details)
Create-Metric
  project_id: <id>
  name: "Purchase Conversion Rate"
  description: "% of users who complete purchase"
  params: { ... }  # Insights bookmark params
```

**Why use saved metrics?**

- ✅ Reusable across multiple experiments
- ✅ Consistent definitions (no drift)
- ✅ Simpler experiment creation (just reference by ID)

**4. Identify metric roles**

- **Primary:** 1-3 metrics that determine success/failure (keep as few as possible to avoid false positives)
- **Guardrails:** 2-5 metrics that must not regress (errors, performance, core flows)
- **Secondary:** Up to 30 exploratory metrics (interesting but not decision criteria)

### Phase 2: Create the Experiment

**1. Gather experiment details**

- **Name:** Clear and descriptive
- **Hypothesis:** What you're testing and why
- **Description:** Implementation details, target audience
- **Tags:** For organization (team, feature area, quarter)

**2. Choose collection method**

- **feature_flag** (recommended): Variants controlled by Mixpanel feature flag
- **exposure_events**: Variants assigned by tracking exposure events in your code

**3. Configure statistical settings**

**For sequential testing (recommended):**

```
settings:
  collectionMethod: "feature_flag"
  confidenceLevel: 0.95        # 95% confidence (standard)
  testingModel: "sequential"   # Adaptive sample size
  srm:
    enabled: true              # ALWAYS enable SRM detection
  bonferroni:
    enabled: false             # Enable if using multiple primary metrics
```

**For frequentist testing:**

```
settings:
  collectionMethod: "feature_flag"
  confidenceLevel: 0.95        # 95% confidence
  sampleSize: 10000            # Calculate using sample size calculator
  testingModel: "frequentist"  # Fixed sample size
  srm:
    enabled: true              # ALWAYS enable SRM detection
  bonferroni:
    enabled: false             # Enable if using multiple primary metrics
```

**4. Create experiment with saved metrics (RECOMMENDED)**

```
Create-Experiment
  project_id: <id>
  name: "Simplified Checkout Flow"
  hypothesis: "Reducing checkout steps increases conversion"
  description: "Testing 3-step vs 5-step checkout flow"
  primary_metric_ids: [123]          # Main success metric
  guardrail_metric_ids: [456, 789]   # Don't harm these metrics
  secondary_metric_ids: [101, 102]   # Additional insights
  settings: { ... }
  tags: ["checkout", "q1-2026", "growth-team"]
```

**Metric assignment by type:**

- `primary_metric_ids`: 1-3 metrics that determine success/failure
- `guardrail_metric_ids`: 2-5 metrics that must not regress
- `secondary_metric_ids`: Up to 30 exploratory metrics

**Alternative: Inline metric definitions**

```
Create-Experiment
  project_id: <id>
  name: "..."
  metrics:
    - metric_type: "primary"
      event_name: "Purchase Completed"
      aggregation: "unique"
    - metric_type: "guardrail"
      event_name: "Page Error"
      aggregation: "total"
```

⚠️ **Inline metrics cannot be reused** — use metric ID parameters instead for consistency.

**5. Review experiment configuration**

```
Get-Experiment-Details
  project_id: <id>
  experiment_id: "<returned_id>"
```

Verify:

- [ ] Metrics are correctly attached (1-3 primary, 2-5 guardrails, up to 30 secondary)
- [ ] Collection method matches your setup (feature_flag or exposure_events)
- [ ] Testing model is appropriate (sequential recommended, or frequentist with calculated sample size)
- [ ] SRM detection is enabled
- [ ] Bonferroni correction is enabled if using multiple primary metrics

### Phase 3: Set Up Variant Infrastructure

**If using collectionMethod: "feature_flag"**

See the `feature-flags` skill for detailed guidance. Quick version:

```
# 1. Create feature flag for experiment
Create-Feature-Flag
  project_id: <id>
  name: "simplified_checkout_experiment"
  description: "Controls checkout flow experiment variants"
  state: "disabled"

# 2. Implement variant logic in code
if (featureFlag.get('simplified_checkout_experiment') === 'variant_a') {
  // 3-step flow
} else {
  // 5-step flow (control)
}

# 3. Deploy code with flag disabled
# 4. Enable flag and link to experiment
```

**If using collectionMethod: "exposure_events"**

Track an exposure event when users are assigned to a variant:

```javascript
// Assign user to variant in your code
const variant = assignUserToVariant(userId); // Your assignment logic

// Track exposure event with variant information
mixpanel.track("Experiment Viewed", {
  "Experiment name": "Simplified Checkout",
  "Variant name": variant,
});

// Show appropriate experience
if (variant === "variant_a") {
  render3StepCheckout();
} else {
  render5StepCheckout();
}
```

Configure the experiment with the exposure event name and variant property names.

### Phase 4: Launch the Experiment

**1. Pre-launch checklist**

- [ ] Metrics are validated and attached (1-3 primary, 2-5 guardrails, up to 30 secondary)
- [ ] Variant infrastructure is deployed and tested
- [ ] Testing model configured (sequential recommended, or frequentist with calculated sample size)
- [ ] Bonferroni correction enabled if using multiple primary metrics
- [ ] Team knows experiment is launching
- [ ] Hypothesis and success criteria are documented

**2. Launch**

```
Manage-Experiment-State
  project_id: <id>
  experiment_id: "<id>"
  action: "launch"
```

**3. Monitor early results**

- Check for SRM violations (imbalanced assignment)
- Verify events are flowing to both variants
- Look for unexpected metric movements

⚠️ **Don't make decisions based on early data** — wait for statistical significance.

### Phase 5: Monitor & Conclude

**1. Check experiment progress**

```
Get-Experiment-Details
  project_id: <id>
  experiment_id: "<id>"
```

Review:

- Sample size collected vs target
- Primary metric trend
- Guardrail metric stability
- Statistical significance

**2. When to stop**

**Stop when:**

- ✅ Reached statistical significance on primary metric
- ✅ Guardrails are stable (no regressions)
- ✅ Results are consistent for several days

**Keep running when:**

- ⏱ Not yet reached significance
- ⏱ Results are noisy or inconsistent
- ⏱ Guardrails show concerning trends (investigate first)

**3. Make decision**

```
Manage-Experiment-State
  project_id: <id>
  experiment_id: "<id>"
  action: "stop"
```

Based on results:

- **Ship winning variant** (update feature flag to 100%)
- **Iterate** (new experiment with learnings)
- **Abandon** (no impact or negative impact)

## Recommended Workflow

```
Phase 1: Define
1. Get-Metrics - Check for existing saved metrics
   → Reuse metrics for consistency across experiments

2. Create-Metric - If needed, create new saved metrics
   → Validate metric definitions first (see 'metrics' skill)

Phase 2: Create
3. Create-Experiment with:
   → primary_metric_ids=[123]
   → guardrail_metric_ids=[456, 789]
   → secondary_metric_ids=[101, 102]
   → Assign metrics by type using saved metric IDs (RECOMMENDED)

Phase 3: Setup
4. Set up variant infrastructure
   → If using feature_flag method, see 'feature-flags' skill
   → Deploy and test before launching experiment

Phase 4: Launch
5. Manage-Experiment-State action="launch"
   → Start collecting data
   → Monitor for SRM violations

Phase 5: Conclude
6. Manage-Experiment-State action="stop"
   → Stop when statistically significant
   → Make decision: ship, iterate, or abandon
```

## Common Pitfalls

### 1. Starting experiment before metrics are validated

❌ Create experiment → realize metric is broken → restart
✅ Validate metric with Run-Report-Query → create experiment

### 2. Peeking at results and stopping early

❌ "It's trending positive after 1 day, let's ship!"
✅ Wait for statistical significance, ignore early trends

### 3. Not setting guardrail metrics

❌ Primary metric improves but page errors spike
✅ Include error rate, page load, and core flow metrics as guardrails

### 4. Using inline metrics instead of saved metrics

❌ Define metrics inline → can't reuse in future experiments
✅ Use primary_metric_ids, guardrail_metric_ids, secondary_metric_ids to reference saved metrics

### 5. SRM violations

❌ Ignore imbalanced assignment (52% vs 48%)
✅ Always enable SRM detection, investigate violations immediately

### 6. Insufficient sample size

❌ Run for 2 days, conclude "no effect"
✅ Calculate required sample size upfront, run until reached

### 7. Multiple testing problem

❌ Run 20 experiments simultaneously, some will show "significance" by chance
✅ Limit concurrent experiments, adjust confidence levels if needed

### 8. Moving goalposts

❌ Primary metric shows no effect, so focus on secondary metric instead
✅ Decide success criteria before launching

### 9. Novelty effects

❌ New design shows lift in week 1, regresses in week 2
✅ Run experiments for at least 2 weeks to catch novelty effects

### 10. Not linking feature flag to experiment

❌ Manually assign variants in code, no connection to experiment
✅ Use collection_method: "feature_flag" for tight integration

## Best Practices

### Before Launch

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

### Metric Selection

- ✅ **Keep primary metrics to 1-3** — each additional primary metric increases false positive risk
- ✅ **Enable Bonferroni correction if multiple primary** — compensates for multiple testing (reduces power)
- ✅ **Guardrails prevent regressions** — 2-5 metrics for errors, performance, core flows
- ✅ **Secondary metrics are exploratory** — up to 30 for interesting insights, not decision criteria
- ✅ **Use the same metrics across experiments** — enables comparison and learning

### Statistical Rigor

- ✅ **Choose confidence level upfront** — typically 95%
- ✅ **Use sequential testing** — allows peeking anytime, adaptive sample size
- ✅ **For frequentist: pre-commit to sample size** — calculate using sample size calculator and stick to it
- ✅ **Run until significance** — sequential stops automatically, frequentist waits for target sample
- ✅ **Enable Bonferroni correction if multiple primary metrics** — prevents false positives from multiple testing

## Example: Complete Experiment Workflow

**Goal:** Test if simplified onboarding increases activation rate

### Step 1: Check existing metrics

```
Get-Metrics project_id=3 query="activation"
→ Found: "7-Day Activation Rate" (metric_id: 456)
→ Found: "Error Rate" (metric_id: 789)
```

### Step 2: Create missing metric

```
Create-Metric
  project_id: 3
  name: "Onboarding Completion Rate"
  description: "% of users who complete all onboarding steps"
  params:
    displayOptions: { chartType: "line" }
    sections:
      events:
        - event: "Onboarding Completed"
          math: "unique"

→ Returns: { id: 999, name: "Onboarding Completion Rate", ... }
```

### Step 3: Create experiment

```
Create-Experiment
  project_id: 3
  name: "Simplified Onboarding Test"
  hypothesis: "Reducing onboarding from 5 steps to 3 increases activation"
  description: "Testing streamlined onboarding with AI suggestions"
  metric_ids: [999, 456, 789]  # Primary, secondary, guardrail
  settings:
    collectionMethod: "feature_flag"
    confidenceLevel: 0.95
    testingModel: "sequential"  # Recommended - adaptive sample size
    srm: { enabled: true }
    bonferroni: { enabled: false }  # Only 1 primary metric
  tags: ["onboarding", "activation", "q1-2026"]

→ Returns: { id: "exp-abc123", status: "draft", ... }
```

### Step 4: Set up feature flag (see feature-flags skill)

```
Create-Feature-Flag
  project_id: 3
  name: "simplified_onboarding_experiment"
  description: "Controls 3-step vs 5-step onboarding experiment"
  state: "disabled"

→ Deploy code, test variants, enable flag
```

### Step 5: Launch

```
Manage-Experiment-State
  project_id: 3
  experiment_id: "exp-abc123"
  action: "launch"

→ Experiment is now live, collecting data
```

### Step 6: Monitor and conclude

After 2 weeks, check results:

```
Get-Experiment-Details
  project_id: 3
  experiment_id: "exp-abc123"

→ Primary metric: +8% lift, p < 0.01 (significant)
→ Guardrails stable
→ Sample size reached
```

Decision: Ship the simplified onboarding!

```
Manage-Experiment-State
  project_id: 3
  experiment_id: "exp-abc123"
  action: "stop"

→ Update feature flag to 100% variant_a
→ Document learnings
→ Plan next iteration
```

## Related Skills

- **metrics** — Create and validate saved metrics for experiments
- **feature-flags** — Set up feature flags for variant assignment
- **analysis** — Build complex metric queries with breakdowns and filters
- **data-governance** — Document experiment learnings in Lexicon

## Further Reading

- Statistical significance calculator
- Sample size determination guide
- A/B testing best practices
- Common statistical pitfalls in experiments
