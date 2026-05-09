USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.Game_Passage', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Game_Passage
    (
        passage_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Game_Passage PRIMARY KEY,

        project_id INT NOT NULL,

        team_id INT NOT NULL,

        session_id INT NULL,

        passage_code NVARCHAR(100) NOT NULL,

        title NVARCHAR(200) NOT NULL,

        body_markdown NVARCHAR(MAX) NOT NULL,

        source_scene_id INT NULL,

        location_setting_id INT NULL,

        location_name NVARCHAR(200) NULL,

        time_slot NVARCHAR(30) NULL,

        tag_json NVARCHAR(MAX) NULL,

        on_enter_json NVARCHAR(MAX) NULL,

        on_exit_json NVARCHAR(MAX) NULL,

        is_start BIT NOT NULL
            CONSTRAINT DF_Game_Passage_is_start
            DEFAULT 0,

        is_terminal BIT NOT NULL
            CONSTRAINT DF_Game_Passage_is_terminal
            DEFAULT 0,

        is_active BIT NOT NULL
            CONSTRAINT DF_Game_Passage_is_active
            DEFAULT 1,

        sort_order INT NOT NULL
            CONSTRAINT DF_Game_Passage_sort_order
            DEFAULT 100,

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Game_Passage_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Game_Passage_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_Game_Passage_Research_Project
            FOREIGN KEY (project_id)
            REFERENCES dbo.Research_Project(project_id),

        CONSTRAINT FK_Game_Passage_Team
            FOREIGN KEY (team_id)
            REFERENCES dbo.Team(team_id),

        CONSTRAINT FK_Game_Passage_TRPG_Session
            FOREIGN KEY (session_id)
            REFERENCES dbo.TRPG_Session(session_id),

        CONSTRAINT FK_Game_Passage_Source_Scene
            FOREIGN KEY (source_scene_id)
            REFERENCES dbo.Scene(scene_id),

        CONSTRAINT FK_Game_Passage_World_Setting
            FOREIGN KEY (location_setting_id)
            REFERENCES dbo.World_Setting(world_setting_id),

        CONSTRAINT UQ_Game_Passage_Team_Code
            UNIQUE (team_id, passage_code),

        CONSTRAINT CK_Game_Passage_Code_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(passage_code))) > 0),

        CONSTRAINT CK_Game_Passage_Title_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(title))) > 0),

        CONSTRAINT CK_Game_Passage_Tag_IsJson
            CHECK (tag_json IS NULL OR ISJSON(tag_json) = 1),

        CONSTRAINT CK_Game_Passage_OnEnter_IsJson
            CHECK (on_enter_json IS NULL OR ISJSON(on_enter_json) = 1),

        CONSTRAINT CK_Game_Passage_OnExit_IsJson
            CHECK (on_exit_json IS NULL OR ISJSON(on_exit_json) = 1)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Game_Passage_Team_Session_Sort' AND object_id = OBJECT_ID(N'dbo.Game_Passage'))
BEGIN
    CREATE INDEX IX_Game_Passage_Team_Session_Sort
        ON dbo.Game_Passage(team_id, session_id, is_active, sort_order, passage_id);
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Game_Passage_SourceScene' AND object_id = OBJECT_ID(N'dbo.Game_Passage'))
BEGIN
    CREATE INDEX IX_Game_Passage_SourceScene
        ON dbo.Game_Passage(source_scene_id)
        WHERE source_scene_id IS NOT NULL;
END;
GO

