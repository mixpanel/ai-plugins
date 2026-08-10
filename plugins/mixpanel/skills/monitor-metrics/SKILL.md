---
name: monitor-metrics
description: >
  Monitor and diagnose a Mixpanel metric for anomalies, drift, and root
  cause. Use whenever the user asks to investigate, debug, monitor, or
  explain a change in a metric tracked in Mixpanel — a saved Metric, KPI,
  conversion rate, retention, event count, funnel step, or anything tracked
  in a saved report or dashboard. Trigger phrases: "monitor [metric]", "what's going on
  with [metric]", "why did [metric] drop/spike", "diagnose this metric",
  "check for anomalies", "has [metric] drifted", "what's driving the drop",
  "where is the movement coming from", "run RCA on this metric". Also
  trigger when the user shares a Mixpanel report/dashboard/metric link and
  asks what's happening, or describes a metric in prose and wants to know if
  the movement is real. Do NOT trigger for portfolio health checks (use
  `weekly-pulse`) or adoption reports (use `gtm-customer-intelligence`).
  Requires a Mixpanel engine — run /mixpanel:install if not set up.
metadata:
  engine: required
---

# Monitor Metrics

> **Engine required** — resolve an engine per [`ENGINE.md`](../../ENGINE.md): one named in the conversation or loaded instructions is mandatory (not set up → offer `/mixpanel:install` for it); otherwise use the Mixpanel MCP server, or offer `/mixpanel:install` if it's unavailable.

A focused diagnostic skill for a single metric at a time. Works for any project the user has access to. Requires a Mixpanel engine. Answers three questions cleanly:

1. **Is a recent point weird?** (anomaly detection — `metric-anomaly`)
2. **Has the baseline itself shifted?** (drift detection — `metric-drift`)
3. **Where is the movement coming from?** (root-cause attribution — `metric-rca`)

Separation matters because the customer conversation is different for each: an anomaly is an incident, drift is a trend, and RCA is the segmentation story that makes either of the first two actionable.

`metric-rca` runs on top of an existing anomaly or drift diagnosis — it consumes the diagnosis payload, fans out across segmentation branches, and appends its findings to the diagnosis board. It does not perform detection itself.

---

## Commands

This skill has three commands. Route to the right one based on the user's ask.

### `metric-anomaly`

Detect point-in-time anomalies — recent spikes, drops, and clusters in a single metric. Fits an additive seasonal baseline (median polish) and flags points by robust residual (MAD-based) against 7-day hourly and 30-day daily series. Produces flagged timestamps, classification (isolated / cluster / edge), and a verdict. **Does not** test for trend-level drift.

Trigger when the user wants to know _whether a specific point looks weird_ — "is this spike real?", "did something happen yesterday?", "is this a blip?".

→ See `commands/metric-anomaly.md`

### `metric-drift`

Detect trend-level drift — whether the baseline has shifted. Runs mean-shift and variance-ratio tests on 60-day daily (last 30 vs prior 30) and 16-week weekly (last 8 vs prior 8) windows. Includes a lightweight outlier contamination check so it can run standalone without `metric-anomaly` first. Produces direction, magnitude, shape (step/slope/oscillating), and a verdict. **Does not** flag individual point anomalies.

Trigger when the user wants to know _whether the trend has changed_ — "has this drifted?", "is the baseline different now?", "what's happened over the last month?".

→ See `commands/metric-drift.md`

### `metric-rca`

Root-cause attribution on top of an existing anomaly or drift diagnosis. Fans out across five branches — component decomposition, default-property breakdowns, distinct-id outliers, cohort comparison, and calendar/market context — over the same date windows the source command used. Ranks findings by concentration and deviation, renders charts for the important ones, and appends results to the diagnosis board.

Trigger when the user wants to know _where the movement came from_ — "what's driving this drop?", "where is the spike concentrated?", "break this down", "run RCA", "is it a specific segment?". Requires a prior `metric-anomaly` or `metric-drift` run in the same session.

→ See `commands/metric-rca.md`

---

## Choosing between the commands

Route by matching the user's ask to the first branch that applies:

