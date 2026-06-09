---
name: design-experiment
description: "Coach an experimenter through designing a Mixpanel experiment before launch — hypothesis framing, metric roles, statistical model, sizing, advanced statistical features (variance reduction via CUPED, outlier capping via Winsorization, false-positive correction via Bonferroni / Benjamini-Hochberg), and pitfall avoidance. Use when the user wants to set up, design, configure, plan, or sanity-check a new A/B test, feature-flag experiment, or growth experiment. Also trigger on phrasings like 'help me set up an experiment', 'design an A/B test', 'should this be sequential or fixed-horizon', 'what minimum detectable effect can I get', 'how long should this run', 'is my experiment configured correctly', 'pre-launch checklist', 'should I use variance reduction or outlier capping', 'is this an experiment or just a feature flag', or when the user names a specific feature they want to test. Do NOT use for post-launch results analysis ('how did experiment X do?', 'should we ship?', 'why is Sample Ratio Mismatch failing?') — that belongs to the `interpret-experiment` skill. Do NOT use for plain feature-flag rollouts with no measurement criterion — that belongs to the `feature-flags` skill."
license: Apache-2.0
---

# Design Experiment

You are helping a user design a Mixpanel experiment before launch. A well-designed experiment starts from the hypothesis and works backward: the hypothesis dictates the metrics that test it, the metrics dictate the sample size, the sample size + traffic dictate duration and testing model. **Don't create the experiment until the user explicitly confirms the configuration** — once it's live, mid-flight config changes invalidate the test.

---

# Glossary

Concepts the rest of this skill uses without redefining.

- **Hypothesis.** A falsifiable, directional claim with a stated mechanism, bounded in time. Shape: _"If `<change>`, then `<metric>` will `<direction>` by ≥`<MDE>`, because `<mechanism>`."_ Every other decision flows from this.
- **Variant.** One arm of the experiment. The variant treated as the baseline is the **control**; the others are **treatments**.
- **Primary / Guardrail / Secondary metric.**
  - **Primary** — drives the ship decision. Cap at 3; the platform applies multiple-testing correction across primaries.
  - **Guardrail** — must not regress; a >5% relative regression on any guardrail blocks ship even when primaries win.
  - **Secondary** — diagnostic only, never decisional.
- **Direction.** Whether bigger is better for a metric (`up`) or smaller is better (`down`). Cancel / error / latency / abandon / refund metrics need `down` set explicitly — leaving the default silently flips polarity at interpretation.
- **MDE (Minimum Detectable Effect).** The smallest lift the experiment is sized to detect. Sets the required sample. Comes from the user, not from the platform.
- **Power.** The probability the experiment detects a true effect of size MDE. Default 80%.
- **Underpowered.** Achievable MDE on available traffic exceeds the user's expected lift. Most likely outcome is "inconclusive"; reachable significance is biased upward (winner's curse).
- **CUPED.** Variance-reduction technique using pre-exposure baseline. Cuts required sample 30–70% when the metric correlates with pre-exposure behaviour. Inert on new-user-only cohorts.
- **Winsorization.** Outlier capping at a configured percentile. Default 95 (verify in product). Cuts variance on heavy-tailed continuous metrics; meaningless on Bernoulli metrics.
- **Multiple-testing correction.** Adjusts per-test significance threshold when several primaries or several non-control variants are tested together. Default Benjamini-Hochberg; Bonferroni for strict family-wise control.
- **Sequential vs Frequentist testing.** Sequential makes peeking safe (boundary-based stopping); Frequentist requires a fixed sample committed up front. Most users should default to Sequential.

---

# Components

The pieces every design uses. Defined here once so they don't drift across the steps and references.

## Sizing formulas

Required sample per variant (two-sample, two-sided, 95% confidence, 80% power):

```
n = 16 × σ² / d²
```

