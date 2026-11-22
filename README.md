# yamamoto-yuta.github.io

## 初回セットアップ

```sh
git clone git@github.com:yamamoto-yuta/yamamoto-yuta.github.io.git
cd yamamoto-yuta.github.io/
git submodule update --init --recursive
cp .env.sample .env
docker compose build
```

## ローカルでの起動

```sh
make server
```

ブラウザで <http://localhost:1313/> にアクセスしてください。

## 使い方

Makefileを参照。
