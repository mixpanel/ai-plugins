---
name: create-dashboard
description: Creates a well-designed Mixpanel dashboard. Use when the user asks you to build, create, or design a dashboard, or when you need to present findings from an investigation as a live dashboard. Handles layout, text cards, report validation, and narrative structure.
license: Apache-2.0
---

# Dashboard Creation

Your job is to design a coherent analytical narrative, not just drop reports into rows.

## Requirements

- Mixpanel MCP server connected and authenticated.

If missing, stop and tell the user what's needed before continuing.

---

## Workflow

### Phase 1 — Scope

Infer the theme from the user's request and surrounding context. Pick a sensible structure yourself. Ask clarifying questions if the request is fundamentally ambiguous (e.g. no project context at all).

1. **Project.** Which Mixpanel project? If ambiguous, ask.
2. **Theme.** What is the dashboard about? Derive scope from the request.

### Phase 2 — Discover and validate

This is the most important phase. Empty or failing reports are the #1 complaint.

1. Resolve event and property names using the schema tools (always get query schemas first before building queries).
2. Run small probe queries to confirm the data exists and returns meaningful results.
3. A query that runs successfully but returns zero rows is still not useful — treat it like a missing event.

### Phase 3 — Plan layout

Before building, decide:

- **Be space-efficient.** Fewer rows with more reports each makes the dashboard faster to scan. Don't spread metrics across many rows when they fit naturally together.
- **Row hierarchy.** Headline metrics on top, supporting breakdowns below. The dashboard reads top-to-bottom like a narrative.
- **Row count.** Aim for **4-8 rows**. Don't add every available breakdown, be smart.
- **Items per row.** Use **2–4 reports per row**. A single report alone in a row wastes space — pair it with related metrics or a text card. **4 cards per row** (text + reports combined) is the practical maximum.
- **One conceptual focus per row.** Group related reports together; never mix unrelated metrics in the same row just to fill space.
- **Time filter.** Decide intentionally: Dashboard global time filter overrides all the reports. Don't use it when you want each report to have its own default range.
- **Text cards.** Identify where they add real value (see rules below).

### Phase 4 — Build queries

1. Validate every query returns real, non-empty data before adding it to the dashboard.
2. Only use `skip_results: true` once you have already confirmed a query produces meaningful output.
3. Never reuse a query template without knowing it produces valid results.

### Phase 5 — Compose the dashboard

- **Title:** `<distinguishing emoji> <theme>` — the emoji helps users tell multiple dashboards apart at a glance.
- **First row:** Intro text card setting context (what this dashboard covers, scope, audience, caveats).
- **Subsequent rows:** 1-4 reports per row, with an optional leading text card.
- **Report names:** Every report needs a descriptive name a viewer can understand without clicking into it — what the metric is, what it is broken down by, what context it covers. Avoid generic names like "Funnel" or "Trend".
- Be creative with layout. Each dashboard is different. Think about what *this* user needs and arrange for maximum clarity.

### Phase 6 — Present

Respond with a brief summary (2–3 sentences) and the dashboard URL. **Never** list individual report URLs — the dashboard already contains them.

---

## Text Cards

### When to use them

- **Set context at the top** — what this dashboard covers, scope, audience, caveats.
- **Provide guidance at the bottom** — next steps, follow-ups.
- **Explain a concerning metric** — call attention to something the user should watch.
- **Section a row** — a short text card next to the report it describes.

### Placement rules

- **At most one text card per row.**
- Place a text card next to the report it relates to, or use it as a standalone row for section headings.

### Writing style

- Use rich formatting (headings, lists, bold, inline code) to create hierarchy inside the card — that is what makes them scannable. Read dashboard schema documentation for formatting options.
- Keep them short. A text card is a sign-post, not an essay.
- Lead with the point. If the card explains a metric, state the takeaway first, then the nuance.

