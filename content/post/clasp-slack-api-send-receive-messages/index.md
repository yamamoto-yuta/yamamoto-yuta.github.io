---
title: "Clasp 環境下で Slack API を使ってメッセージを送受信する"
description:
slug: clasp-slack-api-send-receive-messages
date: 2024-03-24T16:56:00Z
lastmod:
image:
math:
license:
hidden: false
comments: true
draft: false
---

Clasp 環境から Slack API を使ってメッセージの送受信を行ってみたので、その時のメモを残す。

Clasp 環境は過去記事の環境を使用している。

[Docker で clasp 環境を構築する | yamamoto-yuta.github.io](https://yamamoto-yuta.github.io/articles/35)

## Slack App の作成

https://api.slack.com/apps から Slack App を作成する、

OAuth & Permissions から下記の Scope を設定してワークスペースへインストールする。

![image](https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/assets/55144709/841b6c19-5480-407a-b972-ab0c426f55c9)

## GAS でのメッセージ送受信部分の実装

Bot User Token と Slack App のメンバー ID を GAS のスクリプトプロパティに登録する。

メッセージ送受信部分の実装は次のとおり。 `main.ts` の実装は下記記事のコードをほぼほぼベースにしている。

[Slack で動く ChatGPT のチャットボットを Google Apps Script（GAS）でサクッと作ってみる](https://zenn.dev/lclco/articles/712d482d07e18c)

`index.ts` :

```typescript
import { doPost } from "./main";

declare const global: any;

// GAS において doPost() は特別な関数なので、global の名前は doPost にしておく必要がある
global.doPost = doPost;
```

`main.ts` :

```typescript
import URLFetchRequestOptions = GoogleAppsScript.URL_Fetch.URLFetchRequestOptions;

// Slack へのメッセージ送信関数
const sendMessageToSlack = (channel: string, message: string) => {
  const SLACK_BOT_TOKEN =
    PropertiesService.getScriptProperties().getProperty("SLACK_BOT_TOKEN");
  if (!SLACK_BOT_TOKEN) throw new Error("SLACK_BOT_TOKEN is not set.");

  const url = "https://slack.com/api/chat.postMessage";
  const payload = {
    channel: channel,
    text: "echo: " + message,
  };

  const options: URLFetchRequestOptions = {
    method: "post",
    contentType: "application/json",
    headers: { Authorization: `Bearer ${SLACK_BOT_TOKEN}` },
    payload: JSON.stringify(payload),
  };

  UrlFetchApp.fetch(url, options);
};

export const doPost = (e: any) => {
  const reqObj = JSON.parse(e.postData.getDataAsString());

  // Slackから認証コードが送られてきた場合(初回接続時)
  // これをやっておかないと Event Subscriptions で URL が Verify されない
  if (reqObj.type == "url_verification") {
    // 認証コードをそのまま返すことで、アプリをSlackに登録する処理が完了する
    return ContentService.createTextOutput(reqObj.challenge);
  }

  // Slackからのコールバック以外の場合、OKを返して処理を終了する
  if (reqObj.type !== "event_callback" || reqObj.event.type !== "message") {
    return ContentService.createTextOutput("OK");
  }

  // メッセージが編集または削除された場合、OKを返して処理を終了する
  if (reqObj.event.subtype !== undefined) {
    return ContentService.createTextOutput("OK");
  }

  // Slackから送信されたトリガーメッセージ
  const triggerMsg = reqObj.event;
  // ユーザーID
  const userId = triggerMsg.user;
  // メッセージID
  const msgId = triggerMsg.client_msg_id;
  // チャンネルID
  const channelId = triggerMsg.channel;
  // タイムスタンプ
  const ts = triggerMsg.ts;

  // Bot自身によるメッセージである場合、OKを返して処理を終了する
  const SLACK_BOT_USER_ID =
    PropertiesService.getScriptProperties().getProperty("SLACK_BOT_USER_ID");
  if (!SLACK_BOT_USER_ID) throw new Error("SLACK_BOT_USER_ID is not set.");
  if (userId === SLACK_BOT_USER_ID) {
    return ContentService.createTextOutput("OK");
  }

  sendMessageToSlack(channelId, triggerMsg.text);
  return ContentService.createTextOutput("OK");
};
```

## Slack App の Event Subscription の設定

GAS 側が実装できたら、 GAS からウェブアプリとしてデプロイする。

デプロイ後、ウェブアプリの URL を Slack App の Events Subscriptions の Request URL に貼り付ける。

次の bot events を subscribe するよう設定する。

![image](https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/assets/55144709/3a7b3c3a-600c-40fd-8114-a60c44097227)

## 実際に動かしてみる

作成した Slack App をチャンネルに招待してメッセージを送信すると、送信した文章を Slack App が echo するはず。

## ローカルからデプロイする

`clasp deploy` でローカルからデプロイできる。が、いくつか注意点がある。

**① `appsscript.json` に下記設定を追加しないと、「ウェブアプリ」ではなく「ライブラリ」としてデプロイされてしまう＝ウェブアプリの URL が発行されない**

```json
  "webapp": {
    "access": "ANYONE_ANONYMOUS",
    "executeAs": "USER_DEPLOYING"
  },
```

設定内容は下記画像と同じ。

![image](https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/assets/55144709/3828bd5b-90e6-434f-97cb-cf01bce0fc88)

**② `clasp deploy` 時にデプロイ ID を指定しないと新しいデプロイが作成されてしまい、ウェブアプリの URL が変わってしまう（ [→ 公式ドキュメント](https://arc.net/l/quote/meqjrjco) ）**

`clasp deployment` でアクティブなデプロイの一覧が取得できる。再デプロイする場合、デプロイ一覧の中から最新のデプロイ ID を取得し、それを `clasp deploy` で指定する。今回は次のような再デプロイ用スクリプトを作成して対処した。

`redeploy.sh` :

```sh
#!/bin/bash

# Build
yarn webpack --mode production

# Push
yarn clasp push

# Get last deployment id
LAST_DEPLOYMENT_ID=$(yarn clasp deployments | tail -n 2 | head -n 1 | awk '{print $2}')

# Deploy
yarn clasp deploy --deploymentId $LAST_DEPLOYMENT_ID
```

クリプトは次の記事が参考になった。

[Google Apps Script の Clasp で Web アプリの URL を変えないでデプロイする方法 - ある SE のつぶやき・改](https://www.aruse.net/entry/2022/10/09/130019)

## 参考記事

- [Slack で動く ChatGPT のチャットボットを Google Apps Script（GAS）でサクッと作ってみる](https://zenn.dev/lclco/articles/712d482d07e18c)
- [GAS ＋ clasp に npm のライブラリも使って slack アプリを作る #Slack - Qiita](https://qiita.com/h-uminoue-gxp/items/83ace042a22d07ebbcd4)
- [GAS Web app を Clasp からデプロイ #JavaScript - Qiita](https://qiita.com/ume3003/items/cd9d05dff014952a73f8)
- [Google Apps Script の Clasp で Web アプリの URL を変えないでデプロイする方法 - ある SE のつぶやき・改](https://www.aruse.net/entry/2022/10/09/130019)
