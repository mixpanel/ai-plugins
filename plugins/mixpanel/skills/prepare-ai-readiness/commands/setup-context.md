# Command: setup-context

Build business context from scratch via a guided interview, when the customer has nothing written down to import. Pulls schema facts first to make questions concrete, drafts to the fixed template, previews with a diff, and writes on `CONFIRM`. Handles org level, project level, or both.

**Session reads:** `org_id`, `target_level`, `project_id`, `project_name`, `caller_role`, `existing_context`
**Session writes:** `schema_facts`, `interview_answers`, `draft_context`

---

## Step 0 — Confirm the user wants interview-based setup

Run SKILL.md's "Offer import-context first" step. If they have a source, hand off to `import-context` immediately. Only proceed with this command if that step clears (per its own exemptions).

## Step 1 — Research and pull schema first

Before asking the user anything (per `references/interview-questions.md`):
- **Web search the company** and draft the Business and Customer Segments sections from public sources — these are confirmed, not asked cold. If no web search tool is available, skip this pre-fill and ask those questions directly in Step 2 instead.
- **Pull schema facts** into `schema_facts` (top ~10 events, ~15 properties, integrations, timezone, recency), timestamped, per SKILL.md's "Quarantine volatile facts" rule. Partial failure: continue, note the gap in Open Questions.

## Step 2 — Interview (gaps and internal-only facts)

Work `references/interview-questions.md`, in small batches, seeded with research and `schema_facts`. Present the web-researched Business/Segments drafts for correction rather than asking from scratch.

Cover `references/interview-questions.md`'s "Always ask if not already covered" list in full — do not skip any item on it. Record in `interview_answers` (unknowns → Open Questions per SKILL.md's "Ground everything" rule).

## Step 3 — Compose draft

Compose `draft_context` per SKILL.md's Write flow composition rules, with the qualitative sections drawn from `interview_answers` and the research pre-fill.

## Step 4 — Preview and write

Run SKILL.md's Write flow section on the composed `draft_context`.

## Follow-on

"Now set up the **data layer** (event/property descriptions + tags via manage-lexicon) so the agent understands your schema?" → hands to `enrich-data`.