- **IF** the ask is ambiguous or exploratory ("something looks off") **→** run `metric-anomaly` first. It is cheaper (2 queries) and catches point-in-time issues that would otherwise contaminate a drift test.
- **IF** the ask is about a trend or baseline change over time (e.g. "has this changed over the last month?", "is the baseline different now?") **→** run `metric-drift` directly.
- **IF** both detection questions matter **→** run `metric-anomaly` first, then `metric-drift`. Drift picks up any anomaly context if present and downgrades confidence accordingly.
- **IF** the user asks "why" or "where" **AND** a diagnosis payload already exists **→** run `metric-rca`.
- **IF** the user asks "why did X drop" (or "what's driving the drop", "where is the movement coming from") **AND** no diagnosis payload exists yet **→** run `metric-anomaly` or `metric-drift` first (whichever fits their framing), then flow into `metric-rca`. Never run RCA cold — it needs the detection payload. These triggers route here **on purpose**: detection first, then RCA.

---

## Classify `metric_type`

Before either detection command fires queries, classify the metric into one of: `count`, `unique_count`, `ratio`, `funnel`, `retention`, `unknown`. Both `metric-anomaly` and `metric-drift` reference this single table — do not duplicate it into the command files.

| Detected | Classification |
| --- | --- |
| Report type `funnels` | `funnel` |
| Report type `retention` | `retention` |
| Query template has A/B form or `% of total` (conversion rate, session rate, etc.) | `ratio` |
| Single-series count (event count, event count distinct users) | `count` |
| Single-series unique count | `unique_count` |
| Formula metric / custom SQL / anything else | `unknown` |

Store as `metric_type` on the metric series object. Used in every verdict card and in special-case routing (funnel, retention).

---

## Output contract

Both commands produce a structured verdict, not a data dump. The commands define their own output formats; common principles:

- **Default to compact.** A CSA scanning between calls needs a verdict in under 60 seconds. Full detail is opt-in.
- **Always chart the trend.** Both commands always render inline charts — whether anomalies/drift were detected or not. A stable metric gets the same charts; the visual confirmation of stability is just as valuable as flagging a problem. Annotation overlays (anomaly dots, drift window shading, change-point markers) only appear when something was flagged.
- **Fixed section order.** Headline → confidence → next step. Never lead with a hedge.
- **Explicit scope limits.** Every output names what it did _not_ do ("this does not test for drift — run `metric-drift`"; "this does not flag individual anomalies — run `metric-anomaly`").

Never output a wall of tables or raw query results. The CSA is the audience, and the goal is a verdict they can act on.

---

## Execution steps

The shared setup and board-handoff steps live in `references/execution.md`:

- **Step 0** — Input validation (project + metric resolution)
- **Step 1** — Metric ingestion (Paths A/B, normalized metric series object)
- **Step 1.5** — Project profile resolution (filter + instrumentation checks)
- **Step 2** — Post-diagnosis handoff and board creation
- **Step 3** — Post-RCA board append

Steps 0, 1, and 1.5 run for `metric-anomaly` and `metric-drift` before any detection query. `metric-rca` does not re-run them — it consumes the diagnosis payload. Read `references/execution.md` before running a command.

---

## When not to use this skill

- **Portfolio-wide sweeps** → use `weekly-pulse`.
- **Full adoption story / QBR prep** → use `gtm-customer-intelligence`.
- **Lexicon / instrumentation health** → use `manage-lexicon`.
- **Just want to know what a chart shows** ("walk me through this report", "what does this tile show") → use `analyze-report`. That skill is the lean read of _what's there_ and deliberately doesn't chase causes. This skill is for statistical detection (anomaly / drift) **plus** RCA. On a bare "what's happening with this report?", start with `analyze-report` and hand off here when the user wants the _why_.
- **Metric definition help** ("how should I measure X?") → answer directly, no skill needed.
- **Root-cause investigation from scratch, without a prior diagnosis** → run `metric-anomaly` or `metric-drift` first, then `metric-rca`. RCA does not run cold.

This skill is deliberately narrow: one metric, one diagnosis, one attribution pass.

---

## Files

- `references/execution.md` — shared setup and board handoff (Steps 0, 1, 1.5, 2, 3)
- `commands/metric-anomaly.md` — point-in-time anomaly detection (additive seasonal baseline + robust residual; 2 queries; 7-day hourly + 30-day daily views)
- `commands/metric-drift.md` — trend-level drift detection (mean shift + variance ratio; 2 queries; 60-day daily + 16-week weekly views; owns shape classification)
- `commands/metric-rca.md` — root-cause attribution (5-branch segmentation fan-out on same windows as source command; ranks findings by concentration × deviation; appends to the diagnosis board)
