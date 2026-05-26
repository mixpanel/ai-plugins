---
name: manage-flags
description: >
  Take a single Mixpanel feature flag through a measured PM-led rollout
  end to end — plan who gets exposed and what the risk is, bind success
  and guardrail metrics, run a staged ramp with auto-pause on regression,
  produce a retrospective, and keep a personalized view of the flags you
  own. Built for Product Managers shipping a feature behind a flag who
  want the rollout measured rather than blind. Trigger phrases: "plan a
  rollout for [feature]", "ship [feature] behind a flag", "ramp this
  flag", "attach metrics to a flag", "start the rollout", "advance the
  rollout", "is the rollout safe", "did this rollout work", "before/after
  on flag", "show me my flags", "what flags do I own", "what's stuck",
  "ready to archive". Also trigger when a user shares a Mixpanel feature
  flag URL or ID. Do NOT trigger for randomized A/B tests (use
  `manage-experiments`).
compatibility: "Requires the Mixpanel MCP (US) feature-flag tool surface — MCP server ID `MIXPANEL_US_MCP_ID`. User must supply a project ID; no hardcoded default."
---

# Manage Flags

A focused skill for Product Managers running a measured rollout behind a
single feature flag, plus a personalized view of the flag portfolio they
own. Five commands, five distinct moments:

1. **Who should this go to, and what's the risk?** → `plan-rollout`
2. **What are we measuring, and what must not regress?** → `attach-metrics`
3. **Run the ramp, with guardrails.** → `run-rollout`
4. **Did it work?** → `analyze-impact`
5. **What's in my portfolio?** → `my-flags`

The skill treats Mixpanel as a closed loop: metrics are committed
*before* the rollout starts, and the same metric IDs are queried at every
ramp stage and in the final readout. The flag, the metrics, and the
analysis are bound together, not separate ad-hoc artifacts.

This skill is the operator-side counterpart to `manage-experiments`. If
the PM wants statistical rigor on a randomized A/B test, they should be
routed to `manage-experiments`. If they want a measured-but-progressive
ship of a feature behind a flag, this is the right skill.

---

## Connector and project rules

**Region binding — US.** This copy of the skill is hardwired to the Mixpanel US data residency region (`api.mixpanel.com`). The active MCP connector is `MIXPANEL_US_MCP_ID` (see `config.md`). Do **not** call Mixpanel MCP tools from a different region — events, metrics, experiments, and flags do not cross residency boundaries. If the user's project lives in a different region, stop and route them to the matching skill folder (`mixpanel-mcu` / `mixpanel-mcu-eu` / `mixpanel-mcu-in`).

Before any command runs, read `config.md`. It defines:

