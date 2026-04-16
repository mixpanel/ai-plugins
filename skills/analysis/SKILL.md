---
name: analysis
description: Guidance for querying Mixpanel data using MCP tools — Insights, Funnels, Flows, Retention, Frequency, and Dashboards.
---

# Analysis

Two families of query tools are available. Use the right one for the task:

| Family | Tools | When to use |
|--------|-------|-------------|
| **Simple** | `Run-Segmentation-Query`, `Run-Funnels-Query`, `Run-Retention-Query`, `Run-Frequency-Query` | Fast, targeted queries with straightforward parameters |
| **Structured** | `Run-Query` (insights/funnels/flows/retention) | Complex queries with breakdowns, formulas, filters, multiple metrics; also needed to get a `query_id` for dashboards |

Always call `Get-Query-Schema` before building a `Run-Query` call — it returns the full JSON schema for the chosen report type.

## Insights / Segmentation

### Simple — `Run-Segmentation-Query`

```
event: "Signup Completed"
from_date: "2026-02-01"
to_date:   "2026-02-28"
unit:      "day"                           # hour | day | week | month
type:      "unique"                        # general (total) | unique
on:        "properties[\"Signup Type\"]"   # breakdown expression — note escaped quotes
where:     "properties[\"$country\"] == \"US\""  # filter expression
```

`on` and `where` use Mixpanel expression syntax with property names in `properties["Name"]`.

**Breakdown by user profile property** — use `user["property_name"]` with `type=general`:
```
on: "user[\"project_name\"]"   # joins via $distinct_id
```
Works when the event's `$distinct_id` matches the user profile key. Returns `undefined` if the join fails or the property is empty.

**Always call `Get-Property-Names` on the event first** to find the exact property name before writing `on=`. Property names are case-sensitive and project-specific — `Email` ≠ `email` ≠ `$email`. If `$email` returns undefined, check whether the project uses a custom property name instead.

Returns: `{ data: { series: [...dates], values: { segmentValue: { date: count } } } }`

### Structured — `Run-Query` (insights)

Call `Get-Query-Schema report_type=insights` first, then build the report object:

```json
{
  "name": "Signups by type",
  "metrics": [
    {
      "eventName": "Signup Completed",
      "measurement": { "type": "basic", "math": "unique" }
    }
  ],
  "chartType": "line",
  "unit": "day",
  "breakdowns": [
    { "metric": { "type": "property", "propertyName": "Signup Type" } }
  ],
  "dateRange": { "type": "relative", "range": { "unit": "day", "value": 30 } }
}
```

**Measurement types:** `basic` (unique/total/dau/wau/mau/session), `aggregate-property` (sum/avg/median/p90/etc), `frequency-per-user`, `aggregate-property-per-user`

**Chart types:** `bar`, `stacked-bar`, `line`, `stacked-line`, `pie`, `table`, `metric`

Returns: `{ results: { series: { metricLabel: { date: value } } }, query_id: "..." }`

## Funnels

### Simple — `Run-Funnels-Query`

```
events:      '[{"event": "Signup Completed"}, {"event": "Report Viewed"}]'
from_date:   "2026-02-01"
to_date:     "2026-02-28"
length:      30
length_unit: "day"        # conversion window
count_type:  "unique"
on:          "properties[\"plan\"]"   # optional breakdown
```

Returns: steps with `count`, `overall_conv_ratio`, `step_conv_ratio`, `avg_time` (seconds), `avg_time_from_start`.

### Structured — `Run-Query` (funnels)

```json
{
  "name": "Signup to Report Viewed",
  "metrics": [
    { "eventName": "Signup Completed" },
    { "eventName": "Report Viewed" }
  ],
  "chartType": "steps",
  "conversionTime": { "unit": "day", "value": 30 },
  "countType": "unique",
  "dateRange": { "type": "relative", "range": { "unit": "day", "value": 30 } }
}
```

**Chart types:** `steps` (conversion rates), `trends` (over time), `ttc` (time-to-convert distribution), `frequency`

Returns: `overall_conv_ratio`, `count` per step, `avg_time_from_start`, `p_value` for significance.

## Retention

### Simple — `Run-Retention-Query`

```
born_event:     "Signup Completed"   # cohort entry event
event:          "Report Viewed"          # retention action
from_date:      "2026-01-01"
to_date:        "2026-02-28"
retention_type: "birth"                  # birth | compounding
unit:           "week"                   # day | week | month
```

Returns: cohort dates as keys, each with `{ first: N, counts: [N, N, ...] }` — counts per period. `first` is cohort size; each element in `counts` is the number who returned in that period.

### Structured — `Run-Query` (retention)

```json
{
  "name": "Signup Retention",
  "metrics": [
    { "eventName": "Signup Completed" },
    { "eventName": "Report Viewed" }
  ],
  "retentionUnit": "week",
  "chartType": "curve",
  "dateRange": { "type": "relative", "range": { "unit": "month", "value": 2 } }
}
```

**Chart types:** `curve` (retention curves per cohort), `trend` (retention rate over time)

## Flows

Use `Run-Query` with `report_type: "flows"`. Call `Get-Query-Schema report_type=flows` first.

```json
{
  "name": "Paths after signup",
  "metrics": [
    { "eventName": "Signup Completed", "stepsAfter": 3 }
  ],
  "chartType": "sankey"
}
```

**Chart types:** `sankey` (all paths diagram), `paths` (most common sequences)

**Note:** Flows may return empty results if the anchor event has few follow-on paths or the date range is too narrow. Try expanding the date range or using a higher-volume event.

## Frequency

```
event:          "Report Viewed"
from_date:      "2026-02-01"
to_date:        "2026-02-28"
addiction_unit: "day"
unit:           "day"
```

Returns: per-period count of sessions. Useful for understanding engagement frequency.

## Building Dashboards

1. Run `Run-Query` with `skip_results: true` to get a `query_id` without waiting for data:
   ```
   skip_results: true  →  { results: {}, query_id: "abc123" }
   ```

2. Pass `query_id` values to `Create-Dashboard`:
   ```json
   {
     "title": "Growth Dashboard",
     "rows": [
       {
         "contents": [
           { "type": "report", "query_id": "abc123", "name": "Weekly Signups" },
           { "type": "report", "query_id": "def456", "name": "Funnel Conversion" }
         ]
       }
     ]
   }
   ```

Up to 4 reports per row, up to 10 rows.

## Date Range Formats

```json
{ "type": "relative", "range": { "unit": "day", "value": 30 } }
{ "type": "relative", "range": "today" }
{ "type": "relative", "range": "yesterday" }
{ "type": "absolute", "from": "2026-01-01", "to": "2026-02-28" }
```

Relative ranges support `day`, `week`, `month` only.

## Filter Syntax (all query types)

Five filter types — always include `type`, `propertyName`, `operator`, `value`:

```json
{ "type": "string",  "propertyName": "Signup Type", "operator": "equals", "value": "Magic Link" }
{ "type": "number",  "propertyName": "age",          "operator": "is at least", "value": 18 }
{ "type": "boolean", "propertyName": "is_trial",     "operator": "true",  "value": true }
{ "type": "datetime","propertyName": "created_at",   "operator": "was since", "value": "2026-01-01" }
{ "type": "number_array", "propertyName": "score",   "operator": "is between", "value": [10, 50] }
```

Add `"resource": "user"` to filter on user profile properties instead of event properties.
