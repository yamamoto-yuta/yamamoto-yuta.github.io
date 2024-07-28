.PHONY: new-content
new-content:
	@echo 'Enter article title (e.g. "my-new-article"):'
	@read TITLE; docker compose run --rm site hugo new content content/post/$$TITLE/index.md

.PHONY: server
server:
	docker compose run --rm --service-ports site hugo server --bind 0.0.0.0 --buildDrafts

.PHONY: server-prod
server-prod:
	docker compose run --rm --service-ports site hugo server --bind 0.0.0.0

.PHONY: build
build:
	docker compose run --rm site hugo --minify