IF OBJECT_ID(N'dbo.Game_Choice', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Game_Choice
    (
        choice_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Game_Choice PRIMARY KEY,

        passage_id BIGINT NOT NULL,

        choice_code NVARCHAR(100) NOT NULL,

        choice_text NVARCHAR(300) NOT NULL,

        next_passage_code NVARCHAR(100) NULL,

        utterance_function NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Game_Choice_utterance_function
            DEFAULT N'decision',

        condition_json NVARCHAR(MAX) NULL,

        effect_json NVARCHAR(MAX) NULL,

        skill_check_json NVARCHAR(MAX) NULL,

        visibility_json NVARCHAR(MAX) NULL,

        failure_passage_code NVARCHAR(100) NULL,

        weight INT NOT NULL
            CONSTRAINT DF_Game_Choice_weight
            DEFAULT 1,

        sort_order INT NOT NULL
            CONSTRAINT DF_Game_Choice_sort_order
            DEFAULT 100,

        is_repeatable BIT NOT NULL
            CONSTRAINT DF_Game_Choice_is_repeatable
            DEFAULT 1,

        is_active BIT NOT NULL
            CONSTRAINT DF_Game_Choice_is_active
            DEFAULT 1,

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Game_Choice_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Game_Choice_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_Game_Choice_Passage
            FOREIGN KEY (passage_id)
            REFERENCES dbo.Game_Passage(passage_id),

        CONSTRAINT UQ_Game_Choice_Passage_Code
            UNIQUE (passage_id, choice_code),

        CONSTRAINT CK_Game_Choice_Code_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(choice_code))) > 0),

        CONSTRAINT CK_Game_Choice_Text_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(choice_text))) > 0),

        CONSTRAINT CK_Game_Choice_Function
            CHECK (utterance_function IN (
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
            )),

        CONSTRAINT CK_Game_Choice_Condition_IsJson
            CHECK (condition_json IS NULL OR ISJSON(condition_json) = 1),

        CONSTRAINT CK_Game_Choice_Effect_IsJson
            CHECK (effect_json IS NULL OR ISJSON(effect_json) = 1),

        CONSTRAINT CK_Game_Choice_SkillCheck_IsJson
            CHECK (skill_check_json IS NULL OR ISJSON(skill_check_json) = 1),

        CONSTRAINT CK_Game_Choice_Visibility_IsJson
            CHECK (visibility_json IS NULL OR ISJSON(visibility_json) = 1),

        CONSTRAINT CK_Game_Choice_Weight
            CHECK (weight >= 0)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Game_Choice_Passage_Sort' AND object_id = OBJECT_ID(N'dbo.Game_Choice'))
BEGIN
    CREATE INDEX IX_Game_Choice_Passage_Sort
        ON dbo.Game_Choice(passage_id, is_active, sort_order, choice_id);
END;
GO

IF OBJECT_ID(N'dbo.Game_State_Definition', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Game_State_Definition
    (
        state_definition_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Game_State_Definition PRIMARY KEY,

        project_id INT NOT NULL,

        team_id INT NULL,

        state_key NVARCHAR(150) NOT NULL,

        state_group NVARCHAR(50) NOT NULL,

        value_type NVARCHAR(20) NOT NULL,

        default_value_text NVARCHAR(MAX) NULL,

        min_value DECIMAL(18,4) NULL,

        max_value DECIMAL(18,4) NULL,

        ui_label NVARCHAR(100) NULL,

        ui_visible BIT NOT NULL
            CONSTRAINT DF_Game_State_Definition_ui_visible
            DEFAULT 1,

        persist_scope NVARCHAR(20) NOT NULL
            CONSTRAINT DF_Game_State_Definition_persist_scope
            DEFAULT N'save',

        description_note NVARCHAR(MAX) NULL,

        is_active BIT NOT NULL
            CONSTRAINT DF_Game_State_Definition_is_active
            DEFAULT 1,

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Game_State_Definition_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Game_State_Definition_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_Game_State_Definition_Research_Project
            FOREIGN KEY (project_id)
            REFERENCES dbo.Research_Project(project_id),

        CONSTRAINT FK_Game_State_Definition_Team
            FOREIGN KEY (team_id)
            REFERENCES dbo.Team(team_id),

        CONSTRAINT UQ_Game_State_Definition_Key
            UNIQUE (project_id, team_id, state_key),

        CONSTRAINT CK_Game_State_Definition_Key_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(state_key))) > 0),

        CONSTRAINT CK_Game_State_Definition_Type
            CHECK (value_type IN (N'number', N'boolean', N'string', N'json')),

        CONSTRAINT CK_Game_State_Definition_Scope
            CHECK (persist_scope IN (N'save', N'runtime', N'export')),

        CONSTRAINT CK_Game_State_Definition_MinMax
            CHECK (min_value IS NULL OR max_value IS NULL OR min_value <= max_value)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Game_State_Definition_Group' AND object_id = OBJECT_ID(N'dbo.Game_State_Definition'))
BEGIN
    CREATE INDEX IX_Game_State_Definition_Group
        ON dbo.Game_State_Definition(project_id, team_id, state_group, is_active);
END;
GO

