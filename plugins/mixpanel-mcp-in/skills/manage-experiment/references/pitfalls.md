# Pre-launch pitfalls

Catalogue of the deterministic checks to run before the user creates an experiment. Detection logic lives in the platform's pre-launch validation capability; this document owns the prose — the _why_ behind each check — so the agent can explain the violation in human terms rather than just nagging.

## Triage order

Surface pitfalls in this order:

1. **Blockers first.** An experiment that triggers a blocker should not launch as-is. Two today: **insufficient duration** for the configured MDE on available traffic, and **cohort too small** to supply enough eligible users. Both mean the experiment literally cannot reach statistical power.
2. **Warnings next.** Configuration smells that would degrade interpretability or trustworthiness. Most pitfalls fall here.
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

If the team genuinely wants to make that trade, they can disable the guardrail before launch and document the decision in the experiment's description. Don't let them silently override; force the conversation.

---

## The catalogue

### Insufficient duration for the configured MDE — blocker

**Expected exposures over the planned window cover less than 50% of the required per-arm sample.** The experiment cannot reach statistical power for this MDE no matter how clean the rest of the config is. The most likely outcome is "inconclusive," and a non-trivial fraction of those inconclusive results will be noise crossing the significance threshold rather than a real effect (the winner's-curse problem). Extend planned duration to cover the required sample, OR relax the MDE (only ship if the lift is bigger), OR pick a higher-volume primary metric, OR enable CUPED if pre-exposure data is available (cuts required sample 30–70%).

### Cohort too small — blocker

**Eligible cohort size is smaller than (number of arms × per-arm target).** Same root cause as the duration blocker, different lever. Even with infinite time, the experiment will run out of eligible users. Either expand the cohort to comfortably exceed (number of arms × per-arm target) eligible users (relax filters, broaden segment, extend eligibility window), or lower the per-arm target to what the cohort can supply (and accept the larger achievable MDE).

### Pre-experiment bias likely — warning

**Retro A/A is enabled, at least one continuous-ish metric (continuous, retention, or funnel) is configured, AND CUPED is off.** Pre-experiment bias is likely on metrics with seasonality or power-user skew. Without CUPED to absorb the baseline difference, post-experiment lifts inherit it — the team sees "treatment up 2%" when the real treatment effect is 0% and the baseline difference is +2%. Enable CUPED with a 2–4 week pre-exposure window; it specifically regresses out the pre-exposure baseline difference.

### High variance, no Winsorization — warning

**At least one continuous-ish metric is configured AND Winsorization is off.** Outliers will inflate variance and widen confidence intervals; a handful of power users can dominate the per-arm mean. Enable Winsorization at the default `percentile=5` (cap each 5% tail). Push back if the user sets a `percentile` above ~20 — more than 20% of values capped on each side is almost always a misconfiguration.

### Multiple primaries, no correction — warning

**≥2 primary metrics configured AND multiple-testing correction is off.** Family-wise false-positive rate compounds with each additional primary: at 3 primaries ~14.3%, at 5 ~22.6% — more than one in five "wins" is noise. Enable multiple-testing correction. Default to Benjamini-Hochberg (more powerful with correlated metrics); use Bonferroni for strict family-wise error control.

### Marginally underpowered duration — warning

**Expected exposures cover 50–100% of the required per-arm sample.** The experiment might reach significance on a true effect; it might not. Either way, the lift estimate at conclusion will be wider than expected. Extend duration to reach 100%+ of the required sample, or accept the higher Type-II error rate. Less urgent than the insufficient-duration blocker.

### Missing guardrails — warning

**Zero guardrail metrics configured.** Without guardrails, there's no >5% hard-gate to block a ship on a regression. The team is implicitly trusting that the primary captures every relevant impact — rarely true. Add at least one guardrail covering the most likely failure mode of the change:

- UI change → page-load time or error rate.
- Monetisation / pricing → cancel rate or refund rate.
- Engagement change → Day-7 retention or session count.
- Performance change → error rate or crash rate.

### Hypothesis ↔ metric mismatch — warning

**The hypothesis mentions a canonical metric noun (conversion, retention, revenue, signup, engagement, click, purchase) but no primary's name appears to measure that outcome.** Soft signal — the heuristic is coarse, but it catches the common case where the user wrote "X will increase conversion" and then set the primary to "session count." Phrase as a question, not a verdict: _"Your hypothesis mentions `<noun>`, but no primary metric name suggests it measures that. Should `<configured primary>` be replaced or supplemented with a metric that more directly tests the hypothesis?"_

### Primary lacks a leading indicator — warning

**Primaries include a retention-type metric AND no leading-indicator secondary (conversion or funnel type) is configured.** A retention primary is valid but reads slowly — there may not be enough signal to interpret results before the experiment concludes. Add a leading-indicator secondary measured within the experiment runtime; the retention primary stays as the ship decision, the secondary just gives early visibility.

---

## Detection vs prose

The detection math lives in the platform's pre-launch validation capability. The prose lives here. The platform reports which check fired; the agent renders the human-readable message. When the platform's thresholds change (e.g., the 50% / 100% bounds on the underpowered checks), the recommendation language in this document needs to track — the agent will quote stale numbers otherwise.

## What's not in the catalogue (yet)

- **Cross-test contamination** — when the same users are eligible for multiple concurrent experiments on the same surface. Hard to detect statically; usually surfaces as anomalous variance at interpretation time.
- **Novelty effect detection** — early days of the experiment show inflated treatment effect, then settle. Not a pre-launch check; lives in the post-launch interpretation skill.
- **Seasonality misalignment** — running a 2-week experiment that doesn't align to weekly cycles. Today this is detected indirectly via the duration check; a future explicit seasonality-alignment check is a reasonable add.
