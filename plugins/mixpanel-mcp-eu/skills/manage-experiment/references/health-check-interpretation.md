# Health-Check Interpretation

Turn the platform's already-computed health verdict into a plain-language explanation, an ordered list of likely causes, and a recommended next action.

---

## Kohavi framing — always cite when a health check fails

> **Sample Ratio Mismatch is the #1 trustworthiness check (Kohavi).** When SRM is failing, do not trust the experiment's lift, p-values, or confidence intervals — the randomization assumption is broken, so the measured effect cannot be attributed to the treatment.
>
> **Twyman's Law**: any unusually clean or unusually large result is more likely a bug than a discovery. A spectacular lift on a failing-SRM experiment is not evidence of a great treatment; it's evidence the bucketing is broken.

These two principles drive the recommendations below. Lead with them when explaining a failing check to the user.

---

## 1. SRM (Sample Ratio Mismatch)

**What the platform tells you**: the SRM verdict the experiment-details response carries (live, or cached when live isn't available). The platform tags failing SRMs already — consume the verdict, do not compute chi-square yourself.

### What it means

Users were assigned to variants in proportions that disagree with the configured target allocation. The disagreement is too large to be chance. Bucketing — the experimental machinery itself — is broken. Every downstream number (lift, p-value, CI) inherits that brokenness.

### Likely causes, ordered most → least likely

(Surface in this order — investigate the most probable first.)

1. **bucketing_bug** — A bug in the variant-assignment code is sending more traffic to one variant than the configured split. Check the SDK or server-side bucketing logic that decides which variant each user sees.
2. **biased_assignment** — The assignment criterion correlates with the variant — e.g. assigning by user-id parity when user-ids aren't uniformly distributed, or bucketing on a property that drifts over the experiment window.
3. **bot_traffic** — Bot or crawler traffic is being exposed to one variant more than the other. Bots often hit only the default/control variant or follow patterns that skew allocation.
4. **exposure_tracking_bug** — Exposures are being logged for one variant but dropped or duplicated for another. Verify the exposure event fires exactly once per user per variant assignment.
5. **ramp_up_timing** — If the experiment was ramped (e.g. 10% → 50% → 100%) and the SRM alert fired during a ramp, the deviation may be a transient effect of the ramp schedule rather than a real bucketing problem. Re-check after a stable allocation period.

### Recommended actions

- **pause_and_investigate** — Pause the experiment before drawing any conclusions. SRM violates the experiment's core randomization assumption — any lift or regression measured against a mis-allocated split is unreliable.
- **restart_with_bot_filtering** — Restart with bot filtering enabled in your exposure tracking. Bot traffic is the most common SRM cause when the deviation is small and asymmetric.
- **investigate_exposure_logging** — Compare exposure event volume per variant against your feature-flag evaluation logs. A gap between flag evaluations and logged exposures is the classic signature of exposure-tracking bugs.
- **continue** — Only when the SRM is _not_ failing and the observed allocation is consistent with the configured split.

### Investigation checklist

1. Compare the actual per-variant exposure ratio to the configured target allocation — which variant is over/under-represented?
2. If feature-flag-based: check whether a property filter on the flag was added or changed mid-experiment. Inspect the flag's rollout rules and history.
3. For multi-variant tests, the platform may apply a per-comparison correction to the SRM threshold — the effective per-variant threshold may be tighter than the headline. Trust the platform's bucket flag, not raw p-value math.
4. Verify SDK version and bucketing logic. Query the exposure event grouped by variant to confirm exposure events are flowing correctly.
5. Check for bot/QA traffic — bots often skew toward control. If QA traffic isn't being excluded, recommend enabling that filter.
6. If exposures are very small (e.g. under ~1k total): SRM is unreliable on tiny samples. Wait for more data before acting.
7. If still failing: stop the experiment, fix bucketing, restart with fresh allocation. **Do NOT just re-conclude with the broken data.**

---

## 2. Retro A/A (pre-experiment bias) failure

**What the platform tells you**: the pre-experiment-bias analysis the platform attaches when that check is enabled in the experiment's settings.

### What it means

The same statistical comparison run on the **pre-exposure** period revealed that variant cohorts already differed _before_ the treatment started. Any "lift" measured during the experiment may just be reflecting that pre-existing gap, not the change.

- Pre-experiment bias on a **primary** metric is a **stop-and-investigate** signal.
- Pre-experiment bias on a **secondary** metric is informational only.

### Investigation checklist

1. Identify which metric × variant pair triggered the failure (after the platform's correction).
2. Check whether bucketing was deterministic — non-deterministic assignment in the pre-period means users were assigned to different variants than they would have been in production.
3. Look for cohort skew: did one variant disproportionately receive heavy users? Query the metric pre-experiment grouped by variant to confirm.
4. Check for a recent product change that went out before the experiment — pre-period bias can reflect non-experimental treatment that disproportionately affected one cohort.
5. If isolated to a single metric × variant: consider dropping that metric from the analysis, or restart with new bucketing.

---

## 3. Insufficient exposures

**What the platform tells you**: per-variant exposure counts plus an "insufficient" flag when the count is too low to trust. Do not invent a per-variant threshold; route the user to extend or relaunch the experiment when the platform has flagged the issue.

### Investigation checklist

1. Check per-variant exposure totals — which variant is undersampled?
2. Inspect feature-flag rollout — was rollout dialed back?
3. Query the exposure event with a date breakdown to see if traffic dropped recently (seasonal? incident?).
4. If the experiment is still ACTIVE: extend duration via an experiment update with a new end target.
5. If the experiment concluded too early: relaunch with longer planned duration. The setup-side skill covers the power-analysis math.

If the user wants to talk about _why_ a primary metric is still inconclusive even when exposures look adequate, route to [why-no-statsig.md](why-no-statsig.md) — different question.

---

## 4. Frequentist peeking

**What to check**: the experiment's testing model and whether it ended before reaching its configured end condition (sample size or duration, whichever was configured).

### What it means

A frequentist test that ends before reaching its configured target has an **inflated false-positive rate**. The math assumes a fixed sample size; peeking before that point and stopping on a favorable look is exactly what "p-hacking" looks like in production.

### Investigation checklist

1. Confirm the testing model is frequentist (sequential tests don't have this problem).
2. Compare the actual end date against the planned end (date- or sample-based, whichever the experiment was configured with).
3. If the conclusion was premature: results have inflated false-positive rate. Recommend a re-run.
4. If the user wants to keep current results: caveat strongly. Recommend a sequential testing model for the next experiment so they can stop early without penalty.

(Sequential tests are designed for continuous monitoring — stopping early on significance is safe and intended for those, not a peeking violation.)

---

## 5. Live computation timeout / broken data

**What the platform tells you**: a non-null error block on the live results, with the live data path empty.

### Investigation checklist

1. Retry the experiment-details request once. If it fails again, surface the error and stop retrying — the tool layer owns retry policy.
2. On repeated failure: count metrics × variants × date range. Many metrics on a multi-variant experiment over a long window can exceed the query budget.
3. Recommend reducing scope: drop unused secondary metrics, narrow the date range, or temporarily archive metrics that aren't part of the decision.
4. If the cache is recent (within hours), surface those results with a "stale data" caveat and the timestamp. If the cache is days old or empty, the user must resolve the backend issue before any meaningful interpretation.

---

## 6. Experiment ran < 3 days

**What to compute (this one is local)**: the elapsed time between the experiment's start and end.

Day-of-week, novelty, and cohort-skew effects dominate windows shorter than ~3 days regardless of sample size. **Refuse to interpret.** Tell the user explicitly:

> _"This experiment ran less than 3 days. Day-of-week effects, novelty, and cohort skew dominate a window this short, so the results cannot be reliably interpreted — even if they look 'significant.' Recommend extending or relaunching with a longer planned duration."_

If the experiment was sample-size-bounded and a tiny target was reached in hours, increase the target and rerun. Reaching sample size quickly is not the same as a valid experiment window.

---

## 7. Misconfigurations

These don't always invalidate results, but they change how to _read_ them. Surface them as warnings during the trustworthiness gate.

### Multiple-testing correction off with several primaries

**Correction off AND 2+ primaries × 1+ non-control variants.** Any single significant primary may be a false positive — family-wise error rate scales multiplicatively (e.g. 15 primaries × 1 variant at α=0.05 → ~54% expected family-wise false positive rate). Look at primaries in aggregate: if most point the same direction, the effect is likely real; if only one or two of many are significant, recommend enabling Benjamini-Hochberg or Bonferroni and re-analyzing.

### Extreme winsorization percentile

**Winsorization enabled with a percentile far from the platform default (typically 95).** A percentile near 50 caps almost all data — almost certainly a misconfiguration. Confirm with the user; recommend resetting to the default unless they have a specific reason.

### SRM check disabled

**SRM check is off.** Often deliberate — e.g. when a feature-flag rollout intentionally splits traffic unevenly. Do not compute SRM yourself or treat the absence as a bug. Only flag if results otherwise look suspicious (Twyman-sized lifts, implausible exposure ratios) and then recommend re-enabling SRM and re-analyzing.

### CUPED on new-users-only cohort

**CUPED enabled AND the cohort is "new users only".** CUPED needs pre-exposure data, so it had no effect here — but **results are still valid**, variance reduction just didn't happen. Mention as informational. For future experiments on this surface, suggest extending the cohort to include returning users so CUPED can apply.

### Non-default confidence level

**Confidence level differs from the platform default (typically 0.95).** `0.9` (α = 0.10) inflates false positives; `0.99` (α = 0.01) is conservative. Call out in the verdict and combine with metric count to estimate the family-wise error rate.

### Broken or placeholder metric entries

**Metric entries with empty names.** Likely broken or placeholder references. Flag and skip during analysis.

### Primary metric with no computed result

**A metric is listed as primary but has no result (live or cached).** This is **"no measurement," not "no effect."** Surface prominently; recommend re-syncing results before any conclusion that depends on this primary.

---

## Output shape when a health check fails

1. **What failed**, in one sentence (use the verdict the platform attached — do not re-derive).
2. **What that means for trust** — cite the Kohavi framing (SRM is #1) or Twyman's Law where it fits.
3. **Likely causes**, ordered most → least probable.
4. **Recommended action** from the small set above.
5. **Investigation checklist** the user can run.
6. **What NOT to do** — usually, "do not act on the current lift / p-value numbers."
