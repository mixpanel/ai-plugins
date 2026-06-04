---
name: experiment-setup
description: "Coach an experimenter through designing a Mixpanel experiment before launch — hypothesis framing, metric roles, statistical model, sizing, advanced features (CUPED / Winsorization / Bonferroni), and pitfall avoidance. Use when the user wants to set up, configure, design, plan, or sanity-check a new A/B test, feature-flag experiment, or growth experiment. Also trigger on phrasings like 'help me set up an experiment', 'design an A/B test', 'should this be sequential or fixed', 'what MDE can I detect', 'how long should this run', 'is my experiment configured correctly', 'pre-launch checklist', 'should I use CUPED / Winsorization / Bonferroni', 'is this an experiment or just a feature flag', or when the user names a specific feature they want to test."
license: Apache-2.0
---

# Experiment Setup

Coach the user through designing a Mixpanel experiment before launch. A well-designed experiment starts from the hypothesis and works backward: the hypothesis dictates the metrics that test it, the metrics dictate the sample size, and the sample size + traffic dictate duration and testing model.

This skill is one place. Everything about pre-launch — hypothesis framing, metric roles, statistical model, sizing, advanced features, prior-experiment reuse, intent routing (experiment vs feature flag), and pitfall detection — lives here. Reach into `references/` only when the current step needs the depth.

## Requirements

- Access to Mixpanel (event schema, run queries, create experiments and feature flags).
- Access to a "prior experiments" lookup (e.g. `search_prior_experiments`) when one is available — the skill works without it, but degrades gracefully and tells the user what it skipped.

## When to use this skill

Trigger on any of:

- "Set up / design / configure / plan an experiment on `<feature>`."
- "Help me write a hypothesis."
- "What MDE can I detect with my current traffic?"
- "Should this be sequential or fixed-horizon?"
- "Should I enable CUPED / Winsorization / Bonferroni?"
- "How long should this experiment run?"
- "Is this an experiment or should I just ship a feature flag?"
- "Sanity-check / pre-launch / pitfall-check this experiment configuration."

Do **not** trigger for post-launch analysis ("how did experiment X do?") — that's the `analyze-experiment` skill.

## XP vs FF: route before you design

Before any setup work, decide whether the user actually wants an **experiment** (XP) or just a **feature flag** (FF). The intent is often blurry.

- Wants causal evidence (lift, ship/no-ship from data) → experiment.
- Wants progressive rollout, kill-switch, or per-segment gating with no decision criterion → feature flag.

If you can't tell, ask:

> "Are you trying to measure whether this change moves a metric (experiment), or are you rolling it out gradually / behind a flag with no measurement criterion (feature flag)? An experiment commits to a hypothesis, metrics, and a stopping rule; a feature flag is purely a delivery mechanism."

Read `references/routing-xp-vs-ff.md` if the user pushes back or the intent is ambiguous. Once the intent is "experiment," continue with the setup workflow below.

## Before suggesting any setup: check for prior work

When the user names a feature to test, **always look for prior experiments on that feature first** (call `search_prior_experiments` with keywords from the feature name when the tool is available). Surface anything you find:

- Same feature already tested → reference prior results before recommending a new test. Don't re-run a settled question.
- Earlier iteration of the same hypothesis → use prior baseline rates and variance to inform the new MDE.
- Recently concluded with similar metrics → pull the realised exposure rate to set a realistic duration.

Skipping this check leads to redundant tests, contradictory ship decisions, and wasted traffic. See `references/prior-experiments.md` for how to fold prior results into the new design.

## Workflow: a 4-step setup sequence

Run these in order. Each step's output is the next step's input — don't skip.

### Step 1 — Write the hypothesis

A good hypothesis is a **falsifiable directional claim with a stated mechanism**:

> **If** `<change>`, **then** `<measurable outcome>` will `<direction>`, **because** `<mechanism>`.

Examples:

