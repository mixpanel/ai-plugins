# Reference — Gotchas

Things the agent will get wrong without being told. Add to this file every time a real failure surfaces a missing rule.

---

## Tag operations

- **`Bulk-Edit-Events` `tags` field is uniform across the events list** — if you want different tag sets per event, you must group events by identical target tag set and issue one bulk call per group. Mixing tags across events in a single call applies them all to all of them.
- **Always use `operation: "add"` in `enrich-and-tag`.** `"set"` clobbers tags added manually by the customer outside this tool. Use `"set"` only in `reset-lexicon` for explicit clearing.
- **`Rename-Tag` may error on merge** — when the target name already exists in the project. Fall back path: per-event `Edit-Event` to rewrite tag arrays, then `Delete-Tag(old)`. The atomic call is preferred when it works because it propagates server-side without per-event writes.

## Bulk property writes

- **`Bulk-Edit-Properties` is single-resource-type.** Always split gaps by `Event` vs `User` and issue two calls. The MCP will reject a mixed list.
- **Per-entry fields are partial.** Include only the fields that need updating. If `display_name` already exists on a property and you re-send it (even with the same value), it counts as a write and may overwrite case differences silently.

## Reads

- **`Get-Events` and `Get-Properties` return everything in bulk.** There is no per-entity detail tool — do not loop. If you find yourself looping `Get-Events` per event, stop and re-read `references/mcp-cheatsheet.md`.
- **Volume rank degrades gracefully.** If `Run-Query` fails twice, downstream commands run with `volume_rank_map = {}`. This is fine — severity scoring in `review-issues` skips the volume tiebreaker; the score report still renders.

## Writes & confirmations

- **Reset requires literal `CONFIRM`.** Case-sensitive. Do not accept `confirm`, `yes`, `y`, `confirmed`. Anything other than the exact string `CONFIRM` cancels the operation.
- **Fill-only-empty is a hard guarantee.** Before including a field in any `enrich-and-tag` write payload, check the field is currently null/empty in the session cache. There is no config flag to bypass this. Customers who want to regenerate must run `reset-lexicon` first.

## Exclusions

- **`mp_*` and `$`-prefixed properties are read-only via Mixpanel's UI** — writes will succeed at the MCP level but be ignored. Filter them out before building the working set, not after the write.
- **Custom events that happen to start with `$` are NOT auto-excluded.** Only the explicit list in `references/exclusions.md` is. If a customer has a custom `$myevent`, the governor scores it normally.

## Score sub-scores

- **The "Issues" sub-score depends on whether `review-issues` has been run in the session.** If `issues_list` is in session, sub-score is `max(0, 100 - (open_count × 2))`. If not, redistribute that 10% weight to the other six sub-scores. Do not show a `0/100` issues row if you don't have data.

## Session cache

- **Never re-fetch what already exists.** This is the single biggest reason a multi-command session feels slow. The schema-reader contract is explicit — check session, fetch only what's missing.
- **After any write command, update the session cache.** Otherwise a follow-up score will show stale gaps.

## Output

- **Do not narrate phases.** Customers see only previews, confirmations, progress lines, and final reports. No "I'll now fetch your events…" or "Let me analyze the score…" Just do the work.
