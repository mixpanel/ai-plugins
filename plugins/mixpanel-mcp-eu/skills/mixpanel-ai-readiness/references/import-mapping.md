# Import Mapping

How to turn an arbitrary source document into template-conformant context. The source is *input*; the output is always the fixed template. Never paste raw source into Mixpanel.

## Mapping table (source → template section)

| If the source has… | Map to |
|---|---|
| "About us", company overview, what we do/sell | Business / Domain & Vocabulary |
| North star, primary KPI, "the one metric", success criteria | North Star & Key Metrics |
| Definition of active/qualified/engaged user, MAU/WAU logic | Definition of Qualified User |
| Customer types, segments, personas, tiers | Customer Segments |
| Glossary, acronyms, "what we mean by X" | Internal Vocabulary & Acronyms |
| Tracking plan, event spec, naming rules, casing/prefix conventions | Event Taxonomy & Naming Conventions |
| Data owner, schema owner, "ask X before adding events", RACI | Authority & Governance |
| List of canonical dashboards/reports and their purpose | Key Dashboards & Reports |
| Default project guidance, which project for what | Conventions & Defaults (org) |

## What to drop (do not map)

- Meeting notes, decisions logs, dated standups.
- Roadmap, upcoming features, "Q3 plans" — time-bound, not durable context.
- Changelogs, migration notes, ticket references.
- Anything that contradicts the live schema — flag it as an Open Question rather than importing it.
- Raw numbers/counts — schema facts come from the live pull, fenced and timestamped, not from the doc.

## Rules

- **One concept per template section.** If the source mixes business intent and operational notes in one paragraph, extract only the durable business intent.
- **Preserve the customer's own vocabulary.** If they call it "design partners" not "enterprise customers", keep their term — the agent should speak their language.
- **Attribute nothing you can't ground.** If the doc implies an owner but doesn't name one, that's an Open Question, not an Authority entry.
- **Show your work.** The coverage view (import-context Step 3) must make clear which sections came from the source and which are still empty, so the user trusts the result and knows what the gap-interview will cover.