IF OBJECT_ID(N'dbo.Game_Relationship_Definition', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Game_Relationship_Definition
    (
        relationship_definition_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Game_Relationship_Definition PRIMARY KEY,

        team_id INT NOT NULL,

        npc_id INT NOT NULL,

        relation_key NVARCHAR(100) NOT NULL,

        default_value DECIMAL(18,4) NOT NULL
            CONSTRAINT DF_Game_Relationship_Definition_default_value
            DEFAULT 0,

        min_value DECIMAL(18,4) NOT NULL
            CONSTRAINT DF_Game_Relationship_Definition_min_value
            DEFAULT -100,

        max_value DECIMAL(18,4) NOT NULL
            CONSTRAINT DF_Game_Relationship_Definition_max_value
            DEFAULT 100,

        ui_label NVARCHAR(100) NULL,

        description_note NVARCHAR(MAX) NULL,

        is_active BIT NOT NULL
            CONSTRAINT DF_Game_Relationship_Definition_is_active
            DEFAULT 1,

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Game_Relationship_Definition_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Game_Relationship_Definition_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_Game_Relationship_Definition_Team
            FOREIGN KEY (team_id)
            REFERENCES dbo.Team(team_id),

        CONSTRAINT FK_Game_Relationship_Definition_NPC
            FOREIGN KEY (npc_id)
            REFERENCES dbo.NPC(npc_id),

        CONSTRAINT UQ_Game_Relationship_Definition_NPC_Key
            UNIQUE (npc_id, relation_key),

        CONSTRAINT CK_Game_Relationship_Definition_Key_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(relation_key))) > 0),

        CONSTRAINT CK_Game_Relationship_Definition_MinMax
            CHECK (min_value <= max_value)
    );
END;
GO

IF OBJECT_ID(N'dbo.Game_Event_Pool', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Game_Event_Pool
    (
        event_pool_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Game_Event_Pool PRIMARY KEY,

        project_id INT NOT NULL,

        team_id INT NOT NULL,

        session_id INT NULL,

        event_pool_code NVARCHAR(100) NOT NULL,

        pool_name NVARCHAR(200) NOT NULL,

        trigger_type NVARCHAR(50) NOT NULL,

        location_scope NVARCHAR(200) NULL,

        event_code NVARCHAR(100) NOT NULL,

        event_name NVARCHAR(200) NOT NULL,

        passage_code NVARCHAR(100) NULL,

        event_text NVARCHAR(MAX) NULL,

        condition_json NVARCHAR(MAX) NULL,

        effect_json NVARCHAR(MAX) NULL,

        weight INT NOT NULL
            CONSTRAINT DF_Game_Event_Pool_weight
            DEFAULT 1,

        cooldown_turns INT NOT NULL
            CONSTRAINT DF_Game_Event_Pool_cooldown_turns
            DEFAULT 0,

        max_triggers_per_day INT NOT NULL
            CONSTRAINT DF_Game_Event_Pool_max_triggers_per_day
            DEFAULT 1,

        is_active BIT NOT NULL
            CONSTRAINT DF_Game_Event_Pool_is_active
            DEFAULT 1,

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Game_Event_Pool_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Game_Event_Pool_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_Game_Event_Pool_Research_Project
            FOREIGN KEY (project_id)
            REFERENCES dbo.Research_Project(project_id),

        CONSTRAINT FK_Game_Event_Pool_Team
            FOREIGN KEY (team_id)
            REFERENCES dbo.Team(team_id),

        CONSTRAINT FK_Game_Event_Pool_TRPG_Session
            FOREIGN KEY (session_id)
            REFERENCES dbo.TRPG_Session(session_id),

        CONSTRAINT UQ_Game_Event_Pool_Entry
            UNIQUE (team_id, event_pool_code, event_code),

        CONSTRAINT CK_Game_Event_Pool_Code_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(event_pool_code))) > 0),

        CONSTRAINT CK_Game_Event_Pool_Event_Code_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(event_code))) > 0),

        CONSTRAINT CK_Game_Event_Pool_Trigger
            CHECK (trigger_type IN (
                N'after_choice',
                N'on_enter',
                N'on_rest',
                N'on_travel',
                N'hourly',
                N'daily'
            )),

        CONSTRAINT CK_Game_Event_Pool_Condition_IsJson
            CHECK (condition_json IS NULL OR ISJSON(condition_json) = 1),

        CONSTRAINT CK_Game_Event_Pool_Effect_IsJson
            CHECK (effect_json IS NULL OR ISJSON(effect_json) = 1),

        CONSTRAINT CK_Game_Event_Pool_Weight
            CHECK (weight >= 0),

        CONSTRAINT CK_Game_Event_Pool_Cooldown
            CHECK (cooldown_turns >= 0),

        CONSTRAINT CK_Game_Event_Pool_Max_Per_Day
            CHECK (max_triggers_per_day >= 0)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Game_Event_Pool_Trigger' AND object_id = OBJECT_ID(N'dbo.Game_Event_Pool'))
