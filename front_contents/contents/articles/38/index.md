---
description: 'この前、 BigQuery で LEFT JOIN するクエリを書いていた時に少しつまづいたので、その時の調査結果を備忘録として残す（おそらく
  BigQuery に限らず SQL 全般の話だと思うので、記事タイトルは「SQL の」としている）。  ## 前提: 対象データ  次のような3つのテーブルを考える。    ##
  LEFT JOIN してみる①  この3つのテーブルを JOIN して、 `...'
posted_at: 2024-05-12 17:15:16+00:00
slug: '38'
tag_ids: []
title: SQL の LEFT JOIN の挙動についての調査メモ
updated_at: ''

---
この前、 BigQuery で LEFT JOIN するクエリを書いていた時に少しつまづいたので、その時の調査結果を備忘録として残す（おそらく BigQuery に限らず SQL 全般の話だと思うので、記事タイトルは「SQL の」としている）。

## 前提: 対象データ

次のような3つのテーブルを考える。

<img src='/static/images/articles/38/547c416a09bb8a977b555e5b31a498fc.webp' origin_url='https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/assets/55144709/62220c0c-8dae-4194-a2b5-d4a85cd65915' alt='image' />

## LEFT JOIN してみる①

この3つのテーブルを JOIN して、 `(item_key, item_code, shop_id)` の組み合わせテーブルを作ることを考える。

今回は次の3パターンの LEFT JOIN で実現してみる。

1. 次の順で LEFT JOIN する: <font color="lime">ItemShops</font> → <font color="deepskyblue">Shops</font>
2. 次の順で LEFT JOIN する: <font color="red">Items</font> → <font color="lime">ItemShops</font> → <font color="deepskyblue">Shops</font>
3. 次の順で LEFT JOIN する: <font color="lime">ItemShops</font> → <font color="deepskyblue">Shops</font> → <font color="red">Items</font>

### パターン1: ItemShops → Shops

<details><summary>クエリ</summary>

```sql
WITH

Items AS (
  SELECT 'xxx' AS item_key, 'aaa' AS item_code
  UNION ALL
  SELECT 'yyy', 'bbb'
),

ItemShops AS (
  SELECT 'aaa' AS item_code, 1 AS shop_id
  UNION ALL
  SELECT 'aaa', 2
  UNION ALL
  SELECT 'bbb', 1
  UNION ALL
  SELECT 'bbb', 2
),

Shops AS (
  SELECT 1 AS shop_id, 'xxx' AS item_key
  UNION ALL
  SELECT 2, 'yyy'
)

SELECT
  C.item_key,
  B.item_code,
  B.shop_id
FROM
  ItemShops B
LEFT JOIN
  Shops C USING(shop_id)
```
  
</details><br />

結果:

<img src='/static/images/articles/38/b0972363b8f0da6a1c34d328d565f750.webp' origin_url='https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/assets/55144709/f6321f56-cd6d-4865-ae5c-62b469502516' alt='image' />

`(item_key, item_code)` の組み合わせがおかしい行が出てしまうため、この JOIN 方法では実現できない。

### パターン2: Items → ItemShops → Shops

<details><summary>クエリ</summary>

```sql
WITH

Items AS (
  SELECT 'xxx' AS item_key, 'aaa' AS item_code
  UNION ALL
  SELECT 'yyy', 'bbb'
),

ItemShops AS (
  SELECT 'aaa' AS item_code, 1 AS shop_id
  UNION ALL
  SELECT 'aaa', 2
  UNION ALL
  SELECT 'bbb', 1
  UNION ALL
  SELECT 'bbb', 2
),

Shops AS (
  SELECT 1 AS shop_id, 'xxx' AS item_key
  UNION ALL
  SELECT 2, 'yyy'
)

SELECT
  A.item_key AS A_item_key,
  C.item_key AS C_item_key,
  B.item_code,
  B.shop_id,
FROM
  Items A
