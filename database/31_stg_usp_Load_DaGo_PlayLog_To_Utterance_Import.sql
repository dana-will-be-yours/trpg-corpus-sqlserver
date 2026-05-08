USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE stg.usp_Load_DaGo_PlayLog_To_Utterance_Import
    @playlog_code NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @json NVARCHAR(MAX);
    DECLARE @batch_code NVARCHAR(100);
    DECLARE @project_code NVARCHAR(50);
    DECLARE @batch_id BIGINT;
    DECLARE @validation_status NVARCHAR(50);

    SELECT
        @json = playlog_json,
        @validation_status = validation_status
    FROM stg.DaGo_PlayLog_Import
    WHERE playlog_code = @playlog_code;

    IF @json IS NULL
    BEGIN
        THROW 51200, 'playlog_code not found.', 1;
    END;

    IF @validation_status NOT IN (N'valid', N'warning')
    BEGIN
        EXEC stg.usp_Validate_DaGo_PlayLog_Import @playlog_code = @playlog_code;

        SELECT @validation_status = validation_status
        FROM stg.DaGo_PlayLog_Import
        WHERE playlog_code = @playlog_code;
    END;

    IF @validation_status = N'error'
    BEGIN
        THROW 51201, 'DaGo playlog has validation errors.', 1;
    END;

    SET @batch_code = COALESCE(
        JSON_VALUE(@json, '$.metadata.import_batch_code'),
        CONCAT(N'DAGO_', @playlog_code)
    );
    SET @project_code = JSON_VALUE(@json, '$.metadata.project_code');

    BEGIN TRANSACTION;

    IF NOT EXISTS (
        SELECT 1
        FROM stg.Import_Batch
        WHERE batch_code = @batch_code
    )
    BEGIN
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
            JSON_VALUE(@json, '$.stg_Import_Batch.source_file_name'),
            N'json',
            N'da_go playlog roundtrip',
            N'da_go',
            N'imported',
            COUNT(*),
            @playlog_code
        FROM OPENJSON(@json, '$.stg_Utterance_Import');
    END;

    SELECT @batch_id = import_batch_id
    FROM stg.Import_Batch
    WHERE batch_code = @batch_code;

    IF EXISTS (
        SELECT 1
        FROM stg.Utterance_Import
        WHERE import_batch_id = @batch_id
    )
    BEGIN
        THROW 51202, 'Target stg.Utterance_Import batch already has rows.', 1;
    END;

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
        @batch_id,
        rows.source_row_no,
        rows.project_code,
        rows.team_code,
        rows.session_code,
        rows.scene_code,
        rows.turn_no_text,
        rows.sub_turn_no_text,
        rows.utterance_code,
        rows.speaker_type,
        rows.speaker_code,
        rows.speaker_label_raw,
        rows.utterance_function,
        rows.is_in_character_text,
        rows.is_gm_narration_text,
        rows.is_rule_related_text,
        rows.is_decision_related_text,
        rows.is_knowledge_related_text,
        rows.start_timecode,
        rows.end_timecode,
        rows.duration_sec_text,
        rows.utterance_text_raw,
        rows.utterance_text_clean,
        rows.utterance_text_verified,
        rows.language_code,
        rows.emotion_label,
        rows.interaction_target_type,
        rows.interaction_target_code,
        rows.related_rule_code,
        rows.related_world_setting_code,
        rows.related_item_code,
        rows.ai_summary,
        rows.ai_annotation_json,
        rows.human_annotation_note,
        rows.transcription_confidence_text,
        rows.review_status,
        rows.include_in_analysis_text,
        rows.exclusion_reason,
        N'raw'
    FROM OPENJSON(@json, '$.stg_Utterance_Import')
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
    ) AS rows
    ORDER BY rows.source_row_no;

    UPDATE stg.DaGo_PlayLog_Import
    SET
        import_batch_id = @batch_id,
        validation_status = N'loaded_to_utterance_import',
        updated_at = SYSDATETIME()
    WHERE playlog_code = @playlog_code;

    COMMIT TRANSACTION;

    SELECT
        @playlog_code AS playlog_code,
        @batch_code AS batch_code,
        @batch_id AS import_batch_id,
        COUNT(*) AS inserted_row_count
    FROM stg.Utterance_Import
    WHERE import_batch_id = @batch_id;
END;
GO
