all:
	@echo hi,

.PHONY: shell

shell:
	@nix develop

up:
	@bash bin/tmuxup

.PHONY: gotosocial mastodon

gotosocial:
	@process-compose -f gotosocial.yaml -p 8001

mastodon:
	@process-compose -e app/mastodon/.env.production -f mastodon.yaml -p 8002

misskey:
	@process-compose -f misskey.yaml -p 8003
