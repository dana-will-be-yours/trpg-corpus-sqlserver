# da_go corpus input v13 工作手冊

版本：

```text
2026-05-12 json-xlsx-v13-indexeddb-large-workspace
```

本手冊是 v13 分支與 v13 preview 的工作基準。v13 的目標是將大型逐字稿工作區從 `sessionStorage rows` 改為 IndexedDB 本機工作區，並支援 Large Mode 分批解析、分批寫入與分批 cursor 匯出。

## 一、版本號檢查規則

每次編輯前必須先檢查一次版本號是否相同。

必查位置：

```text
1. web/dago-corpus-input.html 大標題
2. web/dago-corpus-review.html 大標題
3. web/v13-preview/dago-corpus-input.html 大標題
4. web/v13-preview/dago-corpus-review.html 大標題
5. 所有 active script 的 query string
6. 本手冊版本號
```

若版本號不一致，必須先更新成相同版本號，再開始功能修改。

目前統一版本號：

```text
2026-05-12 json-xlsx-v13-indexeddb-large-workspace
```

## 二、v13 active files

v13 分支 active files：

```text
web/dago-corpus-input.html
web/dago-corpus-review.html
web/assets/dago-corpus-workspace-v13.js
web/assets/dago-corpus-workspace-ops-v13.js
web/assets/dago-corpus-parser-v13.js
web/assets/dago-corpus-docx-v13.js
web/assets/dago-corpus-open-review-v13.js
web/assets/dago-corpus-input-ops-v13.js
web/assets/dago-corpus-review-v13.js
web/assets/dago-corpus-export-v13.js
web/assets/dago-corpus-xlsx-parts-v13.js
web/assets/dago-corpus-large-import-v13.js
web/assets/dago-corpus-stress-test-v13.js
web/assets/dago-corpus-mapping-validation-v13.js
web/assets/dago-corpus-help-v13.js
```

v13 preview active files：

```text
web/v13-preview/dago-corpus-input.html
web/v13-preview/dago-corpus-review.html
web/v13-preview/assets/dago-corpus-workspace-v13.js
web/v13-preview/assets/dago-corpus-workspace-ops-v13.js
web/v13-preview/assets/dago-corpus-parser-v13.js
web/v13-preview/assets/dago-corpus-docx-v13.js
web/v13-preview/assets/dago-corpus-open-review-v13.js
web/v13-preview/assets/dago-corpus-input-ops-v13.js
web/v13-preview/assets/dago-corpus-review-v13.js
web/v13-preview/assets/dago-corpus-export-v13.js
web/v13-preview/assets/dago-corpus-xlsx-parts-v13.js
web/v13-preview/assets/dago-corpus-large-import-v13.js
web/v13-preview/assets/dago-corpus-stress-test-v13.js
web/v13-preview/assets/dago-corpus-mapping-validation-v13.js
web/v13-preview/assets/dago-corpus-help-v13.js
```

## 三、目前資料流

```text
Word .docx / raw transcript
→ sourceText
→ parser
→ Large Mode 判斷
→ appendRowsChunk()
→ IndexedDB workspaces / rows / maps
→ input preview / review page
→ 點選前端驗證時執行 Speaker Mapping cursor validation
→ JSON / UTF-16LE TSV / XLSX cursor chunk export
→ SSMS 22 匯入 stg.Utterance_Import / stg.Import_Batch
→ T-SQL 查核
→ dbo.Utterance
```

## 四、目前已支援功能

```text
1. Word .docx 匯入。
2. sourceText 解析。
3. rows 寫入 IndexedDB。
4. maps 寫入 IndexedDB。
5. Speaker Mapping 顯示與編輯。
6. stg.Utterance_Import 預覽顯示。
7. 輸入頁上一頁 / 下一頁。
8. 審閱頁上一頁 / 下一頁。
9. speaker filter。
10. 單列上插。
11. 單列下插。
12. 單列刪除。
13. 單列分割。
14. 單列欄位修改後寫回 IndexedDB。
15. 清除本機工作區。
16. JSON 全量匯出。
17. JSON cursor 分批匯出。
18. UTF-16LE TSV 全量匯出。
19. UTF-16LE TSV cursor 分批匯出。
20. XLSX 四工作表全量匯出。
21. XLSX 四工作表 cursor 分批匯出。
22. 點選前端驗證時執行 cursor 全量驗證。
23. 壓力測試資料產生器。
24. 未閉合括號 action/dialogue segment 解析。
25. Speaker Mapping 與 stg.Utterance_Import 欄位中英對照面板。
26. IndexedDB cursor 計數。
27. IndexedDB cursor 分頁。
28. IndexedDB cursor iterator。
29. 單列文字修改使用 parser cleanText / annotation，不再回退到舊清洗邏輯。
30. Large Mode：超過 5000 rows 自動分批解析與寫入。
31. 壓力測試資料分批寫入，避免測試器本身造成卡頓。
32. Speaker Mapping 驗證只在點選「前端驗證」時執行，結果寫回 frontend_validation_error / frontend_validation_warning。
33. 「套用 Speaker Mapping」會以 cursor 逐列更新 speaker_type / speaker_code，不全量重寫 rows。
34. Speaker Mapping 驗證與套用已改為同一個 readwrite cursor transaction 內 cursor.update()，避免 cursor 迭代中 await 另一個 IndexedDB transaction 導致停住。
```

