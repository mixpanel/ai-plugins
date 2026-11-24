---
name: weekly-kpi-digest
description: >
  Builds a weekly KPI digest from a Mixpanel dashboard: reads the dashboard's
  reports, compares the latest full week to the prior week, and writes a short
  summary of headline numbers, notable movers, and items to watch. Use when
  the user wants a weekly summary, KPI recap, or status update based on a
  dashboard, or pastes a dashboard link and asks for a digest. Trigger
  phrases: "weekly KPI digest", "summarize this dashboard for the week",
  "weekly metrics update", "write up this week's numbers", "KPI recap for the
  team". Do NOT use for explaining a single chart (use analyze-report),
  investigating why a metric moved (use monitor-metrics), or building or
  cleaning up dashboards (use create-dashboard or manage-boards). Requires a
  Mixpanel engine — run /mixpanel:install if not set up.
license: Apache-2.0
metadata:
  engine: required
---

# Weekly KPI Digest

> **Engine required** — resolve an engine per [`ENGINE.md`](../../ENGINE.md): one named in the conversation or loaded instructions is mandatory (not set up → offer `/mixpanel:install` for it); otherwise use the Mixpanel MCP server, or offer `/mixpanel:install` if it's unavailable.

Turn a Mixpanel dashboard into a short weekly KPI digest. The skill reads the dashboard's reports, compares the last complete week to the prior week, and writes a summary with headline numbers, notable movers, and items to watch. It uses the dashboard's own report definitions, so the numbers match what the team already sees.

The result is sized to paste into Slack or email. It describes what changed, not why. Root-cause questions and single-chart deep dives are handed off to other skills.

## When to use

Use this skill when the user names or links a dashboard and wants a weekly summary, KPI recap, or status update built from it.

Hand off other requests:

- Explaining a single chart: use `analyze-report`.
- Finding out why a metric moved: use `monitor-metrics`.
- Building or cleaning up dashboards: use `create-dashboard` or `manage-boards`.

If the user asks for a weekly summary but names no dashboard, ask which dashboard to use before starting.

## Step 1: Identify the dashboard

Find the dashboard the user means. It may arrive as a pasted URL, a dashboard name, or a rough description to search by name.

- **URL:** open that dashboard directly and take the project from the link.
- **Name or description:** search the dashboards by name. If the project isn't clear from the conversation, confirm it with the user before searching further.

Once found, confirm the project and the dashboard title in one line, for example "Using the Growth dashboard in the Acme Web project."

If several dashboards match, list the top few by title and ask which one to use. Do not guess.

If nothing is found, or access to the project or dashboard fails, say so plainly and stop. Do not substitute a different dashboard or build the digest from memory.

## Step 2: Pick the KPI reports

List the reports on the dashboard. Each one is a card with a type and a title.

Keep the cards that report a metric: insights, funnels, retention, and flows reports that track a number the team watches. Skip text cards, images, section headers, and other decorative content.

Tell the user what you included and what you skipped, in a line or two. For example: "Included 8 reports. Skipped 2 text cards and 1 image."

If the dashboard has many reports, name the ones you included so the user can see the scope. If a report's purpose is unclear, include it and let the title speak for itself rather than dropping it silently.

If the dashboard has no metric reports, say so and stop.

## Step 3: Fix the comparison window

Compare the last complete week against the prior week. Never include the current partial week.

Use the project's timezone and week start day. If the project's settings don't make these clear, check them before choosing dates rather than assuming Monday or UTC.

Work out both windows from today's date:

- **This week:** the most recent full week that has already ended.
- **Last week:** the seven days immediately before it.

Write the exact start and end dates of both windows, for example "Mar 3 to Mar 9 vs Feb 24 to Mar 2". These dates go in the digest.

If the user asks for a different window, use it and state it the same way.

## Step 4: Pull current and prior values

