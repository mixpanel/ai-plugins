---
name: implement-flags-and-experiments
description: Implements Mixpanel feature flags and experiments in a customer's codebase — installing and initializing the SDK with flags enabled, writing the flag-evaluation code at the right decision point, and verifying exposures arrive before anyone ramps or launches. Covers first-flag quick start, production setup, adding a flag, migrating from LaunchDarkly, Statsig, Optimizely, GrowthBook or OpenFeature, and auditing a flag that isn't working. Use when a customer wants to add a feature flag or A/B test to their app, asks why their flag returns the fallback, sees zero exposure events traced to the code rather than rollout or targeting, or is moving flags to Mixpanel from another vendor. Do NOT use for configuring rollout percentages, staged ramps, kill switches, or archiving flags — those belong to `manage-feature-flags`; nor for experiment design, sizing, launch, or results interpretation — those belong to `manage-experiment`; nor for designing a tracking plan or event schema — that is `tracking-implementation`.
license: Apache-2.0
metadata:
  engine: optional
---

For any reference to `sdk-snippets.md`, use this resource: [sdk-snippets.md](references/sdk-snippets.md).

For any reference to `exposure-correctness.md`, use this resource: [exposure-correctness.md](references/exposure-correctness.md).

For any reference to `verification.md`, use this resource: [verification.md](references/verification.md).

For any reference to `migration.md`, use this resource: [migration.md](references/migration.md).

# Implement Feature Flags and Experiments

> **Engine optional** — the core flow (SDK code generation, verifying exposures in Live View) needs no engine. When creating a flag, reading its key, or checking exposure counts, use an available engine per [`ENGINE.md`](../../ENGINE.md); otherwise fall back to directing the customer to the Mixpanel UI. Never stop for a missing engine.

This skill puts a working flag in the customer's code. It ends when a real variant reaches a real user and the exposure event proves it.

*Source: the Mixpanel feature-flags and experiments docs at docs.mixpanel.com. Product behaviour, defaults and SDK surfaces change — verify against current docs before relying on any specific claim here.*

