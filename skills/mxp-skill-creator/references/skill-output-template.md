# Skill Output Template

Structure for `[customer-slug]-mixpanel-skill/`. The output is a **folder**, not a single file. Fill each section as the wizard progresses. This is the single source of truth for output format — do not define section formats inline elsewhere.

## Version Convention

- `skill_creator_version`: version of this wizard that produced the output
- `skill_version`: version of the output skill itself. Bump minor (`1.0` → `1.1`) for value/filter edits; bump major (`1.0` → `2.0`) for adding/removing metrics or structural changes

---

## Folder Layout

```
[customer-slug]-mixpanel-skill/
├── SKILL.md                       # Lean entry point: frontmatter, trigger, router
└── references/
    ├── business-context.md        # Customer identity + project registry
    ├── metrics.md                 # Standard metric definitions
    ├── breakdowns.md              # Breakdown properties + known values
    ├── data-quality.md            # Gaps, aliases, default filters, service accounts
    ├── query-conventions.md       # Timezone, lookback, thresholds
    └── presentation.md            # Brand, audience, format, chart defaults
```

**Why folders, not a single file:**
- SKILL.md stays short → trigger description isn't drowned out by 200 lines of metric YAML.
- Reference files load on demand → query workflows skip presentation; output workflows skip data-quality.
- Edits diff cleanly → adding a metric touches `metrics.md` only.
- Reference files grow independently — large customers (JioHotstar, Nykaa) don't bloat the entry point.

---

## File 1 — `SKILL.md` (entry point)

Lean router. No metric definitions, no brand YAML, no data quality lists. Pointers only.

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

[2–3 sentence summary: what the company does, what this skill standardises, what kind of work it supports.]

**North Star Metric**: [metric name]
**Primary Project**: [project name] (ID: [id])

---

## When to load which reference

Claude must read the relevant reference file(s) before producing output. Load only what the task needs.

| Task | Files to read |
|---|---|
| Identify project, scoping, business context | `references/business-context.md` |
| Look up a canonical metric definition | `references/metrics.md` |
| Find valid breakdown property + known values | `references/breakdowns.md` |
| **Before running ANY query (mandatory)** | `references/data-quality.md` + `references/query-conventions.md` |
| Format output (deck, doc, dashboard, Slack) | `references/presentation.md` |
| Multi-metric report or QBR prep | All six |

---

## Hard Rules

These apply to every query produced under this skill. Violating any of them silently produces wrong results.

1. **Always apply `default_filters` from `references/data-quality.md`.** Skipping these includes test/internal/bot traffic.
2. **Never query unvalidated project IDs.** Use only those listed in `references/business-context.md`.
3. **Use only the canonical metric definitions in `references/metrics.md`.** Do not redefine a metric inline in a query — if it's missing, flag it and ask the user.
4. **For list-type breakdown properties, pass `propertyType: 'list'`** (flagged per-property in `references/breakdowns.md`).
5. **Respect query conventions** in `references/query-conventions.md` — timezone, lookback, minimum-sample thresholds.
6. **Format output per `references/presentation.md`** — currency locale, large-number format, chart type, audience tone.

---

## Validation Status

- Last validated against live Mixpanel: `[YYYY-MM-DD]`
- Re-validation triggers: instrumentation changes, new SDK rollout, new project added, > 90 days elapsed.
```

---

## File 2 — `references/business-context.md`

Customer identity and the project registry. Read whenever the skill loads, since every downstream query needs the project ID.

```markdown
# Business Context — [Customer Name]

## Identity

**Customer**: [Customer Name]
**Website**: [website]
**Industry**: [vertical]
**Business Model**: [e.g., D2C e-commerce / subscription OTT / B2B SaaS]
**Created**: [date]

[2–4 sentences: what the company does, who their users are, what success looks like, and what Mixpanel is the source of truth for.]

## Strategic Metrics

**North Star Metric**: [metric name]
**Supporting Metrics**: [metric-1], [metric-2], [metric-3]

(Full definitions live in `metrics.md`. This is the index.)

## Stakeholders

(Optional — populate if known.)

| Name | Role | Mixpanel Usage |
|---|---|---|
| [name] | [VP Product / Head of Data / etc.] | [primary user / approver / consumer of reports] |

