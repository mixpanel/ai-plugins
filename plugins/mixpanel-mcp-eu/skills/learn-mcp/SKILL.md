---
name: learn-mcp
description: >
  Onboard users to the Mixpanel MCP server through guided, interactive modules.
  Use when the user asks "how do I use MCP", "what can I ask", "what should I
  try first", "show me what MCP can do", or is figuring out where to start
  (e.g. "what now?"). Always invoke this skill when the user asks about MCP
  capabilities, even if the question seems simple. Do NOT use for: creating
  reports or dashboards, running
  queries, tracking setup, experiment analysis, or Lexicon management — use
  the dedicated skills for those tasks.
license: Apache-2.0
---

# Mixpanel MCP Guide

Onboards users to the Mixpanel MCP server through interactive modules. One concept, one prompt, one result at a time.

## Delivery rules

- Each module has a **FIRST MESSAGE** (concept + prompt) and a **DEFERRED** block. Send only the FIRST MESSAGE, then stop. Surface deferred content one branch at a time when the user responds.
- Present the path selector before any module. Default new users to the Starter path, beginning with Module 0.
- Respect tiers: don't push advanced modules until starter checkpoints are cleared.

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

If you're new to MCP, start with Module 0. Reply with a module name or number to begin.

---

## Module 0: How to Prompt MCP
<!-- tier: starter -->

### FIRST MESSAGE

**Concept:** MCP isn't a faster report builder. If you're only using it to skip clicks, you'll miss the point. The real unlock is exploration and synthesis: asking questions in plain language and joining product behavior with context that doesn't live in Mixpanel.

The one rule to internalize: **for analysis prompts, include four things: Behavior (which events), Population (who), Timeframe (when), and Shape (rate, trend, breakdown).** When any part is missing, the AI fills in defaults that may not match intent.

**Want the deeper prompting principles, or ready to jump into Module 1 and orient your data?**

═══════════ DEFERRED ═══════════

#### → if the user wants prompting principles
Surface the two or three that fit what they're doing:
- **Specificity:** "conversion from `Checkout Started` to `Purchase Completed` for first-time buyers, last 60 days" beats "show me checkout conversion."
- **Context:** load business context early so the AI grounds analysis in your team's vocabulary.
- **Iterate:** follow up with "break that down by…" instead of re-prompting from scratch.
- **One ask per turn:** compound questions force the AI to plan multiple jobs at once and the synthesis suffers. Decompose.

#### → if the user asks what a session looks like end to end
Four phases: **Discover** (projects, events, properties) → **Query** (insights, funnels, retention, flows) → **Create** (dashboards, saved metrics, Lexicon edits) → **Iterate** (follow-ups in the same conversation). Query results are temporary — persist them by building a dashboard.

### CHECKPOINT: offer Module 1 when the user understands the four-part rule and that MCP is for synthesis, not click-saving.

---

## Module 1: Orient (Always Start Here)
<!-- tier: starter -->

### FIRST MESSAGE

**Concept:** Map the project's schema before running any analysis. Schemas drift (event names get cryptic, properties go undocumented), and skipping this step is the most common reason MCP answers come back confidently wrong.

**Try this:**
> "What Mixpanel projects do I have access to? Pick the most active one and list the top 10 events by recent volume, with descriptions if available. Flag any that don't have a description."

═══════════ DEFERRED ═══════════

#### → if the user asks "what should I be seeing?"
A good result: project names and IDs, an event list with volume signals, descriptions where they exist and flags where they don't, and a read on what the product looks like.

#### → if their prompt was too vague ("what's our checkout conversion rate?")
Show the contrast — make the AI reason about the schema first:
> "List the events that relate to checkout. For each, give the description and top three properties. Then suggest which combination best represents `purchase intent` based on how this project is actually instrumented."

