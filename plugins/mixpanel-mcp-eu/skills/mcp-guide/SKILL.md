---
name: mcp-guide
description: Use this skill whenever the user asks about the Mixpanel MCP server, what it does, what it can answer, what tools are available, how to phrase questions, why to use it, or what value it provides. Trigger on phrases like "how do I use Mixpanel MCP", "what can I ask Mixpanel", "Mixpanel in Claude", "Mixpanel natural language", "connect Mixpanel", "Mixpanel through AI", "show me what Mixpanel MCP can do", or any open-ended question about Mixpanel's MCP capabilities. Also trigger when the user has just connected Mixpanel and is figuring out where to start, even if their question is vague (e.g. "what now?", "what should I try first?"). Do NOT skip this skill on the assumption a question is simple. The skill contains canonical tool names, prompt patterns, and known gotchas that are easy to get wrong from memory.
license: Apache-2.0
---

# Mixpanel MCP Guide

A hands-on course for getting real value out of the Mixpanel MCP server. It teaches by doing: one concept, one prompt, one result at a time.

═══════════════════════════════════════════════════════════════════
## HOW TO DELIVER THIS SKILL: read before responding
═══════════════════════════════════════════════════════════════════

**The one rule that overrides everything else: one concept, one prompt, then STOP.**

Each module below is split into two physically separate parts:

- A **▶ FIRST MESSAGE** block: the concept in 1-2 sentences plus a single "Try this" prompt. This is the *entire* first message for that module. Send it and stop.
- A **DEFERRED** block, walled off below a `═══` divider and broken into `→ if` branches. Never paste this block whole. Surface ONE branch at a time, and only when the user's situation calls for it (they got stuck, asked for detail, hit an error, or reported back).

If you ever find yourself about to send a module's concept, prompt, troubleshooting, *and* tool list in one message, stop. You're doing the thing this restructure exists to prevent. The deferred content is reference for you to pull from, not a script to recite.

**Start every session by presenting the path selector below.** Don't dump a module until the user picks one. Default a brand-new user to the Starter path, beginning with Module 0.

**Respect the tiers.** Each module is tagged `starter`, `advanced`, or `reference`. Don't push a user toward an advanced module until they've cleared the starter checkpoints. If someone new asks about chaining or governance, point them at the basics first and let them opt up.

### Path selector (present this first)

**Starter path (get value fast):**
- **Module 0:** How to think about MCP and how to prompt it
- **Module 1:** Orient your project's data (always start here)
- **Module 2:** Run analysis (funnels, retention, trends)
- **Module 4:** Build a dashboard so the insight persists

**Advanced path (deeper investigation and governance):**
- **Module 3:** Investigate individual users and session replays
- **Module 5:** Govern your schema and data quality
- **Module 6:** Chain Mixpanel with other tools

**Reference (open anytime):**
- **Module 7:** Prompting principles and known limits

Ask where they'd like to start. New to MCP? Start at Module 0.

---

## Module 0: How to Think About MCP and How to Prompt It
<!-- tier: starter · the foundation for every other module -->

### ▶ FIRST MESSAGE: send only this, then STOP

**Concept:** MCP isn't a faster report builder. If you're only using it to skip clicks, you'll miss the point. The real unlock is exploration and synthesis: asking questions in plain language and joining product behavior with context that doesn't live in Mixpanel.

The one rule to internalize: **every analysis prompt needs four things: Behavior (which events), Population (who), Timeframe (when), and Shape (rate, trend, breakdown).** Miss one and the AI guesses.

**Want the deeper prompting principles, or ready to jump into Module 1 and orient your data?**

═══════════ DEFERRED: one branch at a time, never the whole block ═══════════

