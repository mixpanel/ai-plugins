# Shared Config — manage-flags

This file is the single source of truth for all five commands in this
skill. If connector names or tool surfaces change, edit here once and
every command picks it up.

---

## Connector

```
ACTIVE_CONNECTOR: Mixpanel MCP — EU (api-eu.mixpanel.com)
ACTIVE_CONNECTOR_MCP_SERVER_ID: MIXPANEL_EU_MCP_ID
DATA_RESIDENCY: EU
```

Tool names below are bare (no namespace prefix) — commands prepend the
connector name at call time.

### Tool surface used by this skill

| Tool | Used by |
|---|---|
| `Create-Feature-Flag` | `run-rollout` |
| `Get-Feature-Flag` | `run-rollout`, `attach-metrics`, `analyze-impact`, `plan-rollout`, `my-flags` |
| `List-Feature-Flags` | flag-resolution prerequisite, `my-flags` |
| `Update-Feature-Flag` | `run-rollout`, `attach-metrics` (state writes), `analyze-impact` (mark complete), `my-flags` (archive) |
| `Get-Feature-Flag-Setup-Guidance` | `plan-rollout` (flag-vs-experiment decision support) |
| `Get-Feature-Flag-Lifecycle-Guidance` | `run-rollout` (staged ramp posture) |
| `Create-Metric` | `attach-metrics` |
| `Get-Metric` | `attach-metrics`, `run-rollout`, `analyze-impact` |
| `List-Metrics` | `attach-metrics` (reuse search) |
| `Get-Business-Context` | `attach-metrics` (anchor against tracked KPIs), `analyze-impact` |
| `Run-Query` | `plan-rollout`, `run-rollout`, `analyze-impact` |
| `Search-Entities` | `plan-rollout` (cohort reuse), `attach-metrics` (metric reuse), `my-flags` (dashboard refs) |
| `Get-Property-Values` | `plan-rollout` |

If any of these tool names change, update the mapping table below and
reference it from the commands instead of bare names.

```
TOOL_MAP:
  create_flag:              Create-Feature-Flag
  get_flag:                 Get-Feature-Flag
  list_flags:               List-Feature-Flags
  update_flag:              Update-Feature-Flag
  flag_setup_guidance:      Get-Feature-Flag-Setup-Guidance
  flag_lifecycle_guidance:  Get-Feature-Flag-Lifecycle-Guidance
  create_metric:            Create-Metric
  get_metric:               Get-Metric
  list_metrics:             List-Metrics
  get_business_context:     Get-Business-Context
  run_query:                Run-Query
  search_entities:          Search-Entities
  get_property_values:      Get-Property-Values
```

---

## Project handling

This skill **does not** hardcode a project ID. The user must supply one.

Resolution order:
1. Explicit in the current user turn ("for project 4019861").
2. Extracted from a Mixpanel URL the user shared.
3. Carried forward from earlier in this conversation.
4. **Ask the user.** Do not guess. Do not default.

If the user asks to switch projects mid-conversation:
1. Push back, surface the switch, and ask them to confirm explicitly.
2. Only on explicit confirmation, override `project_id`.
3. Never override silently.

---

## Rollout-state encoding

Rollout state lives as a JSON blob inside the flag's `description` field,
wrapped in a fenced marker so the skill can locate it deterministically
and any human-readable description above it stays clean.

### Marker format

```
<human-written description, optional>

<!-- manage-flags-state -->
{ ...JSON... }
<!-- /manage-flags-state -->
```

When reading: find the markers, parse the JSON between them. If markers
are absent, the flag is **unmanaged** by this skill — offer the user the
option to retro-attach.

When writing: preserve any text above the opening marker as the human
description, replace the JSON between the markers, leave nothing after
the closing marker.

### State schema (version 1)

