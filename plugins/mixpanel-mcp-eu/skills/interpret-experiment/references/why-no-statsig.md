# Why Hasn't This Reached Statistical Significance Yet?

Help the user decide between **wait**, **extend**, **boost power**, **narrow the hypothesis**, or **accept the null** — _without_ recomputing the platform's verdicts.

The actual stop / extend math (sample size, power, MDE) is owned by the `experiment-setup` skill — point the user there for the formulas. This reference explains _which_ lever to pull, not how to recompute one.

---

## First, rule out a broken result

Inconclusive can mean two very different things:

1. **The experiment is genuinely too small to detect the effect** — this is what the rest of this document is about.
2. **The result isn't trustworthy at all** — SRM failing, broken data, peeked frequentist, etc. — and "inconclusive" is the wrong frame entirely.

Before answering "why no statsig?", run the **trustworthiness gate**. If anything fails, route to [health-check-interpretation.md](health-check-interpretation.md) — fixing the bucketing or the data is a prerequisite to talking about power.

Also check:

- The primary's lift is missing or null → no measurement, not "no effect."
- The primary is listed on the experiment but has no computed result (live or cached) → "no measurement," not "no effect."
- The live results carry an error block → results are stale or partial; resolve the backend issue before drawing power conclusions.

---

## The five real reasons an experiment hasn't hit statsig

Walk through these in order. The first one that explains the picture is usually right.

### 1. Not enough sample yet (not enough exposures)

**What to check**: per-variant exposure counts against the configured end target (sample size or duration, whichever the experiment was configured with), and which testing model the experiment is using.

- **Sequential** + target not reached → genuinely too early. Recommend **WAIT**.
- **Frequentist** + target not reached → also too early; do NOT peek-and-call. Recommend **WAIT** to the configured end, or restart as sequential next time so peeking is safe.
- Target _was_ reached and still no significance → not a sample-size problem; move to reasons 2–5.

If exposures are falling short of plan because traffic dropped: surface that. Querying the exposure event with a date breakdown shows whether something changed mid-experiment.

### 2. Observed effect is smaller than the MDE

**What to check**: the lift on the primary metric, plus the MDE the user planned for (typically captured in the experiment's hypothesis/description, or recovered via the setup-side skill's power math).

- Observed lift ≈ planned MDE → experiment is correctly sized for the effect; if not significant yet, see reason 1.
- Observed lift **much smaller** than planned MDE → the effect (if any) is below what this experiment was sized to detect. Two real options:
  - **Accept the null** — at this size, the change isn't moving the metric. Document and move on.
  - **Resize and rerun** — if a smaller effect would still be ship-worthy, re-run with a larger sample (lower MDE).
- Observed lift much **larger** than planned MDE but still not significant → unusual; likely high variance (see reason 3) or insufficient exposures (reason 1).

### 3. Variance is too high (metric is too noisy)

**What to check**: the metric's distribution type, plus whether CUPED and Winsorization are enabled.

- **Gaussian** metric (revenue, time-on-page) with no Winsorization → whales inflate variance, widen CIs, and crush power. Recommend enabling Winsorization on the next run.
- **Poisson** metric (event counts per user) → one heavy user can swing results. Same Winsorization recommendation; also consider switching to a rate metric if the hypothesis is about behavior, not volume.
- **Bernoulli** metric near 0% or 100% → variance shrinks at the extremes, but so does the absolute scale of detectable effects. Lifts near 50% rates are easiest; lifts near 0%/100% need much more sample.
- **CUPED not enabled** AND the metric correlates with pre-exposure behavior AND users existed before the experiment → enabling CUPED on a re-run typically cuts required sample 30–70%.
- **CUPED enabled on a new-user-only cohort** → CUPED has no effect (no pre-exposure data exists). Not a misconfiguration to "fix," but variance reduction simply didn't happen.

### 4. Traffic split is starving the variant

**What to check**: the configured traffic split against the actual per-variant exposure counts.

