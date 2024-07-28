---
title: "Function Calling 触ってみたメモ"
description:
slug: function-calling-memo
date: 2023-11-25T11:54:00Z
lastmod:
image:
math:
license:
hidden: false
comments: true
draft: false
---

Function Calling が説明等を読んでもイマイチよくわからなかったので実際に試してみた。これはその時のメモ。

今回は次の公式ドキュメントの手順をやってみた。

https://platform.openai.com/docs/guides/function-calling

また、次の日本語解説記事が参考になった。

https://dev.classmethod.jp/articles/understand-openai-function-calling/

## セットアップ

今回、実行環境は Google Colab にした。

まずは OpenAI ライブラリをインストール。

```
!pip install openai
```

続いて、各種ライブラリのインポートと OpenAI クライアントを作成。

```python
import json
from openai import OpenAI

client = OpenAI(
    api_key=OPENAI_API_KEY
)
```

OpenAI API Key は次のページで作成できる:

> [API keys - OpenAI API](https://platform.openai.com/api-keys)

今回、 Function Calling の動作確認用に次のダミー関数を利用した。

```python
# Example dummy function hard coded to return the same weather
# In production, this could be your backend API or an external API
def get_current_weather(location, unit="fahrenheit"):
    """Get the current weather in a given location"""
    if "tokyo" in location.lower():
        return json.dumps({"location": "Tokyo", "temperature": "10", "unit": "celsius"})
    elif "san francisco" in location.lower():
        return json.dumps({"location": "San Francisco", "temperature": "72", "unit": "fahrenheit"})
    elif "paris" in location.lower():
        return json.dumps({"location": "Paris", "temperature": "22", "unit": "celsius"})
    else:
        return json.dumps({"location": location, "temperature": "unknown"})
```

## 全体像

公式ドキュメントのコードの全体像は次のとおり:

1. （AI が）質問に必要な関数を選び、引数を作成する
1. （プログラムが）関数を実行
1. （AI が）関数結果も入力に入れて質問に回答する

> 引用: [[OpenAI] Function calling で遊んでみたら本質が見えてきたのでまとめてみた | DevelopersIO](https://dev.classmethod.jp/articles/understand-openai-function-calling/#:~:text=%E5%87%A6%E7%90%86%E3%81%A8%E3%81%AF-,%EF%BC%88AI%E3%81%8C%EF%BC%89%E8%B3%AA%E5%95%8F%E3%81%AB%E5%BF%85%E8%A6%81%E3%81%AA%E9%96%A2%E6%95%B0%E3%82%92%E9%81%B8%E3%81%B3%E3%80%81%E5%BC%95%E6%95%B0%E3%82%92,%E9%96%A2%E6%95%B0%E7%B5%90%E6%9E%9C%E3%82%82%E5%85%A5%E5%8A%9B%E3%81%AB%E5%85%A5%E3%82%8C%E3%81%A6%E8%B3%AA%E5%95%8F%E3%81%AB%E5%9B%9E%E7%AD%94%E3%81%99%E3%82%8B,-%E3%81%A7%E3%81%99%E3%80%82%20AI%E3%81%AE)

## STEP 1 ｜会話と利用可能な関数をモデルに送る

公式ドキュメントのコード（日本語のコメントは自分で追記した）:

```python
# Step 1: send the conversation and available functions to the model

# 会話
messages = [{"role": "user", "content": "What's the weather like in San Francisco, Tokyo, and Paris?"}]

# 利用可能な関数
tools = [
    {
        "type": "function",
        "function": {
            "name": "get_current_weather",
            "description": "Get the current weather in a given location",
            "parameters": {
                "type": "object",
                "properties": {
                    "location": {
                        "type": "string",
                        "description": "The city and state, e.g. San Francisco, CA",
                    },
                    "unit": {"type": "string", "enum": ["celsius", "fahrenheit"]},
                },
                "required": ["location"],
            },
        },
    }
]

# モデルへ投げて回答を取得
response = client.chat.completions.create(
    model="gpt-3.5-turbo-1106",
    messages=messages,
    tools=tools,
    tool_choice="auto",  # auto is default, but we'll be explicit
)
```

`response` の中身はこんな感じ。今回はサンフランシスコ、東京、パリの 3 つの都市の天気を訊いているので、 `tool_calls` が 3 リクエスト分になっている。

```python
{
  'id': 'chatcmpl-xxxxxxxxxx',
  'choices': [
    Choice(
      finish_reason='tool_calls',
      index=0,
      message=ChatCompletionMessage(
        content=None,
        role='assistant',
        function_call=None,
        tool_calls=[
          ChatCompletionMessageToolCall(
            id='call_aaaaaaaaaa',
            function=Function(
              arguments='{"location": "San Francisco", "unit": "celsius"}',
              name='get_current_weather'
            ),
            type='function'
          ),
          ChatCompletionMessageToolCall(
            id='call_bbbbbbbbbb',
            function=Function(
              arguments='{"location": "Tokyo", "unit": "celsius"}',
              name='get_current_weather'
            ),
            type='function'
          ),
          ChatCompletionMessageToolCall(
            id='call_cccccccccc',
            function=Function(
              arguments='{"location": "Paris", "unit": "celsius"}',
              name='get_current_weather'
            ),
            type='function'
          )
        ]
      )
    )
  ],
  'created': 1700895213,
  'model': 'gpt-3.5-turbo-1106',
  'object': 'chat.completion',
  'system_fingerprint': 'fp_xxxxxxxxxx',
  'usage': CompletionUsage(
    completion_tokens=77,
    prompt_tokens=88,
    total_tokens=165
  )
}
```

この中から次の 2 つを取り出す。

```python
response_message = response.choices[0].message
tool_calls = response_message.tool_calls
```

次の処理に入る前に、 Function Calling が要求されているかのチェックが必要。

```python
# Step 2: check if the model wanted to call a function
if tool_calls:
  ...
```

## STEP 2 ｜実際に関数を実行する

公式ドキュメント:

```python
# Step 3: call the function
# Note: the JSON response may not always be valid; be sure to handle errors
available_functions = {
    "get_current_weather": get_current_weather,
}  # only one function in this example, but you can have multiple
messages.append(response_message)  # extend conversation with assistant's reply
# Step 4: send the info for each function call and function response to the model
for tool_call in tool_calls:
    function_name = tool_call.function.name
    function_to_call = available_functions[function_name]
    function_args = json.loads(tool_call.function.arguments)
    function_response = function_to_call(
        location=function_args.get("location"),
        unit=function_args.get("unit"),
    )
    messages.append(
        {
            "tool_call_id": tool_call.id,
            "role": "tool",
            "name": function_name,
            "content": function_response,
        }
    )  # extend conversation with function response
```

分解して見ていく。

利用可能な関数の辞書を作成している。今回は `get_current_weather()` しか利用できないので、辞書内のアイテムは 1 つだけになる。

```python
available_functions = {
    "get_current_weather": get_current_weather,
}  # only one function in this example, but you can have multiple
```

`available_functions` の中身は次のようになっている。関数がオブジェクトとして辞書に登録されている。

```python
{'get_current_weather': <function __main__.get_current_weather(location, unit='fahrenheit')>}
```

STEP 1 で得た `response_message` を `message` に `append` している。これは STEP 3 で最終的な回答を作成するために使用する。

```python
messages.append(response_message)  # extend conversation with assistant's reply
```

したがって、 `messages` の中身は次のようになる。

```python
[
  {
    'role': 'user',
    'content': "What's the weather like in San Francisco, Tokyo, and Paris?"
  },
  ChatCompletionMessage(
    content=None,
    role='assistant',
    function_call=None,
    tool_calls=[
      ChatCompletionMessageToolCall(
        id='call_aaaaaaaaaa',
        function=Function(
          arguments='{"location": "San Francisco", "unit": "celsius"}',
          name='get_current_weather'
        ),
        type='function'
      ),
      ChatCompletionMessageToolCall(
        id='call_bbbbbbbbbb',
        function=Function(
          arguments='{"location": "Tokyo", "unit": "celsius"}',
          name='get_current_weather'
        ),
        type='function'
      ),
      ChatCompletionMessageToolCall(
        id='call_cccccccccc',
        function=Function(
          arguments='{"location": "Paris", "unit": "celsius"}',
          name='get_current_weather'
        ),
        type='function'
      )
    ]
  )
]
```

STEP 1 で作成したリクエストをループで順次、実際に関数へリクエストしていく。

```python
# Step 4: send the info for each function call and function response to the model
for tool_call in tool_calls:
  ...
```

実際に関数を実行する部分は次のコード。

```python
# 呼び出す関数を取得
function_name = tool_call.function.name
function_to_call = available_functions[function_name]

# 関数に渡す引数を取得（引数は JSON 文字列で格納されているので json.loads() ）
function_args = json.loads(tool_call.function.arguments)

# 実際に関数を実行する
function_response = function_to_call(
    location=function_args.get("location"),
    unit=function_args.get("unit"),
)
```

関数の実行結果を `messages` へ `append` している。これは STEP 3 で最終的な回答を作成するためである。

```python
messages.append(
    {
        "tool_call_id": tool_call.id,
        "role": "tool",
        "name": function_name,
        "content": function_response,
    }
)  # extend conversation with function response
```

ループ終了時の `messages` の中身は次のようになっている。

```python
[{'role': 'user',
  'content': "What's the weather like in San Francisco, Tokyo, and Paris?"},
 ChatCompletionMessage(content=None, role='assistant', function_call=None, tool_calls=[ChatCompletionMessageToolCall(id='call_aaaaaaaaaa', function=Function(arguments='{"location": "San Francisco", "unit": "celsius"}', name='get_current_weather'), type='function'), ChatCompletionMessageToolCall(id='call_bbbbbbbbbb', function=Function(arguments='{"location": "Tokyo", "unit": "celsius"}', name='get_current_weather'), type='function'), ChatCompletionMessageToolCall(id='call_cccccccccc', function=Function(arguments='{"location": "Paris", "unit": "celsius"}', name='get_current_weather'), type='function')]),
 {'tool_call_id': 'call_aaaaaaaaaa',
   'role': 'tool',
   'name': 'get_current_weather',
   'content': '{"location": "San Francisco", "temperature": "72", "unit": "fahrenheit"}'},
 {'tool_call_id': 'call_bbbbbbbbbb',
  'role': 'tool',
  'name': 'get_current_weather',
  'content': '{"location": "Tokyo", "temperature": "10", "unit": "celsius"}'},
 {'tool_call_id': 'call_cccccccccc',
  'role': 'tool',
  'name': 'get_current_weather',
  'content': '{"location": "Paris", "temperature": "22", "unit": "celsius"}'}]
```

## STEP 3 ｜最終的な回答を作成する

公式ドキュメントのコード:

```python
second_response = client.chat.completions.create(
    model="gpt-3.5-turbo-1106",
    messages=messages,
)  # get a new response from the model where it can see the function response
```

second_response の中身:

```python
{
  'id': 'chatcmpl-yyyyyyyyyy',
  'choices': [
    Choice(
      finish_reason='stop',
      index=0,
      message=ChatCompletionMessage(
        content='Currently, the weather in San Francisco is 72°F, in Tokyo it is 10°C, and in Paris it is 22°C.',
        role='assistant',
        function_call=None,
        tool_calls=None
      )
    )
  ],
  'created': 1700895214,
  'model': 'gpt-3.5-turbo-1106',
  'object': 'chat.completion',
  'system_fingerprint': 'fp_eeff13170a',
  'usage': CompletionUsage(
    completion_tokens=29,
    prompt_tokens=169,
    total_tokens=198
  )
}
```

`second_response.choices[0].message.content` を見てみると、関数の実行結果が回答に組み込まれていることがわかる。

```python
'Currently, the weather in San Francisco is 72°F, in Tokyo it is 10°C, and in Paris it is 22°C.'
```

## 何が嬉しいのか？

（ほぼほぼ「 [[OpenAI] Function calling で遊んでみたら本質が見えてきたのでまとめてみた | DevelopersIO](https://dev.classmethod.jp/articles/understand-openai-function-calling/) 」に書かれていることではあるが…）

例えば、今回のように自然言語で各都市の気温を問い合わせる仕組みを作る場合、 ChatGPT だけでは各都市の気温は答えられないので API 等で別途情報を取得してくる必要がある（補足）。そのため、問い合わせ文から API 等へのリクエストに必要な情報を抽出する必要があった。

「 What's the weather like in San Francisco, Tokyo, and Paris? 」という質問の場合、（どのような情報がリクエストに必要かによるが）「 San Francisco 」「 Tokyo 」「 Paris 」の 3 つの情報を抽出する必要がある。

Function Calling が登場するまでは、プロンプトを工夫することで情報を抽出しやすくしていた。

例えば次のプロンプトを用いたとする。

```
次の問い合わせ文から都市を抽出してください。出力フォーマットは次のようにしてください:

## 出力フォーマット
- 都市1
- 都市2

## 問い合わせ文
What's the weather like in San Francisco, Tokyo, and Paris?
```

すると、 ChatGPT は次のように回答してくれる。

```
## 出力フォーマット
- San Francisco
- Tokyo
- Paris
```

今回の気温の例は出力フォーマットがシンプルだったので比較的指定したフォーマットで回答してくれているが、複雑な出力フォーマットだったりすると指定したフォーマットにしたがってくれなかったりする。

Function Calling を使えば、引数の仕様を指定すればそれに合うように情報を抽出してくれる。例えば今回の場合、次のように情報を抽出してくれていた。

```python
[
  ChatCompletionMessageToolCall(
    id='call_aaaaaaaaaa',
    function=Function(
      arguments='{"location": "San Francisco", "unit": "celsius"}',
      name='get_current_weather'
    ),
    type='function'
  ),
  ChatCompletionMessageToolCall(
    id='call_bbbbbbbbbb',
    function=Function(
      arguments='{"location": "Tokyo", "unit": "celsius"}',
      name='get_current_weather'
    ),
    type='function'
  ),
  ChatCompletionMessageToolCall(
    id='call_cccccccccc',
    function=Function(
      arguments='{"location": "Paris", "unit": "celsius"}',
      name='get_current_weather'
    ),
    type='function'
  )
]
```

## 補足: 今は Browse with Bing のおかげで ChatGPT 単体での回答が可能になっている

現在では ChatGPT に「 Browse with Bing 」機能が搭載されているため、 LLM 単体でも回答が可能となっている。

例えば、今回の「 What's the weather like in San Francisco, Tokyo, and Paris? 」という質問を ChatGPT (ChatGPT Plus 加入版) に投げてみたところ、次の回答が得られた:

> 現在の天気について、以下の都市の情報は次の通りです：
>
> サンフランシスコ（カリフォルニア州、アメリカ）：気温は 57°F（約 14°C）で、部分的に雲があります。今後の予報では最高気温が 66°F（約 19°C）、最低気温が 49°F（約 9°C）となる見込みです。風速は北東から 5mph（約 8km/h）です[\[”\]](https://www.timeanddate.com/weather/usa/san-francisco#:~:text=Weather%20Today%20Weather%20Hourly%2014,hour%20forecast%20for%20next%20week)。
>
> 東京（日本）：気温は 60°F（約 16°C）で、涼しいです。今後の予報では最高気温が 76°F（約 24°C）、最低気温が 48°F（約 9°C）となる見込みです。風速は南から 9mph（約 14km/h）です[\[”\]](https://www.timeanddate.com/weather/japan/tokyo#:~:text=Weather%20Today%20Weather%20Hourly%2014,for%20the%20next%202%20weeks)。
>
> パリ（フランス）：気温は 41°F（約 5°C）で、一部に雲があります。体感温度は 39°F（約 4°C）です。今後の予報では最高気温が 56°F（約 13°C）、最低気温が 40°F（約 4°C）となる見込みです。風速は北西から 3mph（約 5km/h）です[\[”\]](https://www.timeanddate.com/weather/france/paris#:~:text=Weather%20Today%20Weather%20Hourly%2014,hour%20forecast%20for%20next%20week)。
>
> これらの情報は、各都市の現在の気象条件を反映しています。天候は変わりやすいので、最新の情報を得るためには、定期的に天気予報を確認することをお勧めします。
