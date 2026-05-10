USE TRPG_Corpus_DB;
GO

/*
    39_dago_combat_encounter_authoring.sql

    Purpose:
    Add additive authoring tables for da_go text-combat encounters.
    This script does not drop, delete, or truncate data.

    Backup reminder:
    Before applying this schema extension in SSMS 22, back up TRPG_Corpus_DB.
*/

IF SCHEMA_ID(N'stg') IS NULL
BEGIN
    EXEC(N'CREATE SCHEMA stg');
END;
GO

IF OBJECT_ID(N'dbo.DaGo_Combat_Encounter', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DaGo_Combat_Encounter
    (
        encounter_id INT IDENTITY(1,1) NOT NULL,
        encounter_code NVARCHAR(80) NOT NULL,
        passage_code NVARCHAR(80) NULL,
        scene_id INT NULL,
        encounter_title NVARCHAR(200) NULL,
        encounter_intro NVARCHAR(1000) NULL,
        enemy_json NVARCHAR(MAX) NOT NULL,
        win_passage NVARCHAR(80) NULL,
        escape_passage NVARCHAR(80) NULL,
        loss_passage NVARCHAR(80) NULL,
        combat_tags NVARCHAR(MAX) NULL,
        is_tutorial BIT NOT NULL CONSTRAINT DF_DaGo_Combat_Encounter_is_tutorial DEFAULT (0),
        is_active BIT NOT NULL CONSTRAINT DF_DaGo_Combat_Encounter_is_active DEFAULT (1),
        created_at DATETIME2(0) NOT NULL CONSTRAINT DF_DaGo_Combat_Encounter_created_at DEFAULT (SYSUTCDATETIME()),
        updated_at DATETIME2(0) NULL,

        CONSTRAINT PK_DaGo_Combat_Encounter PRIMARY KEY CLUSTERED (encounter_id),
        CONSTRAINT UQ_DaGo_Combat_Encounter_code UNIQUE (encounter_code),
        CONSTRAINT CK_DaGo_Combat_Encounter_code_not_blank CHECK (LEN(LTRIM(RTRIM(encounter_code))) > 0),
        CONSTRAINT CK_DaGo_Combat_Encounter_enemy_json CHECK (ISJSON(enemy_json) = 1),
        CONSTRAINT CK_DaGo_Combat_Encounter_combat_tags CHECK (combat_tags IS NULL OR ISJSON(combat_tags) = 1)
    );
END;
GO

IF OBJECT_ID(N'stg.DaGo_Combat_Encounter_Import', N'U') IS NULL
BEGIN
    CREATE TABLE stg.DaGo_Combat_Encounter_Import
    (
        import_row_id INT IDENTITY(1,1) NOT NULL,
        source_file_name NVARCHAR(260) NULL,
        import_batch_code NVARCHAR(80) NULL,
        encounter_code NVARCHAR(80) NULL,
        passage_code NVARCHAR(80) NULL,
        scene_no NVARCHAR(50) NULL,
        encounter_title NVARCHAR(200) NULL,
        encounter_intro NVARCHAR(1000) NULL,
        enemy_json NVARCHAR(MAX) NULL,
        win_passage NVARCHAR(80) NULL,
        escape_passage NVARCHAR(80) NULL,
        loss_passage NVARCHAR(80) NULL,
        combat_tags NVARCHAR(MAX) NULL,
        is_tutorial NVARCHAR(10) NULL,
        validation_status NVARCHAR(20) NULL,
        validation_message NVARCHAR(1000) NULL,
        created_at DATETIME2(0) NOT NULL CONSTRAINT DF_stg_DaGo_Combat_Encounter_Import_created_at DEFAULT (SYSUTCDATETIME()),

        CONSTRAINT PK_stg_DaGo_Combat_Encounter_Import PRIMARY KEY CLUSTERED (import_row_id),
        CONSTRAINT CK_stg_DaGo_Combat_Encounter_Import_enemy_json CHECK (enemy_json IS NULL OR ISJSON(enemy_json) = 1),
        CONSTRAINT CK_stg_DaGo_Combat_Encounter_Import_combat_tags CHECK (combat_tags IS NULL OR ISJSON(combat_tags) = 1)
    );
END;
GO

CREATE OR ALTER PROCEDURE stg.usp_Validate_DaGo_Combat_Encounter_Import
    @import_batch_code NVARCHAR(80) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE src
        SET validation_status = CASE WHEN err.error_count = 0 THEN N'valid' ELSE N'error' END,
            validation_message = NULLIF(CONCAT(
                CASE WHEN NULLIF(LTRIM(RTRIM(src.encounter_code)), N'') IS NULL THEN N'encounter_code 不可為空；' ELSE N'' END,
                CASE WHEN src.enemy_json IS NULL OR ISJSON(src.enemy_json) <> 1 THEN N'enemy_json 必須為有效 JSON；' ELSE N'' END,
                CASE WHEN src.combat_tags IS NOT NULL AND ISJSON(src.combat_tags) <> 1 THEN N'combat_tags 必須為有效 JSON 陣列或 NULL；' ELSE N'' END
            ), N'')
    FROM stg.DaGo_Combat_Encounter_Import AS src
    CROSS APPLY
    (
        SELECT
            (CASE WHEN NULLIF(LTRIM(RTRIM(src.encounter_code)), N'') IS NULL THEN 1 ELSE 0 END) +
            (CASE WHEN src.enemy_json IS NULL OR ISJSON(src.enemy_json) <> 1 THEN 1 ELSE 0 END) +
            (CASE WHEN src.combat_tags IS NOT NULL AND ISJSON(src.combat_tags) <> 1 THEN 1 ELSE 0 END) AS error_count
    ) AS err
    WHERE @import_batch_code IS NULL
       OR src.import_batch_code = @import_batch_code;
END;
GO

CREATE OR ALTER PROCEDURE stg.usp_Load_DaGo_Combat_Encounter_Import_To_Dbo
    @import_batch_code NVARCHAR(80) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    EXEC stg.usp_Validate_DaGo_Combat_Encounter_Import @import_batch_code = @import_batch_code;

    INSERT INTO dbo.DaGo_Combat_Encounter
    (
        encounter_code,
        passage_code,
        encounter_title,
        encounter_intro,
        enemy_json,
        win_passage,
        escape_passage,
        loss_passage,
        combat_tags,
        is_tutorial
    )
    SELECT
        LTRIM(RTRIM(src.encounter_code)) AS encounter_code,
        NULLIF(LTRIM(RTRIM(src.passage_code)), N'') AS passage_code,
        NULLIF(LTRIM(RTRIM(src.encounter_title)), N'') AS encounter_title,
        NULLIF(LTRIM(RTRIM(src.encounter_intro)), N'') AS encounter_intro,
        src.enemy_json,
        NULLIF(LTRIM(RTRIM(src.win_passage)), N'') AS win_passage,
        NULLIF(LTRIM(RTRIM(src.escape_passage)), N'') AS escape_passage,
        NULLIF(LTRIM(RTRIM(src.loss_passage)), N'') AS loss_passage,
        src.combat_tags,
        CASE WHEN src.is_tutorial IN (N'1', N'true', N'TRUE', N'Y', N'y', N'是') THEN 1 ELSE 0 END AS is_tutorial
    FROM stg.DaGo_Combat_Encounter_Import AS src
    WHERE src.validation_status = N'valid'
      AND (@import_batch_code IS NULL OR src.import_batch_code = @import_batch_code)
      AND NOT EXISTS
      (
          SELECT 1
          FROM dbo.DaGo_Combat_Encounter AS tgt
          WHERE tgt.encounter_code = LTRIM(RTRIM(src.encounter_code))
      );
END;
GO

CREATE OR ALTER VIEW dbo.v_DaGo_Combat_Encounter_Runtime
AS
SELECT
    encounter_code,
    passage_code,
    encounter_title,
    encounter_intro,
    JSON_QUERY(enemy_json) AS enemy_json,
    win_passage,
    escape_passage,
    loss_passage,
    JSON_QUERY(combat_tags) AS combat_tags,
    is_tutorial,
    is_active
FROM dbo.DaGo_Combat_Encounter
WHERE is_active = 1;
GO
