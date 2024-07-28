---
title: "NuPhy Air75 V2 キーボードを買ったので、キー割り当てメモ"
description:
slug: nuphy-air75-v2-keyboard-layout-memo
date: 2024-03-22T17:27:00Z
lastmod:
image:
math:
license:
hidden: false
comments: true
draft: false
---

## 買ったキーボード

NuPhy Air75 V2 ワイヤレスメカニカルキーボード

- 日本の販売ページ: [Air75 V2 ワイヤレスメカニカルキーボード – Nuphy Japan](https://sanyoshop.jp/products/air75-v2)
- NuPhy 公式販売ページ: [NuPhy Air75 V2 QMK/VIA Wireless Custom Mechanical Keyboard](https://nuphy.com/collections/in-stock-keyboards/products/air75-v2)

## キー割り当て

### 利用環境

- キーボード:
  - NuPhy Air75 V2 （US 配列）
- PC:
  - Mac (JIS 配列)
  - Windows （JIS 配列）

### Win/Mac のデバイス切り替え

下記ショートカットキーでデバイス切り替えが可能。

```
FN + 1 / 2 / 3 / 4 = Bluetooth 1 / 2/ 3 / 2.4GHz
```

今回は FN + 1 を Mac 、 FN + 2 を Windows に割り当てた。

また、キーボードに Win/Mac の切り替えスイッチがあるので、接続先の PC に合わせてスイッチを切り替えることにした。

![image](https://i.shgcdn.com/7d4f1cc6-b5e7-4733-966f-b4f800054518/-/format/auto/-/preview/3000x3000/-/quality/lighter/)

（画像引用: [NuPhy Air75 V2 QMK/VIA Wireless Custom Mechanical Keyboard](https://nuphy.com/collections/in-stock-keyboards/products/air75-v2)）

これにより、 Windows と Mac で使用する VIA のレイヤーを切り替えることができる。

![image](https://cdn.shopify.com/s/files/1/0537/7920/2230/files/pf-6726f98f--1629364400319.jpg?v=1698227316)

（画像引用: [VIA– SUPER KOPEK](https://superkopek.jp/pages/howtouse-via)）

> 参考: [VIA– SUPER KOPEK](https://superkopek.jp/pages/howtouse-via#:~:text=VIA%E3%81%A7%E3%81%AF%E3%80%81%E3%82%AD%E3%83%BC%E3%83%9C%E3%83%BC%E3%83%89%E3%81%AE%E5%90%84%E3%83%AC%E3%82%A4%E3%83%A4%E3%83%BC%E3%81%AE%E5%90%84%E3%82%AD%E3%83%BC%E3%82%92%E3%82%AB%E3%82%B9%E3%82%BF%E3%83%9E%E3%82%A4%E3%82%BA%E3%81%99%E3%82%8B%E3%81%93%E3%81%A8%E3%81%8C%E3%81%A7%E3%81%8D%E3%80%81Mac%E7%94%A8%E3%81%AB%E3%81%AF2%E3%81%A4%E3%81%AE%E3%83%AC%E3%82%A4%E3%83%A4%E3%83%BC%E3%80%81Windows%E7%94%A8%E3%81%AB%E3%81%AF2%E3%81%A4%E3%81%AE%E3%83%AC%E3%82%A4%E3%83%A4%E3%83%BC%E3%81%8C%E3%81%82%E3%82%8A%E3%81%BE%E3%81%99%E3%80%82)

### Mac でのキー割り当て

Mac ではキーボードを繋ぐとダイアログが出てきて、その指示に従えば JIS/US を判別してくれる。そのため、繋ぐだけで最低限使える状態になった。

以前のキーボードでは左キーを下記の配置で使っていた。

```
Ctrl | Cmd | Opt
```

そのため、 Air75 V2 でもキー割り当てを変更し、同じ配置にした。

キー割り当ての変更は VIA で行った。

NuPhy Air75 V2 における VIA を使ったキー割り当て変更については、次の公式ページに記載されている手順で行った。

> 公式ページ: [VIA Usage Guide for NuPhy Keyboards](https://nuphy.com/pages/via-usage-guide-for-nuphy-keyboards)

実際に割り当てた結果が次の画像。なお、 LWin = LCmd 、 LAlt = LOpt と対応している。

![image](https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/assets/55144709/10a757ac-b6f7-4d99-8d91-b49ed6a97c21)

キー割り当てに合わせて、キーキャップも入れ替えた（CMD と OPT のキーキャップが同じ形状で良かった…）。

![image](https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/assets/55144709/8b1cf674-b64d-428b-b4ee-13c432db8b10)

### Win でのキー割り当て

JIS 配列の Windows に US 配列のキーボードを繋ぐ方法はいくつかあるようだが、今回は [ULE4JIS](https://github.com/dezz/ULE4JIS/tree/master/publish) というフリーソフトを使う方法を採用した。理由は Capslock でかな/英字のモード切替を行いたかったから。

> 参考: [ノートパソコンは JIS 配列で外付けキーボードを US 配列に（Windows）](https://mastdesign.me/20240107-jiskeyboard-uskeyboard/)

Mac の Cmd の位置に Win の Ctrl を置きたかったので、 VIA で次のように割り当てた。

![image](https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/assets/55144709/869c7ddf-580e-4e75-a307-77b42795bd72)
