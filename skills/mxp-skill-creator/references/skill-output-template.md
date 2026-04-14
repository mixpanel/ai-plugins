# Skill Output Template

Structure for `[customer]-mixpanel-skill/SKILL.md`. Fill each section as the wizard progresses. This is the single source of truth for output format — do not define section formats inline elsewhere.

## Version Convention

- `skill_creator_version`: version of this wizard that produced the file
- `skill_version`: version of the output skill itself. Bump minor (`1.0` → `1.1`) for value/filter edits; bump major (`1.0` → `2.0`) for adding/removing metrics or structural changes

---

```markdown
---
name: [customer-slug]-mixpanel-skill
skill_creator_version: "2.0"
skill_version: "1.0"
last_validated: "[YYYY-MM-DD]"
description: >
  Mixpanel query skill for [Customer Name] ([website]). Covers [metric-1], [metric-2], [metric-3]
  with breakdowns by [property-1], [property-2]. Always apply validated project IDs, canonical
  metric definitions, and data quality filters. Trigger whenever querying [Customer Name]'s
  Mixpanel data, running analytics, or building reports/dashboards/health checks for [Customer Name].
compatibility:
  tools:
    - Mixpanel MCP
---

# [Customer Name] — Mixpanel Query Skill

## Business Context

**Customer**: [Customer Name]
**Website**: [website]
**Industry**: [vertical]
**Created**: [date]

[2–4 sentences: what the company does, what Mixpanel measures, what success looks like.]

**North Star Metric**: [metric name]
**Key Metrics**: [metric-1], [metric-2], [metric-3]

---

## Projects

Use only these validated project IDs. Do not query other projects unless explicitly instructed.

| Project Name | Project ID | Purpose | MCP Endpoint |
|---|---|---|---|
| [name] | [id] | [Primary / Infra / etc.] | [mcp-in / mcp / mcp-eu] |

**Scoping property**: `[property name]` (type: [string/numeric]) = `[value]`

---

## Standard Metric Definitions

Validated against live data. Do not alter without re-validating.

### Metric: [Metric Name]

```yaml
events: [[event_name_1], [event_name_2]]
event_union: [yes | no]
aggregation: [total_events | unique_users | sum:[property] | ratio]
filters:
  - [property_name]: [value]
unit: [users | % | INR | sessions]
decimal_precision: [0 | 1 | 2]
healthy_direction: [up | down]
validation_status: ✅ Validated [date]
notes: >
  [Validation findings, platform gaps, list-type flags]
```

---

## Standard Breakdown Properties

Offer these as default slice dimensions for any metric.

```yaml
breakdowns:
  - name: [property_name]
    label: [Human-readable label]
    type: [string | numeric | list]
    known_values: [[value1], [value2], [value3]]
    notes: [e.g., "list-type: pass propertyType: 'list'"]
    validation_status: ✅ Validated [date]
```

---

## Data Quality Signals

Read before running any query. These are known dirty corners — violating them produces plausible but wrong results.

### Instrumentation Gaps

- **[name]**: [description]. Affected: [scope]. Known since: [date or "unknown"].

### Renamed / Re-instrumented Events

Union old + new names for queries spanning the cutover date.

```yaml
event_aliases:
  - alias: [canonical name]
    current_event: [new_name]
    legacy_event: [old_name]
    union_required_for_dates_before: [cutover_date]
    notes: [optional]
```

### Default Exclusion Filters

Always apply unless explicitly overridden. Omitting these includes test/internal/bot traffic.

```yaml
default_filters:
  - [property]: [value]
```

### Service Account / Programmatic Traffic

[Known service accounts, automated pipelines. May appear as `undefined` in user breakdowns. Exclude: yes/no.]

### Additional Notes

[Surprises for new analysts, instrumentation debt, planned changes.]

---

## Query Conventions

- **Timezone**: [IST | UTC | project default]
- **Default lookback**: [Last 7 days | Last 30 days]
- **Week definition**: [Monday–Sunday rolling 7 days]
- **Minimum sample**: [50] events before interpreting rates — flag as low-volume otherwise
- **Trend threshold**: Flag WoW > [20%]; treat < [5%] as noise unless sustained 3+ periods

---

## Presentation & Brand Guidelines

Apply to all outputs for [Customer Name].

```yaml
brand_colours:
  primary:   "[hex or label]"
  secondary: "[hex or label]"
  accent:    "[hex or label]"
  notes: "[clarifications]"

artifact_formats:
  primary:   "[html | pptx | docx | pdf | slack | context_dependent]"
  secondary: ["[format]"]
  context_dependent: [true | false]
  notes: "[situational rules]"

audience:
  primary_persona: "[exec | pm_analyst | engineering | mixed]"
  tone:            "[executive | analytical | mixed]"
  notes: "[specifics]"

visualisation_style:
  use_mixpanel_defaults: [true | false]
  trend_chart_type:  "[line | bar | area]"
  number_display:    "[raw | percentage | both]"
  currency_locale:   "[INR | USD]"
  large_number_format: "[lakh_crore | million_billion]"
  notes: "[chart conventions]"

presentation_notes: >
  [Style guide URLs, logo links, slide templates, hard rules]
```
```
