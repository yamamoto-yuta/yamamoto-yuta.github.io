.PHONY: new-content
new-content:
	@echo 'Enter article slug (e.g. "my-new-article"):'
	@read SLUG; \
	docker compose run --rm site hugo new content content/post/$$SLUG/index.md; \
	sed -i '' 's/{slug}/'"$$SLUG"'/g' content/post/$$SLUG/index.md

.PHONY: server
server:
	docker compose run --rm --service-ports site hugo server --bind 0.0.0.0 --buildDrafts

.PHONY: server-prod
server-prod:
	docker compose run --rm --service-ports site hugo server --bind 0.0.0.0

.PHONY: build
build:
	docker compose run --rm site hugo --minify

.PHONY: remove-theme
remove-theme:
	git submodule deinit -f themes/hugo-theme-stack # 登録解除
	git rm -f themes/hugo-theme-stack # ファイルを削除
	git config -f .gitmodules --remove-section submodule.themes/hugo-theme-stack # 設定ファイルから削除

.PHONY: add-theme
add-theme:
	git submodule add -f git@github.com:CaiJimmy/hugo-theme-stack.git themes/hugo-theme-stack
	cd themes/hugo-theme-stack && git reset --hard v3.29.0 # バージョン固定