---
title: "Google SQLにおけるUNNEST方式による挙動の違い（カンマ結合 vs LEFT JOIN UNNEST）"
description:
slug: bqsql-lost-record-by-crossjoin
date: 2026-09-08T14:25:55Z
lastmod: 2026-09-08T14:25:55Z
image:
math:
license:
hidden: false
comments: true
draft: false
---

<font size="1" align="right">

[✏️ 編集](https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/blob/main/content/post/bqsql-lost-record-by-crossjoin/index.md)

</font>

配列カラムをUNNESTで展開する際、「カンマ結合（CROSS JOIN相当）」と「`LEFT JOIN UNNEST`」とで、配列が空配列 `[]` またはNULLの場合の挙動が異なる。ダミーデータで検証した。

## 検証クエリ

```sql
WITH dummy_data AS (
  SELECT 'group_a' AS group_id, 1 AS row_number, '[{"item":"a"},{"item":"b"}]' AS items
  UNION ALL
  SELECT 'group_a', 2, '[]' -- 空配列
  UNION ALL
  SELECT 'group_a', 3, NULL -- NULL
),

cross_join_unnest AS (
  SELECT
    group_id, row_number, item_order,
    JSON_VALUE(item_element, '$.item') AS item_value
  FROM
    dummy_data,
    UNNEST(JSON_EXTRACT_ARRAY(items)) AS item_element WITH OFFSET AS item_order
),

left_join_unnest AS (
  SELECT
    group_id, row_number, item_order,
    JSON_VALUE(item_element, '$.item') AS item_value
  FROM
    dummy_data
    LEFT JOIN UNNEST(JSON_EXTRACT_ARRAY(items)) AS item_element WITH OFFSET AS item_order
)

SELECT 'cross_join(comma)' AS join_type, row_number, item_order, item_value FROM cross_join_unnest
UNION ALL
SELECT 'left_join' AS join_type, row_number, item_order, item_value FROM left_join_unnest
ORDER BY join_type, row_number, item_order
```

## 結果

| join_type         | row_number | item_order | item_value |
| ----------------- | ---------- | ---------- | ---------- |
| cross_join(comma) | 1          | 0          | a          |
| cross_join(comma) | 1          | 1          | b          |
| left_join         | 1          | 0          | a          |
| left_join         | 1          | 1          | b          |
| left_join         | 2          | (NULL)     | (NULL)     |
| left_join         | 3          | (NULL)     | (NULL)     |

## 結論

- 配列が空配列 `[]`（`row_number=2`）またはNULL（`row_number=3`）の場合、カンマ結合UNNEST（CROSS JOIN相当）では**元テーブル側のレコード自体が結果から消失する**。
- `LEFT JOIN UNNEST`にすると、展開後のカラム（`item_order`/`item_value`）はNULLになるが、元テーブル側のレコードは残る。
- マスタテーブルなど、元テーブル側のレコードを欠落させたくない場合は`LEFT JOIN UNNEST`を使うべき。逆に、配列が必ず1要素以上あることが保証されている、あるいは空配列の行を意図的に除外したい場合はカンマ結合（CROSS JOIN相当）でも問題ない。
