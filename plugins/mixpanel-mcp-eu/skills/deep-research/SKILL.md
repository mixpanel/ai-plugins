---
name: deep-research
description: Conducts a structured metric investigation in Mixpanel. Use when the user asks why a metric changed, what's driving a trend, requests a "deep dive" or "root cause," or wants to understand a phenomenon in their data. Walks through project / event / property scoping, plan confirmation, and an iterative query → interpret → hypothesise loop.
license: Apache-2.0
---

# Deep Research / Metric Investigation

This skill is a structured investigation, not a one-shot answer.

## Requirements

- Mixpanel MCP server (bundled with the plugin).

---

## When to use this skill

Trigger when the user wants to understand *why* something happened in their data. Common phrasings:

- "Why did [metric] drop / spike / change?"
- "Can you do a deep dive on [X]?"
- "What's driving [trend]?"
- "Root cause this for me."
- "Help me understand what happened with [feature / cohort / segment]."

Do **not** trigger for one-off lookups ("what was DAU yesterday?"). Those are direct queries, not investigations.

---

## Workflow

### Phase 1 — Scope

Do not run analysis queries until scope is confirmed.

Using the MCP tools, do your best to find the following information from the user's question and context. If anything is missing or ambiguous, ask clarifying questions before proceeding.

1. **Project.** Which Mixpanel project? If the user has access to several, ask.
2. **Events.** Which events relate to the question?
3. **Properties.** Which properties are relevant to break down by? (e.g. platform, utm_source, plan_tier)

State your assumptions and ask the user to confirm before continuing. The final answer depends on this being right.

### Phase 2 — Validate and plan

Run small exploratory queries to confirm data exists in the analysis window. Be resilient — try different approaches if your first attempts don't work.
If volume is zero, partial, or anomalously low, surface that to the user before going further.

Then present a compact plan:

```
*Investigation Plan*

• *Project:* `project name`
• *Events:* `event_a`, `event_b`, `event_c`
• *Properties:* `platform`, `utm_source`, `plan_tier`

*Initial Queries:*
• Trend of event_a over 30 days to establish baseline
• Breakdown by platform to isolate where the change happened
• ...

Say *yes* to continue the analysis.
```

Wait for explicit confirmation before running the full investigation. If the user revises the plan, restate it and re-confirm before continuing.

### Phase 3 — Investigate

Enter the research loop:

1. **Run** one or more queries from the plan.
2. **Read and interpret** the results — what stands out, what doesn't?
3. **Form a hypothesis.** If the data clearly answers the question, prepare to summarise. If not, return to step 1 with a sharper query.

Continue until you can answer the original question with evidence, or you can clearly articulate what data is missing. Stay creative — every dataset is different, so let the data shape the next query rather than following a fixed sequence.

---

## Guidelines

- **Start broad, then narrow.** Establish the overall trend first; each subsequent query should be informed by the previous one.
- **Break down by dimensions where you'd expect variation given the question.** Don't slice by every property — pick the ones most likely to show a delta.
- **Correlate timing.** If a metric shifted on a specific date, ask what else changed: a deploy, a campaign, a policy, an outage.

---

## Output

When the investigation concludes, present:

1. The **answer** to the original question, in one or two sentences.
2. The **evidence** — create a dashboard using the `create-dashboard` skill to back your findings with live data.
3. **Caveats** — anything the data doesn't tell you, alternative explanations you can't rule out, and follow-up queries the user might want to run.
