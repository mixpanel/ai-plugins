#!/bin/sh
# Detects the Mixpanel engine installed for the current project. Run from the project root.
# Prints exactly one line:
#   engine=mcp region=<us|eu|in> config=<file>
#   engine=headless version=<version>
#   engine=none
# See ENGINE.md for how skills use the result.

for f in .mcp.json .cursor/mcp.json; do
  [ -f "$f" ] || continue
  host=$(grep -o '[a-z-]*mcp[a-z-]*\.mixpanel\.com' "$f" | head -n 1)
  [ -n "$host" ] || continue
  case "$host" in
    mcp-eu.*) region=eu ;;
    mcp-in.*) region=in ;;
    *)        region=us ;;
  esac
  echo "engine=mcp region=$region config=$f"
  exit 0
done

version=$(python3 -c "import mixpanel_headless as mh; print(mh.__version__)" 2>/dev/null)
if [ -n "$version" ]; then
  echo "engine=headless version=$version"
  exit 0
fi

echo "engine=none"
