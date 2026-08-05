#!/usr/bin/env bash
# Every skill in plugins/mixpanel/skills/ must declare in its SKILL.md
# frontmatter whether it needs a Mixpanel engine:
#
#   metadata:
#     engine-required: "true"    # or "false"
#
# Default-require: a skill without the tag FAILS, so new skills can't silently
# ship without deciding. When "true", the body's first 40 lines must also point
# the model at the engine convention (mention ENGINE.md and /mixpanel:install),
# since frontmatter metadata is not loaded into model context.
# See plugins/mixpanel/ENGINE.md.
set -euo pipefail

HEAD_LINES=40
fail=0

for skill_md in plugins/mixpanel/skills/*/SKILL.md; do
  # frontmatter = everything up to the second '---'
  frontmatter=$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "$skill_md")
  tag=$(grep -E '^[[:space:]]+engine-required:' <<<"$frontmatter" | sed -E 's/.*engine-required:[[:space:]]*"?([a-z]+)"?.*/\1/' || true)

  case "$tag" in
    true)
      head_content=$(head -n "$HEAD_LINES" "$skill_md")
      if ! grep -q "ENGINE.md" <<<"$head_content" || ! grep -q "/mixpanel:install" <<<"$head_content"; then
        echo "ERROR: $skill_md has engine-required: \"true\" but its first $HEAD_LINES lines"
        echo "       don't point at ENGINE.md and /mixpanel:install (the model never sees"
        echo "       frontmatter metadata — the body needs the pointer)."
        fail=1
      fi
      ;;
    false)
      ;;
    "")
      echo "ERROR: $skill_md is missing the engine tag. Add to frontmatter:"
      echo '         metadata:'
      echo '           engine-required: "true"   # or "false"'
      fail=1
      ;;
    *)
      echo "ERROR: $skill_md has engine-required: \"$tag\" — must be \"true\" or \"false\"."
      fail=1
      ;;
  esac
done

if [ "$fail" -eq 1 ]; then
  exit 1
fi
echo "All skills declare engine-required, and engine skills point at ENGINE.md."
