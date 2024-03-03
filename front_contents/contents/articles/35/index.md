---
description: 'clasp 環境を Docker で作ってみたので、そのときの作業ログを以下に示す。  ## Clasp とは  GAS をローカルで開発するためのツール。  >
  公式リポジトリ: [google/clasp: 🔗 Command Line Apps Script Projects](https://github.com/google/clasp)  ##
  前準備: GAS API を有効化する ...'
posted_at: 2024-03-03 16:13:09+00:00
slug: '35'
tag_ids: []
title: Docker で clasp 環境を構築する
updated_at: 2024-03-03 16:27:08+00:00

---
clasp 環境を Docker で作ってみたので、そのときの作業ログを以下に示す。

## Clasp とは

GAS をローカルで開発するためのツール。

> 公式リポジトリ: [google/clasp: 🔗 Command Line Apps Script Projects](https://github.com/google/clasp)

## 前準備: GAS API を有効化する

ここから有効化できる: https://script.google.com/home/usersettings

## 用意するファイルとディレクトリ構造

ディレクトリ構造:

```
.
|-- .gitignore
|-- .env
|-- Dockerfile
|-- docker-compose.yml
```

.gitignore

```
.*
.*/

!.gitignore
```

.env:

- clasp はログインの credential 情報をコンテナ内のユーザの `$HOME` 直下に作成する（ [→参考](https://arc.net/l/quote/lbrrbdld) ）なので、 `$HOME` を `$WORKING_DIR` にするよう設定している
    - docker-compose.yml によってカレントディレクトリが `$WORKING_DIR` にマウントされる＝カレントディレクトリに credential 情報が書かれたドットファイルが置かれるが、 .gitignore で指定したドットファイル以外は gitignore するようにすることで誤 push を防いでいる

```
WORKING_DIR=/usr/src/app
HOME=$WORKING_DIR
```

Dockerfile:

- Node.js のバージョンは現時点（2024/03/04）で LST だった 20 系を採用した
- 依存関係は package.json ベースでの管理も考えたが、思いの外うまくいかず、「webpack 導入する？」みたいな話になって沼理想だったので、一旦 Dockerfile に直書きしてグローバルインストールすることにした

```
FROM node:20

RUN npm i -g typescript @google/clasp
```

docker-compose.yml:

```yml
version: '3'

services:
  app:
    build: .
    image: docker_clasp_image
    container_name: docker_clasp_container
    env_file:
      - .env
    volumes:
      - ./:$WORKING_DIR
    working_dir: $WORKING_DIR
    tty: true
```

## 環境構築手順

1. イメージビルド→コンテナ起動→コンテナ内に入る

```
$ docker compose build
$ docker compose up -d
$ docker exec -it <CONTAINER_ID> bash
```

2. clasp login

`--no-localhost` オプションをつけることで、リダイレクトが不要となる（ [→参考](https://arc.net/l/quote/wjrynyeg) ）。

```
[In the conatiner]# clasp login --no-localhost
```

① 出てきた URL にアクセス
② Google アカウントでログイン
③ `localhost:***` という無効な URL に遷移すれば OK
④ 別ターミナルでコンテナ内に入り、 curl 'localhost:***（さっきの無効な URL）'
⑤ ターミナルにログイン成功の旨が出ていればOK

補足:

- 最初のうちは②でアカウント選択のページが出てこなかった（要検証）
- ③について、どうやら `--no-localhost` オプションがうまく機能しないらしい（ [→参考](https://qiita.com/naoyeah/items/0db5fc82561020f2768e) ）。 curl を使った方法はその回避策

3. 指定した GAS プロジェクトを cloneする

```
[In the container]# clasp clone <PROJECT_ID>
```

## ローカルでの変更を GAS へ反映する

```
$ clasp push
```

## 参考記事

- [claspを使ってGoogle Apps Scriptの開発環境を構築してみた | DevelopersIO](https://dev.classmethod.jp/articles/vscode-clasp-setting/)
- [claspでGASをgithub管理する](https://zenn.dev/flutteruniv_dev/articles/8013785f70a2f4)
- [DockerとClaspとTypeScriptとGitHubを使ってGASをローカル開発する - おかしんワークス](https://okash1n.works/posts/developing-gas-with-typescript-docker-clasp-github/)
- [gasを管理するclaspのdocker環境を作成する #Docker - Qiita](https://qiita.com/rei-ta/items/61b3fde6a069b77d335d)
- [clasp login --no-localhost が使えない #GoogleAppsScript - Qiita](https://qiita.com/naoyeah/items/0db5fc82561020f2768e)
