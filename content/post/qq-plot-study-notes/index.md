---
title: "Q-Qプロット勉強メモ"
description:
slug: qq-plot-study-notes
date: 2023-01-07T15:00:00Z
lastmod:
image:
math:
license:
hidden: false
comments: true
draft: false
---

## 「Q-Q プロット」って何？

2 つの確率分布の分位数を互いにプロットして，両者がどのくらい類似した確率分布なのかを可視化する手法．

縦軸に調べたい確率分布の分位数，横軸に理論分布の確率密度関数の逆関数をプロットする．分布が類似していれば $y=x$ 的な直前上にプロットされる．

Q-Q プロットの一例:

<img width="516" alt="1fe932b0e2d4ef4fe94fad297b47bb7b.png (30.4 kB)" src="https://img.esa.io/uploads/production/attachments/14611/2023/01/08/74743/349093a2-1682-4e62-8604-3c68df52313b.png">

> 引用: [【Python】正規分布に従っているかを調べる手法 3 種 | データサイエンス情報局](https://analysis-navi.com/?p=3302)

Q-Q プロットの縦軸，横軸の関係をアニメーションにしたもの:

![](https://camo.qiitausercontent.com/0757163be4e5748e85dea4b244da7af84a4c11dd/68747470733a2f2f71696974612d696d6167652d73746f72652e73332e616d617a6f6e6177732e636f6d2f302f35303637302f32343037656536322d366335352d336437392d303762332d6565383132643361313962312e676966)

> 引用: [【統計学】Q-Q プロットの仕組みをアニメーションで理解する。 - Qiita](https://qiita.com/kenmatsu4/items/59605dc745707e8701e0)

## やってみる

検証コード全体はコチラ:

> Google Colab: https://colab.research.google.com/drive/1wSn2s6tbKpCUa6Gbi7zMsIzWZzTCkT_-?usp=sharing

import:

```python
import numpy as np
import matplotlib.pyplot as plt
import japanize_matplotlib
import scipy.stats as st
from scipy.special import ndtri
```

### 正規分布からランダムサンプリングしたデータが正規分布と類似しているか調べる

#### 縦軸

サンプリングしたデータのヒストグラム:

```python
N = 200     # データ件数
MEAN = 10    # 平均
STD = 3   # 標準偏差

data = np.random.normal(loc=MEAN, scale=STD, size=N)

plt.title(f"正規分布からランダムサンプリングしたプロットのヒストグラム\n（平均={MEAN}，標準偏差={STD}）")
plt.xlabel("階級")
plt.ylabel("度数")
plt.hist(data, bins=20)
plt.grid(True)
plt.show()
```

<img width="388" alt="image.png (6.8 kB)" src="https://img.esa.io/uploads/production/attachments/14611/2023/01/08/74743/e3323cd4-9401-44b3-a933-c9940dd6e2cc.png">

データの分位数:

```python
sorted_data = np.sort(data)

x = np.linspace(0, 1, N)
plt.figure(figsize=(5, 5))
plt.title("正規分布からランダムサンプリングしたプロットの分位数")
plt.xlabel("分位数")
plt.ylabel("値")
plt.xlim(0, 1)
plt.scatter(x, sorted_data)
plt.grid(True)
plt.show()
```

<img width="342" alt="image.png (9.8 kB)" src="https://img.esa.io/uploads/production/attachments/14611/2023/01/08/74743/e9dccd1a-385a-4672-922d-551ad1241da0.png">

#### 横軸

今回の理論分布は正規分布なので，正規分布の確率密度関数（＝正規累積分布関数）の逆関数を用いる．

正規累積分布:

```python
x = np.linspace(-STD, STD, N)
y_cdf = st.norm.cdf(x)

plt.figure(figsize=(5, 5))
plt.title(f"正規累積分布関数\n（定義域=[{-STD}, {STD}]）")
plt.xlabel("x")
plt.ylabel("y")
plt.scatter(x, y_cdf)
plt.grid(True)
```

<img width="328" alt="image.png (8.4 kB)" src="https://img.esa.io/uploads/production/attachments/14611/2023/01/08/74743/d1df61f7-4496-419d-abcd-9a6b5efe7f01.png">

正規累積分布関数の逆関数:

```python
x = np.linspace(0, 1, N)
inv_norm = ndtri(x)

plt.figure(figsize=(5, 5))
plt.title(f"正規累積分布関数の逆関数\n（定義域=[{0}, {1}]）")
plt.xlabel("x")
plt.ylabel("y")
plt.scatter(x, inv_norm)
plt.grid(True)
```

<img width="326" alt="image.png (8.4 kB)" src="https://img.esa.io/uploads/production/attachments/14611/2023/01/08/74743/30c44d00-6b05-4316-82a4-60008def8f6b.png">

#### Q-Q プロット

```python
plt.figure(figsize=(5, 5))
plt.title(f"Q-Qプロット")
plt.xlabel("理論分布")
plt.ylabel("対象データの分布")
plt.scatter(inv_norm, sorted_data)
plt.grid(True)
```

<img width="326" alt="image.png (8.6 kB)" src="https://img.esa.io/uploads/production/attachments/14611/2023/01/08/74743/3a788c54-b744-4e02-ba64-4ef112798569.png">

グラフが一直線になっていることが分かり，対象データの確率分布が正規分布に類似していることが確認できた．

## 個人的な理解

- 同じ分布なら，ソートして分位数で可視化したときの分布も同じはず
  - その場合，同じデータを x 軸，y 軸両方にプロットするのと同じなので，そのプロットは $y=x$ 的な感じになる
- 理論分布の分位数プロットは累積確率関数が使える
  - 「なら，理論分布の関数から分位数プロット生成してもいけるのでは？」と思ってやってみたけど，Q-Q プロット生成時の逆関数値が分からなくて詰んだ…

## 実用

SciPy の `stats.probplot()` を使えば簡単に Q-Q プロットを作成できる．

```python
fig = plt.subplots(figsize=(5, 5))

st.probplot(sorted_data, dist="norm", plot=plt)
plt.show()
```

<img width="335" alt="image.png (11.8 kB)" src="https://img.esa.io/uploads/production/attachments/14611/2023/01/08/74743/b6bc7e5f-8d28-49cb-a7dd-3078b4a433aa.png">

## 参考記事

- [【Python】正規分布に従っているかを調べる手法 3 種 | データサイエンス情報局](https://analysis-navi.com/?p=3302)
- [正規 Q-Q プロット | 統計用語集 | 統計 WEB](https://bellcurve.jp/statistics/glossary/2071.html)
- [【統計学】Q-Q プロットの仕組みをアニメーションで理解する。 - Qiita](https://qiita.com/kenmatsu4/items/59605dc745707e8701e0)
- [Q-Q プロット - Wikipedia](https://ja.wikipedia.org/wiki/Q-Q%E3%83%97%E3%83%AD%E3%83%83%E3%83%88)
