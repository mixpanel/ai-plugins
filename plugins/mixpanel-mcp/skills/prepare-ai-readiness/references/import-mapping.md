# Import Mapping

How to turn an arbitrary source document into template-conformant context. The source is *input*; the output is always the fixed template — per SKILL.md's "Imported content is mapped, never passed through raw" constraint.

## Mapping table (source → template section)

Section names are the literal `references/context-template.md` headings — use them verbatim, never a paraphrase. One annotation is allowed in Map-to cells: an "— bullet …" suffix names a bullet *inside* the section and is not part of the heading. ("(this project)" carries no such caveat — it *is* part of the literal project-level heading.)

| If the source has… | Map to | Level |
|---|---|---|
| "About us", company overview, what we do/sell | Business | org |
| Product/surface description, what events represent, who the tracked end-user is | Domain & Vocabulary | project |
| North star, primary KPI, "the one metric", success criteria | North Star & Key Metrics | org |
| Definition of active/qualified/engaged user, MAU/WAU logic (org-wide) | North Star & Key Metrics — bullet "Definition of Active/Qualified User" | org |
| Definition of active/qualified/engaged user, MAU/WAU logic (project-specific override) | Definition of Active/Qualified User (this project) | project |
| Customer types, segments, personas, tiers | Customer Segments | org |
| Glossary, acronyms, "what we mean by X" | Internal Vocabulary & Acronyms | org |
| Default-project guidance, "which project for what", projects to avoid | Default Project & Routing | org |
| Tracking plan, event spec, naming rules, casing/prefix conventions | Event Taxonomy & Naming Conventions | project |
| Data owner, schema owner, "ask X before adding events" | Authority & Governance | project |
| List of canonical dashboards/reports and their purpose | Key Dashboards & Reports | project |

Three template fields have no body section to map to. Two are filled by `import-context`'s "Fill gaps (mini-interview)" step (targeted questions for what the import left empty) instead of by import mapping:

- The project `tldr;`'s "Why" line.
- The org `tldr;`'s "Who" line's internal-users clause (Customer Segments only covers external customer types).

The third — the project `tldr;`'s "Where" line — is never mapped from a source doc: its integrations come from `schema_facts` (pulled live, see SKILL.md's session vocabulary), and the SDK/server/warehouse detail is confirmed via the Domain & Vocabulary "Where" question ("where does this project's data come from?") in `references/interview-questions.md`.

`Open Questions` is never a direct mapping target either — it's populated via SKILL.md's "Ground everything" rule: anything the source can't ground lands there, not in a mapped section. Schema contradictions are one such case (see "What to drop").

## What to drop (do not map)

- Meeting notes, decisions logs, dated standups.
- Roadmap, upcoming features, "Q3 plans" — time-bound, not durable context.
- Changelogs, migration notes, ticket references.
- Anything that contradicts the live schema — flag it as an Open Question rather than importing it.
- Raw numbers/counts — barred by context-template.md's "no quantity-in-prose" rule; any live counts come from the schema pull, never from the doc.

## Rules

- **One concept per template section.** If the source mixes business intent and operational notes in one paragraph, extract only the durable business intent. E.g. from "activation is our north star, tracked on the growth pod's dashboard," map "activation" to North Star & Key Metrics and route the dashboard to Key Dashboards & Reports — don't paste the whole sentence into one section.
- **Preserve the customer's own vocabulary.** If they call it "design partners" not "enterprise customers", keep their term — the agent should speak their language.
- **Attribute nothing you can't ground.** If the doc implies an owner but doesn't name one, that's an Open Question, not an Authority entry.