## Projects

Use only these validated project IDs. Do not query other projects unless explicitly instructed.

| Project Name | Project ID | Purpose | MCP Endpoint |
|---|---|---|---|
| [name] | [id] | [Primary / Infra / Mobile / etc.] | [mcp-in / mcp / mcp-eu] |

**Scoping property** (if multi-tenant project): `[property name]` (type: [string/numeric]) = `[value]`

## Cross-Project Joins

(If any metric requires data from multiple projects.)

- **[Metric]**: pull `[event_a]` from `[project_1]`, `[event_b]` from `[project_2]`. Join key: `[user_id / device_id / etc.]`. Notes: [...].
```

---

## File 3 — `references/metrics.md`

Canonical metric definitions. The single most-edited file over a skill's lifetime.

```markdown
# Standard Metric Definitions — [Customer Name]

Validated against live data. Do not alter without re-validating against `Get-Events`, `Get-Properties`, and `Get-Property-Values`.

When a query requires a metric not listed here, **stop and ask the user** rather than improvising.

---

## Metric: [Metric Name]

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
  [Validation findings, platform gaps, list-type flags, edge cases.]
```

---

## Metric: [Next Metric Name]

```yaml
[...]
```

---

## Ratio / Formula Metrics

For ratio metrics, define numerator and denominator separately:

```yaml
metric_name: [Conversion Rate]
type: ratio
numerator:
  events: [[checkout_complete]]
  aggregation: unique_users
  filters: [...]
denominator:
  events: [[checkout_started]]
  aggregation: unique_users
  filters: [...]
unit: "%"
decimal_precision: 1
healthy_direction: up
validation_status: ✅ Validated [date]
notes: >
  [...]
```
```

---

## File 4 — `references/breakdowns.md`

Standard slice dimensions. Validated separately from metrics so adding a breakdown doesn't bump the metric file.

```markdown
# Standard Breakdown Properties — [Customer Name]

Default slice dimensions for any metric. Use `Get-Property-Values` to refresh `known_values` periodically.

---

```yaml
breakdowns:
  - name: [property_name]
    label: [Human-readable label]
    scope: [event | user]
    type: [string | numeric | list]
    known_values: [[value1], [value2], [value3]]
    notes: [e.g., "list-type: pass propertyType: 'list'", "available on Project A only"]
    validation_status: ✅ Validated [date]

  - name: [next_property]
    label: [Label]
    scope: [event | user]
    type: [string | numeric | list]
    known_values: [[v1], [v2], [v3]]
    notes: [...]
    validation_status: ✅ Validated [date]
```

---

## Multi-Project Coverage

(If skill spans multiple projects and a property exists in only some.)

| Property | Project A | Project B | Project C |
|---|---|---|---|
| `[name]` | ✅ | ✅ | ❌ Not instrumented |
| `[name]` | ✅ | ⚠️ Different values | ✅ |
```

---

## File 5 — `references/data-quality.md`

Known dirty corners. **Mandatory read before any query.** Surface this fact in SKILL.md's hard rules.

```markdown
# Data Quality Signals — [Customer Name]

Read before running any query. These are known dirty corners — violating them produces plausible but wrong results.

---

## Default Exclusion Filters

**Apply to every query unless explicitly overridden.** Omitting these includes test/internal/bot traffic.

```yaml
default_filters:
  - [property]: [value]
  - [property]: [value]
```

---

## Instrumentation Gaps

Known incomplete or inconsistent instrumentation.

- **[event/property name]**: [description]. Affected: [scope — platform, user type, date range]. Known since: [date or "unknown"]. Workaround: [if any].

---

## Renamed / Re-instrumented Events

Events that changed name or were re-instrumented. Union old + new for queries spanning the cutover date.

```yaml
event_aliases:
  - alias: [canonical name]
    current_event: [new_name]
    legacy_event: [old_name]
    union_required_for_dates_before: [cutover_date]
    notes: [SDK version, A/B variant, why the change happened]
