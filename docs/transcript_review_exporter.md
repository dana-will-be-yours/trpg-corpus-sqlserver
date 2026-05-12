# TRPG 逐字稿審閱與匯出器

本工具位於：

```text
web/transcript-review.html
```

公開頁位置：

```text
https://dana-will-be-yours.github.io/trpg-corpus-sqlserver/web/transcript-review.html
```

## 定位

此頁是 GitHub Pages 靜態前端工具，用於整理 TRPG 語音逐字稿與文字逐字稿。它只在瀏覽器端處理資料，不直接連線 SQL Server，不保存帳密，不寫入資料庫。

資料流程：

```text
錄音或文字逐字稿
→ 外部語音轉文字或人工貼上
→ transcript-review.html 切分 turn
→ 研究者審閱 raw / clean / verified
→ 匯出 JSON 或 CSV UTF-8
→ SSMS 22 匯入 stg.Import_Batch 與 stg.Utterance_Import
→ 執行 stg 驗證程序
→ 載入 dbo.Utterance
```

## 支援來源

- TXT：每列一個發言。
- CSV：欄位對齊 `stg.Utterance_Import` 匯出欄位。
- JSON：包含 `import_batch` 與 `utterances`。

TXT 建議格式：

```text
[00:01:03] GM：你們來到荒廢的祠堂。
[00:01:12] 陽月：我想檢查門上的符咒。
[00:01:20] 楚服：我在旁邊戒備。
```

## 匯出欄位

匯出的 JSON/CSV 嚴格對齊 `stg.Utterance_Import` 可接收欄位，不包含 `import_batch_id`，因為該欄位在 SSMS 匯入批次時由 `stg.Import_Batch` 產生。

主要欄位：

```text
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
```

## 前端檢查

前端會檢查下列條件，降低 SSMS 匯入後被 SQL Server CHECK constraint 或 UNIQUE constraint 擋下的機率：

```text
project_code、team_code、session_code 不可空白
turn_no_text 必須為正整數
同一 session_code 下 turn_no_text 不可重複
同一 session_code 下 utterance_code 不可重複
speaker_type 必須是 GM、PL、PC、NPC、Observer、Researcher
utterance_function 必須是 narration、dialogue、action、rule_check、decision、negotiation、question、clarification、conflict、summary
PC、NPC 必須 is_in_character_text = 1
GM、PL、Observer、Researcher 必須 is_in_character_text = 0
is_gm_narration_text = 1 時，speaker_type 必須是 GM 且 utterance_function 必須是 narration
include_in_analysis_text = 0 時必須填 exclusion_reason
transcription_confidence_text 若有值，必須介於 0 到 1
utterance_text_raw 不可空白
```

## SSMS 22 JSON 匯入範例

以下範例只新增資料，不包含 DROP、DELETE、TRUNCATE。

