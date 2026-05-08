# analyze-chart

Read and explain a Mixpanel chart — what it shows, what's notable, and what's worth digging into. Lean by default: surfaces the shape and flags anomalies, but stops short of root-cause analysis. Hands off "why" questions to `mxp-metric-diagnosis`.

## What it does

Takes an existing Mixpanel chart (URL, ID, NL search, or freshly built) and:

1. Locates the chart and pulls its metadata
2. Re-runs the query for fresh data
3. Reads the chart's shape — current value, trend, anomalies, breakdown distribution
4. Returns a one-screen summary: what it shows, the shape, what's worth noting, and an offer to dig deeper

## Who it's for

End users who want a fast read on what a chart is saying — without manually scanning the chart and forming their own takeaway. Customer-facing in their own Claude environment.

## Requirements

- Mixpanel MCP connected
- User has read access to the chart being analyzed

## Install

1. Download `analyze-chart.zip`
2. Unzip
3. Drop the `analyze-chart/` folder into your skills directory

## Trigger phrases

- "what does this chart show?"
- "explain this report"
- "summarize this for me"
- "anything weird in this chart?"
- "walk me through this report"
- "what's the takeaway from this?"

Also activates when the user pastes a Mixpanel chart URL and asks anything about it.

## Output shape

The output is always the same shape, so users learn to scan it fast:

```
**What this shows**
[Chart subject, time window, current value]

**The shape**
[Trend direction, magnitude, key inflection points]

**Worth noting**
[Bullet list of flagged items — only if there are any]

**Want to dig in?**
[Offer to escalate to mxp-metric-diagnosis or modify the chart]
```

## The "lean by default" rule

The skill surfaces what's there and stops. It does NOT:

- Speculate on causes ("might be because of...")
- Recommend fixes
- Try to root-cause a movement inline

If the user's follow-up is "why did this drop?" — the skill explicitly hands off:

> *"That's a root-cause question — `mxp-metric-diagnosis` is built for that. Want me to run it on this metric?"*

This bound is intentional. Without it, an "explain this chart" ask can balloon into a 10-tool-call investigation.

## What the skill won't do

- Build new charts (use `create-chart`)
- Review whole dashboards (use `analyze-dashboard`)
- Run full multi-branch RCA (use `mxp-metric-diagnosis`)

## File structure

```
analyze-chart/
├── SKILL.md                       # Workflow router
└── references/
    ├── read-insights.md           # Reading patterns for Insights charts
    ├── read-funnels.md            # Reading patterns for Funnels
    ├── read-retention.md          # Reading patterns for Retention
    └── read-flows.md              # Reading patterns for Flows
```

These are *reading* references (vs. `create-chart`'s *build* references). Same chart types, different lens — what to flag vs. how to construct.

## Customizing for your team

- **Adjust the "notable movement" threshold** — currently 15% change. Change in `references/read-*.md` files.
- **Add team-specific patterns to flag** — e.g., if your team always wants flagged when MAU drops below a specific number, add a named pattern to `read-insights.md`.
- **Tighten or loosen the escalation rule** — currently any "why" question routes to `mxp-metric-diagnosis`. Edit Step 4's escalation section in `SKILL.md` if you want lighter inline RCA.

## Known limitations

- Mixpanel chart URL formats vary. URL parsing is best-effort; if it fails the skill asks for the report ID directly.
- The skill re-runs the query each time — chart state is not cached. This adds a few seconds but ensures fresh data.
- The "lean" bound means deep analysis is out of scope here. That's a feature for a customer-facing skill, but if your team wants integrated RCA, this is the wrong skill — use `mxp-metric-diagnosis`.

## Pairs well with

- `create-chart` — chains cleanly: build a chart, then explain it
- `analyze-dashboard` — same reading patterns, scaled across a whole dashboard
- `mxp-metric-diagnosis` — the hand-off destination for "why" questions

## Version

v1 — first draft. Test with real customer chart asks before considering production-ready.
