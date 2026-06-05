# Pre-launch pitfalls

This is the catalogue of the deterministic checks the agent runs before the user creates an experiment. **Detection logic lives in the platform's pre-launch validation capability**; this document owns the prose — the _why_ behind each check — so the agent can explain the violation in human terms rather than just nagging.

For the source-of-truth severities, thresholds, and message templates, see `ai/engine/tools/experiments/_shared/pitfall_prose.py` in `mixpanel/analytics`. When that file changes, this document changes too.

## Triage order

The agent surfaces pitfalls in this order:

1. **Blockers first.** An experiment that triggers a blocker should not launch as-is. Two pitfalls today: `underpowered_duration_insufficient` and `cohort_too_small`. Both mean the experiment literally cannot reach statistical power for the configured MDE.
2. **Warnings next.** Configuration smells that would degrade interpretability or trustworthiness. Most fall here.
3. **FYIs last.** Soft nudges; not blocking even if the user ignores them.

Within a severity tier, surface in this order (most actionable first): data-trust risks (pre-experiment bias, variance inflation) → configuration nudges (guardrails, hypothesis alignment).

## The >5% guardrail hard-gate

The single most important rule in the catalogue. **A 5% relative regression on any guardrail blocks ship even if the primary wins.**

### Why 5%

The threshold is calibrated to be tight enough to catch real degradations of user experience, revenue, or performance, and loose enough that day-to-day noise on a moderately-volatile guardrail doesn't trip it on every test.

- Below 5%: typically within the noise band of most guardrails on a 2-week test. Tightening below 5% would generate too many false alarms.
- Above 5%: the team has implicitly traded measurable user/revenue/performance damage for headline-metric lift. That's not a ship — that's a re-design.

### Why "hard gate"

Guardrails are not "things to also look at." They are the **trustworthiness backstop**. A winning primary with a regressing guardrail means the change _exchanged_ something the team agreed must not regress for the headline-metric lift. If guardrails are negotiable, they aren't guardrails.

### Why explain it to the user

The most common reaction to a guardrail regression is "but the primary won, can't we just ship?" The agent's job is to make the trade-off explicit:

> "Primary metric `<X>` won by +2.3pp, but guardrail `<Y>` regressed by 7.4%. The 5% threshold exists because guardrails are the trustworthiness backstop — a winning primary with a regressing guardrail means you've traded `<Y>` for `<X>`, which is a design choice that needs explicit sign-off, not a ship decision."

If the team genuinely wants to make that trade, they can disable the guardrail before launch and document the decision in `description`. Don't let them silently override; force the conversation.

---

## The catalogue

Each entry lists: kind → severity → trigger condition → why it matters → what to recommend. The message templates are in `pitfall_prose.py`; reproduced inline here for context.

### `underpowered_duration_insufficient` — blocker

**Trigger.** Expected exposures (`exposures_per_day × planned_days × n_arms`) are less than 50% of the per-arm sample size required to detect the configured MDE at the baseline rate.

**Why it matters.** The experiment cannot reach statistical power for this MDE no matter how clean the rest of the config is. If launched, the most likely outcome is "inconclusive" — and a non-trivial fraction of those inconclusive results will be due to noise crossing the significance threshold rather than a real effect, the winner's-curse problem.

**Recommendation.** Extend planned duration by roughly `(n_required − expected_exposures) / exposures_per_day` days, OR relax the MDE (only ship if the lift is bigger), OR pick a higher-volume primary metric, OR enable CUPED if pre-exposure data is available (which can cut required `n` by 30–70%).

### `cohort_too_small` — blocker

**Trigger.** Cohort size is smaller than `num_arms × target_sample_size`. The cohort cannot supply enough eligible users.

**Why it matters.** Same root cause as the duration blocker, different lever. Even with infinite time, the experiment will run out of eligible users before each arm reaches the per-arm target.

**Recommendation.** Either expand the cohort to ~`num_arms × target_sample_size` eligible users (relax filters, broaden segment, extend eligibility window), or lower the per-arm target sample size to what the cohort can actually supply (and accept the larger achievable MDE that comes with it).

### `pre_experiment_bias_likely` — warning

**Trigger.** Retrospective A/A is enabled, at least one continuous-ish metric (continuous, retention, or funnel) is configured, AND CUPED is off.

**Why it matters.** Pre-experiment bias is likely on metrics with seasonality or power-user skew. Without CUPED to absorb the baseline difference, post-experiment lifts will inherit it — the team will see "treatment up 2%" when the real treatment effect is 0% and the baseline difference is +2%.

