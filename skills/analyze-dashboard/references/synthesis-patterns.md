# Synthesis patterns — reference

Use this reference when constructing the dashboard-level narrative in
SKILL.md Step 4. Synthesis is the hardest part of dashboard analysis
and the part that distinguishes a useful read from a chart-by-chart
recap.

---

## The core principle

The customer reading the synthesis has 30 seconds. If they walk away
remembering one thing, it should be the most important thing on the
dashboard. Everything else can wait for the appendix.

That means: **don't tell them what each chart shows. Tell them what
the dashboard, taken together, is saying.**

---

## Step 1 — Bucket every chart's read into one of four states

After reading each chart (via the per-type references from
`analyze-chart/references/`), classify it:

- **Notable up** — the chart shows a meaningful positive movement
  (>15% increase, recovery from prior dip, new high)
- **Notable down** — meaningful negative movement (>15% decrease,
  step-change drop, new low)
- **Stable** — flat or within typical noise range
- **Broken / empty / stale** — health issue, can't inform the
  narrative

The threshold isn't strict — use judgment. A 5% drop in a metric the
customer's business is built on is notable. A 30% wiggle in a
high-noise vanity metric is not.

---

## Step 2 — Look for cross-chart patterns

The synthesis's value comes from connecting movements across charts.
Five common patterns to look for:

### Pattern A — Concentrated movement

Multiple charts move in the same direction, telling the same story.
Example: signups up, DAU up, key event volume up — all driven by an
acquisition spike.

> Synthesis: *"Acquisition spiked this week — signups up 22%, DAU up
> 14%, key engagement events up 18%. The dashboard reflects one
> driver: more new users."*

This is the strongest synthesis shape. One driver, multiple charts.

### Pattern B — Contradiction

Charts that should move together don't. Example: signups up, but
activation rate down. The dashboard implies a problem the headline
metrics hide.

> Synthesis: *"Signups are up 18% but activation is flat — the
> additional users aren't converting at the same rate. Volume is
> hiding a quality drop."*

This is the most valuable synthesis shape because the customer
probably hadn't noticed the contradiction.

### Pattern C — Isolated movement

One chart moved, the rest didn't. The synthesis names the moving
chart and explicitly says nothing else changed.

> Synthesis: *"Most of the dashboard is steady — DAU, retention, and
> conversion are flat. The exception is checkout funnel conversion,
> which dropped 8% over the last 10 days."*

The "everything else is flat" is part of the finding. It tells the
customer the issue is contained.

### Pattern D — Compound issue

A movement on one chart is amplified or caused by a movement on
another. Example: DAU dropped, AND retention also dropped — the DAU
problem is partly because returning users aren't returning.

> Synthesis: *"DAU is down 12% and retention dipped at the same time —
> the DAU drop is partly retention-driven, not just acquisition. Two
> overlapping issues."*

Compound findings are harder to spot but more valuable to surface.

### Pattern E — Genuinely flat

Nothing notable. Don't manufacture drama.

> Synthesis: *"The dashboard is steady — nothing material moved this
> period. All charts within typical ranges."*

Saying "nothing happened" is a valid finding when it's true.

---

## Step 3 — Write the narrative

The synthesis is 2–4 sentences. Structure:

1. **Lead sentence** — the one thing the customer should walk away
   with. State the headline movement and its scale.
2. **Context sentence(s)** — what other charts do or don't reinforce
   this. Connect related findings.
3. **Implication sentence (optional)** — only if the implication is
   sharp and short. Otherwise leave it out and let the customer draw
   the conclusion.

Avoid:
- Listing chart titles in the synthesis ("The DAU chart shows... The
  funnel chart shows...") — that's chart-by-chart recap, not
  synthesis.
- Hedging ("It seems like maybe..."). Either there's a finding or
  there isn't.
- Numbers without context. "DAU is at 142K" is meaningless without
  movement direction or magnitude.

Good synthesis:
> *"Volume is the headline this week — signups, DAU, and key events
> all up double digits, driven by the campaign launch on Tuesday.
> Retention and conversion held steady through the spike, which
> suggests the new users are behaving like the existing base."*

Bad synthesis (chart-by-chart):
> *"The DAU chart shows growth. The signup chart is up. The key event
> chart is up. The retention chart is flat. The conversion chart is
> flat."*

---

## Step 4 — Build the "Worth your attention" list

After the synthesis, surface the items the customer should action or
investigate. Bar for inclusion:

- A movement >15% in either direction
- A cross-chart contradiction even if individual movements are <15%
- A step-change anomaly (single point that breaks the pattern)
- A health issue (broken, empty, stale chart)
- Cohort divergence inside a single chart (one segment diverging from
  the rest)

Skip:
- Stable findings restated ("DAU was flat" — that's the appendix)
- Methodology notes ("this uses unique users" — only mention if it
  affects the finding)
- General product observations ("the funnel could be improved" —
  the customer didn't ask for advice)

Each bullet is one line. Lead with the chart name or metric, then the
finding.

```
- Checkout funnel: 8% conversion drop over the last 10 days, isolated
  to mobile platform
- DAU: step-change on Mar 18, value moved from ~150K to ~135K and
  held — suggests a single trigger event
- Errors dashboard: ❌ broken chart — 'API Error' event no longer
  exists in project
```

---

## Common synthesis pitfalls

**Treating the dashboard as a list of independent metrics**
Every chart on a dashboard exists in relation to the others. If you
analyze them independently, you produce a recap, not a synthesis.

**Burying the lede in a roundup**
"Several things happened: A is up, B is down, C is flat, D is up
slightly..." Pick the most important one and lead with it.

**Equal weight to flat charts and moved charts**
The synthesis should weight by movement size, not chart count. One
chart with a 30% drop deserves more synthesis space than five flat
charts combined.

**Speculating across charts without evidence**
"DAU dropped, so users must be unhappy with the new feature" —
hallucinated cause. The synthesis can flag that DAU and feature usage
both dropped, but causal claims are out of scope. That's
`mxp-metric-diagnosis` territory.

**Forcing a narrative when there isn't one**
Sometimes a dashboard genuinely has 7 unrelated movements with no
common thread. In that case the synthesis acknowledges this:
*"Several independent movements this period — no single driver."*
Then list them. Honest beats over-synthesized.
