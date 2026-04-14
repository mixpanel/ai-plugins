---
name: mxp-skill-creator
description: >
  Guided wizard to create standardised Mixpanel query skills for any customer or internal team.
  ALWAYS use this skill when a user asks to: create a Mixpanel skill, build a query skill for a customer,
  set up a standardised analytics skill, configure a Mixpanel MCP skill, define metrics for a team skill,
  or says anything like "let's build a skill for [customer]", "create a new Mixpanel skill",
  "set up query standards", or "I want to define metrics in a skill". Also use when a user mentions
  editing an existing skill, describing what's in a skill, reviewing a skill, or asking what improvements
  can be made to an existing customer skill. Do NOT use for querying an existing customer's Mixpanel data
  — use the customer's dedicated query skill instead (e.g., jiohotstar-query). This skill is only for
  creating, editing, or reviewing skill definitions themselves. Requires Mixpanel MCP.
---

# Mixpanel Skill Creator

This skill creates, edits, and reviews standardised Mixpanel query skills for enterprise customers. It validates every event, property, and filter value against live Mixpanel data before writing anything.

---

## Primary Menu

Present this menu on entry. Do not read any reference file until the user makes a selection.

```
Mixpanel Skill Creator

1. Create a new customer skill (guided, step-by-step)
2. Quick Create (paste structured input, validate in one pass)
3. Edit an existing skill
4. Describe / review a skill
5. Exit
```

