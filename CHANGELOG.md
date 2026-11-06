# Changelog

## mixpanel 1.1.0 — 2026-11-06

- Added an experimental V2 tracking journey split across `onboard-mixpanel`,
  `implement-mixpanel`, and `maintain-mixpanel-tracking`.
- Added a report-first greenfield flow that derives the minimum event schema
  from a confirmed value moment and verifies data before Lexicon/report writes.
- Retained `tracking-implementation` as the all-in-one control for the product
  onboarding experiment.
- Centralized the high-risk consent, identity, pipeline, runtime, schema, and
  verification invariants shared by the V2 implementation skills.

## mixpanel 1.0.0 — 2026-08-05

New general-purpose plugin: **`mixpanel`**.

- One plugin for all regions and access methods. An engine — Mixpanel MCP server (US/EU/India), the `mixpanel-headless` Python SDK, or the user's own integration — is set up per project with the new `install` skill.
- New `ENGINE.md` convention: skills describe Mixpanel actions in plain language, executed through the detected engine; no hardcoded tool names or URLs.
- All 11 skills migrated from `mixpanel-mcp` and decoupled from any specific engine.
- Legacy plugins `mixpanel-mcp`, `mixpanel-mcp-eu`, `mixpanel-mcp-in` are **retired**: removed from the marketplace and auto-migrated to `mixpanel` via the `renames` map (Claude Code ≥ 2.1.193); on older clients the old name reports `plugin-not-found` — update Claude Code or migrate manually (see README). Their source lives at tag `v0.1.1`; pin the marketplace with `claude plugin marketplace add mixpanel/ai-plugins@v0.1.1` to stay on the pre-restructure state.

## v0.1.1 — 2025-2026 (legacy, frozen)

- Three region-specific plugins, each bundling the Mixpanel MCP server for its region: `mixpanel-mcp` (US), `mixpanel-mcp-eu`, `mixpanel-mcp-in`.
- Skills: analyze-report, create-dashboard, deep-research, learn-mcp, manage-boards, manage-experiment, manage-feature-flags, manage-lexicon, monitor-metrics, prepare-ai-readiness, tracking-implementation.
- Frozen at git tag `v0.1.1`; no further changes.
