.PHONY: new-content
HOST_UID := $(shell id -u)
HOST_GID := $(shell id -g)

new-content:
	@echo 'Enter article slug (e.g. "my-new-article"):'
	@read SLUG; \
	docker compose run --rm --user "$(HOST_UID):$(HOST_GID)" site hugo new content content/post/$$SLUG/index.md && \
	sed 's/{slug}/'"$$SLUG"'/g' content/post/$$SLUG/index.md > content/post/$$SLUG/index.md.tmp && \
	mv content/post/$$SLUG/index.md.tmp content/post/$$SLUG/index.md

.PHONY: server
server:
	docker compose run --rm --user "$(HOST_UID):$(HOST_GID)" --service-ports site hugo server --bind 0.0.0.0 --buildDrafts

.PHONY: server-prod
server-prod:
	docker compose run --rm --user "$(HOST_UID):$(HOST_GID)" --service-ports site hugo server --bind 0.0.0.0

.PHONY: build
build:
	docker compose run --rm --user "$(HOST_UID):$(HOST_GID)" site hugo --minify

.PHONY: remove-theme
remove-theme:
	git submodule deinit -f themes/hugo-theme-stack # 登録解除
	git rm -f themes/hugo-theme-stack # ファイルを削除
	git config -f .gitmodules --remove-section submodule.themes/hugo-theme-stack # 設定ファイルから削除

.PHONY: add-theme
add-theme:
	git submodule add -f git@github.com:CaiJimmy/hugo-theme-stack.git themes/hugo-theme-stack
	cd themes/hugo-theme-stack && git reset --hard v3.29.0 # バージョン固定
	git submodule update --init --recursive