#### → if the user mentions "error", "didn't work", "empty", "no results", or "nothing came back"
- **No projects returned** → project access isn't configured; check Mixpanel permissions.
- **"MCP access is not enabled"** → org admin enables it in Settings > Org > Overview (verify current at https://docs.mixpanel.com/docs/mcp).
- **Auth errors** → cached token is stale; re-authenticate your MCP connection using your AI client's auth flow.

### CHECKPOINT: offer Module 2 when the user can name 5–10 core events and knows which have descriptions and which don't.

---

## Module 2: Analyze
<!-- tier: starter -->

### FIRST MESSAGE

**Concept:** This is where MCP replaces dashboard navigation. A well-formed prompt returns a chart and a written takeaway in one turn. Apply the four-part rule from Module 0 to every analysis prompt.

**Try this:**
> "Pick a key funnel in this project. Run the conversion analysis for the last 30 days, break it down by one meaningful property. Tell me where the biggest drop-off is and which segment converts best."

═══════════ DEFERRED ═══════════

#### → if their prompt was too vague ("how is our funnel doing?")
Show the contrast. The good version names all four parts:
> "What's the conversion from `Sign Up` to `First Purchase` for users acquired through paid channels over the last 60 days? Show the trend week-over-week and flag any week the rate dropped more than 10%."
Behavior (two events), population (paid-channel users), timeframe (60 days), shape (weekly trend with anomaly flags).

#### → if the user mentions "wrong events", "empty", "no data", "numbers feel off", or "doesn't look right"
- **Wrong event names** → orient first; re-run a Module 1 prompt to confirm names.
- **Breakdown returned empty** → the property may not exist on that event; check available properties for the specific event, then retry.
- **Numbers feel off** → check for open data quality issues before trusting the output.

### CHECKPOINT: offer Module 4 (persist it) or Module 3 (investigate why).

---

## Module 3: Investigate
<!-- tier: advanced -->

### FIRST MESSAGE

**Concept:** Some questions are unanswerable in aggregate. "Why did this account churn?" is a user-level question. This module drops from population data to individual users via Session Replay or Flows, depending on your instrumentation.

**Try this:**
> "Identify 5 users who started but didn't complete a key funnel in the last 7 days. If Session Replay is enabled, pull their replays. If not, show the most common paths after the drop-off point and tell me the top 3 things they did instead of converting."

═══════════ DEFERRED ═══════════

#### → if the user wants to go deeper with Flows
> "For users who dropped between `[Step A]` and `[Step B]` in the last 14 days, show the most common paths after `[Step A]`. What are the top 3 things they did instead of converting?"

#### → if their prompt was too vague ("why are users churning?")
Show the two-step contrast — identify the users, then investigate:
> "Step 1: find 10 users who finished onboarding in the last 30 days but haven't been active in 14. Step 2: pull replays for 3 of them, focused on their last active sessions, and summarize what they did before going quiet."

#### → if the user mentions "no replays", "empty", "wrong paths", "no IDs", or "generic answer"
- **No replay data** → Replay must be enabled; confirm in project settings, or fall back to Flows.
- **Flows came back empty** → try a different chart visualization; some types may not render drop-off splits (verify current behavior in Mixpanel docs).
- **Generic answer, no IDs** → the prompt was too aggregate; specify the funnel step to filter on.

### CHECKPOINT: offer Module 5 when the user can move from aggregate to individual investigation.

---

## Module 4: Build
<!-- tier: starter -->

### FIRST MESSAGE

**Concept:** A query result lives only in the chat. To make an analysis persist, you turn it into a dashboard. Saved metrics also write back and can be reused across reports — a definition like "activated account" lives in one place instead of being rebuilt each time.

**Try this:**
> "Take the analysis we've done and turn it into a Mixpanel dashboard. Pick a clear name. Add a text card at the top explaining what it tracks and how to read it."

═══════════ DEFERRED ═══════════

#### → if the user wants to persist a reusable metric
> "Create a saved metric for [the core behavior we analyzed]. Show me the definition before you save it."

#### → if the user mentions "permission", "error", "can't create", "didn't save", or "charts missing"
- **Permission error** → check the user's project role; dashboard creation may require elevated permissions (verify current at https://docs.mixpanel.com/docs/mcp).
- **Charts didn't carry over** → the AI lost context; re-run the underlying queries and try again.

### CHECKPOINT: Starter path complete. Offer Advanced path (Module 3, 5, or 6) or Module 7 as reference.

---

## Module 5: Govern
<!-- tier: advanced -->

### FIRST MESSAGE

**Concept:** MCP can audit your Lexicon and fix what it finds, all from chat. **Note: reading and auditing works for any role, but writing changes (descriptions, tags, merges, sensitive flags) requires Project Owner or Admin.** The rule that keeps it safe: audit first, review the plan, then apply selectively — never let it write before you've seen what it will do.

**Try this:**
> "Run a read-only Lexicon health check: list events missing a description, properties that look like PII but aren't flagged sensitive, and any duplicate event names. Don't change anything, just group findings by issue type."

═══════════ DEFERRED ═══════════

#### → if the user wants to fix what the audit found
Group findings by type. Show the full plan for each group with a single confirmation per group:
> "Draft a description for each undocumented event. Show me the full list, then apply only the ones I approve."
> "Mark these properties as sensitive: [list]."
> "Merge the duplicate cluster into [canonical name]." (reversible in the Mixpanel UI)

#### → if the user asks about unused events
Lead with the count, not the raw list:
> "How many distinct events have fired in the last 90 days, versus the total number defined?"

#### → if the user mentions "permission", "blocked", "too many results", "empty", or "wrong suggestions"
- **Write blocked** → the user's role may not allow Lexicon writes on this project. Run the audit there, apply fixes where you have write access.
- **Findings overwhelming** → narrow by tag or group, or filter hidden and dropped first.

### CHECKPOINT: offer Module 6 when the user can audit, drill in, and resolve at least one issue.

---

## Module 6: Chain
<!-- tier: advanced -->

### FIRST MESSAGE

**Concept:** The highest-leverage thing MCP does is combine Mixpanel with your other connected tools for synthesis that used to take a week of manual coordination. The discipline that makes it work: decompose into one tool per turn, quantitative first, qualitative last.

**Try this (follow these steps in order):**
> 1. Run a Mixpanel analysis that surfaces a finding worth investigating (a drop-off, an anomaly, a segment difference).
> 2. Pick one other connected tool (error monitoring, CRM, tracker, feedback).
> 3. Run a follow-up against that second tool to deepen the Mixpanel finding — e.g. correlate the drop-off with error spikes, or look up churned accounts in CRM.

═══════════ DEFERRED ═══════════

#### → if the user wants the full worked example
A feature shipped 3 weeks ago; leadership wants to know if it landed. One prompt per turn:
1. **Mixpanel:** Pull adoption, retention of adopters vs non-adopters, common paths after first use.
2. **Error monitoring:** Do error spikes line up with drop-off?
3. **Tracker:** Match drop-off steps against open bugs.
4. **CRM:** Break adoption down by plan tier and ARR.
5. **Feedback:** Categorize mentions as positive, friction, missing, confusion.
6. **Synthesis:** One-page retrospective — did it land, what's broken, what ships next.

#### → if the user mentions "not connected", "error", "auth", or "tried everything at once"
- **Second tool not connected** → confirm both servers are connected and authorized.
- **AI tried all steps at once** → break it down; one ask per turn.

### CHECKPOINT: done when the user has produced a cross-tool synthesis.

---

## Module 7: Principles and Limits
<!-- tier: reference — open anytime, don't walk as a lesson -->

### FIRST MESSAGE

**Concept:** This module is reference, not a lesson. Pull from it when a question comes up. Ask which limit or principle they're checking on — don't recite the whole list.

═══════════ DEFERRED: surface only the one that applies ═══════════

- **Cohorts can be managed but not used to filter queries.** You can create, list, and get cohorts, but audience targeting via cohort names isn't supported in analytics queries yet — express population as event/user properties instead (verify current at https://docs.mixpanel.com/docs/mcp).
- **MCP inherits your Mixpanel permissions.** Same roles and Data Views as the web app.
- **Individual reports don't save.** Persist charts by adding them to a dashboard. Saved metrics and Lexicon edits do persist.
- **Heatmaps aren't available.** Session replays are; heatmaps aren't.
- **Output isn't deterministic.** Same prompt, different framing each run. For demos, use a pre-run conversation.
- **Write operations require role.** Dashboard creation and Lexicon edits need Project Owner or Admin (verify current at https://docs.mixpanel.com/docs/mcp).
- **Rate limit: 600 requests/hour/user** (verify current at https://docs.mixpanel.com/docs/mcp).
- **No HIPAA coverage.** Mixpanel's BAA does not currently cover MCP (verify current at https://docs.mixpanel.com/docs/mcp). Don't connect projects with PHI.

---

## Where to Go Next

- Mixpanel MCP docs: https://docs.mixpanel.com/docs/mcp
- "How Mixpanel uses MCP internally": https://mixpanel.com/blog/how-mixpanel-uses-mcp/
