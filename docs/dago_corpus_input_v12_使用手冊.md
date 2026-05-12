# da_go corpus input v12 使用手冊

版本：

```text
2026-05-12 json-xlsx-v12-docx-review-workspace-save-fix
```

本手冊以 v12 作為後續維護基準。v12 新增 Word `.docx` 純文字逐字稿與段落式逐字稿匯入功能，並修正 DOCX 匯入後開啟審閱工作頁時的工作資料保存流程。v12 不修改 SQL Server 暫存表，不修改正式表，不修改 JSON 欄位結構，不修改 XLSX 工作表結構。

公開輸入頁：

```text
https://dana-will-be-yours.github.io/trpg-corpus-sqlserver/web/dago-corpus-input.html?v=20260512-v12-docx-review-workspace-save-fix
```

審閱工作頁：

```text
https://dana-will-be-yours.github.io/trpg-corpus-sqlserver/web/dago-corpus-review.html?v=20260512-v12-docx-review-workspace-save-fix
```

核心檔案：

```text
web/dago-corpus-input.html
web/dago-corpus-review.html
web/assets/dago-corpus-input-v11.js
web/assets/dago-corpus-export-v11-fix.js
web/assets/dago-corpus-docx-v12.js
web/assets/dago-corpus-open-review-v12-fix.js
docs/dago_corpus_input_v12_使用手冊.md
```

## 一、v12 修改摘要

v12 實作以下功能：

```text
1. HTML 新增「上傳 Word .docx」控制項。
2. JS 新增 importDocxFile()。
3. 使用瀏覽器端 DOCX ZIP / XML 解析流程讀取 word/document.xml。
4. 將 Word 段落轉成純文字 raw transcript。
5. 再沿用 v11 的 parseTranscriptBlocks()。
6. 保留 v11 的 GM 代 NPC 引號段落解析。
7. 匯出仍維持 JSON / 真 XLSX 四工作表 / UTF-16LE TSV。
8. 不修改 SQL Server 表。
9. DOCX 讀取後會延遲檢查 rowSummary / sessionStorage。
10. 若 rows = 0，會提示解析失敗原因。
11. 開啟審閱頁前會先檢查 sessionStorage rows。
12. 若 rows = 0 且 sourceText 有文字，會先重跑解析與前端驗證。
13. 若仍無 rows，不開啟空白審閱頁。
```

## 二、支援範圍

v12 只支援：

```text
.docx
一般文字段落
段落式 TRPG 逐字稿
純文字逐字稿
```

不支援：

```text
.doc 舊二進位 Word 檔
圖片 OCR
文字方塊
頁首頁尾
註解
修訂記錄
複雜表格逐字稿
```

若 Word 內容是表格逐字稿，請先轉成段落式逐字稿，或另行規劃 v13 表格解析。

## 三、建議 Word 格式

建議每段一個發言或一個接續段落：

```text
GM：你們來到南陽郡城門前。
陽月：我先觀察守衛。
楚服：（低聲）這裡好像不太對。
GM：「鄉令聽說了你們的事，吩咐說這些都贈給你們，也不用還了。」士兵把韁繩遞給妳，解釋道：「鄉令先前似乎受過崑崙門人幫助，這就當作是還恩。」
```

若某段沒有 speaker 前綴，v11/v12 會將它接續到上一個 speaker block。

## 四、DOCX 匯入流程

使用者流程：

```text
1. 開啟 web/dago-corpus-input.html。
2. 點選檔案欄位，選擇 .docx。
3. 按「上傳 Word .docx」。
4. 前端讀取 word/document.xml。
5. 將 Word 段落合併成 sourceText。
6. 自動按「解析」。
7. 系統檢查 rowSummary / sessionStorage 是否產生 rows。
8. 到 stg.Utterance_Import 預覽或審閱工作頁校正。
9. 匯出 JSON / XLSX / UTF-16LE TSV。
```

技術流程：

```text
Word .docx
→ browser-side ZIP reader
→ word/document.xml
→ w:p 段落
→ w:t 文字節點
→ raw transcript
→ parseTranscriptBlocks()
→ clean preview
→ speaker mapping
→ sessionStorage
→ review workspace
→ JSON / XLSX / UTF-16LE TSV
```

## 五、審閱工作頁保存修正

`web/assets/dago-corpus-open-review-v12-fix.js` 會在開啟審閱工作頁前執行：