```sql
USE TRPG_Corpus_DB;
GO

DECLARE @json NVARCHAR(MAX);

SELECT @json = BulkColumn
FROM OPENROWSET(
    BULK N'C:\TRPG_Import\BATCH_TRPG_UTTERANCE_001.json',
    SINGLE_CLOB,
    CODEPAGE = '65001'
) AS src;

DECLARE @import_batch_id BIGINT;

INSERT INTO stg.Import_Batch
(
    batch_code,
    project_code,
    source_table_name,
    source_file_name,
    source_file_type,
    import_purpose,
    imported_by,
    import_status,
    total_row_count
)
SELECT
    JSON_VALUE(@json, '$.import_batch.batch_code'),
    JSON_VALUE(@json, '$.import_batch.project_code'),
    JSON_VALUE(@json, '$.import_batch.source_table_name'),
    JSON_VALUE(@json, '$.import_batch.source_file_name'),
    N'json',
    JSON_VALUE(@json, '$.import_batch.import_purpose'),
    JSON_VALUE(@json, '$.import_batch.imported_by'),
    N'imported',
    (
        SELECT COUNT(*)
        FROM OPENJSON(@json, '$.utterances')
    );

SET @import_batch_id = SCOPE_IDENTITY();

INSERT INTO stg.Utterance_Import
(
    import_batch_id,
    source_row_no,
    project_code,
    team_code,
    session_code,
    scene_code,
    turn_no_text,
    sub_turn_no_text,
    utterance_code,
    speaker_type,
    speaker_code,
    speaker_label_raw,
    utterance_function,
    is_in_character_text,
    is_gm_narration_text,
    is_rule_related_text,
    is_decision_related_text,
    is_knowledge_related_text,
    start_timecode,
    end_timecode,
    duration_sec_text,
    utterance_text_raw,
    utterance_text_clean,
    utterance_text_verified,
    language_code,
    emotion_label,
    interaction_target_type,
    interaction_target_code,
    related_rule_code,
    related_world_setting_code,
    related_item_code,
    ai_summary,
    ai_annotation_json,
    human_annotation_note,
    transcription_confidence_text,
    review_status,
    include_in_analysis_text,
    exclusion_reason,
    import_status
)
SELECT
    @import_batch_id,
    source_row_no,
    project_code,
    team_code,
    session_code,
    scene_code,
    turn_no_text,
    sub_turn_no_text,
    utterance_code,
    speaker_type,
    speaker_code,
    speaker_label_raw,
    utterance_function,
    is_in_character_text,
    is_gm_narration_text,
    is_rule_related_text,
    is_decision_related_text,
    is_knowledge_related_text,
    start_timecode,
    end_timecode,
    duration_sec_text,
    utterance_text_raw,
    utterance_text_clean,
    utterance_text_verified,
    ISNULL(language_code, N'zh-TW'),
    emotion_label,
    interaction_target_type,
    interaction_target_code,
    related_rule_code,
    related_world_setting_code,
    related_item_code,
    ai_summary,
    ai_annotation_json,
    human_annotation_note,
    transcription_confidence_text,
    review_status,
    include_in_analysis_text,
    exclusion_reason,
    N'raw'
FROM OPENJSON(@json, '$.utterances')
WITH
(
    source_row_no INT '$.source_row_no',
    project_code NVARCHAR(50) '$.project_code',
    team_code NVARCHAR(50) '$.team_code',
    session_code NVARCHAR(50) '$.session_code',
    scene_code NVARCHAR(50) '$.scene_code',
    turn_no_text NVARCHAR(50) '$.turn_no_text',
    sub_turn_no_text NVARCHAR(50) '$.sub_turn_no_text',
    utterance_code NVARCHAR(80) '$.utterance_code',
    speaker_type NVARCHAR(50) '$.speaker_type',
    speaker_code NVARCHAR(80) '$.speaker_code',
    speaker_label_raw NVARCHAR(100) '$.speaker_label_raw',
    utterance_function NVARCHAR(50) '$.utterance_function',
    is_in_character_text NVARCHAR(20) '$.is_in_character_text',
    is_gm_narration_text NVARCHAR(20) '$.is_gm_narration_text',
    is_rule_related_text NVARCHAR(20) '$.is_rule_related_text',
    is_decision_related_text NVARCHAR(20) '$.is_decision_related_text',
    is_knowledge_related_text NVARCHAR(20) '$.is_knowledge_related_text',
    start_timecode NVARCHAR(20) '$.start_timecode',
    end_timecode NVARCHAR(20) '$.end_timecode',
    duration_sec_text NVARCHAR(50) '$.duration_sec_text',
    utterance_text_raw NVARCHAR(MAX) '$.utterance_text_raw',
    utterance_text_clean NVARCHAR(MAX) '$.utterance_text_clean',
    utterance_text_verified NVARCHAR(MAX) '$.utterance_text_verified',
    language_code NVARCHAR(20) '$.language_code',
    emotion_label NVARCHAR(50) '$.emotion_label',
    interaction_target_type NVARCHAR(50) '$.interaction_target_type',
    interaction_target_code NVARCHAR(80) '$.interaction_target_code',
    related_rule_code NVARCHAR(50) '$.related_rule_code',
    related_world_setting_code NVARCHAR(50) '$.related_world_setting_code',
    related_item_code NVARCHAR(50) '$.related_item_code',
    ai_summary NVARCHAR(MAX) '$.ai_summary',
    ai_annotation_json NVARCHAR(MAX) '$.ai_annotation_json',
    human_annotation_note NVARCHAR(MAX) '$.human_annotation_note',
    transcription_confidence_text NVARCHAR(50) '$.transcription_confidence_text',
    review_status NVARCHAR(50) '$.review_status',
    include_in_analysis_text NVARCHAR(20) '$.include_in_analysis_text',
    exclusion_reason NVARCHAR(MAX) '$.exclusion_reason'
);
GO
```

## 匯入後檢查

```sql
USE TRPG_Corpus_DB;
GO

SELECT
    utterance_import_id,
    source_row_no,
    session_code,
    turn_no_text,
    speaker_type,
    speaker_code,
    utterance_function,
    is_in_character_text,
    utterance_text_raw,
    import_status,
    validation_error,
    validation_warning
FROM stg.Utterance_Import
ORDER BY import_batch_id DESC, source_row_no ASC;
GO
```

完成 staging 匯入後，仍需執行倉庫既有的 `stg.usp_Validate_Utterance_Import` 與 `stg.usp_Load_Utterance_Import_To_Dbo`。正式載入前請先備份資料庫。
