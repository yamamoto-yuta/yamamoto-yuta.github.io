---
description: '※ この記事は、私が2020/07/02に書いたメモを転記したものです。  ---  ## 風邪薬の効果を検証 新しく開発した風邪薬に「回復を早める効果があるか」を検証する  ##
  データ収集 風邪を引いている人を100人集めて薬を飲んでもらい，回復日数を計測する  ## 効果を確かめる ### 統計的検定の方針 収集した「投薬者の平均回復日数」とあらかじめ分かっている「一般人の平均回復日数」の差...'
posted_at: 2023-11-29 00:23:53+00:00
slug: '25'
tag_ids: []
title: 統計的有意とp値
updated_at: ''

---
※ この記事は、私が2020/07/02に書いたメモを転記したものです。

---

## 風邪薬の効果を検証
新しく開発した風邪薬に「回復を早める効果があるか」を検証する

## データ収集
風邪を引いている人を100人集めて薬を飲んでもらい，回復日数を計測する

## 効果を確かめる
### 統計的検定の方針
収集した「投薬者の平均回復日数」とあらかじめ分かっている「一般人の平均回復日数」の差を比較する．この差が一定以上であれば薬に効果があるとみなす．

※ 一般人の風邪の回復日数はその分布（回復の平均日数、回復日数の個人差など) があらかじめ分っているものとする

### 統計的検定の手順
__帰無仮説__：「薬に効果がない」＝「薬を飲んでも飲まなくても回復日数に変わりはない」
__対立仮説__：「薬に効果がある」＝「薬を飲んだ方が回復日数が短くなる」

1. 測定した100人の平均回復日数を算出
1. 帰無仮説の確率分布（＝一般人の回復日数の確率分布）に従う環境で，測定した値になる確率を算出
1. 算出した確率が低かった場合，「薬に効果がない」という帰無仮説を棄却し「薬に効果がある」という対立仮説を採用する

## 判断に使う数値
「一定以上の差がある」（有意差が認められた）という判断を下すためには数値的判断基準が必要

__p値__：帰無仮説が正しい場合，観測値と等しいかそれより極端な値を取る確率
__有意水準__：p値がどのくらい小さい場合に帰無仮説を棄却するか，その閾値

p値が有意水準を下回る＝有意差が認められた

## 風邪薬のケースの場合
### p値
一般人から100人をランダムに選んだ場合の確率分布
<img width="481" alt="image.png (13.1 kB)" src="https://img.esa.io/uploads/production/attachments/14611/2020/07/02/74743/b08fa928-8517-4ac4-8efb-b629d7261676.png">

p値
- 平均回復日数が3.7日以下になる確率＝20%
- 平均回復日数が3.2日以下になる確率＝10%
- 平均回復日数が2.9日 以下になる確率 ＝5%

### 有意水準
検定前にあらかじめ決めておく
- 今回は有意水準＝5%に設定

### 判定方法
「薬を飲んだ人」100人の平均が3.7日だった場合
→それは「一般人」100人でも20%の確率であり得る値＝薬に効果があるとは言えない（有意差が認められなかった）

「薬を飲んだ人」100人の平均が2.9日以下だった場合
→それは「一般人」100人でも5%以下の確率でしかあり得ない値＝薬に効果があると言える（有意差が認められた）

## p値の解釈に関する注意点
### p値は効果を示すものではない
今回の風邪薬の場合では平均回復日数が3.7日以下になる確率＝20%だったが，サンプル数がもっと多かったり少なかったりすればこの20%という値は変わる

### 何回も試行して有効なp値を出してはいけない
p値=0.05の場合，100回に5回しか起こらない低い確率を前提としているので，何回も試行するとその前提が崩れてしまう
おみくじで大吉が出るまで何回も引くようなもの

### p値だけで判断してはいけない
p値はあくまで指標の一つにすぎない
その他の統計手法，実務上の考慮点などを鑑みて最終的な判断を下す必要がある

### 帰無仮説が棄却されなくても，帰無仮説が正しいということにはならない
帰無仮説が棄却されなかった＝有意差がが認められなかった
つまり，帰無仮説が正しいということを示したわけではない

# 参考文献
- [統計的有意 p値って何ですか？](https://note.com/tenkamere/n/n5f85b0499061)



