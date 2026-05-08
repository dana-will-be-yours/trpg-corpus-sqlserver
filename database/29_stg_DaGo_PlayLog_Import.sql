USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'stg.DaGo_PlayLog_Import', N'U') IS NULL
BEGIN
    CREATE TABLE stg.DaGo_PlayLog_Import
    (
        dago_playlog_import_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_stg_DaGo_PlayLog_Import PRIMARY KEY,

        import_batch_id BIGINT NULL,

        playlog_code NVARCHAR(100) NOT NULL,

        project_code NVARCHAR(50) NULL,

        team_code NVARCHAR(50) NULL,

        session_code NVARCHAR(50) NULL,

        source_file_name NVARCHAR(260) NULL,

        playlog_json NVARCHAR(MAX) NOT NULL,

        validation_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_stg_DaGo_PlayLog_Import_validation_status
            DEFAULT N'raw',

        validation_error NVARCHAR(MAX) NULL,

        validation_warning NVARCHAR(MAX) NULL,

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_stg_DaGo_PlayLog_Import_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_stg_DaGo_PlayLog_Import_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_stg_DaGo_PlayLog_Import_Import_Batch
            FOREIGN KEY (import_batch_id)
            REFERENCES stg.Import_Batch(import_batch_id),

        CONSTRAINT UQ_stg_DaGo_PlayLog_Import_PlaylogCode
            UNIQUE (playlog_code),

        CONSTRAINT CK_stg_DaGo_PlayLog_Import_PlaylogCode_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(playlog_code))) > 0),

        CONSTRAINT CK_stg_DaGo_PlayLog_Import_IsJson
            CHECK (ISJSON(playlog_json) = 1),

        CONSTRAINT CK_stg_DaGo_PlayLog_Import_Status
            CHECK (validation_status IN (
                N'raw',
                N'checking',
                N'valid',
                N'warning',
                N'error',
                N'loaded_to_utterance_import',
                N'excluded'
            ))
    );
END;
GO
