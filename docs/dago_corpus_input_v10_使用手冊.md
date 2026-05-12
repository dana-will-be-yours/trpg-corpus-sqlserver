# da_go corpus input v10 使用手冊（歷史版）

此檔案保留作為 v10 歷史紀錄。後續維護基準已改為 v12。

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

v12 已在後續版本基礎上新增：

```text
1. 全螢幕審閱工作頁。
2. sessionStorage 工作資料暫存與 save-fix。
3. GM 代 NPC 引號段落解析。
4. ai_annotation_json.segments。
5. 真正 XLSX 四工作表匯出修正。
6. 獨立 UTF-16LE TSV 匯出。
7. Word .docx 純文字逐字稿匯入。
8. Word 段落式逐字稿匯入。
9. browser-side DOCX ZIP / XML 解析。
10. DOCX 匯入後 rowSummary / sessionStorage 檢查。
11. 審閱工作頁保存修正，避免開啟空白審閱頁。
```

後續修改一律以 v12 手冊與 v12 公開頁為準。此歷史檔不再作為實作依據。
