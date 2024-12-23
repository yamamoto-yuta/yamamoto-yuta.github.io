---
title: "Gmail to Slack Using Gas"
description: 
slug: gmail-to-slack-using-gas
date: 2024-12-23T13:38:07Z
lastmod: 2024-12-23T13:38:07Z
image: 
math: 
license: 
hidden: false
comments: true
draft: false
---

<font size="1" align="right">

[✏️ 編集](https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/blob/main/content/post/gmail-to-slack-using-gas/index.md)

</font>

## 動機

Gmailに未読が溜まりまくる。なんとかしたい。Slackなら常に見てるからここに転送させれば解消できるのでは？

## 方法

1. Gmailでラベルを振り分ける
1. Slack Appを作成し、Bot Token Scopesに `chat:write` を追加してワークスペースへインストールする
1. 通知先のチャンネルにインストールしたSlack Appを招待する
1. GASのスクリプトプロパティに `SLACK_BOT_USER_OAUTH_TOKEN` を設定する
1. 次のスクリプトを定期的に（自分は10分にしている）実行するトリガーを設定する

```javascript
const main = () => {
  forwardGmailToSlack('label:<YOUR_LABEL> is:unread ', 'YOUR_CHANNEL_ID');
  forwardGmailToSlack('is:unread ', 'OTHERS_CHANNEL_ID');   // 先に分類可能な未読メールを転送させてから、最後に残った未読を転送させること
};

const forwardGmailToSlack = (query, channel) => {
  const threads = GmailApp.search(query);
  if (threads.length == 0) {
    Logger.log(`新規メッセージなし: ${query}`);
    return
  }
  // Logger.log(threads.length);

  threads.forEach((thread) => {
    const messages = thread.getMessages();
    // Logger.log(messages.length);
    messages.forEach((message) => {

    
      const from = message.getFrom();
      const subject = message.getSubject();
      const body = message.getPlainBody();
      const mailId = message.getId();
      const received_date = message.getDate();

      const profileId = 0; // デフォルトプロファイルを使用
      const mailUrl = 'https://mail.google.com/mail/u/'+ profileId + '/#inbox/' + mailId;

      try {
        // 件名をチャンネルに投稿
        const subjectMessage = `*件名*: ${subject}\n*送信者*: ${from}\n*受信日時*: ${formatDate(received_date)}\n*メールURL*: ${mailUrl}`;
        const subjectResponse = postToSlack(channel, subjectMessage);
        const threadTs = subjectResponse.ts;  // 投稿されたメッセージのタイムスタンプ

        // 本文をスレッドに投稿
        const bodyMessage = `*本文*:\n${body}`;
        postToSlack(channel, bodyMessage, threadTs);

        // メールを既読に変更
        message.markRead();
      } catch (e) {
        Logger.log(`Slackへの送信エラー: ${e.message}`);
      }
    });
  });
};

const postToSlack = (channel, text, threadTs = null) => {
  const getSlackBotToken = () => {
    const scriptProperties = PropertiesService.getScriptProperties();
    const token = scriptProperties.getProperty('SLACK_BOT_USER_OAUTH_TOKEN');
    
    if (!token) {
      throw new Error('スクリプトプロパティに SLACK_BOT_USER_OAUTH_TOKEN が見つかりません。');
    }
    
    return token;
  };
  const slackBotToken = getSlackBotToken();

  const url = 'https://slack.com/api/chat.postMessage';
  const payload = {
    channel: channel,
    text: text,  // 投稿するメッセージ
  };

  // スレッドへの投稿
  if (threadTs) {
    payload.thread_ts = threadTs;
  }

  const options = {
    method: 'post',
    contentType: 'application/json',
    headers: {
      'Authorization': `Bearer ${slackBotToken}`,
    },
    payload: JSON.stringify(payload),
  };

  const response = UrlFetchApp.fetch(url, options);
  const result = JSON.parse(response.getContentText());

  if (!result.ok) {
    throw new Error(`Slack投稿エラー: ${channel} ${text} ${result.error}`);
  }

  return result;
};

const formatDate = (date) => {
  const year = date.getFullYear();
  const month = ('0' + (date.getMonth() + 1)).slice(-2);  // 月を2桁にフォーマット
  const day = ('0' + date.getDate()).slice(-2);           // 日を2桁にフォーマット
  const hours = ('0' + date.getHours()).slice(-2);        // 時間を2桁にフォーマット
  const minutes = ('0' + date.getMinutes()).slice(-2);    // 分を2桁にフォーマット
  return `${year}/${month}/${day} ${hours}:${minutes}`;
};
```

こんな感じでSlackへ通知される。

チャンネル:

![](https://github.com/user-attachments/assets/01877625-5fe5-4ba6-b599-271e2b0732f9)

スレッド:

![](https://github.com/user-attachments/assets/62f89735-37d7-40d5-9168-c91601c3e31a)
