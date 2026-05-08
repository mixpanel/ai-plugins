# Layout patterns — reference

Use this reference when planning the dashboard layout in SKILL.md
Step 5. Layout decisions depend on **who's reading** and **what the
dashboard is for**. The default lifecycle sectioning works for most
asks, but several common dashboard types need a different shape.

---

## Lifecycle sectioning (default for general-purpose dashboards)

The default 5-section layout — Overview → Acquisition → Engagement →
Retention → Quality. This works for:

- Weekly product reviews
- Exec dashboards covering the full product
- Post-launch tracking (with renamed sections)
- General health monitoring

**When it works**: the dashboard covers a *product or experience
end-to-end*. The user lifecycle is the natural narrative.

**When it doesn't**: when the dashboard is about a single moment in the
funnel (only acquisition, only retention, only one feature).

---

## Funnel-focused dashboard

For dashboards built around a single conversion flow (signup funnel,
checkout funnel, onboarding funnel), use this layout instead:

1. **Top-line conversion** — the headline funnel chart, conversion
   rate over time
2. **Per-step volume** — Insights charts of each step's volume
3. **Per-step drop-off causes** — breakdowns of users who drop off at
   each step
4. **Cohort comparisons** — funnel conversion segmented by acquisition
   source, plan tier, etc.

**Trigger to use this layout**: the customer's brief mentions one
specific funnel and most charts are about that funnel.

---

## Feature-focused dashboard

For dashboards tracking a single feature's adoption and impact:

1. **Adoption** — % of users who tried the feature, trend over time
2. **Engagement** — frequency of use among adopters
3. **Retention impact** — retention curves for adopters vs.
   non-adopters
4. **Downstream effect** — does feature use correlate with the key
   business metric

**Trigger to use this layout**: the customer's brief names a specific
feature.

---

## Executive / leadership dashboard

For VP/Director audiences, the rules change:

- **Cap at 6 charts** even if the soft cap is 8
- **No breakdowns** in top-line charts — pure totals and trends
- **Comparison is key** — every chart should show vs. prior period
- **One sentence per chart** — title should be self-explanatory ("DAU
  is up 12% WoW" not "DAU")
- **Section order**: business outcome metrics first, leading indicators
  second, operational health last

**Trigger to use this shape**: the brief mentions VP, Director, CEO,
exec review, board, or leadership.

---

## Operational / analyst dashboard

For analysts or product teams who use the dashboard daily:

- **Soft cap can stretch to 12** — analysts skim more
- **Breakdowns are expected** — most charts have at least one
  breakdown
- **Filters at the dashboard level** if Mixpanel supports them in this
  project
- **Section order**: input metrics first (acquisition, traffic), then
  process metrics (events, conversions), then output metrics
  (revenue, retention)

**Trigger**: brief mentions analysts, product team, growth team, or
"daily review."

---

## Section naming conventions

When the customer's brief is domain-specific, rename default sections
to match. Examples:

| Default | Renamed for... |
|---|---|
| Overview | Launch Snapshot, Weekly Pulse, Health Check |
| Acquisition | Sign-ups, New Users, Top of Funnel |
| Engagement | Feature Use, Activity, Daily Behavior |
| Retention | Stickiness, Comeback Rate, Cohort Health |
| Quality | Errors, Infra, Reliability, Crashes |

The principle: section names should make sense to the customer's team
without explanation. If the dashboard is for a marketing team, "Top of
Funnel" reads better than "Acquisition." Read `Get-Business-Context`
to find the customer's vocabulary.

---

## When to skip sections entirely

Skip sectioning if any of the following are true:

- Dashboard has 4 or fewer charts (sections add overhead, not clarity)
- All charts share one section (sectioning would create one section
  with everything in it — pointless)
- The customer explicitly asks for a flat layout

---

## Common pitfalls

**Forcing lifecycle sections onto a non-lifecycle dashboard**
A dashboard called "Onboarding Drop-off Analysis" doesn't need an
Acquisition section — the customer is past acquisition. Use the
funnel-focused layout instead.

**Skipping sectioning to "save space"**
A dashboard with 8 unsectioned charts looks faster to build but is
slower to read. The cost of two seconds adding sections is recouped
every time someone scans the dashboard.

**Section count > 5**
More than 5 sections is a sign the dashboard is doing too much.
Surface this: *"This dashboard spans 6 distinct areas — consider
splitting into two dashboards?"*

**Empty sections**
If a planned section has zero charts that fit, drop it. Don't ship a
dashboard with a "Retention" header followed by no charts.
