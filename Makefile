.PHONY: up down restart logs ps first-run init patch reset-init shell wp

up:
	docker compose up -d

down:
	docker compose down

restart:
	docker compose restart

logs:
	docker compose logs -f

ps:
	docker compose ps

# Bring the stack up AND run the first-run data import in one go.
first-run: up
	@echo "Waiting a few seconds for wp-config.php to be generated..."
	@sleep 5
	docker compose --profile init run --rm wpcli

# Just (re-)run the import script (safe/no-op if already initialized).
init:
	docker compose --profile init run --rm wpcli

# Apply plugin patches only, without a full re-init (safe to run any time,
# even after the stack has already been initialized - see init.sh's
# `patch-only` branch, which bypasses the "already initialized" marker
# check that would otherwise short-circuit this).
patch:
	docker compose --profile init run --rm wpcli patch-only

# Delete the "already initialized" marker so the next `make init` re-imports.
reset-init:
	docker compose --profile init run --rm --entrypoint sh wpcli -c \
		"rm -f /var/www/html/wp-content/.initialized && echo marker removed"

shell:
	docker compose exec wordpress bash

# Run an arbitrary wp-cli command, e.g.:  make wp CMD="plugin list"
wp:
	docker compose --profile init run --rm --entrypoint wp wpcli \
		--path=/var/www/html --allow-root $(CMD)