---
title: "Hugo+Stackテーマの導入メモ"
description:
slug: hugo-stack-theme-installation-notes
date: 2024-07-28T06:27:45Z
lastmod:
image:
math:
license:
hidden: false
comments: true
draft: false
---

今回、自分の github.io を [Hugo](https://gohugo.io/) に乗り換えた。テーマは [Stack](https://themes.gohugo.io/themes/hugo-theme-stack/) を選んだ。この記事では導入時のメモを残す。

なお、次の記事が大変参考になった。

<div class="iframely-embed"><div class="iframely-responsive" style="height: 140px; padding-bottom: 0;"><a href="https://miiitomi.github.io/p/hugo/" data-iframely-url="//iframely.net/b8MWdeU"></a></div></div><script async src="//iframely.net/embed.js"></script>

## Hugo のインストール

ローカルを汚したくなかったので Docker で環境構築を行うことにした。

apt install で入るが、そのままだとバージョンが古かったので、GitHub から最新版を取得してインストールした。

- `Dockerfile`

```Dockerfile
FROM ubuntu:latest

RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y \
    git \
    curl

RUN curl -L -o hugo_extended.deb https://github.com/gohugoio/hugo/releases/download/v0.129.0/hugo_extended_0.129.0_linux-arm64.deb \
    && apt-get install -y ./hugo_extended.deb \
    && rm hugo_extended.deb
```

- `docker-compose.yml`

```yaml
services:
  site:
    build: .
    image: hugo
    env_file:
      - ./.env
    volumes:
      - .:/$WORKING_DIR
    working_dir: /$WORKING_DIR
    ports:
      - "1313:1313"
    tty: true
```

> 公式ドキュメント: [Linux | Hugo](https://gohugo.io/installation/linux/#debian)

## Hugo の初回セットとアップ

基本的には公式ドキュメントの [Quickstart](https://gohugo.io/getting-started/quick-start/) の通りに進めた。

サイト名は `blog` に設定。

```
hugo site new blog
```

Stack テーマを submodule として追加。

```
cd blog/
git submodule add https://github.com/CaiJimmy/hugo-theme-stack/ themes/hugo-theme-stack
```

以後、Dockerfile 等は `blog/` にあったほうが都合が良いので移動。

```
cd ..
mv \
 .env \
 docker-compose.yml \
 Dockerfile \
 Makefile \
 blog/
```

Stack テーマは[サンプル](https://github.com/CaiJimmy/hugo-theme-stack/tree/master/exampleSite)を用意してくれているので、それをベースに作成。

```
cp -r \
 blog/themes/hugo-theme-stack/exampleSite/hugo.yaml \
 blog/themes/hugo-theme-stack/exampleSite/content \
 blog/themes/hugo-theme-stack/archetypes \
 blog/
```

元々あった `hugo.toml` は先ほどコピーした`hugo.yaml`に置き換わって不要になったので削除。

```
rm blog/hugo.toml
```

> 参考:
>
> - [Quick start | Hugo](https://gohugo.io/getting-started/quick-start/)
> - [Getting Started | Stack](https://stack.jimmycai.com/guide/getting-started)
> - [非エンジニアの初心者が Hugo(テーマ Stack)+GitHub Pages でブログを開設するまで](https://miiitomi.github.io/p/hugo/)

## ローカルでの確認

ここまでで一旦 Hugo+Stack テーマの導入は完了したので、ローカルで動作確認を行った。コマンドは Makefile にまとめた。Docker 環境だと`hugo server` 時に `--bind 0.0.0.0` を付けないと表示されないので注意。

```Makefile
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
```

## `hugo.yaml` の微調整

次の記事が参考になった。

> 参考:
>
> - [非エンジニアの初心者が Hugo(テーマ Stack)+GitHub Pages でブログを開設するまで](https://miiitomi.github.io/p/hugo/)
> - [miiitomi.github.io/config.yaml at main · miiitomi/miiitomi.github.io](https://github.com/miiitomi/miiitomi.github.io/blob/main/config.yaml)

## 日本語フォントの変更

漢字が中国語フォントになっていたので日本語フォントに変更した。変更方法は`layouts/partials/head/custom.html`を次の内容で作成することで行った。

- `layouts/partials/head/custom.html`

```html
<style>
  /* Overwrite CSS variable */
  :root {
    --ja-font-family: "游ゴシック体", "Yu Gothic", YuGothic, "ヒラギノ角ゴ Pro",
      "Hiragino Kaku Gothic Pro", "メイリオ", "Meiryo";
    --base-font-family: "Lato", var(--sys-font-family), var(--ja-font-family),
      sans-serif;
  }
</style>

<script>
  (function () {
    const customFont = document.createElement("link");
    customFont.href =
      "https://fonts.googleapis.com/css2?family=Merriweather:wght@400;700&display=swap";

    customFont.type = "text/css";
    customFont.rel = "stylesheet";

    document.head.appendChild(customFont);
  })();
</script>
```

> 参考:
>
> - [Custom Header / Footer | Stack](https://stack.jimmycai.com/config/header-footer#example-custom-font-family-for-article-content)
> - [非エンジニアの初心者が Hugo(テーマ Stack)+GitHub Pages でブログを開設するまで](https://miiitomi.github.io/p/hugo/)

## カスタムアイコンの追加

> 公式ドキュメント: [Custom Menu | Stack](https://stack.jimmycai.com/config/menu#add-custom-icon)

## 埋め込みリンクの対応（断念）

Hugo の [Shortcodes](https://gohugo.io/content-management/shortcodes/) を使ってはてなブログや Qiita のように簡単に埋め込みリンクを実現したかったが、想像以上に工数かかりそうだったのでので一旦 [iframely](https://iframely.com/try) で生成した DIV タグをそのまま貼り付けることにした。

> 参考:
>
> - [自サービスに埋め込みコード対応をする方法 #oEmbed - Qiita](https://qiita.com/blue_islands/items/33ee08bc73652893c413)

## デプロイ

GitHub Actions を使って GitHub Pages にデプロイするように設定した。ワークフローは次のとおり。コメントのある箇所が注意点。

```yaml
name: Deploy Hugo site to GitHub Pages

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: write # Required for deploying to GitHub Pages

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          submodules: true # Fetch Hugo themes

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v3
        with:
          hugo-version: "latest"
          extended: true # Use Hugo extended version

      - name: Build Hugo site
        run: hugo --minify

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v4
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_branch: gh-pages
          publish_dir: ./public
```

> 参考:
>
> - [peaceiris/actions-gh-pages: GitHub Actions for GitHub Pages 🚀 Deploy static files and publish your site easily. Static-Site-Generators-friendly.](https://github.com/peaceiris/actions-gh-pages?tab=readme-ov-file#getting-started)
