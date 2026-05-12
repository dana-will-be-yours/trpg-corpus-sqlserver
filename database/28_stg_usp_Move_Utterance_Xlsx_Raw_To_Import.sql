USE TRPG_Corpus_DB;
GO

CREATE OR ALTER PROCEDURE stg.usp_Move_Utterance_Xlsx_Raw_To_Import
    @batch_code NVARCHAR(100),
    @source_file_name NVARCHAR(260) = NULL,
    @imported_by NVARCHAR(100) = NULL,
    @run_validation BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @import_batch_id BIGINT;
    DECLARE @row_count INT;
    DECLARE @project_code NVARCHAR(50);

    IF @batch_code IS NULL OR LTRIM(RTRIM(@batch_code)) = N''
    BEGIN
        THROW 54001, N'@batch_code 不可空白。', 1;
    END;

    SELECT
        @row_count = COUNT(*),
        @project_code = MIN(NULLIF(LTRIM(RTRIM(project_code)), N''))
    FROM stg.Utterance_Import_Xlsx_Raw
    WHERE import_batch_code = @batch_code;

    IF ISNULL(@row_count, 0) = 0
    BEGIN
        THROW 54002, N'找不到指定 batch_code 的 XLSX raw 資料。', 1;
    END;

    IF @project_code IS NULL
    BEGIN
        THROW 54003, N'XLSX raw 資料缺少 project_code。', 1;
    END;

    IF EXISTS (SELECT 1 FROM stg.Import_Batch WHERE batch_code = @batch_code)
    BEGIN
        THROW 54004, N'batch_code 已存在於 stg.Import_Batch。', 1;
    END;

    BEGIN TRANSACTION;

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
    VALUES
    (
        @batch_code,
        @project_code,
        N'stg.Utterance_Import',
        COALESCE(@source_file_name, N'dago_utterance_import.xlsx'),
        N'xlsx',
        N'web transcript input from xlsx raw',
        COALESCE(@imported_by, N'SSMS Import Wizard'),
        N'imported',
        @row_count
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
        TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(source_row_no)), N'')),
        LTRIM(RTRIM(project_code)),
        LTRIM(RTRIM(team_code)),
        LTRIM(RTRIM(session_code)),
        NULLIF(LTRIM(RTRIM(scene_code)), N''),
        LTRIM(RTRIM(turn_no_text)),
        NULLIF(LTRIM(RTRIM(sub_turn_no_text)), N''),
        NULLIF(LTRIM(RTRIM(utterance_code)), N''),
        LTRIM(RTRIM(speaker_type)),
        NULLIF(LTRIM(RTRIM(speaker_code)), N''),
        NULLIF(LTRIM(RTRIM(speaker_label_raw)), N''),
        LTRIM(RTRIM(utterance_function)),
        LTRIM(RTRIM(is_in_character_text)),
        NULLIF(LTRIM(RTRIM(is_gm_narration_text)), N''),
        NULLIF(LTRIM(RTRIM(is_rule_related_text)), N''),
        NULLIF(LTRIM(RTRIM(is_decision_related_text)), N''),
        NULLIF(LTRIM(RTRIM(is_knowledge_related_text)), N''),
        NULLIF(LTRIM(RTRIM(start_timecode)), N''),
        NULLIF(LTRIM(RTRIM(end_timecode)), N''),
        NULLIF(LTRIM(RTRIM(duration_sec_text)), N''),
        utterance_text_raw,
        utterance_text_clean,
        utterance_text_verified,
        COALESCE(NULLIF(LTRIM(RTRIM(language_code)), N''), N'zh-TW'),
        NULLIF(LTRIM(RTRIM(emotion_label)), N''),
        NULLIF(LTRIM(RTRIM(interaction_target_type)), N''),
        NULLIF(LTRIM(RTRIM(interaction_target_code)), N''),
        NULLIF(LTRIM(RTRIM(related_rule_code)), N''),
        NULLIF(LTRIM(RTRIM(related_world_setting_code)), N''),
        NULLIF(LTRIM(RTRIM(related_item_code)), N''),
        ai_summary,
        ai_annotation_json,
        human_annotation_note,
        NULLIF(LTRIM(RTRIM(transcription_confidence_text)), N''),
        COALESCE(NULLIF(LTRIM(RTRIM(review_status)), N''), N'draft'),
        COALESCE(NULLIF(LTRIM(RTRIM(include_in_analysis_text)), N''), N'1'),
        NULLIF(LTRIM(RTRIM(exclusion_reason)), N''),
        N'raw'
    FROM stg.Utterance_Import_Xlsx_Raw
    WHERE import_batch_code = @batch_code;

    COMMIT TRANSACTION;

    IF @run_validation = 1
    BEGIN
        EXEC stg.usp_Validate_Utterance_Import @batch_code = @batch_code;
    END;

    SELECT
        import_batch_id,
        batch_code,
        import_status,
        total_row_count,
        valid_row_count,
        invalid_row_count,
        warning_count,
        error_count
    FROM stg.Import_Batch
    WHERE import_batch_id = @import_batch_id;
END;
GO
