.PHONY: setup check-legacy-frozen

FREEZE_TAG := v0.1.1
LEGACY_PLUGINS := mixpanel-mcp mixpanel-mcp-eu mixpanel-mcp-in

setup:
	git config core.hooksPath .githooks
	@echo "Git hooks configured."

check-legacy-frozen:
	@frozen_ok=1; \
	for plugin in $(LEGACY_PLUGINS); do \
		if ! git diff --quiet $(FREEZE_TAG) HEAD -- "plugins/$${plugin}/"; then \
			echo "ERROR: plugins/$${plugin}/ differs from $(FREEZE_TAG)."; \
			echo "Legacy plugins are frozen at $(FREEZE_TAG); changes belong in plugins/mixpanel/."; \
			frozen_ok=0; \
		fi; \
	done; \
	[ "$$frozen_ok" = "1" ]
	@echo "Legacy plugins are frozen at $(FREEZE_TAG)."
