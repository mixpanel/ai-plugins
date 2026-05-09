# Changelog

## May 2026 — Refresh & DRY pass

Refactor against the Mixpanel AI Plugins guidelines. No behavioural change for the user; substantial structural cleanup.

**Renamed:** `mxp-governor-tool` → `data-governance`.

**Structure:**
- `shared/` → `references/` (per Agent Skills spec convention).
- New `references/exclusions.md` — single source of truth for ignored events / properties; was duplicated across 4 commands.
- New `references/mcp-cheatsheet.md` — every MCP-specific quirk (chunk sizes, `add` vs `set`, single-resource-type bulk property writes, fallback paths).
- New `references/gotchas.md` — curated list of edge cases that have broken historically.
- New `assets/volume-ranking-query.json` — extracted from `schema-reader.md`. One file to update if the Run-Query payload schema changes.

**Flow:**
- Symmetric **Reset → Enrich** handoff added (matches the existing Score → Enrich handoff).
- New `(d) Export preview as JSON` option on the `enrich-and-tag` and `reset-lexicon` previews — supports compliance/audit workflows without committing writes.
- Per-run audit trail — every successful write command appends a one-line summary to `data-governance-runs/[timestamp]-[command].json`.
- Tag taxonomy in `enrich-and-tag` softened from a closed list to a default suggestion set (the agent may propose alternatives; the customer can override in the preview).

**SKILL.md:**
- Added `license: Apache-2.0` to frontmatter.
- Sharpened description (imperative voice; dropped "run the governor" implementation phrasing).
- Defined "clear command intent" in Step 0 routing via canonical trigger table.
- Global Rules split into Behavior / Mechanics for readability.

## April 2026 — Bulk property writes

Property metadata writes (`description`, `display_name`) now go through `Bulk-Edit-Properties` in chunks of 50 instead of per-call `Edit-Property` in batches of 10. Mixpanel's bulk property tool now exposes per-entry `description` and `display_name`, so the previous fallback is no longer needed.

Affected paths:
- **Enrich & Tag** — Step 4d (property metadata) is now bulk. ~5× faster on property-heavy projects.
- **Reset Lexicon** — Step 4c (clearing property descriptions / display names) is now bulk.

Bulk calls split by `resource_type` (`Event` vs `User`) since each call is single-type. If a bulk chunk fails, the flow falls back to per-property `Edit-Property` for that chunk only and continues.

No breaking changes. Command menu, prompts, previews, confirmations, and output formats are identical.
