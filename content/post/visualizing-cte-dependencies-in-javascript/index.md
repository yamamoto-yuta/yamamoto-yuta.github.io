---
title: "SQL の CTE の依存関係を JavaScript で可視化してみる"
description:
slug: visualizing-cte-dependencies-in-javascript
date: 2024-02-25T11:53:00Z
lastmod:
image:
math:
license:
hidden: false
comments: true
draft: false
---

## やったこと

次の記事で実装されていた SQL の CTE を可視化するツールが便利だった。

https://note.com/dd_techblog/n/n3876f38cc5fc

ただ、記事では Python で実装されており、ツールを使うにはサーバを建てる必要があり少し面倒だった。なので、 GitHub Pages からサクッと使えるよう JavaScript で実装し直してみた。

次のリンクから実際に触れる。

> https://yamamoto-yuta.github.io/sql-cte-visualizer-js/

---

以下、試行錯誤したときのメモ

## Python → JavaScript への実装

[先の記事](https://note.com/dd_techblog/n/n3876f38cc5fc) を自分で動かしてみた。そのときの GitHub リポジトリがこちら:

https://github.com/yamamoto-yuta/sql-cte-visualizer?tab=readme-ov-file

この中の `main.py ` コピーし、 ChatGPT へ「 JavaScript で書き直して」と指示することで、実装の叩きを作った。というか、可視化の部分以外はこれでいけた。

## SQL パーサーを用いたアプローチ

実は当初は記事にある正規表現ではなく SQL パーサーを用いた方法を検討していた。理由は ChatGPT に投げた際に Python → JavaScript の変換で正規表現部分がうまくいかなかったため（後にうまくいくことがわかったため、正規表現を用いた方法に戻した）。

その際、 SQL パーサーは「 [node-sql-parse](https://github.com/taozhi8833998/node-sql-parser) 」というライブラリを採用した。

https://github.com/taozhi8833998/node-sql-parser

（SQL パーサーの選定には次の記事が参考になった）

https://zenn.dev/carenet/articles/d42b236ae69bc5

node-sql-parser でのパースの例を以下に示す。

<details><summary>SQL</summary>

```sql
-- 複数のCTEの定義
WITH DepartmentSummary AS (
    SELECT
        department_id,
        department_name,
        COUNT(*) AS employee_count
    FROM
        departments
    GROUP BY
        department_id, department_name
),
ProjectSummary AS (
    SELECT
        project_id,
        project_name,
        COUNT(*) AS member_count
    FROM
        projects
    GROUP BY
        project_id, project_name
)

-- 複数のCTEとJOINを使用したクエリ
SELECT
    e.employee_id,
    e.employee_name,
    e.role,
    d.department_name,
    d.employee_count,
    p.project_name,
    p.member_count
FROM
    employees e
JOIN
    DepartmentSummary d ON e.department_id = d.department_id
LEFT JOIN
    employee_projects ep ON e.employee_id = ep.employee_id
LEFT JOIN
    ProjectSummary p ON ep.project_id = p.project_id;
```

</details>

<details><summary>パース結果</summary>

```json
[
  {
    "type": "select",
    "as_struct_val": null,
    "distinct": null,
    "columns": [
      {
        "expr": {
          "type": "column_ref",
          "table": "e",
          "column": "employee_id",
          "subFields": []
        },
        "as": null
      },
      {
        "expr": {
          "type": "column_ref",
          "table": "e",
          "column": "employee_name",
          "subFields": []
        },
        "as": null
      },
      {
        "expr": {
          "type": "column_ref",
          "table": "e",
          "column": "role",
          "subFields": []
        },
        "as": null
      },
      {
        "expr": {
          "type": "column_ref",
          "table": "d",
          "column": "department_name",
          "subFields": []
        },
        "as": null
      },
      {
        "expr": {
          "type": "column_ref",
          "table": "d",
          "column": "employee_count",
          "subFields": []
        },
        "as": null
      },
      {
        "expr": {
          "type": "column_ref",
          "table": "p",
          "column": "project_name",
          "subFields": []
        },
        "as": null
      },
      {
        "expr": {
          "type": "column_ref",
          "table": "p",
          "column": "member_count",
          "subFields": []
        },
        "as": null
      }
    ],
    "from": [
      {
        "db": null,
        "table": "employees",
        "as": "e",
        "operator": null
      },
      {
        "db": null,
        "table": "DepartmentSummary",
        "as": "d",
        "join": "JOIN",
        "on": {
          "type": "binary_expr",
          "operator": "=",
          "left": {
            "type": "column_ref",
            "table": "e",
            "column": "department_id",
            "subFields": []
          },
          "right": {
            "type": "column_ref",
            "table": "d",
            "column": "department_id",
            "subFields": []
          }
        }
      },
      {
        "db": null,
        "table": "employee_projects",
        "as": "ep",
        "join": "LEFT JOIN",
        "on": {
          "type": "binary_expr",
          "operator": "=",
          "left": {
            "type": "column_ref",
            "table": "e",
            "column": "employee_id",
            "subFields": []
          },
          "right": {
            "type": "column_ref",
            "table": "ep",
            "column": "employee_id",
            "subFields": []
          }
        }
      },
      {
        "db": null,
        "table": "ProjectSummary",
        "as": "p",
        "join": "LEFT JOIN",
        "on": {
          "type": "binary_expr",
          "operator": "=",
          "left": {
            "type": "column_ref",
            "table": "ep",
            "column": "project_id",
            "subFields": []
          },
          "right": {
            "type": "column_ref",
            "table": "p",
            "column": "project_id",
            "subFields": []
          }
        }
      }
    ],
    "for_sys_time_as_of": null,
    "where": null,
    "with": [
      {
        "name": {
          "type": "default",
          "value": "DepartmentSummary"
        },
        "stmt": {
          "tableList": ["select::null::departments"],
          "columnList": [
            "select::null::department_id",
            "select::null::department_name"
          ],
          "ast": {
            "type": "select",
            "as_struct_val": null,
            "distinct": null,
            "columns": [
              {
                "expr": {
                  "type": "column_ref",
                  "table": null,
                  "column": "department_id"
                },
                "as": null
              },
              {
                "expr": {
                  "type": "column_ref",
                  "table": null,
                  "column": "department_name"
                },
                "as": null
              },
              {
                "expr": {
                  "type": "aggr_func",
                  "name": "COUNT",
                  "args": {
                    "expr": {
                      "type": "star",
                      "value": "*"
                    }
                  },
                  "over": null
                },
                "as": "employee_count"
              }
            ],
            "from": [
              {
                "db": null,
                "table": "departments",
                "as": null,
                "operator": null
              }
            ],
            "for_sys_time_as_of": null,
            "where": null,
            "with": null,
            "groupby": [
              {
                "type": "column_ref",
                "table": null,
                "column": "department_id"
              },
              {
                "type": "column_ref",
                "table": null,
                "column": "department_name"
              }
            ],
            "having": null,
            "qualify": null,
            "orderby": null,
            "limit": null,
            "window": null
          }
        }
      },
      {
        "name": {
          "type": "default",
          "value": "ProjectSummary"
        },
        "stmt": {
          "tableList": ["select::null::departments", "select::null::projects"],
          "columnList": [
            "select::null::department_id",
            "select::null::department_name",
            "select::null::project_id",
            "select::null::project_name"
          ],
          "ast": {
            "type": "select",
            "as_struct_val": null,
            "distinct": null,
            "columns": [
              {
                "expr": {
                  "type": "column_ref",
                  "table": null,
                  "column": "project_id"
                },
                "as": null
              },
              {
                "expr": {
                  "type": "column_ref",
                  "table": null,
                  "column": "project_name"
                },
                "as": null
              },
              {
                "expr": {
                  "type": "aggr_func",
                  "name": "COUNT",
                  "args": {
                    "expr": {
                      "type": "star",
                      "value": "*"
                    }
                  },
                  "over": null
                },
                "as": "member_count"
              }
            ],
            "from": [
              {
                "db": null,
                "table": "projects",
                "as": null,
                "operator": null
              }
            ],
            "for_sys_time_as_of": null,
            "where": null,
            "with": null,
            "groupby": [
              {
                "type": "column_ref",
                "table": null,
                "column": "project_id"
              },
              {
                "type": "column_ref",
                "table": null,
                "column": "project_name"
              }
            ],
            "having": null,
            "qualify": null,
            "orderby": null,
            "limit": null,
            "window": null
          }
        }
      }
    ],
    "groupby": null,
    "having": null,
    "qualify": null,
    "orderby": null,
    "limit": null,
    "window": null,
    "_orderby": null,
    "_limit": null
  }
]
```

</details>

node-sql-parser を使っていた時に発生していた既知の不具合は [コチラ](https://github.com/yamamoto-yuta/sql-cte-visualizer-js/issues?q=is:issue+SQL%E3%83%91%E3%83%BC%E3%82%B5%E3%83%BC) にストックしてある。

現時点で判明している不具合の多くは node-sql-parser が使用しているパーサーの改修が必要そうな雰囲気（要検証）。その場合、 node-sql-parser は内部で PEG.js というパーサージェネレータを使用しており、おそらく下記の部分を回収することになるのではないかと思われる（が、今回は一旦ここまでで…）。

> 該当コード: https://github.com/taozhi8833998/node-sql-parser/blob/master/pegjs/bigquery.pegjs

「PEG.js is 何？」は次の記事が参考になった。

https://qiita.com/kujirahand/items/eab914bc77cf1bc0837c

## 可視化方法の検討

[先の記事](https://note.com/dd_techblog/n/n3876f38cc5fc) では [Graphviz](https://graphviz.org/) を用いて可視化していた。当初、 Graphviz が JavaScript でも使えることを知らずに別のライブラリでの実装を試みていた。そのときのメモを下記に示す（現在は Graphviz を用いている）。

### D3.js

当初、 [D3.js](https://d3js.org/) での可視化を試みていた。理由は D3.js の hierarchy が今回の用途に使えそうだったから（後に使えないことが分かったが…）。

hierarchy の実装については次の記事が参考になった。

https://zenn.dev/yuji/articles/7eb96460317222

前述の「使えないことが分かった」についてだが、「同名の子ノードが複数存在できてしまう」ことが問題となった。

例えば、次のような SQL クエリがあったとする。

```sql
WITH

  cte1 AS (
    SELECT * FROM source1
  ),

  cte2 AS (
    SELECT * FROM source1
  ),

  cte3 AS (
    SELECT * FROM cte2
  )

SELECT * FROM cte3 JOIN cte1
```

その場合…

| 正規表現による可視化（本来）                                                                                                                       | hierarchy による可視化                                                                                                                                                        |
| -------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| このように可視化してほしい。 ![image](https://github.com/yamamoto-yuta/sql-cte-visualizer-js/assets/55144709/ec98b212-c5af-4ecd-94fc-fdda235bfe69) | しかし、 hierarchy だと次のような可視化になってしまう。 ![image](https://github.com/yamamoto-yuta/sql-cte-visualizer-js/assets/55144709/5c26db28-6a91-4a8a-b0aa-ee66eaed7dce) |

見てみると、 `source1` が複数に分かれてしまっていることがわかる、おそらく子ノードが結合するような構造に hierarchy を適用するのは適切ではなかったものと思われる…（公式ドキュメント等を調べても、子ノードが結合するような構造に適用したサンプルは見つけられなかった）。

なお、D3.js 以外では [Mermaid.js](https://mermaid.js.org/) も検討したが、[公式の Live Editor](https://mermaid.live/) のようにユーザ入力に応じで図を更新する方法が分からず沼ったので断念した。

### Graphviz

[先の記事](https://note.com/dd_techblog/n/n3876f38cc5fc) と同じく Graphviz が JavaScript でも使えることが分かったので、最終的にこちらを採用した。

Graphviz の操作は次の記事が参考になった。

https://qiita.com/mmmmk/items/f7c70024938b0e38e4c9

## node-sql-parser を使っていたときの実装

node-sql-parser を使っていたときの CTE 可視化の実装を下記に示す。

node-sql-parser や hierarchy の実装についてはほぼ公式ドキュメントや参考記事の通り。

独自で実装したのは node-sql-parser で得られた構文木を hierarchy で可視化できるよう変換する処理。

node-sql-parser から得られる構文木のフォーマットは次のとおり。

```json
[
  {
    "type": "select",
    ...
    "from": [
      {
        ...
        "table": "<ROOT_FROM_TABLE>",
        ...
      },
      ...
    ],
    ...
    "with": [
      {
        "name": {
          ...
          "value": "<CTE_1"
        },
        "stmt": {
          ...
          "ast": {
            ...
            "from": [
              {
                ...
                "table": "CTE_1_FROM_TABLE>",
                ...
              },
              ...
            ],
            ...
          }
        }
      },
      ...
    ],
    ...
  }
]
```

hierarchy のフォーマットは次のとおり。

```json
{
  "name": "<ROOT>",
  "children": [
    {
      "name": "<CHILDREN_1_DEPTH_1>"
    },
    {
      "name": "<CHILDREN_2_DEPTH_1>",
      "children": [
  ...
}
```

変換処理は主に次のステップで行うようにした。

1. 構文木のデータから CTE 同士の依存関係データを作成する
2. 最後の SELECT ~ FROM で FROM している CTE に先の依存関係データを結合する

1 つ目のステップの実装コードは次のとおりである（ `originalJson` に構文木のデータが格納されている）。ポイントは、 CTE が CTE を FROM しているケースにも対応できるよう、再帰的に依存関係を特定している点である。

```js
let cteMap = new Map();

// 'with'節の処理（もし存在する場合）
if (originalJson[0].with) {
  originalJson[0].with.forEach((cte) => {
    cteMap.set(cte.name.value, {
      name: cte.name.value,
      children: [],
      processed: false,
    });
  });

  // 再帰的にCTEの依存関係を解析
  function processCte(cteName) {
    let cte = cteMap.get(cteName);
    if (cte.processed) {
      return cte;
    }

    cte.processed = true;
    originalJson[0].with.forEach((w) => {
      if (w.name.value === cteName) {
        if (w.stmt.ast.from) {
          // CTE に FROM 句がない場合もあるため分岐を入れている
          w.stmt.ast.from.forEach((fromTable) => {
            if (cteMap.has(fromTable.table)) {
              // FROM 句のテーブルがCTEの場合は深掘り
              cte.children.push(processCte(fromTable.table));
            } else {
              // 依存の終端に達した場合はテーブル名を追加
              cte.children.push({
                name: fromTable.table,
              });
            }
          });
        }
      }
    });

    return cte;
  }

  cteMap.forEach((_, cteName) => processCte(cteName));
}
```

2 つ目のステップの実装コードは次のとおり。

```js
// 新しいJSONオブジェクトの初期化
let convertedJson = {
  name: "root",
  children: [],
};

// 各テーブルを処理
originalJson[0].from.forEach((table) => {
  if (cteMap.has(table.table)) {
    convertedJson.children.push(cteMap.get(table.table));
  } else {
    convertedJson.children.push({
      name: table.table,
    });
  }
});
```

各ステップの動作例を以下に記す。

例えば、次のような SQL があったとする。

```sql
WITH

  cte_depth_2 AS (
    SELECT * FROM source
  ),

  cte_depth_1 AS (
    SELECT * FROM cte_depth_2
  )

SELECT * FROM cte_depth_1
```

この SQL から得られる構文木は次のようになる。

<details><summary>長いので折りたたみ</summary>

```json
{
  "type": "select",
  "as_struct_val": null,
  "distinct": null,
  "columns": [
    {
      "expr": {
        "type": "column_ref",
        "table": null,
        "column": "*"
      },
      "as": null
    }
  ],
  "from": [
    {
      "db": null,
      "table": "cte_depth_1",
      "as": null,
      "operator": null
    }
  ],
  "for_sys_time_as_of": null,
  "where": null,
  "with": [
    {
      "name": {
        "type": "default",
        "value": "cte_depth_2"
      },
      "stmt": {
        "tableList": ["select::null::source"],
        "columnList": ["select::null::(.*)"],
        "ast": {
          "type": "select",
          "as_struct_val": null,
          "distinct": null,
          "columns": [
            {
              "expr": {
                "type": "column_ref",
                "table": null,
                "column": "*"
              },
              "as": null
            }
          ],
          "from": [
            {
              "db": null,
              "table": "source",
              "as": null,
              "operator": null
            }
          ],
          "for_sys_time_as_of": null,
          "where": null,
          "with": null,
          "groupby": null,
          "having": null,
          "qualify": null,
          "orderby": null,
          "limit": null,
          "window": null
        }
      }
    },
    {
      "name": {
        "type": "default",
        "value": "cte_depth_1"
      },
      "stmt": {
        "tableList": ["select::null::source", "select::null::cte_depth_2"],
        "columnList": ["select::null::(.*)"],
        "ast": {
          "type": "select",
          "as_struct_val": null,
          "distinct": null,
          "columns": [
            {
              "expr": {
                "type": "column_ref",
                "table": null,
                "column": "*"
              },
              "as": null
            }
          ],
          "from": [
            {
              "db": null,
              "table": "cte_depth_2",
              "as": null,
              "operator": null
            }
          ],
          "for_sys_time_as_of": null,
          "where": null,
          "with": null,
          "groupby": null,
          "having": null,
          "qualify": null,
          "orderby": null,
          "limit": null,
          "window": null
        }
      }
    }
  ],
  "groupby": null,
  "having": null,
  "qualify": null,
  "orderby": null,
  "limit": null,
  "window": null,
  "_orderby": null,
  "_limit": null
}
```

</details>
<br />

1 つ目のステップでは、この構文木のデータから次のような依存関係データを作成する。

```json
[
  [
    "cte_depth_2",
    {
      "name": "cte_depth_2",
      "children": [
        {
          "name": "source"
        }
      ],
      "processed": true
    }
  ],
  [
    "cte_depth_1",
    {
      "name": "cte_depth_1",
      "children": [
        {
          "name": "cte_depth_2",
          "children": [
            {
              "name": "source"
            }
          ],
          "processed": true
        }
      ],
      "processed": true
    }
  ]
]
```

2 つ目のステップを経て、最終的に次のような hierarchy 用データになる。今回のクエリでは、最終クエリは `cte_depth_1` を FROM していたので、1 つ目のステップで得られた `cte_depth_1` の依存関係データを結合すれば OK となる。

```json
{
  "name": "root",
  "children": [
    {
      "name": "cte_depth_1",
      "children": [
        {
          "name": "cte_depth_2",
          "children": [
            {
              "name": "source"
            }
          ],
          "processed": true
        }
      ],
      "processed": true
    }
  ]
}
```
