# Context Template

Fixed section structure for generated context. Adapted from the who/what/where/why/how framework Mixpanel uses for native context generation, so skill output stays consistent with the in-product "Generate with AI" button. **Structure is fixed; only content varies.** Used by `import-context`, `setup-context`, and scored by `status`.

---

## ORG-LEVEL TEMPLATE

```markdown
# [Company] — Organization Context

## tldr;
- **What**: One line — what the company does and its business model.
- **Who**: One line — primary customer segments and who uses Mixpanel internally.
- **How we measure success**: One line — the Mixpanel-trackable metric that best reflects success, plus any true north star that lives outside Mixpanel.

## Business
[2–4 sentences: product, business model, how the company makes money. Durable facts only.]

## North Star & Key Metrics
- **North star (in Mixpanel)**: [the Mixpanel-trackable metric that best reflects success + why]
- **Supporting metrics (in Mixpanel)**: [list]
- **True north star outside Mixpanel**: [e.g. revenue/NRR/GMV in another tool, + closest Mixpanel proxy — or "none, north star is trackable here"]
- **Definition of a qualified/active user**: [the exact rule the agent should apply]

## Customer Segments
[Named segments and what distinguishes them.]

## Internal Vocabulary & Acronyms
[Term — meaning. Anything the agent would otherwise misread.]

## Open Questions
[Anything not yet known, phrased as questions. Never fabricate.]
```

---

## PROJECT-LEVEL TEMPLATE

```markdown
# [Project] — Project Context

## tldr;
- **What**: One line — what this project tracks and for which product/surface.
- **Where**: One line — where data comes from (SDK, server, warehouse) and key integrations.
- **Who**: One line — who has authority over this project's schema and reports.
- **How**: One line — how analysis is done here (custom entities, conventions).
- **Why**: One line — the business decisions this project's analysis feeds.

## Domain & Vocabulary
[What the product is, what the events represent, who the tracked end-user is.]

## Event Taxonomy & Naming Conventions
[How events/properties are named and organized. Casing, prefixes, the canonical
patterns the agent should follow when referring to or creating entities.]

## Authority & Governance
[Who owns the schema and canonical reports. Whose conventions to emulate. When
the agent should defer to a human instead of creating new entities. This section
prevents the agent from copying a non-authoritative user's chaotic style.]

## Key Dashboards & Reports
[Named canonical surfaces and what each is for.]

## Definition of Active/Qualified User (this project)
[If it differs from org level.]

## Schema Snapshot
<!-- VOLATILE — captured [TIMESTAMP]. Re-verify via a schema query if this looks stale. -->
```
Top events: [list]
Key properties: [list]
Integrations in use: [list]
Timezone: [tz]
```

## Open Questions
[Anything not grounded in answers, import, or schema, phrased as questions.]
```

---

## Rules

- `tldr;` H3s are 1–3 sentences each. Terse. Point to deeper sections, don't duplicate.
- Schema-derived facts live **only** in Schema Snapshot, fenced and timestamped.
- No quantity-in-prose ("project has 26 users") — goes stale, is bloat.
- Hedging language not allowed in the body. Uncertainty → Open Questions.
- Imported content is mapped here section-by-section; it never enters raw.
