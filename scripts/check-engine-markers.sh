#!/usr/bin/env bash
# Every skill in plugins/mixpanel/skills/ must declare in its SKILL.md
# frontmatter whether it needs a Mixpanel engine:
#
#   metadata:
#     engine: required    # or: optional, none
#
# Default-require: a skill without the tag FAILS, so new skills can't silently
# ship without deciding. When "required", the body's first 40 lines must carry
# the engine marker (mention /mixpanel:install), since frontmatter metadata is
# not loaded into model context. When "optional", the body must mention
# ENGINE.md (how to use the engine when present) but must not gate on one.
# See plugins/mixpanel/ENGINE.md.
set -euo pipefail

HEAD_LINES=40
fail=0

for skill_md in plugins/mixpanel/skills/*/SKILL.md; do
  # frontmatter = everything up to the second '---'
  frontmatter=$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "$skill_md")
  tag=$(grep -E '^[[:space:]]+engine:' <<<"$frontmatter" | sed -E 's/.*engine:[[:space:]]*"?([a-z]+)"?.*/\1/' || true)

  case "$tag" in
    required)
      head_content=$(head -n "$HEAD_LINES" "$skill_md")
      if ! grep -q "/mixpanel:install" <<<"$head_content"; then
        echo "ERROR: $skill_md has 'engine: required' but its first $HEAD_LINES lines"
        echo "       don't carry the engine marker (mention /mixpanel:install — the model"
        echo "       never sees frontmatter metadata; the body needs the marker)."
        fail=1
      fi
      ;;
    optional)
      head_content=$(head -n "$HEAD_LINES" "$skill_md")
      if ! grep -q "ENGINE.md" <<<"$head_content"; then
        echo "ERROR: $skill_md has 'engine: optional' but its first $HEAD_LINES lines"
        echo "       don't mention ENGINE.md (how to use the engine when configured)."
        fail=1
      fi
      ;;
    none)
      ;;
    "")
      echo "ERROR: $skill_md is missing the engine tag. Add to frontmatter:"
      echo '         metadata:'
      echo '           engine: required   # or: optional, none'
      fail=1
      ;;
    *)
      echo "ERROR: $skill_md has 'engine: $tag' — must be 'required', 'optional', or 'none'."
      fail=1
      ;;
  esac
done

if [ "$fail" -eq 1 ]; then
  exit 1
fi
echo "All skills declare an engine tag and carry their engine marker."
