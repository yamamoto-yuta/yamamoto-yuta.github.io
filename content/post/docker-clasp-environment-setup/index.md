---
title: "Docker で clasp 環境を構築する"
description:
slug: docker-clasp-environment-setup
date: 2024-03-03T16:13:00Z
lastmod: 2024-03-24T12:07:00Z
image:
math:
license:
hidden: false
comments: true
draft: false
---

<font size="1" align="right">

[✏️ 編集](https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/blob/main/content/post/docker-clasp-environment-setup/index.md)

</font>

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
|-- docker-compose.yml
```

用意するファイル:

<details>
<summary>.gitignore</summary>

```
.*
.*/
node_modules/
dist/Code.gs

!.gitignore
!.*.sample
```

補足:

- `Code.gs` はビルド結果なので gitignore しておく

</details>

<details>
<summary>.env</summary>

```
WORKING_DIR=/usr/src/app
HOME=$WORKING_DIR
```

補足:

- clasp はログインの credential 情報をコンテナ内のユーザの `$HOME` 直下に作成する（ [→ 参考](https://arc.net/l/quote/lbrrbdld) ）ので、 `$HOME` を `$WORKING_DIR` にするよう設定している
  - docker-compose.yml によってカレントディレクトリが `$WORKING_DIR` にマウントされる＝カレントディレクトリに credential 情報が書かれたドットファイルが置かれるが、 .gitignore で指定したドットファイル以外は gitignore するようにすることで誤 push を防いでいる

</details>

<details>
<summary>docker-compose.yml</summary>

```yaml
version: "3"

services:
  app:
    image: node:20
    container_name: docker_clasp_container
    env_file:
      - .env
    volumes:
      - ./:$WORKING_DIR
    working_dir: $WORKING_DIR
    tty: true
```

</details>

## 環境構築手順

コンテナを起動して中に入る・

```
$ docker compose up -d
$ docker exec -it <CONTAINER_ID> bash
```

`yarn init` し、Clasp と TypeScript をインストールする。

```
[In the container]# yarn init -y
[In the container]# yarn add -D @google/clasp @types/google-apps-script typescript ts-loader
```

clasp にログインする。

```
[In the container]# yarn clasp login
① 出てきた URL にアクセス
② Google アカウントでログイン
③ localhost:*** という無効な URL に遷移すれば OK
④ 別ターミナルでコンテナ内に入り、 curl 'さっきの無効な URL'
⑤ ターミナルにログイン成功の旨が出ていればOK
```

<details>
<summary>補足: なぜ別ターミナルで curl する必要があるのか？</summary>

どうやら `clasp login` の `--no-localhost` オプションがうまく機能しないらしいため。

その回避策として別ターミナルで curl を叩く方法が紹介されていた（ [→ 参考](https://qiita.com/naoyeah/items/0db5fc82561020f2768e) ）。

今回、 `--no-localhost` オプションは使用していないが、同じ方法でログインできた。

</details>

<br />

今回は スクリプト ID が `<GAS_SCRIPT_ID>` の GAS プロジェクトのソースコードを `src/` ディレクトリに配置することにする。

そのため、まず `src/` ディレクトリを作成する。

```
[In the container]# mkdir src
```

指定したスクリプト ID の GAS プロジェクトのコードをローカルへ clone する。

```
[In the container]# yarn clasp clone <GAS_SCRIPT_ID>
```

clone 後、次の 3 ファイルが生成される。

```
.
|-- src/
|-- .clasp.json
|-- appsscript.json
|-- <YOUR_GAS_SCRIPT>.js
```

このうち、次の 2 ファイルを `src/` へ移動させる。

```
[In the container]# mv appsscript.json <YOUR_GAS_SCRIPT>.js src/
```

`.clasp.json` の `rootDir` を次のように変更する。

```diff
-     "rootDir": "/usr/src/app"
+     "rootDir": "/usr/src/app/src"
```

`clasp push` で、ローカルのコードを GAS 上へ反映させる。

```
[In the container]# yarn clasp push
```

Web 上の GAS エディタのページをリロードすると、ローカルのコードが反映されているはず。

## ES modules の利用

2024/03/18 現在、 GAS は ES modules に対応しておらず、 `import` などが使えない。

使えるようにする方法はいくつかあるようだが、今回は [gas-webpack-plugin](https://github.com/fossamagna/gas-webpack-plugin) を使ってみる。

Webpack と gas-webpack-plugin をインストール。

```
[In the container]# yarn add -D gas-webpack-plugin webpack webpack-cli
```

今回は `src/` のソースコードをビルドして `dist/` に置くことにする。

そのため、まず `dist/` を作成する。

```
[In the container]# mkdir dist/
```

続いて、 `appsscript.json` を `dist/` へ移動させる。

```
[In the container]# mv src/appsscript.json dist/
```

併せて、 `.clasp.json` の `rootDir` を次のように変更する。

```diff
-     "rootDir": "/usr/src/app/src"
+     "rootDir": "/usr/src/app/dist"
```

`webpack.config.js` を作成し、次の内容を設定する。

```js
const path = require("path");
const GasPlugin = require("gas-webpack-plugin");