```json
{
  "version": 1,
  "skill": "manage-flags",
  "owner_email": "pm@example.com",

  "metric_ids": {
    "success": "m_abc123",
    "guardrails": ["m_def456", "m_ghi789", "m_jkl012"]
  },

  "ramp_schedule": [10, 25, 50, 100],
  "current_stage_index": 1,
  "stage_started_at": "2026-05-01T10:00:00Z",

  "guardrail_thresholds": {
    "default_relative_degradation_pct": 2.0,
    "overrides": {
      "m_def456": 1.0
    }
  },

  "min_dwell_hours": 24,

  "baselines": {
    "m_abc123": { "value": 0.142, "computed_at": "2026-04-30T22:00:00Z" },
    "m_def456": { "value": 0.018, "computed_at": "2026-04-30T22:00:00Z" }
  },

  "last_eval_at": "2026-05-02T11:00:00Z",
  "last_eval_verdict": "advance",

  "history": [
    {
      "stage_pct": 10,
      "started_at": "2026-04-30T22:00:00Z",
      "ended_at":   "2026-05-02T11:00:00Z",
      "verdict":    "advance",
      "metric_snapshots": {
        "m_abc123": 0.149,
        "m_def456": 0.018
      }
    }
  ],

  "status": "active"
}
```

`status` values: `active` | `paused` | `complete` | `dry_run`.

### Migration safety

If the skill reads a state blob with a `version` it doesn't recognize, it
must stop and surface the mismatch — never silently mutate a future
schema. v1 commands only handle `version: 1`.

---

## Defaults

These defaults apply when the user doesn't override them.

### Ramp schedule

```
DEFAULT_RAMP_SCHEDULE: [10, 25, 50, 100]
```

Users can override per-rollout. Common alternatives: `[1, 5, 25, 100]`
for high-risk changes, `[50, 100]` for low-risk toggles.

### Dwell time

```
MIN_DWELL_HOURS: 24
```

Hard minimum — even if the user requests faster, the skill should warn
that metrics may not have stabilized. The minimum protects against
ramping faster than signal can form.

### Guardrail thresholds

```
DEFAULT_RELATIVE_DEGRADATION_PCT: 2.0
```

A guardrail metric that drops more than 2% relative to its pre-rollout
baseline triggers a pause. Per-metric overrides live in the state blob's
`guardrail_thresholds.overrides`.

### Stabilization buffer for `analyze-impact`

```
DEFAULT_STABILIZATION_DAYS: 7
```

After a flag hits 100%, the "after" window for impact analysis starts 7
days later by default. Users can shorten or lengthen.

### Guardrail set defaults (PM-shaped)

When proposing a guardrail set in `attach-metrics`, the default ordering
of suggestions is:

1. A **business KPI guardrail** — drawn from `Get-Business-Context`
   tracked KPIs if available. Things like revenue per session, paying
   user retention, conversion to paid.
2. A **counter-metric** — the metric most likely to silently regress
   when the success metric improves. Examples:
   - Success: checkout conversion → counter: post-checkout cancellation rate
   - Success: signup conversion → counter: 7-day retention of new signups
   - Success: feature engagement → counter: support ticket volume on the surface
3. A **user-experience guardrail** — error rate, latency, or any
   reliability metric the user defines, if they want one.

If no obvious counter-metric exists, surface that and ask.

### `my-flags` thresholds

```
STUCK_THRESHOLD_WEEKS: 3
```

A flag is **Stuck** if: it's under 100%, no `last_eval_at` update in
the past N weeks, and the PM owns it. Tune per project.

```
RETIRE_REQUIRES_NO_DASHBOARD_REFS: true
```

A flag is only **Ready to retire** if `Search-Entities` finds no
active dashboards referencing it. Override available on explicit user
request.

---

## Statistical posture (passthrough)

This skill **does not** compute statistics itself. When Mixpanel's
compute is incomplete or errored, report "results not ready" and stop.
Do not fall back to hand-rolled lift or significance.

For `analyze-impact` v1: simple before/after comparison on the bound
metrics, with relative lift as the headline number. No confidence
intervals computed in-skill — if the user wants statistical rigor on a
randomized rollout, route them to `manage-experiments`.

---

## Output conventions

- All commands produce structured Markdown output by default.
- Verdicts use a fixed vocabulary:
  - `run-rollout` per-stage: **Advance**, **Hold**, **Pause**.
  - `analyze-impact` final: **Clear win**, **Ambiguous**, **Negative —
    consider rollback**.
  - `my-flags` classifications: **Active**, **Stuck**, **Ready to retire**.
- Never hedge with "it depends." State the verdict, then list the
  reasoning and caveats.
- Structured JSON is available on request for any command.
