---
title: "BigQueryでdbtのfull-refreshを実行するときの挙動調査メモ"
description: 
slug: dbt-full-refresh-replace-statement
date: 2026-05-11T10:10:57Z
lastmod: 2026-05-11T10:10:57Z
image: 
math: 
license: 
hidden: false
comments: true
draft: false
---

<font size="1" align="right">

[✏️ 編集](https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/blob/main/content/post/dbt-full-refresh-replace-statement/index.md)

</font>

BigQueryでは、パーティション変更を伴う場合、 `REPLACE TABLE` 文は使えない。

dbtのfull-refreshは `CREATE OR REPLACE TABLE` 文でテーブルを置き換える。

したがって、incremental更新のdbtモデルで、パーティション変更を伴う変更を加えた場合、full-refresh実行時にエラーが発生する…ように思われるが、実はエラーにはならない。

なぜなら、dbtの内部処理で、 `REPLACE` 句が使えない場合はテーブル削除を行ってからテーブル作成を行うようになっているから。

> 参考: [コードからdbtを理解する](https://zenn.dev/analytics_eng/articles/f761b63b38ea08)

…ということに先日つまづいたので、その調査メモを残す。

## `REPLACE TABLE` 文の挙動

例えば、下記クエリで一度テーブルを作成したとする。

```sql
    CREATE OR REPLACE TABLE `YOUR_GC_PROJECT_ID.YOUR_DATASET.for_replace_test_table`
    PARTITION BY dt
    CLUSTER BY dt
    -- CLUSTER BY user_id -- Cannot replace a table with a different partitioning spec. Instead, DROP the table, and then recreate it. New partitioning spec is interval(type:day,field:dt) clustering(user_id) and existing spec is interval(type:day,field:dt) clustering(dt)

    AS

    SELECT DATE('2026-01-01') AS dt, 'user1' AS user_id, 'hogehoge' AS text
    UNION ALL
    SELECT DATE('2026-01-02') AS dt, 'user2' AS user_id, 'hogehoge' AS text
    UNION ALL
    SELECT DATE('2026-01-03') AS dt, 'user3' AS user_id, 'hogehoge' AS text
```

その後、次のようにクラスタリング対象のカラムを変更してテーブルを置き換えようとすると、エラーが発生する。

> [!NOTE]
>
> クラスタリング対象のカラム変更もパーティション変更を伴うんだ…。

```diff
    CREATE OR REPLACE TABLE `YOUR_GC_PROJECT_ID.YOUR_DATASET.for_replace_test_table`
    PARTITION BY dt
-   CLUSTER BY dt
+   CLUSTER BY user_id

    AS

    SELECT DATE('2026-01-01') AS dt, 'user1' AS user_id, 'hogehoge' AS text
    UNION ALL
    SELECT DATE('2026-01-02') AS dt, 'user2' AS user_id, 'hogehoge' AS text
    UNION ALL
    SELECT DATE('2026-01-03') AS dt, 'user3' AS user_id, 'hogehoge' AS text
```

発生したエラー:

```
Cannot replace a table with a different partitioning spec. Instead, DROP the table, and then recreate it. New partitioning spec is interval(type:day,field:dt) clustering(user_id) and existing spec is interval(type:day,field:dt) clustering(dt)
```

## dbtのincrementalモデルの挙動

### 初期状態

`seeds/raw_data.csv` :

```csv
dt,user_id,text
2026-01-01,user1,あけましておめでとうございます！今年もよろしくお願いします。
2026-01-01,user2,新年の抱負は何ですか？
2026-01-02,user1,今年はもっと運動を頑張りたいと思います。
2026-01-02,user2,私は新しい趣味を始めたいと思っています。
2026-01-03,user1,どんな趣味を始める予定ですか？
2026-01-04,user2,料理を始めたいと思っています。新しいレシピを試すのが楽しみです。
2026-01-05,user1,それは素晴らしいですね！私も料理が好きです。
2026-01-06,user2,どんな料理が得意ですか？
2026-01-07,user1,私は和食が得意です。特に寿司が好きです。
2026-01-07,user1,寿司を作るのは楽しいですよね！あなたはどんな料理が得意ですか？
```

`models/incremental_model.sql` :

```sql
{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by={
        "field": "dt",
        "data_type": "date",
        "granularity": "day"
    },
    cluster_by=['dt']
) }}

WITH

max_date AS (
    SELECT
        MAX(dt) AS max_dt
    FROM
        {{ ref('raw_data') }}
),

raw_data AS (
    SELECT
        dt,
        user_id
    FROM
        {{ ref('raw_data') }}
    {% if is_incremental() %}
    WHERE
        dt >= (SELECT max_dt FROM max_date) - 2
    {% endif %}
),

final AS (
    SELECT
        dt,
        user_id,
        COUNT(*) AS cnt
    FROM
        raw_data
    GROUP BY ALL
)

SELECT * FROM final
```

dbt seed コマンドで、シードデータをロードしておく。

```
$ dbt seed
```

### 初回実行

実行コマンド:

```
$ dbt run -s incremental_model
```

実行されたクエリ:

普通に `CREATE OR REPLACE TABLE` 文でテーブルが作成されている。

```sql

  
    

    create or replace table `YOUR_GC_PROJECT_ID`.`YOUR_DATASET`.`incremental_model`
      
    partition by dt
    cluster by dt

    
    OPTIONS()
    as (
      

WITH

max_date AS (
    SELECT
        MAX(dt) AS max_dt
    FROM
        `YOUR_GC_PROJECT_ID`.`YOUR_DATASET`.`raw_data`
),

raw_data AS (
    SELECT
        dt,
        user_id
    FROM
        `YOUR_GC_PROJECT_ID`.`YOUR_DATASET`.`raw_data`
    
),

final AS (
    SELECT
        dt,
        user_id,
        COUNT(*) AS cnt
    FROM
        raw_data
    GROUP BY ALL
)

SELECT * FROM final
    );
  
```

### 2回目実行

incremental更新をさせたいので、シードデータに行を追加しておく。

`seeds/raw_data.csv` に追加したレコード:

```diff
    dt,user_id,text
    2026-01-01,user1,あけましておめでとうございます！今年もよろしくお願いします。
    2026-01-01,user2,新年の抱負は何ですか？
    2026-01-02,user1,今年はもっと運動を頑張りたいと思います。
    2026-01-02,user2,私は新しい趣味を始めたいと思っています。
    2026-01-03,user1,どんな趣味を始める予定ですか？
    2026-01-04,user2,料理を始めたいと思っています。新しいレシピを試すのが楽しみです。
    2026-01-05,user1,それは素晴らしいですね！私も料理が好きです。
    2026-01-06,user2,どんな料理が得意ですか？
    2026-01-07,user1,私は和食が得意です。特に寿司が好きです。
    2026-01-07,user1,寿司を作るのは楽しいですよね！あなたはどんな料理が得意ですか？
+   2026-01-08,user2,寿司は美味しいですよね！私も大好きです。
+   2026-01-08,user1,今度一緒に寿司を食べに行きましょうか？
```

反映コマンド:

> [!NOTE]
> 
> 余談だが、dbt seed コマンドも初回実行と2回目実行で内部処理が少し違う模様。
>
> 参考: [コードリーディングで理解する dbt seed の仕組み](https://zenn.dev/finatext/articles/dbt-seed-how-it-works)

```
$ dbt seed
```

実行コマンド:

```
$ dbt run -s incremental_model
```

実行されたクエリ:

tmpテーブルを作った後、元のテーブルに対して、 `MERGE` 文で更新処理を行っている。

> [!NOTE]
> 
> この辺りの挙動については、次の記事でわかりやすく解説されている。
>
> 参考: [BigQuery で使える dbt incremental strategy 完全ガイド](https://belonginc.dev/members/kobori/posts/dbt-incremental-strategies/)

```sql


    
    
        -- generated script to merge partitions into `YOUR_GC_PROJECT_ID`.`YOUR_DATASET`.`incremental_model`
      declare dbt_partitions_for_replacement array<date>;

      
      
       -- 1. create a temp table with model data
        
  
    

    create or replace table `YOUR_GC_PROJECT_ID`.`YOUR_DATASET`.`incremental_model__dbt_tmp`
      
    partition by dt
    cluster by dt

    
    OPTIONS(
      expiration_timestamp=TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL 12 hour)
    )
    as (
      

WITH

max_date AS (
    SELECT
        MAX(dt) AS max_dt
    FROM
        `YOUR_GC_PROJECT_ID`.`YOUR_DATASET`.`raw_data`
),

raw_data AS (
    SELECT
        dt,
        user_id
    FROM
        `YOUR_GC_PROJECT_ID`.`YOUR_DATASET`.`raw_data`
    
    WHERE
        dt >= (SELECT max_dt FROM max_date) - 2
    
),

final AS (
    SELECT
        dt,
        user_id,
        COUNT(*) AS cnt
    FROM
        raw_data
    GROUP BY ALL
)

SELECT * FROM final
    );
  
      -- 2. define partitions to update
      set (dbt_partitions_for_replacement) = (
          select as struct
              -- IGNORE NULLS: this needs to be aligned to _dbt_max_partition, which ignores null
              array_agg(distinct date(dt) IGNORE NULLS)
          from `YOUR_GC_PROJECT_ID`.`YOUR_DATASET`.`incremental_model__dbt_tmp`
      );

      -- 3. run the merge statement
      

    merge into `YOUR_GC_PROJECT_ID`.`YOUR_DATASET`.`incremental_model` as DBT_INTERNAL_DEST
        using (
        select
        * from `YOUR_GC_PROJECT_ID`.`YOUR_DATASET`.`incremental_model__dbt_tmp`
      ) as DBT_INTERNAL_SOURCE
        on FALSE

    when not matched by source
         and date(DBT_INTERNAL_DEST.dt) in unnest(dbt_partitions_for_replacement) 
        then delete

    when not matched then insert
        (`dt`, `user_id`, `cnt`)
    values
        (`dt`, `user_id`, `cnt`)

;

      -- 4. clean up the temp table
      drop table if exists `YOUR_GC_PROJECT_ID`.`YOUR_DATASET`.`incremental_model__dbt_tmp`

  


    


    
```

### full-refresh実行

実行コマンド:

```
$ dbt run --full-refresh -s incremental_model
```

実行されたクエリ:

初回実行と全く同じクエリが実行されている。

```sql

  
    

    create or replace table `YOUR_GC_PROJECT_ID`.`YOUR_DATASET`.`incremental_model`
      
    partition by dt
    cluster by dt

    
    OPTIONS()
    as (
      

WITH

max_date AS (
    SELECT
        MAX(dt) AS max_dt
    FROM
        `YOUR_GC_PROJECT_ID`.`YOUR_DATASET`.`raw_data`
),

raw_data AS (
    SELECT
        dt,
        user_id
    FROM
        `YOUR_GC_PROJECT_ID`.`YOUR_DATASET`.`raw_data`
    
),

final AS (
    SELECT
        dt,
        user_id,
        COUNT(*) AS cnt
    FROM
        raw_data
    GROUP BY ALL
)

SELECT * FROM final
    );
  
```

### クラスタを変更して普通にrun

`models/incremental_model.sql` :

クラスタを変更している。

```diff
    {{ config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
            "field": "dt",
            "data_type": "date",
            "granularity": "day"
        },
-       cluster_by=['dt']
+       cluster_by=['user_id']
    ) }}

    WITH

    max_date AS (
        SELECT
            MAX(dt) AS max_dt
        FROM
            {{ ref('raw_data') }}
    ),

    raw_data AS (
        SELECT
            dt,
            user_id
        FROM
            {{ ref('raw_data') }}
        {% if is_incremental() %}
        WHERE
            dt >= (SELECT max_dt FROM max_date) - 2
        {% endif %}
    ),

    final AS (
        SELECT
            dt,
            user_id,
            COUNT(*) AS cnt
        FROM
            raw_data
        GROUP BY ALL
    )

    SELECT * FROM final
```

実行コマンド:

```
$ dbt run -s incremental_model
```

実行されたクエリ:

普通にincremental更新した時と同じクエリが実行されている。クラスタ変更も反映されておらず、元のクラスタのまま。

```sql


    
    
        -- generated script to merge partitions into `YOUR_GC_PROJECT_ID`.`YOUR_DATASET`.`incremental_model`
      declare dbt_partitions_for_replacement array<date>;

      
      
       -- 1. create a temp table with model data
        
  
    

    create or replace table `YOUR_GC_PROJECT_ID`.`YOUR_DATASET`.`incremental_model__dbt_tmp`
      
    partition by dt
    cluster by user_id

    
    OPTIONS(
      expiration_timestamp=TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL 12 hour)
    )
    as (
      

WITH

max_date AS (
    SELECT
        MAX(dt) AS max_dt
    FROM
        `YOUR_GC_PROJECT_ID`.`YOUR_DATASET`.`raw_data`
),

raw_data AS (
    SELECT
        dt,
        user_id
    FROM
        `YOUR_GC_PROJECT_ID`.`YOUR_DATASET`.`raw_data`
    
    WHERE
        dt >= (SELECT max_dt FROM max_date) - 2
    
),

final AS (
    SELECT
        dt,
        user_id,
        COUNT(*) AS cnt
    FROM
        raw_data
    GROUP BY ALL
)

SELECT * FROM final
    );
  
      -- 2. define partitions to update
      set (dbt_partitions_for_replacement) = (
          select as struct
              -- IGNORE NULLS: this needs to be aligned to _dbt_max_partition, which ignores null
              array_agg(distinct date(dt) IGNORE NULLS)
          from `YOUR_GC_PROJECT_ID`.`YOUR_DATASET`.`incremental_model__dbt_tmp`
      );

      -- 3. run the merge statement
      

    merge into `YOUR_GC_PROJECT_ID`.`YOUR_DATASET`.`incremental_model` as DBT_INTERNAL_DEST
        using (
        select
        * from `YOUR_GC_PROJECT_ID`.`YOUR_DATASET`.`incremental_model__dbt_tmp`
      ) as DBT_INTERNAL_SOURCE
        on FALSE

    when not matched by source
         and date(DBT_INTERNAL_DEST.dt) in unnest(dbt_partitions_for_replacement) 
        then delete

    when not matched then insert
        (`dt`, `user_id`, `cnt`)
    values
        (`dt`, `user_id`, `cnt`)

;

      -- 4. clean up the temp table
      drop table if exists `YOUR_GC_PROJECT_ID`.`YOUR_DATASET`.`incremental_model__dbt_tmp`

  


    


    
```

### 変更されたクラスタでfull-refresh

実行コマンド:

```
$ dbt run --full-refresh -s incremental_model
```

実行されたクエリ:

初回実行、full-refresh実行の時と同じクエリが実行されている。クラスタ変更は反映されている。

```sql

  
    

    create or replace table `YOUR_GC_PROJECT_ID`.`YOUR_DATASET`.`incremental_model`
      
    partition by dt
    cluster by user_id

    
    OPTIONS()
    as (
      

WITH

max_date AS (
    SELECT
        MAX(dt) AS max_dt
    FROM
        `YOUR_GC_PROJECT_ID`.`YOUR_DATASET`.`raw_data`
),

raw_data AS (
    SELECT
        dt,
        user_id
    FROM
        `YOUR_GC_PROJECT_ID`.`YOUR_DATASET`.`raw_data`
    
),

final AS (
    SELECT
        dt,
        user_id,
        COUNT(*) AS cnt
    FROM
        raw_data
    GROUP BY ALL
)

SELECT * FROM final
    );
  
```

INFORMATION_SCHEMA.JOBS_BY_PROJECTや監査ログで、テーブルを削除してそうなログを探してみたが、見つからなかった…（探し方が悪いのだろうか…）。

## コードリーディング

冒頭の記事でもコードリーディングの結果が貼られていたが、改めて自分でも読んでみる。

次の箇所で、 `adapter.is_replaceable()` で `REPLACE` 句が使えるかどうかを判定し、使えない場合は `adapter.drop_relation()` でテーブル削除を行っている。

```sql
  {% elif full_refresh_mode %}
      {#-- If the partition/cluster config has changed, then we must drop and recreate --#}
      {% if not adapter.is_replaceable(existing_relation, partition_by, cluster_by) %}
          {% do log("Hard refreshing " ~ existing_relation ~ " because it is not replaceable") %}
          {{ adapter.drop_relation(existing_relation) }}
      {% endif %}
      {%- call statement('main', language=language) -%}
        {{ bq_create_table_as(partition_by, False, target_relation, compiled_code, language) }}
      {%- endcall -%}


  {% else %}
```

> 引用: https://github.com/dbt-labs/dbt-adapters/blob/main/dbt-bigquery/src/dbt/include/bigquery/macros/materializations/incremental.sql#L116-L126

`adapter.is_replaceable()` の実装は次のようになっている。テーブルが存在しない場合や、テーブルのパーティション・クラスタリングの設定が変更されていない場合は `True` を返すようになっている。

```python
    def is_replaceable(
        self, relation, conf_partition: Optional[PartitionConfig], conf_cluster
    ) -> bool:
        """
        Check if a given partition and clustering column spec for a table
        can replace an existing relation in the database. BigQuery does not
        allow tables to be replaced with another table that has a different
        partitioning spec. This method returns True if the given config spec is
        identical to that of the existing table.
        """
        if not relation:
            return True


        try:
            table = self.connections.get_bq_table(
                database=relation.database, schema=relation.schema, identifier=relation.identifier
            )
        except google.cloud.exceptions.NotFound:
            return True


        return all(
            (
                self._partitions_match(table, conf_partition),
                self._clusters_match(table, conf_cluster),
            )
        )
```

> 引用: https://github.com/dbt-labs/dbt-adapters/blob/cb1b4a0b0758fd307dc21583bb3acfc78397a077/dbt-bigquery/src/dbt/adapters/bigquery/impl.py#L679-L704

`adapter.drop_relation()` の実装は次のようになっている。

```python
    def drop_relation(self, relation: BigQueryRelation) -> None:
        is_cached = self._schema_is_cached(relation.database, relation.schema)  # type:ignore
        if is_cached:
            self.cache_dropped(relation)


        conn = self.connections.get_thread_connection()


        table_ref = self.get_table_ref_from_relation(relation)


        # mimic "drop if exists" functionality that's ubiquitous in most sql implementations
        conn.handle.delete_table(table_ref, not_found_ok=True)
```

> 引用: https://github.com/dbt-labs/dbt-adapters/blob/cb1b4a0b0758fd307dc21583bb3acfc78397a077/dbt-bigquery/src/dbt/adapters/bigquery/impl.py#L246-L256


`conn.handle.delete_table()` の部分をもう少し追ってみる。

`BigQueryConnectionManager` が `open()` された時に `handle` へBigQueryクライアントをセットしている。

```python
    @classmethod
    def open(cls, connection):
        if connection.state == ConnectionState.OPEN:
            logger.debug("Connection is already open, skipping open.")
            return connection


        try:
            connection.handle = create_bigquery_client(connection.credentials)
            connection.state = ConnectionState.OPEN
            return connection


        except Exception as e:
            logger.debug(f"""Got an error when attempting to create a bigquery " "client: '{e}'""")
            connection.handle = None
            connection.state = ConnectionState.FAIL
            raise FailedToConnectError(str(e))
```

> 引用: https://github.com/dbt-labs/dbt-adapters/blob/cb1b4a0b0758fd307dc21583bb3acfc78397a077/dbt-bigquery/src/dbt/adapters/bigquery/connections.py#L189-L204

したがって、 `conn.handle.delete_table()` は、BigQueryクライアントの `delete_table()` メソッドを呼び出していることになる。

> 参考: [Package Methods (3.41.0)  |  Python client libraries  |  Google Cloud Documentation](https://docs.cloud.google.com/python/docs/reference/bigquery/latest/summary_method#google_cloud_bigquery_client_Client_delete_table_summary)

（であれば、監査ログにテーブル削除のログが残るはずなんだけどなぁ…）