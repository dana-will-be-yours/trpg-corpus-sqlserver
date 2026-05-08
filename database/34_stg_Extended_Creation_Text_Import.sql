USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'stg.Extended_Creation_Text_Import', N'U') IS NULL
BEGIN
    CREATE TABLE stg.Extended_Creation_Text_Import
    (
        extended_creation_text_import_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_stg_Extended_Creation_Text_Import PRIMARY KEY,

        source_document_import_id BIGINT NULL,

        source_row_no INT NOT NULL,

        project_code NVARCHAR(50) NOT NULL,

        team_code NVARCHAR(50) NOT NULL,

        session_code NVARCHAR(50) NULL,

        scene_code NVARCHAR(50) NULL,

        creation_code NVARCHAR(80) NOT NULL,

        creation_no_text NVARCHAR(50) NOT NULL,

        creation_title NVARCHAR(250) NOT NULL,

        creation_type NVARCHAR(50) NOT NULL,

        creation_stage NVARCHAR(50) NOT NULL,

        authoring_mode NVARCHAR(50) NOT NULL,

        author_member_code NVARCHAR(50) NULL,

        source_material_note NVARCHAR(MAX) NULL,

        creation_text_raw NVARCHAR(MAX) NOT NULL,

        creation_text_clean NVARCHAR(MAX) NULL,

        creation_text_verified NVARCHAR(MAX) NULL,

        creation_summary NVARCHAR(MAX) NULL,

        theme_summary NVARCHAR(MAX) NULL,

        plot_summary NVARCHAR(MAX) NULL,

        character_summary NVARCHAR(MAX) NULL,

        worldbuilding_summary NVARCHAR(MAX) NULL,

        conflict_summary NVARCHAR(MAX) NULL,

        decision_trace_summary NVARCHAR(MAX) NULL,

        knowledge_trace_summary NVARCHAR(MAX) NULL,

        trpg_source_trace_summary NVARCHAR(MAX) NULL,

        narrative_coherence_note NVARCHAR(MAX) NULL,

        originality_note NVARCHAR(MAX) NULL,

        completeness_note NVARCHAR(MAX) NULL,

        smm_relevance_note NVARCHAR(MAX) NULL,

        tms_relevance_note NVARCHAR(MAX) NULL,

        evaluation_note NVARCHAR(MAX) NULL,

        word_count_text NVARCHAR(50) NULL,

        version_no_text NVARCHAR(50) NULL,

        is_final_version_text NVARCHAR(20) NULL,

        source_type NVARCHAR(50) NOT NULL,

        extraction_method NVARCHAR(50) NULL,

        review_status NVARCHAR(50) NOT NULL,

        include_in_analysis_text NVARCHAR(20) NULL,

        exclusion_reason NVARCHAR(MAX) NULL,

        import_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_stg_Extended_Creation_Text_Import_import_status
            DEFAULT N'raw',

        validation_error NVARCHAR(MAX) NULL,

        validation_warning NVARCHAR(MAX) NULL,

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_stg_Extended_Creation_Text_Import_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_stg_Extended_Creation_Text_Import_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_stg_Extended_Creation_Text_Import_Document
            FOREIGN KEY (source_document_import_id)
            REFERENCES stg.Source_Document_Import(source_document_import_id),

        CONSTRAINT UQ_stg_Extended_Creation_Text_Import_Doc_Row
            UNIQUE (source_document_import_id, source_row_no),

        CONSTRAINT CK_stg_Extended_Creation_Text_Import_Row_No
            CHECK (source_row_no >= 1),

        CONSTRAINT CK_stg_Extended_Creation_Text_Import_Text_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(creation_text_raw))) > 0),

        CONSTRAINT CK_stg_Extended_Creation_Text_Import_Type
            CHECK (creation_type IN (
                N'short_story',
                N'novel_excerpt',
                N'worldbuilding_text',
                N'character_story',
                N'ip_proposal',
                N'game_proposal',
                N'story_outline',
                N'script',
                N'campaign_summary',
                N'creative_brief',
                N'other'
            )),

        CONSTRAINT CK_stg_Extended_Creation_Text_Import_Stage
            CHECK (creation_stage IN (
                N'draft',
                N'revised',
                N'cleaned',
                N'verified',
                N'final',
                N'excluded'
            )),

        CONSTRAINT CK_stg_Extended_Creation_Text_Import_Authoring
            CHECK (authoring_mode IN (
                N'individual',
                N'pair',
                N'team',
                N'gm',
                N'ai_assisted',
                N'unknown'
            )),

        CONSTRAINT CK_stg_Extended_Creation_Text_Import_Source_Type
            CHECK (source_type IN (
                N'human_created',
                N'ai_generated',
                N'ai_assisted',
                N'human_modified',
                N'trpg_derived',
                N'database_imported',
                N'unknown'
            )),

        CONSTRAINT CK_stg_Extended_Creation_Text_Import_Review
            CHECK (review_status IN (
                N'draft',
                N'in_review',
                N'reviewed',
                N'verified',
                N'excluded'
            )),

        CONSTRAINT CK_stg_Extended_Creation_Text_Import_Status
            CHECK (import_status IN (
                N'raw',
                N'valid',
                N'warning',
                N'error',
                N'loaded_to_dbo',
                N'excluded'
            ))
    );
END;
GO
