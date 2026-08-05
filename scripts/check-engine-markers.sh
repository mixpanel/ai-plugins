#!/usr/bin/env bash
# Every skill in plugins/mixpanel/skills/ must declare its engine dependency
# with exactly one of two markers in the first 40 lines of SKILL.md:
#
#   > **Requires a Mixpanel engine.**     (resolve per ENGINE.md before acting)
#   > **No Mixpanel engine required.**    (skill never touches Mixpanel data)
#
# Default-require: a skill with neither marker FAILS, so new skills can't
# silently ship without engine resolution. See plugins/mixpanel/ENGINE.md.
set -euo pipefail

REQUIRED="Requires a Mixpanel engine."
EXEMPT="No Mixpanel engine required."
HEAD_LINES=40
fail=0

for skill_md in plugins/mixpanel/skills/*/SKILL.md; do
  head_content=$(head -n "$HEAD_LINES" "$skill_md")
  has_required=$(grep -cF "$REQUIRED" <<<"$head_content" || true)
  has_exempt=$(grep -cF "$EXEMPT" <<<"$head_content" || true)

  if [ "$has_required" -eq 0 ] && [ "$has_exempt" -eq 0 ]; then
    echo "ERROR: $skill_md declares no engine marker in its first $HEAD_LINES lines."
    echo "       Add '> **$REQUIRED** ...' (see ENGINE.md) or '> **$EXEMPT**'."
    fail=1
  elif [ "$has_required" -gt 0 ] && [ "$has_exempt" -gt 0 ]; then
    echo "ERROR: $skill_md declares BOTH engine markers — keep exactly one."
    fail=1
  fi
done

if [ "$fail" -eq 1 ]; then
  exit 1
fi
echo "All skills declare an engine marker."