- ✅ _"If we surface a free-item offer during onboarding, then signup→activation conversion will increase by ≥3pp, because reducing first-action friction lowers cold-start dropout."_
- ✅ _"If we move 'Create New' to the top of the nav, then weekly core-report-creator rate will increase by ≥5%, because discoverability is the current bottleneck."_
- ❌ _"Test the new onboarding."_ — no outcome, no direction, no mechanism.
- ❌ _"Improve user engagement."_ — engagement isn't a metric; "improve" isn't directional.

If the hypothesis is vague, ask the user to commit to:

1. The change (what's different in treatment).
2. The primary outcome metric (one specific event or rate).
3. The expected direction (up or down).
4. The minimum effect size that would justify shipping (this becomes the MDE).
5. The mechanism (why you expect this to work).

The mechanism matters: it forces the user to think about whether the metric they picked is actually downstream of the change. A change to onboarding screens shouldn't be measured by Day-30 retention if no one has gotten to Day 30 yet.

For the deeper rubric (falsifiability, directionality, mechanism, time-bounding) and common misalignment patterns, read `references/hypothesis-framing.md`.

### Step 2 — Pick metrics that actually test the hypothesis

Each metric serves one of three roles. The hypothesis dictates the assignment.

- **Primary metrics (1–3 max).** Decide ship/no-ship. Come straight from the hypothesis's outcome clause. Each additional primary inflates the false-positive rate.
- **Guardrail metrics (0+, strongly recommended).** Must not regress. A >5% relative regression on any guardrail blocks ship even if the primary wins (the "hard gate").
- **Secondary metrics (0+, diagnostic only).** Help explain _why_ the primary moved. **Not** decisional.

Every primary and guardrail needs an explicit `direction` (`"up"` or `"down"`). The system defaults to `"up"`, which is wrong for cancel / error / latency / abandon metrics — leaving it default silently flips polarity at interpretation time.

Match each metric's response window to the experiment's duration. A 2-week experiment on a 30-day retention primary will conclude before the primary can move; expect either false significance from noise, or "no effect" on a real effect that hasn't arrived yet. When the only metric the team cares about is lagging, use a leading proxy as primary and demote the lagging metric to a post-launch monitor.

Watch for the **changed-denominator** trap: if a metric's denominator is created by the treatment itself, lift will be artificially infinite. The classic case is a metric defined as "users who saw the new flow → conversion" — control users never see the flow, so the denominator is zero and the comparison is meaningless.

The full sanity checklist, the standard guardrails by domain, and the rule for promoting hypothesis-mentioned secondaries to primary are in `references/metric-selection.md`.

### Step 3 — Size the experiment using historical data

You almost never know the right sample size by guessing. Pull the data first.

Standard formula for required sample size per variant (two-sample, two-sided test at 95% confidence, 80% power):

```
n = 16 × σ² / d²
```

Where `σ²` is the variance of the metric and `d` is the MDE in the same units as the metric. For a Bernoulli (conversion) metric, `σ² = p(1−p)`.

**Worked example.** Detecting a 5% **relative** lift on a 10% baseline conversion rate at 80% power, 95% confidence:

```
p = 0.10        →  σ² = 0.10 × 0.90 = 0.09
absolute MDE   = 0.10 × 0.05 = 0.005
n              = 16 × 0.09 / 0.005² = 57,600 per variant
```

~57.6k per variant for a 5% relative lift — humbling, and surprising to most teams. Use this number when the user proposes "a quick 2-week test" on a metric that doesn't have the volume to support it.

**Kohavi's inverted formula** (use when traffic, not patience, is the constraint):

```
MDE = 4σ / √n
```

This tells the user: "given your traffic, the smallest effect you can reliably detect is X." If that achievable MDE is larger than the lift the user actually expects, the experiment is **underpowered** — surface this immediately. Underpowered experiments suffer from **winner's curse**: if you do reach significance, the lift estimate is exaggerated because only the high-variance positive realisations crossed the threshold.

**Sample-size floor.** Never set `sampleSize` below ~350–400 per variant regardless of the math — below this the statistical machinery itself becomes unreliable (CLT breaks down, SRM check gets noisy).

For the input-estimation playbook (how to pull baseline rate, variance, and daily traffic from Mixpanel), the full per-baseline lookup table, and the five remediations when the experiment is underpowered, read `references/sizing.md`.

### Step 4 — Choose a testing model and end condition

Two settings remain: `settings.testingModel` and `settings.endCondition`.

**Default to `sequential`** for most users. Peeking is the most common Mixpanel customer mistake, and sequential testing makes early-look safe. Override to `frequentist` when the user explicitly hunts for a small lift (1–2% relative on high-volume metrics) on a well-sized experiment, or when the team prefers wider industry familiarity ("we used a t-test").

For end condition:

- **`sample_size`** — stop when the per-variant target is hit. Use when daily traffic is variable.
- **`days`** — stop at a fixed date. Use when the primary metric has strong weekly (or other periodic) seasonality, so each variant sees the same mix of high- and low-traffic periods. Customers with sharp weekday/weekend behavior typically run experiments in 1- or 2-week increments.

Frequentist + days is a supported combination — don't flag it.

**Confidence level.** Default 0.95 (α = 0.05). Bump to 0.99 only for high-stakes irreversible ships (billing, etc.) and accept the increased Type-II error. Drop to 0.90 only for low-stakes exploratory tests where speed matters more than rigor — and tell the user explicitly that the family-wise false-positive rate is inflated.

**Multiple testing correction** kicks in when `len(primary_metrics) ≥ 2` OR `len(non_control_variants) ≥ 2`. Default to `"benjamini-hochberg"` (controls false-discovery rate, more powerful with correlated metrics). Use `"bonferroni"` when the user needs strict family-wise error control (regulatory, high-stakes). Set `"off"` only with a single primary and a single non-control variant. Without correction, the family-wise FPR climbs fast: 2 primaries × 1 variant → ~9.75%, 5 × 1 → ~22.6%, 5 × 3 → ~53.7%.

For the full sequential-vs-frequentist decision tree, end-condition reasoning, and worked numbers on confidence-level trade-offs, read `references/statistical-model.md`.

## Advanced features

Three optional features are worth enabling in the right situations. The full rationale lives in `references/advanced-features.md`; the short version:

- **CUPED** (`settings.cuped.enabled`). Reduces variance 30–70% on metrics that correlate with pre-exposure behaviour (revenue, engagement, retention). Cuts required sample size by the same amount. Enable when (a) the primary metric correlates with pre-exposure behaviour and (b) all experiment users existed before the experiment start (no new-user-only cohorts) and (c) a 2–4 week pre-exposure window is available with stable behaviour. Do **not** enable on new-user-only experiments, brand-new metrics, or metrics where pre-exposure behaviour is not predictive (e.g. one-time onboarding events).

- **Winsorization** (`settings.winsorization.enabled`, default `percentile: 95`). Caps the top and bottom 5% of values. Enable for heavy-tailed Gaussian-like metrics: revenue/spend with whales, time-on-page with sleepers, session duration with bots. Do **not** enable on Bernoulli (conversion) metrics — capping a 0/1 outcome is meaningless. Push back if the user sets `percentile < 80` (that's >20% of values capped — almost always a misconfiguration).

- **Multiple testing correction**. See Step 4 above.

## Pre-launch pitfall check

Before the user creates the experiment, run through the pitfall catalogue in `references/pitfalls.md`. Surface only the ones that actually fire on the current config. Order: blockers first, then warnings, then fyi.

The two **blockers** that should stop the user from launching:

- **`underpowered_duration_insufficient`** — expected exposures < 50% of the per-arm sample size required to detect the configured MDE. The experiment literally cannot reach statistical power.
- **`cohort_too_small`** — the eligible cohort is smaller than `num_arms × target_sample_size`. The experiment will run out of eligible users before each arm reaches the target.

The most common **warnings**:

- `pre_experiment_bias_likely` — pre-experiment bias detected on a continuous-ish metric and CUPED is off.
- `high_variance_no_winsorization` — continuous-ish metric configured and Winsorization is off.
- `multiple_primaries_no_bonferroni` — multiple primaries configured and multiple-testing correction is off.
- `missing_guardrails` — no guardrails configured (and therefore no hard gate against regressions).
- `hypothesis_metric_mismatch` — the hypothesis text mentions a metric/noun that doesn't appear in any primary's name.
- `primary_lacks_leading_indicator` — primary is retention-typed (lagging by construction) and no leading-indicator secondary is set, so there's nothing to read mid-flight.

The **>5% guardrail hard-gate** rationale: a 5% relative regression on any guardrail blocks ship even if the primary wins. Guardrails are the trustworthiness backstop. A winning primary with a regressing guardrail means the change exchanged headline-metric lift for damage to something the team explicitly said must not regress — not a ship.

## Output

When the design is locked, present a compact summary the user can confirm before you call `create_experiment`:

```
*Experiment Setup Summary*

• *Hypothesis:* If <change>, then <metric> will <direction> by ≥<MDE>, because <mechanism>.
• *Primary metrics:* <name> (direction: up/down), …
• *Guardrails:* <name> (direction: …), …
• *Variants:* control 50% / treatment 50% (or as configured)
• *Statistical model:* sequential | frequentist
• *End condition:* sample_size (per-arm <N>) | days (<N> days)
• *Confidence level:* 0.95
• *Multiple testing correction:* benjamini-hochberg | bonferroni | off
• *Advanced features:* CUPED on/off · Winsorization on/off (percentile <P>)
• *Expected duration on current traffic:* <D> days
• *Achievable MDE on current traffic:* <X>% relative

*Pitfall check:*
✅ Underpowered duration — adequate
✅ Cohort size — adequate
⚠️ <pitfall name> — <short explanation>
```

Wait for explicit confirmation before creating the experiment.

## Edge cases

- **Hypothesis given as a one-liner.** Coach on the four properties (Step 1). Don't proceed until the user commits to direction and MDE.
- **No baseline data available** (brand-new metric or feature). Tell the user you cannot size the experiment. Options: run a 1-week observation period first, use a proxy metric with historical data, or accept a very large MDE and label the test exploratory.
- **Multi-arm test (3+ variants).** Each treatment vs control is its own statistical comparison; sample size grows per non-control variant. Even split (e.g. 33/33/33) is usually correct. Multiple-testing correction is non-negotiable.
- **Risk-asymmetric rollout.** If the treatment is a risky billing change, 80/20 control/treatment is fine. Lift estimates stay valid; total exposures need to grow to reach the same power.
- **User insists on peeking with frequentist.** Switch them to sequential. Frequentist + peeking inflates the false-positive rate; sequential makes early-look safe.
- **User wants no guardrails.** Push back. Guardrails are the regression detection, not the noise. If they refuse, log the decision in `description` so the post-launch interpretation knows.

## Writing style

- Lead with the hypothesis. Every other decision flows from it.
- Use concrete numbers from real data ("baseline 4.2%, σ² = 0.040, required n ≈ 6,400/arm") rather than vague guidance ("you'll need a decent sample").
- Quote the user's own MDE and metric names back at them so they catch typos.
- When the experiment is underpowered, say so plainly; list the remediations in order of cost.
- Don't moralise about peeking — switch them to sequential.
- Guardrail regressions are hard gates, not "slight concerns."

## Related skills

- `analyze-experiment` — post-launch results analysis. Use after the experiment ships and reaches its end condition.
- `create-dashboard` — build a live dashboard of the primary + guardrail metrics for monitoring during the experiment.

## References

- `references/hypothesis-framing.md` — the four properties of a good hypothesis; hypothesis ↔ metric alignment patterns.
- `references/metric-selection.md` — primary / guardrail / secondary roles, lagging-indicator trap, full sanity checklist.
- `references/sizing.md` — sample-size math, inverted formula, input-estimation playbook, lookup table, five remediations for underpowered experiments.
- `references/statistical-model.md` — sequential vs frequentist decision tree, end-condition reasoning, confidence level, multiple-testing correction.
- `references/advanced-features.md` — CUPED, Winsorization, Bonferroni / Benjamini-Hochberg.
- `references/routing-xp-vs-ff.md` — XP vs FF intent disambiguation.
- `references/prior-experiments.md` — how to fold prior results into a new design.
- `references/pitfalls.md` — the full pitfall catalogue with severities, message templates, and thresholds.
