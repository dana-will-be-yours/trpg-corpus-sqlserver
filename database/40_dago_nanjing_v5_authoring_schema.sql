USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.DaGo_Authoring_Role_Definition', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DaGo_Authoring_Role_Definition
    (
        role_code NVARCHAR(50) NOT NULL
            CONSTRAINT PK_DaGo_Authoring_Role_Definition PRIMARY KEY,
        role_name NVARCHAR(100) NOT NULL,
        role_category NVARCHAR(50) NOT NULL
            CONSTRAINT DF_DaGo_Authoring_Role_Definition_Category DEFAULT N'nanjing_identity',
        role_description NVARCHAR(MAX) NULL,
        default_skill_json NVARCHAR(MAX) NOT NULL,
        is_repeatable BIT NOT NULL
            CONSTRAINT DF_DaGo_Authoring_Role_Definition_is_repeatable DEFAULT 1,
        is_active BIT NOT NULL
            CONSTRAINT DF_DaGo_Authoring_Role_Definition_is_active DEFAULT 1,
        sort_order INT NOT NULL
            CONSTRAINT DF_DaGo_Authoring_Role_Definition_sort_order DEFAULT 100,
        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_DaGo_Authoring_Role_Definition_created_at DEFAULT SYSDATETIME(),
        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_DaGo_Authoring_Role_Definition_updated_at DEFAULT SYSDATETIME(),
        CONSTRAINT CK_DaGo_Authoring_Role_Definition_JSON CHECK (ISJSON(default_skill_json) = 1)
    );
END;
GO

