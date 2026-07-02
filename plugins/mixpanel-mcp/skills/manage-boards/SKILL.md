---
name: manage-boards
description: >
  Full lifecycle dashboard management for Mixpanel — create, template, clone, clean up,
  inventory, and update dashboards across projects and teams. ALWAYS use when a user asks
  to: create a dashboard, build a board, template or clone a dashboard, clean up stale
  dashboards, audit dashboards, list all dashboards, inventory boards, update or rename a
  dashboard, delete a dashboard, standardize boards across projects, or says anything like
  "create a board", "template this dashboard", "clone dashboard", "clean up dashboards",
  "dashboard inventory", "duplicate board", "update dashboard", "delete dashboard",
  "dashboard audit", "stale dashboards", "empty boards", "board management". Also trigger
  when dashboards are mentioned with "governance", "cleanup", "template", "onboarding",
  or "standardize". Do NOT use for A/B experiments (use `manage-experiment`), feature-flag
  rollouts (use `manage-feature-flags`), or Lexicon/event-and-property metadata cleanup (use
  `manage-lexicon`). Requires Mixpanel MCP.
compatibility: "Requires Mixpanel MCP (mcp.mixpanel.com or regional variants). No other connectors required."
---

# Manage Boards

Top-level router: validate project → route command → handle return.

This skill uses the **Mixpanel MCP only**. No other connectors are required or referenced.

---

## Execution Philosophy

**Silent execution.** Do not narrate steps, announce phases, or explain what you are about to do. Run the work, process results, present only final output. The user sees:
- Command menu (when needed)
- Confirmation prompts before destructive operations (delete, bulk cleanup)
- Progress indicators during batch operations
- Error messages
- Final output

Nothing else. No "Starting X...", no "I'll now fetch Y...", no "Let me analyze Z...". Just do the work and show the result.

---

## Step 0 — Project Validation

**Direct routing:** If the user's message contains a project ID AND a clear command intent (e.g. "create a dashboard in project 12345", "clean up dashboards in project 67890"), extract both, validate, and route directly — skip the menu.

**Project ID without command:** Validate and show menu.

**No project ID:** Ask which project. On 'list' → retrieve the accessible projects and show them in a table.

**Validation:**
1. Retrieve the list of accessible projects and match the ID. If found → `✅ [Project Name] ([project_id])`, proceed.
2. Not found → error, ask to re-enter or 'list'.

**MCP check:** If the project lookup fails because no Mixpanel capability is available → tell the user to connect the Mixpanel MCP, then stop.

---

## Command Menu

Show only when no direct command was inferred:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Manage Boards — [Project Name] ([project_id])
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1. Create Dashboard      — Build a new board from description
  2. Template Dashboard    — Clone a reference board to a new project
  3. Cleanup Dashboards    — Audit & remove stale/empty boards
  4. Dashboard Inventory   — Catalog all boards with metadata
  5. Duplicate Dashboard   — Copy a board within the same project
  6. Update Dashboard      — Modify metadata, rows, or layout
  7. Exit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

| Choice | Action |
|--------|--------|
| **1** | Read `commands/create-dashboard.md`, execute |
| **2** | Read `commands/template-dashboard.md`, execute |
| **3** | Read `commands/cleanup-dashboards.md`, execute |
| **4** | Read `commands/dashboard-inventory.md`, execute |
| **5** | Read `commands/duplicate-dashboard.md`, execute |
| **6** | Read `commands/update-dashboard.md`, execute |
| **7** | Exit |

---

## Return Handler

When a command completes → `✅ Done.` → re-display command menu. No re-validation.

---

## Session Context

Persist across commands within a session. **Cross-command reuse is mandatory** — never re-fetch what exists in session.

| Variable | Description |
|----------|-------------|
| `project_id` | Immutable after Step 0. |
| `project_name` | Display name. |
| `projects_list` | All accessible projects. |
| `dashboard_list_cache` | `dashboard_id → {title, description, last_modified, ...}` map. Report counts are NOT returned by the list operation — populate them from `dashboard_layout_cache` after reading a board's full layout. |
| `dashboard_layout_cache` | `dashboard_id → {layout, report_count, text_count, row_count}` map (populated on-demand). |

---

## Global Rules

1. **Silent execution.** No narration, no phase announcements. Only output: progress during batch writes, errors, confirmation prompts, and final results.
2. **Project ID immutable.** All work uses the confirmed `project_id` unless explicitly cross-project (template command).
3. **Surface MCP failures explicitly.** Never silently skip.
4. **Confirm before destructive ops.** Always preview + explicit user confirmation before: deleting a dashboard, bulk cleanup, or overwriting dashboard content.
5. **'exit' always valid.** Stop, discard uncommitted, return to menu.
6. **No per-command "what next" menus.** Commands return control here. The router shows the menu.
7. **Cross-project operations.** The template command is the only one that works across projects. It validates both source and target project IDs and reconstructs the board in the target project (see `commands/template-dashboard.md`).
8. **Validate every write before reporting success.** After any operation that mutates a board — create, update, duplicate, or a template rebuild — re-read the affected board *including its full layout* and confirm the result matches intent (expected row count, report/text cell counts, title/description). If the readback diverges, do NOT report `✅` — surface what landed vs. what was requested. Layout cells use opaque server-generated IDs, so a write can partially succeed silently; the readback is the only reliable confirmation. Refresh `dashboard_layout_cache` from this readback.
9. **Fetching the dashboard set.** Default to the sortable entity-search capability when listing dashboards — it returns richer metadata and supports sorting. Fall back to the plain dashboard-list capability only if search is unavailable. Cache the result in `dashboard_list_cache` and reuse it across commands rather than re-fetching.
10. **Shared constraints.** Layout limits, the text-card HTML whitelist, and other API gotchas live once in `references/mcp-tool-reference.md`. Command files point to it by name rather than restating.
