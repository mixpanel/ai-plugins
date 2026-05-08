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

The output is a **modular skill folder**, not a single file. See `references/skill-output-template.md` for the full structure. The wizard writes one reference file per module — never appends everything into one file.

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
- **Write incrementally.** Append to the correct reference file after each confirmed step. Never wait until the end.
- **One question at a time in Module 4.** Ask, receive answer, then ask the next. Do not batch.
- **Modular output.** Each module writes to its own reference file under `references/`. The top-level `SKILL.md` is a lean router and is finalised in Module 6, not piecemeal.

### Output Folder Layout

Every skill produced by this wizard follows this structure (see `references/skill-output-template.md` for full content):

```
[customer-slug]-mixpanel-skill/
├── SKILL.md                       # Lean entry point: frontmatter, trigger, router
└── references/
    ├── business-context.md        # Customer identity + project registry  (Module 1)
    ├── metrics.md                 # Standard metric definitions           (Module 2)
    ├── breakdowns.md              # Breakdown properties + known values   (Module 3)
    ├── data-quality.md            # Gaps, aliases, default filters        (Module 4)
    ├── query-conventions.md       # Timezone, lookback, thresholds        (Module 4)
    └── presentation.md            # Brand, audience, format               (Module 5)
```

### Validation Pattern

Use this whenever matching user-provided names/values against live Mixpanel data.

**Name Resolution** (events, properties): Call `Get-Events` for events, or `Get-Properties` for properties, and match against both names and descriptions.
- Exact match → ✅ confirm and proceed.
- Close match → show it, ask *"Is this the one?"* Wait for confirmation.
- No match → ❌ show 3 most similar, ask which to use.

**Property Scope Note**: `Get-Properties` returns both event-scoped and user-scoped properties. Always check the `entity` / scope field in the result — validating an event property against the user-property namespace (or vice versa) will return a false negative. When the user names a property, ask which scope they mean if it isn't obvious from context.

**Value Resolution** (filter values, property values): Call `Get-Property-Values` scoped to the validated event/property.
- Exact match → ✅ confirm briefly.
- Close match → show it, ask to confirm.
- No match → ❌ show top 5 values found, ask which to use.

**List-Type Detection**: Read the `type` field returned by `Get-Properties` directly — if it is `list`, flag it: *"This is a list-type property — `propertyType: 'list'` is required in breakdown queries. I'll note this."* Do not infer list-type by inspecting `Get-Property-Values` output shape; the typed metadata is authoritative.

Do not proceed past any validation step until the name/value is confirmed against live data.

### Checkpoint System

To survive session breaks, write a `_wizard_state` YAML block at the top of the **top-level `SKILL.md`** (below frontmatter) after each module completes. **Do not** scatter state across reference files.

```yaml
<!-- _wizard_state
  modules_complete: [1, 2, 3]
  current_module: 4
  customer_slug: mixpanel
  created: 2026-04-11
-->
```

On any new session where the user says "continue" or "resume", read the top-level `SKILL.md`, detect `_wizard_state`, show which modules are done, and offer to pick up from the next incomplete module.

At finalization (Module 6), delete the `_wizard_state` block from the file.

---

## Create Flow — Guided

Tell the user: *"Type 'exit' at any point to cancel. Any partial progress will be deleted."*

Run Modules 1–6 in order. After each module, update `_wizard_state` and proceed to the next.

---

### Module 1 — Customer Context & Project Access

**Goal**: Collect customer identity, auto-research business context, validate Mixpanel project access, create the output folder structure.

**Writes**: `SKILL.md` (frontmatter + placeholders) and `references/business-context.md`.

**Step 1.1 — Customer Entry Point**

Ask for the customer name or website URL (at least one required). Then optionally: *"Any additional context? (industry, product type, business model)"*

If only one provided, infer the other (e.g., `mixpanel.com` → "Mixpanel") but confirm before continuing.

**Step 1.2a — Check Stored Business Context First**

Before web-searching, call `Get-Business-Context` from the Mixpanel MCP. The project owner may have already curated north star, segments, KPIs, and product description directly in the workspace.

