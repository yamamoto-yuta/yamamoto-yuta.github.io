---
title: "executeScript() で呼ぶ関数の中で別ファイルの関数を呼び出したい"
description:
slug: executing-functions-from-other-files-in-executescript
date: 2023-08-05T15:57:00Z
lastmod:
image:
math:
license:
hidden: false
comments: true
draft: false
---

先日、ブラウザ拡張機能「 [CSV2MD Shortcut](https://chrome.google.com/webstore/detail/csv2md-shortcut/fakcffdpcdlhgphdbcanlningmnoigoe?hl=ja) 」の [v0.2.0 をリリースした](https://github.com/yamamoto-yuta/csv2md-shortcut/releases/tag/v0.2.0) 。このバージョンでは新機能として Popup からテキスト変換を行えるようにした。
<br />
v0.1.0 では BSW にテキスト変換処理を実装していた。 Popup からテキスト変換を行えるようにするにあたってその処理を BSW から切り出そうとした。が、うまくいかなかった…。
<br />
この記事では、そのときの試行錯誤をログとして残す。
<br />

---

<br />

該当 issue:

https://github.com/yamamoto-yuta/csv2md-shortcut/issues/35

検証用リポジトリ:

https://github.com/yamamoto-yuta/chrome-extension-injected-code-debug

公式ドキュメントの記載:

> For the `func` key, you can pass in a TS function from your project. It will be transpiled into JS when your extension bundles. You may also use the `files` key to inject a file from the root of the built bundle.

これを読む限り、ビルド済みファイルに手を加えるしか無さそう…？（であれば、それは管理面倒くさくなりそうなのでやらない方が良さそう…）
