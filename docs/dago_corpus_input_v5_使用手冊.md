# da_go corpus input v5 使用手冊

版本記錄：2026-05-12 `json-xlsx-v5-mapping`

本手冊記錄 `web/dago-corpus-input.html` v5 的使用方式、匯出格式、SQL Server 匯入流程與資料庫對應。此版已同步寫入 `main`，公開頁由 `gh-pages` 提供。

公開頁：

```text
https://dana-will-be-yours.github.io/trpg-corpus-sqlserver/web/dago-corpus-input.html?v=20260512-v5-mapping
```

主分支檔案：

```text
web/dago-corpus-input.html
web/assets/dago-corpus-input-v5.js
database/26_stg_Utterance_Import_Xlsx_Raw.sql
database/27_stg_usp_Import_Utterance_From_Json.sql
database/28_stg_usp_Move_Utterance_Xlsx_Raw_To_Import.sql
```

## 一、此版目標

此版用於將 TRPG 語音逐字稿、文字逐字稿、論壇貼文或研究者手動整理內容轉成 SQL Server 可匯入格式。

資料流：

```text
HTML 貼上逐字稿
→ 解析 turn
→ Speaker Mapping 校正
→ 前端驗證
→ 匯出 JSON 或 XLSX
→ stg.Import_Batch
→ stg.Utterance_Import
→ stg.usp_Validate_Utterance_Import
→ stg.usp_Load_Utterance_Import_To_Dbo
→ dbo.Utterance
```

此頁不直接連線 SQL Server，不保存資料庫帳密，不在 GitHub Pages 中寫入資料庫。

## 二、輸入格式

建議每列一個發言。支援時間碼：

```text
[00:01:03] GM：你們來到荒廢的祠堂。
[00:01:12] 陽月：我想檢查門上的符咒。
[00:01:20] 楚服：我在旁邊戒備。
```

也支援無時間碼：

```text
GM：你們來到荒廢的祠堂。
陽月：我想檢查門上的符咒。
楚服：我在旁邊戒備。
```

解析後會產生：

```text
source_row_no
turn_no_text
speaker_label_raw
speaker_type
speaker_code
utterance_function
start_timecode
utterance_text_raw
utterance_text_clean
utterance_text_verified
frontend_validation_error
frontend_validation_warning
```

## 三、Speaker Mapping

`Speaker Mapping` 區用來把逐字稿中的原始說話者名稱，對應到 SQL Server 正式表可辨識的 code。

欄位：

```text
raw_speaker_label  原始逐字稿標籤，例如 GM、陽月、楚服
speaker_type       GM、PL、PC、NPC、Observer、Researcher
speaker_code       SQL Server 正式表既有 code
target_table       目標表，例如 dbo.Team_Member、dbo.Player_Character、dbo.NPC
note               備註
```

正式對應規則：

```text
GM / PL / Observer / Researcher → dbo.Team_Member.member_code
PC                              → dbo.Player_Character.character_code
NPC                             → dbo.NPC.npc_code
```

前端自動產生的 `PC-陽月`、`TM-GM` 只作為暫時值。匯入正式表前，必須改成 SQL Server 已存在的正式 code。否則 `stg.usp_Validate_Utterance_Import` 會產生 error。

## 四、前端驗證

v5 會產生兩個輔助欄位：

```text
frontend_validation_error
frontend_validation_warning
```

常見 error：

```text
project_code 不可空白
team_code 不可空白
session_code 不可空白
turn_no_text 必須為正整數
utterance_text_raw 不可空白
speaker_type 不合法
utterance_function 不合法
speaker_code 必填，且需對應資料庫正式 code
同一 session_code 下 turn_no_text 重複
同一 session_code 下 utterance_code 重複
```

常見 warning：

```text
scene_code 空白，匯入 dbo.Utterance 時 scene_id 將為 NULL
start_timecode 空白，無法回溯語音時間
```

前端驗證只是早期提示。正式判斷仍以 SQL Server 的 `stg.usp_Validate_Utterance_Import` 為準。

## 五、JSON 匯出格式

JSON 會輸出：

```text
metadata
stg_Import_Batch
stg_Utterance_Import
Code_Mapping
frontend_validation_summary
```

用途：

```text
metadata                   版本、來源、匯出時間
stg_Import_Batch            對應 stg.Import_Batch
stg_Utterance_Import        對應 stg.Utterance_Import
Code_Mapping                供研究者檢查 speaker_code 對應
frontend_validation_summary 前端錯誤與警告統計
```

## 六、XLSX 匯出格式

XLSX 會輸出四個工作表：

```text
stg_Import_Batch
stg_Utterance_Import
Code_Mapping
Metadata
```

`stg_Utterance_Import` 工作表的主要欄位：

```text
import_batch_code
import_batch_id
source_row_no
project_code
team_code
session_code
scene_code
turn_no_text
sub_turn_no_text
utterance_code
speaker_type
speaker_code
speaker_label_raw
utterance_function
is_in_character_text
is_gm_narration_text
is_rule_related_text
is_decision_related_text
is_knowledge_related_text
start_timecode
end_timecode
duration_sec_text
utterance_text_raw
utterance_text_clean
utterance_text_verified
language_code
emotion_label
interaction_target_type
interaction_target_code
related_rule_code
related_world_setting_code
related_item_code
ai_summary
ai_annotation_json
human_annotation_note
transcription_confidence_text
review_status
include_in_analysis_text
exclusion_reason
import_status
frontend_validation_error
frontend_validation_warning
```

