# da_go corpus input v11 使用手冊

版本：

```text
2026-05-12 json-xlsx-v11-review-workspace-gm-npc-quote
```

本手冊以 v11 作為後續維護基準。v11 修改前端解析、審閱工作頁、GM 代 NPC 引號段落註記與匯出輔助，不修改 SQL Server 暫存表，不修改正式表，不修改 JSON 欄位結構，不修改 XLSX 工作表結構。

公開頁：

```text
https://dana-will-be-yours.github.io/trpg-corpus-sqlserver/web/dago-corpus-input.html?v=20260512-v11-review-workspace-gm-npc-quote
```

審閱工作頁：

```text
https://dana-will-be-yours.github.io/trpg-corpus-sqlserver/web/dago-corpus-review.html?v=20260512-v11-review-workspace-gm-npc-quote
```

核心檔案：

```text
web/dago-corpus-input.html
web/dago-corpus-review.html
web/assets/dago-corpus-input-v11.js
web/assets/dago-corpus-export-v11-fix.js
docs/dago_corpus_input_v11_使用手冊.md
```

## 一、v11 修改摘要

v11 實作以下功能：

```text
1. 新增 web/dago-corpus-review.html 作為全螢幕審閱工作頁。
2. input.html 新增「開啟審閱工作頁」按鈕。
3. v11 JS 使用 sessionStorage 暫存 rows / mappings / metadata。
4. review.html 使用整頁高度顯示 stg.Utterance_Import 預覽。
5. 保留 rowSummary、speakerFilter、分頁、插入列、分割列、刪除列、分批匯出。
6. 新增 splitQuotedNarrationSegments()。
7. 新增 inferGmNarrationMode()。
8. 偵測中文引號「……」內文字為 GM 代 NPC 發話。
9. 引號外文字視為 GM 敘事或動作描述。
10. 將 segment 結構寫入 ai_annotation_json。
11. frontend_warning 提示「偵測到 GM 代 NPC 發話」。
12. 下載 XLSX 維持真正 XLSX 四工作表。
13. 另提供 UTF-16LE TSV 下載，不冒用 XLSX。
```

## 二、審閱工作頁

輸入頁解析後可按：

```text
開啟審閱工作頁
```

資料會先寫入瀏覽器 `sessionStorage`，再開啟：

```text
web/dago-corpus-review.html
```

審閱頁提供更大的工作畫面，適合逐列修正、speaker filter、分頁、插入列、分割列與匯出。

注意：

```text
sessionStorage 只存在於同一瀏覽器來源。
重新整理通常仍可保留資料。
關閉瀏覽器或資料量過大時可能遺失。
重要資料請及早下載 JSON 或 XLSX。
```

## 三、GM 代 NPC 引號段落解析

v11 會檢查 GM 敘事中的中文引號：

```text
「……」
```

引號內視為：

```text
npc_quoted_dialogue
```

引號外視為：

```text
gm_narration
```

範例 raw：

```text
GM：「鄉令聽說了你們的事，吩咐說這些都贈給你們，也不用還了。」士兵把韁繩遞給妳，解釋道：「鄉令先前似乎受過崑崙門人幫助，這就當作是還恩。」
```

v11 會在同一列保留：

```text
speaker_type = GM
utterance_function = narration
is_gm_narration_text = 1
```

並把句內結構寫入 `ai_annotation_json`：

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
  ],
  "utterance_function_detail": [
    "npc_quoted_dialogue",
    "gm_narration",
    "npc_quoted_dialogue"
  ]
}
```

前端 warning 會顯示：

```text
偵測到 GM 代 NPC 發話：2 段；GM 敘事：1 段，已寫入 ai_annotation_json.segments
```

## 四、為何不自動拆成 NPC 列

v11 採用「同列 segment annotation」原則。

理由：

```text
1. GM 代 NPC 發話仍是 GM 的主持輸出。
2. 自動拆列會改變 turn_no 與原始回合邏輯。
3. NPC code 未必已存在於 dbo.NPC。
4. ai_annotation_json 可保存句內結構，不破壞 dbo.Utterance。
```

若研究者要把某段引號另列為 NPC，可在審閱頁手動分割列並自行設定 speaker_type / speaker_code。

## 五、匯出格式

v11 維持既有 JSON 欄位與 XLSX 工作表結構。

JSON 包含：

```text
metadata
stg_Import_Batch
stg_Utterance_Import
Code_Mapping
frontend_validation_summary
```

XLSX 包含四個工作表：

```text
stg_Import_Batch
stg_Utterance_Import
Code_Mapping
Metadata
```

`下載 XLSX` 會輸出真正 `.xlsx` 檔案。

`下載 UTF-16LE TSV` 會輸出 `.tsv` 檔案，供 Excel 直接開啟以避免中文亂碼。TSV 不取代 XLSX。

分批匯出：

```text
分批 JSON
分批 XLSX
分批 TSV
```

分批時 batch_code 會加上：

```text
_P001
_P002
_P003
```

## 六、SQL Server 匯入建議

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

正式載入前請先備份資料庫。

## 七、版本接續原則

後續修改請以 v11 作為基準：

```text
版本：2026-05-12 json-xlsx-v11-review-workspace-gm-npc-quote
核心腳本：web/assets/dago-corpus-input-v11.js
匯出修正腳本：web/assets/dago-corpus-export-v11-fix.js
輸入頁：web/dago-corpus-input.html
審閱頁：web/dago-corpus-review.html
手冊：docs/dago_corpus_input_v11_使用手冊.md
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
