# Skill Discovery

Shared resolution logic used by both the Edit flow (Phase 1) and the Describe flow (Step D.1) to locate an existing customer skill.

## Input

Ask the user for a customer name, slug, or website. Accept any of:
- Customer name (e.g. "JioHotstar", "Swiggy Instamart")
- Skill file name (e.g. "jiohotstar-mixpanel-skill")
- Website (e.g. "nykaa.com", "app.cred.club")

## Slug Derivation

Derive `[slug]` from the user's input:
- Customer name → lowercase, spaces to hyphens (e.g. "Swiggy Instamart" → `swiggy-instamart`)
- Website → strip TLD and any subdomain (e.g. "nykaa.com" → `nykaa`, "app.cred.club" → `cred`)
- Skill file name → strip `-mixpanel-skill` suffix if present, use the remainder as slug

## Path Resolution

Check locations in this order:

| Priority | Path | Action if found |
|----------|------|-----------------|
| 1 | `/home/claude/[slug]-mixpanel-skill/SKILL.md` | Use directly as working copy |
| 2 | `/mnt/user-data/uploads/[slug]-mixpanel-skill.skill` | Unpack to `/tmp/`, then use |
| 3 | `/mnt/user-data/outputs/[slug]-mixpanel-skill.skill` | Unpack to `/tmp/`, then use |
| 4 | None found | Ask the user — see fallback below |

### Unpacking a `.skill` file

```bash
mkdir -p /tmp/[slug]-mixpanel-skill
unzip [path-to-.skill-file] -d /tmp/[slug]-mixpanel-skill
```

The unpacked SKILL.md will be at `/tmp/[slug]-mixpanel-skill/[slug]-mixpanel-skill/SKILL.md`.

### Fallback — file not found

Show:
> *"I couldn't find a skill for '[user input]' at the usual locations. Can you help me locate it?"*
> - *"(a) Provide the full path to the SKILL.md file"*
> - *"(b) Provide the full path to the .skill package"*
> - *"(c) The skill was built in a previous session — I'll need you to re-upload or paste the path"*
> - *"(d) Cancel — return to the main menu"*

If the user selects (d), read `SKILL.md` and re-show the Primary Menu.

Accept any path the user provides. If it's a `.skill` file, unpack it first using the steps above.

## Output

Store the resolved path as `WORKING_SKILL_PATH`. All subsequent reads and writes in this session use this path.
