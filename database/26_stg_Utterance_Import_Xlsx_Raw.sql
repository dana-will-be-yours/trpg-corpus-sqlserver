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

IF OBJECT_ID(N'stg.Utterance_Import_Xlsx_Raw', N'U') IS NULL
BEGIN
    CREATE TABLE stg.Utterance_Import_Xlsx_Raw
    (
        xlsx_raw_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_stg_Utterance_Import_Xlsx_Raw PRIMARY KEY,

        import_batch_code NVARCHAR(100) NULL,
        import_batch_id NVARCHAR(50) NULL,
        source_row_no NVARCHAR(50) NULL,
        project_code NVARCHAR(50) NULL,
        team_code NVARCHAR(50) NULL,
        session_code NVARCHAR(50) NULL,
        scene_code NVARCHAR(50) NULL,
        turn_no_text NVARCHAR(50) NULL,
        sub_turn_no_text NVARCHAR(50) NULL,
        utterance_code NVARCHAR(80) NULL,
        speaker_type NVARCHAR(50) NULL,
        speaker_code NVARCHAR(80) NULL,
        speaker_label_raw NVARCHAR(100) NULL,
        utterance_function NVARCHAR(50) NULL,
        is_in_character_text NVARCHAR(20) NULL,
        is_gm_narration_text NVARCHAR(20) NULL,
        is_rule_related_text NVARCHAR(20) NULL,
        is_decision_related_text NVARCHAR(20) NULL,
        is_knowledge_related_text NVARCHAR(20) NULL,
        start_timecode NVARCHAR(20) NULL,
        end_timecode NVARCHAR(20) NULL,
        duration_sec_text NVARCHAR(50) NULL,
        utterance_text_raw NVARCHAR(MAX) NULL,
        utterance_text_clean NVARCHAR(MAX) NULL,
        utterance_text_verified NVARCHAR(MAX) NULL,
        language_code NVARCHAR(20) NULL,
        emotion_label NVARCHAR(50) NULL,
        interaction_target_type NVARCHAR(50) NULL,
        interaction_target_code NVARCHAR(80) NULL,
        related_rule_code NVARCHAR(50) NULL,
        related_world_setting_code NVARCHAR(50) NULL,
        related_item_code NVARCHAR(50) NULL,
        ai_summary NVARCHAR(MAX) NULL,
        ai_annotation_json NVARCHAR(MAX) NULL,
        human_annotation_note NVARCHAR(MAX) NULL,
        transcription_confidence_text NVARCHAR(50) NULL,
        review_status NVARCHAR(50) NULL,
        include_in_analysis_text NVARCHAR(20) NULL,
        exclusion_reason NVARCHAR(MAX) NULL,
        import_status NVARCHAR(50) NULL,

        source_file_name NVARCHAR(260) NULL,
        source_sheet_name NVARCHAR(128) NULL,
        frontend_validation_error NVARCHAR(MAX) NULL,
        frontend_validation_warning NVARCHAR(MAX) NULL,
        raw_import_note NVARCHAR(MAX) NULL,

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_stg_Utterance_Import_Xlsx_Raw_created_at
            DEFAULT SYSDATETIME(),
        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_stg_Utterance_Import_Xlsx_Raw_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT CK_stg_Utterance_Import_Xlsx_Raw_Row_No
            CHECK (source_row_no IS NULL OR TRY_CONVERT(INT, source_row_no) IS NULL OR TRY_CONVERT(INT, source_row_no) >= 1)
    );
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_stg_Utterance_Import_Xlsx_Raw_Batch_Row'
      AND object_id = OBJECT_ID(N'stg.Utterance_Import_Xlsx_Raw')
)
BEGIN
    CREATE INDEX IX_stg_Utterance_Import_Xlsx_Raw_Batch_Row
    ON stg.Utterance_Import_Xlsx_Raw(import_batch_code, source_row_no);
END;
GO
