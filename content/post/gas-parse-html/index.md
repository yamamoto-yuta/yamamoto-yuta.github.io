---
title: "Gas Parse Html"
description: 
slug: gas-parse-html
date: 2026-04-25T16:13:33Z
lastmod: 2026-04-25T16:13:33Z
image: 
math: 
license: 
hidden: false
comments: true
draft: false
---

<font size="1" align="right">

[✏️ 編集](https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/blob/main/content/post/gas-parse-html/index.md)

</font>

gas-npm-parserが良い感じだった。

```ts
const html = `<body>
<ul id="fruits">
<li class="apple">Apple</li>
<li class="orange">Orange</li>
<li class="pear">Pear</li>
</ul>
</body>`;
const dom = HtmlParser.parse(html);
console.log(dom.querySelector('#fruits .pear').innerHTML);
```

ref: [GASでちゃんとしたHTMLパーサーが使いたかったのでライブラリにした #Node.js - Qiita](https://qiita.com/kairi003/items/06fbf2dc8fb5415c7f60)