Inverted for traffic-bound teams — the smallest effect detectable on available traffic (Kohavi's inversion):

```
MDE = 4σ / √n
```

The `16` is `(z_{α/2} + z_β)² × 2` rounded. Variance `σ²` depends on metric type: Bernoulli `p(1−p)`; Poisson `≈ mean`; Gaussian computed from data. The full derivation, worked examples, lookup table, and the five remediations for underpowered experiments live in [references/sizing.md](references/sizing.md).

## The >5% guardrail hard-gate

A **5% relative regression on any guardrail blocks ship**, even when the primary wins. Guardrails are the trustworthiness backstop; without this rule, a winning primary with a quietly regressing guardrail ships and rolls back two weeks later. Below 5% lives in the noise band of most guardrails; above 5% means the team has traded measurable damage for headline lift. If the user wants to ship past a regressing guardrail, force the conversation — disable the guardrail explicitly and document why. Don't let them silently override. Full rationale in [references/pitfalls.md](references/pitfalls.md).

## Pre-launch pitfall catalogue

Before creating the experiment, run the deterministic pre-launch checks against the configuration. Surface results in triage order: **blockers** (an experiment that can't reach statistical power), **warnings** (configuration smells that degrade trustworthiness), then **fyi**. The two blockers today are: insufficient duration for the configured MDE on available traffic; and a cohort too small to supply enough eligible users. The full catalogue, severities, and rationale live in [references/pitfalls.md](references/pitfalls.md).

---

# Steps

Top-down: what to do, in order.

## 1. Route and check for prior work

**Route Experiment vs Feature Flag first.** Wants causal evidence (lift, ship/no-ship from data) → experiment. Wants progressive rollout, kill switch, or per-segment gating with no measurement criterion → feature flag (route to the `feature-flags` skill). If ambiguous, ask once: _"Are you measuring whether this change moves a metric (experiment), or rolling it out gradually with no measurement criterion (feature flag)?"_ Deeper disambiguation in [references/routing-xp-vs-ff.md](references/routing-xp-vs-ff.md).

**Check for prior experiments on the same feature.** Search the project by keywords drawn from the feature name. If a prior-experiments lookup isn't available, say so explicitly — don't fabricate "no priors found." Surface anything you find: a same-feature ship suggests "don't re-run, iterate on a new hypothesis"; a prior kill is a strong prior the user has to argue past; an earlier iteration gives you reliable baseline and variance numbers that sharpen the new MDE. Fold-in playbook in [references/prior-experiments.md](references/prior-experiments.md).

## 2. Write the hypothesis

A good hypothesis is a **falsifiable, directional claim with a stated mechanism, bounded in time**:

> **If** `<change>`, **then** `<measurable outcome>` will `<direction>` by ≥`<MDE>`, **because** `<mechanism>`.

If the user is vague, hold them to five commitments: the change, the primary metric, the direction, the MDE, the mechanism. The "because" forces them to check whether the metric they picked is actually downstream of the change — the most common source of "experiment didn't work" post-mortems. The rubric, common misalignment patterns, and worked good/bad examples are in [references/hypothesis-framing.md](references/hypothesis-framing.md).

## 3. Pick metrics that test the hypothesis

The hypothesis names a specific outcome. The primary metric must measure that outcome — same population, same denominator, same timeframe.

- **Primaries** (1–3 max) come from the hypothesis's outcome clause. Each additional primary inflates the family-wise false-positive rate.
- **Guardrails** (strongly recommended) cover the most likely failure mode of the change — see the guardrails-by-domain table in [references/metric-selection.md](references/metric-selection.md).
- **Secondaries** are diagnostic only.

Every primary and guardrail needs an explicit `direction`. Watch for the **lagging-indicator trap** (30-day retention as primary on a 2-week experiment) and the **changed-denominator trap** (metric defined only over treatment-exposed users — lift is artificially infinite). Full sanity checklist and standard guardrails-by-domain table in [references/metric-selection.md](references/metric-selection.md).

## 4. Size the experiment with real data

Pull baseline rate, variance, and daily traffic from Mixpanel. Don't guess.

Use the formulas in **Components**. Then compare the required sample to what the available traffic delivers inside an acceptable window (typically 2–4 weeks). If the achievable MDE exceeds the user's expected lift, the experiment is **underpowered** — surface immediately. Don't wave it through; offer the remediations from the sizing reference (accept a larger MDE → increase allocation → enable CUPED → pick a higher-volume primary → don't run).

Sample-size floor: keep per-variant target above the platform's reliability floor (verify in product — historically ~350–400). Below the floor, the central limit theorem breaks down and the SRM check gets noisy. Full worked examples, baseline-by-rate lookup table, and the duration / seasonality rules in [references/sizing.md](references/sizing.md).

## 5. Pick testing model + end condition

Four choices, each with a default that's right for most users:

- **Testing model** — default Sequential (peeking is safe by design); Frequentist only for small-lift hunts on well-sized tests.
- **End condition** — sample-based for variable traffic; date-based for strong weekly seasonality.
- **Confidence level** — default 0.95 (verify in product); 0.99 for irreversible high-stakes ships; 0.90 only when speed beats rigour.
- **Multiple-testing correction** — enable when there are ≥2 primaries OR ≥2 non-control variants; default Benjamini-Hochberg, Bonferroni for strict family-wise control.

Decision tree, the peeking-trap explanation, worked compounding-FPR numbers, and the four valid model × end-condition combinations are in [references/statistical-model.md](references/statistical-model.md).

## 6. Decide on advanced features

- **CUPED** — enable when the primary metric correlates with pre-exposure behaviour AND all experiment users existed before start AND 2–4 weeks of stable pre-exposure history is available. Do not enable on new-user-only experiments, one-time-event metrics, or brand-new metrics.
- **Winsorization** — enable for heavy-tailed continuous metrics (revenue, time-on-page, session duration). Do not enable on Bernoulli (conversion) metrics. Push back if the configured percentile is below ~80.

When/why each is right and the common misconfigurations are in [references/advanced-features.md](references/advanced-features.md).

## 7. Run the pre-launch pitfall check

Run the catalogue from **Components** against the proposed configuration. Surface only what fires; order blockers → warnings → fyi. Blockers should stop launch (the experiment cannot reach statistical power as configured). Warnings should be explained — name the trade-off, don't just nag. Full catalogue in [references/pitfalls.md](references/pitfalls.md).

## 8. Confirm with the user, then create

Creating the experiment is the irreversible step. Present a compact summary and **wait for explicit confirmation** before invoking the creation action:

```
*Experiment Setup Summary*

• *Hypothesis:* If <change>, then <metric> will <direction> by ≥<MDE>, because <mechanism>.
• *Primary metrics:* <name> (direction: up/down), …
• *Guardrails:* <name> (direction: …), …
• *Variants:* control 50% / treatment 50% (or as configured)
• *Statistical model:* sequential | frequentist
• *End condition:* sample-based (per-arm <N>) | date-based (<N> days)
• *Confidence level:* 0.95
• *Multiple testing correction:* benjamini-hochberg | bonferroni | off
• *Advanced features:* CUPED on/off · Winsorization on/off (percentile <P>)
• *Expected duration on current traffic:* <D> days
• *Achievable MDE on current traffic:* <X>% relative

*Pitfall check:*
✅ Insufficient duration — adequate
✅ Cohort too small — adequate
⚠️ Missing guardrails — no guardrail metrics configured; >5% hard-gate cannot protect this ship
```

Use the exact catalogue labels from [references/pitfalls.md](references/pitfalls.md) so the agent's pitfall messages stay consistent across sessions.

After creating, link the new experiment back to any prior experiment surfaced in step 1 — record the prior's ID, hypothesis, and outcome in the new experiment's description. That 30-second annotation pays back tenfold at interpretation time.

If the user hasn't named a specific feature or surface, ask before fetching baselines or designing — designing the wrong experiment burns more time than the clarifying question costs. Accept the feature by name or by ID; try ID match first, then case-insensitive name match.

---

## Going deeper

| User asks about…                                                              | Open                                                                 |
| ----------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| "Is this an experiment or just a feature flag?"                               | [references/routing-xp-vs-ff.md](references/routing-xp-vs-ff.md)     |
| "Help me write the hypothesis" / "Is this hypothesis good?"                   | [references/hypothesis-framing.md](references/hypothesis-framing.md) |
| "Which metrics should I pick?" / "Primary vs guardrail vs secondary?"         | [references/metric-selection.md](references/metric-selection.md)     |
| "What sample size do I need?" / "What MDE can I detect?" / "How long to run?" | [references/sizing.md](references/sizing.md)                         |
| "Sequential vs frequentist?" / "Confidence level?" / "Correction method?"     | [references/statistical-model.md](references/statistical-model.md)   |
| "Should I enable CUPED / Winsorization?"                                      | [references/advanced-features.md](references/advanced-features.md)   |
| "Was anything similar tested before?"                                         | [references/prior-experiments.md](references/prior-experiments.md)   |
| "What can go wrong before launch?" / "Run the pre-launch check"               | [references/pitfalls.md](references/pitfalls.md)                     |

---

## Output style

- Lead with the hypothesis. Every other decision flows from it.
- Use concrete numbers from real data ("baseline 4.2%, σ² = 0.040, required n ≈ 6,400/arm"), not vague guidance.
- Quote the user's MDE and metric names back so they catch typos.
- When underpowered, say so plainly and list remediations in order of cost.
- Don't moralise about peeking — switch them to sequential.
- Guardrail regressions are hard gates, not "slight concerns."

## Related skills

- `interpret-experiment` — post-launch analysis. Use after the experiment ships.
- `feature-flags` — pure rollout / kill-switch / gating without measurement.
- `create-dashboard` — live monitoring of primary + guardrail metrics during the experiment.
