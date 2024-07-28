---
title: "Selenium+Python環境をDockerで作ったときのメモ"
description:
slug: selenium-python-environment-docker-memo
date: 2022-12-30T15:00:00Z
lastmod:
image:
math:
license:
hidden: false
comments: true
draft: false
---

## はじめに

Selenium+Python 環境を Docker で作った際のメモ．基本的に下記の記事を参考に行った:

> 参考記事: [第 662 回　 Docker+Selenium Server で Web ブラウザ自動操作環境を作る | gihyo.jp](https://gihyo.jp/admin/serial/01/ubuntu-recipe/0662)

また，記事中のコードは下記リポジトリに上がっている:

> リポジトリ: https://github.com/yamamoto-yuta/selenium-on-docker-sample

## 手順

### 1. Docker イメージを pull

今回はスクレイピングできれば OK だったので `standalone-chrome` を pull した

```
$ docker pull selenium/standalone-chrome
```

### 2. 素のイメージには pip と selenium が入っていないので，入れたイメージを Dockerfile で作成

```
FROM selenium/standalone-chrome

USER root
RUN apt-get update && apt-get upgrade -y && apt install -y python3-pip

USER 1200
RUN pip3 install selenium
```

なお， `apt` コマンドを使おうとしたら Permission denied と言われたので，一時的に root ユーザにしている:

```
=> ERROR [2/3] RUN apt-get update && apt-get upgrade -y && apt install -y python3-pip                                                            1.0s
------
 > [2/3] RUN apt-get update && apt-get upgrade -y && apt install -y python3-pip:
#0 0.900 Reading package lists...
#0 0.925 E: List directory /var/lib/apt/lists/partial is missing. - Acquire (13: Permission denied)
------
failed to solve: executor failed running [/bin/sh -c apt-get update && apt-get upgrade -y && apt install -y python3-pip]: exit code: 100
```

### 3. 環境設定を `docker-compose.yml` にまとめる

```yml
version: "3.9"

services:
  app:
    build: .
    image: "selenium-on-docker-sample"
    container_name: "selenium-on-docker-sample"
    volumes:
      - /dev/shm:/dev/shm
      - .:/usr/src/app
    working_dir: /usr/src/app
```

ポイントは下記の volumes 設定．この設定ではホストのメモリ領域 `/dev/shm` をマウントしている．これをしておかないとメモリ不足で正常に動作しないことがあるらしい:

```yml
volumes:
  - /dev/shm:/dev/shm
```

> 参考: [Selenium を docker で動かすと異様に遅い 特定サイトで落ちる場合の対処法 │ wonwon eater](https://wonwon-eater.com/python-selenium-docker/)

なお，上記の方法はホスト OS が Linux の場合に使える方法で，他の OS の場合は直接サイズを指定する方法があるらしい:

```yml
build:
context: .
shm_size: "2gb"
```

> 参考: [Selenium を docker で動かすと異様に遅い 特定サイトで落ちる場合の対処法 │ wonwon eater](https://wonwon-eater.com/python-selenium-docker/)

公式ドキュメント:

> 1. Start a Docker container with Firefox
>
> ```
> docker run -d -p 4444:4444 -p 7900:7900 --shm-size="2g" selenium/standalone-firefox:4.7.2-20221219
> ```
>
> （中略）
> ☝️ When executing docker run for an image that contains a browser please use the flag --shm-size=2g to use the host's shared memory.
>
> 引用: [SeleniumHQ/docker-selenium: Docker images for Selenium Grid](https://github.com/SeleniumHQ/docker-selenium)

### 3. コンテナを起動して中に入る

```
$ docker compose up
$ docker exec -it <CONTAINER_ID> bash
```

### 4. スクレイピングスクリプトを実行

今回は下記のようなスクレイピングスクリプト `sample.py` を作成した．内容としては，「webdriver」でググって検索結果のページタイトルを標準出力する．

```python
import time

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys


# Chromeのオプション
options = webdriver.ChromeOptions()
driver = webdriver.Chrome('chromedriver', options=options)


try:
    # 要素の待機時間を最大10秒に設定
    driver.implicitly_wait(10)

    # http://www.google.com を開く
    driver.get("http://www.google.com")

    # 検索ボックスに「webdriver」と入力して検索
    driver.find_element(By.NAME, "q").send_keys("webdriver" + Keys.ENTER)
    time.sleep(5)

    # 検索結果のタイトルを取得して出力
    element_titles = driver.find_elements(By.TAG_NAME, "h3")
    for element_title in element_titles:
        print(element_title.text)

except:
    import traceback
    traceback.print_exc()

finally:
    # Chromeを終了
    input("何かキーを押すと終了します...")
    driver.quit()
```

実行結果:

```
seluser@aefbc6616615:/usr/src/app$ python3 sample.py
WebDriver - Selenium
WebDriver を使用して Microsoft Edge を自動化する
WebDriver - MDN Web Docs - Mozilla
WebDriver について私が知っていること (2017 年版)




10分で理解する Selenium - Qiita
ChromeDriver - WebDriver for Chrome
7. WebDriver API — Selenium Python Bindings 2 ドキュメント
WebDriverマウスとキーボードイベント
Pythonで自動化しよう！ ー Selenium Webdriverを ...
何かキーを押すと終了します...
```

## 過程で調べたこと

### `/dev/shm` って何？

tmpfs という Linux マシンのメモリに作成できるファイルシステムのマウントポイントの 1 つ．tmpfs は一見 RAM ディスクっぽいが，tmpfs はファイルシステムのためフォーマットが不要という違いがある（そのため，あらかじめ容量を確保する必要が無く，使用した分だけメモリを消費する）．

`/dev/shm` を利用するには，好きなディレクトリをマウントする．

> 参考: [tmpfs - Linux 技術者認定 LinuC | LPI-Japan](https://linuc.org/study/knowledge/441/)

### Selenium は 3 系と 4 系で書き方が変わっている

[元記事](https://gihyo.jp/admin/serial/01/ubuntu-recipe/0662) では `find_elements_by_*` 系メソッドが用いられていたが，それらはバージョン 4.3.0 廃止されており，現在は下記のような書き方になっている模様:

3 系:

```python
driver.find_elements_by_class_name("content")
```

4 系:

```python
# 引数にまとめて書くやり方に統一される
from selenium.webdriver.common.by import By
driver.find_elements(By.CLASS_NAME, "content")
```

> 引用: [【Selenium】急に AttributeError: 'WebDriver' object has no attribute が起きた - Qiita](https://qiita.com/syoshika_/items/288fc8bf552672589f4c)
