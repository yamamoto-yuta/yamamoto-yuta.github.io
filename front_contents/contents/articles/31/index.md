---
description: '※ この記事は、私が2022/12/20に書いたメモを転記したものです。  ---  ## ３行で  * SlackDeck は複数の
  `<iframe>` に Web 版 Slack を表示するため，通知が来ると多重で音が鳴ってしまう * この問題を解決するために色々調べてみたところ， Slack
  の通知は Notification API を用いて行われていることが分かった * しかし， `<...'
posted_at: 2023-12-03 08:39:09+00:00
slug: '31'
tag_ids: []
title: SlackDeckの通知多重で鳴っちゃう問題で詰んだ話
updated_at: ''

---
※ この記事は、私が2022/12/20に書いたメモを転記したものです。

---

## ３行で

* SlackDeck は複数の `<iframe>` に Web 版 Slack を表示するため，通知が来ると多重で音が鳴ってしまう
* この問題を解決するために色々調べてみたところ， Slack の通知は Notification API を用いて行われていることが分かった
* しかし， `<iframe>` の通知許可はメインフレームの通知許可から行うべきであることも分かり，多重で音が鳴っている挙動が適切な挙動ということになってしまった

## SlackDeck とは？

Slack のチャンネルを横に並べられる Chrome 拡張機能

<img width="640" alt="image.png (191.4 kB)" src="https://img.esa.io/uploads/production/attachments/14611/2022/12/20/74743/658cfc76-1fc3-42bb-b396-2a8e0203905b.png">

https://chrome.google.com/webstore/detail/slackdeck/cocnkjpcbmoopfpmogblnjpjdfcaohod

## 何が問題だったか？

SlackDeck は，メインの Slack を表示する `<body>` とカラムとして Slack を表示する `<iframe>` で構成されている．図にすると次の通り:

<img src='/static/images/articles/31/b24b343bafecd9516e89c8b5f89a249d.webp' origin_url='https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/assets/55144709/110645ba-57e9-455f-b350-bd252f475974' alt='image' />

この状態で Slack に通知が来ると， `<body>` と全ての `<iframe>` で通知音が鳴ってしまい，多重で通知音が鳴ってしまう．

これが原因で SlackDeck を Chrome から削除してしまうユーザもいたため，今回，修正を試みた次第．

## 調べて分かったこと

* Slack では通知の送信に Notification API を利用している

> ウェブ通知の最も顕著な用途の一つが、ウェブベースのメールや IRC アプリケーションにおいて、新しいメッセージを受信したときに、ユーザーがほかのアプリケーションで何かをしていても通知をする必要がある場合です。これには数多くの事例が存在し、例えば Slack などがあります。
> 引用: [通知 API の使用 - Web API | MDN](https://developer.mozilla.org/ja/docs/Web/API/Notifications_API/Using_the_Notifications_API)

* `<iframe>` から通知許可を求めるメソッド `Notification.requestPermission()` は Chrome から非推奨と言われている

> Remove the ability to call Notification.requestPermission() from non-main frames.
> This change will align the requirements for notification permission with that of push notifications, easing friction for developers. It allows us to unify notification and push permissions.
> 引用: [Remove Usage of Notifications from iFrames - Chrome Platform Status](https://chromestatus.com/feature/6451284559265792)

* この非推奨宣言に対応した事例を見てみると，代わりにトップレベルのフレームから許可を要求するか新しいウィンドウで開くのが良いらしい

> 参考: [Notification.requestPermission from iframe deprecated · Issue #17 · amazon-connect/amazon-connect-streams](https://github.com/amazon-connect/amazon-connect-streams/issues/17)

以上より， `<body>` で表示している Slack の通知を許可したならば `<iframe>` で表示している Slack も許可されているのが適切．つまり，多重で通知音が鳴っている挙動が適切となる．

## どうする？

どうしよう…


