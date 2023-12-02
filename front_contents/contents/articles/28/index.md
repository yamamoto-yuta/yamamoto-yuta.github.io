---
description: '※ この記事は、私が2021/06/25に書いたメモを転記したものです。  ---  ## 方法 - skickaを使う - rcloneを使う  ##
  skickaを使う ### skickaって何？ - Google ドライブをCLI上で操作できるツール  → [公式リポジトリ](https://github.com/google/skicka)  ###
  導入方法 - 基本的に[公式READ...'
posted_at: 2023-12-02 11:12:22+00:00
slug: '28'
tag_ids: []
title: GoogleドライブをCLIで操作する試み
updated_at: 2023-12-02 11:36:42+00:00

---
※ この記事は、私が2021/06/25に書いたメモを転記したものです。

---

## 方法
- skickaを使う
- rcloneを使う

## skickaを使う
### skickaって何？
- Google ドライブをCLI上で操作できるツール

→ [公式リポジトリ](https://github.com/google/skicka)

### 導入方法
- 基本的に[公式README](https://github.com/google/skicka#getting-started)通りでOK
- 2021/6/25現在、手順5の認証のところでエラーが出る（[issue514](https://github.com/prasmussen/gdrive/issues/514)）ので、次の記事の手順を実行して解決する
    - [skickaの『「Google でログイン」機能が一時的に無効』を一時的に解決する - Qiita](https://qiita.com/satackey/items/34c7fc5bf77bd2f5c633)
    - 公開ステータスが「テスト」のままだと `エラー 403: access_denied` が出るので、「本番環境にpush」しておくこと

### 導入してみた感想
- lsだけでも毎回3秒以上かかるので使い物にならない…何故…

### 参考記事
- [GDriveをCLIで使う　- skicka - - Qiita](https://qiita.com/sesame_apps/items/054fbc49d5a7da9679b7)
- [リンク等まとめ｜Google Driveをコマンドラインで扱う - Qiita](https://qiita.com/hann-solo/items/35668297d687e01c821f)

## rcloneを使う
- [Rclone](https://rclone.org/)
- [rcloneを使用したGoogle Driveのバックアップ - Qiita](https://qiita.com/kodai-saito/items/f7597392e470863c450e)



