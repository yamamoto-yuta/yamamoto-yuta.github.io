---
title: "API経由でSlackへカスタム絵文字を追加できないか調査したときのメモ"
description:
slug: "api-add-custom-emoji-to-slack"
date: 2023-05-06T16:56:00Z
lastmod:
image:
math:
license:
hidden: false
comments: true
draft: false
---

## やりたいこと

Slack API 経由で Slack へ絵文字を追加したい

## 調べたこと

### 方針 1: Slack API の admin.emoji.add を利用する

公式で用意されている絵文字追加用 API。

> 公式ドキュメント: https://api.slack.com/methods/admin.emoji.add

ただし、結局この API は使えなかった。理由はこの API を利用するには Slack App に `admin.teams:write` という権限を付与する必要があったから。

> `admin.teams:write` についての公式ドキュメント: https://api.slack.com/scopes/admin.teams:write

これには次の問題があったので今回は方針を変更することにした:

- Admin API は個々のワークスペースではなく組織全体に影響を与えることができ、ただ絵文字を追加するだけの用途で付与するには不適当なため
- そもそも Enterprise 版でないと利用できないため

### 方針 2: 一般公開されていない API /api/emoji.add を利用する

どうやら Slack には一般公開されていない API がいくつかあるらしく、その中の一つである `/api/emoji.add` を利用すれば絵文字の追加が可能らしい:

> 参考: https://github.com/slackhq/slack-api-docs/issues/28#issuecomment-424195796

この API を利用しているプロダクトがいくつかあるようだったので、それらを参考に API を叩いてみた。 API を叩く手順は次の通り。

#### /api/emoji.add API を叩く手順

##### 1. トークンを入手する

1. 絵文字を追加したいワークスペースを開く
2. 開発者ツールを開き、コンソールタブで次のコマンドを実行する

> ```js
> JSON.parse(localStorage.localConfig_v2).teams[
>   document.location.pathname.match(/^\/client\/(T[A-Z0-9]+)/)[1]
> ].token;
> ```
>
> 引用: https://github.com/jackellenberger/emojme/blob/master/README.md#cookie-token-one-liner

`xoxc-xxxxxxxxxx` といった形式のトークンが返ってくるはず。

##### 2. Cookie を入手する

1. `https://<TEAM_ID>.slack.com/customize/emoji` を開く（ワークスペースを開いた状態で「以下をカスタマイズ」をクリックすると飛べる）
2. 開発者ツールを開き、「ネットワーク」タブを開く
3. `emoji` というドキュメントを選択する
4. リクエストヘッダーの `cookie:` の値が入手したい Cookie （この値をコピーするとき、「右クリック > 『値をコピー』」だとコピー後の文字列に日本語が混じって後で困るので、範囲選択でコピーする必要がある）

##### 3. API を叩く

API を叩くコード:

```python
import requests

TOKEN = "xoxc-xxxxxxxxxx"   # トークン
COOKIE = "xxxxxxxxxx"   # Cookie

team_name = "xxxxxxxxxx"    # ワークスペースのチーム名
emoji_name = "emoji"   # 絵文字の名前
emoji_img_filepath = "./emoji.png"   # 絵文字の画像ファイルへのパス

URL_ADD = "https://{team_name}.slack.com/api/emoji.add"
r = requests.post(
    URL_ADD.format(team_name=team_name),
    headers = {'Cookie': COOKIE},
    data = {
        'mode': 'data',
        'name': emoji_name,
        'token': TOKEN
    },
    files={'image': open(emoji_img_filepath, 'rb')}
)
```

次のレスポンスが返ってきていれば成功:

```
{"ok":true}
```

## 残る課題

- トークンと Cookie の入手を自動でできないか？

## 余談

### `/api/emoji.add` の xoxb トークンでの利用について

`/api/emoji.add` を xoxb トークンで利用できるよう求める Issue が 2019 年 1 月に建てられているが、2023 年 5 月現在、まだ Open なままである。

> 該当 Issue: https://github.com/slackhq/slack-api-docs/issues/95

### xoxc トークンをスクレイピングで入手する

`https://<TEAM_ID>.slack.com/customize/emoji` ページをスクレイピングすることで xoxc トークンを入手している例を紹介している [記事](https://codenote.net/tool/4487.html) を見つけた。

> 該当コード: https://github.com/smashwilson/slack-emojinator/blob/fbcf759ebbda8bd37b77c91362edde9fd3e0c05a/upload.py#L81-L94

しかし、やってみたがうまくいかなかった（ `api_token:` の値が `""` だった）。やってみた当時はまだトークンや Cookie の入手などが手探りの状態だったので、それが原因でうまくいかなかったのかも…？

## 参考

- [Slack で絵文字を追加するサービスを作ろうとしたときに調べたこと](https://hirotoohira.link/how-to-add-slack-emoji-on-api/)
- [Slack Custom Emoji を追加する非公開 API /api/emoji.add | CodeNote](https://codenote.net/tool/4487.html)
- [smashwilson/slack-emojinator: Bulk upload emoji into Slack](https://github.com/smashwilson/slack-emojinator)
- [Fauntleroy/neutral-face-emoji-tools: Utilities that make life as a Slack emoji addict a little easier.](https://github.com/Fauntleroy/neutral-face-emoji-tools)
- [jackellenberger/emojme: very powerful very stupid Slack emoji tools, holy cow!](https://github.com/jackellenberger/emojme/tree/master)
