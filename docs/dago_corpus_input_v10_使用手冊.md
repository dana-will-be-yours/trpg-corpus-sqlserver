# da_go corpus input v10 使用手冊（歷史版）

此檔案保留作為 v10 歷史紀錄。後續維護基準已改為 v11。

目前維護基準：

```text
2026-05-12 json-xlsx-v11-review-workspace-gm-npc-quote
```

請優先使用：

```text
docs/dago_corpus_input_v11_使用手冊.md
web/assets/dago-corpus-input-v11.js
web/assets/dago-corpus-export-v11-fix.js
web/dago-corpus-input.html
web/dago-corpus-review.html
```

v11 公開頁：

```text
https://dana-will-be-yours.github.io/trpg-corpus-sqlserver/web/dago-corpus-input.html?v=20260512-v11-review-workspace-gm-npc-quote
```

v11 審閱工作頁：

```text
https://dana-will-be-yours.github.io/trpg-corpus-sqlserver/web/dago-corpus-review.html?v=20260512-v11-review-workspace-gm-npc-quote
```

v10 功能摘要如下，僅供回溯：

```text
1. clean preview 移除「(對話)」「(動作)」等功能標籤。
2. function 改由 segments 與關鍵字判斷。
3. 新增未閉合括號 warning。
4. 新增 rowSummary。
5. 新增 speaker_code filter。
6. 新增插入列：上方 / 下方。
7. 新增從游標分割列。
8. 新增解析後視窗高度適應。
9. 新增每頁顯示筆數，預設 100。
10. 新增分批匯出 JSON/XLSX。
```

v11 已在 v10 基礎上新增：

```text
1. 全螢幕審閱工作頁。
2. sessionStorage 工作資料暫存。
3. GM 代 NPC 引號段落解析。
4. ai_annotation_json.segments。
5. 真正 XLSX 四工作表匯出修正。
6. 獨立 UTF-16LE TSV 匯出。
```
