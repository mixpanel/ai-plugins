# Reading Insights charts — reference

Use this reference when the chart being analyzed is an **Insights**
chart (event volume, trend over time, breakdown, ratio).

---

## What to read first

1. **Current value** — last point of the series, or total for the
   period. State it in the customer's units (events, unique users,
   conversion %).

2. **Trend direction** — is the line up, down, flat, or oscillating?
   Compare last 7 days to prior 7 days for short charts, last 30 to
   prior 30 for medium charts.

3. **Magnitude of change** — express as % change, not just direction.
   "DAU is up" is weaker than "DAU is up 12% WoW."

4. **Breakdown distribution** — if the chart has a breakdown, what's
   the top segment's share? A breakdown where one segment is 80%+ of
   volume is notable on its own (concentration risk or
   instrumentation issue).

---

## Patterns to flag

### Step-change

A single point where the line jumps or drops and stays at the new
level. Distinct from a gradual trend. Almost always indicates a
deploy, instrumentation change, or external trigger event.

> Flag as: *"Step-change on [date] — value moved from X to Y and held."*

### Spike then return

A single point sharply different, then back to normal. Usually a
campaign, batch event, or test traffic.

> Flag as: *"Single-day spike on [date], value returned to baseline
> next day. Looks like a one-off."*

### Drift (trend-level shift)

The last 30 days are running consistently above or below the prior 30,
without a single step-change point. Slower-moving than a step-change,
harder to spot at a glance.

> Flag as: *"The last 30 days run ~X% [above/below] the prior period —
> looks like a baseline shift, not a single event."*

### Going to zero

A series that drops to zero and stays there is almost never a real
business signal — it's an instrumentation break. SDK update, event
rename, deploy that broke tracking.

> Flag as: *"Series goes to zero on [date] and stays flat. This usually
> means tracking broke, not that the behavior actually stopped."*

### Cyclic pattern (weekly seasonality)

Most user-facing metrics show weekday/weekend cycles. If the chart
spans a few weeks, the cycle should be obvious. Two things to flag:
- Cycle disappears suddenly (something dampened weekend activity)
- Cycle inverts (weekends becoming higher than weekdays)

### High-cardinality breakdown explosion

If the breakdown shows hundreds of small segments, the chart is
probably misconfigured (e.g., breaking down by `user_id`). Surface
this as a chart quality issue, not a metric finding.

---

## Common reader pitfalls

**Mistaking weekend dips for drops**
If the customer is looking at a single recent low point, check if it's
a weekend. The chart isn't broken; it's Tuesday vs. Sunday.

**Treating ratios like volumes**
A conversion ratio chart can change because the numerator moved OR the
denominator moved. Always state which.

**Reading the legend wrong**
Multi-series charts: confirm which line the customer is asking about
before analyzing. "The blue one" might be a different segment from
what they think.

**Comparing different time aggregations**
A chart switching from daily to weekly granularity creates an
artificial "drop" because weekly bins are smaller in the partial last
week. Verify granularity before flagging movement.

---

## Output focus

Insights summary should answer:
- What's the current level?
- What direction is it moving?
- Is anything unusual happening?

Skip:
- Methodology ("this is unique users, not events" — only mention if
  relevant to the finding)
- Hypothesis on why ("might be because of..." — that's `mxp-metric-diagnosis`)
