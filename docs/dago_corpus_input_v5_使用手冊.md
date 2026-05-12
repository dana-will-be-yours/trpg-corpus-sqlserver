# da_go corpus input v8 使用手冊

版本記錄：

```text
2026-05-12 json-xlsx-v5-mapping
2026-05-12 json-xlsx-v6-edit-stable
2026-05-12 json-xlsx-v7-row-delete-responsive
2026-05-12 json-xlsx-v8-field-notes
```

本手冊以 v8 作為後續維護基準。v8 新增「來源與批次」欄位說明筆記，讓使用者可直接查詢 stg.Utterance_Import、dbo.Utterance 與 function 代碼意思。v8 不修改 `database/*.sql`，不修改 JSON 欄位，不修改 XLSX 工作表結構，不修改 staging 到正式表的 SQL 流程。

公開頁：

```text
https://dana-will-be-yours.github.io/trpg-corpus-sqlserver/web/dago-corpus-input.html?v=20260512-v8-field-notes
```

主分支檔案：

```text
web/dago-corpus-input.html
web/assets/dago-corpus-input-v8.js
web/assets/dago-corpus-input-v7.js
web/assets/dago-corpus-input-v6.js
web/assets/dago-corpus-input-v5.js
database/26_stg_Utterance_Import_Xlsx_Raw.sql
database/27_stg_usp_Import_Utterance_From_Json.sql
database/28_stg_usp_Move_Utterance_Xlsx_Raw_To_Import.sql
```

## 一、工具目標

此工具用於將 TRPG 語音逐字稿、文字逐字稿、論壇貼文或研究者手動整理內容轉成 SQL Server 可匯入格式。

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

## 二、v8 修改內容

v8 修改項目：

```text
1. 在「來源與批次」欄新增可收合欄位說明筆記。
2. 筆記說明 stg.Utterance_Import 與 dbo.Utterance 的基本對應。
3. 筆記說明 project_code、team_code、session_code、batch_code、scene_code、speaker_code、start_timecode 與三層文本。
4. 筆記說明 speaker_type 的正式對應邏輯。
5. 筆記提供 utterance_function 的代碼、中文名稱與用途。
6. JSON/XLSX 欄位結構與 SQL 流程維持既有設計不變。
```

v8 的 `metadata.export_format` 為：

```text
trpg_corpus_web_input_json_xlsx_v8_field_notes
```

## 三、來源與批次欄位筆記

v8 在「來源與批次」加入：

```text
欄位說明筆記：stg.Utterance_Import / dbo.Utterance
```

此筆記使用 HTML 原生 `details` / `summary`，可展開或收合。用途是讓研究者或玩家在同一頁面查詢欄位含義，不必另開手冊。

主要說明：

```text
stg.Utterance_Import 是暫存匯入表。
dbo.Utterance 是正式逐字稿核心表，一列代表一個 turn。
turn_no_text 會轉成 dbo.Utterance.turn_no。
speaker_code 會依 speaker_type 轉成正式外鍵。
utterance_text_raw、utterance_text_clean、utterance_text_verified 會三層保留。
```

## 四、function 代碼對照

| function 代碼 | 中文名稱 | 用途 |
|---|---|---|
| narration | 旁白 | GM 描述場景、環境、事件、NPC 狀態。 |
| dialogue | 對話 | 角色內對話或一般交談。 |
| action | 行動宣告 | 玩家宣告角色要做什麼。 |
| rule_check | 規則檢定 | 擲骰、技能檢定、規則確認、成功失敗判定。 |
| decision | 決策 | 個人或團隊做出明確選擇。 |
| negotiation | 協商 | 玩家討論方案、分配任務、協調敘事方向。 |
| question | 提問 | 詢問規則、世界觀、場景資訊、角色意圖。 |
| clarification | 澄清 | 補充、確認、修正前一段資訊。 |
| conflict | 衝突 | 立場不一致、反對、爭執或敘事衝突。 |
| summary | 摘要 | 回顧事件、整理資訊、階段性總結。 |

