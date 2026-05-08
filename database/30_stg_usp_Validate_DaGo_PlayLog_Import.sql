USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE stg.usp_Validate_DaGo_PlayLog_Import
    @playlog_code NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @json NVARCHAR(MAX);
    DECLARE @error NVARCHAR(MAX) = N'';
    DECLARE @warning NVARCHAR(MAX) = N'';
    DECLARE @row_count INT = 0;

    SELECT @json = playlog_json
    FROM stg.DaGo_PlayLog_Import
    WHERE playlog_code = @playlog_code;

    IF @json IS NULL
    BEGIN
        THROW 51100, 'playlog_code not found.', 1;
    END;

    UPDATE stg.DaGo_PlayLog_Import
    SET
        validation_status = N'checking',
        project_code = COALESCE(project_code, JSON_VALUE(playlog_json, '$.metadata.project_code')),
        team_code = COALESCE(team_code, JSON_VALUE(playlog_json, '$.metadata.team_code')),
        session_code = COALESCE(session_code, JSON_VALUE(playlog_json, '$.metadata.session_code')),
        updated_at = SYSDATETIME()
    WHERE playlog_code = @playlog_code;

    SELECT @row_count = COUNT(*)
    FROM OPENJSON(@json, '$.stg_Utterance_Import');

    IF @row_count = 0
    BEGIN
        SET @error = CONCAT(@error, N'No stg_Utterance_Import rows were found. ');
    END;

    IF JSON_VALUE(@json, '$.metadata.export_format') NOT IN (N'da_go_playlog_json_v2', N'da_go_playlog_json_v1')
    BEGIN
        SET @warning = CONCAT(@warning, N'Unknown da_go export_format. ');
    END;

    IF EXISTS (
        SELECT 1
        FROM OPENJSON(@json, '$.stg_Utterance_Import')
        WITH (
            speaker_type NVARCHAR(50) '$.speaker_type'
        ) AS rows
        WHERE rows.speaker_type NOT IN (N'GM', N'PL', N'PC', N'NPC', N'Observer', N'Researcher')
    )
    BEGIN
        SET @error = CONCAT(@error, N'Invalid speaker_type found. ');
    END;

    IF EXISTS (
        SELECT 1
        FROM OPENJSON(@json, '$.stg_Utterance_Import')
        WITH (
            utterance_function NVARCHAR(50) '$.utterance_function'
        ) AS rows
        WHERE rows.utterance_function NOT IN (
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
    )
    BEGIN
        SET @error = CONCAT(@error, N'Invalid utterance_function found. ');
    END;

    IF EXISTS (
        SELECT turn_no_text
        FROM OPENJSON(@json, '$.stg_Utterance_Import')
        WITH (
            turn_no_text NVARCHAR(50) '$.turn_no_text'
        ) AS rows
        GROUP BY turn_no_text
        HAVING COUNT(*) > 1
    )
    BEGIN
        SET @error = CONCAT(@error, N'Duplicate turn_no_text found. ');
    END;

    IF EXISTS (
        SELECT 1
        FROM OPENJSON(@json, '$.stg_Utterance_Import')
        WITH (
            turn_no_text NVARCHAR(50) '$.turn_no_text',
            utterance_text_raw NVARCHAR(MAX) '$.utterance_text_raw'
        ) AS rows
        WHERE TRY_CONVERT(INT, rows.turn_no_text) IS NULL
           OR TRY_CONVERT(INT, rows.turn_no_text) < 1
           OR NULLIF(LTRIM(RTRIM(rows.utterance_text_raw)), N'') IS NULL
    )
    BEGIN
        SET @error = CONCAT(@error, N'Blank text or invalid turn_no_text found. ');
    END;

    UPDATE stg.DaGo_PlayLog_Import
    SET
        validation_error = NULLIF(@error, N''),
        validation_warning = NULLIF(@warning, N''),
        validation_status =
            CASE
                WHEN NULLIF(@error, N'') IS NOT NULL THEN N'error'
                WHEN NULLIF(@warning, N'') IS NOT NULL THEN N'warning'
                ELSE N'valid'
            END,
        updated_at = SYSDATETIME()
    WHERE playlog_code = @playlog_code;

    SELECT
        playlog_code,
        validation_status,
        validation_error,
        validation_warning,
        @row_count AS utterance_row_count
    FROM stg.DaGo_PlayLog_Import
    WHERE playlog_code = @playlog_code;
END;
GO
