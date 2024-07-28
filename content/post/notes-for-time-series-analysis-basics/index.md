---
title: "時系列解析の触りだけメモ"
description:
slug: notes-for-time-series-analysis-basics
date: 2020-06-30T15:00:00Z
lastmod:
image:
math:
license:
hidden: false
comments: true
draft: false
---

## 時系列解析とは？

時系列データ（毎日の売り上げ，日々の気温 etc…）を分析する手法
過去のデータから未来のデータを予測することが可能

## 回帰分析で予測すればいいのでは？

時系列データの回帰分析には注意が必要

回帰分析：　最小二乗法を用いて傾きや切片を推定
→ 最小二乗法が使える条件：　データの独立性

独立でないデータとは？
→ 過去の値に合わせて現在の値も変わってしまう（自己相関のある）データ

-     例）「昨日の売り上げが多ければ，今日の売り上げも多くなる」

時系列データは独立でないことが多い　 → 　回帰分析ではうまくいかない場合が多い

## 時系列データへの回帰分析フローチャート

> <img width="1134" alt="image.png (88.5 kB)" src="https://img.esa.io/uploads/production/attachments/14611/2020/07/02/74743/0b5394e3-3c40-4609-a786-3fcfaab2cdec.png">

> 引用：https://logics-of-blue.com/time-series-regression/

- 誤差分布には正規分布を仮定（正規分布以外の場合，状態空間モデル等での対応が必要）
- 検定の方法はいろいろあり、このフローチャート通りにしてもうまくいかない or このやり方以外のうまい方法がある場合もあるので、あくまで参考程度

## 検定

### 単位根検定

時系列データが単根過程かどうかを判定する検定

#### 定常過程

- 期待値（平均）と自己相関が常に一定の確率過程
- 大局的に見て真っ平 - 例）ホワイトノイズ
  <img width="400" alt="image.png (42.6 kB)" src="https://img.esa.io/uploads/production/attachments/14611/2020/07/02/74743/62030f45-ecdc-4200-82a5-662ce084de9b.png">

#### 単位根過程

<img width="1212" alt="image.png (64.5 kB)" src="https://img.esa.io/uploads/production/attachments/14611/2020/07/02/74743/f10641e9-35ff-4dca-9dfa-f84978e7e75e.png">

- 原系列$y_t$が非定常過程で，差分系列$\Delta y_t = y_t - y_{t-1}$が定常過程の時系列
  - 例）ランダムウォーク

#### 単位根過程に回帰分析を行うとどうなるか？

有意な回帰係数が得られる
しかし，無関係な２つの系列に対して有意な回帰が行えているのはおかしい
したがって，単位根過程に回帰分析を行うのは良くない
→ 検定で時系列データが単位根過程がどうか調べる必要がある

#### 単位根検定

##### ADF 検定

- 帰無仮説：単位根過程である
- 対立仮説：単位根過程でない

として，p 値<0.05 で帰無仮説棄却＝単位根過程でないとする単位根検定

## 参考文献

- [Python による時系列分析の基礎](https://logics-of-blue.com/python-time-series-analysis/)
- [時系列解析\_理論編](https://logics-of-blue.com/時系列解析_理論編/)
- [時系列データへの回帰分析](https://logics-of-blue.com/time-series-regression/)
