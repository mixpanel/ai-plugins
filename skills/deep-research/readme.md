# Deep Research — Maintainer Notes

This skill turns a "why did this happen?" question into a structured Mixpanel investigation: scope the project / events / properties, validate the data exists, agree a plan with the user, then run a query → interpret → hypothesise loop until the question is answered with evidence.

## Layout

- `SKILL.md` — entry point and workflow.
- `references/` — long-form reference material the skill links to via progressive disclosure (currently empty).
- `assets/` — reusable templates or prompts the skill references (currently empty).

## Design notes

- **Scope-first is non-negotiable.** Wrong project / events / properties produces a confidently wrong answer. The skill blocks on confirmation before running anything beyond exploratory volume checks.
- **Plan-then-run.** The user sees the plan as a compact block and explicitly says "yes" before the investigation runs. This prevents wasted queries and gives the user a chance to redirect.
- **Loop, don't script.** The investigation phase is intentionally a loop, not a fixed sequence — every dataset is different and rigid templates produce shallow answers.

## Open questions

- Should the skill optionally pull in non-Mixpanel context (deploys, campaigns, incidents) when correlating timing?
- What's the right output format for the final answer — inline summary, DOCX brief, or a Mixpanel dashboard?
- Do we need a "stop after N queries" guardrail to avoid runaway investigations?

Update this file as decisions are made so future contributors understand the architecture.
