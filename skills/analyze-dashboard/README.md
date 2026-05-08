# analyze-dashboard

Read a Mixpanel dashboard end-to-end and produce a synthesis-first summary — one screen of cross-chart takeaways with a per-chart appendix the user can expand. Light health flagging surfaces broken/empty/stale charts without auditing dashboard hygiene.

## What it does

Takes an existing Mixpanel dashboard (URL, ID, NL search, or freshly built) and:

1. Locates the dashboard and inventories all charts
2. Re-runs each chart's query for fresh data
3. Flags any broken, empty, or stale charts as health issues
4. Reads each chart individually, then **synthesizes** across charts
5. Outputs: synthesis (the story), worth-your-attention bullets, per-chart appendix

## Who it's for

End users who want the takeaway from a dashboard without scanning every chart themselves. Designed to answer: *"what's happening on this dashboard?"* in 30 seconds.

## Requirements

- Mixpanel MCP connected
- User has read access to the dashboard

## Install

1. Download `analyze-dashboard.zip`
2. Unzip
3. Drop the `analyze-dashboard/` folder into your skills directory

## Trigger phrases

- "review this dashboard"
- "summarize this board"
- "what's happening on this dashboard?"
- "give me the takeaway from this"
- "anything I should know about this board?"
- "what's the story on this dashboard?"

Also activates when the user pastes a Mixpanel dashboard URL and asks anything about it.

## Output shape

```
**The story**
[2–4 sentences. The cross-chart narrative — what moved, what's
notable, the one thing to walk away with.]

**Worth your attention**
[Bullets: big movements, contradictions, anomalies, health issues.
Skipped if nothing meets the bar.]

**Want to dig in?**
[Offer to run mxp-metric-diagnosis or expand the appendix.]

---

**Per-chart appendix**
[One line per chart, in dashboard order, with current value,
direction, magnitude, and any flags.]
```

The synthesis is always first. The appendix is always included but visually de-prioritized.

## Synthesis patterns

The skill looks for five common cross-chart patterns:

- **Concentrated movement** — multiple charts moving the same direction, one driver
- **Contradiction** — charts that should move together don't
- **Isolated movement** — one chart moved, the rest didn't
- **Compound issue** — overlapping causes amplifying a single metric
- **Genuinely flat** — nothing notable; the skill says so plainly

The contradiction pattern is the highest-value one — it surfaces things the user didn't notice.

## Light health flagging

The skill flags obvious issues that would mislead the reader:

- Chart returning zero data when the event/property no longer exists
- Chart with date range hardcoded to a stale period
- Chart that fails to render

It does NOT do:
- Hygiene audits
- Stale-chart cleanup
- Templating

For those, use `mixpanel-dashboard-manager`.

## What the skill won't do

- Review a single chart (use `analyze-chart`)
- Diagnose why a metric moved (use `mxp-metric-diagnosis`)
- Build dashboards (use `create-dashboard`)
- Clean up or audit dashboards (use `mixpanel-dashboard-manager`)

## File structure

```
analyze-dashboard/
├── SKILL.md                       # Workflow router
└── references/
    └── synthesis-patterns.md      # How to construct cross-chart narratives
```

The skill also reads chart-reading references from `analyze-chart` at runtime — install both for full functionality.

## Customizing for your team

- **Adjust the synthesis threshold** — currently 15% movement. Change in `references/synthesis-patterns.md`.
- **Add team-specific synthesis patterns** — e.g., if your team has standard cross-metric patterns to watch for (acquisition up + activation flat = "quality drop"), codify them as named patterns.
- **Tighten what gets flagged** — currently flags step-change anomalies, drift, contradictions. Edit `synthesis-patterns.md` if you want stricter or looser flagging.

## Known limitations

- Dashboards above ~12 charts get a one-line warning before processing. The skill still reads all of them, but the synthesis prioritizes headline movements over comprehensive coverage.
- Re-runs every chart's query, which adds latency for large dashboards. Worth it for fresh data.
- Synthesis is the hardest part to get consistently right. First-draft quality should be eval'd against real dashboards before relying on the output for exec-facing purposes.

## Pairs well with

- `analyze-chart` — chart-reading logic this skill reuses
- `mxp-metric-diagnosis` — the hand-off for "why did X move" follow-ups
- `mixpanel-dashboard-manager` — for hygiene/cleanup the skill explicitly defers
- `create-dashboard` — to build a dashboard this skill can later analyze

## Version

v1 — first draft. The synthesis quality is the hardest part to get right; eval against real dashboards before treating as production.
