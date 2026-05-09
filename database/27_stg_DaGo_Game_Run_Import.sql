USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF SCHEMA_ID(N'stg') IS NULL
BEGIN
    EXEC(N'CREATE SCHEMA [stg] AUTHORIZATION [dbo];');
END;
GO

IF OBJECT_ID(N'stg.DaGo_Game_Run_Import', N'U') IS NULL
BEGIN
    CREATE TABLE stg.DaGo_Game_Run_Import
    (
        game_run_import_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_stg_DaGo_Game_Run_Import PRIMARY KEY,
        import_batch_id BIGINT NOT NULL,
        export_format NVARCHAR(100) NULL,
        engine_version NVARCHAR(100) NULL,
        project_code NVARCHAR(50) NOT NULL,
        team_code NVARCHAR(50) NOT NULL,
        session_code NVARCHAR(50) NOT NULL,
        import_batch_code NVARCHAR(100) NOT NULL,
        source_json NVARCHAR(MAX) NOT NULL,
        import_status NVARCHAR(50) NOT NULL CONSTRAINT DF_stg_DaGo_Game_Run_Import_import_status DEFAULT N'raw',
        import_note NVARCHAR(MAX) NULL,
        exported_at DATETIME2(0) NULL,
        imported_at DATETIME2(0) NOT NULL CONSTRAINT DF_stg_DaGo_Game_Run_Import_imported_at DEFAULT SYSDATETIME(),
        created_at DATETIME2(0) NOT NULL CONSTRAINT DF_stg_DaGo_Game_Run_Import_created_at DEFAULT SYSDATETIME(),
        updated_at DATETIME2(0) NOT NULL CONSTRAINT DF_stg_DaGo_Game_Run_Import_updated_at DEFAULT SYSDATETIME(),
        CONSTRAINT FK_stg_DaGo_Game_Run_Import_Import_Batch FOREIGN KEY (import_batch_id) REFERENCES stg.Import_Batch(import_batch_id),
        CONSTRAINT UQ_stg_DaGo_Game_Run_Import_Batch UNIQUE (import_batch_id),
        CONSTRAINT CK_stg_DaGo_Game_Run_Import_Source_JSON CHECK (ISJSON(source_json) = 1),
        CONSTRAINT CK_stg_DaGo_Game_Run_Import_Status CHECK (import_status IN (N'raw',N'imported',N'loaded_to_staging',N'error',N'excluded'))
    );
END;
GO

