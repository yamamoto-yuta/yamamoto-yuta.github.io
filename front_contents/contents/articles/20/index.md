---
description: '# Rust 版 lsi 導入メモ  ## コードはここ  > https://github.com/ShotaroKataoka/ls-Improved/tree/develop-rust-rewrite  ##
  Manual  1. 公式 GitHub の [Releases](https://github.com/ShotaroKataoka/ls-Improved/releases)
  ペー...'
posted_at: 2023-07-23 14:50:15+00:00
slug: '20'
tag_ids: []
title: Rust 版 ls-Improved 導入メモ
updated_at: ''

---
# Rust 版 lsi 導入メモ

## コードはここ

> https://github.com/ShotaroKataoka/ls-Improved/tree/develop-rust-rewrite

## Manual

1. 公式 GitHub の [Releases](https://github.com/ShotaroKataoka/ls-Improved/releases) ページからダウンロード
2. ダウンロードファイルを解凍して、lsi を使いたいディレクトリへ移動
3. `path/to/lsi-**` で動く

毎回 `path/to/lsi-**` と打つのは面倒くさいので alias を登録しておくと良い。

## apt

### 手順

PPA リポジトリ:

> https://github.com/ShotaroKataoka/ppa

1. GPG 鍵をダウンロード

```
curl -s --compressed "https://ShotaroKataoka.github.io/ppa/ubuntu/KEY.gpg" | gpg --dearmor | tee /etc/apt/trusted.gpg.d/ls_improved_ppa.gpg
```

2. PPA を追加

```
echo "deb [signed-by=/etc/apt/trusted.gpg.d/ls_improved_ppa.gpg] https://ShotaroKataoka.github.io/ppa/ubuntu ./" |  tee /etc/apt/sources.list.d/ls_Improved.list
```

3. インストール

```
apt-get update && apt-get install ls-improved
```

### 検証用環境

Dockerfile:

```
FROM ubuntu:20.04

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    curl \
    gpg
```

docker-compose.yml

```yml
version: "3.8"
services:
  ubuntu:
    build: .
    image: ubuntu-apt-install-sandbox
    container_name: ubuntu
    tty: true
```

### 参考記事

- [.deb ファイルをカスタマイズして、GitHub で PPA をホストして、Debian にインストールする方法（その 4: ホスティングした PPA から、パッケージを Debian にインストールする）｜ Ryo Nakano](https://note.com/ryonakano/n/na5bada77dff7)
- [gcloud CLI をインストールする  |  Google Cloud](https://cloud.google.com/sdk/docs/install?hl=ja)


