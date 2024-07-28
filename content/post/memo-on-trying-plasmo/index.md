---
title: "Plasmo 触ってみたメモ"
description:
slug: "memo-on-trying-plasmo"
date: 2023-06-04T12:54:00Z
lastmod: 2023-07-17T12:54:00Z
image:
math:
license:
hidden: false
comments: true
draft: false
---

前から気になっていたブラウザ拡張機能の開発フレームワーク「Plasmo」を触ってみたので、その時のメモ。

基本的に下記の記事をなぞる形で触っていった。

> [ブラウザ拡張機能を作るための React フレームワーク『Plasmo』](https://zenn.dev/nado1001/articles/plasmo-browser-extension)

なので、ここでは上記記事をなぞった際につまづいた箇所や個人的な所感などについて記す。

## 環境構築を Docker でやってみた

ローカル環境がごちゃごちゃするのが個人的に嫌だったので、 Docker で環境構築してみた。

上記記事や公式ドキュメントには特に Docker についての言及は無かったが、 Node.js があれば十分だったので適当な Node.js のイメージを持ってこればいけるはず。

ちなみに、 Plasmo のシステム要件として Node.js が 16.14 以降であることが挙げられていた。

> Node.js 16.14.x or later  
> 引用: https://docs.plasmo.com/framework#system-requirements

ただ、 Node.js のリリースケジュールによると 16 系は今年（記事執筆時は 2023 年 6 月 4 日）の 9 月で End-of-life とのことだったので、今回は 18 系を使ってみることにした。

> Node.js のリリーススケジュール:  
> https://github.com/nodejs/Release#release-schedule

以上を踏まえて作成した `docker-compose.yml` が下記の通り:

```yml
version: "3"

services:
  app:
    image: node:18.16.0
    volumes:
      - .:/usr/src/app
    working_dir: /usr/src/app
    tty: true
```

Plasmo プロジェクトの作成は `docker compose run` コマンドを用いて下記で行える。なお、 Plasmo は pnpm コマンドの利用を推奨していたが、 Node.js のイメージにデフォルトで入っていなかったので今回はデフォルトで入っている npm コマンドで進めた。コマンド実行のためにコンテナが溜まっていかないよう `--rm` オプションを付けている。

```
$ docker compose run --rm app npm create plasmo
```

プロジェクト作成の際に色々訊かれたが、今回は拡張機能の名前を `learn-plasmo` にした以外は既定値で回答した。

Development server の起動も同様に下記のコマンドで行える。プロジェクトディレクトリ（ `learn-plasmo/` ）に移動する必要がある点に注意。

```
$ docker compose run --rm app bash -c "cd learn-plasmo && npm run dev"
```

記事中に Storage API を利用するためにパッケージを追加インストールするくだりがあるが、それも下記コマンドで行える:

```
$ docker compose run --rm app bash -c "cd learn-plasmo && npm install @plasmohq/storage react-hook-form"
```

他にも Messaging API を利用するためにも追加インストールのくだりがあったが、それも下記コマンドで行える:

```
$ docker compose run --rm app bash -c "cd learn-plasmo && npm install @plasmohq/messaging"
```

## つまづいた点メモ

- 「 [Storage を利用する](https://zenn.dev/nado1001/articles/plasmo-browser-extension#storage%E3%82%92%E5%88%A9%E7%94%A8%E3%81%99%E3%82%8B) 」のところでなぜか入力値が保存されなくてつまづいたが、一度 Production build で動かした後 Development server に戻ってきたらちゃんと保存されるようになった。原因は不明…（要検証）
- 「 [New Tab Page](https://zenn.dev/nado1001/articles/plasmo-browser-extension#new-tab-page) 」のところは自分が Vivaldi ユーザだったせいでそもそもカスタマイズできなかった
- ファイル変更時は「ホットリロードが走る → 拡張機能を再読み込み」の手順を踏むと反映される

## 個人的な所感

デフォルトで下記の機能が付いてるのが良かった:

- dev/prod のビルド分け
- ホットリロード

また、今回は試さなかったが下記の機能も良さそうだった:

- Chrome Web Store への自動デプロイ
- Google Analytics と連携できるっぽい（→ [公式ドキュメント](https://docs.plasmo.com/quickstarts/with-google-analytics) ）

メンテナンスもこまめにされてそうなので、これから拡張機能作るときは Plasmo 使うようにしてみようかな…
