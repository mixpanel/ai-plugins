# Command: import-context

Pull business knowledge the customer has already written down and turn it into template-conformant context, then write on `CONFIRM`. This is the preferred starting path — most customers have *something* already, and adapting it beats a cold interview.

**Session reads:** `org_id`, `target_level`, `project_id`, `caller_role`, `existing_context`, `schema_facts`
**Session writes:** `imported_source`, `interview_answers` (for gaps), `draft_context`

---

## Step 1 — Find the source

Ask where the existing context lives, and accept any of:

- **A connected MCP connector** — e.g. Notion, Google Drive, Confluence, a wiki, a knowledge source. Search it for the relevant doc (tracking plan, data dictionary, analytics README, PRD, "about our metrics" page). If several connectors are connected, ask which to search, or search the most likely and confirm the hit.
- **A pasted block or uploaded file** — the user drops text or a file directly.

Do not assume which connector. Detect what's connected; if nothing relevant is, fall back to paste/file. If the user names a connector that isn't connected, tell them and offer paste/file or `setup-context` instead.

Store the raw retrieved text and its origin in `imported_source` — never written to Mixpanel (see SKILL.md's "Imported content is mapped, never passed through raw" constraint).

## Step 2 — Map onto the template

Using `references/import-mapping.md`, map the source onto `references/context-template.md` for the target level(s):

- Pull each template section's content from the source where it exists.
- **Drop** what doesn't belong — see `references/import-mapping.md`'s "What to drop" list.
- Do not invent. If a section has no source material, leave it empty and mark it for the gap step.
- Schema-derived facts still come from `schema_facts` (pulled during setup), not from the doc — the doc's own numbers are likely stale.

## Step 3 — Show the mapping

Present a coverage view so the user sees exactly what the import produced:

```
Mapped from [source]:
  ✓ Business                                        ← from doc
  ✓ North Star & Key Metrics                        ← from doc
  ✓ Internal Vocabulary & Acronyms                  ← from doc
  ⚠ Definition of Active/Qualified User (this project) — partial, needs confirmation
  ✗ Authority & Governance                          — not found in source
  ✗ Key Dashboards & Reports                         — not found in source
```

Use the literal template heading text for every row, per `references/import-mapping.md`'s verbatim-heading rule. Anything ✗ or ⚠ is a gap.

## Step 4 — Fill gaps (mini-interview)

For gaps only, ask the targeted questions from `references/interview-questions.md`. Always cover that file's "Always ask if not already covered" mandatory list for anything the import didn't already fill. Record in `interview_answers` (unknowns → Open Questions per SKILL.md's "Ground everything" rule).

## Step 5 — Compose and write

Compose `draft_context` per SKILL.md's Write flow composition rules, with the mapped source material in its sections and gap answers from `interview_answers`. Then run SKILL.md's Write flow section.

## Follow-on

After writing: "Want me to **enrich the data layer** (event/property descriptions and tags) so the agent understands your schema too? I'll run that through manage-lexicon." → hands to `enrich-data`.
