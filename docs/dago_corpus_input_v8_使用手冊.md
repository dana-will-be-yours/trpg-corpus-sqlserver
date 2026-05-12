# da_go corpus input v8 使用手冊（歷史版）

此檔案保留作為 v8 歷史紀錄。後續維護基準已改為 v12。

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

v8 功能摘要如下，僅供回溯：

```text
1. 在「來源與批次」欄新增可收合欄位說明筆記。
2. 筆記說明 stg.Utterance_Import 與 dbo.Utterance 的基本對應。
3. 筆記說明 project_code、team_code、session_code、batch_code、scene_code、speaker_code、start_timecode 與三層文本。
4. 筆記說明 speaker_type 的正式對應邏輯。
5. 筆記提供 utterance_function 的代碼、中文名稱與用途。
6. JSON/XLSX 欄位結構與 SQL 流程維持既有設計不變。
```

v12 已在後續版本基礎上新增：

```text
1. speaker block 合併解析。
2. clean preview。
3. 插入、刪除、分割列。
4. 全螢幕審閱工作頁。
5. sessionStorage 工作資料暫存與 save-fix。
6. GM 代 NPC 引號段落解析。
7. ai_annotation_json.segments。
8. 真正 XLSX 四工作表匯出修正。
9. 獨立 UTF-16LE TSV 匯出。
10. Word .docx 純文字逐字稿匯入。
11. Word 段落式逐字稿匯入。
12. browser-side DOCX ZIP / XML 解析。
```

後續修改一律以 v12 手冊與 v12 公開頁為準。此歷史檔不再作為實作依據。
