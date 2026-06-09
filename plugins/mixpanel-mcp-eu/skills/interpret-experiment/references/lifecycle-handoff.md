# Lifecycle Hand-off

How to conclude an experiment once the verdict is settled. This reference is **interpretation guidance** — the per-field schema of the decide action lives in the experiment-update tool description.

---

## Confirm before concluding — always

Concluding an experiment is **irreversible**. Before invoking the decide action, surface the proposed parameters to the user (winning variant, success/fail, rationale message) and wait for explicit confirmation. A SHIP verdict is a recommendation, not an authorization.

## The three pieces every decide call needs

A decide call expresses three things:

1. **Did the experiment succeed?** A win for one of the treatments, or a deliberate stop.
2. **Which variant ships?** Required when success is true. Either a real variant key, or one of the two special constants below.
3. **Why?** A rationale message — what metrics were evaluated, the polarity reading, the tradeoffs accepted. The platform requires this on every decide call; treat it as a one-paragraph decision record, not a placeholder.

## Special variant choices for success

When you have a winning result but no single variant to ship:

- **Ship the change without picking a variant.** Use when the experiment validated a direction but the team will ship outside the experiment's variant set. (The platform exposes this as the constant `__no_variant_shipped__`.)
- **Defer the variant decision.** Use when you want to lock in the success verdict but the variant choice needs more discussion. (The platform exposes this as `__defer_variant_decision__` and shows `SUCCESS_DEFERRED` in the UI.)

When the verdict is KILL — no winner — record success as false. No variant key is needed in that case.

## Multi-variant experiments

For a 3+ arm test, the decide action still names a single winning variant. If two treatments are roughly tied:

- If both clear the practical-significance bar and shipping either is acceptable, pick on simplicity (smaller diff from control, lower implementation cost).
- If the team genuinely cannot pick, use the defer constant above — better than fabricating a winner.

A multi-variant test where only one treatment is significantly different from control is a clean SHIP for that variant; the inconclusive arms are simply not the winner.

## After concluding

The decision record (`results_cache.message`, `results_cache.variant`, and `status` transitioning to `concluded` / `success` / `fail`) becomes the durable artifact. If a follow-up question comes in about why this experiment was shipped, that record is the answer.
