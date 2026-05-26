# Command: analyze-impact

Retrospective readout for a flag at 100% (or recently completed).
Reads the bound metric IDs from rollout state, runs before/after on the
exposed cohort using a configurable stabilization buffer, and produces
a plain-English verdict: **Clear win**, **Ambiguous**, or **Negative —
consider rollback**.

Output is framed for a PM audience. The headline answers three
questions:

1. Did the hypothesis hold?
2. What moved, by how much, with what confidence (passthrough only —
   never hand-computed)?
3. What does this mean for the next release?

---

## Prerequisites

Steps 0 and 1 from `SKILL.md` must complete.

The flag's rollout-state JSON must exist and contain `metric_ids` and
`baselines`. If state is missing, the flag is unmanaged by this skill —
surface the gap and offer `attach-metrics` + retro-baseline as a path
forward.

Connector and project ID come from `config.md`.

---

## Phase 1 — Validate readiness

**Step 1: Check rollout status.**

The flag's state should be `status: "complete"`. If not:

- `active` and below 100% → not ready for impact analysis, recommend
  `run-rollout` instead.
- `paused` → impact analysis on a paused rollout is rarely meaningful,
  but offer it on explicit user request with a clear caveat.
- `dry_run` → impact analysis on a dry run is supported but flagged in
  the output.

**Step 2: Check the stabilization buffer.**

After the flag hit 100%, the "after" window starts after a buffer (default
7 days, from `config.md`). If `now - stage_started_at` (for the final
stage) is less than the buffer, surface that and stop — the post-100%
window hasn't stabilized.

User can override with explicit "analyze now anyway" — flag the result
as "early readout."

---

## Phase 2 — Pull before/after for every bound metric

For each metric in `metric_ids`:

- **Before window:** the baseline window used at `attach-metrics` time
  (typically last 14 days *before* stage 1 started).
- **After window:** starts at `stage_100pct_committed_at +
  stabilization_buffer`, extends to `now`.

`Run-Query` per metric, scoped to:

- The **targeted cohort** for the before window (the users who *would
  have* been exposed if the flag had been at 100% before).
- The **exposed cohort** for the after window (users currently flipped
  on by the flag at 100% — which should be the same population modulo
  churn).

Surface both raw values and the relative lift.

If Mixpanel's compute errors or returns null for any metric: report
"results not ready for `<metric_name>`" and stop — passthrough posture.

---

## Phase 3 — Anchor against Business Context

Call `Get-Business-Context` once. For each bound metric, check whether
the metric appears in (or maps closely to) a tracked business KPI.

This matters for the PM framing of the verdict. A success metric that
maps to a tracked KPI ("our north-star metric is paid conversion, this
test moved it from 4.1% to 4.3%") lands very differently in a product
review than the same number framed as an isolated rate.

If no business-context match exists, continue but soften the framing
("conversion improved 4.9%, though this isn't a metric currently
tracked as a business KPI for the project").

---

## Phase 4 — Apply the verdict

Three possible verdicts. Apply in order:

| Condition | Verdict |
|---|---|
| Success metric improved AND no guardrail breached by more than its threshold | **Clear win** |
| Success metric flat or guardrails mixed (some improved, some regressed within tolerance) | **Ambiguous** |
| Success metric regressed OR any guardrail regressed beyond its threshold | **Negative — consider rollback** |

Surface the reasoning explicitly. The PM should be able to defend the
verdict in a product review without re-deriving it from the table.

---

## Phase 5 — Frame for the PM audience

The output has three layers, all in one response:

### Layer 1 — Slack-able paragraph

A 3–5 sentence block the PM can paste into a team channel. Should
include the feature name, the verdict, the success metric and its
movement, and the strongest counter-signal (or "no counter-signals").

### Layer 2 — Long-form block

Designed for product reviews and roadmap docs. Includes:

- **Hypothesis recap** — what we expected to move and by how much (from
  the original spec if captured; otherwise reconstructed from metric
  intent).
- **What happened** — before/after table with relative lifts.
- **Counter-signals** — anything that moved against expectation.
- **Segment notes** — if obvious cuts surface meaningful differences,
  call them out. *Do not* run an exhaustive segment sweep — this is a
  PM retrospective, not a forensic diagnosis.
- **Roadmap implications** — phrased as questions the PM should bring
  to their next planning meeting. Avoid prescriptive recommendations.

### Layer 3 — State update

Write back to the flag's rollout-state JSON:

- Append the impact result to `history` with the verdict and
  per-metric snapshot.
- Optional: update `status` from `complete` to `archived` if the user
  explicitly confirms (most won't).

---

## Output

```markdown
## Impact Analysis — <flag name>

**Verdict:** ✅ Clear win
**Window:** Before = 14d pre-stage-1 / After = 7d post-100%

---

### Slack-able

We rolled out the new checkout CTA copy to 100% on May 14. Over the
7-day post-stabilization window, checkout conversion moved from 14.2%
to 14.9% (+4.9% relative). Revenue per session and cancellation rate
held within tolerance. No counter-signals — calling this a clear win.

---

### Full readout

**Hypothesis (inferred from spec):**
- New CTA copy will improve checkout completion by 3–5% relative,
  without increasing post-checkout cancellations.

**What happened:**
| Metric | Before | After | Δ | Business KPI? |
|---|---|---|---|---|
| `checkout_conversion_v2` (success) | 14.2% | 14.9% | +4.9% | ✅ Tracked |
| `revenue_per_session` | $4.18 | $4.24 | +1.4% | ✅ Tracked |
| `post_checkout_cancellation_rate` (counter) | 1.8% | 1.8% | 0% | — |
| `error_rate_checkout_surface` | 0.18% | 0.17% | -5.6% | — |

**Counter-signals:** None. The counter-metric (post-checkout cancellation)
held flat. Error rate improved marginally (likely noise).

**Roadmap implications:**
- Are there adjacent CTAs in the funnel where the same pattern could
  apply (cart, post-cart, payment selection)?
- Did the lift come uniformly across new and returning users, or is it
  concentrated in one segment? Worth a quick `Run-Query` cut before
  the next planning meeting.

---

### State updated
- Result appended to flag history.
- Recommend: leave the flag at 100% for one more reporting cycle, then
  archive via `my-flags > Ready to retire`.
```

---

## What this command does NOT do

- **Run an exhaustive segment sweep.** A PM retrospective is not a
  forensic root-cause investigation. If the PM wants deep slicing, hand
  off to `analyze-chart` or a chart-specific skill — but not via this
  skill's auto-route logic.
- **Recompute baselines.** Baselines were locked at `attach-metrics`
  time. If the PM doesn't trust them, they should re-invoke
  `attach-metrics` and re-baseline before reading the impact result.
- **Compute confidence intervals.** Passthrough — relative lift only.
  For statistical rigor, point at `manage-experiments`.
- **Auto-archive the flag.** Archival is a `my-flags` operation, with
  an explicit approval gate.
- **Generate slide-ready visuals.** The Markdown output is the
  deliverable. Slide generation belongs to a separate skill.