**Scope.** This skill owns the code, and the flag the code reads. Everything downstream of that — rollout, ramps, experiment design, results — belongs to the neighbours listed in [Handing off](#handing-off).

---

## The three facts that prevent most first-time failures

State these before writing any code. Nearly every "my flag doesn't work" report traces to one of them.

1. **The flag must exist in Mixpanel before code reads it, and it starts disabled.** A disabled flag serves control to everyone. Create the flag before writing the evaluation call, not after — code that reads a flag key that doesn't exist yet returns the fallback forever and looks identical to a broken implementation.
2. **The fallback value must mean "feature off."** The fallback is served on network failure, on service downtime, and when the user isn't in the rollout. If the fallback enables the feature, an outage ships a half-built feature to everyone.
3. **Evaluating a flag is what fires the exposure event.** Assignment (which variant) and exposure (the user actually saw it) are different moments. Put the evaluation call at the point where the variant changes what the user sees — not at app boot, unless boot is genuinely where the branch happens.

---

## Pre-Flight — Codebase Scan

**Run this before any mode. Do not ask the customer anything yet.** Read the codebase and build a picture; this replaces most discovery questions.

| What to read | What to extract |
|---|---|
| Package manifests (`package.json`, `requirements.txt`, `go.mod`, `build.gradle`, `Package.swift`, `pubspec.yaml`, `Gemfile`, `pom.xml`) | Platform and language → which SDK; whether Mixpanel is already a dependency; **the installed version** |
| Existing Mixpanel init call | Whether flags are enabled, what context is passed, region/API host, whether `debug` is on |
| Existing flag/experiment vendor SDKs (LaunchDarkly, Statsig, Optimizely, GrowthBook, Unleash, OpenFeature) | Migration mode is the real request; the call sites to convert |
| Auth / session / login handlers | Where `identify()` happens — flags reload on identify, so evaluation must not race it |
| The feature the customer named | The exact branch point where the variant changes behavior — this is where the evaluation call goes |
| Env/config files | Whether dev/staging/prod use separate Mixpanel projects (they need separate flags — see *Full Setup*) |

**Carry forward:** platform + SDK + installed version, whether init already exists, the target branch point, and the identity call site.

**Version gate.** Feature flags require a minimum SDK version per platform, and flag persistence requires a higher one on client SDKs. Check the installed version against the table in [sdk-snippets.md](references/sdk-snippets.md) before writing code — an old SDK fails with no flags returned and no error.

---

## Mode Selection

> "What are you trying to do?"
> 1. **Quick Start** — get your first flag evaluating in your code, this session
> 2. **Full Setup** — production-ready flags, including experiment-backed ones
> 3. **Add a Flag** — you already have Mixpanel flags working; add another
> 4. **Migrate** — move flags/experiments from another vendor into Mixpanel
> 5. **Audit** — a flag isn't behaving; find out why

State the selected mode and offer to switch at any point.

| Mode | Covers | Section |
|---|---|---|
| Quick Start | Pre-flight → SDK init with flags → create flag → evaluate → verify → enable | [Quick Start Flow](#quick-start-flow) |
| Full Setup | Quick Start plus identity, environments, exposure correctness, experiment wiring, cleanup plan | [Full Setup](#full-setup) |
| Add a Flag | Reuse existing init → route flag type → evaluate → verify | [Add a Flag](#add-a-flag) |
| Migrate | Inventory vendor flags → map semantics → recreate → dual-run → cut over | [migration.md](references/migration.md) |
| Audit | Diagnose fallback-always, zero exposures, wrong variant, skewed splits | [Audit](#audit) |

**Escalation rules**

- Quick Start surfaces consent/GDPR requirements, an identity-merge setup, or a CDP in the path → offer Full Setup.
- No Mixpanel SDK present at all → absorb a minimal init inline (Quick Start, *Ensure the SDK is installed*). Do **not** route to `tracking-implementation` for this; a flag needs only init and identity, not a tracking plan.
- The customer needs a *tracking plan*, event design, or analytics strategy → that is `tracking-implementation`'s job. Hand off.
- Escalation is always an offer. The user decides.

---

## Quick Start Flow

Seven steps. Do not skip *Verify*.

### 1. Route the flag type

Three shapes, one SDK call surface. The difference is server-side configuration, not code — reassure the customer of this, it is the most common source of over-thinking at this stage.

| The customer wants | Type | Evaluation call |
|---|---|---|
| Turn a feature on/off for some users | **Feature Gate** | the boolean check (`isEnabled` / `is_enabled?`) |
| Serve different values/payloads per user, no measurement | **Dynamic Config** | the variant-value getter |
| Compare variants and **measure** which wins | **Experiment** | the variant-value getter |

If the customer says "A/B test," "does this improve conversion," or names a success metric → that is an **Experiment**. Experiment-backed flags must be created through the experiment path, which auto-creates and links the backing flag; creating a flag directly and then an experiment produces an unlinked orphan. Route the *design* of that experiment (hypothesis, metrics, sizing) to the `manage-experiment` skill — this skill implements whatever it produces.

### 2. Ensure the SDK is installed and initialized with flags enabled

Flags are **off by default in every SDK** — the most common cause of "I added the code and nothing happened." Init shapes per platform, and the two context rules that go with them, are in [sdk-snippets.md](references/sdk-snippets.md#enabling-flags-at-init).

- Already initialized → add the flags option to the existing init. Do not create a second instance.
- Not installed → install and write a minimal init: token, flags enabled, region host if EU/IN, `debug` on for now.
- Server-side → choose remote vs local evaluation now; it changes the init shape. **Local cannot do cohort targeting or sticky variants** — if the customer wants either, they need remote. Details in [sdk-snippets.md](references/sdk-snippets.md#server-sdks-remote-vs-local-evaluation).

**Before writing the init, check whether any flag in the project uses a non-default variant assignment key or runtime-property targeting.** Both need extra fields in the init context, and omitting either is a silent no-match — the flag just never returns.

### 3. Create the flag — before writing any code

**Show the proposed flag and get an explicit yes before creating it** — name, key, type, variant assignment key, variants. Two of those are irreversible (below), which is why this step earns a confirmation gate when most don't.

With an engine: create it on confirmation and read back the generated key. Without one: direct the customer to create it in the Mixpanel UI and paste the key back.

- Let the key auto-generate unless the customer asked for a specific one. **Keys are immutable after creation.**
- Name it for the behavior being gated, not the quarter or the project codename.
- **The variant assignment key cannot be changed once the flag is enabled** — decide now: `distinct_id` for logged-in experiences, `device_id` for pre-auth/acquisition flows, a group key for account-level rollout.
- It starts disabled. That is correct and deliberate — it means the evaluation code is safe to ship immediately.

### 4. Write the evaluation code

Put the call at the branch point identified in pre-flight. Use the snippet for the platform from [sdk-snippets.md](references/sdk-snippets.md).

- Pass a fallback that means "feature off" — see [The three facts that prevent most first-time failures](#the-three-facts-that-prevent-most-first-time-failures).
- Match the call to the flag type (boolean check for a gate, variant-value getter for config/experiment).
- Client SDKs: prefer the async getter. The sync variants return the fallback if flags haven't loaded yet — only use them behind a flags-ready check.
- Server SDKs: read [exposure-correctness.md](references/exposure-correctness.md) **before** writing the call — exposure semantics and the suppression API both differ from the client SDKs.

### 5. Ship it safely

The flag is still disabled, so this code serves control to everyone. It is safe to merge and deploy before anyone enables anything. Say this explicitly — customers routinely hold the PR waiting for permission they don't need.

### 6. Verify — do not skip

**This step is the point of the skill.** Everything before it is unverified assumption.

Get yourself served a real variant, exercise the code path, and confirm:

1. The evaluation returns the variant you expect — not the fallback.
2. An exposure event actually arrives in Mixpanel, with the right flag key and variant.
3. The variant source is `network` (not `fallback`), if the SDK reports it.

**Use the QA tester allowlist for this** — it serves you a chosen variant without touching rollout configuration, which is `manage-feature-flags`'s territory rather than this skill's. Verification does need the flag enabled; if it isn't, ask the customer to enable it rather than configuring rollout yourself. Full procedure, including the fallback options when the allowlist isn't usable, is in [verification.md](references/verification.md).

If exposures are zero, work [verification.md](references/verification.md)'s diagnostic checklist — do not proceed to *Hand off*, and do not launch an experiment.

### 7. Hand off

Route what comes next per [Handing off](#handing-off). Tell the customer which skill owns what, and that the launch decision is theirs.

---

## Full Setup

Quick Start, plus the things that bite in production. Work through in order.

1. **Everything in Quick Start.**
2. **Identity.** Flags are bucketed on the assignment key, so identity correctness *is* bucketing correctness. Calling `identify()` reloads flags; `reset()` clears them. Evaluation that races either returns the pre-identify assignment. Anonymous users with rotating IDs re-bucket on every session and produce skewed splits.
3. **Environments.** There is no cross-project flag linking (verify current) — dev, staging, and prod in separate projects means separate flags, created and keyed identically in each. **Default to separate projects** — clean data separation is worth the duplicated flag admin, and it is much harder to retrofit later. Use one project with an environment runtime property in the targeting only when the customer already runs a single project per product, where splitting would fragment their existing analytics. Encode the choice in config, not in scattered conditionals.
4. **Consent.** If tracking is gated on consent, exposure events are gated with it. An evaluation that happens while opted out fires no exposure, and that event is **not** replayed when consent arrives later. Handle explicitly — see [exposure-correctness.md](references/exposure-correctness.md).
5. **Exposure correctness.** Read [exposure-correctness.md](references/exposure-correctness.md) in full. This is where experiment-invalidating bugs live.
6. **Experiment wiring**, if applicable. The backing flag is auto-created by the experiment; read its key from the experiment and implement against that. Verify exposures arrive **before** launch — launching is irreversible and locks variants, statistical model, and cohort.
7. **Cleanup plan.** Decide now what happens when the flag is done: who removes the branch, and when. Write it in the flag's description. Flags with no cleanup owner become permanent.

---

## Add a Flag

The customer already has working Mixpanel flags.

1. Confirm init already enables flags and note the context shape already in use.
2. Check whether a flag for this feature already exists — duplicate flags gating the same behavior are a common mess.
3. Route the type, create the flag, then write the evaluation call — Quick Start's *Route the flag type*, *Create the flag*, and *Write the evaluation code* steps.
4. **Still verify.** A working init does not mean the new flag is wired correctly — wrong key strings are silent.

If the new flag needs a variant assignment key or runtime properties the existing init doesn't pass, the init must be updated. This is the most common reason a second flag fails when the first one worked.

---

## Audit

A flag isn't behaving.

Customers name flags in prose ("the checkout flag"), not by key. Match on key first, then case-insensitive name; if several match, list name + key and ask which. Never ask for an internal ID.

**The diagnostic checklists live in [verification.md](references/verification.md)** — one each for always-getting-the-fallback, wrong-variant, correct-variants-but-zero-exposures, and skewed splits. Work the one that matches the symptom.

Two things to bring to them that the checklists can't supply on their own:

- **Order by cost, not by suspicion.** The checklists are already ordered by what is cheapest to rule out against how often it is the cause; resist jumping to the interesting hypothesis. A disabled flag and a mistyped key account for most reports and take seconds to rule out.
- **Separate "wrong variant" from "no exposure".** They look alike to a customer and have disjoint causes. Establish which one you're chasing before opening a checklist.

---

## Handing off

This skill stops at verified code. Three neighbours own what comes next:

| Question | Skill |
|---|---|
| Rollout %, ramp cadence, kill switch, archive, flag hygiene | `manage-feature-flags` |
| Hypothesis, metrics, sizing, launch, monitoring, results | `manage-experiment` |
| Event tracking plan, event naming, analytics strategy | `tracking-implementation` |

Reference files are linked from the step that needs them; the Mode Selection table above routes the rest.

---

## Output style

- Show the diff you intend to make before making it; flag code is load-bearing and customers want to see the branch point.
- Name the exact file and line where the evaluation call goes.
- Never claim the flag works until an exposure event has been observed. "Implemented" and "verified" are different words.
- When the SDK's behavior differs by language (exposure suppression especially), say so explicitly rather than generalizing from another SDK.
- If the customer's SDK version is below minimum, lead with that — everything else is unfixable until it's upgraded.
