# Reference — Exclusions

Single source of truth for entities that the governor never reads, never scores, and never writes. Apply these filters **before** building any working set or gap list.

---

## Ignored events

| Pattern | Reason |
|---|---|
| `$ae_first_open`, `$ae_updated`, `$ae_session`, `$ae_iap`, `$ae_crashed` | Legacy auto-tracked mobile SDK events. Mixpanel-managed, customers cannot edit metadata. |
| `$session_start`, `$session_end` | Virtual events (project session definitions). Not physical events; have no Lexicon row. |

## Ignored properties

| Pattern | Reason |
|---|---|
| Any property whose name starts with `mp_` | Mixpanel-managed reserved property namespace. |
| Any property whose name starts with `$` | Mixpanel system properties. |

---

## How commands use this file

Each command starts with:

> *Apply exclusions per `references/exclusions.md` before building the working set or gap list. Excluded items must not appear in scores, suggestions, previews, or writes.*

If you change the exclusion list, change only this file. All commands inherit automatically.

---

## What is *not* excluded

- Custom events that happen to start with `$` are not auto-excluded — only the explicit `$ae_*`, `$session_start`, `$session_end` are. (Customers should not be naming custom events with `$` per Mixpanel guidance, but if they have, the governor still scores them.)
- Hidden or dropped events are *included* in the working set — they are part of hygiene scoring (e.g. zero-volume events not hidden is a flag).
