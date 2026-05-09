USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/*
    DaGo 劇本 authoring schema
    用途：讓研究者以 SQL Server Management Studio 22 建立可同時匯入 da_go 與 trpg-corpus-sqlserver 的劇本包。
    執行前請先備份 TRPG_Corpus_DB。
*/

IF OBJECT_ID(N'dbo.DaGo_Authoring_Scenario', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DaGo_Authoring_Scenario
    (
        scenario_code NVARCHAR(80) NOT NULL
            CONSTRAINT PK_DaGo_Authoring_Scenario PRIMARY KEY,
        scenario_name NVARCHAR(200) NOT NULL,
        scenario_subtitle NVARCHAR(200) NULL,
        scenario_summary NVARCHAR(MAX) NOT NULL,
        time_span_note NVARCHAR(300) NOT NULL,
        player_area NVARCHAR(100) NOT NULL
            CONSTRAINT DF_DaGo_Authoring_Scenario_player_area DEFAULT N'南京',
        play_feature_json NVARCHAR(MAX) NOT NULL,
        worldview_json NVARCHAR(MAX) NOT NULL,
        runtime_bundle_path NVARCHAR(500) NULL,
        is_active BIT NOT NULL
            CONSTRAINT DF_DaGo_Authoring_Scenario_is_active DEFAULT 1,
        sort_order INT NOT NULL
            CONSTRAINT DF_DaGo_Authoring_Scenario_sort_order DEFAULT 100,
        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_DaGo_Authoring_Scenario_created_at DEFAULT SYSDATETIME(),
        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_DaGo_Authoring_Scenario_updated_at DEFAULT SYSDATETIME(),
        CONSTRAINT CK_DaGo_Authoring_Scenario_Feature_JSON CHECK (ISJSON(play_feature_json) = 1),
        CONSTRAINT CK_DaGo_Authoring_Scenario_World_JSON CHECK (ISJSON(worldview_json) = 1)
    );
END;
GO

IF OBJECT_ID(N'dbo.DaGo_Authoring_Scenario_Location', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DaGo_Authoring_Scenario_Location
    (
        scenario_code NVARCHAR(80) NOT NULL,
        location_code NVARCHAR(80) NOT NULL,
        location_name NVARCHAR(200) NOT NULL,
        district_name NVARCHAR(100) NOT NULL,
        location_type NVARCHAR(80) NOT NULL,
        allowed_for_player BIT NOT NULL
            CONSTRAINT DF_DaGo_Authoring_Scenario_Location_allowed DEFAULT 1,
        story_note NVARCHAR(MAX) NULL,
        sort_order INT NOT NULL
            CONSTRAINT DF_DaGo_Authoring_Scenario_Location_sort_order DEFAULT 100,
        CONSTRAINT PK_DaGo_Authoring_Scenario_Location PRIMARY KEY (scenario_code, location_code),
        CONSTRAINT FK_DaGo_Authoring_Scenario_Location_Scenario FOREIGN KEY (scenario_code)
            REFERENCES dbo.DaGo_Authoring_Scenario(scenario_code)
    );
END;
GO

IF OBJECT_ID(N'dbo.DaGo_Authoring_Scenario_NPC', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DaGo_Authoring_Scenario_NPC
    (
        scenario_code NVARCHAR(80) NOT NULL,
        npc_code NVARCHAR(80) NOT NULL,
        npc_name NVARCHAR(200) NOT NULL,
        npc_role NVARCHAR(200) NOT NULL,
        default_location_code NVARCHAR(80) NULL,
        relation_start INT NOT NULL
            CONSTRAINT DF_DaGo_Authoring_Scenario_NPC_relation DEFAULT 0,
        tag_json NVARCHAR(MAX) NOT NULL
            CONSTRAINT DF_DaGo_Authoring_Scenario_NPC_tag DEFAULT N'[]',
        gm_note NVARCHAR(MAX) NULL,
        sort_order INT NOT NULL
            CONSTRAINT DF_DaGo_Authoring_Scenario_NPC_sort_order DEFAULT 100,
        CONSTRAINT PK_DaGo_Authoring_Scenario_NPC PRIMARY KEY (scenario_code, npc_code),
        CONSTRAINT FK_DaGo_Authoring_Scenario_NPC_Scenario FOREIGN KEY (scenario_code)
            REFERENCES dbo.DaGo_Authoring_Scenario(scenario_code),
        CONSTRAINT CK_DaGo_Authoring_Scenario_NPC_Tag_JSON CHECK (ISJSON(tag_json) = 1)
    );
END;
GO

IF OBJECT_ID(N'dbo.DaGo_Authoring_Scenario_Quest', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DaGo_Authoring_Scenario_Quest
    (
        scenario_code NVARCHAR(80) NOT NULL,
        quest_code NVARCHAR(80) NOT NULL,
        quest_title NVARCHAR(200) NOT NULL,
        quest_goal NVARCHAR(MAX) NOT NULL,
        quest_step_json NVARCHAR(MAX) NOT NULL,
        sort_order INT NOT NULL
            CONSTRAINT DF_DaGo_Authoring_Scenario_Quest_sort_order DEFAULT 100,
        CONSTRAINT PK_DaGo_Authoring_Scenario_Quest PRIMARY KEY (scenario_code, quest_code),
        CONSTRAINT FK_DaGo_Authoring_Scenario_Quest_Scenario FOREIGN KEY (scenario_code)
            REFERENCES dbo.DaGo_Authoring_Scenario(scenario_code),
        CONSTRAINT CK_DaGo_Authoring_Scenario_Quest_JSON CHECK (ISJSON(quest_step_json) = 1)
    );
END;
GO

MERGE dbo.DaGo_Authoring_Scenario AS tgt
USING (VALUES
    (
        N'xiaocheng_jiushi',
        N'小城舊事',
        N'大興二十年南京篇',
        N'雨後的南京外城，驛舍、茶棚、南市帳房與官署門廊同時浮出異樣。南陽帳目、銀川急信與崑崙遠訊彼此交錯，玩家只能在南京城內追索舊事的痕跡。',
        N'大興二十年九月九日起；玩家活動限定南京。',
        N'南京',
        N'["南京限定探索","市井傳聞與官署線索交錯","帳目、急信、門派消息三線並進","4D3 技能檢定與失敗回饋","可輸出 TRPG Corpus playlog JSON"]',
        N'{"title":"大國年代記","political_context":"大興二十年，南京表面平穩，商會帳目、驛路急信與門派傳聞正在城內暗流相接。","themes":["舊事","帳目","信路","門閥","江湖遠訊"]}',
        N'assets/data/scenarios/xiaocheng-jiushi.json',
        10
    )
) AS src(scenario_code, scenario_name, scenario_subtitle, scenario_summary, time_span_note, player_area, play_feature_json, worldview_json, runtime_bundle_path, sort_order)
ON tgt.scenario_code = src.scenario_code
WHEN MATCHED THEN UPDATE SET
    scenario_name = src.scenario_name,
    scenario_subtitle = src.scenario_subtitle,
    scenario_summary = src.scenario_summary,
    time_span_note = src.time_span_note,
    player_area = src.player_area,
    play_feature_json = src.play_feature_json,
    worldview_json = src.worldview_json,
    runtime_bundle_path = src.runtime_bundle_path,
    sort_order = src.sort_order,
    is_active = 1,
    updated_at = SYSDATETIME()
WHEN NOT MATCHED THEN INSERT
    (scenario_code, scenario_name, scenario_subtitle, scenario_summary, time_span_note, player_area, play_feature_json, worldview_json, runtime_bundle_path, sort_order)
    VALUES
    (src.scenario_code, src.scenario_name, src.scenario_subtitle, src.scenario_summary, src.time_span_note, src.player_area, src.play_feature_json, src.worldview_json, src.runtime_bundle_path, src.sort_order);
GO

MERGE dbo.DaGo_Authoring_Scenario_Location AS tgt
USING (VALUES
    (N'xiaocheng_jiushi', N'Gate', N'南京外城', N'外郭', N'city_gate', 1, 10),
    (N'xiaocheng_jiushi', N'Tea', N'城門茶棚', N'外郭', N'rumour_hub', 1, 20),
    (N'xiaocheng_jiushi', N'Relay', N'南京驛舍', N'外城', N'office_route', 1, 30),
    (N'xiaocheng_jiushi', N'River', N'秦淮河埠', N'外城', N'harbour', 1, 40),
    (N'xiaocheng_jiushi', N'Ledger', N'南市帳房', N'內城', N'market_archive', 1, 50),
    (N'xiaocheng_jiushi', N'Kunlun', N'西街書肆', N'內城', N'bookshop', 1, 60),
    (N'xiaocheng_jiushi', N'Yamen', N'官署門廊', N'皇城外署', N'government', 1, 70)
) AS src(scenario_code, location_code, location_name, district_name, location_type, allowed_for_player, sort_order)
ON tgt.scenario_code = src.scenario_code AND tgt.location_code = src.location_code
WHEN MATCHED THEN UPDATE SET location_name = src.location_name, district_name = src.district_name, location_type = src.location_type, allowed_for_player = src.allowed_for_player, sort_order = src.sort_order
WHEN NOT MATCHED THEN INSERT (scenario_code, location_code, location_name, district_name, location_type, allowed_for_player, sort_order)
VALUES (src.scenario_code, src.location_code, src.location_name, src.district_name, src.location_type, src.allowed_for_player, src.sort_order);
GO

MERGE dbo.DaGo_Authoring_Scenario_NPC AS tgt
USING (VALUES
    (N'xiaocheng_jiushi', N'npc_tea_master', N'茶博士', N'市井情報節點', N'Tea', N'["情報","市井"]', 10),
    (N'xiaocheng_jiushi', N'npc_post_runner', N'驛卒', N'北路官信節點', N'Relay', N'["北路","官信"]', 20),
    (N'xiaocheng_jiushi', N'npc_old_scribe', N'老書吏', N'官署與魏氏線索節點', N'Yamen', N'["官署","魏氏"]', 30),
    (N'xiaocheng_jiushi', N'npc_boatman', N'船主', N'江夏糧船線索節點', N'River', N'["江夏","糧船"]', 40),
    (N'xiaocheng_jiushi', N'npc_accountant', N'帳房先生', N'南陽帳目線索節點', N'Ledger', N'["南陽","商會"]', 50)
) AS src(scenario_code, npc_code, npc_name, npc_role, default_location_code, tag_json, sort_order)
ON tgt.scenario_code = src.scenario_code AND tgt.npc_code = src.npc_code
WHEN MATCHED THEN UPDATE SET npc_name = src.npc_name, npc_role = src.npc_role, default_location_code = src.default_location_code, tag_json = src.tag_json, sort_order = src.sort_order
WHEN NOT MATCHED THEN INSERT (scenario_code, npc_code, npc_name, npc_role, default_location_code, tag_json, sort_order)
VALUES (src.scenario_code, src.npc_code, src.npc_name, src.npc_role, src.default_location_code, src.tag_json, src.sort_order);
GO

MERGE dbo.DaGo_Authoring_Scenario_Quest AS tgt
USING (VALUES
    (N'xiaocheng_jiushi', N'quest_south_ledger', N'南陽銀痕', N'追查南合商會戳記、南陽帳目疑點與劉廷平舊名。', N'["取得南合商會戳記","取得南陽帳目疑點","問出劉廷平舊名"]', 10),
    (N'xiaocheng_jiushi', N'quest_north_letter', N'銀川急信', N'取得銀川急信線索、北路送信圖，並請馬客帶信。', N'["取得銀川急信線索","取得北路送信圖","請馬客帶信"]', 20),
    (N'xiaocheng_jiushi', N'quest_kunlun_rumour', N'崑崙遠訊', N'確認崑崙受襲傳聞、取得書肆信物，追查下山者去向。', N'["取得崑崙受襲傳聞","取得崑崙書肆信物","查下山者去向"]', 30)
) AS src(scenario_code, quest_code, quest_title, quest_goal, quest_step_json, sort_order)
ON tgt.scenario_code = src.scenario_code AND tgt.quest_code = src.quest_code
WHEN MATCHED THEN UPDATE SET quest_title = src.quest_title, quest_goal = src.quest_goal, quest_step_json = src.quest_step_json, sort_order = src.sort_order
WHEN NOT MATCHED THEN INSERT (scenario_code, quest_code, quest_title, quest_goal, quest_step_json, sort_order)
VALUES (src.scenario_code, src.quest_code, src.quest_title, src.quest_goal, src.quest_step_json, src.sort_order);
GO

CREATE OR ALTER VIEW dbo.vw_DaGo_Scenario_Bundle_Export
AS
SELECT
    s.scenario_code,
    s.scenario_name,
    s.scenario_subtitle,
    s.scenario_summary,
    s.time_span_note,
    s.player_area,
    s.play_feature_json,
    s.worldview_json,
    s.runtime_bundle_path,
    (
        SELECT l.location_code, l.location_name, l.district_name, l.location_type, l.allowed_for_player, l.story_note
        FROM dbo.DaGo_Authoring_Scenario_Location AS l
        WHERE l.scenario_code = s.scenario_code
        ORDER BY l.sort_order
        FOR JSON PATH
    ) AS location_json,
    (
        SELECT n.npc_code, n.npc_name, n.npc_role, n.default_location_code, n.relation_start, JSON_QUERY(n.tag_json) AS tags, n.gm_note
        FROM dbo.DaGo_Authoring_Scenario_NPC AS n
        WHERE n.scenario_code = s.scenario_code
        ORDER BY n.sort_order
        FOR JSON PATH
    ) AS npc_json,
    (
        SELECT q.quest_code, q.quest_title, q.quest_goal, JSON_QUERY(q.quest_step_json) AS steps
        FROM dbo.DaGo_Authoring_Scenario_Quest AS q
        WHERE q.scenario_code = s.scenario_code
        ORDER BY q.sort_order
        FOR JSON PATH
    ) AS quest_json
FROM dbo.DaGo_Authoring_Scenario AS s
WHERE s.is_active = 1;
GO
