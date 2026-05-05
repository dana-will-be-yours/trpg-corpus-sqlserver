USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'stg.Utterance_Import', N'U') IS NULL
BEGIN
    CREATE TABLE stg.Utterance_Import
    (
        utterance_import_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_stg_Utterance_Import PRIMARY KEY,

        import_batch_id BIGINT NOT NULL,

        source_row_no INT NOT NULL,

        project_code NVARCHAR(50) NOT NULL,

        team_code NVARCHAR(50) NOT NULL,

        session_code NVARCHAR(50) NOT NULL,

        scene_code NVARCHAR(50) NULL,

        turn_no_text NVARCHAR(50) NOT NULL,

        sub_turn_no_text NVARCHAR(50) NULL,

        utterance_code NVARCHAR(80) NULL,

        speaker_type NVARCHAR(50) NOT NULL,

        speaker_code NVARCHAR(80) NULL,

        speaker_label_raw NVARCHAR(100) NULL,

        utterance_function NVARCHAR(50) NOT NULL,

        is_in_character_text NVARCHAR(20) NOT NULL,

        is_gm_narration_text NVARCHAR(20) NULL,

        is_rule_related_text NVARCHAR(20) NULL,

        is_decision_related_text NVARCHAR(20) NULL,

        is_knowledge_related_text NVARCHAR(20) NULL,

        start_timecode NVARCHAR(20) NULL,

        end_timecode NVARCHAR(20) NULL,

        duration_sec_text NVARCHAR(50) NULL,

        utterance_text_raw NVARCHAR(MAX) NOT NULL,

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

        import_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_stg_Utterance_Import_import_status
            DEFAULT N'raw',

        validation_error NVARCHAR(MAX) NULL,

        validation_warning NVARCHAR(MAX) NULL,

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_stg_Utterance_Import_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_stg_Utterance_Import_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_stg_Utterance_Import_Import_Batch
            FOREIGN KEY (import_batch_id)
            REFERENCES stg.Import_Batch(import_batch_id),

        CONSTRAINT UQ_stg_Utterance_Import_Batch_Row
            UNIQUE (import_batch_id, source_row_no),

        CONSTRAINT CK_stg_Utterance_Import_Source_Row_No
            CHECK (source_row_no >= 1),

        CONSTRAINT CK_stg_Utterance_Import_Project_Code_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(project_code))) > 0),

        CONSTRAINT CK_stg_Utterance_Import_Team_Code_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(team_code))) > 0),

        CONSTRAINT CK_stg_Utterance_Import_Session_Code_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(session_code))) > 0),

        CONSTRAINT CK_stg_Utterance_Import_Turn_No_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(turn_no_text))) > 0),

        CONSTRAINT CK_stg_Utterance_Import_Speaker_Type_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(speaker_type))) > 0),

        CONSTRAINT CK_stg_Utterance_Import_Function_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(utterance_function))) > 0),

        CONSTRAINT CK_stg_Utterance_Import_In_Character_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(is_in_character_text))) > 0),

        CONSTRAINT CK_stg_Utterance_Import_Text_Raw_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(utterance_text_raw))) > 0),

        CONSTRAINT CK_stg_Utterance_Import_Status
            CHECK (import_status IN (
                N'raw',
                N'checking',
                N'valid',
                N'warning',
                N'error',
                N'loaded_to_dbo',
                N'excluded'
            ))
    );
END;
GO