**Recommendation.** Enable CUPED with a 2–4 week pre-exposure window. CUPED specifically handles this case: it regresses out the pre-exposure baseline difference so the post-exposure lift is the actual treatment effect.

### `high_variance_no_winsorization` — warning

**Trigger.** At least one continuous-ish metric is configured AND Winsorization is off.

**Why it matters.** Outliers will inflate variance and widen confidence intervals. A handful of power users can dominate the per-arm mean, swinging the headline based on which arm those users got assigned to.

**Recommendation.** Enable Winsorization with default percentile 95. Push back if the user sets percentile <80 (that's >20% of values capped — almost always a misconfiguration).

### `multiple_primaries_no_bonferroni` — warning

**Trigger.** ≥2 primary metrics configured AND multiple-testing correction is off.

**Why it matters.** Family-wise false-positive rate compounds with each additional primary. At 3 primaries the FPR is ~14.3%; at 5 it's ~22.6% — more than one in five "wins" is noise.

**Recommendation.** Enable multiple-testing correction. Default to Benjamini-Hochberg (more powerful with correlated metrics); use Bonferroni for strict family-wise error control. The name of this pitfall is historical — the correction need not be Bonferroni specifically.

### `underpowered_duration_marginal` — warning

**Trigger.** Expected exposures are between 50% and 100% of the per-arm sample size required for the configured MDE.

**Why it matters.** Marginally underpowered. The experiment might reach significance on a true effect; it might not. Either way, the lift estimate at conclusion will be wider than expected.

**Recommendation.** Extend duration to reach 100%+ of the required sample, or accept the higher Type-II error rate (more chance of missing a real effect). Less urgent than the `_insufficient` variant.

### `missing_guardrails` — warning

**Trigger.** Zero guardrail metrics configured.

**Why it matters.** Without guardrails, there's no >5% hard-gate to block a ship on a regression to user experience, revenue, or performance. The team is implicitly trusting that the primary metric captures every relevant impact — which is rarely true.

**Recommendation.** Add at least one guardrail covering the most likely failure mode of the change. Standard choices:

- UI change → page-load time or error rate.
- Monetisation / pricing → cancel rate or refund rate.
- Engagement change → Day-7 retention or session count.
- Performance change → error rate or crash rate.

### `hypothesis_metric_mismatch` — warning

**Trigger.** The hypothesis text mentions one of the canonical metric nouns (`conversion`, `retention`, `revenue`, `signup`, `engagement`, `click`, `purchase`) but no primary metric's name appears to measure that outcome.

**Why it matters.** Soft signal — the heuristic is coarse, but it catches the common case where the user wrote "X will increase conversion" and then set the primary to "session count" or vice versa. If the user's hypothesis is about conversion, the primary should be a conversion metric.

**Recommendation.** Phrase as a question, not a verdict: _"Your hypothesis mentions `<noun>`, but no primary metric name suggests it measures that. Should `<configured primary>` be replaced or supplemented with a metric that more directly tests the hypothesis?"_

### `primary_lacks_leading_indicator` — warning

**Trigger.** Primary metrics include a retention-type metric (lagging by construction) AND no leading-indicator secondary (conversion or funnel type) is configured.

**Why it matters.** A retention primary is valid but reads slowly — there may not be enough signal to interpret results before the experiment concludes. Without a leading-indicator secondary, the agent has no early-read evidence to reason from.

**Recommendation.** Add a leading-indicator secondary metric (a conversion or funnel metric measured within the experiment runtime). The retention primary stays as the ship decision; the secondary just gives early visibility.

---

## Detection vs prose

The detection math lives in the platform's pre-launch validation capability. The prose lives here and in `pitfall_prose.py`. The two are connected by the pitfall `kind` field — the validation step reports the kind, the agent renders the message.

This separation lets product retune phrasing (this document, `pitfall_prose.py`) without touching the detection helpers, and vice versa. When you update a threshold (e.g., the 50% / 100% bounds on the underpowered checks), update the helper math, the `_shared/pitfall_prose.py` constant, and the recommendation in this document together — the agent will quote stale numbers if any of the three drifts.

## What's not in the catalogue (yet)

- **Cross-test contamination** — when the same users are eligible for multiple concurrent experiments on the same surface. Hard to detect statically; usually surfaces as anomalous variance at interpretation time.
- **Novelty effect detection** — early days of the experiment show inflated treatment effect, then settle. Not a pre-launch check; lives in the post-launch interpretation skill.
- **Seasonality misalignment** — running a 2-week experiment that doesn't align to weekly cycles. Today this is detected indirectly via the duration check; a future explicit `seasonality_misaligned` pitfall is a reasonable add.