- Even split (50/50) when one variant is the bottleneck → balanced is optimal for power, so this is usually not the issue.
- Skewed split (e.g. 90/10) → the smaller variant is undersampled; power is bottlenecked by the small side. If the skew was for risk reasons, that's a deliberate trade-off; flag that the smaller variant will reach significance much later.
- Multi-variant test (3+ arms) → each treatment-vs-control comparison gets a fraction of total traffic. Each non-control variant needs to clear the platform's per-variant exposure floor in its own right. Adding arms costs power per-comparison.

Never change traffic allocation mid-Frequentist test — it invalidates the SRM baseline and the power calculation. If allocation needs to change, restart the experiment.

### 5. Exposure config is filtering more users than the user expects

**What to check**: exposure event volume, any audience filters on the backing feature flag, and whether QA traffic is being excluded.

- A property filter or audience filter on the feature flag is excluding most users → exposures lag the user's mental "available traffic." Inspect the flag's rollout rules; query the exposure event to confirm how many users actually got exposed.
- The exposure event isn't firing where the user thinks it does (e.g. only on a deep-funnel page) → effective exposed cohort is much smaller than top-of-funnel traffic. Confirm with a query on the exposure event.
- QA traffic isn't being excluded and you suspect internal traffic is dominating one variant → enable the QA exclusion on the next run (results then are cleaner but also smaller).

**Triggered / dilution math** matters here too. If only a fraction of "exposed" users actually saw the change (e.g. they didn't reach the screen where the treatment differs), the population-level lift is diluted. See the triggered-analysis notes in [per-metric-interpretation.md](per-metric-interpretation.md).

---

## Decision: WAIT, EXTEND, BOOST POWER, NARROW, or ACCEPT NULL?

Once you know which reason fits, the recommendation almost picks itself.

| Reason                                 | Recommendation                                                                                               |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| Not enough sample yet, still ACTIVE    | **WAIT.** Show projected end date based on observed traffic.                                                 |
| Not enough sample yet, concluded early | **EXTEND** (Frequentist: relaunch with longer planned duration; Sequential: resume if possible).             |
| Effect << MDE                          | **ACCEPT NULL** if the planned MDE is the smallest ship-worthy effect; otherwise **BOOST POWER** and re-run. |
| Variance too high                      | **BOOST POWER**: enable CUPED, enable Winsorization, switch to a less noisy metric proxy.                    |
| Variant starved by traffic split       | **EXTEND** (if remaining time is enough) or restart with rebalanced split.                                   |
| Exposure config is filtering           | **NARROW the hypothesis** to the triggered cohort, or **EXTEND** to grow the triggered sample.               |
| Experiment finished, well-powered      | **ACCEPT NULL.** "No effect" is a real finding when the experiment was sized for the MDE that matters.       |

When recommending EXTEND on an active experiment, the action is to update the experiment's end target (duration or sample size, whichever it was configured for). Don't fabricate the target number — derive it from the experiment's existing config, or send the user to the `experiment-setup` skill for the power math.

---

## What NOT to suggest

- ❌ **Stop early on a favorable peek** in a Frequentist test — that's exactly the false-positive inflation problem.
- ❌ **Switch testing model mid-experiment** — restart, don't morph.
- ❌ **Add more primary metrics** to "fish" for a win — multiplies the family-wise FPR. If a single primary is inconclusive, more primaries make the picture worse, not better.
- ❌ **Re-run identical hypothesis on the same audience right after concluding "no effect"** — without a power change, you'll get the same answer.
- ❌ **Claim "no effect"** from an underpowered inconclusive result — the right framing is "the experiment wasn't sized to detect the effect we observed."

---

## Output shape

1. **The reason** (one of the five above), in one sentence.
2. **The evidence** — concrete numbers from the experiment (e.g. "exposures only at 4.2k of the 10k target," "observed lift 0.8% vs planned MDE 5%").
3. **Recommendation** from the table above, with the specific experiment update or follow-up action.
4. **What to NOT do**, briefly — the wrong-way temptation specific to this experiment.
