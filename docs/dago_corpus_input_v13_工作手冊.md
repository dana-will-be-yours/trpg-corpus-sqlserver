# da_go corpus input v13 工作手冊

版本：

```text
2026-05-17 mapping-io-validation-selftest
```

本手冊是 `v13` 分支的工作基準。v13 的目標是將大型逐字稿工作區從舊版 `sessionStorage rows` 改為 IndexedDB 本機工作區，並支援 Large Mode 分批解析、分批寫入、Speaker Mapping 匯入匯出、前端驗證與 cursor 分批匯出。

## 一、版本號檢查規則

每次編輯前必須先檢查版本號是否相同。

必查位置：

```text
1. web/dago-corpus-input.html 大標題
2. web/dago-corpus-review.html 大標題
3. 所有 active script 的 query string
4. web/assets/dago-corpus-v13-core.js 的 VERSION
5. 本手冊版本號
6. tools/check_v13_static_refs.ps1 的 ExpectedVersion / ExpectedQuery
```

目前統一版本號：

```text
2026-05-17 mapping-io-validation-selftest
```

目前統一 query string：

```text
20260517-mapping-io-validation-selftest
```

## 二、v13 active files

目前 v13 分支 active files 只有以下檔案。`web/v13-preview/` 不存在，不能列為 active path。

```text
web/dago-corpus-input.html
web/dago-corpus-review.html
web/assets/dago-corpus-v13-core.js
web/assets/dago-corpus-workspace-v13.js
web/assets/dago-corpus-workspace-ops-v13.js
web/assets/dago-corpus-parser-v13.js
web/assets/dago-corpus-docx-v13.js
web/assets/dago-corpus-open-review-v13.js
web/assets/dago-corpus-input-ops-v13.js
web/assets/dago-corpus-review-v13.js
web/assets/dago-corpus-xlsx-core-v13.js
web/assets/dago-corpus-mapping-io-v13.js
web/assets/dago-corpus-export-v13.js
web/assets/dago-corpus-xlsx-parts-v13.js
web/assets/dago-corpus-large-import-v13.js
web/assets/dago-corpus-stress-test-v13.js
web/assets/dago-corpus-mapping-validation-v13.js
web/assets/dago-corpus-help-v13.js
web/assets/dago-corpus-v13-selftest.js
```

## 三、歷史檔案隔離規則

舊版文件與舊版前端 JS 不得放在 active path 混用。若需保留追溯性，放入：

```text
docs/archive/
web/assets/archive/
```

active HTML 不得引用 archive 檔案。v13 主流程不得引用 v5–v12 JS。

## 四、目前資料流

```text
Word .docx / raw transcript
→ sourceText
→ parser
→ Large Mode 判斷
→ appendRowsChunk()
→ IndexedDB workspaces / rows / maps
→ Speaker Mapping 顯示、編輯、JSON/TSV/XLSX 匯出、JSON/TSV 匯入
→ input preview / review page
→ 點選前端驗證時執行 Speaker Mapping cursor validation
→ JSON / UTF-16LE TSV / XLSX cursor chunk export
→ SSMS 22 匯入 stg.Utterance_Import / stg.Import_Batch
→ T-SQL 查核
→ dbo.Utterance
```

## 五、目前已支援功能

```text
1. Word .docx 匯入。
2. sourceText 解析。
3. rows 寫入 IndexedDB。
4. maps 寫入 IndexedDB。
5. Speaker Mapping 顯示與編輯。
6. Speaker Mapping JSON 匯出與匯入。
7. Speaker Mapping UTF-16LE TSV 匯出與匯入。
8. Speaker Mapping XLSX 匯出，工作表為 Speaker_Mapping / Metadata。
9. stg.Utterance_Import 預覽顯示。
10. 輸入頁上一頁 / 下一頁。
11. 審閱頁上一頁 / 下一頁。
12. speaker filter。
13. 單列上插。
14. 單列下插。
15. 單列刪除。
16. 單列分割。
17. 單列欄位修改後寫回 IndexedDB。
18. 清除本機工作區。
19. JSON 全量匯出。
20. JSON cursor 分批匯出。
21. UTF-16LE TSV 全量匯出。
22. UTF-16LE TSV cursor 分批匯出。
23. XLSX 四工作表全量匯出。
24. XLSX 四工作表 cursor 分批匯出。
25. 點選前端驗證時執行 cursor 全量驗證。
26. 壓力測試資料產生器。
27. 未閉合括號 action/dialogue segment 解析。
28. Speaker Mapping 與 stg.Utterance_Import 欄位中英對照面板。
29. IndexedDB cursor 計數。
30. IndexedDB cursor 分頁。
31. IndexedDB cursor iterator。
32. Large Mode：超過 5000 rows 自動分批解析與寫入。
33. Speaker Mapping 驗證結果寫回 frontend_validation_error / frontend_validation_warning。
34. Speaker Mapping mismatch 會將 row 寫回 Observer / OBS_MISMATCH。
35. 套用 Speaker Mapping 會以 cursor 逐列更新 speaker_type / speaker_code。
36. v13 core 已集中管理欄位常數與純函式。
37. parser 與 Large Mode 已共用 speaker 判斷與 row builder。
38. 分批 JSON / TSV / XLSX 已統一走 cursor chunk。
39. selftest 只在 ?selftest=1 啟用。
40. selftest 若原本沒有 workspace，會保留 selftest workspace 供檢查。
```

