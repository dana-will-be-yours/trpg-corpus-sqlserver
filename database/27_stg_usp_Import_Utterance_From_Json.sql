USE TRPG_Corpus_DB;
GO

CREATE OR ALTER PROCEDURE stg.usp_Import_Utterance_From_Json
    @json NVARCHAR(MAX),
    @source_file_name NVARCHAR(260) = NULL,
    @imported_by NVARCHAR(100) = NULL,
    @run_validation BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @json IS NULL OR ISJSON(@json) <> 1
    BEGIN
        THROW 53001, N'@json 不是有效 JSON。', 1;
    END;

    DECLARE @batch_code NVARCHAR(100) = JSON_VALUE(@json, N'$.stg_Import_Batch.batch_code');
    DECLARE @project_code NVARCHAR(50) = JSON_VALUE(@json, N'$.stg_Import_Batch.project_code');
    DECLARE @import_batch_id BIGINT;

    IF @batch_code IS NULL OR LTRIM(RTRIM(@batch_code)) = N''
    BEGIN
        SET @batch_code = JSON_VALUE(@json, N'$.metadata.import_batch_code');
    END;

    IF @project_code IS NULL OR LTRIM(RTRIM(@project_code)) = N''
    BEGIN
        SET @project_code = JSON_VALUE(@json, N'$.metadata.project_code');
    END;

    IF @batch_code IS NULL OR LTRIM(RTRIM(@batch_code)) = N''
    BEGIN
        THROW 53002, N'JSON 缺少 stg_Import_Batch.batch_code 或 metadata.import_batch_code。', 1;
    END;

    IF @project_code IS NULL OR LTRIM(RTRIM(@project_code)) = N''
    BEGIN
        THROW 53003, N'JSON 缺少 stg_Import_Batch.project_code 或 metadata.project_code。', 1;
    END;

    IF EXISTS (SELECT 1 FROM stg.Import_Batch WHERE batch_code = @batch_code)
    BEGIN
        THROW 53004, N'batch_code 已存在。請更換批次代碼，避免重複匯入。', 1;
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
        total_row_count,
        import_note
    )
    SELECT
        @batch_code,
        @project_code,
        N'stg.Utterance_Import',
        COALESCE(@source_file_name, JSON_VALUE(@json, N'$.stg_Import_Batch.source_file_name'), JSON_VALUE(@json, N'$.metadata.source_file_name')),
        N'json',
        COALESCE(JSON_VALUE(@json, N'$.stg_Import_Batch.import_purpose'), N'web transcript input'),
        COALESCE(@imported_by, JSON_VALUE(@json, N'$.stg_Import_Batch.imported_by'), N'web/dago-corpus-input.html'),
        N'imported',
        (SELECT COUNT(*) FROM OPENJSON(@json, N'$.stg_Utterance_Import')),
        JSON_QUERY(@json, N'$.metadata');

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
    FROM OPENJSON(@json, N'$.stg_Utterance_Import')
    WITH
    (
        source_row_no INT N'$.source_row_no',
        project_code NVARCHAR(50) N'$.project_code',
        team_code NVARCHAR(50) N'$.team_code',
        session_code NVARCHAR(50) N'$.session_code',
        scene_code NVARCHAR(50) N'$.scene_code',
        turn_no_text NVARCHAR(50) N'$.turn_no_text',
        sub_turn_no_text NVARCHAR(50) N'$.sub_turn_no_text',
        utterance_code NVARCHAR(80) N'$.utterance_code',
        speaker_type NVARCHAR(50) N'$.speaker_type',
        speaker_code NVARCHAR(80) N'$.speaker_code',
        speaker_label_raw NVARCHAR(100) N'$.speaker_label_raw',
        utterance_function NVARCHAR(50) N'$.utterance_function',
        is_in_character_text NVARCHAR(20) N'$.is_in_character_text',
        is_gm_narration_text NVARCHAR(20) N'$.is_gm_narration_text',
        is_rule_related_text NVARCHAR(20) N'$.is_rule_related_text',
        is_decision_related_text NVARCHAR(20) N'$.is_decision_related_text',
        is_knowledge_related_text NVARCHAR(20) N'$.is_knowledge_related_text',
        start_timecode NVARCHAR(20) N'$.start_timecode',
        end_timecode NVARCHAR(20) N'$.end_timecode',
        duration_sec_text NVARCHAR(50) N'$.duration_sec_text',
        utterance_text_raw NVARCHAR(MAX) N'$.utterance_text_raw',
        utterance_text_clean NVARCHAR(MAX) N'$.utterance_text_clean',
        utterance_text_verified NVARCHAR(MAX) N'$.utterance_text_verified',
        language_code NVARCHAR(20) N'$.language_code',
        emotion_label NVARCHAR(50) N'$.emotion_label',
        interaction_target_type NVARCHAR(50) N'$.interaction_target_type',
        interaction_target_code NVARCHAR(80) N'$.interaction_target_code',
        related_rule_code NVARCHAR(50) N'$.related_rule_code',
        related_world_setting_code NVARCHAR(50) N'$.related_world_setting_code',
        related_item_code NVARCHAR(50) N'$.related_item_code',
        ai_summary NVARCHAR(MAX) N'$.ai_summary',
        ai_annotation_json NVARCHAR(MAX) N'$.ai_annotation_json',
        human_annotation_note NVARCHAR(MAX) N'$.human_annotation_note',
        transcription_confidence_text NVARCHAR(50) N'$.transcription_confidence_text',
        review_status NVARCHAR(50) N'$.review_status',
        include_in_analysis_text NVARCHAR(20) N'$.include_in_analysis_text',
        exclusion_reason NVARCHAR(MAX) N'$.exclusion_reason'
    );

    COMMIT TRANSACTION;

    IF @run_validation = 1
    BEGIN
        EXEC stg.usp_Validate_Utterance_Import @batch_code = @batch_code;
    END;

    SELECT
        ib.import_batch_id,
        ib.batch_code,
        ib.import_status,
        ib.total_row_count,
        ib.valid_row_count,
        ib.invalid_row_count,
        ib.warning_count,
        ib.error_count
    FROM stg.Import_Batch AS ib
    WHERE ib.import_batch_id = @import_batch_id;
END;
GO
