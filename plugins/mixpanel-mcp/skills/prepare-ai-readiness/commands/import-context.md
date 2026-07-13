# Command: import-context

Pull business knowledge the customer has already written down, map it onto the fixed template, show what mapped and what's still empty, then write on `CONFIRM`. This is the preferred starting path — most customers have *something* already, and adapting it beats a cold interview.

**Session reads:** `org_id`, `target_level`, `project_id`, `caller_role`, `existing_context`, `schema_facts`
**Session writes:** `imported_source`, `interview_answers` (for gaps), `draft_context`

---

## Step 1 — Find the source

Ask where the existing context lives, and accept any of:

- **A connected MCP connector** — e.g. Notion, Google Drive, Confluence, a wiki, a knowledge source. Search it for the relevant doc (tracking plan, data dictionary, analytics README, PRD, "about our metrics" page). If several connectors are connected, ask which to search, or search the most likely and confirm the hit.
- **A pasted block or uploaded file** — the user drops text or a file directly.

Do not assume which connector. Detect what's connected; if nothing relevant is, fall back to paste/file. If the user names a connector that isn't connected, tell them and offer paste/file or `setup-context` instead.

Store the raw retrieved text and its origin in `imported_source`. Never write this raw text to Mixpanel — it is input, not output.

## Step 2 — Map onto the template

Using `references/import-mapping.md`, map the source onto `references/context-template.md` for the target level(s):

- Pull each template section's content from the source where it exists.
- **Drop** what doesn't belong: meeting notes, roadmap, changelogs, anything time-bound or operational that isn't durable context.
- Do not invent. If a section has no source material, leave it empty and mark it for the gap step.
- Schema-derived facts still come from `schema_facts` (Step via setup-context's schema pull), not from the doc — the doc's own numbers are likely stale.

## Step 3 — Show the mapping

Present a coverage view so the user sees exactly what the import produced:

```
Mapped from [source]:
  ✓ Business / domain        ← from doc
  ✓ North star               ← from doc
  ✓ Vocabulary & acronyms    ← from doc
  ⚠ Qualified-user definition — partial, needs confirmation
  ✗ Authority & governance   — not found in source
  ✗ Key dashboards           — not found in source
```

Anything ✗ or ⚠ is a gap.

## Step 4 — Fill gaps (mini-interview)

For gaps only, ask the targeted questions from `references/interview-questions.md`. Always include the **authority** question and the **qualified-user** question if the import didn't cover them — these are the highest-value fields and source docs usually lack them. Record in `interview_answers`. Unknowns → Open Questions.

## Step 5 — Compose, preview, diff, confirm

Identical to `setup-context` Steps 3–4: compose `draft_context` to the template (durable content first, schema facts fenced + timestamped, uncertainty in Open Questions), respect the 50k cap, show the full document plus a diff against `existing_context`. Only literal `CONFIRM` proceeds to write. `EXPORT` saves a local `.md`. For `both`, confirm each level separately.

## Step 6 — Back up, then write

Back up existing context per SKILL.md's "Back up before every write" rule, then write the composed document. Report level + char count. On permission error, fall back to `EXPORT` and name the required role.

## Follow-on

After writing: "Want me to **enrich the data layer** (event/property descriptions and tags) so the agent understands your schema too? I'll run that through manage-lexicon." → hands to `enrich-data`.
