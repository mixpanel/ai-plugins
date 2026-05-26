# Command: my-flags

Personalized portfolio view of the flags the calling PM owns. Three
sections in one digest:

1. **Active** — flags currently mid-ramp, with time at current %.
2. **Stuck** — flags created more than N weeks ago, still under 100%,
   no recent state updates. Accountability nudge.
3. **Ready to retire** — flags at 100%, no active dashboard references,
   safe to archive.

Every archive recommendation goes through the approval gate. Never
auto-archive.

This is intentionally narrower than estate-wide governance — it's the
PM's accountability view, not the platform team's cleanup tool.

---

## Prerequisites

- Step 1 from `SKILL.md` (project resolution) must complete.
- No flag resolution needed — this command scopes by `creator_email`.

The calling user's email is used as the default `creator_email` filter.
If the PM wants to look at someone else's portfolio (peer review,
manager check-in), they can override with an explicit
`for <email>` parameter.

Connector and project ID come from `config.md`.

---

## Phase 1 — Pull the flag list

Call `List-Feature-Flags` with:

- `creator_email` = calling PM's email (or override)
- `include_archived` = false
- No status filter — we want everything the PM owns, then we classify
  locally.

Surface the count up front: "You own 14 active flags in this project."

If the count is zero, output a friendly empty-state and stop.

---

## Phase 2 — Hydrate state for each flag

For each flag, call `Get-Feature-Flag` and parse the rollout-state JSON
in the description field.

Classify based on state + flag config:

| State / Config | Classification |
|---|---|
| `status: "active"` or `"dry_run"`, current rollout % < 100 | **Active** |
| `status: "active"`, no `last_eval_at` update in > STUCK_THRESHOLD_WEEKS | **Stuck** |
| `status: "paused"` for > 1 week with no resume | **Stuck** (paused subtype) |
| Flag has no state blob (unmanaged) but rollout % > 0 and < 100 | **Stuck** (unmanaged subtype) |
| `status: "complete"` and rollout % = 100 | Candidate for **Ready to retire** — proceed to Phase 3 |
| `status: "complete"` and rollout % = 100, recently flipped (< 2 weeks) | **Active** (call this "newly complete" in the section) |

Thresholds come from `config.md` and can be tuned per project.

---

## Phase 3 — Dashboard reference check for retirement candidates

For each candidate **Ready to retire** flag, call `Search-Entities` to
find dashboards referencing the flag (by key or name).

If **any active dashboard** references the flag:
- Classify as **Active** instead. Surface the dashboard name in the
  output. Archiving would break those dashboards.

If **no dashboards** reference the flag:
- Confirm **Ready to retire**.

The `RETIRE_REQUIRES_NO_DASHBOARD_REFS` config flag controls this
behavior. Default is `true` — override only on explicit user request.

---

## Phase 4 — Compose the digest

Three sections, in order. Each row should fit on one line where
possible.

### Active

```markdown
### Active (5)
| Flag | Stage | Time at stage | Last verdict | Bound success metric |
|---|---|---|---|---|
| `india-checkout-cta-v2` | 25% (stage 2/4) | 1d 6h | Advance | `checkout_conversion_v2` (+4.9%) |
| `power-user-mobile-nav` | 50% (stage 3/4) | 2d 14h | Advance | `7d_retention` (+1.1%) |
| ... |
```

### Stuck

```markdown
### Stuck (3) — needs attention

**`onboarding-progress-bar`** — 10% rollout, no eval in 5 weeks
- Last verdict: Advance (5 weeks ago)
- Recommendation: re-invoke `run-rollout` to advance, or pause
  intentionally if no longer relevant.

**`pricing-page-redesign-v3`** — paused at 25% for 18 days
- Pause reason: `revenue_per_session` breach (-3.2% vs -2% threshold)
- Recommendation: investigate the breach with the pricing team. If
  resolved, `run-rollout` with explicit resume.

**`legacy-banner-suppress`** — unmanaged, 30% rollout, no metrics
- This flag was created outside `manage-flags`. No state blob.
- Recommendation: `attach-metrics` to retro-bind a measurement plan,
  or archive if the flag is no longer needed.
```

### Ready to retire

```markdown
### Ready to retire (2) — approval needed

| # | Flag | At 100% since | Dashboards | Last impact verdict |
|---|---|---|---|---|
| 1 | `holiday-promo-2025` | 142 days | None found | Clear win (Oct 2025) |
| 2 | `signup-cta-copy-v1` | 89 days | None found | Clear win (Mar 2026) |

**To archive:** reply `approve 1` / `approve 2` / `approve all` / `skip`.
The skill will re-fetch each flag to confirm no dashboard refs were
added since this scan, then `Update-Feature-Flag` with status="archived".
```

---

## Phase 5 — Archive approval gate

Standard approval pattern, identical posture to estate-wide cleanup
skills:

1. Skill produces a numbered list of retirement candidates.
2. User says one of:
   - `"approve all"` → archive every listed candidate.
   - `"approve 1, 3"` → archive only those numbered.
   - `"approve 1-N"` → archive the range.
   - `"skip"` or no response → archive nothing.
3. Before executing each archive, re-fetch the flag:
   - Check no new dashboards reference it.
   - Check `status` hasn't changed.
   - If either changed, skip that item with a clear note.
4. `Update-Feature-Flag(status="archived")` per approved item.
5. Report per-item success/failure.

Never batch-archive without explicit approval. Never assume silence is
approval.

---

## Output

A full run produces all three sections in one Markdown digest, plus
the approval gate prompt for retirement candidates. Format:

```markdown
# My Flags — <PM email> — Project <project_id>

You own **14 flags** in this project (excluding archived).

### Active (5)
[table]

### Stuck (3) — needs attention
[per-flag block with recommendation]

### Ready to retire (2) — approval needed
[table + approval prompt]
```

---

## What this command does NOT do

- **Audit other PMs' flags.** Default scope is the calling PM only.
  Override is explicit and one-shot — not silent.
- **Enforce naming conventions.** That's a platform-team concern, not
  PM accountability. Out of scope.
- **Auto-archive anything.** Every archive passes through the approval
  gate and a re-fetch confirmation.
- **Manage the metric catalog.** A flag pointing to a stale or broken
  metric is surfaced in `Stuck` for context, but metric cleanup itself
  isn't this skill's job.
- **Cross-project portfolio view.** Single-project scope. If the PM
  owns flags in multiple projects, they re-invoke per project.