module.exports = {
  context: __dirname,
  entry: "./src/index.ts",
  output: {
    path: path.join(__dirname, "dist"),
    filename: "Code.gs",
  },
  resolve: {
    extensions: [".ts", ".js"],
  },
  module: {
    rules: [
      {
        test: /\.[tj]s$/,
        use: "ts-loader",
        exclude: /node_modules/,
      },
    ],
  },
  plugins: [new GasPlugin()],
};
```

この時点で、次のようなディレクトリ構造になっているはず。

```
.
|-- /dist
|   |-- appsscript.json
|-- src/
|   |-- <YOUR_GAS_SCRIPT>.js
|-- .clasp.json
|-- webpack.config.js
```

`yarn webpack` でコードをビルドした後、 `clasp push` で、ローカルのコードを GAS 上へ反映させる。

```
[In the container]# yarn webpack --mode production
[In the container]# yarn clasp push
```

2026/03/29追記: `The 'files' list in config file 'tsconfig.json' is empty.` というエラーが出る場合、 `tsconfig.json` を作成すること。中身は次のようにする（ 型がインストールされていなくて、 `DripveApp` などが動かないため）。

```ts
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "CommonJS",
    "lib": [
      "ESNext"
    ],
    "types": [
      "google-apps-script"
    ],
    "esModuleInterop": true,
    "strict": true
  }
}
```


Web 上でローカルのコードが確認できたら OK 。

## サンプルコード

`clasp create` 等の際の動作確認用サンプルコードを以下に示す。

ディレクトリ構造:

```
.
|-- src/
|   |-- index.ts
|   |-- main.ts
```

index.ts

```ts
import { mainFunc } from "./main";

declare const global: any;

global.mainFunc = mainFunc;
```

main.ts

```ts
export const mainFunc = () => console.log("Hello World");
```

## TIPS

こんな感じで Makefile に `clasp push` 用コマンドを登録しておくと、 `make push` で GAS へ push できて楽。

Makefile

```Makefile
.PHONY: push
push:
	docker compose run --rm app bash -c "yarn webpack --mode production && yarn clasp push"
```

## 参考記事

- [clasp を使って Google Apps Script の開発環境を構築してみた | DevelopersIO](https://dev.classmethod.jp/articles/vscode-clasp-setting/)
- [clasp で GAS を github 管理する](https://zenn.dev/flutteruniv_dev/articles/8013785f70a2f4)
- [gas を管理する clasp の docker 環境を作成する #Docker - Qiita](https://qiita.com/rei-ta/items/61b3fde6a069b77d335d)
- [clasp login --no-localhost が使えない #GoogleAppsScript - Qiita](https://qiita.com/naoyeah/items/0db5fc82561020f2768e)
- [GAS + Typescript のいい感じのビルド環境を整える](https://zenn.dev/terass_dev/articles/a39ab8d0128eb1)
- [[初心者向け] GoogleAppsScript(GAS)の開発環境をインクリメンタルに構築(TypeScript / Module / Polyfill) #Docker - Qiita](https://qiita.com/cajonito/items/3a5c7da8965e28e485bf)
