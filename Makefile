all:
	@echo hi,

.PHONY: shell

shell:
	@nix develop

.PHONY: gotosocial mastodon

gotosocial:
	@process-compose -f gotosocial.yaml -p 8001

mastodon:
	@process-compose -e app/mastodon/.env.production -f mastodon.yaml -p 8002
