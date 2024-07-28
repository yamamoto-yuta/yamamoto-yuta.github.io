---
title: "GoogleドライブをCLIで使えるようにしてみる"
description:
slug: using-google-drive-via-cli
date: 2021-06-24T15:00:00Z
lastmod:
image:
math:
license:
hidden: false
comments: true
draft: false
---

## 方法

- skicka を使う
- rclone を使う

## skicka を使う

### skicka って何？

- Google ドライブを CLI 上で操作できるツール

→ [公式リポジトリ](https://github.com/google/skicka)

### 導入方法

- 基本的に[公式 README](https://github.com/google/skicka#getting-started)通りで OK
- 2021/6/25 現在、手順 5 の認証のところでエラーが出る（[issue514](https://github.com/prasmussen/gdrive/issues/514)）ので、次の記事の手順を実行して解決する
  - [skicka の『「Google でログイン」機能が一時的に無効』を一時的に解決する - Qiita](https://qiita.com/satackey/items/34c7fc5bf77bd2f5c633)
  - 公開ステータスが「テスト」のままだと `エラー 403: access_denied` が出るので、「本番環境に push」しておくこと

### 導入してみた感想

- ls だけでも毎回 3 秒以上かかるので使い物にならない…何故…

### 参考記事

- [GDrive を CLI で使う　- skicka - - Qiita](https://qiita.com/sesame_apps/items/054fbc49d5a7da9679b7)
- [リンク等まとめ｜ Google Drive をコマンドラインで扱う - Qiita](https://qiita.com/hann-solo/items/35668297d687e01c821f)

## rclone を使う

- [Rclone](https://rclone.org/)
- [rclone を使用した Google Drive のバックアップ - Qiita](https://qiita.com/kodai-saito/items/f7597392e470863c450e)
