# Sync skills from the US plugin (source of truth) to EU and IN plugins.
sync-skills:
    rsync -a --delete plugins/mixpanel-mcp/skills/ plugins/mixpanel-mcp-eu/skills/
    rsync -a --delete plugins/mixpanel-mcp/skills/ plugins/mixpanel-mcp-in/skills/

# Verify EU and IN skills are in sync with the US source of truth.
check-skills-sync:
    #!/usr/bin/env bash
    set -euo pipefail
    for region in eu in; do
        if ! diff -rq plugins/mixpanel-mcp/skills/ "plugins/mixpanel-mcp-${region}/skills/" > /dev/null 2>&1; then
            echo "ERROR: plugins/mixpanel-mcp-${region}/skills/ is out of sync with plugins/mixpanel-mcp/skills/"
            echo "Run 'just sync-skills' to fix."
            exit 1
        fi
    done
    echo "Skills are in sync."