## 七、JSON 匯入 SQL Server 流程

先將 JSON 放到本機路徑，例如：

```text
C:\TRPG_Import\dago_utterance_import.json
```

在 SSMS 22 執行：

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

查看驗證結果：

```sql
SELECT
    ib.batch_code,
    ui.source_row_no,
    ui.import_status,
    ui.project_code,
    ui.team_code,
    ui.session_code,
    ui.scene_code,
    ui.turn_no_text,
    ui.speaker_type,
    ui.speaker_code,
    ui.utterance_function,
    ui.utterance_text_raw,
    ui.validation_error,
    ui.validation_warning
FROM stg.Utterance_Import AS ui
INNER JOIN stg.Import_Batch AS ib
    ON ib.import_batch_id = ui.import_batch_id
WHERE ib.batch_code = N'DAGO_HTML_UTT_001'
ORDER BY ui.source_row_no;
```

若沒有 error，載入正式表：

```sql
EXEC stg.usp_Load_Utterance_Import_To_Dbo
    @batch_code = N'DAGO_HTML_UTT_001';
GO
```

正式載入前請先備份資料庫。

## 八、XLSX 匯入 SQL Server 流程

XLSX 無法直接寫入 `stg.Utterance_Import`，因為 `import_batch_id` 必須由 `stg.Import_Batch` 產生。因此採用 raw table 流程。

先執行建表：

```sql
:r .\database\26_stg_Utterance_Import_Xlsx_Raw.sql
```

用 SSMS 匯入精靈將 XLSX 的 `stg_Utterance_Import` 工作表匯入：

```text
目標表：stg.Utterance_Import_Xlsx_Raw
```

匯入後執行：

```sql
EXEC stg.usp_Move_Utterance_Xlsx_Raw_To_Import
    @batch_code = N'DAGO_HTML_UTT_001',
    @source_file_name = N'dago_utterance_import.xlsx',
    @imported_by = N'researcher',
    @run_validation = 1;
GO
```

查看驗證結果：

```sql
SELECT
    ib.batch_code,
    ui.source_row_no,
    ui.import_status,
    ui.speaker_type,
    ui.speaker_code,
    ui.utterance_text_raw,
    ui.validation_error,
    ui.validation_warning
FROM stg.Utterance_Import AS ui
INNER JOIN stg.Import_Batch AS ib
    ON ib.import_batch_id = ui.import_batch_id
WHERE ib.batch_code = N'DAGO_HTML_UTT_001'
ORDER BY ui.source_row_no;
```

無 error 後載入：

```sql
EXEC stg.usp_Load_Utterance_Import_To_Dbo
    @batch_code = N'DAGO_HTML_UTT_001';
GO
```

## 九、正式表對應

`stg.Utterance_Import` 進入 `dbo.Utterance` 時會轉換：

```text
session_code                → dbo.TRPG_Session.session_id
scene_code                  → dbo.Scene.scene_id
speaker_code + speaker_type → speaker_member_id / speaker_character_id / speaker_npc_id
interaction_target_code     → interaction_target_member_id / interaction_target_character_id / interaction_target_npc_id
related_rule_code           → dbo.Game_Rule.rule_id
related_world_setting_code  → dbo.World_Setting.world_setting_id
related_item_code           → dbo.Item.item_id
turn_no_text                → turn_no
sub_turn_no_text            → sub_turn_no
duration_sec_text           → duration_sec
transcription_confidence_text → transcription_confidence
include_in_analysis_text    → include_in_analysis
```

逐字稿三層文本會完整保留：

```text
utterance_text_raw
utterance_text_clean
utterance_text_verified
```

## 十、常見錯誤

### 1. speaker_code 找不到

原因：前端自動 code 與資料庫正式 code 不一致。

處理：在 Speaker Mapping 中把 `speaker_code` 改成正式 code。

### 2. session_code 找不到

原因：`dbo.TRPG_Session` 尚未建立對應場次，或 team_code 不正確。

處理：先建立 `Research_Project`、`Team`、`TRPG_Session`。

### 3. scene_code 找不到

原因：輸入了資料庫中不存在的 scene_code。

處理：先建立 `dbo.Scene`，或讓 scene_code 空白，使 `scene_id` 為 NULL。

### 4. 同一 session turn_no 重複

原因：同一場次中 `turn_no_text` 重複，或正式表已存在同 turn_no。

處理：修正 turn_no，或改用新 batch 與新 session。

### 5. include_in_analysis_text = 0 但 exclusion_reason 空白

原因：正式表要求排除分析時必須填排除理由。

處理：填寫 `exclusion_reason`。

## 十一、版本接續原則

後續修改請以此版作為基準：

```text
版本：2026-05-12 json-xlsx-v5-mapping
主分支：main
公開分支：gh-pages
公開頁：web/dago-corpus-input.html
核心腳本：web/assets/dago-corpus-input-v5.js
```

若後續新增欄位，必須同步修改：

```text
1. HTML 預覽表頭
2. JS 的 utteranceColumns / batchColumns / mappingColumns
3. JSON buildExport()
4. XLSX sheets
5. stg.Utterance_Import_Xlsx_Raw
6. stg.usp_Import_Utterance_From_Json
7. stg.usp_Move_Utterance_Xlsx_Raw_To_Import
8. stg.usp_Validate_Utterance_Import
9. stg.usp_Load_Utterance_Import_To_Dbo
```