IF OBJECT_ID(N'dbo.DaGo_Authoring_Rank_Rule', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DaGo_Authoring_Rank_Rule
    (
        repeat_count TINYINT NOT NULL
            CONSTRAINT PK_DaGo_Authoring_Rank_Rule PRIMARY KEY,
        rank_code NVARCHAR(10) NOT NULL,
        rank_name NVARCHAR(20) NOT NULL,
        reputation_bonus INT NOT NULL
            CONSTRAINT DF_DaGo_Authoring_Rank_Rule_reputation_bonus DEFAULT 0,
        coin_bonus INT NOT NULL
            CONSTRAINT DF_DaGo_Authoring_Rank_Rule_coin_bonus DEFAULT 0,
        rule_note NVARCHAR(300) NULL,
        CONSTRAINT CK_DaGo_Authoring_Rank_Rule_Count CHECK (repeat_count BETWEEN 1 AND 5)
    );
END;
GO

IF OBJECT_ID(N'dbo.DaGo_Authoring_Difficulty_Rule', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DaGo_Authoring_Difficulty_Rule
    (
        dc INT NOT NULL
            CONSTRAINT PK_DaGo_Authoring_Difficulty_Rule PRIMARY KEY,
        difficulty_name NVARCHAR(50) NOT NULL,
        target_actor_note NVARCHAR(300) NOT NULL,
        is_active BIT NOT NULL
            CONSTRAINT DF_DaGo_Authoring_Difficulty_Rule_is_active DEFAULT 1,
        CONSTRAINT CK_DaGo_Authoring_Difficulty_Rule_DC CHECK (dc >= 8)
    );
END;
GO

IF OBJECT_ID(N'dbo.DaGo_Authoring_Nanjing_Location', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DaGo_Authoring_Nanjing_Location
    (
        location_code NVARCHAR(50) NOT NULL
            CONSTRAINT PK_DaGo_Authoring_Nanjing_Location PRIMARY KEY,
        location_name NVARCHAR(100) NOT NULL,
        location_type NVARCHAR(50) NOT NULL,
        district_name NVARCHAR(100) NOT NULL
            CONSTRAINT DF_DaGo_Authoring_Nanjing_Location_district DEFAULT N'南京',
        allowed_for_player BIT NOT NULL
            CONSTRAINT DF_DaGo_Authoring_Nanjing_Location_allowed DEFAULT 1,
        story_note NVARCHAR(MAX) NULL,
        sort_order INT NOT NULL
            CONSTRAINT DF_DaGo_Authoring_Nanjing_Location_sort_order DEFAULT 100
    );
END;
GO

IF OBJECT_ID(N'dbo.DaGo_Authoring_Skill_Definition', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DaGo_Authoring_Skill_Definition
    (
        skill_code NVARCHAR(50) NOT NULL
            CONSTRAINT PK_DaGo_Authoring_Skill_Definition PRIMARY KEY,
        skill_name NVARCHAR(100) NOT NULL,
        attribute_code NVARCHAR(20) NOT NULL,
        skill_group NVARCHAR(50) NOT NULL,
        max_skill_level TINYINT NOT NULL
            CONSTRAINT DF_DaGo_Authoring_Skill_Definition_max DEFAULT 5,
        training_only_growth BIT NOT NULL
            CONSTRAINT DF_DaGo_Authoring_Skill_Definition_training_growth DEFAULT 1,
        is_active BIT NOT NULL
            CONSTRAINT DF_DaGo_Authoring_Skill_Definition_is_active DEFAULT 1,
        sort_order INT NOT NULL
            CONSTRAINT DF_DaGo_Authoring_Skill_Definition_sort_order DEFAULT 100,
        CONSTRAINT CK_DaGo_Authoring_Skill_Definition_Attr CHECK (attribute_code IN (N'body', N'tech', N'mind'))
    );
END;
GO

MERGE dbo.DaGo_Authoring_Rank_Rule AS tgt
USING (VALUES
    (1, N'wu', N'戊', 0, 0, N'單次身分選擇。'),
    (2, N'ding', N'丁', 1, 1, N'同一身分重複兩次。'),
    (3, N'bing', N'丙', 2, 3, N'同一身分重複三次。'),
    (4, N'yi', N'乙', 3, 5, N'同一身分重複四次。'),
    (5, N'jia', N'甲', 4, 8, N'同一身分重複五次。')
) AS src(repeat_count, rank_code, rank_name, reputation_bonus, coin_bonus, rule_note)
ON tgt.repeat_count = src.repeat_count
WHEN MATCHED THEN UPDATE SET rank_code = src.rank_code, rank_name = src.rank_name, reputation_bonus = src.reputation_bonus, coin_bonus = src.coin_bonus, rule_note = src.rule_note
WHEN NOT MATCHED THEN INSERT (repeat_count, rank_code, rank_name, reputation_bonus, coin_bonus, rule_note) VALUES (src.repeat_count, src.rank_code, src.rank_name, src.reputation_bonus, src.coin_bonus, src.rule_note);
GO

MERGE dbo.DaGo_Authoring_Difficulty_Rule AS tgt
USING (VALUES
    (8, N'簡單', N'一般人也常能做到'),
    (10, N'基礎挑戰', N'普通受訓者可挑戰'),
    (12, N'標準挑戰', N'熟練者穩定處理'),
    (14, N'困難', N'專精者較有把握'),
    (16, N'很困難', N'專家級挑戰'),
    (18, N'極難', N'頂尖人物才可靠近'),
    (20, N'傳奇級', N'非常罕見的成功'),
    (22, N'非常規', N'多半需要優勢、資源或敘事加成')
) AS src(dc, difficulty_name, target_actor_note)
ON tgt.dc = src.dc
WHEN MATCHED THEN UPDATE SET difficulty_name = src.difficulty_name, target_actor_note = src.target_actor_note, is_active = 1
WHEN NOT MATCHED THEN INSERT (dc, difficulty_name, target_actor_note) VALUES (src.dc, src.difficulty_name, src.target_actor_note);
GO

MERGE dbo.DaGo_Authoring_Role_Definition AS tgt
USING (VALUES
    (N'wenxuan', N'文選', N'{"study":2,"office":2,"court":1,"elegance":1}', 10),
    (N'house', N'門閥子弟', N'{"wealth":2,"resource":1,"court":1,"social":1}', 20),
    (N'yamen', N'胥吏', N'{"office":2,"observe":1,"court":1}', 30),
    (N'guard', N'衛士', N'{"outer":1,"slash":1,"court":1,"ride":1}', 40),
    (N'wanderer', N'遊俠', N'{"jianghu":2,"geo":1,"hide":1,"history":1}', 50),
    (N'merchant', N'行商', N'{"wealth":2,"resource":2,"speech":1,"appraise":1}', 60),
    (N'medic', N'坊郭醫', N'{"medicine":2,"pharma":1,"nature":1,"observe":1}', 70),
    (N'artist', N'伎伶俳優', N'{"art":2,"empathy":1,"social":1,"elegance":1}', 80),
    (N'disciple', N'門派弟子', N'{"outer":1,"light":1,"jianghu":1,"religion":1}', 90)
) AS src(role_code, role_name, default_skill_json, sort_order)
ON tgt.role_code = src.role_code
WHEN MATCHED THEN UPDATE SET role_name = src.role_name, default_skill_json = src.default_skill_json, sort_order = src.sort_order, is_repeatable = 1, is_active = 1, updated_at = SYSDATETIME()
WHEN NOT MATCHED THEN INSERT (role_code, role_name, default_skill_json, sort_order) VALUES (src.role_code, src.role_name, src.default_skill_json, src.sort_order);
GO

MERGE dbo.DaGo_Authoring_Nanjing_Location AS tgt
USING (VALUES
    (N'Gate', N'南京外城', N'city_gate', 10),
    (N'Tea', N'南京茶棚', N'rumour_hub', 20),
    (N'Relay', N'南京驛舍', N'office_route', 30),
    (N'River', N'秦淮河埠', N'harbour', 40),
    (N'Ledger', N'南京南市帳房', N'market_archive', 50),
    (N'Kunlun', N'南京西街書肆', N'bookshop', 60),
    (N'Yamen', N'南京官署', N'government', 70),
    (N'NorthStreet', N'南京北街', N'north_route', 80),
    (N'Training', N'借住小院', N'training', 90)
) AS src(location_code, location_name, location_type, sort_order)
ON tgt.location_code = src.location_code
WHEN MATCHED THEN UPDATE SET location_name = src.location_name, location_type = src.location_type, district_name = N'南京', allowed_for_player = 1, sort_order = src.sort_order
WHEN NOT MATCHED THEN INSERT (location_code, location_name, location_type, sort_order) VALUES (src.location_code, src.location_name, src.location_type, src.sort_order);
GO

CREATE OR ALTER VIEW dbo.vw_DaGo_Nanjing_V5_Authoring_Rules
AS
SELECT
    N'role' AS rule_type,
    role_code AS code,
    role_name AS display_name,
    default_skill_json AS rule_json,
    sort_order
FROM dbo.DaGo_Authoring_Role_Definition
WHERE is_active = 1
UNION ALL
SELECT
    N'difficulty',
    CONVERT(NVARCHAR(50), dc),
    CONCAT(dc, N' ', difficulty_name),
    CONCAT(N'{"dc":', dc, N',"difficulty_name":"', difficulty_name, N'","target_actor_note":"', target_actor_note, N'"}'),
    dc
FROM dbo.DaGo_Authoring_Difficulty_Rule
WHERE is_active = 1
UNION ALL
SELECT
    N'location',
    location_code,
    location_name,
    CONCAT(N'{"district":"南京","location_type":"', location_type, N'"}'),
    sort_order
FROM dbo.DaGo_Authoring_Nanjing_Location
WHERE allowed_for_player = 1;
GO