## 五、Large Mode 行為

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
7. Word .docx 匯入會自動使用同一個 parser API，因此大型 DOCX 也會走 Large Mode。
```

## 六、Speaker Mapping 前端驗證

`dago-corpus-mapping-validation-v13.js` 會接管「前端驗證」與「套用 Speaker Mapping」。

驗證執行時機：

```text
只有點選「前端驗證」時才執行 cursor 全量查詢。
一般換頁、輸入、匯出、開啟審閱頁不會自動掃描全 workspace rows。
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
```

「套用 Speaker Mapping」行為：

```text
1. 先保存目前 Speaker Mapping 表格。
2. 使用 readwrite cursor 掃描 rows。
3. 依 speaker_label_raw 找 mapping。
4. 使用 cursor.update() 逐列更新 speaker_type / speaker_code。
5. 不使用 getAllRows() 全量重寫。
6. 不在 cursor transaction 中 await 另一個 updateRow transaction。
7. 完成後提示 scanned / updated / missing_mapping。
```

## 七、50000 rows 壓力測試流程

輸入頁提供壓力測試資料產生器。壓力測試產生器已改為 chunked write，不再一次建立完整 rows 後寫入。

測試級距：

```text
10000 rows
30000 rows
50000 rows
```

測試流程：

```text
1. 強制重新整理 v13 preview input 頁。
2. 按「清除本機工作區」。
3. 在「壓力測試列數」輸入 10000。
4. 按「產生壓力測試資料」。
5. 等待 status 顯示完成。
6. 測試上一頁 / 下一頁。
7. 測試 speaker filter。
8. 按「前端驗證」。
9. 確認 status 從「讀取 rows」推進到每 500 rows 進度，最後顯示「前端驗證完成」。
10. 確認 frontend_validation_error / frontend_validation_warning 顯示於預覽表。
11. 設定分批列數為 1000。
12. 下載分批 JSON。
13. 下載分批 UTF-16LE TSV。
14. 下載分批 XLSX。
15. 重複 30000 rows。
16. 30000 成功後再測 50000 rows。
```

驗收標準：

```text
1. 產生資料期間 status 持續更新，不長時間停住。
2. 10000 / 30000 / 50000 rows 完成後 rowSummary 與 IndexedDB rows 數一致。
3. 第一頁可顯示。
4. 下一頁可顯示。
5. speaker filter 可切換。
6. 前端驗證只在點選時執行。
7. 前端驗證結果寫回每列 frontend_validation_error / frontend_validation_warning。
8. 分批 JSON / TSV / XLSX 可下載。
9. TSV 用 Excel 開啟中文不亂碼。
10. 分批 XLSX 每批有四工作表：stg_Import_Batch、stg_Utterance_Import、Code_Mapping、Metadata。
```

## 八、匯出建議

小型資料：

```text
1000 rows 以下：JSON / TSV / XLSX 皆可。
```

中型資料：

```text
1000–5000 rows：JSON / TSV 優先，XLSX 可用。
```

大型資料：

```text
5000 rows 以上：使用分批 JSON / 分批 TSV / 分批 XLSX。
```

超大型資料：

```text
30000–50000 rows：優先使用分批 JSON 或分批 UTF-16LE TSV；XLSX 僅作人工審閱輔助。
```

## 九、仍保留的限制

```text
1. 新增、刪除、分割仍會重排 rows，50,000 rows 下不建議頻繁操作。
2. 若要完全大型化，後續應導入 stable row_id 與 row_order gap 策略。
3. 全量 XLSX 不建議用於 50,000 rows。
4. 瀏覽器 IndexedDB 可用空間依瀏覽器與裝置政策而不同。
```

## 十、SSMS 22 連接與匯入可行度

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

若後續要一鍵送入 SQL Server，建議另建本機 Node.js / .NET 匯入器，且只寫入 `stg` schema，不直接寫入 `dbo.Utterance`。

## 十一、SSMS 22 匯入前檢查

匯入 SQL Server 前，必須確認：

```text
1. JSON / XLSX / TSV 的 row_count 與 IndexedDB row_count 一致。
2. source_row_no 連續。
3. turn_no_text 連續。
4. utterance_code 不重複。
5. speaker_type 僅使用 GM、PL、PC、NPC、Observer、Researcher。
6. utterance_function 僅使用 narration、dialogue、action、rule_check、decision、negotiation、question、clarification、conflict、summary。
7. 中文以 Excel 開啟沒有亂碼。
```

## 十二、不得修改項目

```text
database/*.sql
JSON 欄位
XLSX 四工作表
UTF-16LE TSV 欄位
stg.Utterance_Import
dbo.Utterance
```

正式資料仍應由匯出 JSON / XLSX / TSV 後，用 SSMS 22 匯入 SQL Server。v13 IndexedDB 僅是瀏覽器本機工作區。
