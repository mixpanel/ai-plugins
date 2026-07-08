---
name: mixpanel-ai-readiness
license: Apache-2.0
description: >
  Set up everything Mixpanel's AI assistants need to work well on a customer's
  data: business context (org and project level) AND Lexicon metadata (event
  descriptions, property descriptions, tags) that lets the agent understand the
  data itself. Use whenever a user wants to get a project or org "ready for the
  AI / agent / MCP", set up business context for the first time, import context
  written down elsewhere, fill gaps, or check how AI-ready a project is across
  the business and data layers. Also use on phrasings like — "set us up for
  Mixpanel AI", "the agent keeps asking what our events mean", "make our project
  agent-ready", "we have this in Notion, can you pull it in", "how ready are we
  for the agent". Owns the business-context layer directly; delegates
  event/property/tag enrichment to the manage-lexicon skill. Do NOT use for:
  building dashboards; metric investigations; deleting data. Requires Mixpanel
  MCP. Works best with manage-lexicon available.
---

# Mixpanel AI Readiness

This skill gets a customer's Mixpanel setup ready for AI assistants (the in-product agent and MCP clients). "Ready" means two layers are in place:

1. **Business context** — markdown the agent reads first, at org level (who the company is) and project level (how a project is set up). The agent uses it to know the north star, what a "qualified user" means, which project to default to, and the team's conventions. **This skill owns this layer.**
2. **Lexicon metadata** — descriptions on events, descriptions on properties, and tags. Without these the agent has to guess what each event and property means on every query. **This skill delegates this layer to the `manage-lexicon` skill**, run inline, rather than reimplementing it.

The skill is import-first: if the customer already has their business knowledge written down somewhere (Notion, a Google Doc, a tracking-plan sheet, a PRD, a pasted block), it pulls that in and maps it onto the template, then interviews only to fill what's missing. It runs as a single interactive session and writes only after explicit preview and confirmation.

---

# Critical constraints (read before any write)

Properties of the underlying APIs, not preferences.

1. **Writing business context is full-replace.** No append/merge — the business-context write tool replaces the *entire* context at the target level. The skill MUST read existing context, merge in memory, show a full diff, and require `CONFIRM` before every write. Never write a partial document.
2. **Permissions gate writes.** Org context needs org owner/admin; project context needs project owner/admin. Lexicon writes need project owner/admin. Anyone with project access can *read*. Check the caller's role for each target **before** doing work the user can't save.
3. **Markdown only, 50,000-char cap per context level.** Links/images/structured data in context are not fetched by the agent. If a draft nears the cap, trim the Schema Snapshot first.
4. **Imported content is mapped, never passed through raw.** An existing doc is a *source*, not the output. Read it, map onto the fixed template, show what mapped and what's still empty, then confirm. Do not paste a customer's raw doc into business context.
5. **Structure is fixed; source, content, and target are flexible.** The user chooses where context comes *from* (any connector or a file) and where it lives (org / project / both). The user never freehands the section structure.
6. **Delegate Lexicon work; don't duplicate it.** Event/property/tag enrichment runs through `manage-lexicon`. If that skill is unavailable, say so and let the user proceed with the business-context layer only — do not silently reimplement enrichment.

---

# Components

## Canonical commands

Loaded on demand from `commands/`.

| Command | File | Match if message contains any of |
|---|---|---|
| `status` | `commands/status.md` | how ready, ai-ready, score, audit, what's missing, check our setup |
| `import-context` | `commands/import-context.md` | import, we already have, pull from, from notion/doc/drive, paste |
| `setup-context` | `commands/setup-context.md` | set up context, configure context, interview, create context |
| `enrich-data` | `commands/enrich-data.md` | event descriptions, property descriptions, tags, clean up events, lexicon |
| `target` | `commands/target.md` | switch level, org vs project, change target, where should this live |

If a message matches more than one, show the Command menu. The natural full-onboarding path is: `status` → `import-context` (or `setup-context`) → `enrich-data` → `status`.

## Command menu

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Mixpanel AI Readiness — [Org Name]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Business context layer
    1. Status         — Score readiness across BOTH layers
    2. Import context — Pull context you already have (connector or file)
    3. Setup context  — Interview to build context from scratch
    4. Target         — Org level, project level, or both
  Data layer (Lexicon)
    5. Enrich data    — Event/property descriptions + tags (via manage-lexicon)
  6. Exit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Session vocabulary