- If meaningful context returns → use it as the seed for Step 1.2b. Show the user what was found, mark fields as `(from Mixpanel)`, and only web-search to fill gaps.
- If empty or thin → proceed to full web search in Step 1.2b.

This grounds the wizard in what the project owner has actually defined and saves a research round-trip.

**Step 1.2b — Auto-Generate Business Context**

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

**Step 1.4 — Create Output Folder & Initial Files**

Read `references/skill-output-template.md` for the file structure. Create:

1. The folder `/home/claude/[customer-slug]-mixpanel-skill/references/`
2. `SKILL.md` at the folder root — fill in: name, `description: "[TO BE COMPLETED]"`, compatibility, **and the `_wizard_state` block with `modules_complete: [1]`**. Leave the routing table and Hard Rules sections as the template's placeholder text — Module 6 will finalise them.
3. `references/business-context.md` — fill in: Identity section, Strategic Metrics index, Stakeholders (if any), Projects table, and Cross-Project Joins (if any).

Report: `✅ Module 1 complete — [N] projects validated. Wrote business-context.md. Starting Module 2.`

---

### Module 2 — Metric Definitions

**Goal**: Define, validate, and write metrics one at a time.

**Writes**: `references/metrics.md` (append per metric).

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
- Validate property name via `Get-Properties` + Name Resolution (check correct scope: event vs user)
- Validate filter value via `Get-Property-Values` + Value Resolution
- Flag list-type properties if detected

**2.5 — Unit & Direction**: *"Unit? (users, %, INR, sessions) And does healthy mean up or down?"*

**2.6 — Confirm & Save**: Before showing the metric block, call `Get-Query-Schema` once (cache for the session) to confirm the metric's aggregation, filter shape, and breakdown structure are actually expressible in a Run-Query call. If the schema reveals a constraint that conflicts with the metric definition (e.g., requested aggregation isn't supported, filter operator unavailable), surface it now rather than letting the downstream query skill discover it.

Then show the metric block exactly as it will be written (use the format from `references/skill-output-template.md` under the `metrics.md` section). Ask: *"Save this, or what needs to change?"*
- Save → append to `references/metrics.md`. If the file does not yet exist, create it with the file's H1 header from the template, then append.
- Changes → re-validate affected fields only, show updated block, confirm again

**2.7 — Queue Check**: After saving, if suggested metrics remain, show remaining queue with options: (a) define next, (b) skip one, (c) skip all remaining and finish, (d) define a different metric. If queue empty: *"Define another metric, or done?"*

On completion, update `_wizard_state` in the top-level `SKILL.md`. Report: `✅ Module 2 complete — [N] metrics defined in references/metrics.md. Starting Module 3.`

---

### Module 3 — Breakdown Dimensions

**Goal**: Define standard dimensions analysts slice metrics by. Validate each property inline.

**Writes**: `references/breakdowns.md`.

**Entry**: *"Module 3 — Breakdown Properties. What properties do your teams break metrics down by? One at a time — property name and optionally what it represents."*

**Per property**:

**3.1a — Validate Name**: Call `Get-Properties`, apply Name Resolution. Confirm scope (event vs user). If multi-project skill, check all projects and note which ones have this property.

**3.1b — Validate Values**: Call `Get-Property-Values`. Populate `known_values` from live data. Detect list-type properties. If user specified expected values, validate each.

After each property: *"More breakdown properties, or done?"*

**3.2 — Confirm & Save**: Show full breakdown block (format from `references/skill-output-template.md`). Ask to save or change. Append to `references/breakdowns.md` (creating the file with its H1 header on first write).

If the skill spans multiple projects, also populate the **Multi-Project Coverage** table in `breakdowns.md` — note which properties exist on which projects.

On completion, update `_wizard_state`. Report: `✅ Module 3 complete — [M] properties validated in references/breakdowns.md. Starting Module 4.`

---

### Module 4 — Data Quality Signals & Query Conventions