```text
1. 檢查 sessionStorage 是否已有 rows。
2. 若畫面已有 rows，先執行前端驗證以觸發保存。
3. 若 sourceText 有文字但 rows 尚未保存，先重新觸發解析。
4. 再執行前端驗證。
5. 再檢查 sessionStorage。
6. 有 rows 才開啟審閱工作頁。
7. 仍無 rows 時，顯示錯誤並避免開啟空白審閱頁。
```

錯誤提示：

```text
未產生可審閱的 stg.Utterance_Import rows，因此未開啟空白審閱頁。請確認 Word 內容已解析，且 rowSummary 大於 0。
```

## 六、瀏覽器限制

DOCX 是 ZIP 檔。v12 使用瀏覽器的 `DecompressionStream` 解壓縮 `word/document.xml`。

若瀏覽器不支援，會顯示：

```text
此瀏覽器不支援 DecompressionStream，無法直接解析壓縮 DOCX。請改用 Word 全選複製貼上。
```

建議使用最新版 Chrome、Edge 或其他支援 `DecompressionStream` 的瀏覽器。

## 七、大量逐字稿建議

大量 Word 檔匯入後，建議先確認：

```text
rowSummary 大於 0
狀態列顯示已產生 N 列
```

再按：

```text
開啟審閱工作頁
```

審閱頁可使用：

```text
speaker filter
分頁
上插
下插
分割
刪除
前端驗證
分批 JSON
分批 XLSX
分批 TSV
```

大量資料建議分批 JSON 進 SQL Server，不建議一次匯入超大 XLSX。

## 八、GM 代 NPC 發話

v12 保留 v11 的 GM 代 NPC 引號段落解析。

範例：

```text
GM：「鄉令聽說了你們的事，吩咐說這些都贈給你們，也不用還了。」士兵把韁繩遞給妳，解釋道：「鄉令先前似乎受過崑崙門人幫助，這就當作是還恩。」
```

輸出仍為同一列 GM narration，但 `ai_annotation_json` 會記錄：

```json
{
  "parser": "v11-review-workspace-gm-npc-quote",
  "has_gm_npc_quote": true,
  "gm_narration_mode": "gm_npc_quote_mixed",
  "segments": [
    {
      "type": "npc_quoted_dialogue",
      "text": "鄉令聽說了你們的事，吩咐說這些都贈給你們，也不用還了。"
    },
    {
      "type": "gm_narration",
      "text": "士兵把韁繩遞給妳，解釋道：",
      "speech_verb": true
    },
    {
      "type": "npc_quoted_dialogue",
      "text": "鄉令先前似乎受過崑崙門人幫助，這就當作是還恩。"
    }
  ]
}
```

## 九、匯出格式

v12 維持既有匯出：

```text
JSON
XLSX
UTF-16LE TSV
```

XLSX 保持四個工作表：

```text
stg_Import_Batch
stg_Utterance_Import
Code_Mapping
Metadata
```

UTF-16LE TSV 是獨立匯出選項，供 Excel 直接開啟以避免中文亂碼。

## 十、SQL Server 匯入流程

JSON 匯入範例：

```sql
USE TRPG_Corpus_DB;
GO

DECLARE @json NVARCHAR(MAX);

SELECT @json = BulkColumn
FROM OPENROWSET
(
    BULK N'C:\TRPG_Import\dago_utterance_import.json',
    SINGLE_CLOB,
    CODEPAGE = '65001'
) AS src;

EXEC stg.usp_Import_Utterance_From_Json
    @json = @json,
    @source_file_name = N'dago_utterance_import.json',
    @imported_by = N'researcher',
    @run_validation = 1;
GO
```

分批 JSON 匯入時，batch_code 會加上 `_P001`、`_P002` 等 suffix。

正式載入前請先備份資料庫。

## 十一、版本接續原則

後續修改請以 v12 作為基準：

```text
版本：2026-05-12 json-xlsx-v12-docx-review-workspace-save-fix
DOCX 匯入腳本：web/assets/dago-corpus-docx-v12.js
核心解析腳本：web/assets/dago-corpus-input-v11.js
匯出修正腳本：web/assets/dago-corpus-export-v11-fix.js
審閱開啟修正腳本：web/assets/dago-corpus-open-review-v12-fix.js
輸入頁：web/dago-corpus-input.html
審閱頁：web/dago-corpus-review.html
手冊：docs/dago_corpus_input_v12_使用手冊.md
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
