---
title: "PageRankメモ"
description:
slug: pagerank-memo
date: 2020-03-02T15:00:00Z
lastmod: 2020-03-02T15:00:00Z
image:
math:
license:
hidden: false
comments: true
draft: false
---

<font size="1" align="right">

[✏️ 編集](https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/blob/main/content/post/pagerank-memo/index.md)

</font>

## PageRank とは？

- Google の検索エンジンに用いられている Web ページの価値評価を行うアルゴリズム
- 価値評価には Web ページのリンク関係を用いている

## 直感的な理解

1. Web ページの中からランダムにページを 1 つ決める
1. そのページに貼られているリンクからランダムにページを遷移していく
1. ページ遷移を繰り返して、最終的にどのページを開いている確率が高いか？

- その確率が PageRank

- 重要なページはたくさん引用されるので，↑ の確率が高くなる．

## 計算方法

### 1. 各ページのリンク関係から遷移確率行列 P を作成

例えば，各ページのリンク関係が ↓ みたいな場合，

<img width="414" alt="image.png (27.4 kB)" src="https://img.esa.io/uploads/production/attachments/14611/2020/07/29/74743/a7b80982-91e5-42ff-97fa-59c4e7854a9b.png">

$P$ は ↓ になる

$$
P = \left(
        \begin{array}{ccc}
            0   & 0   & 1/2 & 1/2 & 0   \\
            1/2 & 0   & 0   & 1/2 & 0   \\
            1/2 & 0   & 0   & 0   & 1/2 \\
            1/4 & 1/4 & 1/4 & 0   & 1/4 \\
            1/2 & 1/2 & 0   & 0   & 0
        \end{array}
    \right)
$$

- 行方向：遷移元のページ
- 列方向：遷移先のページ
- 要素：遷移元ページから遷移先ページへの遷移確率
  ex. ページ 1→ ページ 3 への遷移確率は $p_{13} = 1/2$

### 2. 遷移確率行列の固有値と固有ベクトルを計算する

#### 2.1. なぜ固有値と固有ベクトルを計算するのか？

$t$ 回遷移した時にページ $i$ を開いている確率を $x_{t_i}$ として，各ページでの確率をベクトル $\vec{x_t}$ を用いて次のようにまとめる．

$$
\vec{x_t} = \left(
        \begin{array}{ccc}
            x_{t_1} & x_{t_2} & \cdots & x_{t_i} & \cdots
        \end{array}
    \right)
$$

したがって，t+1 回目の遷移は次のように表せる．

$$
\vec{x_{t+1}} = \vec{x_t} P
$$

このようにして何回も遷移を繰り返していくと$\vec{x_t}$は一定に収束する．つまり，

$$
\vec{x_t} = \vec{x_t} P
$$

となる．

#### 2.2. 固有値と固有ベクトルを計算する

行列 $P$ の固有値 $\lambda$ ，固有ベクト $\vec{x}$ は次のような関係にある．

$$
\vec{x} P = \lambda \vec{x}
$$

したがって，固有値 $\lambda = 1$ に対応する固有ベクトルが PageRank となる（※ PageRank は確率なので後で正規化する必要あり）．

## 補足

↑ で説明した計算方法は最もシンプルなものであり，実際にはもう少し改良がなされている．以下にその改良をいくつか挙げる．

### 改良１　ランダムジャンプ

↓ のようなネットワークグラフだと ② と ④ で閉ループが形成されていて，まともに PageRank が計算できない．そのため，一定確率でリンクされていないページへジャンプするようになっている．

<img width="358" alt="image.png (13.7 kB)" src="https://img.esa.io/uploads/production/attachments/14611/2020/07/29/74743/a41a95e6-0971-441f-b66d-6df74ded9943.png">

### 改良２　カテゴリの概念

実際のネットサーフィンでは同じカテゴリのページ間の方が，違うカテゴリのページ間より遷移する可能性が高いと考えられる（例：サッカーのページを開いている人が次に開くページは，同じスポーツカテゴリである野球のページの方が，全く異なるカテゴリである手芸のページより可能性が高い）．

## 参考文献

- [PageRank アルゴリズムおよびそれに関連する研究について](http://www.kentmiyajima.com/document/pagerank.pdf)
- [いまさら学ぶ PageRank アルゴリズム](https://ohke.hateblo.jp/entry/2018/12/29/230000)
