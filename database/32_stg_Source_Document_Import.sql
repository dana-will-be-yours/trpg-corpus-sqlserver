USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'stg.Source_Document_Import', N'U') IS NULL
BEGIN
    CREATE TABLE stg.Source_Document_Import
    (
        source_document_import_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_stg_Source_Document_Import PRIMARY KEY,

        import_batch_id BIGINT NULL,

        source_document_code NVARCHAR(100) NOT NULL,

        project_code NVARCHAR(50) NULL,

        team_code NVARCHAR(50) NULL,

        session_code NVARCHAR(50) NULL,

        source_document_type NVARCHAR(50) NOT NULL,

        source_title NVARCHAR(250) NULL,

        source_author_label NVARCHAR(100) NULL,

        source_url NVARCHAR(500) NULL,

        source_folder_label NVARCHAR(200) NULL,

        file_name NVARCHAR(260) NULL,

        file_extension NVARCHAR(20) NULL,

        mime_type NVARCHAR(100) NULL,

        file_size_bytes BIGINT NULL,

        file_sha256 CHAR(64) NULL,

        storage_mode NVARCHAR(50) NOT NULL
            CONSTRAINT DF_stg_Source_Document_Import_storage_mode
            DEFAULT N'text_only',

        storage_uri NVARCHAR(500) NULL,

        document_binary VARBINARY(MAX) NULL,

        extracted_text_raw NVARCHAR(MAX) NULL,

        parser_name NVARCHAR(100) NULL,

        parser_version NVARCHAR(50) NULL,

        docx_core_title NVARCHAR(250) NULL,

        docx_core_creator NVARCHAR(100) NULL,

        docx_core_created_at DATETIME2(0) NULL,

        docx_core_modified_at DATETIME2(0) NULL,

        paragraph_count INT NULL,

        text_unit_count INT NULL,

        speaker_line_count INT NULL,

        dice_line_count INT NULL,

        table_count INT NULL,

        import_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_stg_Source_Document_Import_import_status
            DEFAULT N'raw',

        validation_error NVARCHAR(MAX) NULL,

        validation_warning NVARCHAR(MAX) NULL,

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_stg_Source_Document_Import_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_stg_Source_Document_Import_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_stg_Source_Document_Import_Batch
            FOREIGN KEY (import_batch_id)
            REFERENCES stg.Import_Batch(import_batch_id),

        CONSTRAINT UQ_stg_Source_Document_Import_Code
            UNIQUE (source_document_code),

        CONSTRAINT CK_stg_Source_Document_Import_Code_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(source_document_code))) > 0),

        CONSTRAINT CK_stg_Source_Document_Import_Type
            CHECK (source_document_type IN (
                N'trpg_transcript',
                N'extended_creation',
                N'hybrid_creation',
                N'forum_html',
                N'da_go_playlog',
                N'researcher_note',
                N'other'
            )),

        CONSTRAINT CK_stg_Source_Document_Import_Storage_Mode
            CHECK (storage_mode IN (
                N'text_only',
                N'database_binary',
                N'local_path',
                N'external_uri',
                N'not_stored'
            )),

        CONSTRAINT CK_stg_Source_Document_Import_File_Size
            CHECK (file_size_bytes IS NULL OR file_size_bytes >= 0),

        CONSTRAINT CK_stg_Source_Document_Import_SHA256
            CHECK (file_sha256 IS NULL OR file_sha256 NOT LIKE '%[^0-9A-Fa-f]%'),

        CONSTRAINT CK_stg_Source_Document_Import_Counts
            CHECK (
                (paragraph_count IS NULL OR paragraph_count >= 0)
                AND (text_unit_count IS NULL OR text_unit_count >= 0)
                AND (speaker_line_count IS NULL OR speaker_line_count >= 0)
                AND (dice_line_count IS NULL OR dice_line_count >= 0)
                AND (table_count IS NULL OR table_count >= 0)
            ),

        CONSTRAINT CK_stg_Source_Document_Import_Status
            CHECK (import_status IN (
                N'raw',
                N'parsed',
                N'in_review',
                N'reviewed',
                N'validated',
                N'loaded',
                N'error',
                N'excluded'
            ))
    );
END;
GO
