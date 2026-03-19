---
name: metrics
description: Create and manage saved metrics (Insights reports) for experiments, dashboards, and reusable analytics definitions.
---

# Metrics

Create and manage saved metrics as reusable Insights report definitions. Use saved metrics in experiments, dashboards, and to standardize analytics across teams.

**See also:** [Mixpanel Insights Documentation](https://docs.mixpanel.com/docs/reports/insights)

## When to Use This Skill

| I want to...                       | Use this skill if...                      | Use another skill if...                 |
| ---------------------------------- | ----------------------------------------- | --------------------------------------- |
| Create reusable metric definitions | You want consistency across experiments   | One-off query → `analysis`              |
| Build metrics for experiments      | Setting up experiment success criteria    | Already have metrics → `experiments`    |
| Standardize metrics across teams   | Creating a shared metric library          | Ad-hoc exploration → `analysis`         |
| Validate a metric before using it  | Testing if metric definition returns data | Just want to see data → `analysis`      |
| Update an existing metric          | Changing calculation or filters           | Creating new metric → use Create-Metric |

**Key distinction:** Saved metrics are reusable definitions. For one-time queries, use the `analysis` skill instead.

## MCP Tool Reference

| Goal                          | Tool                 |
| ----------------------------- | -------------------- |
| Browse existing saved metrics | `Get-Metrics`        |
| View metric definition        | `Get-Metric-Details` |
| Create new saved metric       | `Create-Metric`      |
| Update existing metric        | `Update-Metric`      |
| Delete saved metric           | `Delete-Metric`      |
| Build Insights query          | `Get-Query-Schema`   |
| Validate metric definition    | `Run-Query`          |

For running queries and exploring data, see the `analysis` skill.

## Core Concepts

### Saved Metrics vs Ad-Hoc Queries

| Aspect          | Saved Metric (TypedBookmark)        | Ad-Hoc Query           |
| --------------- | ----------------------------------- | ---------------------- |
| **Reusability** | Reusable across experiments, boards | One-time use           |
| **Consistency** | Same definition every time          | Can drift between uses |
| **Discovery**   | Searchable in metric library        | Lost after query       |
| **Purpose**     | Standardized team metrics           | Exploratory analysis   |

**When to save a metric:**

- ✅ Using in experiments (primary, guardrail, or secondary metrics)
- ✅ Tracking as KPI on dashboards
- ✅ Standard team metric (e.g., "WAU", "Conversion Rate")
- ✅ Complex calculation used repeatedly

**When to use ad-hoc query:**

- ✅ One-time exploratory analysis
- ✅ Debugging data issues
- ✅ Testing different metric definitions

### Metric Types for Experiments

When creating metrics for experiments, consider which role they'll play:

| Type          | Purpose                       | Recommended Count | Examples                      |
| ------------- | ----------------------------- | ----------------- | ----------------------------- |
| **Primary**   | Main success criteria         | 1-3               | Conversion rate, Revenue/user |
| **Guardrail** | Metrics that must not regress | 2-5               | Error rate, Page load time    |
| **Secondary** | Exploratory insights          | Up to 30          | Feature usage, Time on page   |

You assign these types when adding metrics to experiments, not when creating the saved metric.

### Metric Definitions (Insights Bookmarks)

Saved metrics are stored as **Insights bookmarks** (TypedBookmarks). Each metric contains:

- **Name**: Display name for the metric
- **Description**: What it measures and why
- **Params**: Full Insights query definition (events, filters, breakdowns, formulas, date ranges, etc.)
- **Tags**: For organization and discovery

The `params` object follows the Insights report schema - use `Get-Query-Schema report_type="insights"` to see the full structure.

### What Metrics Can Measure

**Event-based metrics:**

- Unique users performing an event (DAU, WAU, MAU)
- Total event count
- Events per user
- Frequency distributions

**Property aggregations:**

- Sum: Total revenue, Total page views
- Average: Avg session duration, Avg cart value
- Percentiles: 90th percentile load time, Median response time
- Min/Max: Fastest/slowest response

**Formulas and ratios:**

- Conversion rate: (Purchases / Signups) × 100
- Revenue per user: Total Revenue / Unique Users
- Engagement rate: Active Users / Total Users

**Segmented metrics:**

- Broken down by: plan type, country, device, custom properties
- Filtered by: specific user cohorts, property values

## Workflow: Create a Saved Metric

### Phase 1: Define What to Measure

**1. Clarify the metric purpose**

Ask yourself:

- What am I trying to measure and why?
- Will this be reused (experiments, dashboards) or one-time?
- What decisions will this metric inform?

**2. Check for existing metrics**

```
Get-Metrics project_id=<id>
Get-Metrics project_id=<id> query="conversion"  # Search by keyword
```

Review results - you might find an existing metric that fits your needs.

**3. Determine metric type**

Choose the right measurement approach:

- **Event count:** "How many users did X?" → `unique` or `total`
- **Property aggregation:** "What's the average/sum/percentile of Y?" → `sum`, `avg`, `p90`
- **Formula:** "What's the ratio/calculation?" → custom formula combining events
- **Per-user metric:** "Average events per user over time?" → aggregate-property-per-user

### Phase 2: Build & Validate the Metric

**1. Get the Insights schema**

```
Get-Query-Schema report_type="insights"
```

This returns the full JSON schema with all available fields, measurement types, and examples.

**2. Build the metric params object**

Key sections of an Insights query:

```javascript
{
  "chartType": "line" | "bar" | "table" | "metric",
  "unit": "hour" | "day" | "week" | "month",
  "dateRange": {
    "type": "relative",
    "range": {"unit": "day", "value": 30}
  },
  "metrics": [
    {
      "eventName": "Purchase Completed",
      "measurement": {
        "type": "basic",           // or "aggregate-property"
        "math": "unique"            // unique, total, dau, wau, mau
      }
    }
  ],
  "breakdowns": [
    {
      "metric": {
        "type": "property",
        "propertyName": "Plan Type"
      }
    }
  ],
  "filters": [
    {
      "type": "string",
      "propertyName": "$country",
      "operator": "equals",
      "value": "US"
    }
  ]
}
```

**Common measurement types:**

- `basic` with `math: "unique"` - Unique users
- `basic` with `math: "total"` - Total events
- `basic` with `math: "dau"` - Daily active users
- `aggregate-property` with `math: "sum"` - Sum of property values
- `aggregate-property` with `math: "avg"` - Average property value
- `aggregate-property` with `math: "p90"` - 90th percentile

**3. Validate with Run-Query**

Before saving, test that the metric returns expected data:

```
Run-Query
  report_type: "insights"
  project_id: <id>
  report: {
    # Your params object here
  }
```

Review the results:

- Does it return data?
- Are the values in the expected range?
- Do breakdowns/filters work correctly?

**Common validation issues:**

- ❌ Event name typo → no data returned
- ❌ Property name case mismatch → filter doesn't apply
- ❌ Date range too narrow → insufficient data
- ❌ Wrong measurement type → unexpected aggregation

Fix issues and re-validate until the metric returns correct data.

### Phase 3: Save for Reuse

**1. Create the metric**

```
Create-Metric
  project_id: <id>
  name: "Weekly Active Users"
  description: "Unique users who performed any event in the last 7 days"
  params: {
    # Validated params from Phase 2
    "chartType": "line",
    "unit": "day",
    "dateRange": {"type": "relative", "range": {"unit": "day", "value": 30}},
    "metrics": [{
      "eventName": "*",
      "measurement": {"type": "basic", "math": "wau"}
    }]
  }
  tags: ["kpi", "engagement"]
```

**2. Note the returned metric ID**

The response includes a metric ID (bookmark ID). Save this for referencing in experiments:

```
{
  "id": 1234,
  "name": "Weekly Active Users",
  ...
}
```

**3. Use in experiments**

```
Create-Experiment
  project_id: <id>
  name: "Feature Test"
  primary_metric_ids: [1234]  # Reference saved metric by ID
  ...
```

### Phase 4: Maintain Metrics

**Update a metric when:**

- Definition needs refinement (filters, aggregation)
- Event names change
- Requirements evolve

**Delete a metric when:**

- No longer used in any experiments or dashboards
- Replaced by better metric
- Based on deprecated events

**Important:** Updating a shared metric affects ALL experiments and dashboards using it. Consider creating a new metric version instead (e.g., "WAU v2") and deprecating the old one.

## Recommended Workflow

```
Phase 1: Discover
1. Get-Metrics - Check for existing metrics
   → Reuse if available, avoiding duplication

Phase 2: Design
2. Get-Query-Schema report_type="insights"
   → Understand available fields and measurement types

3. Run-Query report_type="insights" report={...}
   → Validate metric returns expected data

Phase 3: Save
4. Create-Metric with validated params
   → Save for reuse across experiments and dashboards

Phase 4: Use
5. Create-Experiment with primary_metric_ids=[...]
   → Reference saved metrics in experiments
```

## Common Metric Patterns

### Event Count Metrics

**Unique users performing an event:**

```javascript
{
  "metrics": [{
    "eventName": "Purchase Completed",
    "measurement": {"type": "basic", "math": "unique"}
  }]
}
```

**Total event count:**

```javascript
{
  "metrics": [{
    "eventName": "Page View",
    "measurement": {"type": "basic", "math": "total"}
  }]
}
```

**DAU / WAU / MAU:**

```javascript
{
  "metrics": [{
    "eventName": "*",  // All events
    "measurement": {"type": "basic", "math": "dau"}  // or "wau", "mau"
  }]
}
```

### Property Aggregation Metrics

**Total revenue (sum):**

```javascript
{
  "metrics": [{
    "eventName": "Purchase Completed",
    "measurement": {
      "type": "aggregate-property",
      "math": "sum",
      "propertyName": "revenue"
    }
  }]
}
```

**Average session duration:**

```javascript
{
  "metrics": [{
    "eventName": "Session End",
    "measurement": {
      "type": "aggregate-property",
      "math": "avg",
      "propertyName": "duration_seconds"
    }
  }]
}
```

**90th percentile page load time:**

```javascript
{
  "metrics": [{
    "eventName": "Page Loaded",
    "measurement": {
      "type": "aggregate-property",
      "math": "p90",
      "propertyName": "load_time_ms"
    }
  }]
}
```

### Formula Metrics

**Conversion rate (%):**

```javascript
{
  "metrics": [
    {
      "eventName": "Purchase Completed",
      "measurement": {"type": "basic", "math": "unique"}
    },
    {
      "eventName": "Signup",
      "measurement": {"type": "basic", "math": "unique"}
    }
  ],
  "formula": "(A / B) * 100"
}
```

**Revenue per user:**

```javascript
{
  "metrics": [
    {
      "eventName": "Purchase Completed",
      "measurement": {
        "type": "aggregate-property",
        "math": "sum",
        "propertyName": "revenue"
      }
    },
    {
      "eventName": "*",
      "measurement": {"type": "basic", "math": "unique"}
    }
  ],
  "formula": "A / B"
}
```

### Filtered & Segmented Metrics

**Metric with filters (US users only):**

```javascript
{
  "metrics": [{
    "eventName": "Purchase Completed",
    "measurement": {"type": "basic", "math": "unique"}
  }],
  "filters": [{
    "type": "string",
    "propertyName": "$country",
    "operator": "equals",
    "value": "US"
  }]
}
```

**Metric broken down by property:**

```javascript
{
  "metrics": [{
    "eventName": "Purchase Completed",
    "measurement": {"type": "basic", "math": "unique"}
  }],
  "breakdowns": [{
    "metric": {
      "type": "property",
      "propertyName": "Plan Type"
    }
  }]
}
```

## Common Pitfalls

### 1. Creating metric without validation

❌ Create metric → realize it returns no data → have to delete and recreate
✅ Use Run-Query to validate before saving with Create-Metric

### 2. Poorly named metrics

❌ "WAU_v2" or "Metric 1" (unclear what it measures)
✅ "Weekly Active Users" or "Purchase Conversion Rate" (descriptive)

### 3. No description

❌ Create metric with empty description → team doesn't know what it measures
✅ Always add description explaining what the metric measures and why it exists

### 4. Updating shared metrics without communication

❌ Change metric definition → breaks all experiments using it
✅ Create new metric version (e.g., "WAU v2"), migrate experiments, deprecate old metric

### 5. Overly complex formulas

❌ Formula with 5+ events → hard to debug, understand, maintain
✅ Keep formulas simple (2-3 events max), or break into multiple metrics

### 6. Not using tags

❌ Create 100 metrics with no tags → impossible to find the right one
✅ Tag by team ("growth-team"), type ("kpi"), or area ("checkout")

### 7. Property name typos

❌ Filter on `properties["Email"]` when actual property is `properties["email"]`
✅ Use Get-Property-Names to find exact property names (case-sensitive)

### 8. Wrong aggregation type

❌ Use `total` when you want `unique` → counts events instead of users
✅ Understand measurement types: `unique` for users, `total` for events, `sum` for property values

## Best Practices

### Before Creating

- ✅ **Search first** — Check Get-Metrics for existing similar metrics
- ✅ **Validate first** — Use Run-Query to test metric definition returns expected data
- ✅ **Check property names** — Use Get-Property-Names for exact spelling (case-sensitive)
- ✅ **Start simple** — Create basic metric first, add complexity incrementally

### When Creating

- ✅ **Use clear names** — "Weekly Active Users" not "WAU_final_v3"
- ✅ **Write descriptions** — Explain what metric measures and intended use
- ✅ **Add tags** — Organize by team, feature area, or metric type
- ✅ **Keep formulas simple** — 2-3 events max, avoid deeply nested calculations
- ✅ **Document assumptions** — Note filters, date ranges, exclusions in description

### After Creating

- ✅ **Version carefully** — Create new metric for breaking changes, deprecate old
- ✅ **Communicate updates** — Tell team when shared metrics change
- ✅ **Clean up unused** — Delete metrics no longer used in experiments/dashboards
- ✅ **Review regularly** — Audit metric library quarterly, remove deprecated metrics

### For Experiments

- ✅ **Reuse metrics** — Reference by ID in primary_metric_ids, guardrail_metric_ids, secondary_metric_ids
- ✅ **Create metric library** — Build standard set of team metrics for consistency
- ✅ **Separate by type** — Create distinct metrics for primary vs guardrail vs secondary roles
- ✅ **Validate baseline** — Run metric on historical data to understand normal ranges

## Integration with Other Skills

### Experiments Skill

Saved metrics are the recommended way to define experiment success criteria:

```
# 1. Create metrics (this skill)
Create-Metric name="Purchase Conversion" ...
→ Returns metric_id: 1234

# 2. Use in experiment (experiments skill)
Create-Experiment
  primary_metric_ids: [1234]
  ...
```

**Benefits:**

- Consistent metric definitions across experiments
- Reusable metrics save time
- Team-wide metric library

### Analysis Skill

Use the `analysis` skill to:

- Build and test metric queries before saving
- Explore data ad-hoc without creating metrics
- Validate property names and values

```
# Analysis skill: Test query
Run-Query report_type="insights" report={...}

# Metrics skill: Save validated query
Create-Metric params={same params from Run-Query}
```

### Feature Flags Skill

Metrics can measure feature flag impact:

```
# 1. Create metric for feature usage
Create-Metric name="New Feature Usage" ...

# 2. Create feature flag (feature-flags skill)
Create-Feature-Flag name="new_feature" ...

# 3. Create experiment to measure impact (experiments skill)
Create-Experiment
  primary_metric_ids: [metric_id]
  settings: {collectionMethod: "feature_flag"}
```

## Quick Reference

### Metric Creation Checklist

- [ ] Searched for existing similar metrics (Get-Metrics)
- [ ] Retrieved Insights schema (Get-Query-Schema)
- [ ] Built params object with correct measurement type
- [ ] Validated metric returns data (Run-Query)
- [ ] Checked results are in expected range
- [ ] Written clear name and description
- [ ] Added appropriate tags
- [ ] Saved metric (Create-Metric)
- [ ] Noted metric ID for use in experiments

### Common Measurement Types

| I want to measure...         | Use measurement type...                     |
| ---------------------------- | ------------------------------------------- |
| Number of unique users       | `basic` / `unique`                          |
| Total event count            | `basic` / `total`                           |
| Daily/Weekly/Monthly actives | `basic` / `dau`, `wau`, `mau`               |
| Sum of property values       | `aggregate-property` / `sum`                |
| Average property value       | `aggregate-property` / `avg`                |
| 90th percentile              | `aggregate-property` / `p90`                |
| Conversion rate (ratio)      | Multiple metrics with `formula`             |
| Events per user              | `frequency-per-user` or `basic` / `general` |

### Date Range Formats

```javascript
// Last 30 days
{"type": "relative", "range": {"unit": "day", "value": 30}}

// Today
{"type": "relative", "range": "today"}

// Yesterday
{"type": "relative", "range": "yesterday"}

// Custom range
{"type": "absolute", "from": "2026-01-01", "to": "2026-02-28"}
```

### Filter Types

```javascript
// String property
{"type": "string", "propertyName": "Plan", "operator": "equals", "value": "Pro"}

// Number property
{"type": "number", "propertyName": "age", "operator": "is at least", "value": 18}

// Boolean property
{"type": "boolean", "propertyName": "is_trial", "operator": "true", "value": true}

// Date property
{"type": "datetime", "propertyName": "created_at", "operator": "was since", "value": "2026-01-01"}

// Range
{"type": "number_array", "propertyName": "score", "operator": "is between", "value": [10, 50]}
```
