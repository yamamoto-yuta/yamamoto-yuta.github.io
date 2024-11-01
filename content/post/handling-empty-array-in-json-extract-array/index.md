---
title: "値が空配列の場合を考慮したJSON_EXTRACT_ARRAY"
description: 
slug: handling-empty-array-in-json-extract-array
date: 2024-11-01T15:02:19Z
lastmod:
image: 
math: 
license: 
hidden: false
comments: true
draft: false
---

<font size="1" align="right">

[✏️ 編集](https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/blob/main/content/post/handling-empty-array-in-json-extract-array/index.md)

</font>

BigQueryで `JSON_EXTRACT_ARRAY()` を使ってJSONの配列を展開する際、値が空配列の行が混じっているケースがある。

```json
[
    {"id": 1, "items": [10, 20, 30]},
    {"id": 2, "items": []}
]
```

これを無邪気に `JSON_EXTRACT_ARRAY()` すると、空配列の行が存在しないことになってしまう。

クエリ:

```sql
WITH

sample_data AS (
SELECT '{"id": 1, "items": [10, 20, 30]}' AS item_json
UNION ALL
SELECT '{"id": 2, "items": []}'
),

final AS (
SELECT
  JSON_EXTRACT_SCALAR(item_json, "$.id") AS id,
  item
FROM
  sample_data,
  UNNEST(JSON_EXTRACT_ARRAY(item_json, '$.items')) AS item
)

SELECT * FROM final
```

実行結果:

```
id	item
1	10
1	20
1	30
```

ChatGPT (chatgpt-4o-latest) に訊いてみたところ、要素数が0かどうかで処理を分けるという解決策を教えてくれた。

```sql
WITH

sample_data AS (
SELECT '{"id": 1, "items": [10, 20, 30]}' AS item_json
UNION ALL
SELECT '{"id": 2, "items": []}'
),

final AS (
-- サブクエリは使わない方が良いが、ここまで一気にやらないと下記のエラーが出てしまうため例外的に使っている
-- エラー文: Array cannot have a null element; error in writing field item_array
SELECT
  id,
  IFNULL(item, NULL) AS item
FROM
  (
    SELECT
      JSON_EXTRACT_SCALAR(item_json, "$.id") AS id,
      CASE
        WHEN ARRAY_LENGTH(JSON_EXTRACT_ARRAY(item_json, '$.items')) = 0 THEN ARRAY<STRING>[NULL]
        ELSE JSON_EXTRACT_ARRAY(item_json, '$.items')
        END AS item_array
    FROM
      sample_data
  ),
  UNNEST(item_array) AS item
)

SELECT * FROM final
```

結果:

```
id	item
1	10
1	20
1	30
2	
```

`Array cannot have a null element` なのに後続処理まで一気にやったら動くのは不思議な挙動だ…（BigQuery内部のクエリ最適化の都合だとは思うが…）。
