# Prior experiments

The first thing to do when a user proposes an experiment on a feature is look up prior experiments on that feature. Skipping this leads to redundant tests, contradictory ship decisions, and wasted traffic.

## The lookup

Search the project's prior experiments using the draft you're building — its flag key, its planned metrics, and its hypothesis. The lookup ranks stored experiments by overlap on those signals (shared metrics weigh most, then flag key, then hypothesis wording), so hand it as much of the draft as you have rather than a single keyword. Cast the net wide on the first call — keep the similarity threshold low so adjacent experiments the user may have forgotten about still surface.

If no prior-experiments lookup is available in the current environment, tell the user explicitly that you couldn't check and proceed. Don't fabricate "no prior tests found" — that's worse than admitting the blind spot.

## What to do with what you find

### Same feature already tested and shipped

Reference the prior result before recommending a new test. The right answer is often "don't re-run; iterate on a new hypothesis."

> "There's a prior experiment from [date] on the same feature with a similar hypothesis: it shipped at +X% on metric Y. Re-running won't tell us anything new. What's different about the change you're proposing? Is the new hypothesis about a different sub-population, a different metric, or a different mechanism?"

If the user does want to re-run (e.g., the population has shifted significantly, the underlying product has changed, or the prior test was clearly underpowered), proceed — but design the new test to specifically address what's different from the prior.

### Same feature tested and killed

Treat this as a strong prior. Ask why the user thinks the new variant will work where the prior didn't.

> "Prior experiment [date] on the same surface killed at [-X% / inconclusive]. What's different about your change that should produce a different outcome? If the prior failed because of [mechanism], does your change address that?"

If the user can articulate a different mechanism, run the new test. If they can't, the most likely outcome is a repeat of the prior result — discourage the test or downgrade its priority.

### Earlier iteration of the same hypothesis

Use the prior result to inform the new design — specifically, **baseline rates and variance estimates**. Prior data is much more reliable than guessing.

- Pull the prior's control-arm baseline rate; use it as the baseline for the new sizing calculation.
- Pull the prior's observed variance; use it instead of estimating from scratch.
- Pull the prior's exposure rate (exposures per day per variant); use it to set a realistic duration estimate.

This often shrinks the required sample size or shortens the planned duration. Both are wins worth surfacing.

### Recently concluded with similar metrics

Pull the realised exposure rate. The "expected exposures per day" the user has in mind is usually higher than what actually shows up in a real experiment on the same surface — eligibility filters, opt-outs, and bot exclusion all bite. Use the prior's actual rate, not the theoretical one.

### Multiple prior experiments on adjacent surfaces

Look for **patterns**, not single data points. If three prior tests on the same funnel stage all moved in the same direction by similar magnitudes, that's the realistic prior for what the new test will do. If the prior tests are noisy or contradictory, treat the new test's expected lift with more uncertainty and consider running it longer.

## Folding prior results into the new design

Concretely, when you have a prior result that's relevant, the setup workflow changes as follows:

| Step                       | Without prior                                   | With prior                                                                                                             |
| -------------------------- | ----------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| Step 1 — hypothesis        | Coach from scratch                              | Anchor on the prior's hypothesis; ask what's different                                                                 |
| Step 2 — metric selection  | Suggest standard primaries/guardrails           | Use the prior's metric set as the default; modify only with reason                                                     |
| Step 3 — sizing            | Query baseline + variance over the prior window | Use the prior's observed baseline and variance                                                                         |
| Step 4 — statistical model | Default to sequential / Benjamini-Hochberg (verify current)      | If the prior used a specific model and the team is comparing across tests, keep the same model for comparability       |
| Pitfall check              | Run the standard catalogue                      | Cross-reference: did the prior have an SRM problem? A guardrail regression that should be set up as primary this time? |

## When prior tests warn you away from testing at all

Sometimes the prior data tells you the right answer is **don't run the experiment**:

- The metric the user wants to move has been tested 4 times on this surface in the last year, all with inconclusive or null results, all adequately powered. The hypothesis-space is likely exhausted; suggest a different mechanism or a different surface.
- The baseline rate is so low that even the prior, well-powered tests couldn't detect anything below a 30% relative lift. The new test would inherit the same constraint. Either pick a higher-volume proxy metric or accept that the change has to be very large to be detectable.
- Recent guardrail regressions on the same surface suggest the surface is unstable; running more experiments without first fixing the trust issue is wasted traffic.

Surface these findings as recommendations, not blockers. The user might have context the prior data doesn't capture.

## What to record about the new design's relationship to prior tests

In the experiment's description, link to the prior experiment(s) and note how the new design differs. This becomes critical at interpretation time — the post-launch step uses the prior context to calibrate its read of the new result.

A useful template:

```
Prior: <experiment_id> tested <hypothesis> on <date>, result: <outcome>.
This experiment differs by: <one sentence>.
Inherited from prior: baseline rate (X%), σ², exposure rate (N/day/variant).
```

This is a 30-second annotation that pays back tenfold at analysis time.
