---
title: "いつも使ってるSlack向け絵文字ジェネレーターがどうやって絵文字を生成してるか調べてみたメモ"
description:
slug: "how-slack-emoji-generator-works"
date: 2023-05-07T16:08:00Z
lastmod: 2023-08-12T02:50:00Z
image:
math:
license:
hidden: false
comments: true
draft: false
---

いつも使ってる Slack 向け絵文字ジェネレーター:

> [絵文字ジェネレーター - Slack 向け絵文字を無料で簡単生成](https://emoji-gen.ninja/)

リポジトリを見てみるとバックエンドに Python を用いており、その中で [emojilib](https://github.com/emoji-gen/emojilib) という自作ライブラリを用いていることが分かった。

そこで emojilib のリポジトリを見てみると、 emojilib は [libemoji](https://github.com/emoji-gen/libemoji) という C/C++ 製の自作ライブラリの Python ラッパーということが分かった。

emojilib を動かせるようにした Dockerfile を下記に示す。 emojilib 自体は `pip install` でインストールできるのだが、 libemoji を動かすため依存が [いくつかあった](https://github.com/emoji-gen/libemoji#debian-10-buster) ので別途 `apt-get install` で入れている。

```Dockerfile
FROM python:3.7

RUN apt-get update && apt-get upgrade -y

RUN apt-get install -y \
    git \
    cmake \
    g++ \
    libfontconfig1-dev \
    libx11-dev \
    libxcomposite-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    freeglut3-dev

RUN pip install --upgrade pip

RUN pip install emojilib --extra-index-url https://repo.fury.io/emoji-gen/
```
