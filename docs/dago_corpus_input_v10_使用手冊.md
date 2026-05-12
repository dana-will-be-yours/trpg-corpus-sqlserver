# da_go corpus input v10 使用手冊

版本：

```text
2026-05-12 json-xlsx-v10-clean-filter-split-largefile
```

本手冊以 v10 作為後續維護基準。v10 只修改前端解析、預覽、操作與匯出輔助，不修改 SQL Server 暫存表，不修改正式表，不修改 JSON 欄位結構，不修改 XLSX 工作表結構。

公開頁：

```text
https://dana-will-be-yours.github.io/trpg-corpus-sqlserver/web/dago-corpus-input.html?v=20260512-v10-clean-filter-split-largefile
```

核心檔案：

```text
web/dago-corpus-input.html
web/assets/dago-corpus-input-v10.js
docs/dago_corpus_input_v10_使用手冊.md
```

## 一、v10 修改摘要

v10 實作以下功能：

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
11. 新增 v10 使用手冊。
12. 全部可見版本基準切換為 v10。
```

## 二、clean preview 規則

v9 會在 clean preview 中輸出：

```text
(對話)這個嘛… (動作)用手指著臉
```

v10 改為純文字：

```text
這個嘛… 用手指著臉
```

功能分類由 `utterance_function` 儲存，不寫入文本本身。

對應欄位仍維持：

```text
raw text       → utterance_text_raw
clean preview  → utterance_text_clean
人工確認文本   → utterance_text_verified
```

## 三、function 判斷

v10 先用 `splitInlineActionSegments()` 將括號內外分段，但不把段落標籤寫進 clean preview。

判斷優先序：

```text
GM speaker → narration
含擲骰、檢定、規則、成功、失敗 → rule_check
含決定、我選、我們要、同意、不同意、採用、投票、委託、任務、交代 → decision
含問句或疑問詞 → question
只有 action segment、沒有 dialogue segment → action
其他 → dialogue
```

此分類是前端初判，仍需研究者審閱。

## 四、未閉合括號 warning

若 raw text 出現：

```text
魏無紛：不用妳說我也會把妳們利用的好好的(拿出地圖,攤開,指著南陽郡
```

v10 會將括號後的同一行文字視為動作段落，但不會把下一行延續為動作。系統會在 `frontend_warning` 加入：

```text
偵測到未閉合括號，請檢查 clean preview
```

## 五、rowSummary

`stg.Utterance_Import 預覽` 標題下方會顯示：

```text
目前總列數
目前顯示列數
目前篩選 speaker_code
error 數
warning 數
```

更新時機：

```text
解析
新增列
上方插入列
下方插入列
分割列
刪除列
前端驗證
speaker filter 變更
分頁變更
```

## 六、speaker_code filter

`顯示發話者` 下拉選單可依 `speaker_code` 篩選顯示列。

注意：

```text
篩選只影響畫面顯示。
rows[] 仍保留所有列。
JSON/XLSX 匯出仍包含全部列。
選 all 時顯示全部列。
```

## 七、插入列與分割列

每列操作欄提供：

```text
上插
下插
分割
刪除
```

上插：在該列上方插入空列。

下插：在該列下方插入空列。

分割：從 raw text textarea 的游標位置切分該列。游標前保留在原列，游標後建立新列。分割後會重新編號：

```text
source_row_no
turn_no_text
utterance_code
```

刪除：刪除該 row，刪除後會重新編號。

## 八、解析後視窗高度適應

v10 新增 `fitPreviewHeight()`。

解析、驗證、換頁、插入、刪除、分割與瀏覽器 resize 時，表格高度會依目前視窗重新計算，降低解析後表格過高導致頁面難操作的問題。

## 九、分頁顯示

預設每頁 100 列。

可選：

```text
50
100
200
全部
```

建議大檔使用 100 或 200，不建議使用全部。全部顯示會一次渲染大量 textarea，可能造成瀏覽器變慢。

## 十、分批匯出

v10 新增：

```text
分批列數
分批 JSON
分批 XLSX
```

預設每批 1000 列。若總列數為 3200，會產生：

```text
dago_utterance_import_part001.json
dago_utterance_import_part002.json
dago_utterance_import_part003.json
dago_utterance_import_part004.json
```

分批匯出時，batch_code 會自動加 suffix：

```text
DAGO_HTML_UTT_001_P001
DAGO_HTML_UTT_001_P002
DAGO_HTML_UTT_001_P003
```

metadata 會保留：

```text
parent_batch_code
part_no
part_count
```

## 十一、SQL Server 匯入建議

小量資料可用單一 JSON 或 XLSX。

大量資料建議使用分批 JSON，逐批在 SSMS 22 執行：

```sql
USE TRPG_Corpus_DB;
GO

DECLARE @json NVARCHAR(MAX);

SELECT @json = BulkColumn
FROM OPENROWSET
(
    BULK N'C:\TRPG_Import\dago_utterance_import_part001.json',
    SINGLE_CLOB,
    CODEPAGE = '65001'
) AS src;

EXEC stg.usp_Import_Utterance_From_Json
    @json = @json,
    @source_file_name = N'dago_utterance_import_part001.json',
    @imported_by = N'researcher',
    @run_validation = 1;
GO
```

再逐批檢查：

```sql
SELECT
    ib.batch_code,
    ui.source_row_no,
    ui.import_status,
    ui.speaker_type,
    ui.speaker_code,
    ui.utterance_function,
    ui.utterance_text_raw,
    ui.validation_error,
    ui.validation_warning
FROM stg.Utterance_Import AS ui
INNER JOIN stg.Import_Batch AS ib
    ON ib.import_batch_id = ui.import_batch_id
WHERE ib.batch_code = N'DAGO_HTML_UTT_001_P001'
ORDER BY ui.source_row_no;
```

若無 error，再載入正式表：

```sql
EXEC stg.usp_Load_Utterance_Import_To_Dbo
    @batch_code = N'DAGO_HTML_UTT_001_P001';
GO
```

正式載入前請先備份資料庫。

## 十二、版本接續原則

後續修改請以 v10 作為基準：

```text
版本：2026-05-12 json-xlsx-v10-clean-filter-split-largefile
核心腳本：web/assets/dago-corpus-input-v10.js
公開頁：web/dago-corpus-input.html
手冊：docs/dago_corpus_input_v10_使用手冊.md
```

若未來新增欄位，必須同步檢查：

```text
1. HTML 表頭
2. JS 的 U / B / M 欄位陣列
3. JSON payload()
4. XLSX sheets
5. stg.Utterance_Import_Xlsx_Raw
6. stg.usp_Import_Utterance_From_Json
7. stg.usp_Move_Utterance_Xlsx_Raw_To_Import
8. stg.usp_Validate_Utterance_Import
9. stg.usp_Load_Utterance_Import_To_Dbo
```
