.PHONY: sync-skills check-skills-sync

sync-skills:
	rsync -a --delete plugins/mixpanel-mcp/skills/ plugins/mixpanel-mcp-eu/skills/
	rsync -a --delete plugins/mixpanel-mcp/skills/ plugins/mixpanel-mcp-in/skills/

check-skills-sync:
	@for region in eu in; do \
		if ! diff -rq plugins/mixpanel-mcp/skills/ "plugins/mixpanel-mcp-$${region}/skills/" > /dev/null 2>&1; then \
			echo "ERROR: plugins/mixpanel-mcp-$${region}/skills/ is out of sync with plugins/mixpanel-mcp/skills/"; \
			echo "Run 'make sync-skills' to fix."; \
			exit 1; \
		fi; \
	done
	@echo "Skills are in sync."