## 六、Large Mode 行為

Large Mode 由 `dago-corpus-large-import-v13.js` 提供。

啟動條件：

```text
預估 rows > 5000
```

固定參數：

```text
LARGE_THRESHOLD = 5000
PARSE_CHUNK_SIZE = 500
WRITE_CHUNK_SIZE = 500
```

行為：

```text
1. 不一次建立完整 rows 陣列。
2. 每 500 rows 寫入 IndexedDB 一次。
3. 每批寫入後釋放該批 rows。
4. status 顯示目前寫入進度。
5. 匯入完成後只刷新第一頁預覽。
6. Speaker Mapping 以 Map 累積，完成後一次寫入 maps store。
```

## 七、Speaker Mapping 匯入 / 匯出

`dago-corpus-mapping-io-v13.js` 提供 Speaker Mapping 專用匯入與匯出。

固定欄位：

```text
raw_speaker_label
speaker_type
speaker_code
target_table
note
```

支援匯出：

```text
1. Mapping JSON
2. Mapping UTF-16LE TSV
3. Mapping XLSX
```

支援匯入：

```text
1. Mapping JSON
2. Mapping UTF-16LE TSV / .tsv / .txt / .csv
```

XLSX 匯入第一版尚未支援。若使用 Excel 編輯 Mapping，請另存為 UTF-16LE TSV 後匯入。

Mapping JSON 格式：

```json
{
  "metadata": {
    "version": "2026-05-17 mapping-io-validation-selftest",
    "export_type": "Speaker_Mapping",
    "workspace_id": "...",
    "exported_at": "..."
  },
  "Speaker_Mapping": [
    {
      "raw_speaker_label": "陽月",
      "speaker_type": "PC",
      "speaker_code": "PC_YANGYUE",
      "target_table": "Player_Character",
      "note": ""
    }
  ]
}
```

Mapping TSV 欄位：

```text
raw_speaker_label	speaker_type	speaker_code	target_table	note
```

Mapping XLSX 工作表：

```text
Speaker_Mapping
Metadata
```

## 八、Speaker Mapping 前端驗證

`dago-corpus-mapping-validation-v13.js` 會接管「前端驗證」與「套用 Speaker Mapping」。

驗證執行時機：

```text
只有點選「前端驗證」時才執行 cursor 全量查詢。
一般換頁、輸入、匯出、開啟審閱頁不會自動掃描全 workspace rows。
```

完整驗證規則：

```text
A. 找不到 mapping：
   不改 row，只寫 warning。

B. 找到 mapping，row.speaker_code 空白：
   speaker_code = mapping.speaker_code
   speaker_type = mapping.speaker_type
   is_in_character_text 依 speaker_type 更新
   寫入 warning。

C. 找到 mapping，row.speaker_code 與 mapping.speaker_code 一致：
   若 speaker_type 空白或不一致，依 mapping.speaker_type 修正。
   is_in_character_text 依 speaker_type 更新。
   寫入 warning。

D. 找到 mapping，row.speaker_code 與 mapping.speaker_code 不一致：
   speaker_type = Observer
   speaker_code = OBS_MISMATCH
   is_in_character_text = 0
   寫入 warning。
```

驗證內容：

