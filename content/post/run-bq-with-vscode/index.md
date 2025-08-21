---
title: "VSCodeでBigQuery実行環境を整える"
description: 
slug: run-bq-with-vscode
date: 2024-12-29T04:49:32Z
lastmod: 2024-12-29T04:49:32Z
image: 
math: 
license: 
hidden: false
comments: true
draft: false
---

<font size="1" align="right">

[✏️ 編集](https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/blob/main/content/post/run-bq-with-vscode/index.md)

</font>

## （2025/08/21追記）リポジトリにまとめた

https://github.com/yamamoto-yuta/vscode-bigquery-env

## やろうと思った理由

GitHub Copilotで書かせたクエリをBQコンソールへコピペするのも面倒になってきたため。

## やった方法

### ディレクトリ構成

```
.
|-- .vscode/
|   |-- extensions.json
|   |-- settings.json
|
|-- queries/
|   |-- <YOUR_PROJECT_DIR_1>/
|   |   |-- <YOUR_QUERY_1>.bqsql   // BQのクエリは拡張子を.bqsqlにすること
|   |   |-- ...
|   |
|   |-- ...
|
```

### extensions.json

```json
{
    "recommendations": [
        "minodisk.bigquery-runner", // BigQuery runner
        "shinichi-takii.sql-bigquery", // SQL syntax highlighting
    ]
}
```

### settings.json

```json
{
    "bigqueryRunner.projectId": "YOUR_PROJECT_ID_1", // デフォルトの請求先プロジェクト。アドホック用途でスロットに上限が設定されているプロジェクトなどがあればそれを設定すると良い
    "bigqueryRunner.tree.projectIds": [
        "YOUR_PROJECT_ID_2", // よくテーブルを見に行くプロジェクトがあればここに追加しておくと、VSCodeからツリーで見れて便利
        ...
    ],
    "[sql-bigquery]": {
        "editor.tabSize": 2
    },
    // （お好みで）.bqsqlファイルをデータベースアイコンにする
    "material-icon-theme.files.associations": {
        "*.bqsql": "database"
    }
}
```

### その他、工夫点など

linterやformatterはあえて設定していない。当初は設定していたが、フォーマット結果が気に入らないことが多かったので…。

## 実際やってみての感想

一時クエリを保存しておけるため、分析業務中に別の分析業務が割り込んできた時の切り替えと作業復帰がしやすくなった。WebのBQコンソールだとクエリを保存しない限りは適当なタイミングで消えてしまって切り替えが面倒だったので、これはかなり助かっている。加えて、プロジェクトごとにフォルダを分けておけば、並行している分析業務の数が増えても切り替えやすいので、これも助かっている（そもそも並列数を増やさないようにするのが理想だが…）。

ただ、クエリ結果をスプレッドシートに出力してピボットテーブルなどで集計することが多かったので、VSCode上だとその操作ができないのが少し不便。現状はWebのBQコンソールから個人の実行履歴を見に行くことでカバーしている。まぁ毎回スプレッドシートへの出力を行っているわけではないので、意外とそこまで不便さは感じていない（どっかで見るべき実行履歴を間違えて事故りそう、というのはある）。この辺りは自力でなんとかなりそうだったらcontributeしてみようかな…。

## 参考

- [VSCode ＋ BigQuery ＋ SQLFluff の環境構築](https://zenn.dev/yuichi_dev/articles/ba5c376c955e52)
- [BigQuery Runner for VSCode の紹介](https://zenn.dev/minodisk/articles/418c4ea7aee79e)
- [VSCodeでSQLフォーマットするなら「SQL Formatter VSCode」で決まり！ #VSCode - Qiita](https://qiita.com/the_red/items/98b15aff395c6fc8a8aa)