Run each KPI report you picked in Step 2 twice: once for this week's window and once for last week's window from Step 3. Use the dashboard's own report definition as it is: the same events, filters, breakdowns, and metric settings. Change only the date range. Don't add filters, swap events, or adjust the calculation, so the numbers match what the team sees on the dashboard.

Record both values for every KPI. For reports with breakdowns, record the total, and keep the top breakdown values only if they are needed for a notable mover.

If a report fails or returns nothing, note which one and why, then continue with the rest. Never invent, estimate, or fill in a number. Show a gap as "no data" in the digest.

## Step 5: Flag notable movers

Compare each KPI's change to how much that metric normally moves from week to week. A 5% swing is noise for a volatile metric and a real signal for a stable one. Don't use a fixed percentage cutoff.

To judge normal variation, run the same report for several earlier weeks, using the same definition, and see how far the metric usually moves. If that isn't possible, use the shape of the trend on the dashboard and say the judgment is rougher.

Pick the 2-4 largest or most unusual changes, up and down. Skip the rest, since they stay in the table.

Mark a mover as low confidence when:

- The data is partial, for example a late-arriving event or a report with a gap.
- The sample is small, so a few users could swing the result.

Describe only what moved and by how much, for example "Signups fell 18% to 1,240, well outside the usual weekly range." Do not guess causes. Leave why for the follow-up in Step 7.

## Step 6: Write the digest

Write the digest in this order, with no extra sections:

1. **Headline:** one line on the overall picture, for example which KPIs rose, which fell, and whether the week was mostly steady.
2. **KPI table:** columns `Metric`, `This week`, `Last week`, `Change`. Include every KPI from Step 4, one row each. Show change as a percentage, or as percentage points for rates. Use "no data" for any report that failed or returned nothing.
3. **Notable movers:** the 2-4 movers from Step 5, one line each, with the size of the move. Add "(low confidence)" where it applies. Describe the movement only, with no causes.
4. **Items to watch:** short bullets for low-confidence numbers, reports that failed, and metrics that moved in the same direction for several weeks. Write "None" if there is nothing to flag. Don't add items the data doesn't support.
5. **Footer:** the exact comparison dates from Step 3 and the dashboard link.

Keep the whole digest short enough to paste into Slack or email. Use plain text and simple tables, with no long paragraphs.

### Example

The numbers below are made-up placeholders that show the format.

```
Weekly KPI Digest: Growth dashboard

Headline: Signups fell sharply while activation and revenue held steady.

| Metric | This week | Last week | Change |
|---|---|---|---|
| Signups | 1,240 | 1,512 | -18% |
| Activation rate | 41.0% | 40.2% | +0.8 pts |
| Weekly active users | 18,300 | 18,050 | +1.4% |
| Revenue | $52,400 | $51,900 | +1.0% |
| Trial-to-paid | no data | 6.1% | n/a |

Notable movers
- Signups down 18%, well outside the usual weekly range.
- Activation rate up 0.8 pts, the largest gain in four weeks (low confidence: small sample).

Items to watch
- Trial-to-paid report returned no data this week.
- Weekly active users have risen for three weeks in a row.

Mar 3 to Mar 9 vs Feb 24 to Mar 2
Dashboard: <dashboard link>
```

## Step 7: Offer follow-ups

After sending the digest, offer next steps in one or two lines. Do not run them unless the user says yes.

- A root-cause check on a specific mover, using `monitor-metrics`. Name the mover, for example "I can look into why signups fell 18%."
- A closer read of one chart, using `analyze-report`.

Offer only what fits the digest. If nothing moved much, offer the chart read alone.

## Rules

- Do not guess causes. Describe what moved and by how much, and leave why to a follow-up.
- Never invent, estimate, or fill in a number. Every figure comes from a report run.
- Say when a report fails or returns nothing. Name it in the table and under items to watch.
- Use the dashboard's own report definitions. Change only the date range.
- Always state the exact comparison dates for both weeks.
- Never include the current partial week.
- Keep the digest short enough to paste into Slack or email.
- Run follow-ups only if the user asks.
