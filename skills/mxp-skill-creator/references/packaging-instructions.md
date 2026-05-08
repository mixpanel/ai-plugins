# Packaging Instructions

Shared packaging logic used by both the Create flow (Finalization F.3) and the Edit flow (Phase 5 step 4).

## Inputs

- `SKILL_DIR` — absolute path to the skill folder being packaged (e.g. `/home/claude/nykaa-mixpanel-skill` or `/tmp/nykaa-mixpanel-skill`)
- `CUSTOMER_SLUG` — the customer slug (e.g. `nykaa`, `swiggy-instamart`)

Derive `CUSTOMER_SLUG` from the directory name: strip `-mixpanel-skill` suffix.

## Pre-flight Check — Folder Structure

Before packaging, verify the folder is well-formed. Skipping this risks shipping a half-written skill.

```bash
SKILL_DIR=[SKILL_DIR]

# Required files
required=(
  "$SKILL_DIR/SKILL.md"
  "$SKILL_DIR/references/business-context.md"
  "$SKILL_DIR/references/metrics.md"
  "$SKILL_DIR/references/breakdowns.md"
  "$SKILL_DIR/references/data-quality.md"
  "$SKILL_DIR/references/query-conventions.md"
  "$SKILL_DIR/references/presentation.md"
)

missing=0
for f in "${required[@]}"; do
  if [ ! -f "$f" ]; then
    echo "MISSING: $f"
    missing=1
  fi
done

if [ $missing -eq 1 ]; then
  echo "ERROR: Skill is incomplete. Cannot package."
  exit 1
fi

# SKILL.md must NOT contain _wizard_state (should have been deleted at finalization)
if grep -q "_wizard_state" "$SKILL_DIR/SKILL.md"; then
  echo "ERROR: SKILL.md still contains _wizard_state block. Run Finalization F.2 first."
  exit 1
fi

# SKILL.md description must NOT be the placeholder
if grep -q "\[TO BE COMPLETED\]" "$SKILL_DIR/SKILL.md"; then
  echo "ERROR: SKILL.md description is still the placeholder. Run Finalization F.1 first."
  exit 1
fi

echo "✅ Pre-flight check passed."
```

If any check fails, **stop** and surface the error to the user. Do not proceed to packaging.

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

# 3. Copy the skill folder to /tmp/ for packaging (skip if already there)
if [ ! -d /tmp/[CUSTOMER_SLUG]-mixpanel-skill ]; then
  cp -r [SKILL_DIR] /tmp/[CUSTOMER_SLUG]-mixpanel-skill
fi

# 4. Run the packager — it will recursively include the references/ subfolder
cd /tmp/skill-creator
PYTHONPATH=. python scripts/package_skill.py \
  /tmp/[CUSTOMER_SLUG]-mixpanel-skill

# 5. Move the output .skill file to the outputs directory
mv /tmp/[CUSTOMER_SLUG]-mixpanel-skill.skill \
  /mnt/user-data/outputs/[CUSTOMER_SLUG]-mixpanel-skill.skill
```

## Verification

After packaging, list the contents of the .skill file to confirm references/ is included:

```bash
unzip -l /mnt/user-data/outputs/[CUSTOMER_SLUG]-mixpanel-skill.skill
```

Expected listing should show all 7 files (SKILL.md + 6 reference files). If references/ is missing or empty, packaging failed silently — re-run from step 3.

After verification, present the `.skill` file to the user with `present_files`.
