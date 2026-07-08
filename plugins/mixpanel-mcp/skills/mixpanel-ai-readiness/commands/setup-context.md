# Command: setup-context

Build business context from scratch via a guided interview, when the customer has nothing written down to import. Pulls schema facts first to make questions concrete, drafts to the fixed template, previews with a diff, and writes on `CONFIRM`. Handles org level, project level, or both.

**Session reads:** `org_id`, `target_level`, `project_id`, `project_name`, `caller_role`, `existing_context`
**Session writes:** `schema_facts`, `interview_answers`, `draft_context`

> **CRITICAL:** If the customer *does* have existing context somewhere, prefer `import-context` and use this only to fill gaps. **Always offer import first** before starting this command. See SKILL.md's "Offer import-context first" step.

---

## Step 0 — Confirm the user wants interview-based setup

**ALWAYS ask this first** (unless they explicitly invoked "setup-context" or typed "interview"):

```
Do you have existing business context written down somewhere I could pull from?
  • Notion, Confluence, Google Drive, wiki, tracking plan, etc.
  • Or paste/upload a file

If yes, we'll use import-context instead (faster and more complete).
If no, I'll interview you from scratch.

Which would you prefer?
```

If they have a source, hand off to `import-context` immediately. Only proceed with this command if they confirm they have nothing to import.

## Step 1 — Research and pull schema first

Before asking the user anything (per `references/interview-questions.md`):
- **Web search the company** and draft the Business and Customer Segments sections from public sources — these are confirmed, not asked cold.
- **Pull schema facts** into `schema_facts` (top ~10 events, ~15 properties, integrations, timezone, recency), timestamped. Counts never go into prose, only the fenced Schema Snapshot. Partial failure: continue, note the gap in Open Questions.

## Step 2 — Interview (gaps and internal-only facts)

Work `references/interview-questions.md`, in small batches, seeded with research and `schema_facts`. Present the web-researched Business/Segments drafts for correction rather than asking from scratch.

Mandatory, do not skip:
- **North star, scoped to Mixpanel**: which *Mixpanel-trackable* metric best reflects success, anchored to real events. Capture any true north star that lives outside Mixpanel (revenue, NRR, GMV) separately, with the closest in-Mixpanel proxy, so the agent doesn't chase data that isn't here.
- **Qualified/active user definition** in this data.
- **Authority**: who owns the schema and canonical reports, whose conventions the agent should follow, when to defer to a human vs. create new entities. Highest-value field.
- **Vocabulary**: ask first whether a glossary/data dictionary exists and import it; only interview term-by-term if there's no source.

Record in `interview_answers`. Unknowns → Open Questions, never guessed.

## Step 3 — Compose draft

Fill `references/context-template.md`: durable `tldr;` first (what/where/when/who/how/why, 1–3 sentences each, linking deeper); qualitative sections from answers; all schema facts in the fenced, timestamped Schema Snapshot; unsupported items in Open Questions. Respect the 50k cap (trim Schema Snapshot first).

## Step 4 — Preview, diff, confirm

Show the full proposed document and a diff against `existing_context` (added/changed/removed/unchanged) — required because writes are full-replace. Prompt:

```
Write this to [org / project: NAME] business context?
  CONFIRM  — commit this exact document (replaces current context at this level)
  EXPORT   — save draft to a local .md file, don't write to Mixpanel
  edit     — tell me what to change
  exit     — discard
```

Only literal `CONFIRM` commits. For `both`, confirm each level separately.

## Step 5 — Back up, then write

Back up existing context per SKILL.md's "Back up before every write" rule, then write the full document for the level. Report level + char count. On permission error, fall back to `EXPORT` and name the required role.

## Follow-on

"Now set up the **data layer** (event/property descriptions + tags via manage-lexicon) so the agent understands your schema?" → hands to `enrich-data`.
