.PHONY: setup sync-skills check-skills-sync

setup:
	git config core.hooksPath .githooks
	@echo "Git hooks configured."

sync-skills:
	@out_of_sync=0; \
	for region in eu in; do \
		if ! diff -rq plugins/mixpanel-mcp/skills/ "plugins/mixpanel-mcp-$${region}/skills/" > /dev/null 2>&1; then \
			echo ""; \
			echo "=== plugins/mixpanel-mcp-$${region}/skills/ differs from US source ==="; \
			diff -rq plugins/mixpanel-mcp/skills/ "plugins/mixpanel-mcp-$${region}/skills/" || true; \
			out_of_sync=1; \
		fi; \
	done; \
	if [ "$$out_of_sync" = "1" ] && [ "$(FORCE)" != "1" ]; then \
		echo ""; \
		echo "WARNING: The above changes in EU/IN will be overwritten by the US source."; \
		echo "If you meant to edit skills, edit plugins/mixpanel-mcp/skills/ instead."; \
		echo "To proceed anyway, run: make sync-skills FORCE=1"; \
		exit 1; \
	fi
	rsync -a --delete plugins/mixpanel-mcp/skills/ plugins/mixpanel-mcp-eu/skills/
	rsync -a --delete plugins/mixpanel-mcp/skills/ plugins/mixpanel-mcp-in/skills/
	@echo "Skills synced."

check-skills-sync:
	@for region in eu in; do \
		if ! diff -rq plugins/mixpanel-mcp/skills/ "plugins/mixpanel-mcp-$${region}/skills/" > /dev/null 2>&1; then \
			echo "ERROR: plugins/mixpanel-mcp-$${region}/skills/ is out of sync with plugins/mixpanel-mcp/skills/"; \
			echo "Run 'make sync-skills' to fix."; \
			exit 1; \
		fi; \
	done
	@echo "Skills are in sync."
