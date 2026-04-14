# Packaging Instructions

Shared packaging logic used by both the Create flow (Super Master Step F.3) and the Edit flow (Master Edit Step E.3).

## Inputs

- `SKILL_DIR` — absolute path to the skill directory being packaged (e.g. `/home/claude/nykaa-mixpanel-skill` or `/tmp/nykaa-mixpanel-skill`)
- `CUSTOMER_SLUG` — the customer slug (e.g. `nykaa`, `swiggy-instamart`)

Derive `CUSTOMER_SLUG` from the directory name: strip `-mixpanel-skill` suffix.

## Steps

```bash
# 1. Copy skill-creator tooling to writable location (skip if /tmp/skill-creator already exists this session)
if [ ! -d /tmp/skill-creator ]; then
  cp -r /mnt/skills/examples/skill-creator /tmp/skill-creator
fi

# 2. Verify the packager script exists before proceeding
if [ ! -f /tmp/skill-creator/scripts/package_skill.py ]; then
  echo "ERROR: package_skill.py not found at /tmp/skill-creator/scripts/package_skill.py"
  echo "Check that /mnt/skills/examples/skill-creator/scripts/package_skill.py exists."
  exit 1
fi

# 3. Copy the skill directory to /tmp/ for packaging (skip if already there)
if [ ! -d /tmp/[CUSTOMER_SLUG]-mixpanel-skill ]; then
  cp -r [SKILL_DIR] /tmp/[CUSTOMER_SLUG]-mixpanel-skill
fi

# 4. Run the packager
cd /tmp/skill-creator
PYTHONPATH=. python scripts/package_skill.py \
  /tmp/[CUSTOMER_SLUG]-mixpanel-skill

# 5. Move the output .skill file to the outputs directory
mv /tmp/[CUSTOMER_SLUG]-mixpanel-skill.skill \
  /mnt/user-data/outputs/[CUSTOMER_SLUG]-mixpanel-skill.skill
```

After packaging, present the `.skill` file to the user with `present_files`.