#### → if the user wants the general prompting principles
Surface these, not as a wall. Pick the two or three that fit what they're doing:
- **Role:** set one when it focuses output ("act as a product analyst reviewing a launch"); skip it when it's overhead.
- **Specificity:** name the exact thing. "Show me checkout conversion" is too loose; "conversion from `Checkout Started` to `Purchase Completed` for first-time buyers, last 60 days" is workable.
- **Context:** run `Get-Business-Context` early so the AI grounds analysis in how your team actually thinks.
- **Iterate, don't restart:** MCP keeps context within a session. Follow up with "break that down by…" instead of re-prompting.
- **One ask per turn:** compound questions force the AI to plan multiple jobs at once and the synthesis suffers. Decompose.

#### → if the user asks what a session actually looks like end to end
Every MCP session moves through four phases: **Discover** (find projects, events, properties) → **Query** (insights, funnels, retention, flows) → **Create** (dashboards, saved metrics, Lexicon) → **Iterate** (follow-ups in the same conversation). One thing to flag upfront: query results are temporary and live only in the chat. To persist an analysis you build a dashboard. Saved metrics and Lexicon edits also write back, but a query result on its own doesn't.

### ✓ CHECKPOINT: offer Module 1 when
The user can recite the four-part rule (Behavior + Population + Timeframe + Shape) and understands MCP is for synthesis, not click-saving.

---

## Module 1: Orient (Always Start Here)
<!-- tier: starter · prereq: none -->

### ▶ FIRST MESSAGE: send only this, then STOP

**Concept:** Map the project's schema before running any analysis. Schemas drift (event names get cryptic, properties go undocumented), and skipping this step is the most common reason MCP answers come back confidently wrong.

**Try this:**
> "What Mixpanel projects do I have access to? Pick the most active one and list the top 10 events by recent volume, with descriptions if available. Flag any that don't have a description."

**↑ Complete first message. Send nothing below until the user replies, asks, or errors.**

═══════════ DEFERRED: one branch at a time, never the whole block ═══════════

#### → if the user asks "what should I be seeing?"
A good result has: a list of project names and IDs you can access, a populated event list with volume signals, descriptions where they exist and flags where they don't, and a short read on what kind of product this looks like.

#### → if their prompt was too vague ("what's our checkout conversion rate?")
Show the contrast, then stop. The fix is to make the AI reason about your schema first:
> "List the events that relate to checkout. For each, give the description and top three properties. Then suggest which combination best represents `purchase intent` based on how this project is actually instrumented."
That version surfaces Lexicon gaps instead of assuming.

#### → if it didn't work
- **No projects returned** → project access isn't configured; check Mixpanel permissions.
- **"MCP access is not enabled"** → an org admin enables it in Settings > Org > Overview; changes can take 15 minutes.
- **Auth errors after it worked before** → cached token is stale; re-authenticate your MCP connection using your AI client's auth flow.

#### → tools (only if asked what runs under the hood)
`Get-Projects`, `Get-Events`, `Get-Properties`, `Get-Property-Values`, `Get-Business-Context`.

### ✓ CHECKPOINT: offer Module 2 when
The user can name 5 to 10 events that represent core behaviors in their project, and knows which have good descriptions and which don't.

---

## Module 2: Analyze
<!-- tier: starter · prereq: Module 1 -->

### ▶ FIRST MESSAGE: send only this, then STOP

**Concept:** This is where MCP replaces dashboard navigation. A well-formed prompt returns a chart and a written takeaway in one turn. Apply the four-part rule (Behavior + Population + Timeframe + Shape) to every analysis prompt.

**Try this:**
> "Pick a key funnel in this project (signup-to-activation, browse-to-purchase, or similar). Run the conversion analysis for the last 30 days, then break it down by one meaningful property. Tell me where the biggest drop-off is and which segment converts best."

**↑ Complete first message. Send nothing below until the user replies, asks, or errors.**

═══════════ DEFERRED: one branch at a time, never the whole block ═══════════

#### → if the user asks "did that work?"
A good result has: stepwise conversion numbers, a chart rendered inline, a breakdown by a property the AI chose intelligently from your schema, and a written summary calling out the biggest drop-off and best-performing segment.

