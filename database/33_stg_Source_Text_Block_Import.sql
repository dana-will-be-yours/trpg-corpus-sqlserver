USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'stg.Source_Text_Block_Import', N'U') IS NULL
BEGIN
    CREATE TABLE stg.Source_Text_Block_Import
    (
        source_text_block_import_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_stg_Source_Text_Block_Import PRIMARY KEY,

        source_document_import_id BIGINT NOT NULL,

        source_block_no INT NOT NULL,

        paragraph_no INT NULL,

        line_no INT NULL,

        style_name NVARCHAR(100) NULL,

        block_type_candidate NVARCHAR(50) NOT NULL,

        scene_code_candidate NVARCHAR(50) NULL,

        turn_no_text NVARCHAR(50) NULL,

        speaker_type_candidate NVARCHAR(50) NULL,

        speaker_code_candidate NVARCHAR(80) NULL,

        speaker_label_candidate NVARCHAR(100) NULL,

        utterance_function_candidate NVARCHAR(50) NULL,

        is_in_character_text NVARCHAR(20) NULL,

        text_raw NVARCHAR(MAX) NOT NULL,

        text_clean NVARCHAR(MAX) NULL,

        extraction_note NVARCHAR(MAX) NULL,

        ai_annotation_json NVARCHAR(MAX) NULL,

        human_review_note NVARCHAR(MAX) NULL,

        review_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_stg_Source_Text_Block_Import_review_status
            DEFAULT N'raw',

        include_in_analysis_text NVARCHAR(20) NULL,

        import_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_stg_Source_Text_Block_Import_import_status
            DEFAULT N'raw',

        validation_error NVARCHAR(MAX) NULL,

        validation_warning NVARCHAR(MAX) NULL,

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_stg_Source_Text_Block_Import_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_stg_Source_Text_Block_Import_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_stg_Source_Text_Block_Import_Document
            FOREIGN KEY (source_document_import_id)
            REFERENCES stg.Source_Document_Import(source_document_import_id),

        CONSTRAINT UQ_stg_Source_Text_Block_Import_Doc_Block
            UNIQUE (source_document_import_id, source_block_no),

        CONSTRAINT CK_stg_Source_Text_Block_Import_Block_No
            CHECK (source_block_no >= 1),

        CONSTRAINT CK_stg_Source_Text_Block_Import_Text_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(text_raw))) > 0),

        CONSTRAINT CK_stg_Source_Text_Block_Import_Block_Type
            CHECK (block_type_candidate IN (
                N'metadata',
                N'chapter_heading',
                N'scene_heading',
                N'utterance',
                N'action_note',
                N'dice_roll',
                N'dice_result',
                N'narration',
                N'prose',
                N'blank',
                N'other'
            )),

        CONSTRAINT CK_stg_Source_Text_Block_Import_Speaker_Type
            CHECK (
                speaker_type_candidate IS NULL
                OR speaker_type_candidate IN (
                    N'GM',
                    N'PL',
                    N'PC',
                    N'NPC',
                    N'Observer',
                    N'Researcher',
                    N'Unknown'
                )
            ),

        CONSTRAINT CK_stg_Source_Text_Block_Import_Function
            CHECK (
                utterance_function_candidate IS NULL
                OR utterance_function_candidate IN (
                    N'narration',
                    N'dialogue',
                    N'action',
                    N'rule_check',
                    N'decision',
                    N'negotiation',
                    N'question',
                    N'clarification',
                    N'conflict',
                    N'summary'
                )
            ),

        CONSTRAINT CK_stg_Source_Text_Block_Import_Review
            CHECK (review_status IN (
                N'raw',
                N'needs_review',
                N'in_review',
                N'reviewed',
                N'verified',
                N'excluded'
            )),

        CONSTRAINT CK_stg_Source_Text_Block_Import_Status
            CHECK (import_status IN (
                N'raw',
                N'parsed',
                N'converted_to_utterance_import',
                N'converted_to_creation_import',
                N'error',
                N'excluded'
            ))
    );
END;
GO