```text
1. 每列 speaker_label_raw 是否能找到 mapping。
2. speaker_code 是否與 mapping.speaker_code 一致。
3. speaker_type 是否與 mapping.speaker_type 一致。
4. target_table 是否符合 speaker_type：
   GM / PL / Observer / Researcher → Team_Member
   PC → Player_Character
   NPC → NPC
5. project_code / team_code / session_code 必填。
6. speaker_type 合法值。
7. utterance_function 合法值。
8. utterance_text_raw 不可空。
9. ai_annotation_json 必須是合法 JSON。
```

驗證結果：

```text
1. 錯誤寫回 frontend_validation_error。
2. 警告寫回 frontend_validation_warning。
3. 寫回採用同一個 readwrite cursor transaction 的 cursor.update()。
4. 寫回完成後 refresh 當前頁，預覽表直接顯示錯誤與警告。
5. status 顯示 filled、type_fixed、observer_mismatch 計數。
```

## 九、selftest

selftest 僅在網址包含下列參數時執行：

```text
?selftest=1
```

測試內容：

```text
1. core / workspace / parser / export / mapping-io / mapping-validation API 是否存在。
2. parser 產生 3 rows。
3. Mapping JSON roundtrip。
4. Mapping TSV roundtrip。
5. replaceWorkspaceMaps() 寫回 maps store。
6. 故意將陽月 row 的 speaker_code 改為 WRONG_CODE。
7. 執行前端驗證。
8. 確認該 row 被改為 Observer / OBS_MISMATCH。
9. 確認 frontend_validation_warning 含 OBS_MISMATCH。
```

工作區處理：

```text
若原本有 workspace，selftest 完成後恢復原 workspace。
若原本沒有 workspace，selftest 完成後保留 selftest workspace 供檢查。
```

## 十、50000 rows 壓力測試流程

```text
1. 開啟 web/dago-corpus-input.html。
2. 按「清除本機工作區」。
3. 在「壓力測試列數」輸入 10000。
4. 按「產生壓力測試資料」。
5. 等待 status 顯示完成。
6. 測試上一頁 / 下一頁。
7. 測試 speaker filter。
8. 按「前端驗證」。
9. 確認 frontend_validation_error / frontend_validation_warning 顯示於預覽表。
10. 設定分批列數為 1000。
11. 下載分批 JSON。
12. 下載分批 UTF-16LE TSV。
13. 下載分批 XLSX。
14. 重複 30000 rows。
15. 30000 成功後再測 50000 rows。
```

## 十一、匯出建議

```text
1000 rows 以下：JSON / TSV / XLSX 皆可。
1000–5000 rows：JSON / TSV 優先，XLSX 可用。
5000 rows 以上：使用分批 JSON / 分批 TSV / 分批 XLSX。
30000–50000 rows：優先使用分批 JSON 或分批 UTF-16LE TSV；XLSX 僅作人工審閱輔助。
```

## 十二、SSMS 22 連接與匯入可行度

GitHub Pages 靜態 HTML 不應直接連 SQL Server。正式流程仍建議：

```text
HTML v13
→ 分批 JSON / 分批 UTF-16LE TSV
→ SSMS 22 匯入 stg.Utterance_Import / stg.Import_Batch
→ T-SQL 查核
→ dbo.Utterance
```

50,000 rows 對 SQL Server 本身不是問題，重點在前端匯出與匯入分批。建議每批：

```text
JSON：1000–5000 rows / file
TSV：1000–5000 rows / file
XLSX：1000 rows / file
```

## 十三、SSMS 22 匯入前檢查

```text
1. JSON / XLSX / TSV 的 row_count 與 IndexedDB row_count 一致。
2. source_row_no 連續。
3. turn_no_text 連續。
4. utterance_code 不重複。
5. speaker_type 僅使用 GM、PL、PC、NPC、Observer、Researcher。
6. utterance_function 僅使用 narration、dialogue、action、rule_check、decision、negotiation、question、clarification、conflict、summary。
7. 中文以 Excel 開啟沒有亂碼。
8. 若出現 OBS_MISMATCH，需人工回查該 row 的 speaker_label_raw 與 Speaker Mapping。
```

## 十四、不得修改項目

```text
database/*.sql
JSON 欄位
XLSX 四工作表
UTF-16LE TSV 欄位
stg.Utterance_Import
dbo.Utterance
```

正式資料仍應由匯出 JSON / XLSX / TSV 後，用 SSMS 22 匯入 SQL Server。v13 IndexedDB 僅是瀏覽器本機工作區。
