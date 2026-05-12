# da_go corpus input v9 使用手冊（歷史版）

此檔案保留作為 v9 歷史紀錄。後續維護基準已改為 v12。

目前維護基準：

```text
2026-05-12 json-xlsx-v12-docx-review-workspace-save-fix
```

請優先使用：

```text
docs/dago_corpus_input_v12_使用手冊.md
web/dago-corpus-input.html
web/dago-corpus-review.html
web/assets/dago-corpus-input-v11.js
web/assets/dago-corpus-export-v11-fix.js
web/assets/dago-corpus-docx-v12.js
web/assets/dago-corpus-open-review-v12-fix.js
```

v12 公開輸入頁：

```text
https://dana-will-be-yours.github.io/trpg-corpus-sqlserver/web/dago-corpus-input.html?v=20260512-v12-docx-review-workspace-save-fix
```

v12 審閱工作頁：

```text
https://dana-will-be-yours.github.io/trpg-corpus-sqlserver/web/dago-corpus-review.html?v=20260512-v12-docx-review-workspace-save-fix
```

v9 功能摘要如下，僅供回溯：

```text
1. speaker block 合併解析。
2. 括號動作辨識。
3. clean preview 欄。
4. parseTranscriptBlocks()。
5. splitInlineActionSegments()。
6. buildCleanUtteranceText()。
```

v12 已在後續版本基礎上新增：

```text
1. Word .docx 純文字逐字稿匯入。
2. Word 段落式逐字稿匯入。
3. browser-side DOCX ZIP / XML 解析。
4. DOCX 匯入後 rowSummary / sessionStorage 檢查。
5. 審閱工作頁保存修正，避免開啟空白審閱頁。
6. GM 代 NPC 引號段落解析。
7. 真正 XLSX 四工作表匯出。
8. 獨立 UTF-16LE TSV 匯出。
```

後續修改一律以 v12 手冊與 v12 公開頁為準。此歷史檔不再作為實作依據。
