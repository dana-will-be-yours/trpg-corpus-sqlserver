# da_go corpus input v11 使用手冊（歷史版）

此檔案保留作為 v11 歷史紀錄。後續維護基準已改為 v12。

目前維護基準：

```text
2026-05-12 json-xlsx-v12-docx-import-large-transcript
```

請優先使用：

```text
docs/dago_corpus_input_v12_使用手冊.md
web/assets/dago-corpus-docx-v12.js
web/assets/dago-corpus-input-v11.js
web/assets/dago-corpus-export-v11-fix.js
web/dago-corpus-input.html
web/dago-corpus-review.html
```

v12 公開輸入頁：

```text
https://dana-will-be-yours.github.io/trpg-corpus-sqlserver/web/dago-corpus-input.html?v=20260512-v12-docx-import-large-transcript
```

v12 審閱工作頁：

```text
https://dana-will-be-yours.github.io/trpg-corpus-sqlserver/web/dago-corpus-review.html?v=20260512-v12-docx-import-large-transcript
```

v11 功能摘要如下，僅供回溯：

```text
1. 全螢幕審閱工作頁。
2. sessionStorage 工作資料暫存。
3. GM 代 NPC 引號段落解析。
4. ai_annotation_json.segments。
5. 真正 XLSX 四工作表匯出修正。
6. 獨立 UTF-16LE TSV 匯出。
```

v12 已在 v11 基礎上新增：

```text
1. Word .docx 純文字逐字稿匯入。
2. Word 段落式逐字稿匯入。
3. browser-side DOCX ZIP / XML 解析。
4. 將 word/document.xml 的段落轉成 raw transcript。
5. 自動接續 v11 parseTranscriptBlocks() 與審閱工作頁流程。
```
