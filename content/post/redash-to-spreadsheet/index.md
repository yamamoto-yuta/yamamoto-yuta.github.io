---
title: "Redash→スプレッドシートへの自動反映をやってみたメモ"
description: 
slug: redash-to-spreadsheet
date: 2025-07-07T03:31:49Z
lastmod: 2025-07-07T03:31:49Z
image: 
math: 
license: 
hidden: false
comments: true
draft: false
---

<font size="1" align="right">

[✏️ 編集](https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/blob/main/content/post/redash-to-spreadsheet/index.md)

</font>

記事タイトルの通り。

基本的に次の記事の通りにやれば行けた。

> [RedashのデータをGoogleスプレッドシートに自動で反映する方法 #redash - Qiita](https://qiita.com/yamaking/items/aa6ef37ec0f2b0b3de3d)

この記事では、実際にやってつまづいたところをメモする。

## スプレッドシート側で勝手に数値へ変換されてしまう

カラムの値が全部数値だったり `12e9` のように指数表記だったりすると、スプレッドシート側で勝手に数値変換されてしまう。その場合は Redash 側で先頭に `'` を入れると良い。スプレッドシートでは先頭に `'` が入ったセルは自動変換が走らずそのまま文字列として扱ってくれる。

MySQLの場合は次のように CONCAT してあげれば良い。

```sql
SELECT
    CONCAT('''', col) AS col,
FROM
    table
```

ちなみに表示形式を「書式なしテキスト」にするのは意味がなかった（普通に数値へ変換されてしまった）。

## クエリに変更を加えた場合の更新手順

1. Redash側で save -> execute して、API keyのURLで取ってこれるデータを更新
2. スプレッドシートのIMPORTDATA関数を一度消して再設定
