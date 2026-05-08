# Sync skills from the US plugin (source of truth) to EU and IN plugins.
sync-skills:
    rsync -a --delete plugins/mixpanel-mcp/skills/ plugins/mixpanel-mcp-eu/skills/
    rsync -a --delete plugins/mixpanel-mcp/skills/ plugins/mixpanel-mcp-in/skills/
