USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'stg.DaGo_Researcher_Story_Import', N'U') IS NULL
BEGIN
    CREATE TABLE stg.DaGo_Researcher_Story_Import
    (
        dago_researcher_story_import_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_DaGo_Researcher_Story_Import PRIMARY KEY,

        story_code NVARCHAR(100) NOT NULL,

        project_code NVARCHAR(50) NULL,

        team_code NVARCHAR(50) NULL,

        session_code NVARCHAR(50) NULL,

        source_file_name NVARCHAR(260) NULL,

        story_json NVARCHAR(MAX) NOT NULL,

        auto_load BIT NOT NULL
            CONSTRAINT DF_DaGo_Researcher_Story_Import_auto_load
            DEFAULT 1,

        validation_status NVARCHAR(30) NOT NULL
            CONSTRAINT DF_DaGo_Researcher_Story_Import_validation_status
            DEFAULT N'raw',

        validation_message NVARCHAR(MAX) NULL,

        import_status NVARCHAR(30) NOT NULL
            CONSTRAINT DF_DaGo_Researcher_Story_Import_import_status
            DEFAULT N'raw',

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_DaGo_Researcher_Story_Import_created_at
            DEFAULT SYSDATETIME(),

        loaded_at DATETIME2(0) NULL,

        CONSTRAINT UQ_DaGo_Researcher_Story_Import_Code
            UNIQUE (story_code),

        CONSTRAINT CK_DaGo_Researcher_Story_Import_Code_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(story_code))) > 0),

        CONSTRAINT CK_DaGo_Researcher_Story_Import_Json
            CHECK (ISJSON(story_json) = 1)
    );
END;
GO

CREATE OR ALTER PROCEDURE stg.usp_Validate_DaGo_Researcher_Story_Import
    @story_code NVARCHAR(100),
    @return_result BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @story_json NVARCHAR(MAX);
    DECLARE @passage_count INT = 0;
    DECLARE @error NVARCHAR(MAX) = N'';

    SELECT @story_json = story_json
    FROM stg.DaGo_Researcher_Story_Import
    WHERE story_code = @story_code;

    IF @story_json IS NULL
    BEGIN
        THROW 51039, 'DaGo researcher story import row not found.', 1;
    END;

    IF ISJSON(@story_json) <> 1
    BEGIN
        SET @error = CONCAT(@error, N'story_json 不是有效 JSON。');
    END
    ELSE
    BEGIN
        SELECT @passage_count = COUNT(*)
        FROM OPENJSON(@story_json, N'$.passages');

        IF @passage_count = 0
        BEGIN
            SET @error = CONCAT(@error, N'passages 不可為空。');
        END;

        IF EXISTS (
            SELECT 1
            FROM OPENJSON(@story_json, N'$.passages')
                 WITH (
                     passage_code NVARCHAR(100) N'$.passage_code',
                     id NVARCHAR(100) N'$.id',
                     title NVARCHAR(200) N'$.title',
                     body NVARCHAR(MAX) N'$.body'
                 ) AS p
            WHERE NULLIF(LTRIM(RTRIM(COALESCE(p.passage_code, p.id, N''))), N'') IS NULL
               OR NULLIF(LTRIM(RTRIM(COALESCE(p.title, N''))), N'') IS NULL
               OR NULLIF(LTRIM(RTRIM(COALESCE(p.body, N''))), N'') IS NULL
        )
        BEGIN
            SET @error = CONCAT(@error, N' passage 需有 passage_code/id、title、body。');
        END;
    END;

    UPDATE stg.DaGo_Researcher_Story_Import
    SET validation_status = CASE WHEN LEN(@error) = 0 THEN N'valid' ELSE N'error' END,
        validation_message = NULLIF(@error, N'')
    WHERE story_code = @story_code;

    IF @return_result = 1
    BEGIN
        SELECT
            story_code,
            validation_status,
            validation_message,
            @passage_count AS passage_count
        FROM stg.DaGo_Researcher_Story_Import
        WHERE story_code = @story_code;
    END;
END;
GO