- The active MCP connector.
- The tool surface used by this skill.
- Rollout-state encoding (JSON in the flag's description field).
- Default ramp schedule, dwell time, and guardrail thresholds.
- Stabilization buffer used by `analyze-impact`.

### Project handling

This skill **does not** hardcode a project ID. The user must supply one:

- Explicitly in their request ("project 4019861"), or
- Resolved from a Mixpanel URL they share, or
- Asked for as the first prerequisite step if neither is present.

If the user asks to switch projects mid-conversation after one has been
established, push back, surface the switch, and require explicit
confirmation before overriding. Do not switch silently.

---

## Operating posture

Four rules that shape how every command behaves:

**1. Reuse over creation.** Always search for existing cohorts and saved
metrics before proposing new ones. Duplicates pollute the customer's
library and erode the skill's long-term value. When a fuzzy match exists,
surface it and ask — never silently create alongside.

**2. Pre-registration discipline.** Once metrics are attached and a
rollout is in flight, the metric set is locked. Changing the metric set
mid-rollout requires an explicit re-invocation of `attach-metrics` and is
logged in the flag's rollout-state JSON. The skill never silently swaps
or adds metrics during an active ramp.

**3. Auto-advance, never auto-resume.** Stages can advance automatically
when guardrails are clean. A guardrail breach **pauses** the rollout
(rollout % set to 0 or held at current stage, depending on user
preference). Resuming after a pause requires an explicit human decision
— the skill will not auto-resume even if the breach later normalizes.

**4. PM framing over engineering framing.** Verdicts, metrics, and
output language default to product-and-business terms (conversion,
retention, revenue, support volume) rather than engineering terms
(latency, error rate, throughput). Engineering-style guardrails are
supported, just not the default.

---

## State persistence — the flag's description field

Rollout state lives as a JSON blob in the flag's `description` field. The
skill writes it on `run-rollout` and reads/updates it on every subsequent
invocation. This makes state portable: it travels with the flag,
survives skill re-invocations, and is visible in the Mixpanel UI.

The blob is wrapped in a fenced marker so the skill can find it
deterministically and so any human-readable description above it stays
clean:

```
<human description here, if any>

<!-- manage-flags-state -->
{
  "version": 1,
  "metric_ids": { "success": "...", "guardrails": ["...", "..."] },
  "ramp_schedule": [10, 25, 50, 100],
  "current_stage_index": 1,
  "guardrail_thresholds": { ... },
  "last_eval_at": "...",
  "last_eval_verdict": "advance" | "hold" | "pause",
  "history": [ ... ]
}
<!-- /manage-flags-state -->
```

The full schema lives in `config.md`. Commands read the blob to recover
state, mutate it, and write it back via `Update-Feature-Flag`. If the
blob is absent, the flag is treated as unmanaged by this skill — the
user is offered the option to retro-attach (`attach-metrics` + state
init via `run-rollout`).

---

## Commands

### `plan-rollout`
Pre-flight in one shot. Translates a behavioral description ("power
users in India") into a concrete targeting spec, resolves the segment
to a user count, computes the exposed count at the chosen rollout %,
and flags overlap with high-value or churn-risk users where those
properties exist. Also asks the upfront question: *should this be a
flag rollout, or does it actually want to be an experiment?* If the
answer is experiment, hand off to `manage-experiments > design-experiment`
with the targeting spec pre-filled.

Trigger when the user is at the start of a rollout and hasn't yet
defined the technical targeting or risk profile.

→ See `commands/plan-rollout.md`

### `attach-metrics`
Bind a flag to its measurement plan: typically **1 success metric**
plus **2–3 guardrails** (PM-shaped defaults — revenue, retention, NPS
proxy, support volume — not engineering counter-metrics, though those
are supported). Anchors against the Business Context's tracked KPIs
where possible so the rollout ties back to something leadership already
watches. Reuses saved metrics where they exist; only proposes
`Create-Metric` when no reusable match is found and the user explicitly
confirms.

Can be invoked standalone for a flag that already exists without
metrics, or as a prerequisite inside `run-rollout`.

→ See `commands/attach-metrics.md`

### `run-rollout`
The conductor. Runs a progressive rollout one stage at a time. On
first invocation: pre-flight checks (targeting present, metrics
attached), creates or updates the flag at stage 1's percentage, writes
initial rollout state. On re-invocation: reads state, evaluates the
current stage's metrics against thresholds, and produces a verdict —
**Advance**, **Hold**, or **Pause**.

Invocation-driven by design. The skill does **not** sleep or schedule
itself. The user re-invokes when they want to evaluate a stage.

→ See `commands/run-rollout.md`

### `analyze-impact`
Retrospective readout for a flag at 100% (or recently completed). Reads
the bound metric IDs from rollout state, runs before/after on the
exposed cohort using a configurable stabilization buffer, and produces a
plain-English verdict: **Clear win**, **Ambiguous**, or **Negative —
consider rollback**.

Output is framed for a PM audience: did the hypothesis hold, what
segments responded, what counter-metrics moved, and what this changes
about the next release. Includes a Slack-able paragraph and a
longer-form block for product reviews.

→ See `commands/analyze-impact.md`

### `my-flags`
Personalized portfolio view of the flags the calling PM owns. Three
sections in one digest: *Active* (mid-ramp, how long at current %),
*Stuck* (created more than N weeks ago, still under 100%, no recent
state updates), *Ready to retire* (at 100%, no dashboard references,
safe to archive). This is intentionally narrower than estate-wide
governance — it's the PM's accountability view, not the platform team's.

Every archive recommendation goes through an explicit approval gate.
Never auto-archive.

→ See `commands/my-flags.md`

---

## Routing logic

| User says... | Run |
|---|---|
| "Plan a rollout" / "who should we target" / "design the segment" / "blast radius" | `plan-rollout` |
| "Attach metrics" / "what should we measure" / "set up tracking for the flag" | `attach-metrics` |
| "Start the rollout" / "ramp this" / "advance to next stage" / "check the rollout" | `run-rollout` |
| "Did the rollout work" / "before/after on [flag]" / "post-rollout readout" | `analyze-impact` |
| "My flags" / "what do I own" / "what's stuck" / "ready to archive" | `my-flags` |
| User shares a flag URL with no specific ask | `run-rollout` if state exists, else `analyze-impact` if at 100%, else ask |

If the user says "ship this end to end" without specifying a stage, run
the chain in order: `plan-rollout` → `attach-metrics` → `run-rollout`
(stage 1 only). Each command produces output the user must approve
before the next runs.

If `plan-rollout` returns a recommendation that the work should be an
experiment instead, route to `manage-experiments > design-experiment`
and stop.

---

## Common prerequisites (run before any command)

### Step 0 — Resolve the flag (if applicable)

`plan-rollout` doesn't need a flag yet. Every other command does, except
`my-flags` which scopes by owner.

The user can supply:
- A flag ID
- A flag URL (extract ID from the path)
- A flag name or partial name

For ID or URL: skip to Step 1.

For name: call `List-Feature-Flags` and substring-match (case-insensitive,
exclude archived by default). If exactly one match, use it. If multiple,
surface them and ask which. If none, offer to create — but only inside
`run-rollout` and only after `plan-rollout` has produced a spec.

### Step 1 — Resolve and validate the project

Project ID must come from the user. In order of preference:

1. Explicit in the current turn ("for project 4019861").
2. Extracted from a Mixpanel URL the user shared.
3. Carried forward from earlier in this conversation.
4. **Ask.** Don't guess. Don't default.

If the user attempts to switch projects after one is established in this
conversation, push back and require explicit confirmation.

### Step 2 — Hand off to the command

Each command takes the resolved flag ID (where applicable) and project
ID and runs from there.

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
- Structured JSON is available on request for any command — useful when
  PMs pipe outputs into Slack bots or status pages.

---

## What this skill does NOT do

- **Manage flags across multiple projects.** Single-project scope per
  invocation.
- **Replace Mixpanel Experiments for true A/B tests.** For randomized
  experiments with statistical rigor, route to `manage-experiments`.
  This skill handles measured rollouts, not formal experimentation.
- **Run estate-wide governance.** Naming-convention enforcement,
  duplicate metric detection across the project, and platform-team
  cleanup live elsewhere. `my-flags` is intentionally scoped to the
  calling PM's owned flags only.
- **Compute statistics by hand when Mixpanel's compute fails.** When
  results aren't ready, say so and stop. Don't fall back to hand-rolled
  lift or confidence intervals.
- **Produce QBR/exec slides directly.** Hand off to a slide-generation
  skill if a polished deliverable is needed.
- **Auto-rollback after a guardrail breach.** Auto-pause yes; rollback
  is a one-click human decision in the Mixpanel UI.
