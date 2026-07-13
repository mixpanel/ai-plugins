# Command: status

The unified AI-readiness readout. Scores both layers in one view — business context completeness *and* Lexicon coverage — and tells the user exactly what's missing and which command fixes it. This is the re-engagement hook: run it on any account to see where it stands and what to do next. It is read-only.

**Session reads:** `org_id`, `org_name`, `target_level`, `project_id`, `project_name`, `existing_context`, `lexicon_score`
**Session writes:** `existing_context`, `lexicon_score` (refreshes both)

---

## Step 1 — Business-context layer

For the org and (if a project is in scope) the project:

- Read current context if not already in `existing_context`.
- Score completeness against `references/context-template.md`: which required sections are present and non-empty. Weight the high-value sections (north star, qualified-user definition, authority & governance) more heavily — a doc with vocabulary but no authority section is weaker than the raw section count suggests.
- Flag staleness: if a Schema Snapshot section exists, compare its timestamp to now and warn if old.

## Step 2 — Data layer (Lexicon)

If a project is in scope and `manage-lexicon` is available, run its `score-lexicon` (or reuse `lexicon_score` if fresh this session) to get event-description, property-description, and tag coverage. If `manage-lexicon` is unavailable, mark the data layer "not measured" rather than guessing.

## Step 3 — Present one readout

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  AI Readiness — [Project Name]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  BUSINESS CONTEXT
    Org level        ●●●●○  present, missing: customer segments
    Project level    ●●○○○  thin — no authority section, no qualified-user def

  DATA (LEXICON)
    Event descriptions     45%
    Property descriptions   30%
    Events tagged           12%

  TOP GAPS (most impact first)
    1. Project authority & governance  → import-context / setup-context
    2. Property descriptions (30%)     → enrich-data
    3. Event tags (12%)                → enrich-data
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Order gaps by impact on agent quality, not by raw percentage: a missing authority section or qualified-user definition hurts the agent more than a few undescribed low-volume events. Each gap names the command that fixes it.

## Follow-on

Offer the single highest-impact next step as a direct handoff (e.g. "Start with **import-context** for the project — want me to go?"). Don't dump the whole menu; recommend the one move.
