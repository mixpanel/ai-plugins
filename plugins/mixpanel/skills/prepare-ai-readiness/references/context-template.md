# Context Template

Fixed section structure for generated context. The project-level template follows the what/where/who/how/why framework used by Mixpanel's native context generation (the in-product "Generate with AI" feature) at the time of writing — verify alignment against current Mixpanel docs. The org-level template uses the subset of that framework that applies at org scope (what / who / how-we-measure-success), plus default-project routing. Whatever the native feature does today, the Org-Level and Project-Level Templates below are canonical for this skill — see `SKILL.md`'s "Structure is fixed; source, content, and target are flexible" constraint. Used by `import-context`, `setup-context`, and scored by `status`.

## Contents
- Org-Level Template
- Project-Level Template
- Worked Example (Excerpt)
- Rules

---

## Org-Level Template

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
- **Definition of Active/Qualified User**: [the exact rule the agent should apply]

## Customer Segments
[Named segments and what distinguishes them.]

## Default Project & Routing
[Which project the agent should default to, and which project answers which kind
of question. Name any projects the agent should avoid (test, staging, sandbox).]

## Internal Vocabulary & Acronyms
[Term — meaning. Anything the agent would otherwise misread.]

## Open Questions
[Anything not yet known, phrased as questions. Never fabricate.]
```

---

## Project-Level Template

````markdown
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
````

---

## Worked Example (Excerpt)

The bracketed placeholders in the Org-Level and Project-Level Templates are fill instructions, not output. A completed section is grounded and terse, with no placeholders — for calibration:

````markdown
## Business
Acme runs a B2B expense-management SaaS; revenue is per-seat subscription plus
interchange on the Acme corporate card. Finance and ops teams are the buyers.

## North Star & Key Metrics
- **North star (in Mixpanel)**: weekly active approvers — an approver who actions ≥1 expense in a rolling 7-day window; best in-product signal that the workflow is adopted.
- **True north star outside Mixpanel**: net revenue retention (lives in the billing system); closest Mixpanel proxy is seat activation rate.
````

And a filled project-level Schema Snapshot — the volatile-quarantine convention rendered correctly (fenced, timestamped, counts nowhere else):

````markdown
## Schema Snapshot
<!-- VOLATILE — captured 2025-07-04T09:12:00Z. Re-verify via a schema query if this looks stale. -->
```
Top events: Expense Submitted, Expense Approved, Report Exported
Key properties: team_id, expense_category, approver_role
Integrations in use: Segment (server-side), Snowflake import
Timezone: America/New_York
```
````

---

## Rules

- `tldr;` bullets are a single short line each — one sentence, two short clauses at most. Terse. Point to deeper sections, don't duplicate.
- Schema-derived facts follow `SKILL.md`'s "Quarantine volatile facts" rule — see the fenced, timestamped Schema Snapshot section.
- No quantity-in-prose — meaning no raw data counts or volumes ("project has 26 users", "1.2M events/day"). Metric-definition thresholds (a WAU window, "actions ≥1 expense") are part of a definition, not a data count, and are fine. At project level, data counts live only in the fenced Schema Snapshot; org-level context carries none. This is the canonical home for the rule `import-mapping.md`'s "What to drop" raw-numbers item points back to.
- Grounding and uncertainty handling follow `SKILL.md`'s "Ground everything" rule; imported content is mapped section-by-section per its "Imported content is mapped, never passed through raw" constraint.