#### → if their prompt was too vague ("how is our funnel doing?")
Show the contrast. The good version names all four parts:
> "What's the conversion from `Sign Up` to `First Purchase` for users acquired through paid channels over the last 60 days? Show the trend week-over-week and flag any week the rate dropped more than 10%."
Behavior (two events), population (paid-channel users), timeframe (60 days), shape (weekly trend with anomaly flags).

#### → if it didn't work
- **Wrong event names** → orient first; re-run a Module 1 prompt to confirm names.
- **Breakdown returned empty** → the property may not exist on that event; verify with `Get-Properties` for the specific event, then retry.
- **Numbers feel off** → check `Get-Issues` for data quality problems before trusting the output.

#### → tools (only if asked)
`Get-Query-Schema`, `Run-Query`, `Display-Query`.

### ✓ CHECKPOINT: offer next when
The user can produce a funnel, retention curve, or trend with a meaningful breakdown in one prompt, and trusts the result enough to share it. Starter path next stop is **Module 4** (persist it). If they're chasing *why* behind the numbers, point to **Module 3** (advanced).

---

## Module 3: Investigate
<!-- tier: advanced · prereq: Module 2 -->

### ▶ FIRST MESSAGE: send only this, then STOP

**Concept:** Some questions are unanswerable in aggregate. "Why did this account churn?" is a user-level question. This module drops from population data to individual users. The prompt below tries Session Replay first and falls back to Flows automatically, so it returns insight whether or not Replay is instrumented. Depending on your project's instrumentation, you'll land on Session Replay or Flows. Either one teaches the same move: go from the aggregate to the individuals.

**Try this:**
> "Identify 5 users who started but didn't complete a key funnel in the last 7 days. For each, summarize what they did. If Session Replay is enabled, pull their session replays so I can see the experience firsthand. If it isn't, show me the most common paths they took after the drop-off point using a Flows query, and tell me the top 3 things they did instead of converting."

**↑ Complete first message. Send nothing below until the user replies, asks, or errors.**

═══════════ DEFERRED: one branch at a time, never the whole block ═══════════

#### → if the user asks "did that work?"
The identify step gives you real distinct IDs (an Insights breakdown by the `$distinct_id` property), plus enough context to form a hypothesis. Then, depending on instrumentation: **with Replay**, a per-user narrative of what they did, detected friction like dead clicks and console errors, and replay IDs you can open in the Mixpanel UI; **with Flows**, aggregate post-drop-off paths showing whether users abandoned, looped back, or went somewhere unexpected (no individual IDs on this path).

#### → if the user wants to go deeper with Flows
Flows isn't only a fallback. Even with Replay available, run Flows first to find which drop-off is worth watching, then use Replay on that specific moment:
> "For users who dropped between `[Step A]` and `[Step B]` in the last 14 days, show the most common paths after `[Step A]`. What are the top 3 things they did instead of converting?"

#### → if their prompt was too vague ("why are users churning?")
Show the two-step contrast: identify the users via query, *then* drop into replays or Flows:
> "Step 1: find 10 users who finished onboarding in the last 30 days but haven't been active in 14. Step 2: pull replays for 3 of them, focused on their last active sessions, and summarize what they did before going quiet."

#### → if it didn't work
- **No replay data** → Replay must be enabled and instrumented; confirm in project settings, or fall back to Flows.
- **Replay metadata but no playable links** → replays may be outside your retention window.
- **Flows came back empty, no error** → use the sankey chart type; the paths type can silently return nothing on a drop-off split.
- **Flows returned odd paths** → the entry event is too broad; make it more specific.
- **Generic answer, no IDs** → the prompt was too aggregate; specify the funnel step or behavior to filter on.

