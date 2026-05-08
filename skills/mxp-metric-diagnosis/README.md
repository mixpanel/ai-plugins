# mxp-metric-diagnosis

A Claude skill for diagnosing a single Mixpanel metric — detect anomalies,
identify baseline drift, and attribute root cause across segments.

Built for Mixpanel CSAs, AMs, and analysts who need to answer *"what's going
on with this metric?"* in a structured, repeatable way rather than ad-hoc
dashboard clicking.

---

## What this skill does

Three focused commands, one per diagnostic question:

| Command           | Answers                               | Use when                                               |
| ----------------- | ------------------------------------- | ------------------------------------------------------ |
| `metric-anomaly`  | Is a recent point weird?              | Point spike/drop in an otherwise stable series         |
| `metric-drift`    | Has the baseline itself shifted?      | Slow movement over weeks/months, no single bad point   |
| `metric-rca`      | Where is the movement coming from?    | Runs *on top of* an anomaly or drift diagnosis         |

`metric-rca` does not perform detection on its own — it consumes the
diagnosis payload from a prior `metric-anomaly` or `metric-drift` run and
fans out across segmentation branches (component decomposition, default
properties, distinct_id outliers, calendar context).

---

## Requirements

- **Mixpanel MCP** connected in Claude (required).
- Access to the Mixpanel project containing the metric you want to diagnose.
- Optional: `mixpanel-dashboard-manager` skill for the post-diagnosis board
  append step. Without it, findings are returned inline.

---

## Install

1. Clone or download this folder into your skills repo.
2. Make sure the folder name stays as `mxp-metric-diagnosis` — the skill
   identity depends on it.
3. Ensure Claude has read access to the path (via your skills mount or
   repo sync mechanism).
4. In Claude, confirm the skill shows up in `<available_skills>` before
   triggering.

No install script, no dependencies. The skill is pure markdown + prompt
logic; execution happens through the Mixpanel MCP tools at runtime.

---

## How to trigger it

Use natural language — the skill triggers on phrases like:

- *"What's going on with conversion rate last week?"*
- *"Why did DAU drop on the 14th?"*
- *"Has our activation metric drifted this quarter?"*
- *"Run RCA on the checkout funnel — where is the movement coming from?"*

You can also paste a Mixpanel report or dashboard link and ask what's
happening with the metric.

Do **not** trigger for general portfolio health checks (use `weekly-pulse`)
or adoption reports (use `gtm-customer-intelligence`).

---

## Folder structure

```
mxp-metric-diagnosis/
├── SKILL.md              # Skill entrypoint — orchestration + step flow
├── README.md             # This file
├── CHANGELOG.md          # Version history
└── commands/
    ├── metric-anomaly.md # Point anomaly detection
    ├── metric-drift.md   # Baseline drift detection
    └── metric-rca.md     # Root cause attribution
```

---

## Typical flow

1. User describes a metric concern in natural language.
2. Skill routes to `metric-anomaly` or `metric-drift` based on the phrasing.
3. Diagnosis runs, returns a findings card + renders a visualizer widget.
4. User is asked once whether to save the diagnosis to a Mixpanel board.
5. If the user wants to go deeper, `metric-rca` runs on top and appends
   root-cause findings to the same board.

---

## License

Internal use. Not for public distribution.
