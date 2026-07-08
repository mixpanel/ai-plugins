# Interview Questions

Starter question bank, grouped by template section. **Principle: never ask the customer what you can already find or fetch.** Research public facts first and present them to confirm; pull internal facts from their sources; only interview for what's genuinely internal and undocumented. Adapt wording per customer, seed with `schema_facts` where noted, ask in small batches. Unknown answers → Open Questions, never guessed.

---

## Before interviewing — research and pre-fill

Do these first, so the interview is mostly confirmation, not blank-filling:

1. **Web search the company.** What it does, business model, customers/segments. Draft the **Business** and **Customer Segments** sections from public sources, then present for correction (see below). Don't ask these cold.
2. **Pull the schema** into `schema_facts` (top events, key properties) — needed to anchor the north-star and event questions to what actually exists in Mixpanel.
3. **Check for a definitions source.** Before asking vocab questions, ask if one exists and import it instead.

---

## ORG LEVEL

### Business  *(pre-filled from web search — confirm, don't ask)*
- Here's what I found about the company: [drafted summary]. Is this right? Anything to fix or add?
- Anything about the business model or how you make money that the public description gets wrong?

### Customer Segments  *(pre-filled from web search — confirm, don't ask)*
- I have these as your main customer types: [drafted list]. Accurate? Any segments you analyze separately that aren't obvious from outside?

### North Star & Key Metrics  *(must be Mixpanel-trackable)*
- *(Seed with schema_facts)* Of the things you actually track in Mixpanel, which metric best reflects success? (anchor to real events, e.g. "is it `[Verified] Query Run`, activations, something else?")
- What are the 2–3 supporting metrics **in Mixpanel** underneath it?
- Is your true company north star something Mixpanel can't see? (e.g. revenue, NRR, GMV in a finance tool) If so, name it and the closest Mixpanel proxy — I'll note both so the agent doesn't chase data that isn't here.
- How do you define an "active" or "qualified" user in this data? (the exact rule)

### Vocabulary & Acronyms  *(ask for a source first)*
- Do you have a glossary, data dictionary, or definitions page anywhere? If so, point me to it and I'll pull from it.
- If not: what internal terms or acronyms would the agent misread? Term + meaning. (focus on words that mean something specific in *your* data — "activation", "engaged", "churned")

---

## PROJECT LEVEL

### Domain & Vocabulary
- What product or surface does this project track? (web app, mobile, backend, a specific feature)
- Who is the end-user whose behavior shows up here? (your customer, an internal team, a machine/service)
- *(Seed with schema_facts)* Your highest-volume events are `[X]` and `[Y]` — one line each, what do those represent?

### Event Taxonomy & Naming Conventions
- How are events named here? Casing or prefix rules? (e.g. "Verb Noun", `[Verified]` prefix, snake_case)
- *(Seed with schema_facts)* I see properties like `[A]` and `[B]` — what do they mean, and which matter most for analysis?
- Any events or properties that look important but should be ignored? (test, deprecated, internal-only)

### Authority & Governance
- Who owns the schema and the canonical reports in this project?
- Whose naming and conventions should the agent follow when unsure?
- When should the agent stop and ask a human instead of creating a new event, property, or report itself?

### Key Dashboards & Reports
- Which dashboards/reports are the canonical, trusted ones? What is each for?
- Where would you point a new team member first?

### Qualified User (this project)
- Does "active" or "qualified" user mean something different here than at the org level? If so, what?

### Why / Business Impact
- What decisions does this project's analysis actually drive, and who acts on them?

---

## Always ask if not already covered

Highest-value fields; source docs and web search usually lack them. Don't close an interview without them:

1. **Qualified/active user definition** — applied on almost every agent question.
2. **Authority** — who owns the schema and whose conventions to follow. Prevents the agent copying a random user's messy style.
3. **North star, scoped to Mixpanel** — anchored to events that exist here, with any out-of-Mixpanel true north star noted separately.