#### → tools (only if asked)
`Run-Query` (insights, breakdown by `$distinct_id` for user-level IDs), `Get-User-Replays-Data` (needs a distinct ID and date range, or replay IDs; it can't discover users itself), `Run-Query` (flows, `conversionFilter: did not convert` for drop-offs).

### ✓ CHECKPOINT: offer Module 5 when
The user can move from a population-level finding to an individual-user investigation in the same conversation, and has a clear hypothesis about the drop-off.

---

## Module 4: Build
<!-- tier: starter · prereq: Module 2 -->

### ▶ FIRST MESSAGE: send only this, then STOP

**Concept:** A query result lives only in the chat. To make an analysis persist, you turn it into a dashboard. MCP can write other things back too (saved metrics, plus Lexicon tags and edits), but for charts and reports a dashboard is how the insight survives past the conversation. When an insight matters enough that someone references it next week, it has to live in Mixpanel.

**Try this:**
> "Take the analysis we've done in this conversation and turn it into a persistent Mixpanel dashboard. Pick a clear name. Add a text card at the top explaining what the dashboard tracks, who it's for, and how to read it."

**↑ Complete first message. Send nothing below until the user replies, asks, or errors.**

═══════════ DEFERRED: one branch at a time, never the whole block ═══════════

#### → if the user asks "did that work?"
A good result: a new dashboard in your project, all charts from the conversation present, a sensible layout (related metrics grouped), and a text card up top that frames it for someone who wasn't in the original conversation.

#### → if their prompt was too vague ("save what we just looked at")
Show the contrast. Name the dashboard, list the contents, and ask for framing context:
> "Create a dashboard called `Q2 Activation Health` with the funnel, retention curve, and trend we ran, plus the Flows view that surfaced the drop-off. Add a text card summarizing the key finding from each chart and our hypothesis for why users drop off."
Pinning the investigation view alongside the charts persists *why*, not just *what*, so you can monitor the fix against it.

#### → if the user wants to persist a reusable metric, not just a dashboard
Saved metrics (a behavior or a formula) write back to Mixpanel and can be reused across reports, so a definition like "activated account" lives in one place instead of being rebuilt each time. Try:
> "Create a saved metric for [the core conversion or behavior we just analyzed]. Give it a clear name and base the definition on the events and filters from our analysis. Show me the definition before you save it."
Same review discipline as Module 5: see the definition before it writes.

#### → if it didn't work
- **Permission error** → dashboard creation requires Project Owner or Admin.
- **Name conflict** → rename and retry, or duplicate-and-rename to preserve the existing one.
- **Charts didn't carry over** → the AI lost context; re-run the underlying queries and try again.

#### → tools (only if asked)
Dashboards: `Create-Dashboard`, `Get-Dashboard`, `Update-Dashboard`, `Duplicate-Dashboard`, `Search-Entities`. Saved metrics: `Create-Metric`, `Get-Metric`, `List-Metrics`, `Update-Metric`.

### ✓ CHECKPOINT: Starter path complete when
The user can persist conversation findings to Mixpanel without leaving the chat, and a teammate could open the dashboard cold and understand it. From here, offer the Advanced path (Module 3, 5, or 6) or Module 7 as reference.

---

## Module 5: Govern
<!-- tier: advanced · requires Project Owner or Admin for any write -->

### ▶ FIRST MESSAGE: send only this, then STOP

**Concept:** MCP can audit your Lexicon and fix what it finds, all from chat. The rule that keeps it safe: audit first, review the plan, then apply selectively, never letting it write before you've seen what it will do.

**Try this:**
> "Run a read-only Lexicon health check on this project: list events missing a description, event and user properties that look like PII but aren't flagged sensitive, and any duplicate or near-duplicate event names. Don't change anything, just group the findings by issue type."

**↑ Complete first message. Send nothing below until the user replies, asks, or errors.**

═══════════ DEFERRED: one branch at a time, never the whole block ═══════════

#### → if the user wants to fix what the audit found
This is the payoff: MCP resolves issues, it doesn't just flag them. Heads-up: writes need access to the project's global data view. On a shared, locked-down project you may only have read, in which case the audit still works but the fixes won't apply. Resolve one finding at a time, plan shown before any write.
> "Draft a description for each undocumented event from its name and top properties. Show me the full list, then apply only the ones I approve."
> "Mark these properties as sensitive: [list]."
> "Merge the duplicate cluster into [canonical name]." (reversible in the UI with one click)
Descriptions write via `Bulk-Edit-Events`, sensitivity via `Edit-Property` or `Bulk-Edit-Properties` (`sensitive=True`), merges via `Merge-Event-Group`. Always review first, apply in small batches.

#### → if the user asks about unused or stale events
This is the one heavy check, so lead with the count, never the raw list. Volume isn't in Lexicon metadata, so it has to come from a query:
> "How many distinct events have fired in the last 90 days, versus the total number defined in this project?"
That returns instantly (a single distinct-count). Only if they want to prune:
> "List the events that haven't fired in the last 90 days, excluding hidden and dropped, so I can review them for cleanup."
Two heads-ups for the list version: it runs an All Events breakdown by event name and can be large on a busy project, and the query must use the internal tokens `$all_events` and `$event_name`. The display labels "All Events" and "Event Name" silently return nothing.

#### → if the user wants data-quality issues, not just hygiene
Beyond missing metadata, MCP surfaces detected anomalies like property type drift and value variance:
> "Show me the open data-quality issues in this project, grouped by type and the events they affect."
This uses `Get-Issues`. These are problems in the data itself, distinct from the metadata gaps the health check finds.

#### → if their prompt was too vague ("clean up our events")
Show the contrast. Scoped, names the input, defers the write:
> "Find all events without a Lexicon description. For each, suggest a description from the event name and top three properties. Show me the suggestions before applying anything."

#### → if a write failed or a check returned too much
- **Write blocked (permission error)** → your role or data view access doesn't allow Lexicon writes on this project. Common on shared or company-wide projects. Run the audit there, apply fixes where you have write access.
- **Findings overwhelming** → narrow by tag or group, or filter hidden and dropped first.
- **Stale query hangs or comes back empty** → confirm it used `$all_events` and `$event_name`, and prefer the count over the full list.
- **Suggestions look wrong** → internal acronyms confuse it; review every one before applying.

#### → tools (only if asked)
Read: `Get-Events`, `List-Properties`, `Find-Duplicate-Event-Groups`, `Get-Issues`. Write: `Bulk-Edit-Events`, `Edit-Property`, `Bulk-Edit-Properties`, `Merge-Event-Group`, `Create-Tag`, `Dismiss-Issues`. Stale-event check: `Run-Query` (insights).

### ✓ CHECKPOINT: offer Module 6 when
The user can run the read-only health check, drill into a finding, and resolve at least one issue (a description, a sensitive flag, or a merge) with the plan reviewed before the write.

---

## Module 6: Chain
<!-- tier: advanced · the highest-leverage workflow, save it for last -->

### ▶ FIRST MESSAGE: send only this, then STOP

**Concept:** The highest-leverage thing MCP does is combine Mixpanel with your other connected tools (error monitoring, trackers, CRM, feedback) for synthesis that used to take a week of manual coordination. The discipline that makes it work: decompose into one tool per turn, quantitative first, qualitative last.

**Try this:**
> Pick one tool besides Mixpanel that you have connected. Run a 2-step chain: get a Mixpanel finding first, then a follow-up that pulls from the second tool to deepen it.

**↑ Complete first message. Send nothing below until the user replies, asks, or errors.**

═══════════ DEFERRED: one branch at a time, never the whole block ═══════════

#### → if the user wants the full worked example (feature launch retrospective)
A feature shipped 3 weeks ago; leadership wants to know if it landed. Run these in order, same conversation, one per turn:
1. **Baseline (Mixpanel):** "Evaluate the launch of [Feature X], shipped [date]. Identify the events for it, pull weekly adoption for 4 weeks, retention of adopters vs non-adopters, and the 3 most common paths after first use. Summarize before we layer anything in."
2. **Technical health (+ error monitoring):** "Check our error monitoring for errors thrown by [Feature X] since launch. Do error spikes line up with funnel drop-off? Are users hitting errors disproportionately churning?"
3. **Known bugs (+ tracker):** "Pull tickets tagged [Feature X] or filed after launch. Match drop-off steps against open bugs. Flag high-severity tickets stalled over a week."
4. **Business context (+ CRM):** "Get account IDs of adopters, look them up in CRM, break adoption down by plan tier and ARR. Are paid accounts adopting faster? Flag accounts above [$X ARR] that haven't adopted."
5. **Voice of customer (+ feedback):** "Search customer channels and feedback for [Feature X] mentions in 4 weeks. Categorize: positive, friction, missing, confusion. Does qualitative match quantitative?"
6. **Synthesis:** "Write a one-page retrospective: did it land, what's broken, what ships next sprint, which accounts need CS follow-up. Be honest about what the data does and doesn't tell us."

#### → if the user asks why decomposition matters
A single mega-prompt naming all five tools at once produces worse synthesis than walked steps. The AI needs each result before it can plan the next ask. Order matters too: reverse quantitative-first and you get reasoning in search of data.

#### → if it didn't work
- **Second tool not connected** → confirm both servers are connected and authorized in the same client.
- **Auth expired** → re-authorize the failing connector and retry.
- **AI tried to plan all steps at once** → break it down further; one ask per turn.

### ✓ CHECKPOINT: done when
The user has run at least one cross-tool chain and produced a synthesis they couldn't have gotten from any single tool.

---

## Module 7: Principles and Limits
<!-- tier: reference · open anytime, don't walk it as a lesson -->

### ▶ FIRST MESSAGE: send only this, then STOP

**Concept:** This module is reference, not a lesson. Pull from it when a question comes up. The condensed principles: specify Behavior + Population + Timeframe + Shape on every analysis prompt, orient before analyzing, confirm property names before breakdowns, use Flows for discovery and Funnels for measurement, iterate in the same conversation, decompose compound questions, and verify significant findings in the UI before acting.

**Ask which limit or principle they're checking on. Don't recite the whole list.**

═══════════ DEFERRED: surface only the relevant limit ═══════════

#### → known limits (quote only the one that applies)
- **Cohorts/saved segments by name aren't accessible.** Express population as event/user properties (`plan_type = enterprise`), not "my Enterprise cohort."
- **MCP inherits your existing Mixpanel permissions.** It uses the same roles and Data Views as the web app, so you can only query or write what your account already has access to. A filtered Data View can scope both reads and writes.
- **Individual reports don't save back.** There's no create-report tool, so persist a chart or analysis by adding it to a dashboard. (Saved metrics and Lexicon edits do persist when you create them. It's reports specifically that don't.)
- **Heatmaps aren't available.** Session replays are; heatmaps aren't.
- **Output isn't deterministic.** Same prompt, different framing each run. For demos, use a pre-run conversation.
- **Write operations require role.** `Edit-*`, dashboard creation, and tag changes need Project Owner or Admin.
- **Rate limit: 600 requests/hour/user.** For 20+ query workflows, plan to break across sessions.
- **No HIPAA coverage.** Mixpanel's BAA doesn't currently cover MCP. Don't connect projects with PHI.

---

## Where to Go Next

- Mixpanel MCP documentation: https://docs.mixpanel.com/docs/mcp
- Launch announcement: https://mixpanel.com/blog/mixpanel-mcp/
- "How Mixpanel uses MCP internally": https://mixpanel.com/blog/how-mixpanel-uses-mcp/

The fastest way to make this stick on a team is a shared prompt library: document the prompts that worked, what fired under the hood, and the gotchas you hit.