CREATE OR ALTER PROCEDURE stg.usp_Load_DaGo_Game_Run_Json_To_Staging
    @source_json NVARCHAR(MAX),
    @imported_by NVARCHAR(100) = NULL,
    @source_file_name NVARCHAR(260) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @batch_code NVARCHAR(100), @project_code NVARCHAR(50), @team_code NVARCHAR(50), @session_code NVARCHAR(50), @import_batch_id BIGINT, @row_count INT;

    IF ISJSON(@source_json) <> 1
        THROW 53001, N'@source_json 不是有效 JSON。', 1;

    SELECT
        @batch_code = NULLIF(LTRIM(RTRIM(JSON_VALUE(@source_json, N'$.metadata.import_batch_code'))), N''),
        @project_code = NULLIF(LTRIM(RTRIM(JSON_VALUE(@source_json, N'$.metadata.project_code'))), N''),
        @team_code = NULLIF(LTRIM(RTRIM(JSON_VALUE(@source_json, N'$.metadata.team_code'))), N''),
        @session_code = NULLIF(LTRIM(RTRIM(JSON_VALUE(@source_json, N'$.metadata.session_code'))), N'');

    IF @batch_code IS NULL OR @project_code IS NULL OR @team_code IS NULL OR @session_code IS NULL
        THROW 53002, N'JSON metadata.import_batch_code、project_code、team_code、session_code 不可為空。', 1;

    IF EXISTS (SELECT 1 FROM stg.Import_Batch WHERE batch_code = @batch_code)
        THROW 53003, N'batch_code 已存在，請重新匯出或改用新的批次碼。', 1;

    BEGIN TRANSACTION;

    INSERT INTO stg.Import_Batch
    (
        batch_code, project_code, source_table_name, source_file_name, source_file_type, import_purpose, imported_by, import_status
    )
    VALUES
    (
        @batch_code, @project_code, N'stg.Utterance_Import', COALESCE(@source_file_name, CONCAT(N'da_go_', @session_code, N'.json')), N'json', N'da_go runtime JSON 匯入 stg.Utterance_Import', @imported_by, N'importing'
    );

    SET @import_batch_id = CONVERT(BIGINT, SCOPE_IDENTITY());

    INSERT INTO stg.DaGo_Game_Run_Import
    (
        import_batch_id, export_format, engine_version, project_code, team_code, session_code, import_batch_code, source_json, import_status, exported_at, import_note
    )
    VALUES
    (
        @import_batch_id,
        JSON_VALUE(@source_json, N'$.metadata.export_format'),
        JSON_VALUE(@source_json, N'$.metadata.engine_version'),
        @project_code, @team_code, @session_code, @batch_code, @source_json, N'imported',
        TRY_CONVERT(DATETIME2(0), JSON_VALUE(@source_json, N'$.metadata.exported_at'), 127),
        N'完整 game_state 與 raw_game_events 保存在 source_json；utterance 已拆入 stg.Utterance_Import。'
    );

    INSERT INTO stg.Utterance_Import
    (
        import_batch_id, source_row_no, project_code, team_code, session_code, scene_code, turn_no_text, sub_turn_no_text, utterance_code, speaker_type, speaker_code, speaker_label_raw, utterance_function, is_in_character_text, is_gm_narration_text, is_rule_related_text, is_decision_related_text, is_knowledge_related_text, start_timecode, end_timecode, duration_sec_text, utterance_text_raw, utterance_text_clean, utterance_text_verified, language_code, emotion_label, interaction_target_type, interaction_target_code, related_rule_code, related_world_setting_code, related_item_code, ai_summary, ai_annotation_json, human_annotation_note, transcription_confidence_text, review_status, include_in_analysis_text, exclusion_reason
    )
    SELECT
        @import_batch_id,
        COALESCE(TRY_CONVERT(INT, u.source_row_no), TRY_CONVERT(INT, oj.[key]) + 1),
        COALESCE(NULLIF(LTRIM(RTRIM(u.project_code)), N''), @project_code),
        COALESCE(NULLIF(LTRIM(RTRIM(u.team_code)), N''), @team_code),
        COALESCE(NULLIF(LTRIM(RTRIM(u.session_code)), N''), @session_code),
        NULLIF(LTRIM(RTRIM(u.scene_code)), N''), NULLIF(LTRIM(RTRIM(u.turn_no_text)), N''), NULLIF(LTRIM(RTRIM(u.sub_turn_no_text)), N''), NULLIF(LTRIM(RTRIM(u.utterance_code)), N''),
        NULLIF(LTRIM(RTRIM(u.speaker_type)), N''), NULLIF(LTRIM(RTRIM(u.speaker_code)), N''), NULLIF(LTRIM(RTRIM(u.speaker_label_raw)), N''), NULLIF(LTRIM(RTRIM(u.utterance_function)), N''),
        NULLIF(LTRIM(RTRIM(u.is_in_character_text)), N''), NULLIF(LTRIM(RTRIM(u.is_gm_narration_text)), N''), NULLIF(LTRIM(RTRIM(u.is_rule_related_text)), N''), NULLIF(LTRIM(RTRIM(u.is_decision_related_text)), N''), NULLIF(LTRIM(RTRIM(u.is_knowledge_related_text)), N''),
        NULLIF(LTRIM(RTRIM(u.start_timecode)), N''), NULLIF(LTRIM(RTRIM(u.end_timecode)), N''), NULLIF(LTRIM(RTRIM(u.duration_sec_text)), N''),
        NULLIF(LTRIM(RTRIM(u.utterance_text_raw)), N''), NULLIF(LTRIM(RTRIM(u.utterance_text_clean)), N''), NULLIF(LTRIM(RTRIM(u.utterance_text_verified)), N''),
        COALESCE(NULLIF(LTRIM(RTRIM(u.language_code)), N''), N'zh-TW'), NULLIF(LTRIM(RTRIM(u.emotion_label)), N''), NULLIF(LTRIM(RTRIM(u.interaction_target_type)), N''), NULLIF(LTRIM(RTRIM(u.interaction_target_code)), N''),
        NULLIF(LTRIM(RTRIM(u.related_rule_code)), N''), NULLIF(LTRIM(RTRIM(u.related_world_setting_code)), N''), NULLIF(LTRIM(RTRIM(u.related_item_code)), N''),
        NULLIF(LTRIM(RTRIM(u.ai_summary)), N''), NULLIF(LTRIM(RTRIM(u.ai_annotation_json)), N''), NULLIF(LTRIM(RTRIM(u.human_annotation_note)), N''), NULLIF(LTRIM(RTRIM(u.transcription_confidence_text)), N''),
        COALESCE(NULLIF(LTRIM(RTRIM(u.review_status)), N''), N'draft'), COALESCE(NULLIF(LTRIM(RTRIM(u.include_in_analysis_text)), N''), N'1'), NULLIF(LTRIM(RTRIM(u.exclusion_reason)), N'')
    FROM OPENJSON(@source_json, N'$.stg_Utterance_Import') AS oj
    CROSS APPLY OPENJSON(oj.[value]) WITH
    (
        source_row_no NVARCHAR(50) N'$.source_row_no', project_code NVARCHAR(50) N'$.project_code', team_code NVARCHAR(50) N'$.team_code', session_code NVARCHAR(50) N'$.session_code', scene_code NVARCHAR(50) N'$.scene_code', turn_no_text NVARCHAR(50) N'$.turn_no_text', sub_turn_no_text NVARCHAR(50) N'$.sub_turn_no_text', utterance_code NVARCHAR(80) N'$.utterance_code', speaker_type NVARCHAR(50) N'$.speaker_type', speaker_code NVARCHAR(80) N'$.speaker_code', speaker_label_raw NVARCHAR(100) N'$.speaker_label_raw', utterance_function NVARCHAR(50) N'$.utterance_function', is_in_character_text NVARCHAR(20) N'$.is_in_character_text', is_gm_narration_text NVARCHAR(20) N'$.is_gm_narration_text', is_rule_related_text NVARCHAR(20) N'$.is_rule_related_text', is_decision_related_text NVARCHAR(20) N'$.is_decision_related_text', is_knowledge_related_text NVARCHAR(20) N'$.is_knowledge_related_text', start_timecode NVARCHAR(20) N'$.start_timecode', end_timecode NVARCHAR(20) N'$.end_timecode', duration_sec_text NVARCHAR(50) N'$.duration_sec_text', utterance_text_raw NVARCHAR(MAX) N'$.utterance_text_raw', utterance_text_clean NVARCHAR(MAX) N'$.utterance_text_clean', utterance_text_verified NVARCHAR(MAX) N'$.utterance_text_verified', language_code NVARCHAR(20) N'$.language_code', emotion_label NVARCHAR(50) N'$.emotion_label', interaction_target_type NVARCHAR(50) N'$.interaction_target_type', interaction_target_code NVARCHAR(80) N'$.interaction_target_code', related_rule_code NVARCHAR(50) N'$.related_rule_code', related_world_setting_code NVARCHAR(50) N'$.related_world_setting_code', related_item_code NVARCHAR(50) N'$.related_item_code', ai_summary NVARCHAR(MAX) N'$.ai_summary', ai_annotation_json NVARCHAR(MAX) N'$.ai_annotation_json', human_annotation_note NVARCHAR(MAX) N'$.human_annotation_note', transcription_confidence_text NVARCHAR(50) N'$.transcription_confidence_text', review_status NVARCHAR(50) N'$.review_status', include_in_analysis_text NVARCHAR(20) N'$.include_in_analysis_text', exclusion_reason NVARCHAR(MAX) N'$.exclusion_reason'
    ) AS u;

    SET @row_count = @@ROWCOUNT;
    IF @row_count = 0
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 53004, N'JSON stg_Utterance_Import 沒有可匯入資料列。', 1;
    END;

    UPDATE stg.Import_Batch SET total_row_count = @row_count, import_status = N'imported', import_finished_at = SYSDATETIME(), updated_at = SYSDATETIME() WHERE import_batch_id = @import_batch_id;
    UPDATE stg.DaGo_Game_Run_Import SET import_status = N'loaded_to_staging', updated_at = SYSDATETIME() WHERE import_batch_id = @import_batch_id;

    COMMIT TRANSACTION;

    EXEC stg.usp_Validate_Utterance_Import @batch_code = @batch_code;
END;
GO
