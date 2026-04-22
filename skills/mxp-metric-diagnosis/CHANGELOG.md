# Changelog

## 1.0.0 — 2026-04-22

Initial packaged release of `mxp-metric-diagnosis` for distribution.

### Included
- **`SKILL.md`** — skill entrypoint, step flow, and routing logic across
  the three commands.
- **`commands/metric-anomaly.md`** — point anomaly detection.
- **`commands/metric-drift.md`** — baseline drift detection.
- **`commands/metric-rca.md`** — root cause attribution on top of an
  existing anomaly or drift diagnosis.

### Requirements
- Mixpanel MCP connected in Claude.
- Optional: `mixpanel-dashboard-manager` for the post-diagnosis board
  append step.
