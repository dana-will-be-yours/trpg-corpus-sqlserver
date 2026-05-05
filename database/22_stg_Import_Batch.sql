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

IF OBJECT_ID(N'stg.Import_Batch', N'U') IS NULL
BEGIN
    CREATE TABLE [stg].[Import_Batch]
    (
        import_batch_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_stg_Import_Batch PRIMARY KEY,

        batch_code NVARCHAR(100) NOT NULL,

        project_code NVARCHAR(50) NOT NULL,

        source_table_name NVARCHAR(128) NOT NULL,

        source_file_name NVARCHAR(260) NULL,

        source_file_type NVARCHAR(50) NOT NULL
            CONSTRAINT DF_stg_Import_Batch_source_file_type
            DEFAULT N'csv_utf8',

        import_purpose NVARCHAR(200) NULL,

        imported_by NVARCHAR(100) NULL,

        import_started_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_stg_Import_Batch_import_started_at
            DEFAULT SYSDATETIME(),

        import_finished_at DATETIME2(0) NULL,

        import_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_stg_Import_Batch_import_status
            DEFAULT N'created',

        total_row_count INT NULL,

        valid_row_count INT NULL,

        invalid_row_count INT NULL,

        warning_count INT NULL,

        error_count INT NULL,

        import_note NVARCHAR(MAX) NULL,

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_stg_Import_Batch_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_stg_Import_Batch_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT UQ_stg_Import_Batch_BatchCode
            UNIQUE (batch_code),

        CONSTRAINT CK_stg_Import_Batch_BatchCode_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(batch_code))) > 0),

        CONSTRAINT CK_stg_Import_Batch_ProjectCode_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(project_code))) > 0),

        CONSTRAINT CK_stg_Import_Batch_SourceTable_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(source_table_name))) > 0),

        CONSTRAINT CK_stg_Import_Batch_Source_File_Type
            CHECK (source_file_type IN (
                N'csv_utf8',
                N'xlsx',
                N'txt',
                N'json',
                N'manual',
                N'unknown'
            )),

        CONSTRAINT CK_stg_Import_Batch_Status
            CHECK (import_status IN (
                N'created',
                N'importing',
                N'imported',
                N'checking',
                N'checked',
                N'has_error',
                N'approved',
                N'loaded_to_dbo',
                N'excluded'
            )),

        CONSTRAINT CK_stg_Import_Batch_Row_Count
            CHECK (total_row_count IS NULL OR total_row_count >= 0),

        CONSTRAINT CK_stg_Import_Batch_Valid_Row_Count
            CHECK (valid_row_count IS NULL OR valid_row_count >= 0),

        CONSTRAINT CK_stg_Import_Batch_Invalid_Row_Count
            CHECK (invalid_row_count IS NULL OR invalid_row_count >= 0),

        CONSTRAINT CK_stg_Import_Batch_Warning_Count
            CHECK (warning_count IS NULL OR warning_count >= 0),

        CONSTRAINT CK_stg_Import_Batch_Error_Count
            CHECK (error_count IS NULL OR error_count >= 0)
    );
END;
GO