BEGIN
    CREATE INDEX IX_Game_Event_Pool_Trigger
        ON dbo.Game_Event_Pool(team_id, session_id, trigger_type, is_active, event_pool_code);
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Export_DaGo_Runtime_Bundle
    @project_code NVARCHAR(50),
    @team_code NVARCHAR(50),
    @session_code NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @project_id INT;
    DECLARE @team_id INT;
    DECLARE @session_id INT;
    DECLARE @resolved_session_code NVARCHAR(50);
    DECLARE @gm_code NVARCHAR(50);
    DECLARE @researcher_code NVARCHAR(50);
    DECLARE @states_json NVARCHAR(MAX);
    DECLARE @passages_json NVARCHAR(MAX);
    DECLARE @event_pools_json NVARCHAR(MAX);
    DECLARE @relationships_json NVARCHAR(MAX);
    DECLARE @start_passage NVARCHAR(100);
    DECLARE @start_location NVARCHAR(200);

    SELECT @project_id = project_id
    FROM dbo.Research_Project
    WHERE project_code = @project_code;

    IF @project_id IS NULL
    BEGIN
        THROW 51000, 'project_code not found.', 1;
    END;

    SELECT @team_id = team_id
    FROM dbo.Team
    WHERE project_id = @project_id
      AND team_code = @team_code;

    IF @team_id IS NULL
    BEGIN
        THROW 51001, 'team_code not found in project.', 1;
    END;

    IF @session_code IS NULL
    BEGIN
        SELECT TOP (1)
            @session_id = session_id,
            @resolved_session_code = session_code
        FROM dbo.TRPG_Session
        WHERE team_id = @team_id
        ORDER BY session_no DESC, session_id DESC;
    END
    ELSE
    BEGIN
        SELECT
            @session_id = session_id,
            @resolved_session_code = session_code
        FROM dbo.TRPG_Session
        WHERE team_id = @team_id
          AND session_code = @session_code;
    END;

    IF @session_id IS NULL
    BEGIN
        THROW 51002, 'session_code not found in team.', 1;
    END;

    SELECT TOP (1) @gm_code = tm.member_code
    FROM dbo.TRPG_Session AS s
    INNER JOIN dbo.Team_Member AS tm
        ON tm.team_member_id = s.gm_member_id
    WHERE s.session_id = @session_id;

    SELECT TOP (1) @researcher_code = tm.member_code
    FROM dbo.Team_Member AS tm
    WHERE tm.team_id = @team_id
      AND tm.member_role IN (N'researcher', N'recorder', N'observer')
    ORDER BY
        CASE tm.member_role
            WHEN N'researcher' THEN 1
            WHEN N'recorder' THEN 2
            ELSE 3
        END,
        tm.team_member_id;

    SELECT @states_json = (
        SELECT
            s.state_key AS [key],
            s.state_group AS [group],
            s.value_type AS [type],
            s.default_value_text AS [default],
            s.min_value AS [min],
            s.max_value AS [max],
            s.ui_label AS [label],
            s.ui_visible,
            s.persist_scope,
            s.description_note
        FROM (
            SELECT
                gsd.state_key,
                gsd.state_group,
                gsd.value_type,
                gsd.default_value_text,
                gsd.min_value,
                gsd.max_value,
                gsd.ui_label,
                gsd.ui_visible,
                gsd.persist_scope,
                gsd.description_note,
                10 AS sort_group
            FROM dbo.Game_State_Definition AS gsd
            WHERE gsd.project_id = @project_id
              AND (gsd.team_id IS NULL OR gsd.team_id = @team_id)
              AND gsd.is_active = 1

            UNION ALL

            SELECT *
            FROM (VALUES
                (N'stats.spirit', N'stats', N'number', N'50', CONVERT(DECIMAL(18,4), 0), CONVERT(DECIMAL(18,4), 100), N'精神', CONVERT(BIT, 1), N'save', N'角色的精神消耗與恢復。', 99),
                (N'stats.composure', N'stats', N'number', N'50', CONVERT(DECIMAL(18,4), 0), CONVERT(DECIMAL(18,4), 100), N'鎮定', CONVERT(BIT, 1), N'save', N'角色的鎮定程度。', 99),
                (N'stats.suspicion', N'stats', N'number', N'0', CONVERT(DECIMAL(18,4), 0), CONVERT(DECIMAL(18,4), 100), N'疑心', CONVERT(BIT, 1), N'save', N'場景中被注意或引起疑慮的程度。', 99),
                (N'stats.fatigue', N'stats', N'number', N'0', CONVERT(DECIMAL(18,4), 0), CONVERT(DECIMAL(18,4), 100), N'疲勞', CONVERT(BIT, 1), N'save', N'長時間行動造成的累積負擔。', 99),
                (N'stats.hunger', N'stats', N'number', N'0', CONVERT(DECIMAL(18,4), 0), CONVERT(DECIMAL(18,4), 100), N'飢餓', CONVERT(BIT, 1), N'save', N'用於日常循環的消耗指標。', 99),
                (N'stats.coin', N'stats', N'number', N'12', CONVERT(DECIMAL(18,4), -99), CONVERT(DECIMAL(18,4), 999), N'錢', CONVERT(BIT, 1), N'save', N'可被交易與補給消耗的資源。', 99),
                (N'skills.inquiry', N'skills', N'number', N'1', CONVERT(DECIMAL(18,4), 0), CONVERT(DECIMAL(18,4), 9), N'探問', CONVERT(BIT, 1), N'save', N'詢問、打聽與推進資訊。', 99),
                (N'skills.archive', N'skills', N'number', N'1', CONVERT(DECIMAL(18,4), 0), CONVERT(DECIMAL(18,4), 9), N'案卷', CONVERT(BIT, 1), N'save', N'閱讀、比對與整理文件。', 99),
                (N'skills.influence', N'skills', N'number', N'1', CONVERT(DECIMAL(18,4), 0), CONVERT(DECIMAL(18,4), 9), N'交涉', CONVERT(BIT, 1), N'save', N'說服、斡旋與談判。', 99),
                (N'skills.travel', N'skills', N'number', N'1', CONVERT(DECIMAL(18,4), 0), CONVERT(DECIMAL(18,4), 9), N'行路', CONVERT(BIT, 1), N'save', N'移動、追蹤與跨地點行動。', 99)
            ) AS defaults
            (
                state_key,
                state_group,
                value_type,
                default_value_text,
                min_value,
                max_value,
                ui_label,
                ui_visible,
                persist_scope,
                description_note,
                sort_group
            )
            WHERE NOT EXISTS (
                SELECT 1
                FROM dbo.Game_State_Definition AS existing
                WHERE existing.project_id = @project_id
                  AND (existing.team_id IS NULL OR existing.team_id = @team_id)
                  AND existing.is_active = 1
            )
        ) AS s
        ORDER BY s.sort_group, s.state_group, s.state_key
        FOR JSON PATH
    );

    IF EXISTS (
        SELECT 1
        FROM dbo.Game_Passage
        WHERE project_id = @project_id
          AND team_id = @team_id
          AND (session_id IS NULL OR session_id = @session_id)
          AND is_active = 1
    )
    BEGIN
        SELECT @start_passage = gp.passage_code,
               @start_location = gp.location_name
        FROM dbo.Game_Passage AS gp
        WHERE gp.project_id = @project_id
          AND gp.team_id = @team_id
          AND (gp.session_id IS NULL OR gp.session_id = @session_id)
          AND gp.is_active = 1
        ORDER BY gp.is_start DESC, gp.sort_order, gp.passage_id;

        SELECT @passages_json = (
            SELECT
                gp.passage_code AS id,
                gp.passage_code,
                gp.title,
                gp.location_name AS [location],
                gp.time_slot,
                gp.body_markdown AS body,
                JSON_QUERY(gp.tag_json) AS tags,
                JSON_QUERY(gp.on_enter_json) AS on_enter,
                JSON_QUERY(gp.on_exit_json) AS on_exit,
                gp.is_start,
                gp.is_terminal,
                gp.sort_order,
                JSON_QUERY((
                    SELECT
                        gc.choice_code AS id,
                        gc.choice_text AS [text],
                        gc.next_passage_code AS [target],
                        gc.utterance_function,
                        JSON_QUERY(gc.condition_json) AS conditions,
                        JSON_QUERY(gc.effect_json) AS effects,
                        JSON_QUERY(gc.skill_check_json) AS [check],
                        JSON_QUERY(gc.visibility_json) AS visibility,
                        gc.failure_passage_code,
                        gc.weight,
                        gc.sort_order,
                        gc.is_repeatable
                    FROM dbo.Game_Choice AS gc
                    WHERE gc.passage_id = gp.passage_id
                      AND gc.is_active = 1
                    ORDER BY gc.sort_order, gc.choice_id
                    FOR JSON PATH
                )) AS choices
            FROM dbo.Game_Passage AS gp
            WHERE gp.project_id = @project_id
              AND gp.team_id = @team_id
              AND (gp.session_id IS NULL OR gp.session_id = @session_id)
              AND gp.is_active = 1
            ORDER BY gp.sort_order, gp.passage_id
            FOR JSON PATH
        );
    END
    ELSE
    BEGIN
        SELECT TOP (1)
            @start_passage = sc.scene_code,
            @start_location = sc.location_name
        FROM dbo.Scene AS sc
        WHERE sc.session_id = @session_id
          AND sc.include_in_analysis = 1
          AND sc.scene_status <> N'excluded'
        ORDER BY sc.scene_no;

        SELECT @passages_json = (
            SELECT
                sc.scene_code AS id,
                sc.scene_code AS passage_code,
                COALESCE(sc.scene_title, sc.scene_code) AS title,
                sc.location_name AS [location],
                CONCAT(N'第 ', sc.scene_no, N' 場') AS time_slot,
                COALESCE(
                    sc.scene_summary_clean,
                    sc.scene_summary_verified,
                    sc.scene_summary_raw,
                    sc.scene_goal,
                    sc.scene_code
                ) AS body,
                JSON_QUERY(N'["corpus","scene"]') AS tags,
                JSON_QUERY(N'[]') AS on_enter,
                JSON_QUERY(N'[]') AS on_exit,
                CONVERT(BIT, CASE WHEN sc.scene_no = MIN(sc.scene_no) OVER () THEN 1 ELSE 0 END) AS is_start,
                CONVERT(BIT, 0) AS is_terminal,
                sc.scene_no AS sort_order,
                JSON_QUERY((
                    SELECT
                        CONCAT(N'goto_', COALESCE(next_scene.scene_code, sc.scene_code)) AS id,
                        N'前往下一段資料' AS [text],
                        COALESCE(next_scene.scene_code, sc.scene_code) AS [target],
                        N'decision' AS utterance_function,
                        JSON_QUERY(N'[]') AS conditions,
                        JSON_QUERY(N'[{"op":"add","path":"dev.traceability","value":1}]') AS effects,
                        CONVERT(INT, 1) AS weight,
                        CONVERT(INT, 100) AS sort_order,
                        CONVERT(BIT, 1) AS is_repeatable
                    FOR JSON PATH
                )) AS choices
            FROM dbo.Scene AS sc
            OUTER APPLY (
                SELECT TOP (1) sc_next.scene_code
                FROM dbo.Scene AS sc_next
                WHERE sc_next.session_id = sc.session_id
                  AND sc_next.include_in_analysis = 1
                  AND sc_next.scene_status <> N'excluded'
                  AND sc_next.scene_no > sc.scene_no
                ORDER BY sc_next.scene_no
            ) AS next_scene
            WHERE sc.session_id = @session_id
              AND sc.include_in_analysis = 1
              AND sc.scene_status <> N'excluded'
            ORDER BY sc.scene_no
            FOR JSON PATH
        );
    END;

    IF EXISTS (
        SELECT 1
        FROM dbo.Game_Event_Pool
        WHERE project_id = @project_id
          AND team_id = @team_id
          AND (session_id IS NULL OR session_id = @session_id)
          AND is_active = 1
    )
    BEGIN
        SELECT @event_pools_json = (
            SELECT
                pool.event_pool_code AS id,
                pool.pool_name AS [name],
                pool.trigger_type AS [trigger],
                pool.location_scope,
                JSON_QUERY((
                    SELECT
                        ep.event_code AS event_id,
                        ep.event_name AS title,
                        ep.passage_code AS passage_id,
                        ep.event_text AS [text],
                        JSON_QUERY(ep.condition_json) AS conditions,
                        JSON_QUERY(ep.effect_json) AS effects,
                        ep.weight,
                        ep.cooldown_turns,
                        ep.max_triggers_per_day
                    FROM dbo.Game_Event_Pool AS ep
                    WHERE ep.project_id = @project_id
                      AND ep.team_id = @team_id
                      AND (ep.session_id IS NULL OR ep.session_id = @session_id)
                      AND ep.is_active = 1
                      AND ep.event_pool_code = pool.event_pool_code
                    ORDER BY ep.weight DESC, ep.event_code
                    FOR JSON PATH
                )) AS entries
            FROM (
                SELECT DISTINCT
                    event_pool_code,
                    pool_name,
                    trigger_type,
                    location_scope
                FROM dbo.Game_Event_Pool
                WHERE project_id = @project_id
                  AND team_id = @team_id
                  AND (session_id IS NULL OR session_id = @session_id)
                  AND is_active = 1
            ) AS pool
            ORDER BY pool.event_pool_code
            FOR JSON PATH
        );
    END
    ELSE
    BEGIN
        SELECT @event_pools_json = (
            SELECT
                N'corpus_plot_events' AS id,
                N'語料劇情事件' AS [name],
                N'after_choice' AS [trigger],
                NULL AS location_scope,
                JSON_QUERY((
                    SELECT TOP (24)
                        pe.event_code AS event_id,
                        pe.event_title AS title,
                        sc.scene_code AS passage_id,
                        COALESCE(pe.event_summary, pe.consequence_summary, pe.event_title) AS [text],
                        JSON_QUERY(N'[]') AS conditions,
                        JSON_QUERY(N'[{"op":"add","path":"dev.smm","value":1},{"op":"add","path":"dev.tms","value":1},{"op":"add","path":"dev.traceability","value":2}]') AS effects,
                        CASE pe.event_importance
                            WHEN N'critical' THEN 5
                            WHEN N'high' THEN 4
                            WHEN N'medium' THEN 2
                            ELSE 1
                        END AS weight,
                        CONVERT(INT, 3) AS cooldown_turns,
                        CONVERT(INT, 1) AS max_triggers_per_day
                    FROM dbo.Plot_Event AS pe
                    LEFT JOIN dbo.Scene AS sc
                        ON sc.scene_id = pe.scene_id
                    WHERE pe.session_id = @session_id
                      AND pe.include_in_analysis = 1
                      AND pe.review_status <> N'excluded'
                    ORDER BY pe.event_no
                    FOR JSON PATH
                )) AS entries
            WHERE EXISTS (
                SELECT 1
                FROM dbo.Plot_Event AS pe
                WHERE pe.session_id = @session_id
                  AND pe.include_in_analysis = 1
                  AND pe.review_status <> N'excluded'
            )
            FOR JSON PATH
        );
    END;

    SELECT @relationships_json = (
        SELECT
            npc.npc_code,
            npc.npc_name,
            npc.npc_type,
            npc.faction,
            npc.location_name,
            JSON_QUERY((
                SELECT
                    metric.relation_key AS [key],
                    metric.default_value AS [default],
                    metric.min_value AS [min],
                    metric.max_value AS [max],
                    metric.ui_label AS [label],
                    metric.description_note
                FROM (
                    SELECT
                        grd.relation_key,
                        grd.default_value,
                        grd.min_value,
                        grd.max_value,
                        grd.ui_label,
                        grd.description_note,
                        10 AS sort_order
                    FROM dbo.Game_Relationship_Definition AS grd
                    WHERE grd.team_id = @team_id
                      AND grd.npc_id = npc.npc_id
                      AND grd.is_active = 1

                    UNION ALL

                    SELECT *
                    FROM (VALUES
                        (N'trust', CONVERT(DECIMAL(18,4), 0), CONVERT(DECIMAL(18,4), -100), CONVERT(DECIMAL(18,4), 100), N'信任', N'角色是否願意提供資訊。', 99),
                        (N'favor', CONVERT(DECIMAL(18,4), 0), CONVERT(DECIMAL(18,4), -100), CONVERT(DECIMAL(18,4), 100), N'好感', N'互動後的偏好變化。', 99),
                        (N'fear', CONVERT(DECIMAL(18,4), 0), CONVERT(DECIMAL(18,4), -100), CONVERT(DECIMAL(18,4), 100), N'畏懼', N'壓迫或衝突造成的心理距離。', 99)
                    ) AS defaults
                    (
                        relation_key,
                        default_value,
                        min_value,
                        max_value,
                        ui_label,
                        description_note,
                        sort_order
                    )
                    WHERE NOT EXISTS (
                        SELECT 1
                        FROM dbo.Game_Relationship_Definition AS existing
                        WHERE existing.team_id = @team_id
                          AND existing.npc_id = npc.npc_id
                          AND existing.is_active = 1
                    )
                ) AS metric
                ORDER BY metric.sort_order, metric.relation_key
                FOR JSON PATH
            )) AS metrics
        FROM dbo.NPC AS npc
        WHERE npc.team_id = @team_id
          AND npc.npc_status <> N'excluded'
        ORDER BY npc.npc_code
        FOR JSON PATH
    );

    IF NULLIF(@passages_json, N'[]') IS NULL
    BEGIN
        SET @start_passage = N'Gate';
        SET @start_location = N'南京';
    END;

    SELECT
        N'da_go_runtime_bundle_v1' AS bundle_format,
        JSON_QUERY((
            SELECT
                N'trpg-corpus-sqlserver' AS source,
                SYSDATETIMEOFFSET() AS exported_at,
                DB_NAME() AS database_name,
                @project_code AS project_code,
                @team_code AS team_code,
                @resolved_session_code AS session_code,
                N'da_go>=1.0.0' AS engine_target
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )) AS metadata,
        JSON_QUERY((
            SELECT
                DB_NAME() AS database_name,
                @project_code AS project_code,
                @team_code AS team_code,
                @resolved_session_code AS session_code,
                CONCAT(N'DAGO_', @team_code, N'_', @resolved_session_code) AS import_batch_code,
                COALESCE(@gm_code, N'TM-GM') AS gm_code,
                COALESCE(@researcher_code, N'TM-RESEARCHER') AS researcher_code
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )) AS config,
        JSON_QUERY((
            SELECT
                COALESCE(@start_passage, N'Gate') AS start_passage,
                CONVERT(INT, 1) AS [day],
                CONVERT(INT, 6) AS [hour],
                COALESCE(@start_location, N'南京') AS [location]
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )) AS world_state,
        JSON_QUERY(COALESCE(@states_json, N'[]')) AS states,
        JSON_QUERY(COALESCE(@passages_json, N'[]')) AS passages,
        JSON_QUERY(COALESCE(@event_pools_json, N'[]')) AS event_pools,
        JSON_QUERY(COALESCE(@relationships_json, N'[]')) AS relationship_defs,
        JSON_QUERY((
            SELECT
                npc.npc_code,
                npc.npc_name,
                npc.npc_type,
                npc.faction,
                npc.location_name,
                npc.role_in_story,
                npc.personality_note,
                npc.motivation_note,
                npc.relationship_note,
                npc.knowledge_note,
                npc.npc_description_clean,
                npc.is_recurring,
                npc.is_hostile,
                npc.is_alive
            FROM dbo.NPC AS npc
            WHERE npc.team_id = @team_id
              AND npc.npc_status <> N'excluded'
            ORDER BY npc.npc_code
            FOR JSON PATH
        )) AS npcs,
        JSON_QUERY((
            SELECT
                i.item_code,
                i.item_name,
                i.item_category,
                i.item_subcategory,
                i.item_summary,
                i.item_description_clean,
                i.mechanical_effect,
                i.related_rule_code,
                i.is_clue,
                i.is_consumable,
                i.is_unique,
                i.quantity
            FROM dbo.Item AS i
            WHERE i.team_id = @team_id
              AND i.item_status <> N'excluded'
            ORDER BY i.item_category, i.item_code
            FOR JSON PATH
        )) AS items,
        JSON_QUERY((
            SELECT
                gr.rule_code,
                gr.rule_name,
                gr.rule_category,
                gr.rule_summary,
                gr.rule_condition,
                gr.rule_effect,
                gr.dice_formula,
                gr.difficulty_rule,
                gr.success_effect,
                gr.failure_effect,
                gr.is_house_rule
            FROM dbo.Game_Rule AS gr
            WHERE gr.project_id = @project_id
              AND gr.is_active = 1
              AND gr.rule_status <> N'excluded'
            ORDER BY gr.rule_category, gr.rule_code
            FOR JSON PATH
        )) AS rules
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
END;
GO