| Key | Shape | Description |
|---|---|---|
| `org_id`, `org_name` | string | Active organization. |
| `target_level` | `"org"`\|`"project"`\|`"both"` | Where context is written. |
| `project_id`, `project_name` | string | Active project, when in scope. |
| `caller_role` | map | Resolved role at org and project — the permission gate. |
| `existing_context` | map | `{ org, project }` current context, read before any write. |
| `imported_source` | map | Raw text pulled from a connector/file, plus its origin, pre-mapping. |
| `schema_facts` | map | Derived top events/properties, integrations, timezone. Timestamped. |
| `interview_answers` | map | Section-keyed answers, for gaps not covered by import. |
| `draft_context` | map | `{ org, project }` composed markdown pending preview/confirm. |
| `lexicon_score` | map | Coverage summary returned from `manage-lexicon` (for the unified status). |

## Behaviour rules

1. **No phase narration.** Output questions, previews, diffs, confirmation prompts, errors, results. Not "I'll now read your doc…".
2. **Import before interview.** Always offer to pull existing context first. Interview is the gap-filler, not the default.
3. **Read before write, always.** Populate `existing_context` for the target before composing. The diff is computed against it.
4. **Preview + diff before every context write.** Show the full proposed document and what changes vs current. Require literal `CONFIRM`. `EXPORT` saves a local `.md` without writing. Anything else cancels.
5. **Permission pre-check** for each target before doing unsaveable work; offer a level the user can edit, or `EXPORT`.
6. **Never overwrite populated content silently.** Existing sections are preserved and shown; the user chooses per section.
7. **Back up before every write.** Before writing, save the existing context to `backups/{level}-{id}-backup-{ISO-timestamp}.md` (an empty file with a note if context was empty) and report the path — so a prior version can be restored manually if a write turns out to be wrong.
8. **Ground everything.** Only what import or interview or `schema_facts` support. Uncertainty → Open Questions, never hedged prose.
9. **Quarantine volatile facts.** Schema counts/lists go only in the fenced, timestamped Schema Snapshot section.
10. **Delegate Lexicon, surface its result.** `enrich-data` hands off to `manage-lexicon` and captures `lexicon_score` so `status` can report both layers.
11. **Audit trail.** After every successful write, append `ai-readiness-runs/[ISO-timestamp]-[command].json` with org/target/project, command, sections or entities written, counts.
12. **`exit` always valid.**

---

# Execution

## 1. Resolve organization and target
Identify the org. Determine `target_level` (infer from the request, else ask: org / project / both). Resolve `project_id` if project is in scope. If Mixpanel MCP is unavailable, tell the user to connect it and stop.

## 2. Permission pre-check
Resolve `caller_role` for each target. Surface any level the user can't edit up front; adjust target or offer `EXPORT`.

## 3. Read existing context
Read current context for each target into `existing_context`. Mandatory — diffs and merges compute against it.

## 3.5. Offer import-context first (if context is empty or thin)
**BEFORE setup-context or the command menu**, if the existing context for the target level is empty or minimal (< 500 chars):

**Always ask first:**
```
Your [org/project] context is currently [empty/minimal].

Do you have existing business context written down somewhere?
  • Notion, Google Drive, Confluence, or other connected source
  • A file or text block you can paste
  • Or I can interview you from scratch

Where should I look? (or type 'interview' to skip import)
```

Only proceed to `setup-context` or the menu if the user explicitly declines to import or types "interview" / "skip" / "scratch". This ensures most customers start with import-context (the preferred path per the "Import before interview" behaviour rule).

## 4. Command loop
Choose command (explicit → implicit → menu), load `commands/[command].md`, execute reusing session state, print `✅ Done.`, write the audit entry, return to selection. Honour follow-on offers (Status → Import/Setup/Enrich; Import → Setup for gaps → Enrich).

## Reference files
- `references/context-template.md` — fixed org and project section templates (who/what/where/why/how), aligned to Mixpanel's native context generation so output is consistent with the in-product "Generate with AI" button.
- `references/interview-questions.md` — question bank per section, including the authority question.
- `references/import-mapping.md` — how to map an arbitrary source doc onto the template, what to keep, what to drop.