LEFT JOIN
  ItemShops B USING(item_code)
LEFT JOIN
  Shops C USING(shop_id)
```

</details><br />

結果:

<img src='/static/images/articles/38/483e9aa289665df100754be39c81f651.webp' origin_url='https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/assets/55144709/a1ec4eeb-e012-4f99-b7e1-60a7015b540e' alt='image' />

`A_item_key` （＝ `Items.item_key` ）を採用しないと対応がおかしくなる。

### パターン3: ItemShops → Shops → Items


<details><summary>クエリ</summary>

```sql
WITH

Items AS (
  SELECT 'xxx' AS item_key, 'aaa' AS item_code
  UNION ALL
  SELECT 'yyy', 'bbb'
),

ItemShops AS (
  SELECT 'aaa' AS item_code, 1 AS shop_id
  UNION ALL
  SELECT 'aaa', 2
  UNION ALL
  SELECT 'bbb', 1
  UNION ALL
  SELECT 'bbb', 2
),

Shops AS (
  SELECT 1 AS shop_id, 'xxx' AS item_key
  UNION ALL
  SELECT 2, 'yyy'
)

SELECT
  A.item_key AS A_item_key,
  C.item_key AS C_item_key,
  B.item_code,
  B.shop_id,
FROM
  ItemShops B
LEFT JOIN
  Shops C USING(shop_id)
LEFT JOIN
  Items A USING(item_code)
```

</details><br />

結果:

<img src='/static/images/articles/38/08295481be6e380400b123bcaa9f8524.webp' origin_url='https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/assets/55144709/e4ea918e-51b9-4bcb-9106-9c8de870a9c9' alt='image' />

パターン2と同じ。

##  LEFT JOIN してみる②

何らかの理由で `Items` テーブルに存在しない `item_key` が `Shops` テーブルに組まれている状況を考える。

<img src='/static/images/articles/38/645b0796c136fad9d53206ca18986af9.webp' origin_url='https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/assets/55144709/f5d45f9e-bb8c-4b71-b663-1410081d33c5' alt='image' />

`Shops.item_key = "yyy"` は `Items` テーブルに存在しない。

この状況で、先ほどと同じ3パターンの LEFT JOIN を行ってみる。


### パターン1: ItemShops → Shops

<details><summary>クエリ</summary>

```sql
WITH

Items AS (
  SELECT 'xxx' AS item_key, 'aaa' AS item_code
),

ItemShops AS (
  SELECT 'aaa' AS item_code, 1 AS shop_id
  UNION ALL
  SELECT 'aaa', 2
  UNION ALL
  SELECT 'bbb', 1
  UNION ALL
  SELECT 'bbb', 2
),

Shops AS (
  SELECT 1 AS shop_id, 'xxx' AS item_key
  UNION ALL
  SELECT 2, 'yyy'
)

SELECT
  C.item_key,
  B.item_code,
  B.shop_id
FROM
  ItemShops B
LEFT JOIN
  Shops C USING(shop_id)
```
  
</details><br />

結果:

<img src='/static/images/articles/38/41b0f2f5afee5220f72289cde697363a.webp' origin_url='https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/assets/55144709/38455cbd-9981-48ca-9682-4cd7a00f3c22' alt='image' />

存在しないはずの `item_key = "yyy"` の行が残っていたり、 `(item_key, item_code)` の組み合わせがおかしい行が存在していたりしており、適切な JOIN 方法ではないことがわかる。

### パターン2: Items → ItemShops → Shops

<details><summary>クエリ</summary>

```sql
WITH

Items AS (
  SELECT 'xxx' AS item_key, 'aaa' AS item_code
),

ItemShops AS (
  SELECT 'aaa' AS item_code, 1 AS shop_id
  UNION ALL
  SELECT 'aaa', 2
  UNION ALL
  SELECT 'bbb', 1
  UNION ALL
  SELECT 'bbb', 2
),