**Goal**: Document known dirty corners + set query defaults. Four questions for data quality, then conventions confirmation. Strict one-at-a-time, all skippable.

**Writes**: `references/data-quality.md` and `references/query-conventions.md`.

**Q1 — Instrumentation Gaps**: Before asking the user, call `Get-Issues` on the project(s) to fetch live data-quality issues (type drift, null values, schema inconsistencies) directly from Lexicon. Present them as a starting point:

```
Mixpanel detected the following data quality issues on this project:
  • [Event/Property]: [issue type] — [detail]
  • [Event/Property]: [issue type] — [detail]

Are any of these worth documenting? Anything else to add that Mixpanel hasn't flagged? (e.g., missing on one platform, null for a user type, broke after an app version)
```

If `Get-Issues` returns nothing, fall back to: *"Any events/properties known to be incomplete or inconsistent?"* Say 'none' to skip.

Write each as: `- **[name]**: [description]. Affected: [scope]. Known since: [date or "unknown"]. Workaround: [if any].` under the **Instrumentation Gaps** section of `data-quality.md`.

**Q2 — Parallel Event Names**: *"Multiple event names for the same action? (SDK version diffs, re-instrumentation, A/B variants) For each: canonical name, alternate name(s), and cutover date."* Say 'none' to skip.

Write as `event_aliases:` block under **Renamed / Re-instrumented Events** in `data-quality.md`.

**Q3 — Default Exclusion Filters**: *"What filters should be applied to every query? (e.g., environment = production, exclude internal users, exclude bots)"* Validate each property and value via the standard validation pattern.

Write as `default_filters:` block under **Default Exclusion Filters** in `data-quality.md`. **This is a critical section — empty `default_filters` means future queries will silently include test traffic.**

**Q4 — Service Accounts & Data Lag**: Two short questions:
- *"Any known service accounts or programmatic traffic to flag?"*
- *"Any known delay between user action and Mixpanel ingestion? (server-side batching, warehouse backfill lag, offline mobile queuing)"*

Write to **Service Accounts** and **Data Lag** sections of `data-quality.md`.

**Cross-Project Joins**: *"Do any Module 2 metrics require data from multiple projects? If yes: which metrics, which projects, join key."* Say 'none' to skip. If yes, **return to `references/business-context.md`** and append to its Cross-Project Joins section (not data-quality.md).

**Query Conventions** (final calibration): Present defaults and ask to confirm or change:
```
Timezone:         IST (UTC+5:30)
Default lookback: Last 7 days
Week definition:  Monday–Sunday rolling 7 days
Minimum sample:   50 events before interpreting rates
Trend threshold:  Flag WoW > 20%; treat < 5% as noise unless 3+ periods
Top-N breakdown:  10
Null handling:    Include as "(unknown)"
PoP comparison:   WoW for ≤14d lookback, MoM for ≤90d, YoY otherwise
```

Write `references/query-conventions.md` from these confirmed values, using the template structure.

On completion, update `_wizard_state`. Report: `✅ Module 4 complete — wrote data-quality.md and query-conventions.md. Starting Module 5.`

---

### Module 5 — Presentation & Brand Guidelines

**Goal**: Capture how outputs should look — brand colours, format, audience, conventions. Four questions, all skippable.

**Writes**: `references/presentation.md`.

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

Write `references/presentation.md` using structure from `references/skill-output-template.md`.

On completion, update `_wizard_state`. Report: `✅ Module 5 complete — wrote presentation.md. Starting final review.`

---

### Module 6 — Review & Finalize

**Goal**: Read-only review of everything captured, then finalise the top-level `SKILL.md` router. User confirms before packaging.

**Reads**: All six output files.
**Writes**: Finalised `SKILL.md` (description + routing table + Hard Rules).

**6.1** — Read all six files fresh from disk:
- `SKILL.md`
- `references/business-context.md`
- `references/metrics.md`
- `references/breakdowns.md`
- `references/data-quality.md`
- `references/query-conventions.md`
- `references/presentation.md`

