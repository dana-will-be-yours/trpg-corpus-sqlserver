# da_go corpus input v13 工作手冊

版本：

```text
2026-05-12 json-xlsx-v13-indexeddb-large-workspace
```

本手冊是 v13 分支與 v13 preview 的工作基準。v13 的目標是將大型逐字稿工作區從 `sessionStorage rows` 改為 IndexedDB 本機工作區。

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
web/assets/dago-corpus-stress-test-v13.js
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
web/v13-preview/assets/dago-corpus-stress-test-v13.js
web/v13-preview/assets/dago-corpus-help-v13.js
```

## 三、目前資料流

```text
Word .docx
→ dago-corpus-docx-v13.js
→ sourceText
→ dago-corpus-parser-v13.js
→ rows / maps
→ dago-corpus-workspace-v13.js
→ IndexedDB workspaces / rows / maps
→ input preview / review page
→ validation / JSON / TSV / XLSX export
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
17. JSON 分批匯出。
18. UTF-16LE TSV 全量匯出。
19. UTF-16LE TSV 分批匯出。
20. XLSX 四工作表全量匯出。
21. XLSX 四工作表分批匯出。
22. 全量前端驗證。
23. 壓力測試資料產生器。
24. 未閉合括號 action/dialogue segment 解析。
25. Speaker Mapping 與 stg.Utterance_Import 欄位中英對照面板。
```

## 五、action/dialogue segment 解析

`dago-corpus-parser-v13.js` 使用 `splitActionDialogueSegmentsV13()` 判斷括號動作與對白。

若原文是：

```text
(看著李遠汗流浹背的樣子，知道他已經很辛苦了，有點生氣地道
災厄，不許你胡說。
```

預期寫入 `ai_annotation_json`：

```json
{
  "segments": [
    { "type": "action", "text": "看著李遠汗流浹背的樣子，知道他已經很辛苦了，有點生氣地道" },
    { "type": "dialogue", "text": "災厄，不許你胡說。" }
  ],
  "has_unclosed_action": true,
  "split_by_speech_cue": true
}
```

`utterance_text_clean` 仍保留純文字，不加入「動作」或「對白」標籤。細部分段以 `ai_annotation_json.segments` 為準。

## 六、欄位中英對照面板

`dago-corpus-help-v13.js` 會在前端加入「欄位中英對照」按鈕。

顯示區域：

```text
1. Speaker Mapping
2. stg.Utterance_Import 預覽
3. stg.Utterance_Import 審閱工作頁
```

用途：

```text
1. 顯示欄位英文名稱。
2. 顯示中文名稱。
3. 顯示用途。
4. 顯示 utterance_function 的英文代碼、中文名稱與用途。
```

此面板不寫入 IndexedDB，不修改 JSON / XLSX / TSV 匯出欄位，也不修改 SQL Server 表。

## 七、分批 XLSX 使用方式

分批 XLSX 由 `dago-corpus-xlsx-parts-v13.js` 接管 `downloadXlsxParts` 按鈕。

```text
1. 先匯入 Word 或產生壓力測試資料。
2. 設定「分批列數」。建議 1000 或 2000。
3. 按「分批 XLSX」。
4. 每一批會產生一個 .xlsx。
5. 每個 .xlsx 都包含四工作表：
   stg_Import_Batch
   stg_Utterance_Import
   Code_Mapping
   Metadata
```

分批 XLSX 採全域連續編號：

```text
source_row_no：依全工作區連續。
turn_no_text：依全工作區連續。
utterance_code：依全工作區連續。
```

若 partSize 大於 5000，前端會自動改為 5000。大型資料建議使用 1000 或 2000。

## 八、壓力測試流程

輸入頁提供壓力測試資料產生器。

建議測試級距：

```text
100 rows
1000 rows
5000 rows
10000 rows
```

測試流程：

```text
1. 在「壓力測試列數」輸入 100。
2. 按「產生壓力測試資料」。
3. 按「前端驗證」。
4. 按「下載 JSON」。
5. 按「下載 UTF-16LE TSV」。
6. 按「下載 XLSX」。
7. 按「分批 XLSX」。
8. 重複測試 1000、5000。
9. 5000 正常後，再測 10000。
```

驗收標準：

```text
1. IndexedDB rows 數量正確。
2. Speaker Mapping 顯示 GM、PC1、PC2、PC3、PC4、PC5。
3. 前端驗證可完成。
4. JSON 可下載並含完整 rows。
5. UTF-16LE TSV 以 Excel 開啟中文不亂碼。
6. XLSX 可由 Excel 開啟。
7. 分批 XLSX 每批均含四工作表。
8. Metadata 可看到 part_no、part_count、row_start、row_end、total_row_count。
```

## 九、檢查各表連線

在瀏覽器 Console 檢查：

```javascript
const id = DagoCorpusWorkspaceV13.getCurrentWorkspaceId();
const rows = await DagoCorpusWorkspaceV13.getAllRows(id);
const maps = await DagoCorpusWorkspaceV13.getAllMaps(id);
console.log(id, rows.length, maps.length);
console.log(document.querySelectorAll('#rows tr').length);
console.log(document.querySelectorAll('#mappingRows tr').length);
```

判斷：

```text
rows > 0 且 #rows tr > 0：stg.Utterance_Import 預覽已接上。
maps > 0 且 #mappingRows tr > 0：Speaker Mapping 已接上。
rows > 100 且下一頁可顯示資料：分頁已接上 IndexedDB。
審閱頁與輸入頁使用同一 workspace_id：跨頁讀取已接上。
```

## 十、SSMS 22 匯入前檢查

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

## 十一、不得修改項目

```text
database/*.sql
JSON 欄位
XLSX 四工作表
UTF-16LE TSV 欄位
stg.Utterance_Import
dbo.Utterance
```

正式資料仍應由匯出 JSON / XLSX / TSV 後，用 SSMS 22 匯入 SQL Server。v13 IndexedDB 僅是瀏覽器本機工作區。