Shops AS (
  SELECT 1 AS shop_id, 'xxx' AS item_key
  UNION ALL
  SELECT 2, 'yyy'
)

SELECT
  A.item_key AS A_item_key,
  C.item_key AS C_item_key,
  B.item_code,
  B.shop_id,
FROM
  Items A
LEFT JOIN
  ItemShops B USING(item_code)
LEFT JOIN
  Shops C USING(shop_id)
```

</details><br />

結果:

<img src='/static/images/articles/38/2f8ce539b921df845ce2a8acbb261c87.webp' origin_url='https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/assets/55144709/047787b1-6a7e-46ba-9475-6ca1e3e6594a' alt='image' />

`A_item_key` （＝ `Items.item_key` ）の方を採用すれば、この JOIN 方法で OK 。


### パターン3: ItemShops → Shops → Items


<details><summary>クエリ</summary>

```sql
WITH

Items AS (
  SELECT 'xxx' AS item_key, 'aaa' AS item_code
),

ItemShops AS (
  SELECT 'aaa' AS item_code, 1 AS shop_id
  UNION ALL
  SELECT 'aaa', 2
  UNION ALL
  SELECT 'bbb', 1
  UNION ALL
  SELECT 'bbb', 2
),

Shops AS (
  SELECT 1 AS shop_id, 'xxx' AS item_key
  UNION ALL
  SELECT 2, 'yyy'
)

SELECT
  A.item_key AS A_item_key,
  C.item_key AS C_item_key,
  B.item_code,
  B.shop_id,
FROM
  ItemShops B
LEFT JOIN
  Shops C USING(shop_id)
LEFT JOIN
  Items A USING(item_code)
```

</details><br />

結果:

<img src='/static/images/articles/38/339abb7c13da6f68fa9d8633db605b45.webp' origin_url='https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/assets/55144709/643ba162-2c24-4bc3-9870-32f9a2dc87f4' alt='image' />

2行目については `A_item_key` （＝ `Items.item_key` ）の方を採用しないと `(item_key, item_code)` の組み合わせがおかしくなるが、 3~4 行目に `A_item_key IS NULL` の行ができてしまっている。

したがって、この JOIN 方法は適切ではない。

## 挙動の理解

上記挙動についての個人的な理解を以下に示す。

### LEFT JOIN してみる①

**パターン1: ItemShops → Shops**

<img src='/static/images/articles/38/5b2e93f30eb8fe0032d30dc9cf99aa2d.webp' origin_url='https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/assets/55144709/4e07765d-e3c6-44c7-9248-abbb711f5722' alt='image' />

**パターン2: Items → ItemShops → Shops**

<img src='/static/images/articles/38/69250eed7359f2b3ad624e658c014f2d.webp' origin_url='https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/assets/55144709/a4cf2a86-70ed-493d-b14b-b6203ab1127e' alt='image' />

**パターン3: ItemShops → Shops → Items**

<img src='/static/images/articles/38/a4bc9e0ca9538278fe0b0d2a9280975c.webp' origin_url='https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/assets/55144709/84303761-e916-4a1b-90b7-d7d7b8411fc3' alt='image' />

### LEFT JOIN してみる②

**パターン1: ItemShops → Shops**

「LEFT JOIN してみる①」と同じ

**パターン2: Items → ItemShops → Shops**

<img src='/static/images/articles/38/dcb49a484e99c69cc5cc56d51d092282.webp' origin_url='https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/assets/55144709/de93474e-1224-44ab-bf80-5f3351b4b87c' alt='image' />

**パターン3: ItemShops → Shops → Items**

<img src='/static/images/articles/38/9212c88e9c3936dde7c4a9d30a93f7c5.webp' origin_url='https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/assets/55144709/2c378990-4613-4f35-89b8-cb024e624e9a' alt='image' />

## 所感

LEFT JOIN するときは JOIN 順に気をつけよう（それはそう）