CREATE OR ALTER PROCEDURE stg.usp_Load_DaGo_Researcher_Story_To_Runtime
    @story_code NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @story_json NVARCHAR(MAX);
    DECLARE @project_code NVARCHAR(50);
    DECLARE @team_code NVARCHAR(50);
    DECLARE @session_code NVARCHAR(50);
    DECLARE @project_id INT;
    DECLARE @team_id INT;
    DECLARE @session_id INT;

    SELECT
        @story_json = story_json,
        @project_code = project_code,
        @team_code = team_code,
        @session_code = session_code
    FROM stg.DaGo_Researcher_Story_Import
    WHERE story_code = @story_code;

    IF @story_json IS NULL
    BEGIN
        THROW 51040, 'DaGo researcher story import row not found.', 1;
    END;

    EXEC stg.usp_Validate_DaGo_Researcher_Story_Import @story_code = @story_code, @return_result = 0;

    IF EXISTS (
        SELECT 1
        FROM stg.DaGo_Researcher_Story_Import
        WHERE story_code = @story_code
          AND validation_status <> N'valid'
    )
    BEGIN
        THROW 51041, 'DaGo researcher story JSON did not pass validation.', 1;
    END;

    SET @project_code = COALESCE(
        NULLIF(@project_code, N''),
        NULLIF(JSON_VALUE(@story_json, N'$.metadata.project_code'), N''),
        NULLIF(JSON_VALUE(@story_json, N'$.config.project_code'), N'')
    );
    SET @team_code = COALESCE(
        NULLIF(@team_code, N''),
        NULLIF(JSON_VALUE(@story_json, N'$.metadata.team_code'), N''),
        NULLIF(JSON_VALUE(@story_json, N'$.config.team_code'), N'')
    );
    SET @session_code = COALESCE(
        NULLIF(@session_code, N''),
        NULLIF(JSON_VALUE(@story_json, N'$.metadata.session_code'), N''),
        NULLIF(JSON_VALUE(@story_json, N'$.config.session_code'), N'')
    );

    SELECT @project_id = project_id
    FROM dbo.Research_Project
    WHERE project_code = @project_code;

    IF @project_id IS NULL
    BEGIN
        THROW 51042, 'project_code does not exist in dbo.Research_Project.', 1;
    END;

    SELECT @team_id = team_id
    FROM dbo.Team
    WHERE project_id = @project_id
      AND team_code = @team_code;

    IF @team_id IS NULL
    BEGIN
        THROW 51043, 'team_code does not exist in dbo.Team for this project.', 1;
    END;

    SELECT @session_id = session_id
    FROM dbo.TRPG_Session
    WHERE team_id = @team_id
      AND session_code = @session_code;

    DECLARE @passages TABLE
    (
        passage_code NVARCHAR(100) NOT NULL PRIMARY KEY,
        title NVARCHAR(200) NOT NULL,
        body_markdown NVARCHAR(MAX) NOT NULL,
        location_name NVARCHAR(200) NULL,
        time_slot NVARCHAR(30) NULL,
        tag_json NVARCHAR(MAX) NULL,
        on_enter_json NVARCHAR(MAX) NULL,
        on_exit_json NVARCHAR(MAX) NULL,
        is_start BIT NOT NULL,
        is_terminal BIT NOT NULL,
        sort_order INT NOT NULL,
        choices_json NVARCHAR(MAX) NULL
    );

    INSERT INTO @passages
    (
        passage_code,
        title,
        body_markdown,
        location_name,
        time_slot,
        tag_json,
        on_enter_json,
        on_exit_json,
        is_start,
        is_terminal,
        sort_order,
        choices_json
    )
    SELECT
        LTRIM(RTRIM(COALESCE(p.passage_code, p.id))),
        LTRIM(RTRIM(p.title)),
        COALESCE(NULLIF(p.body, N''), body_lines.text_body, p.title),
        NULLIF(p.location_name, N''),
        NULLIF(p.time_slot, N''),
        CASE WHEN ISJSON(p.tag_json) = 1 THEN p.tag_json ELSE N'["researcher"]' END,
        CASE WHEN ISJSON(p.on_enter_json) = 1 THEN p.on_enter_json ELSE NULL END,
        CASE WHEN ISJSON(p.on_exit_json) = 1 THEN p.on_exit_json ELSE NULL END,
        COALESCE(p.is_start, 0),
        COALESCE(p.is_terminal, 0),
        COALESCE(p.sort_order, 100),
        CASE WHEN ISJSON(p.choices_json) = 1 THEN p.choices_json ELSE N'[]' END
    FROM OPENJSON(@story_json, N'$.passages')
         WITH (
             id NVARCHAR(100) N'$.id',
             passage_code NVARCHAR(100) N'$.passage_code',
             title NVARCHAR(200) N'$.title',
             body NVARCHAR(MAX) N'$.body',
             text_json NVARCHAR(MAX) N'$.text' AS JSON,
             location_name NVARCHAR(200) N'$.location',
             time_slot NVARCHAR(30) N'$.time_slot',
             tag_json NVARCHAR(MAX) N'$.tags' AS JSON,
             on_enter_json NVARCHAR(MAX) N'$.on_enter' AS JSON,
             on_exit_json NVARCHAR(MAX) N'$.on_exit' AS JSON,
             is_start BIT N'$.is_start',
             is_terminal BIT N'$.is_terminal',
             sort_order INT N'$.sort_order',
             choices_json NVARCHAR(MAX) N'$.choices' AS JSON
         ) AS p
         OUTER APPLY (
             SELECT STRING_AGG(CONVERT(NVARCHAR(MAX), [value]), CHAR(10)) AS text_body
             FROM OPENJSON(p.text_json)
         ) AS body_lines;

    UPDATE gp
    SET gp.project_id = @project_id,
        gp.session_id = @session_id,
        gp.title = p.title,
        gp.body_markdown = p.body_markdown,
        gp.location_name = p.location_name,
        gp.time_slot = p.time_slot,
        gp.tag_json = p.tag_json,
        gp.on_enter_json = p.on_enter_json,
        gp.on_exit_json = p.on_exit_json,
        gp.is_start = p.is_start,
        gp.is_terminal = p.is_terminal,
        gp.is_active = 1,
        gp.sort_order = p.sort_order,
        gp.updated_at = SYSDATETIME()
    FROM dbo.Game_Passage AS gp
         INNER JOIN @passages AS p
             ON p.passage_code = gp.passage_code
    WHERE gp.team_id = @team_id;

    INSERT INTO dbo.Game_Passage
    (
        project_id,
        team_id,
        session_id,
        passage_code,
        title,
        body_markdown,
        location_name,
        time_slot,
        tag_json,
        on_enter_json,
        on_exit_json,
        is_start,
        is_terminal,
        is_active,
        sort_order
    )
    SELECT
        @project_id,
        @team_id,
        @session_id,
        p.passage_code,
        p.title,
        p.body_markdown,
        p.location_name,
        p.time_slot,
        p.tag_json,
        p.on_enter_json,
        p.on_exit_json,
        p.is_start,
        p.is_terminal,
        1,
        p.sort_order
    FROM @passages AS p
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.Game_Passage AS gp
        WHERE gp.team_id = @team_id
          AND gp.passage_code = p.passage_code
    );

    DELETE gc
    FROM dbo.Game_Choice AS gc
         INNER JOIN dbo.Game_Passage AS gp
             ON gp.passage_id = gc.passage_id
         INNER JOIN @passages AS p
             ON p.passage_code = gp.passage_code
    WHERE gp.team_id = @team_id;

    INSERT INTO dbo.Game_Choice
    (
        passage_id,
        choice_code,
        choice_text,
        next_passage_code,
        utterance_function,
        condition_json,
        effect_json,
        skill_check_json,
        visibility_json,
        failure_passage_code,
        weight,
        sort_order,
        is_repeatable,
        is_active
    )
    SELECT
        gp.passage_id,
        COALESCE(NULLIF(c.choice_code, N''), CONCAT(p.passage_code, N'-CHOICE-', c.choice_no)),
        COALESCE(NULLIF(c.choice_text, N''), N'返回'),
        NULLIF(c.next_passage_code, N''),
        CASE
            WHEN c.utterance_function IN (
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
            ) THEN c.utterance_function
            ELSE N'decision'
        END,
        CASE WHEN ISJSON(c.condition_json) = 1 THEN c.condition_json ELSE NULL END,
        CASE WHEN ISJSON(c.effect_json) = 1 THEN c.effect_json ELSE NULL END,
        CASE WHEN ISJSON(c.skill_check_json) = 1 THEN c.skill_check_json ELSE NULL END,
        CASE WHEN ISJSON(c.visibility_json) = 1 THEN c.visibility_json ELSE NULL END,
        NULLIF(c.failure_passage_code, N''),
        COALESCE(c.weight, 1),
        COALESCE(c.sort_order, c.choice_no),
        COALESCE(c.is_repeatable, 1),
        1
    FROM @passages AS p
         INNER JOIN dbo.Game_Passage AS gp
             ON gp.team_id = @team_id
            AND gp.passage_code = p.passage_code
         CROSS APPLY OPENJSON(p.choices_json)
             WITH (
                 choice_no INT N'$.sort_order',
                 id NVARCHAR(100) N'$.id',
                 choice_code NVARCHAR(100) N'$.choice_code',
                 choice_text NVARCHAR(300) N'$.text',
                 next_passage_code NVARCHAR(100) N'$.target',
                 utterance_function NVARCHAR(50) N'$.utterance_function',
                 condition_json NVARCHAR(MAX) N'$.conditions' AS JSON,
                 effect_json NVARCHAR(MAX) N'$.effects' AS JSON,
                 skill_check_json NVARCHAR(MAX) N'$.check' AS JSON,
                 visibility_json NVARCHAR(MAX) N'$.visibility' AS JSON,
                 failure_passage_code NVARCHAR(100) N'$.failure_passage_code',
                 weight INT N'$.weight',
                 sort_order INT N'$.sort_order',
                 is_repeatable BIT N'$.is_repeatable'
             ) AS c;

    UPDATE stg.DaGo_Researcher_Story_Import
    SET import_status = N'loaded',
        loaded_at = SYSDATETIME(),
        project_code = @project_code,
        team_code = @team_code,
        session_code = @session_code
    WHERE story_code = @story_code;

    SELECT
        @story_code AS story_code,
        @project_code AS project_code,
        @team_code AS team_code,
        @session_code AS session_code,
        (SELECT COUNT(*) FROM @passages) AS passage_count,
        (
            SELECT COUNT(*)
            FROM @passages AS p
                 CROSS APPLY OPENJSON(p.choices_json)
        ) AS choice_count,
        N'loaded' AS import_status;
END;
GO
