# Dashboard API — Gotchas & Constraints

Non-obvious behaviour the tool descriptions don't make clear. For tool
parameters and response shapes, rely on the tool descriptions themselves —
this file is only the knowledge those descriptions leave out.

## Contents

- Layout & structure limits
- Content rules for text cards
- Cross-project & duplication constraints
- Listing dashboards
- Reading layout for updates

---

## Layout & structure limits

- A dashboard holds at most **30 rows**, and each row at most **4 cells**
  (report or text). *(verify current — API-enforced.)*
- Every row needs at least one cell.
- Report cells require a `query_id` minted by a prior query run (run the
  query with results skipped). You cannot place a report without one.

## Content rules for text cards

- Only these HTML tags survive; everything else is stripped:
  `a, blockquote, br, code, em, h1, h2, h3, hr, li, mark, ol, p, s,
  strong, u, ul`. No `div`, `span`, `img`, or `table`. *(verify current.)*
- No newlines in the HTML — each element implicitly line-breaks. Use
  `<br>` for an explicit break.
- Keep `html_content` reasonably short (≤ ~2000 chars).

## Cross-project & duplication constraints

- Duplication is **same-project only** — there is no target-project
  parameter. Cross-project templating must *reconstruct* the board
  (see `commands/template-dashboard.md`).
- A `query_id` is only valid in the project it was minted in. Re-mint
  queries per target project when templating.

## Listing dashboards

- Prefer the richer, sortable entity-search capability when you need
  sorting or filtered results (title substring, most-recent timestamp).
- Fall back to the plain dashboard-list capability when you just need
  every board without filtering.
- The list operation does not return report counts — read a board's full
  layout to count report/text cells.

## Reading layout for updates

- Layout cell and row IDs are **opaque server-generated strings** — never
  construct them. Read the board's full layout first to get real IDs, and
  use temporary placeholder IDs only for newly-added rows/cells (the server
  assigns the real ones).
- Layout shape returned per board: rows, each carrying an ordered list of
  cells; each cell reports its type (`report` or `text`) plus its content
  (a report reference, or the text card's HTML). Preserve row grouping and
  cell order when reconstructing a board so the rebuild matches the source.
