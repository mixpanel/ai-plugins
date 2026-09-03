# Migrating from another flag vendor

For customers moving flags and experiments into Mixpanel from Statsig, LaunchDarkly, Optimizely, GrowthBook, Unleash, OpenFeature, or a homegrown system.

This reference covers the code-side work and the sequencing. The full vendor-agnostic playbook, including the exposure-event mapping table per vendor, is at **Mixpanel docs → Guides → Strategic playbooks → "Migrating Your Feature Flags and Experiments to Mixpanel."** Read it alongside this file.

*Source: the Mixpanel feature-flags and SDK docs at docs.mixpanel.com. Product behaviour, defaults, version floors and call shapes all change — verify against current docs before relying on any specific value below.*

## Contents

- [Do not migrate a running experiment](#say-this-before-anything-else-do-not-migrate-a-running-experiment)
- [Division of labour](#division-of-labour)
- [Part 1 — Historical exposures](#part-1--historical-exposures)
- [Part 2 — Configurations](#part-2--configurations)
- [Part 3 — Finish setup in the UI](#part-3--finish-setup-in-the-ui)
- [Part 4 — Change the code](#part-4--change-the-code)
- [Part 5 — Parity check](#part-5--parity-check)
- [Sequencing summary](#sequencing-summary)

---

## Say this before anything else: do not migrate a running experiment

Variant assignment is computed independently by each platform. Moving a live experiment to Mixpanel **reassigns users to different variants mid-flight**. The experiment's results are destroyed — not degraded, destroyed — because the exposed population changes underneath the measurement.

Let in-flight experiments finish where they are, import their history, and relaunch fresh in Mixpanel after cutover — the full ordering is in [Sequencing summary](#sequencing-summary).

Feature gates and dynamic configs have no such constraint — reassignment there is a user-experience flicker, not a correctness failure. Migrate those first.

---

## Division of labour

Parts 1–3 below are API and console work — route them through an available engine (see [`ENGINE.md`](../../../ENGINE.md)) or the customer. **Parts 4 and 5 are this skill's job**, and are where the detail here is deepest. The section headings are the taxonomy; [Sequencing summary](#sequencing-summary) is the order to actually execute in.

---

## Part 1 — Historical exposures

Export the vendor's exposure events and re-ingest them as Mixpanel exposure events through the Import API. Each vendor names its exposure event differently, and the mapping depends on which Mixpanel flag type the original corresponds to — the playbook has the full table.

Each row becomes a Mixpanel `$experiment_started` event. At minimum it needs the enrollment identity, the original exposure timestamp, the flag or experiment name, and the assigned variant:

```json
{
  "event": "$experiment_started",
  "properties": {
    "distinct_id": "the enrollment identity from the vendor export",
    "time": 1709275888,
    "$insert_id": "vendor-exposure-id-or-another-stable-unique-key",
    "Experiment name": "checkout_flow_test",
    "Variant name": "treatment"
  }
}
```

Two things that are easy to get wrong and expensive to redo:

- **Keep the original timestamp.** Ingesting at import time collapses the whole history onto one day and makes it useless for analysis.
- **Include a unique `$insert_id` per row.** Imports get re-run; without it, a re-run duplicates every exposure.

---

## Part 2 — Configurations

Recreate flags and experiments through the Mixpanel API. **Create the experiment first, then the flag that references it** — the flag carries the experiment reference, so the reverse order leaves an orphan.

> **This two-call pattern is specific to migrating via the API.** Working in the product normally, you create the experiment and its backing flag is auto-created and linked for you — one step, not two, and the `manage-feature-flags` skill will tell you that creating a flag directly for an experiment produces an orphan. Both are true: the API path builds the two objects explicitly and links them, which is what makes bulk recreation possible at all. Don't carry the two-call pattern back into non-migration work, and don't let it convince you the product path needs a second step.

The variant value type differs by flag type, and mismatching it is a silent misconfiguration:

| Flag type | `value` type |
|---|---|
| Feature Gate | boolean |
| Experiment | string |
| Dynamic Config | object |

**Map the bucketing key explicitly.** Every vendor randomises on some unit — a user key, a device id, an account id. That maps onto Mixpanel's variant assignment key, and it is **immutable once the flag is enabled**. Getting it wrong is the single most common cause of a migration that passes every aggregate check and still assigns individual users differently (see [Part 5](#part-5--parity-check)). Decide it per flag, from the vendor's config, before creating anything.

**Migrate a few low-risk flags first** and validate the whole pipeline end to end before doing the bulk. A scripted migration that gets the value type wrong, or the bucketing key wrong, will get it wrong hundreds of times.

---

## Part 3 — Finish setup in the UI

The API creates the base configuration. Targeting rules, rollout groups, runtime evaluation, and experiment metrics are completed in the Mixpanel UI. For each migrated experiment, map the vendor's success metrics onto Mixpanel metrics so the same criteria are being measured.

---

## Part 4 — Change the code

### If the customer uses OpenFeature

Swap the provider. Registration changes; every `getBooleanValue` / `getStringValue` call site stays exactly as it is — **provided the flag keys were carried over identically**. Verify key parity before touching code; a renamed key turns into a silent fallback.

This is by far the cheapest migration path. If the customer is on a vendor SDK directly and is facing a large migration, adopting OpenFeature first is worth raising as an option.

### If the customer uses the vendor SDK directly

Replace each evaluation call with the Mixpanel equivalent from [sdk-snippets.md](sdk-snippets.md). The mapping is usually mechanical:

| Vendor concept | Mixpanel equivalent |
|---|---|
| Boolean gate check | boolean flag evaluation |
| Multivariate / experiment variant | variant-value getter |
| Dynamic config / JSON payload read | variant-value getter returning the object |
| User attributes passed for targeting | `custom_properties` inside the evaluation context |
| Per-request evaluation context | the `distinct_id` plus any non-default assignment key |

Two semantic differences to check rather than assume:

- **Default/fallback values.** Confirm the Mixpanel fallback means "feature off" — some vendors default to the *first* variant rather than a designated control.
- **Exposure semantics.** Vendor SDKs vary in whether evaluation fires exposure and whether it deduplicates. Mixpanel client SDKs deduplicate per SDK instance; server SDKs do not deduplicate at all. Read [exposure-correctness.md](exposure-correctness.md) before converting server-side call sites.

### Dual-run during cutover

Wrap Mixpanel flag calls so that if a value can't be retrieved, the code falls back to the value the old provider would have served. Both systems run side by side, and parity can be confirmed with no user-facing risk.

**Introduce a thin facade around flag evaluation while doing this** — one function per flag, or one small module. It makes the dual-run wrapper trivial, makes removing the old provider a one-file change, and leaves the customer better off than the scattered call sites they started with. This is the single highest-value structural change available during a migration; propose it early, because retrofitting it later means touching every call site twice.

### Cut over and clean up

Once parity holds in production: route fully to Mixpanel, remove the fallback, delete the old provider's SDK and configuration. Keep the facade.

---

## Part 5 — Parity check

Do not call the migration done until all four hold:

1. **Flag count** — every flag intended for migration exists in Mixpanel.
2. **Exposure count** — both distinct users exposed and total exposure events are in line with the old system.
3. **Variant splits** — variant count and rollout ratios match the original configuration.
4. **Per-user variant match** — spot-check individual users and confirm they receive the variant expected.

Item 4 catches what the aggregate checks miss. A migration can produce correct totals with systematically wrong per-user assignment — most often from a mismatched bucketing key.

---

## Sequencing summary

1. Inventory the vendor's flags; separate live experiments from gates and configs.
2. Import historical exposures for everything.
3. Migrate gates and dynamic configs first — low risk, validates the pipeline.
4. Let live experiments finish on the old vendor.
5. Introduce the evaluation facade and dual-run the migrated gates.
6. Verify parity, cut over, remove the old provider.
7. Launch replacement experiments fresh in Mixpanel.
