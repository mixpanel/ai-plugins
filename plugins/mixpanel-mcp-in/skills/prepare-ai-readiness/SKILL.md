---
name: prepare-ai-readiness
license: Apache-2.0
description: >
  Gets a Mixpanel org or project ready for its AI assistants — business context
  and Lexicon metadata. Use to set up or import context, fill gaps, or check
  AI-readiness: "set us up for Mixpanel AI", "how ready are we for the agent".
  Not for dashboards or metrics. Requires Mixpanel MCP.
---

# Mixpanel AI Readiness

This skill gets a customer's Mixpanel setup ready for AI assistants (the in-product agent and MCP clients). "Ready" means two layers are in place:

1. **Business context** — markdown designed to be the agent's first read, at org level (who the company is) and project level (how a project is set up), so it can ground the north star, what a "qualified user" means, which project to default to, and the team's conventions. **This skill owns this layer.**
2. **Lexicon metadata** — descriptions on events, descriptions on properties, and tags. Without these the agent has less signal for what each event and property means. **This skill delegates this layer to the `manage-lexicon` skill**, run inline, rather than reimplementing it.

How the agent consumes each layer evolves with the product — verify current agent behavior against Mixpanel docs.

The skill is import-first: if the customer already has their business knowledge written down somewhere (Notion, a Google Doc, a tracking-plan sheet, a PRD, a pasted block), it pulls that in and maps it onto the template, then interviews only to fill what's missing. It runs as a single interactive session and writes only after explicit preview and confirmation.

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
4. **Preview + diff before every context write.** Never write without showing the full proposed document, a diff against `existing_context`, and getting explicit confirmation.
5. **Permission pre-check** for each target before doing unsaveable work; offer a level the user can edit, or `EXPORT` (saves the draft to a local file instead of writing to Mixpanel — see Write flow below).
6. **Never overwrite populated content silently.** Existing sections are preserved and shown; the user chooses per section.
7. **Back up before every write.** Before writing, save the existing context to `backups/{level}-{id}-backup-{ISO-timestamp}.md` (an empty file with a note if context was empty) and report the path — so a prior version can be restored manually if a write turns out to be wrong. If no local file-write capability is available (or it's denied), don't write or fail silently: print the full existing document inline so the user can save it themselves, and get explicit confirmation to proceed without a file backup.
8. **Ground everything.** Only what import or interview or `schema_facts` support. Uncertainty → Open Questions, never hedged prose.
9. **Quarantine volatile facts.** Schema counts/lists go only in the fenced, timestamped Schema Snapshot section.
10. **Delegate Lexicon, surface its result.** `enrich-data` hands off to `manage-lexicon` and captures `lexicon_score` so `status` can report both layers.
11. **Audit trail.** After every successful write, append `ai-readiness-runs/[ISO-timestamp]-[command].json` with org/target/project, command, sections or entities written, counts.
12. **`exit` always valid.**
13. **Resolve identifiers by name or ID.** Accept org/project by human-readable name or system ID. Match by ID first, then by case-insensitive name; if a name matches more than one, list the matches and ask which.

## Write flow

The shared tail of `setup-context` and `import-context`, and the canonical definition of the composition rules, confirmation prompt, and write sequence. Each command sources `draft_context` its own way (from interview answers, or from mapped source), but composes it by the same rules: fill `references/context-template.md` with the durable `tldr;` first; schema facts from `schema_facts` only in the fenced, timestamped Schema Snapshot; anything unsupported in Open Questions (per the "Ground everything" rule); respect the 50,000-char cap per context level (see Critical constraints below), trimming the Schema Snapshot first. From the composed draft, both do exactly this:

1. **Preview, diff, confirm.** Show the full proposed document and a diff against `existing_context` (added/changed/removed/unchanged). For `both`, show both levels together. Prompt:
   ```
   Write this to [org / project: NAME / both] business context?
     CONFIRM  — commit this exact document (replaces current context at that level)
     EXPORT   — save draft to a local .md file, don't write to Mixpanel
     edit     — tell me what to change
     exit     — discard
   ```
   Only literal `CONFIRM` commits; for `both`, one `CONFIRM` applies both levels (writes run per level; report each). `edit` scopes to the level named. Anything else cancels.
2. **Back up, then write.** Back up per the "Back up before every write" rule, then write the document. Report level + char count. On permission error, fall back to `EXPORT` and name the required role.

---

# Critical constraints (read before any write)

Properties of the underlying APIs, not preferences — every constraint below can change as Mixpanel's product evolves; verify current behavior, limits, and role requirements against Mixpanel docs before relying on the specifics.

1. **Writing business context is full-replace.** No append/merge — the business-context write tool replaces the *entire* context at the target level. Because of this, the skill MUST read existing context, merge in memory, and run the Write flow (full diff + `CONFIRM`) before every write. Never write a partial document.
2. **Permissions gate writes.** Org context needs org owner/admin; project context needs project owner/admin. Lexicon writes need project owner/admin. Anyone with project access can *read*. Check the caller's role for each target **before** doing work the user can't save.
3. **Markdown only, 50,000-char cap per context level.** Links/images/structured data in context are not fetched by the agent. If a draft nears the cap, trim the Schema Snapshot first.
4. **Imported content is mapped, never passed through raw.** An existing doc is a *source*, not the output. Read it, map onto the fixed template, show what mapped and what's still empty, then confirm. Do not paste a customer's raw doc into business context.
5. **Structure is fixed; source, content, and target are flexible.** The user chooses where context comes *from* (any connector or a file) and where it lives (org / project / both). The user never freehands the section structure.
6. **`manage-lexicon` can be unavailable.** Enrichment runs through it, per the "Delegate Lexicon, surface its result" behaviour rule. If the skill is unavailable, say so and let the user proceed with the business-context layer only — do not silently reimplement enrichment.

---

# Execution

## 1. Resolve organization and target
Identify the org. Determine `target_level` (infer from the request, else ask: org / project / both). Resolve `project_id` if project is in scope. If Mixpanel MCP is unavailable, tell the user to connect it and stop.

## 2. Permission pre-check
Resolve `caller_role` for each target. Surface any level the user can't edit up front; adjust target or offer `EXPORT`.

## 3. Read existing context
Populate `existing_context` for each target — mandatory before composing, per the "Read before write, always" rule.

## 3.5. Offer import-context first (if context is empty or thin)
**BEFORE the command menu**, if the existing context for the target level is empty or minimal (< 500 chars):

**Always ask first:**
```
Your [org/project] context is currently [empty/minimal].

Do you have existing business context written down somewhere?
  • Notion, Google Drive, Confluence, or other connected source
  • A file or text block you can paste
  • Or I can interview you from scratch

Where should I look? (or type 'interview' to skip import)
```

Only proceed to `setup-context` or the menu if the user explicitly declines to import — types "interview" / "skip" / "scratch" — or explicitly invoked `setup-context` by name (asking to interview from scratch is itself a decline). This ensures most customers start with import-context (the preferred path per the "Import before interview" behaviour rule) without asking twice when the user already said which path they want.

## 4. Command loop
Choose command (explicit → implicit → menu), load `commands/[command].md`, execute reusing session state, print `✅ Done.`, write the audit entry if the command wrote anything (per the "Audit trail" rule — read-only commands like `status` skip it), return to selection. Honour follow-on offers (Status → Import/Setup/Enrich; Import → Setup for gaps → Enrich).

## Reference files
- `references/context-template.md` — fixed org and project section templates, following a what/where/who/how/why framework at project level (org level uses a subset, plus default-project routing); that file carries the note on alignment with Mixpanel's native context generation.
- `references/interview-questions.md` — question bank per section, including the authority question.
- `references/import-mapping.md` — how to map an arbitrary source doc onto the template, what to keep, what to drop.