**6.2** — Display a summary card covering all 5 modules:
- **Module 1** (`business-context.md`): Customer name, website, industry, north star, projects (name → ID), cross-project joins if any
- **Module 2** (`metrics.md`): Count + list of metrics (name, events, aggregation, validation status)
- **Module 3** (`breakdowns.md`): Count + list of breakdowns (name, scope, type, known values truncated at 3)
- **Module 4** (`data-quality.md` + `query-conventions.md`): Gap count, alias count, default filter count, query conventions (timezone, lookback, thresholds)
- **Module 5** (`presentation.md`): Brand colours, primary format, audience/tone, currency/number format

If a field is absent, show `—`. If a section is missing, show `⚠️ Not found`.

**6.3** — Ask: *"Does this look right, or anything to fix before packaging?"*
- **Looks good** → proceed to Finalization
- **Correction** → identify which module owns it, re-run that module's relevant steps (which writes to the correct reference file), then re-show the summary

### Finalization

**F.1 — Write SKILL.md Router**: Now that all reference files exist and are confirmed, finalise the top-level `SKILL.md`:

1. Replace `description: "[TO BE COMPLETED]"` with the final triggering description: name the customer, list 3–5 key metrics, list top breakdowns, include trigger phrases. Keep under ~80 words.
2. Replace placeholder text in the body with the lean router structure from `references/skill-output-template.md` File 1:
   - 2–3 sentence summary
   - North Star Metric and Primary Project lines
   - "When to load which reference" routing table (filled in with actual file paths — they're all standard)
   - Hard Rules section (specialise rule 4 and 5 with any list-type properties or non-default conventions actually present)
   - Validation Status block with today's date

**F.2 — Remove Wizard State**: Delete the `_wizard_state` block from `SKILL.md`.

**F.3 — Package**: Read and execute `references/packaging-instructions.md`.

**F.4 — Return to Menu**: *"Would you like to create another skill or do something else?"* Re-show Primary Menu.

---

## Create Flow — Quick

For users who already know their customer's metrics, breakdowns, and data quality signals. Accepts structured input, validates everything in one pass, writes the modular skill folder.

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
3. **Properties**: For each metric filter and each breakdown, call `Get-Properties`. Validate names and scope (event vs user).
4. **Values**: For each filter value, call `Get-Property-Values`. Validate values.
5. **Query Schema**: Call `Get-Query-Schema` once. Confirm each metric's aggregation/filter/breakdown shape is expressible.

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

Once all validations pass, generate the **complete skill folder** in one shot using `references/skill-output-template.md`:

1. Create folder `/home/claude/[customer-slug]-mixpanel-skill/references/`
2. Write `SKILL.md` (lean router, fully populated — no placeholders since this is one-shot)
3. Write all six reference files

Show the Module 6 summary card. Ask for confirmation.

**Step Q.4 — Finalize**

Package and present. Same as Finalization steps F.3–F.4 in the Guided flow. (No `_wizard_state` to delete since Quick Create never wrote one.)

---

## Edit Flow

**Phase 1 — Discovery**: Read and execute `references/skill-discovery.md` to locate the skill folder. Sets `WORKING_SKILL_DIR` (the folder path, not a single file).

**Phase 1b — Cross-Reference (optional)**: If the skill targets a known project, call `Search-Entities` with `entity_types=['dashboard', 'report']` scoped to that project. Surface a brief list of dashboards/reports the customer actively uses — useful context for the user when deciding which metrics or breakdowns to add/update. Skip if the user is in a hurry; this is informational only.

**Phase 2 — Validation & Snapshot**

Read **all files** in the skill folder:
- `SKILL.md`
- `references/business-context.md`
- `references/metrics.md`
- `references/breakdowns.md`
- `references/data-quality.md`
- `references/query-conventions.md`
- `references/presentation.md`

Show a summary card:

```
Found: [Customer Name] Mixpanel Skill
Working folder: [path]

Section Status:
  Business Context (business-context.md)    [✅ / ⚠️ / ❌]
  Projects (business-context.md)            [✅ / ⚠️ / ❌]   [N validated]
  Metric Definitions (metrics.md)           [✅ / ⚠️ / ❌]   [N metrics]
  Breakdown Dimensions (breakdowns.md)      [✅ / ⚠️ / ❌]   [N properties]
  Data Quality Signals (data-quality.md)    [✅ / ⚠️ / ❌]
  Query Conventions (query-conventions.md)  [✅ / ⚠️ / ❌]
  Presentation & Brand (presentation.md)    [✅ / ⚠️ / ❌]
  SKILL.md router                            [✅ / ⚠️ / ❌]
```

Store all file contents as `ORIGINAL_SNAPSHOT` (a dict: `{path → content}`). Used for undo and changelog. Never modify this snapshot.

Show the Module 6 summary card (read-only, no confirmation prompt), then: *"What would you like to update?"*

**Phase 3 — Edit Menu**

```
What would you like to edit?

  1. Customer Context & Business Info  → references/business-context.md
  2. Metric Definitions                 → references/metrics.md         (a) Add  (b) Replace  (c) Remove
  3. Breakdown Dimensions               → references/breakdowns.md      (a) Add  (b) Update values  (c) Remove
  4. Data Quality Signals               → references/data-quality.md
  5. Query Conventions                  → references/query-conventions.md
  6. Presentation & Brand               → references/presentation.md
  7. Done — finalize and re-package
  8. Exit without saving — discard all edits
```

Multiple selections allowed (e.g., "2, 3"). Run in ascending order.

**Edit Pattern** (applies to every selection):
1. Show current section content from the relevant reference file
2. Ask what to change — do not re-collect unchanged fields
3. For each change: collect → validate against live data → confirm
4. Write only changed blocks to the correct reference file. Update `validation_status` date on modified items.
5. Never re-create any reference file from scratch.

**Per-selection specifics**:
- **Selection 1** (`business-context.md`): Collect new text for requested fields only. Add project → validate that project only, append to Projects table. Remove project → confirm and delete row. Update Stakeholders or Cross-Project Joins as requested.
- **Selection 2** (`metrics.md`): Add → run full Metric Loop, append. Replace → show current block, re-run loop, overwrite that block in place. Remove → confirm, delete the block; flag if metric is in `SKILL.md` description field. **Batch mode**: if the user selects multiple metrics to add/replace at once, collect all definitions first, then batch-validate all events and properties in one pass (call `Get-Events` once per project, `Get-Properties` once per project) before writing. Present a consolidated validation report like Quick Create.
- **Selection 3** (`breakdowns.md`): Add → validate new property, append. Update values → show current `known_values`, validate additions via `Get-Property-Values`. Remove → confirm, delete. **Batch mode**: if the user provides multiple properties at once, batch-validate all names and values in one pass before writing. Update Multi-Project Coverage table if relevant.
- **Selection 4** (`data-quality.md`): Only collect for sub-sections the user specifies (Instrumentation Gaps, Event Aliases, Default Exclusion Filters, Service Accounts, Data Lag). Append new entries, don't overwrite untouched sub-sections. **Validate any new property/value referenced in default_filters.**
- **Selection 5** (`query-conventions.md`): Show current values, ask which to change. Overwrite only the changed lines.
- **Selection 6** (`presentation.md`): Only change requested fields. Validate hex format, enum values. Overwrite only changed keys.

**Option 8 — Exit Without Saving**: Warn, then restore every file in `WORKING_SKILL_DIR` from `ORIGINAL_SNAPSHOT`. Return to Primary Menu.

After all selected edits: mark sections ✅, re-show edit menu so user can select more or choose option 7.

**Phase 5 — Re-finalization**

1. **Version bump**: Increment `skill_version` in the top-level `SKILL.md` YAML frontmatter (e.g., `"1.0"` → `"1.1"` for value/filter edits; `"2.0"` for adding/removing metrics or structural changes). Update `last_validated` to today's date.
2. **Description update**: If metrics were added/removed, ask if the user wants to regenerate the triggering description in `SKILL.md`. Yes → rewrite. No → leave as-is.
3. **Router check**: If new properties or metrics affect the Hard Rules in `SKILL.md` (e.g., new list-type breakdown), update the rules accordingly.
4. **Package**: Read and execute `references/packaging-instructions.md`.
5. **Changelog**: Diff `ORIGINAL_SNAPSHOT` against current files, **per file**. For each of the 7 files:
   - Classify as: ✅ Added / ✏️ Modified / ❌ Removed / — Unchanged
   - For Modified files, list specific items changed (metric names, property names, field-level diffs)
   - Display as a prioritised changelog grouped by file. Omit Unchanged files.
6. **Return to Menu**.

---

## Describe Flow

Read-only review of an existing skill folder with actionable improvement suggestions.

**Step D.1 — Discovery**: Read and execute `references/skill-discovery.md`. Sets `WORKING_SKILL_DIR`.

**Step D.2 — Summary**: Read all seven files. Show the Module 6 summary card (read-only).

**Step D.3 — Improvement Suggestions**

Evaluate across 6 dimensions. Only show dimensions with findings. Reference actual content (file names, metric names, property names, section headers) — never generic advice. Always cite which reference file the issue lives in.

**Dimension 1 — Completeness**: Are all 7 files present and non-empty? Check `last_validated` in `SKILL.md` — if missing or >90 days old, flag as ⚠️. Check that `SKILL.md` routing table actually points to existing files.

**Dimension 2 — Metric Quality** (`metrics.md`): For each metric:
- Has at least one exclusion filter? (unfiltered = test traffic included)
- Marked ✅ Validated?
- Notes field populated? (edge cases documented?)
- If ratio, are both numerator and denominator defined?

**Dimension 3 — Breakdown Coverage** (`breakdowns.md`): For each property:
- `known_values` has ≥3 entries?
- List-type property has `propertyType: 'list'` note?
- Validated?
- Missing obvious dimensions for customer type? (e.g., subscription product with no plan-tier)
- Multi-project skill: is the Multi-Project Coverage table populated?

**Dimension 4 — Data Quality Signals** (`data-quality.md`):
- `default_filters` empty? (queries will include test/internal traffic) — **🔴 critical**
- Mature product with empty `event_aliases`? (yellow flag)
- Service account section documented?
- Cross-project joins in `business-context.md` cover all multi-project metrics?

**Dimension 5 — Presentation & Brand** (`presentation.md`):
- All 3 colour fields populated with hex?
- `context_dependent: true` without format rules? (ambiguous)
- `primary_persona` and `tone` set to specific values? (not `mixed`/`not_specified`)
- For Indian enterprise: `large_number_format` = `lakh_crore`?

**Dimension 6 — SKILL.md Router**:
- Triggering description names customer explicitly?
- Description includes ≥3 metric names?
- Description has trigger phrases?
- Description under ~80 words?
- Routing table present and complete?
- Hard Rules section non-generic (specialised for this customer's actual properties)?

**Display**: Group findings by priority, with the file name in the heading:
- 🔴 High: Silently wrong query results (missing filters, unvalidated metrics, empty `default_filters` in `data-quality.md`)
- ⚠️ Medium: Reduced quality (sparse `known_values` in `breakdowns.md`, ambiguous format in `presentation.md`, vague audience)
- ℹ️ Low: Triggering accuracy in `SKILL.md`, documentation completeness

After displaying: *"Jump into Edit to address these, or just for reference?"*
- **Edit** → jump to Edit Flow Phase 2, skip discovery (skill already located)
- **Reference** → return to Primary Menu

---

## Resume Detection

At the start of any session, if the user says "continue", "resume", or references an in-progress skill:

1. Check `/home/claude/` for any directory matching `*-mixpanel-skill/`
2. Read `SKILL.md` from each candidate folder and look for `_wizard_state`
3. If found, show: *"Found an in-progress skill for [customer]. Modules complete: [list]. Resume from Module [N]?"*
4. If confirmed, jump to the appropriate module in the Create Flow
5. If not found, say so and show the Primary Menu
