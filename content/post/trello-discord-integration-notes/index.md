---
title: "Trello + Discord 連携メモ"
description:
slug: trello-discord-integration-notes
date: 2022-10-30T15:00:00Z
lastmod:
image:
math:
license:
hidden: false
comments: true
draft: false
---

公式ドキュメント:

- [The Trello REST API](https://developer.atlassian.com/cloud/trello/rest/api-group-actions/)
- [API Introduction](https://developer.atlassian.com/cloud/trello/guides/rest-api/api-introduction/#api-introduction)

参考記事:

- [TrelloAPI+GAS で Trello のカード移動を Slack に通知する仕組みを作った話 - トレタ開発者ブログ](https://tech.toreta.in/entry/2019/12/09/210337)
- [【Trello】Rest API の備忘録](https://zenn.dev/miyabisun/articles/bb879493e2648b)

## Discord の Webhook URL を取得

普通に用意

<img width="509.25" alt="image.png (29.3 kB)" src="https://img.esa.io/uploads/production/attachments/14751/2022/10/31/74743/a2d36db2-085b-4b27-959f-f5d1c94c1f50.png">

## Trello の API キー、トークンを取得

1. Trello にログインしている状態で次のページにアクセス

> [開発者向け API キー](https://trello.com/app-key)

2. API キー、トークンを取得する

- API キー:
  - `パーソナルキー` の欄にある英数字の羅列
- トークン:
  - 1. [トークン](https://trello.com/1/authorize?expiration=never&scope=read,write,account&response_type=token&name=Server%20Token&key=5a88c2e2811a40ec930772e37a3a8c53) へアクセス
  - 2. アプリケーションにアカウントへのアクセスを許可
  - 3. 発行されたトークンをメモ

3. 下記コマンドを実行してレスポンスが返ってきていれば OK

```
curl --request GET \
  --url 'https://api.trello.com/1/members/me/boards?key={APIKey}&token={APIToken}'
```

## GAS と連携

1. 通知用チャンネルを作成（権限に `Bot` を追加しておかないと、Bot から通知できないので注意）

<img width="505.5" alt="image.png (31.8 kB)" src="https://img.esa.io/uploads/production/attachments/14751/2022/10/31/74743/4545c8a2-8284-4ccc-8329-e67b889259af.png">

2. GAS プロジェクトを作成

> GAS プロジェクト: [trello_notifier_bot](https://script.google.com/d/1l7gtAPJODCdEaUaX7934hNibD5Pn_J0x71Mlgb_G8Nz1YduRz2yd0CAw/edit?usp=sharing)

3. GAS から Discord へ通知を送れるかテスト

Discord の Webhook URL は環境変数的なものなので、プロジェクト設定からスクリプトプロパティへ追加

<img width="563.25" alt="image.png (18.7 kB)" src="https://img.esa.io/uploads/production/attachments/14751/2022/10/31/74743/178c189b-5e96-4831-82d8-c91c8b4b2f1f.png">

サンプルコード:

```javascript
function myFunction() {
  const scriptProps = PropertiesService.getScriptProperties().getProperties();

  const payload = {
    content: "content",
    embeds: [
      {
        title: "title",
        description: "description",
      },
    ],
  };

  const payloads = [
    {
      url: scriptProps.DISCORD_WEBHOOK_URL,
      contentType: "application/json",
      payload: JSON.stringify(payload),
    },
  ];

  UrlFetchApp.fetchAll(payloads);
}
```

動作結果:
<img width="225" alt="image.png (9.1 kB)" src="https://img.esa.io/uploads/production/attachments/14751/2022/10/31/74743/a092254e-afb0-49d0-9724-1cc349a95fdf.png">

## Trello に Webhook を登録する

下記 POST を送信する。 `callbackURL` には GAS プロジェクトをデプロイしたときに発行される URL を入れる。 `idModel` は変更を検知したいボードの ID を入れる。

```
curl -X POST -H "Content-Type: application/json" \
https://api.trello.com/1/tokens/{APIToken}/webhooks/ \
-d '{
  "key": "{APIKey}",
  "callbackURL": "http://www.mywebsite.com/trelloCallback",
  "idModel":"4d5ea62fd76aa1136000000c",
  "description": "My first webhook"
}'
```

> 引用: https://developer.atlassian.com/cloud/trello/guides/rest-api/webhooks/#creating-a-webhook

うまくいくと、下記コードの場合、登録したボードに変更を加えると `doPost` という文字列が Discord へ送信される。

```javascript
function doPost(e) {
  postToDiscord("doPost");
}

function postToDiscord(content) {
  const payload = {
    content: content,
  };

  const payloads = [
    {
      url: scriptProps.DISCORD_WEBHOOK_URL,
      contentType: "application/json",
      payload: JSON.stringify(payload),
    },
  ];

  UrlFetchApp.fetchAll(payloads);
}
```

`callbackURL` の `URL` は全て大文字なので注意（間違えると、 `Value isn't a string.` というメッセージが返ってくる）

> [When creating a webhook, the error "Value isn't a string." - Trello - The Atlassian Developer Community](https://community.developer.atlassian.com/t/when-creating-a-webhook-the-error-value-isnt-a-string/50388)

次の手順で Webhook の登録を行えるようにした:

1. `新しいデプロイ` > `アクセスできるユーザ: 自分のみ` にしてデプロイ
1. `createWebhook()` を実行
1. `デプロイを管理` > `アクセスできるユーザ: 全員` に変更
1. Trello のボードに変更を加えた時、Discord へ通知が来れば OK

手順 1 で `アクセスできるユーザ: 自分のみ` する理由は、全体公開にすると 403 エラーが返ってくるかららしい。

> 参考: [GAS を使って trello webhook を受ける時のハマりどころ - Qiita](https://qiita.com/meowmeowcats/items/634c6e084d863f303e72)

1 回作成された Webhook を再度作ろうとするとエラーになる。
`新しいデプロイ` を実施することで暫定的に回避できる。

## GAS 変更の反映方法

GAS のコードを変更したら `新しいデプロイ` を行わないと反映されない。ただし、 `新しいデプロイ` をすると Callback URL が変わってしまう。

その場合、 `デプロイを管理` から新バージョンとしてデプロイすることで、URL を変更せずに反映できる。

<img width="599.25" alt="image.png (27.4 kB)" src="https://img.esa.io/uploads/production/attachments/14751/2022/11/14/74743/1d44a778-5239-45dd-b06c-6c056c8dd1d5.png">

> 参考:
>
> - [【Web】GAS の HTML ファイルが「スクリプト関数が見つかりません：doGet」と出て表示されないときに確認すること【Google Apps Script】 - 映画と旅行とエンジニア](https://wakky.tech/gas-html-doget-error/)
> - [GAS の Web アプリで URL を変えずに新バージョンを公開する（新エディタ） - make it easy](https://ryjkmr.com/gas-web-app-deploy-new-same-url/)

## `doPost(e)` で受け取る情報

- [Action Types](https://developer.atlassian.com/cloud/trello/guides/rest-api/action-types/)
- [Object Definitions](https://developer.atlassian.com/cloud/trello/guides/rest-api/object-definitions/)

受け取った情報に Action ID があるので、それを使ってアクション詳細を取得するのが良さそう

> [The Trello REST API](https://developer.atlassian.com/cloud/trello/rest/api-group-actions/)

例１）カードのリストを移動した場合:

<details>
<pre>
<code>
{
    "id": "63712c0f23c9cc02ffa935ef",
    "idMemberCreator": "5da3f38080e88b1af8e8ff86",
    "data": {
        "card": {
            "idList": "5dd692ca0897377466449231",
            "id": "627bc1e708099f5b7124c099",
            "name": "1曲目の前に名乗り, 挨拶と常套句（余裕があったら）",
            "idShort": 26,
            "shortLink": "cs179j1u"
        },
        "old": {
            "idList": "627bc1c16397f33d596253c0"
        },
        "board": {
            "id": "5dd692c956a9247b4140e18b",
            "name": "2022秋ライブ",
            "shortLink": "szHdDf00"
        },
        "listBefore": {
            "id": "627bc1c16397f33d596253c0",
            "name": "やりたいこと"
        },
        "listAfter": {
            "id": "5dd692ca0897377466449231",
            "name": "やること"
        }
    },
    "appCreator": null,
    "type": "updateCard",
    "date": "2022-11-13T17:40:31.715Z",
    "limits": null,
    "display": {
        "translationKey": "action_move_card_from_list_to_list",
        "entities": {
            "card": {
                "type": "card",
                "idList": "5dd692ca0897377466449231",
                "id": "627bc1e708099f5b7124c099",
                "shortLink": "cs179j1u",
                "text": "1曲目の前に名乗り, 挨拶と常套句（余裕があったら）"
            },
            "listBefore": {
                "type": "list",
                "id": "627bc1c16397f33d596253c0",
                "text": "やりたいこと"
            },
            "listAfter": {
                "type": "list",
                "id": "5dd692ca0897377466449231",
                "text": "やること"
            },
            "memberCreator": {
                "type": "member",
                "id": "5da3f38080e88b1af8e8ff86",
                "username": "user36408094",
                "text": "山本雄太"
            }
        }
    },
    "memberCreator": {
        "id": "5da3f38080e88b1af8e8ff86",
        "activityBlocked": false,
        "avatarHash": "bd843173354efbec0932501d2c787a46",
        "avatarUrl": "https://trello-members.s3.amazonaws.com/5da3f38080e88b1af8e8ff86/bd843173354efbec0932501d2c787a46",
        "fullName": "山本雄太",
        "idMemberReferrer": null,
        "initials": "山本太",
        "nonPublic": {},
        "nonPublicAvailable": true,
        "username": "user36408094"
    }
}
</code>
</pre>
</details>

例２）同一リスト内でカードを入れ替えた場合:

<details>
<pre>
<code>
{
    "id": "63712d7e1d8da00421bd3234",
    "idMemberCreator": "5da3f38080e88b1af8e8ff86",
    "data": {
        "card": {
            "pos": 229375,
            "id": "627bc2098e68668fe44d5219",
            "name": "背景と照明であわせる",
            "idShort": 28,
            "shortLink": "htmAcLHf"
        },
        "old": {
            "pos": 131071
        },
        "board": {
            "id": "5dd692c956a9247b4140e18b",
            "name": "2022秋ライブ",
            "shortLink": "szHdDf00"
        },
        "list": {
            "id": "627bc1c16397f33d596253c0",
            "name": "やりたいこと"
        }
    },
    "appCreator": null,
    "type": "updateCard",
    "date": "2022-11-13T17:46:38.819Z",
    "limits": null,
    "display": {
        "translationKey": "action_moved_card_higher",
        "entities": {
            "card": {
                "type": "card",
                "pos": 229375,
                "id": "627bc2098e68668fe44d5219",
                "shortLink": "htmAcLHf",
                "text": "背景と照明であわせる"
            },
            "memberCreator": {
                "type": "member",
                "id": "5da3f38080e88b1af8e8ff86",
                "username": "user36408094",
                "text": "山本雄太"
            }
        }
    },
    "memberCreator": {
        "id": "5da3f38080e88b1af8e8ff86",
        "activityBlocked": false,
        "avatarHash": "bd843173354efbec0932501d2c787a46",
        "avatarUrl": "https://trello-members.s3.amazonaws.com/5da3f38080e88b1af8e8ff86/bd843173354efbec0932501d2c787a46",
        "fullName": "山本雄太",
        "idMemberReferrer": null,
        "initials": "山本太",
        "nonPublic": {},
        "nonPublicAvailable": true,
        "username": "user36408094"
    }
}
</code>
</pre>
</details>

例３）カードにコメントを追加した場合:

<details>
<pre>
<code>
{
    "id": "63712df1630c6c05daf96fd0",
    "idMemberCreator": "5da3f38080e88b1af8e8ff86",
    "data": {
        "text": "aaaaa",
        "textData": {
            "emoji": {}
        },
        "card": {
            "id": "627bc1e708099f5b7124c099",
            "name": "1曲目の前に名乗り, 挨拶と常套句（余裕があったら）",
            "idShort": 26,
            "shortLink": "cs179j1u"
        },
        "board": {
            "id": "5dd692c956a9247b4140e18b",
            "name": "2022秋ライブ",
            "shortLink": "szHdDf00"
        },
        "list": {
            "id": "5dd692ca0897377466449231",
            "name": "やること"
        }
    },
    "appCreator": null,
    "type": "commentCard",
    "date": "2022-11-13T17:48:33.824Z",
    "limits": {
        "reactions": {
            "perAction": {
                "status": "ok",
                "disableAt": 900,
                "warnAt": 720
            },
            "uniquePerAction": {
                "status": "ok",
                "disableAt": 17,
                "warnAt": 14
            }
        }
    },
    "display": {
        "translationKey": "action_comment_on_card",
        "entities": {
            "contextOn": {
                "type": "translatable",
                "translationKey": "action_on",
                "hideIfContext": true,
                "idContext": "627bc1e708099f5b7124c099"
            },
            "card": {
                "type": "card",
                "hideIfContext": true,
                "id": "627bc1e708099f5b7124c099",
                "shortLink": "cs179j1u",
                "text": "1曲目の前に名乗り, 挨拶と常套句（余裕があったら）"
            },
            "comment": {
                "type": "comment",
                "text": "aaaaa"
            },
            "memberCreator": {
                "type": "member",
                "id": "5da3f38080e88b1af8e8ff86",
                "username": "user36408094",
                "text": "山本雄太"
            }
        }
    },
    "memberCreator": {
        "id": "5da3f38080e88b1af8e8ff86",
        "activityBlocked": false,
        "avatarHash": "bd843173354efbec0932501d2c787a46",
        "avatarUrl": "https://trello-members.s3.amazonaws.com/5da3f38080e88b1af8e8ff86/bd843173354efbec0932501d2c787a46",
        "fullName": "山本雄太",
        "idMemberReferrer": null,
        "initials": "山本太",
        "nonPublic": {},
        "nonPublicAvailable": true,
        "username": "user36408094"
    }
}
</code>
</pre>
</details>

例４）さらにコメントを追加した場合:

<details>
<pre>
<code>
{
    "id": "63712e485c9137001535ed3f",
    "idMemberCreator": "5da3f38080e88b1af8e8ff86",
    "data": {
        "text": "bbbbb",
        "textData": {
            "emoji": {}
        },
        "card": {
            "id": "627bc1e708099f5b7124c099",
            "name": "1曲目の前に名乗り, 挨拶と常套句（余裕があったら）",
            "idShort": 26,
            "shortLink": "cs179j1u"
        },
        "board": {
            "id": "5dd692c956a9247b4140e18b",
            "name": "2022秋ライブ",
            "shortLink": "szHdDf00"
        },
        "list": {
            "id": "5dd692ca0897377466449231",
            "name": "やること"
        }
    },
    "appCreator": null,
    "type": "commentCard",
    "date": "2022-11-13T17:50:00.381Z",
    "limits": {
        "reactions": {
            "perAction": {
                "status": "ok",
                "disableAt": 900,
                "warnAt": 720
            },
            "uniquePerAction": {
                "status": "ok",
                "disableAt": 17,
                "warnAt": 14
            }
        }
    },
    "display": {
        "translationKey": "action_comment_on_card",
        "entities": {
            "contextOn": {
                "type": "translatable",
                "translationKey": "action_on",
                "hideIfContext": true,
                "idContext": "627bc1e708099f5b7124c099"
            },
            "card": {
                "type": "card",
                "hideIfContext": true,
                "id": "627bc1e708099f5b7124c099",
                "shortLink": "cs179j1u",
                "text": "1曲目の前に名乗り, 挨拶と常套句（余裕があったら）"
            },
            "comment": {
                "type": "comment",
                "text": "bbbbb"
            },
            "memberCreator": {
                "type": "member",
                "id": "5da3f38080e88b1af8e8ff86",
                "username": "user36408094",
                "text": "山本雄太"
            }
        }
    },
    "memberCreator": {
        "id": "5da3f38080e88b1af8e8ff86",
        "activityBlocked": false,
        "avatarHash": "bd843173354efbec0932501d2c787a46",
        "avatarUrl": "https://trello-members.s3.amazonaws.com/5da3f38080e88b1af8e8ff86/bd843173354efbec0932501d2c787a46",
        "fullName": "山本雄太",
        "idMemberReferrer": null,
        "initials": "山本太",
        "nonPublic": {},
        "nonPublicAvailable": true,
        "username": "user36408094"
    }
}
</code>
</pre>
</details>
