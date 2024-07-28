apt で入る
https://gohugo.io/installation/linux/#debian
が、そのままだとバージョンが古かったので、GitHub から最新版を取得してインストール
https://github.com/gohugoio/hugo/releases/tag/v0.129.0

初回構築は Quickstart の通り
https://gohugo.io/getting-started/quick-start/

https://stack.jimmycai.com/guide/getting-started

hugo site new blog
cd blog/
git submodule add https://github.com/CaiJimmy/hugo-theme-stack/ themes/hugo-theme-stack

cd ..
mv \
 .env \
 docker-compose.yml \
 Dockerfile \
 Makefile \
 blog/

cp -r \
 blog/themes/hugo-theme-stack/exampleSite/hugo.yaml \
 blog/themes/hugo-theme-stack/exampleSite/content \
 blog/themes/hugo-theme-stack/archetypes \
 blog/

rm blog/hugo.toml

[非エンジニアの初心者が Hugo(テーマ Stack)+GitHub Pages でブログを開設するまで](https://miiitomi.github.io/p/hugo/)

GitHub と Twitter しかアイコンがなかったのでこちらで追加
[Custom Menu | Stack](https://stack.jimmycai.com/config/menu#add-custom-icon)

漢字が中国語フォントになっていたので日本語フォントに変更
[Custom Header / Footer | Stack](https://stack.jimmycai.com/config/header-footer#example-custom-font-family-for-article-content)

埋め込み対応、Hugo 側で対応させたかったけど想像以上に工数かかりそうだったので iframely で生成した<div>タグをそのまま貼り付けることにした
[自サービスに埋め込みコード対応をする方法 #oEmbed - Qiita](https://qiita.com/blue_islands/items/33ee08bc73652893c413)

dc up -d

hugo server --bind 0.0.0.0
