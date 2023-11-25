---
description: 'Slack の Slash Commands を作成した際に色々つまづいたのでメモに残す。  ## 今回のゴール  - `/echo`
  で `echo` と返すスラッシュコマンドを作成する - `/hoge` で `hoge` と返すスラッシュコマンドを作成する  ## ngrok のセットアップ  ダウンロードページの
  URL :   アカウントを作成せずに利用していたが、次のエラーが出たのでア...'
posted_at: 2023-11-25 17:45:01+00:00
slug: '23'
tag_ids: []
title: Slack の Slash Commands 作成メモ
updated_at: ''

---
Slack の Slash Commands を作成した際に色々つまづいたのでメモに残す。

## 今回のゴール

- `/echo` で `echo` と返すスラッシュコマンドを作成する
- `/hoge` で `hoge` と返すスラッシュコマンドを作成する

## ngrok のセットアップ

ダウンロードページの URL :
https://ngrok.com/download

アカウントを作成せずに利用していたが、次のエラーが出たのでアカウントを作成した:

```
ERR_NGROK_6022
Before you can serve HTML content, you must sign up for an ngrok account and install your authtoken.

https://ngrok.com/docs/errors/err_ngrok_6022/
```

次のコマンドで ngrok を起動させる（今回は 3000 番ポートを使うことにする）:

```
$ ngrok http 3000
```

## 各種ファイルの作成

`.env.sample` :

```
WORKING_DIR=/usr/src/app
OPENAI_API_KEY=# Your OpenAI API key
SLACK_BOT_TOKEN=# OAuth & Permissions > OAuth Tokens for Your Workspace > Bot User OAuth Access Token
SLACK_SIGNING_SECRET=# Basic Information > App Credentials > Signing Secret
```

`Dockerfile` :

```
FROM python:3.10

COPY requirements.txt ${WORKING_DIR}/

RUN apt-get update && apt-get upgrade -y

RUN pip install --upgrade pip && \
    pip install -r requirements.txt
```

`docker-compose.yml` :

```yml
version: "3.7"

services:
  app:
    build: .
    env_file:
      - .env
    volumes:
      - .:$WORKING_DIR
    working_dir: $WORKING_DIR
    tty: true
    ports:
      - 3000:3000
```

`requirements.txt` :

```txt
slack_bolt==1.18.1
```

`main.py` :

```python
import os

from slack_bolt import App

app = App(
    signing_secret=os.environ["SLACK_SIGNING_SECRET"],
    token=os.environ["SLACK_BOT_TOKEN"]
)


@app.command("/echo")
def echo(ack, respond):
    ack()
    respond("echo")


@app.command("/hoge")
def hoge(ack, respond):
    ack()
    respond("hoge")


if __name__ == "__main__":
    app.start(port=3000)
```

実行コマンドは次のとおり:

```
$ docker-compose build
$ docker-compose up -d
$ docker exec -it <CONTAINER_ID> bash
[IN CONTAINER]# python main.py
```

## Slack App 設定

### App 作成

まずは普通に Slack App を作成。 App Display Name 、 Default username がデフォルトだと空欄になっており、これらを設定しないとワークスペースへインストールできないので、忘れず設定すること。

参考:

- [【Slack】インストールするボットユーザーがありませんと出たときの対処方法 | THE SIMPLE](https://the-simple.jp/slack-nobotuser)

### Slash Commands

```yml
  slash_commands:
    - command: /echo
      url: https://xxxxxxxxxx.ngrok-free.app/slack/events
      description: echo
      should_escape: false
    - command: /hoge
      url: https://xxxxxxxxxx.ngrok-free.app/slack/events
      description: hoge
      should_escape: false
```

⚠️ `url` のエンドポイントは `/echo` や `/hoge` ではなく一律 `/slack/events` （ここで無駄に時間を溶かしてしまった…）

参考: [コマンドのリスニングと応答 - Slack | Bolt for Python](https://slack.dev/bolt-python/ja-jp/concepts#basic:~:text=%E3%82%A2%E3%83%97%E3%83%AA%E3%81%AE%E8%A8%AD%E5%AE%9A%E3%81%A7%E3%82%B3%E3%83%9E%E3%83%B3%E3%83%89%E3%82%92%E7%99%BB%E9%8C%B2%E3%81%99%E3%82%8B%E3%81%A8%E3%81%8D%E3%81%AF%E3%80%81%E3%83%AA%E3%82%AF%E3%82%A8%E3%82%B9%E3%83%88%20URL%20%E3%81%AE%E6%9C%AB%E5%B0%BE%E3%81%AB%20/slack/events%20%E3%82%92%E3%81%A4%E3%81%91%E3%81%BE%E3%81%99%E3%80%82)

### OAuth & Permissions

<img src='/static/images/articles/23/3ae2b7aa38ca14bd1d921197c013e6e5.webp' origin_url='https://github.com/yamamoto-yuta/article-summarize-bot/assets/55144709/99b922b3-405a-477c-bfea-a2ebf1480ebc' alt='image' />

## 実際に動かしてみる

| 入力 |  実行結果 |
| --- | --- |
| ![image](https://github.com/yamamoto-yuta/article-summarize-bot/assets/55144709/83a521fd-f0c4-4811-bb05-f9691bda87c2) |  ![image](https://github.com/yamamoto-yuta/article-summarize-bot/assets/55144709/604b0883-79a4-4de9-a2bc-bef60f723b95) |
| ![image](https://github.com/yamamoto-yuta/article-summarize-bot/assets/55144709/64f3c44a-574e-4bf6-89d0-77f6279b1c16) |  ![image](https://github.com/yamamoto-yuta/article-summarize-bot/assets/55144709/cf2f8f26-81c3-458f-8296-e16f220789ce) |



