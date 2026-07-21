# Command: enrich-data

Set up the Lexicon metadata the agent needs to understand the data itself: event descriptions, property descriptions, and tags. This command **delegates to the `manage-lexicon` skill** run inline — it does not reimplement enrichment. Its job is to hand off cleanly and capture the result for the unified readiness status.

**Session reads:** `org_id`, `project_id`, `project_name`, `caller_role`
**Session writes:** `lexicon_score`

---

## Step 1 — Preconditions

- A project must be in scope (`project_id`). If only org-level context was being worked on, ask which project to enrich — Lexicon is per-project.
- The caller needs write permission for Lexicon (see SKILL.md's "Permissions gate writes" constraint for the role matrix). Check `caller_role`; if missing, name the required role and offer to have an admin run this step.
- Confirm `manage-lexicon` is available. If it is not, follow SKILL.md's "`manage-lexicon` can be unavailable" constraint — additionally, point the user to the `manage-lexicon` skill in the Mixpanel skills repository, then return.

## Step 2 — Hand off to manage-lexicon

Hand this `project_id` to `manage-lexicon` and let it do two things, in this order: first measure current metadata health (description coverage on events and properties, tag coverage) and capture that score; then fill empty event and property descriptions and add tags — using whatever entry points that skill exposes. Respect its own guardrails (verify current behavior against that skill) — expect at least fill-only-empty (never overwrite existing metadata), add tags rather than replace, and a preview + `CONFIRM` gate before writes. Those guardrails are the reason we delegate rather than rebuild — don't bypass them.

Let `manage-lexicon` own its previews and confirmations. This command does not duplicate or wrap those prompts; the user interacts with manage-lexicon's flow directly.

## Step 3 — Capture result

After enrichment, record the post-run coverage into `lexicon_score` (events described %, properties described %, events tagged %), so `status` can show both layers in one readout. If `manage-lexicon` ran a final score, reuse it; otherwise ask it to score coverage once more to capture the after state.

## Follow-on

Offer: "Want me to re-run **status** so you can see the full AI-readiness picture across context and data?" → hands to `status`.