```

---

## Service Accounts / Programmatic Traffic

[Known service accounts, automated pipelines, internal QA users. May appear as `undefined` or specific IDs in user breakdowns.]

- **[account name / ID]**: [description]. Exclude from user-level metrics: [yes/no]. How to filter: [property + value].

---

## Data Lag

[Known delay between user action and appearance in Mixpanel.]

- **Ingestion lag**: [description]. Affected: [events/pipelines]. Avoid interpreting last [N] hours as final.

---

## Additional Notes

[Surprises for new analysts, instrumentation debt, planned changes, gotchas not covered above.]
```

---

## File 6 — `references/query-conventions.md`

Default knobs. Short file, but worth isolating — it's the second mandatory read alongside `data-quality.md`.

```markdown
# Query Conventions — [Customer Name]

Defaults for every query. Override only when the user explicitly asks for something different.

---

- **Timezone**: [IST | UTC | project default]
- **Default lookback**: [Last 7 days | Last 30 days]
- **Week definition**: [Monday–Sunday rolling 7 days | ISO week | custom]
- **Minimum sample**: [50] events before interpreting rates — flag as low-volume otherwise.
- **Trend threshold**: Flag WoW change > [20%]; treat < [5%] as noise unless sustained 3+ periods.
- **Confidence reporting**: [Always include n / sample size in headline numbers | Only when low-volume]

## Breakdown Defaults

- **Default top-N for breakdowns**: [10] (configurable per query)
- **"Other" bucket**: [include | exclude] when truncating breakdowns
- **Null handling**: [include as "(unknown)" | exclude] in breakdowns

## Comparison Defaults

- **Period-over-period**: [WoW | MoM | YoY] depending on lookback
- **Cohort comparison baseline**: [previous period | same period last year | rolling 4-week average]
```

---

## File 7 — `references/presentation.md`

Brand, audience, format. Loaded only when output is being formatted — not on every query.

```markdown
# Presentation & Brand Guidelines — [Customer Name]

Apply to all customer-facing outputs (decks, docs, dashboards, Slack messages, emails).

---

```yaml
brand_colours:
  primary:   "[hex or label]"
  secondary: "[hex or label]"
  accent:    "[hex or label]"
  notes: "[clarifications — e.g., 'use primary for KPI numbers, secondary for trend lines']"

artifact_formats:
  primary:   "[html | pptx | docx | pdf | slack | context_dependent]"
  secondary: ["[format]"]
  context_dependent: [true | false]
  notes: "[situational rules — e.g., 'QBRs always PPTX, weekly check-ins always Slack']"

audience:
  primary_persona: "[exec | pm_analyst | engineering | mixed]"
  tone:            "[executive | analytical | mixed]"
  notes: "[specifics — e.g., 'CPTO is the primary reader for QBRs, expects headline-first']"

visualisation_style:
  use_mixpanel_defaults: [true | false]
  trend_chart_type:  "[line | bar | area]"
  number_display:    "[raw | percentage | both]"
  currency_locale:   "[INR | USD]"
  large_number_format: "[lakh_crore | million_billion]"
  notes: "[chart conventions]"

presentation_notes: >
  [Style guide URLs, logo links, slide templates, hard "never do X" rules.]
```

---

## Output Patterns

(Optional — populate if customer has consistent output preferences worth codifying.)

- **Headline format**: [e.g., "Big number + 1-line context + WoW delta"]
- **Slide template**: [URL or "use Mixpanel default"]
- **Email subject convention**: [e.g., "[Customer] Weekly Pulse — Week of [date]"]
- **Slack message tone**: [e.g., "Lead with the metric, end with one question"]
```

---

## Wizard Write Sequence

For implementers updating `SKILL.md` (the wizard):

| Module | Writes |
|---|---|
| Module 1 | Creates folder, writes `SKILL.md` (frontmatter + placeholders) and `references/business-context.md` |
| Module 2 | Writes `references/metrics.md` (one metric block at a time, append) |
| Module 3 | Writes `references/breakdowns.md` |
| Module 4 | Writes `references/data-quality.md` and `references/query-conventions.md` |
| Module 5 | Writes `references/presentation.md` |
| Module 6 | Reads all six files; finalises `SKILL.md` description and routing table |

`_wizard_state` lives **only** in the top-level `SKILL.md` (never scattered across reference files). Deleted at finalisation.
