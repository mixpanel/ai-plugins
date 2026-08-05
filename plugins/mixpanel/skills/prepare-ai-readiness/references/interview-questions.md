# Interview Questions

Starter question bank, grouped by template section (`tldr;` and section names are defined in `references/context-template.md`). **Principle: never ask the customer what you can already find or fetch.** Research public facts first and present them to confirm; pull internal facts from their sources; only interview for what's genuinely internal and undocumented. Adapt wording per customer, seed with `schema_facts` (the live schema pull — see SKILL.md's session vocabulary) where noted, ask in small batches. Unknown answers go to Open Questions per SKILL.md's "Ground everything" rule.

---

## Before interviewing — research and pre-fill

`commands/setup-context.md`'s "Research and pull schema first" step owns the pre-fill procedure — web-search the company to draft the Business and Customer Segments sections, and pull `schema_facts`. When that step has run (the `setup-context` path, with web search available), the interview is mostly confirmation, not blank-filling. When it hasn't — no web search tool, or the `import-context` gap-filling path — use each section's fallback question and ask directly. (Checking for a definitions source before vocabulary questions is handled by the Internal Vocabulary & Acronyms subsection, which is marked "ask for a source first.")

---

## Org level

### Business  *(confirm the web-research draft when one exists; else use the fallback)*
- Here's what I found about the company: [drafted summary]. Is this right? Anything to fix or add?
- Anything about the business model or how you make money that the public description gets wrong?
- *(Fallback, no pre-fill)* In a sentence or two: what does the company do, and how does it make money?

### North Star & Key Metrics  *(must be Mixpanel-trackable)*
- *(Seed with schema_facts)* Of the things you actually track in Mixpanel, which metric best reflects success? (anchor to real events, e.g. "is it `[X]`, activations, something else?")
- What are the 2–3 supporting metrics **in Mixpanel** underneath it?
- Is your true company north star something Mixpanel can't see? (e.g. revenue, NRR (net revenue retention), GMV (gross merchandise value) in a finance tool) If so, name it and the closest Mixpanel proxy — I'll note both so the agent doesn't chase data that isn't here.
- How do you define an "active" or "qualified" user in this data? (the exact rule)

### Customer Segments  *(confirm the web-research draft when one exists; else use the fallback)*
- I have these as your main customer types: [drafted list]. Accurate? Any segments you analyze separately that aren't obvious from outside?
- Which internal teams or roles use Mixpanel here (e.g. growth, product, support)? (feeds the org `tldr;`'s "Who" line — its internal-users clause)
- *(Fallback, no pre-fill)* What are your main customer types or segments, and what distinguishes them?

### Default Project & Routing
- When someone asks a product question without naming a project, which project should the agent look in first?
- Which project answers which kind of question (e.g. web vs mobile, prod vs internal)? Any projects the agent should avoid (test, staging, sandbox)?

### Internal Vocabulary & Acronyms  *(ask for a source first)*
- Do you have a glossary, data dictionary, or definitions page anywhere? If so, point me to it and I'll pull from it.
- If not: what internal terms or acronyms would the agent misread? Term + meaning. (focus on words that mean something specific in *your* data — "activation", "engaged", "churned")

---

## Project level

### Domain & Vocabulary
- What product or surface does this project track? (web app, mobile, backend, a specific feature)
- Who is the end-user whose behavior shows up here? (your customer, an internal team, a machine/service)
- *(Seed with schema_facts' integrations)* Where does this project's data come from — client SDK, server-side, a warehouse import, or a mix? (confirms the schema-sourced "Where" line in the project `tldr;`)
- *(Seed with schema_facts)* Your highest-volume events are `[X]` and `[Y]` — one line each, what do those represent?

### Event Taxonomy & Naming Conventions
- How are events named here? Casing or prefix rules? (e.g. "Verb Noun", `[Verified]` prefix, snake_case)
- *(Seed with schema_facts)* I see properties like `[A]` and `[B]` — what do they mean, and which matter most for analysis?
- Any events or properties that look important but should be ignored? (test, deprecated, internal-only)
- How is analysis actually done here — custom entities or cohorts built on raw events, saved reports, conventions analysts follow? (feeds the project `tldr;`'s "How" line)

### Authority & Governance
- Who owns the schema and the canonical reports in this project?
- Whose naming and conventions should the agent follow when unsure?
- When should the agent stop and ask a human instead of creating a new event, property, or report itself?

### Key Dashboards & Reports
- Which dashboards/reports are the canonical, trusted ones? What is each for?
- Where would you point a new team member first?

### Definition of Active/Qualified User (this project)
- Does "active" or "qualified" user mean something different here than at the org level? If so, what?

### Why (feeds the project `tldr;` — no dedicated body section)
- What decisions does this project's analysis actually drive, and who acts on them?

---

## Always ask if not already covered

Highest-value fields; source docs and web search usually lack them. Don't close an interview without them:

1. **Active/qualified user definition** — applied on almost every agent question.
2. **Authority** — see the Authority & Governance questions; who owns the schema and whose conventions to follow, so the agent doesn't copy a random user's messy style.
3. **North star, scoped to Mixpanel** — anchored to events that exist here, with any out-of-Mixpanel true north star noted separately.
4. **Vocabulary** — see the Internal Vocabulary & Acronyms questions; check for a source before interviewing term-by-term.
5. **Why (project `tldr;`)** — see the Why question (Project level → Why). It's a tldr-only field with no body section, so `import-mapping.md` can't map it from a source doc — it must come from this list.
6. **Internal users (org `tldr;`)** — see the Customer Segments questions (Org level → Customer Segments; the internal-teams-and-roles bullet). Not covered by any external-facing source material, so `import-mapping.md` can't map it from a source doc either — it must come from this list.

This is the canonical mandatory list — `commands/setup-context.md` and `commands/import-context.md` point here rather than restating it.
