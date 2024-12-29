---
title: "ExcelファイルをGASで操作する場合はスプレッドシートへの変換が必要（2024/12/29時点）"
description: 
slug: convert-xlsx-to-spreadsheet-with-gas
date: 2024-12-29T02:38:10Z
lastmod: 2024-12-29T02:38:10Z
image: 
math: 
license: 
hidden: false
comments: true
draft: false
---

<font size="1" align="right">

[✏️ 編集](https://github.com/yamamoto-yuta/yamamoto-yuta.github.io/blob/main/content/post/convert-xlsx-to-spreadsheet-with-gas/index.md)

</font>

タイトルの通り。ExcelファイルをGASでそのまま操作しようとすると次のエラーが出る。

検証用スクリプト:

```javascript
const main = () => {
  const spreadsheetId = "YOUR_SPREADSHEET_ID";
  const spreadsheetFromSpreadsheet = SpreadsheetApp.openById(spreadsheetId);
  console.log(spreadsheetFromSpreadsheet.getName()); // スプレッドシートのファイル名が出力される

  const xlsxId = "YOUR_XLSX_ID";
  const spreadsheetFromXlsx = SpreadsheetApp.openById(xlsxId);
  console.log(spreadsheetFromXlsx.getName());   // Exception: Service Spreadsheets failed while accessing document with id 1RgRpia4esAR9xXsoxs5xDZRlySzvGpsW.
};
```

そのため、Excelファイルをスプレッドシートに変換する必要がある。調べると色々な方法が見つかるがどれも微妙にうまくいかなかったので、現時点でうまくいった方法を記載する（この方法もそのうち使えなくなるかもしれないが…）。

1. 「サービス」からDrive APIを有効にする（バージョンは現時点での最新版であるv3を使用する）
2. 次のスクリプトを実行する

```javascript
const main = () => {
  const parentFolderId = "YOUR_PARENT_FOLDER_ID";

    const xlsxId = "YOUR_XLSX_ID";
  const xlsxFile = DriveApp.getFileById(xlsxId);

  const options = {
    name: xlsxFile.getName(),
    mimeType: MimeType.GOOGLE_SHEETS,
    parents: [parentFolderId]
  };
  const spreadsheetFromXlsx = Drive.Files.create(
    options, 
    xlsxFile.getBlob(), 
    {supportsAllDrives: true} // 共有ドライブ内のファイルを操作する場合に必要 ref: https://developers.google.com/drive/api/guides/enable-shareddrives?hl=ja
  );

  console.log(spreadsheetFromXlsx.getName()); // ファイル名が表示される
};
```