## 五、speaker_type 對應

| speaker_type | 中文名稱 | 正式表對應 |
|---|---|---|
| GM | 主持人 | dbo.Team_Member.member_code |
| PL | 角色外玩家 | dbo.Team_Member.member_code |
| PC | 玩家角色 | dbo.Player_Character.character_code |
| NPC | 非玩家角色 | dbo.NPC.npc_code |
| Observer | 觀察者 | dbo.Team_Member.member_code |
| Researcher | 研究者 | dbo.Team_Member.member_code |

前端自動產生的 `PC-陽月`、`TM-GM` 只作為暫時值。匯入正式表前，必須改成 SQL Server 已存在的正式 code。否則 `stg.usp_Validate_Utterance_Import` 會產生 error。

## 六、輸入格式

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

## 七、Speaker Mapping

`Speaker Mapping` 區用來把逐字稿中的原始說話者名稱，對應到 SQL Server 正式表可辨識的 code。

欄位：

```text
操作               刪除此 mapping 單列
raw_speaker_label  原始逐字稿標籤，例如 GM、陽月、楚服
speaker_type       GM、PL、PC、NPC、Observer、Researcher
speaker_code       SQL Server 正式表既有 code
target_table       目標表，例如 dbo.Team_Member、dbo.Player_Character、dbo.NPC
note               備註
```

刪除 Speaker Mapping 後，不會自動刪除逐字稿列。若要讓 mapping 變更套用到逐字稿列，請按「套用 Speaker Mapping」。

## 八、stg.Utterance_Import 預覽

預覽表含 `操作` 欄，可刪除單列。刪除單列時會跳出確認視窗。確認後該列不會匯出 JSON/XLSX。

欄位：

```text
操作
row
speaker_type
speaker_code
speaker_label_raw
function
start_timecode
text
scene_code
frontend_error
frontend_warning
```

若只是要排除分析，建議後續新增 `include_in_analysis_text` 與 `exclusion_reason` 的 UI。現階段按「刪除」表示該 turn 不進匯出檔。

## 九、前端驗證

「前端驗證」按鈕位於 `stg.Utterance_Import 預覽` 標題下方。

輔助欄位：

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

## 十、JSON 匯出格式

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

## 十一、XLSX 匯出格式

XLSX 會輸出四個工作表：

```text
stg_Import_Batch
stg_Utterance_Import
Code_Mapping
Metadata
```

`stg_Utterance_Import` 工作表的主要欄位維持既有設計：

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

## 十二、JSON 匯入 SQL Server 流程

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

## 十三、XLSX 匯入 SQL Server 流程

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

無 error 後載入：

```sql
EXEC stg.usp_Load_Utterance_Import_To_Dbo
    @batch_code = N'DAGO_HTML_UTT_001';
GO
```

## 十四、正式表對應

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

## 十五、版本接續原則

後續修改請以 v8 作為基準：

```text
版本：2026-05-12 json-xlsx-v8-field-notes
主分支：main
公開分支：gh-pages
公開頁：web/dago-corpus-input.html
核心腳本：web/assets/dago-corpus-input-v8.js
保留回溯腳本：web/assets/dago-corpus-input-v7.js
保留回溯腳本：web/assets/dago-corpus-input-v6.js
保留回溯腳本：web/assets/dago-corpus-input-v5.js
```

若後續新增欄位，必須同步修改：

```text
1. HTML 預覽表頭
2. JS 的 utteranceColumns / batchColumns / mappingColumns
3. JSON buildExport() / payload()
4. XLSX sheets
5. stg.Utterance_Import_Xlsx_Raw
6. stg.usp_Import_Utterance_From_Json
7. stg.usp_Move_Utterance_Xlsx_Raw_To_Import
8. stg.usp_Validate_Utterance_Import
9. stg.usp_Load_Utterance_Import_To_Dbo
```
