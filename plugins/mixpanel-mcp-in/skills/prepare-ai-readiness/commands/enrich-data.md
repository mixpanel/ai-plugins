# Command: enrich-data

Set up the Lexicon metadata the agent needs to understand the data itself: event descriptions, property descriptions, and tags. This command **delegates to the `manage-lexicon` skill** run inline — it does not reimplement enrichment. Its job is to hand off cleanly and capture the result for the unified readiness status.

**Session reads:** `org_id`, `project_id`, `project_name`, `caller_role`
**Session writes:** `lexicon_score`

---

## Step 1 — Preconditions

- A project must be in scope (`project_id`). If only org-level context was being worked on, ask which project to enrich — Lexicon is per-project.
- The caller needs project owner/admin to write Lexicon. Check `caller_role`; if missing, say so and offer to have an admin run this step.
- Confirm `manage-lexicon` is available. If it is not, tell the user the data layer can't be set up automatically right now, point them to the `manage-lexicon` skill in the Mixpanel skills repository, and return — do **not** reimplement event/property/tag editing here.

## Step 2 — Hand off to manage-lexicon

Invoke `manage-lexicon` for this `project_id`. Drive it through, in order:

1. **`score-lexicon`** — get the current metadata health (description coverage on events and properties, tag coverage). Capture the score.
2. **`enrich-and-tag`** — fill empty event descriptions, empty property descriptions, and add tags. Respect that skill's own rules: fill-only-empty (never overwrite existing metadata), add tags rather than replace, and its preview + `CONFIRM` gate before writes. Those guardrails are the reason we delegate rather than rebuild — don't bypass them.

Let `manage-lexicon` own its previews and confirmations. This command does not duplicate or wrap those prompts; the user interacts with manage-lexicon's flow directly.

## Step 3 — Capture result

After enrichment, record the post-run coverage into `lexicon_score` (events described %, properties described %, events tagged %), so `status` can show both layers in one readout. If `manage-lexicon` ran a final score, reuse it; otherwise run `score-lexicon` once more to capture the after state.

## Follow-on

Offer: "Want me to re-run **status** so you can see the full AI-readiness picture across context and data?" → hands to `status`.
