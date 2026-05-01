# Skill Discovery

Shared resolution logic used by both the Edit flow (Phase 1) and the Describe flow (Step D.1) to locate an existing customer skill.

Skills produced by this wizard are **folders**, not single files. Discovery resolves to a folder path containing `SKILL.md` and a `references/` subfolder.

## Input

Ask the user for a customer name, slug, or website. Accept any of:
- Customer name (e.g. "Music Dummy")
- Skill folder name (e.g. "musicdummy-mixpanel-skill")
- Website (e.g. "musicdummy.com")

## Slug Derivation

Derive `[slug]` from the user's input:
- Customer name → lowercase, spaces to hyphens (e.g. "Music Dummy" → `music-dummy`)
- Website → strip TLD and any subdomain (e.g. "music.com" → `music`, "app.music.com" → `music`)
- Skill folder name → strip `-mixpanel-skill` suffix if present, use the remainder as slug

## Path Resolution

Check locations in this order:

| Priority | Path | Action if found |
|----------|------|-----------------|
| 1 | `/home/claude/[slug]-mixpanel-skill/SKILL.md` | Use directly as working folder |
| 2 | `/mnt/user-data/uploads/[slug]-mixpanel-skill.skill` | Unpack to `/tmp/`, then use |
| 3 | `/mnt/user-data/outputs/[slug]-mixpanel-skill.skill` | Unpack to `/tmp/`, then use |
| 4 | None found | Ask the user — see fallback below |

For each path, validate that **both** of these exist before treating the skill as "found":
- `[skill-folder]/SKILL.md`
- `[skill-folder]/references/` (directory)

If either is missing, treat the skill as not found and fall through to the fallback prompt below.

### Unpacking a `.skill` file

```bash
mkdir -p /tmp/[slug]-mixpanel-skill-unpacked
unzip [path-to-.skill-file] -d /tmp/[slug]-mixpanel-skill-unpacked
```

The unpacked folder will be at `/tmp/[slug]-mixpanel-skill-unpacked/[slug]-mixpanel-skill/`. This is the `WORKING_SKILL_DIR`.

### Fallback — file not found

Show:
> *"I couldn't find a skill for '[user input]' at the usual locations. Can you help me locate it?"*
> - *"(a) Provide the full path to the skill folder (containing SKILL.md and references/)"*
> - *"(b) Provide the full path to the .skill package"*
> - *"(c) The skill was built in a previous session — I'll need you to re-upload or paste the path"*
> - *"(d) Cancel — return to the main menu"*

If the user selects (d), re-show the Primary Menu.

Accept any path the user provides. If it's a `.skill` file, unpack it first using the steps above.

## Output

Store the resolved **folder path** as `WORKING_SKILL_DIR`. All subsequent reads and writes in this session use:

- `[WORKING_SKILL_DIR]/SKILL.md`
- `[WORKING_SKILL_DIR]/references/business-context.md`
- `[WORKING_SKILL_DIR]/references/metrics.md`
- `[WORKING_SKILL_DIR]/references/breakdowns.md`
- `[WORKING_SKILL_DIR]/references/data-quality.md`
- `[WORKING_SKILL_DIR]/references/query-conventions.md`
- `[WORKING_SKILL_DIR]/references/presentation.md`
