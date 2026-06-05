---
name: experiment-setup
description: "Coach an experimenter through designing a Mixpanel experiment before launch — hypothesis framing, metric roles, statistical model, sizing, advanced features (CUPED / Winsorization / Bonferroni), and pitfall avoidance. Use when the user wants to set up, configure, design, plan, or sanity-check a new A/B test, feature-flag experiment, or growth experiment. Also trigger on phrasings like 'help me set up an experiment', 'design an A/B test', 'should this be sequential or fixed', 'what MDE can I detect', 'how long should this run', 'is my experiment configured correctly', 'pre-launch checklist', 'should I use CUPED / Winsorization / Bonferroni', 'is this an experiment or just a feature flag', or when the user names a specific feature they want to test. Do NOT use for post-launch results analysis ('how did experiment X do?', 'should we ship?', 'why is SRM failing?') — that belongs to the `experiment-results` skill. Do NOT use for plain feature-flag rollouts with no measurement criterion — that belongs to the `feature-flags` skill."
license: Apache-2.0
---

# Experiment Setup

Coach the user through designing a Mixpanel experiment before launch. A well-designed experiment starts from the hypothesis and works backward: the hypothesis dictates the metrics that test it, the metrics dictate the sample size, and the sample size + traffic dictate duration and testing model. Reach into `references/` only when a step needs depth.

## Requirements

- Access to Mixpanel (event schema, run queries, create experiments and feature flags).
- Access to a prior-experiments lookup when one is available — the skill works without it, but degrades gracefully and tells the user what it skipped.

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

Do **not** trigger for post-launch analysis ("how did experiment X do?") — that's the `experiment-results` skill.

---

## Pre-flight: route and check for prior work

**Route XP vs FF before designing.** Wants causal evidence (lift, ship/no-ship from data) → experiment. Wants progressive rollout, kill-switch, or per-segment gating with no decision criterion → feature flag (route to the `feature-flags` skill). If ambiguous, ask once: "Are you measuring whether this change moves a metric (experiment), or rolling it out gradually with no measurement criterion (feature flag)?" Deeper disambiguation in [references/routing-xp-vs-ff.md](references/routing-xp-vs-ff.md).

**Always search for prior experiments on the same feature first** (by keyword from the feature name, when the lookup is available). Surface anything you find — re-running settled questions wastes traffic, and prior baseline/variance numbers sharpen the new MDE. See [references/prior-experiments.md](references/prior-experiments.md) for the fold-in playbook.

---

## Workflow: 4 steps

Run in order. Each step's output is the next step's input.

### Step 1 — Write the hypothesis

A good hypothesis is a **falsifiable directional claim with a stated mechanism**:

> **If** `<change>`, **then** `<measurable outcome>` will `<direction>`, **because** `<mechanism>`.

If vague, hold the user to four commitments: the change, the primary metric, the direction, and the smallest effect worth shipping (the MDE). The "because" forces them to check whether the metric they picked is actually downstream of the change. Deeper rubric and misalignment patterns in [references/hypothesis-framing.md](references/hypothesis-framing.md).

### Step 2 — Pick metrics that test the hypothesis

Each metric serves one role:

- **Primary (1–3 max).** Decides ship/no-ship. Comes from the hypothesis's outcome clause. Each additional primary inflates the false-positive rate.
- **Guardrail (0+, strongly recommended).** Must not regress. A >5% relative regression on any guardrail blocks ship even if the primary wins.
- **Secondary (0+).** Diagnostic only. Never decisional.

Every primary and guardrail needs an explicit `direction` (`"up"` or `"down"`). The default `"up"` is wrong for cancel / error / latency / abandon metrics — leaving it default silently flips polarity at interpretation. Watch for **lagging-metric / window mismatch** (30-day retention as primary on a 2-week experiment) and the **changed-denominator** trap (metric defined only over treatment-exposed users). Full sanity checklist in [references/metric-selection.md](references/metric-selection.md).

### Step 3 — Size the experiment with historical data

Pull baseline rate, variance, and daily traffic from Mixpanel; don't guess. The standard formula (two-sample, two-sided, 95% confidence, 80% power):

```
n = 16 × σ² / d²     (per variant; Bernoulli σ² = p(1−p))
```

Inverted for traffic-bound teams — the smallest detectable effect at your traffic:

```
MDE = 4σ / √n
```

If the achievable MDE exceeds the user's expected lift, the experiment is **underpowered** — surface this immediately (winner's curse, etc.). Sample-size floor: never below ~350–400 per variant (CLT breaks down, SRM check gets noisy). Worked examples, baseline-lookup table, and the five remediations for underpowered experiments are in [references/sizing.md](references/sizing.md).

### Step 4 — Pick testing model + end condition

**Default to `sequential`** for most users. Peeking is the most common customer mistake; sequential makes early-look safe. Override to `frequentist` for small-lift hunts on well-sized experiments, or when the team needs t-test familiarity.

**End condition.** `sample_size` when daily traffic is variable; `days` when the primary metric has strong weekly seasonality. Frequentist + days is supported — don't flag it.

**Confidence level.** Default 0.95. Bump to 0.99 only for irreversible high-stakes ships; drop to 0.90 only for exploratory low-stakes tests (and tell the user the family-wise FPR is inflated).

**Multiple-testing correction.** Auto-needed when `len(primary_metrics) ≥ 2` OR `len(non_control_variants) ≥ 2`. Default to `"benjamini-hochberg"`; use `"bonferroni"` for strict family-wise control (regulatory). Without correction the family-wise FPR climbs fast — 5 primaries × 3 variants → ~54%.

Full decision tree and worked numbers in [references/statistical-model.md](references/statistical-model.md).

---

## Advanced features (rationale: [references/advanced-features.md](references/advanced-features.md))

- **CUPED** — variance reduction. Enable when the primary metric correlates with pre-exposure behaviour AND all experiment users existed before start AND 2–4 weeks of stable pre-exposure history exists. Do not enable on new-user-only experiments or one-time-event metrics.
- **Winsorization** — caps extreme values. Enable for heavy-tailed continuous metrics (revenue, time-on-page, session duration). Do not enable on Bernoulli metrics. Push back if `percentile < 80`.

## Pre-launch pitfall check

Before the user creates the experiment, run the pitfall catalogue in [references/pitfalls.md](references/pitfalls.md). Surface only what fires on the current config; order blockers → warnings → fyi.

Two **blockers** that should stop launch:

- `underpowered_duration_insufficient` — expected exposures < 50% of per-arm sample size for the configured MDE.
- `cohort_too_small` — eligible cohort < `num_arms × target_sample_size`.

The **>5% guardrail hard-gate** rationale: a 5% relative regression on any guardrail blocks ship even if the primary wins. A winning primary with a regressing guardrail trades headline lift for damage to something the team explicitly said must not regress — not a ship.

---

## Output

Present a compact summary the user confirms before you create the experiment:

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

## Writing style

- Lead with the hypothesis. Every other decision flows from it.
- Use concrete numbers from real data ("baseline 4.2%, σ² = 0.040, required n ≈ 6,400/arm"), not vague guidance.
- Quote the user's MDE and metric names back so they catch typos.
- When underpowered, say so plainly and list remediations in order of cost.
- Don't moralise about peeking — switch them to sequential.
- Guardrail regressions are hard gates, not "slight concerns."

## Related skills

- `experiment-results` — post-launch analysis. Use after the experiment ships.
- `feature-flags` — pure rollout / kill-switch / gating without measurement.
- `create-dashboard` — live monitoring of primary + guardrail metrics during the experiment.