Route based on selection:
- **1** → Jump to [Create Flow — Guided](#create-flow--guided)
- **2** → Jump to [Create Flow — Quick](#create-flow--quick)
- **3** → Jump to [Edit Flow](#edit-flow)
- **4** → Jump to [Describe Flow](#describe-flow)
- **5** → Say *"Exiting. Come back anytime."* and stop

---

## Global Rules

These apply across every flow in this skill. No exceptions.

- **Never skip validation.** Every event name, property, and filter value must be confirmed against live Mixpanel data before being written. An unvalidated metric silently produces wrong results.
- **Be explicit about failures.** When validation fails, show the closest match and let the user decide — never guess or silently substitute.
- **Write incrementally.** Append to the output skill file after each confirmed step. Never wait until the end.
- **One question at a time in Module 4.** Ask, receive answer, then ask the next. Do not batch.
- **Use `approx.` instead of `~` in any Slack-destined output.** Slack renders `~` as strikethrough.
- **Use `INR` prefix instead of `₹` symbol inside code blocks.** Some Slack clients render currency symbols inconsistently.

### Validation Pattern

Use this whenever matching user-provided names/values against live Mixpanel data.

**Name Resolution** (events, properties): Call `Get-Events` or `Get-Property-Names` and match against both names and descriptions.
- Exact match → ✅ confirm and proceed.
- Close match → show it, ask *"Is this the one?"* Wait for confirmation.
- No match → ❌ show 3 most similar, ask which to use.

**Value Resolution** (filter values, property values): Call `Get-Property-Values` scoped to the validated event/property.
- Exact match → ✅ confirm briefly.
- Close match → show it, ask to confirm.
- No match → ❌ show top 5 values found, ask which to use.

**List-Type Detection**: If returned values appear to be arrays or multi-value, flag it: *"This is a list-type property — `propertyType: 'list'` is required in breakdown queries. I'll note this."*

Do not proceed past any validation step until the name/value is confirmed against live data.

### Checkpoint System

To survive session breaks, write a `_wizard_state` YAML block at the top of the output skill file (below frontmatter) after each module completes:

```yaml
<!-- _wizard_state
  modules_complete: [1, 2, 3]
  current_module: 4
  customer_slug: nykaa
  created: 2026-04-11
-->
```

On any new session where the user says "continue" or "resume", read the skill file, detect `_wizard_state`, show which modules are done, and offer to pick up from the next incomplete module.

At finalization, delete the `_wizard_state` block from the file.

---

## Create Flow — Guided

Tell the user: *"Type 'exit' at any point to cancel. Any partial progress will be deleted."*

Run Modules 1–6 in order. After each module, update `_wizard_state` and proceed to the next.

---

### Module 1 — Customer Context & Project Access

**Goal**: Collect customer identity, auto-research business context, validate Mixpanel project access, create the output skill file.

**Step 1.1 — Customer Entry Point**

Ask for the customer name or website URL (at least one required). Then optionally: *"Any additional context? (industry, product type, business model)"*

If only one provided, infer the other (e.g., `nykaa.com` → "Nykaa") but confirm before continuing.

**Step 1.2 — Auto-Generate Business Context**

Web search using customer name/website to research: core product, user base, business model, key metrics they likely care about, industry vertical, recent priorities.

Search strategy:
1. `[customer name] company product analytics` or fetch homepage
2. For India-based companies, also search recent news/funding
3. Look for product blogs, app store descriptions for north star clues

Present a draft:

```
Business Context (auto-generated — please review):
──────────────────────────────────────────────────
Company:        [name]
Website:        [url]
Industry:       [vertical]
Business model: [e.g., D2C e-commerce / subscription OTT]
Core product:   [1–2 sentences]

What they likely track:
  • North star: [e.g., Weekly Active Buyers]
  • Supporting: [2–3 examples with rationale]

Notes: [caveats or gaps in research]
──────────────────────────────────────────────────
```

Ask: *"Does this look accurate? Correct anything or add context — especially their north star metric."*

Do not proceed until the user confirms or corrects.

**Step 1.3 — Validate Mixpanel Project Access**

Ask: *"What Mixpanel project(s) should this skill query? Provide Project IDs or names."*

Call `Get-Projects` from Mixpanel MCP. For each project the user provided:
- Name matches → ✅ resolve to ID
- ID matches → ✅ confirm name
- No match → ❌ show closest match, ask user

Display resolution table:
```
✅  [Project Name]    ID: [id]
❌  "[user input]"    → No match found. Closest: [suggestion]
```

For ❌ entries, be specific about what went wrong and offer the closest match.

Ask: *"Do these look right?"* Re-resolve if corrections provided. Do not proceed until all projects show ✅.

**Step 1.4 — Create Output File**

Read `references/skill-output-template.md` for the file structure. Create the file at `/home/claude/[customer-slug]-mixpanel-skill/SKILL.md`. Fill in: name, description placeholder `[TO BE COMPLETED]`, compatibility, Business Context, Projects table. Write `_wizard_state` with `modules_complete: [1]`.

Report: `✅ Module 1 complete — [N] projects validated. Starting Module 2.`

---

### Module 2 — Metric Definitions

**Goal**: Define, validate, and write metrics one at a time.

**Entry**: Surface the metrics identified in Module 1 (north star + supporting):

```
Suggested metrics from your business context:
  1. [North star]  ← start here
  2. [Supporting 1]
  3. [Supporting 2]

We'll work through these one at a time. Rename, replace, or skip any.
```

If no suggestions exist, ask for the first metric name directly.

**Metric Loop** — repeat for each metric:

**2.1 — Name**: Announce next metric from queue (or ask for free entry). User can rename or skip.

**2.2 — Events**: Ask which event(s) contribute. For each, call `Get-Events` and validate using the Name Resolution pattern. If multiple events: *"Union (any = 1 occurrence) or tracked separately?"*

**2.3 — Aggregation**: Ask with explicit options:
- Total event count
- Unique users (`math: "unique"`)
- Sum of a property value → ask which property
- Ratio / formula → collect numerator and denominator separately

**2.4 — Filters**: Ask for always-applied filters (e.g., `platform = iOS`, `environment = production`). For each filter:
- Validate property name via `Get-Property-Names` + Name Resolution
- Validate filter value via `Get-Property-Values` + Value Resolution
- Flag list-type properties if detected

**2.5 — Unit & Direction**: *"Unit? (users, %, INR, sessions) And does healthy mean up or down?"*

**2.6 — Confirm & Save**: Show the metric block exactly as it will be written (use the format from `references/skill-output-template.md` under `## Standard Metric Definitions`). Ask: *"Save this, or what needs to change?"*
- Save → append to skill file
- Changes → re-validate affected fields only, show updated block, confirm again

**2.7 — Queue Check**: After saving, if suggested metrics remain, show remaining queue with options: (a) define next, (b) skip one, (c) skip all remaining and finish, (d) define a different metric. If queue empty: *"Define another metric, or done?"*

On completion, update `_wizard_state`. Report: `✅ Module 2 complete — [N] metrics defined. Starting Module 3.`

---

### Module 3 — Breakdown Dimensions

**Goal**: Define standard dimensions analysts slice metrics by. Validate each property inline.

**Entry**: *"Module 3 — Breakdown Properties. What properties do your teams break metrics down by? One at a time — property name and optionally what it represents."*

**Per property**:

**3.1a — Validate Name**: Call `Get-Property-Names`, apply Name Resolution. If multi-project skill, check all projects and note which ones have this property.

**3.1b — Validate Values**: Call `Get-Property-Values`. Populate `known_values` from live data. Detect list-type properties. If user specified expected values, validate each.

After each property: *"More breakdown properties, or done?"*

**3.2 — Confirm & Save**: Show full breakdown block (format from `references/skill-output-template.md`). Ask to save or change. Append on confirmation.

On completion, update `_wizard_state`. Report: `✅ Module 3 complete — [M] properties validated. Starting Module 4.`

---

### Module 4 — Data Quality Signals

**Goal**: Document known dirty corners so future queries know what to watch for. Four questions, strict one-at-a-time, all skippable.

**Q1 — Instrumentation Gaps**: *"Any events/properties known to be incomplete or inconsistent? (e.g., missing on one platform, null for a user type, broke after an app version)"* Say 'none' to skip.

Write each as: `- **[name]**: [description]. Affected: [scope]. Known since: [date or "unknown"].`

**Q2 — Parallel Event Names**: *"Multiple event names for the same action? (SDK version diffs, re-instrumentation, A/B variants) For each: canonical name, alternate name(s), and cutover date."* Say 'none' to skip.

Write as `event_aliases:` block with canonical, also_known_as, legacy_only_before, notes.

**Q3 — Data Lag**: *"Known delay between user action and appearance in Mixpanel? (server-side batching, warehouse backfill lag, offline mobile queuing)"* Say 'none' to skip.

Write as: `- **Ingestion lag**: [description]. Affected: [events/pipelines]. Avoid interpreting last [N] hours as final.`

**Q4 — Cross-Project Joins**: *"Do any Module 2 metrics require data from multiple projects? If yes: which metrics, which projects, join key."* Say 'none' to skip.

**Query Conventions** (final calibration): Present defaults and ask to confirm or change:
```
Timezone:         IST (UTC+5:30)
Default lookback: Last 7 days
Minimum sample:   50 events before interpreting rates
Trend threshold:  Flag WoW > 20%; treat < 5% as noise unless 3+ periods
```

Write both `## Data Quality Signals` and `## Query Conventions` to the skill file.

On completion, update `_wizard_state`. Report: `✅ Module 4 complete. Starting Module 5.`

---

### Module 5 — Presentation & Brand Guidelines

**Goal**: Capture how outputs should look — brand colours, format, audience, conventions. Four questions, all skippable.

**Pre-Q — Brand Colours**: Ask the user first: *"Do you have [Customer Name]'s brand colours (hex codes), or should I research them?"*

- **User provides** → use directly.
- **Research requested** → web search `[customer] brand guidelines` / `[customer] press kit`. Present draft with confidence level (high/medium/low). Ask to confirm.
- **"Use Mixpanel defaults"** → set to `use Mixpanel brand defaults (see mixpanel-brand skill)`.

**Q1 — Output Format**: *"Default delivery format? (a) HTML (b) PPTX (c) DOCX (d) PDF (e) Slack (f) Flexible"*
If multiple, ask which is primary. If flexible, set `context_dependent: true`.

**Q2 — Audience & Tone**: *"Primary reader? (a) Execs/Directors — headline-first (b) PMs/Analysts — full numbers (c) Mixed — exec summary + detail (d) Other"*
Map to tone: a→executive, b→analytical, c→mixed, d→interpret and confirm.

**Q3 — Number & Currency**: *"Currency: INR or USD? (Default: INR) Large numbers: Lakh/Crore or Million/Billion? (Default: Lakh/Crore)"*
Then confirm chart defaults: `Trend chart: Line. Number display: Raw.`

**Q4 — Brand Assets & Hard Rules**: *"Any style guide URL, logo link, or slide template? Any 'never do X' rules for this account?"* Say 'none' if not applicable.

Write `## Presentation & Brand Guidelines` to skill file using structure from `references/skill-output-template.md`.

On completion, update `_wizard_state`. Report: `✅ Module 5 complete. Starting final review.`

---

### Module 6 — Review & Finalize

**Goal**: Read-only review of everything captured. User confirms before packaging.

**6.1** — Read the full skill file fresh from disk.

**6.2** — Display a summary card covering all 5 modules:
- **Module 1**: Customer name, website, industry, north star, projects (name → ID)
- **Module 2**: Count + list of metrics (name, events, aggregation, validation status)
- **Module 3**: Count + list of breakdowns (name, type, known values truncated at 3)
- **Module 4**: Gap count, alias count, default filters, query conventions
- **Module 5**: Brand colours, primary format, audience/tone, currency/number format

If a field is absent, show `—`. If a section is missing, show `⚠️ Not found`.

**6.3** — Ask: *"Does this look right, or anything to fix before packaging?"*
- **Looks good** → proceed to Finalization
- **Correction** → identify which module owns it, re-run that module's relevant steps, then re-show the summary

### Finalization

**F.1 — Write Description**: Read completed skill file. Write final `description` field in YAML frontmatter: name the customer, list 3-5 key metrics, list top breakdowns, include trigger phrases.

**F.2 — Remove Wizard State**: Delete the `_wizard_state` block from the file.

**F.3 — Package**: Read and execute `references/packaging-instructions.md`.

**F.4 — Return to Menu**: *"Would you like to create another skill or do something else?"* Re-show Primary Menu.

---

## Create Flow — Quick

For users who already know their customer's metrics, breakdowns, and data quality signals. Accepts structured input, validates everything in one pass, writes the skill.

**Step Q.1 — Collect Structured Input**

Ask the user to paste or dictate their input in any reasonable format — YAML, a table, free text with clear structure. Provide this template as a guide:

```yaml
customer: [name]
website: [url]
industry: [vertical]
business_model: [description]
north_star: [metric name]

projects:
  - name: [project name]
    id: [project_id]
    purpose: [Primary / Infra / etc.]

metrics:
  - name: [Metric Name]
    events: [event_name]
    aggregation: [unique_users | total_events | sum:property | ratio]
    filters:
      - property: value
    unit: [users | % | INR | sessions]
    direction: [up | down]

breakdowns:
  - name: [property_name]
    label: [Human-readable label]

data_quality:
  gaps: [free text or "none"]
  aliases: [free text or "none"]
  lag: [free text or "none"]
  default_filters:
    - property: value

conventions:
  timezone: IST
  lookback: 7 days

presentation:
  brand_colours: [primary hex, secondary hex]
  format: [html | pptx | slack | flexible]
  audience: [exec | analyst | mixed]
  currency: INR
  large_numbers: lakh_crore
```

Accept partial input — fill gaps with sensible defaults (IST timezone, INR currency, lakh/crore, line charts) and flag what was defaulted.

**Step Q.2 — Batch Validate**

Run all validation in one pass:

1. **Projects**: Call `Get-Projects`, resolve all project names/IDs.
2. **Events**: For each metric, call `Get-Events` on the relevant project. Validate all event names.
3. **Properties**: For each metric filter and each breakdown, call `Get-Property-Names`. Validate names.
4. **Values**: For each filter value, call `Get-Property-Values`. Validate values.

Present a consolidated validation report:

```
Validation Results:
──────────────────────────────────────────────────
Projects:    [N]/[N] ✅
Metrics:     [N]/[N] events validated
Breakdowns:  [N]/[N] properties validated
Filters:     [N]/[N] values validated

Issues found:
  ❌ Metric "X" — event "Y" not found. Closest: "Z"
  ⚠️ Breakdown "A" — list-type detected, will flag propertyType
──────────────────────────────────────────────────
```

For each ❌, ask the user to resolve. For ⚠️, auto-handle and note.

**Step Q.3 — Generate & Confirm**

Once all validations pass, generate the complete skill file in one shot using `references/skill-output-template.md`. Show the Module 6 summary card. Ask for confirmation.

**Step Q.4 — Finalize**

Write description, package, present. Same as Finalization in the Guided flow (steps F.1–F.4).

---

## Edit Flow

**Phase 1 — Discovery**: Read and execute `references/skill-discovery.md` to locate the skill file. Sets `WORKING_SKILL_PATH`.

**Phase 2 — Validation & Snapshot**

Read the skill file. Scan for standard sections and show a summary card:

```
Found: [Customer Name] Mixpanel Skill
Working copy: [path]

Section Status:
  Business Context               [✅ / ⚠️ / ❌]
  Projects                       [✅ / ⚠️ / ❌]   [N validated]
  Metric Definitions             [✅ / ⚠️ / ❌]   [N metrics]
  Breakdown Dimensions           [✅ / ⚠️ / ❌]   [N properties]
  Data Quality Signals           [✅ / ⚠️ / ❌]
  Query Conventions              [✅ / ⚠️ / ❌]
  Presentation & Brand           [✅ / ⚠️ / ❌]
```

Store full file content as `ORIGINAL_SNAPSHOT` (used for undo and changelog). Never modify this snapshot.

Show the Module 6 summary card (read-only, no confirmation prompt), then: *"What would you like to update?"*

**Phase 3 — Edit Menu**

```
What would you like to edit?

  1. Customer Context & Business Info
  2. Metric Definitions → (a) Add  (b) Replace  (c) Remove
  3. Breakdown Dimensions → (a) Add  (b) Update values  (c) Remove
  4. Data Quality Signals & Query Conventions
  5. Presentation & Brand Guidelines
  6. Done — finalize and re-package
  7. Exit without saving — discard all edits
```

Multiple selections allowed (e.g., "2, 3"). Run in ascending order.

**Edit Pattern** (applies to every module):
1. Show current section content
2. Ask what to change — do not re-collect unchanged fields
3. For each change: collect → validate against live data → confirm
4. Write only changed blocks. Update `validation_status` date on modified items.
5. Never re-create the file from scratch.

**Per-module specifics**:
- **Module 1**: Collect new text for requested fields only. Add project → validate that project only. Remove project → confirm and delete row.
- **Module 2**: Add → run full Metric Loop, append. Replace → show current block, re-run loop, overwrite. Remove → confirm, delete; flag if metric is in description field. **Batch mode**: if the user selects multiple metrics to add/replace at once, collect all definitions first, then batch-validate all events and properties in one pass (call `Get-Events` once per project, `Get-Property-Names` once per event) before writing. Present a consolidated validation report like the Quick Create flow.
- **Module 3**: Add → validate new property, append. Update values → show current known_values, validate additions via `Get-Property-Values`. Remove → confirm, delete. **Batch mode**: if the user provides multiple properties at once, batch-validate all names and values in one pass before writing.
- **Module 4**: Only collect for sub-sections the user specifies. Append new entries, don't overwrite untouched sub-sections.
- **Module 5**: Only change requested fields. Validate hex format, enum values. Overwrite only changed keys.

**Option 7 — Exit Without Saving**: Warn, then restore `WORKING_SKILL_PATH` content from `ORIGINAL_SNAPSHOT`. Return to Primary Menu.

After all selected edits: mark modules ✅, re-show edit menu so user can select more or choose option 6.

**Phase 5 — Re-finalization**

1. **Version bump**: Increment `skill_version` in the YAML frontmatter (e.g., `"1.0"` → `"1.1"` for minor edits, `"2.0"` for structural changes like adding/removing metrics). Update `last_validated` to today's date.
2. **Description update**: Ask if the user wants to regenerate the triggering description. Yes → rewrite. No → leave as-is.
3. **Package**: Read and execute `references/packaging-instructions.md`.
4. **Changelog**: Diff `ORIGINAL_SNAPSHOT` against current file. For each of the 7 standard sections, classify as: ✅ Added / ✏️ Modified / ❌ Removed / — Unchanged. For Modified sections, list specific items changed (metric names, property names, field-level diffs). Display as a prioritised changelog. Omit Unchanged sections.
5. **Return to Menu**.

---

## Describe Flow

Read-only review of an existing skill with actionable improvement suggestions.

**Step D.1 — Discovery**: Read and execute `references/skill-discovery.md`. Sets `WORKING_SKILL_PATH`.

**Step D.2 — Summary**: Read the skill file. Show the Module 6 summary card (read-only).

**Step D.3 — Improvement Suggestions**

Evaluate across 6 dimensions. Only show dimensions with findings. Reference actual content (metric names, property names, section headers) — never generic advice.

**Dimension 1 — Completeness**: Are all 7 standard sections present and non-empty? Check `last_validated` — if missing or >90 days old, flag as ⚠️.

**Dimension 2 — Metric Quality**: For each metric:
- Has at least one exclusion filter? (unfiltered = test traffic included)
- Marked ✅ Validated?
- Notes field populated? (edge cases documented?)
- If ratio, are both numerator and denominator defined?

**Dimension 3 — Breakdown Coverage**: For each property:
- `known_values` has ≥3 entries?
- List-type property has `propertyType: 'list'` note?
- Validated?
- Missing obvious dimensions for customer type? (e.g., subscription product with no plan-tier)

**Dimension 4 — Data Quality Signals**:
- `default_filters` empty? (queries will include test/internal traffic)
- Mature product with empty `event_aliases`? (yellow flag)
- Service account section documented?
- Query conventions all explicitly set?

**Dimension 5 — Presentation & Brand**:
- All 3 colour fields populated with hex?
- `context_dependent: true` without format rules? (ambiguous)
- `primary_persona` and `tone` set to specific values? (not `mixed`/`not_specified`)
- For Indian enterprise: `large_number_format` = `lakh_crore`?

**Dimension 6 — Triggering Description**:
- Names customer explicitly?
- Includes ≥3 metric names?
- Has trigger phrases?
- Under ~80 words?

**Display**: Group findings by priority:
- 🔴 High: Silently wrong query results (missing filters, unvalidated metrics, empty default_filters)
- ⚠️ Medium: Reduced quality (sparse known_values, ambiguous format, vague audience)
- ℹ️ Low: Triggering accuracy, documentation completeness

After displaying: *"Jump into Edit to address these, or just for reference?"*
- **Edit** → jump to Edit Flow Phase 2, skip discovery (skill already located)
- **Reference** → return to Primary Menu

---

## Resume Detection

At the start of any session, if the user says "continue", "resume", or references an in-progress skill:

1. Check `/home/claude/` for any directory matching `*-mixpanel-skill/SKILL.md`
2. Read the file and look for `_wizard_state`
3. If found, show: *"Found an in-progress skill for [customer]. Modules complete: [list]. Resume from Module [N]?"*
4. If confirmed, jump to the appropriate module in the Create Flow
5. If not found, say so and show the Primary Menu
