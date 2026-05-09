USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.DaGo_Authoring_NPC_Definition', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DaGo_Authoring_NPC_Definition
    (
        npc_code NVARCHAR(50) NOT NULL CONSTRAINT PK_DaGo_Authoring_NPC_Definition PRIMARY KEY,
        npc_name NVARCHAR(100) NOT NULL,
        location_code NVARCHAR(50) NOT NULL,
        relation_score INT NOT NULL CONSTRAINT DF_DaGo_Authoring_NPC_relation DEFAULT 0,
        tag_json NVARCHAR(MAX) NOT NULL CONSTRAINT DF_DaGo_Authoring_NPC_tag DEFAULT N'[]',
        npc_note NVARCHAR(MAX) NULL,
        is_active BIT NOT NULL CONSTRAINT DF_DaGo_Authoring_NPC_active DEFAULT 1,
        sort_order INT NOT NULL CONSTRAINT DF_DaGo_Authoring_NPC_sort DEFAULT 100,
        CONSTRAINT CK_DaGo_Authoring_NPC_tag_json CHECK (ISJSON(tag_json) = 1)
    );
END;
GO

IF OBJECT_ID(N'dbo.DaGo_Authoring_Quest_Definition', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DaGo_Authoring_Quest_Definition
    (
        quest_code NVARCHAR(50) NOT NULL CONSTRAINT PK_DaGo_Authoring_Quest_Definition PRIMARY KEY,
        quest_title NVARCHAR(150) NOT NULL,
        quest_scope NVARCHAR(50) NOT NULL CONSTRAINT DF_DaGo_Authoring_Quest_scope DEFAULT N'nanjing_only',
        step_json NVARCHAR(MAX) NOT NULL,
        reward_json NVARCHAR(MAX) NULL,
        is_active BIT NOT NULL CONSTRAINT DF_DaGo_Authoring_Quest_active DEFAULT 1,
        sort_order INT NOT NULL CONSTRAINT DF_DaGo_Authoring_Quest_sort DEFAULT 100,
        CONSTRAINT CK_DaGo_Authoring_Quest_step_json CHECK (ISJSON(step_json) = 1),
        CONSTRAINT CK_DaGo_Authoring_Quest_reward_json CHECK (reward_json IS NULL OR ISJSON(reward_json) = 1)
    );
END;
GO

IF OBJECT_ID(N'dbo.DaGo_Authoring_Shop_Definition', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DaGo_Authoring_Shop_Definition
    (
        shop_code NVARCHAR(50) NOT NULL CONSTRAINT PK_DaGo_Authoring_Shop_Definition PRIMARY KEY,
        shop_name NVARCHAR(150) NOT NULL,
        location_code NVARCHAR(50) NOT NULL,
        item_json NVARCHAR(MAX) NOT NULL,
        is_active BIT NOT NULL CONSTRAINT DF_DaGo_Authoring_Shop_active DEFAULT 1,
        sort_order INT NOT NULL CONSTRAINT DF_DaGo_Authoring_Shop_sort DEFAULT 100,
        CONSTRAINT CK_DaGo_Authoring_Shop_item_json CHECK (ISJSON(item_json) = 1)
    );
END;
GO

IF OBJECT_ID(N'dbo.DaGo_Authoring_Event_Pool', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.DaGo_Authoring_Event_Pool
    (
        event_code NVARCHAR(50) NOT NULL CONSTRAINT PK_DaGo_Authoring_Event_Pool PRIMARY KEY,
        event_title NVARCHAR(150) NOT NULL,
        event_text NVARCHAR(MAX) NOT NULL,
        location_code NVARCHAR(50) NULL,
        condition_json NVARCHAR(MAX) NULL,
        effect_json NVARCHAR(MAX) NULL,
        cooldown_turns INT NOT NULL CONSTRAINT DF_DaGo_Authoring_Event_cooldown DEFAULT 4,
        is_active BIT NOT NULL CONSTRAINT DF_DaGo_Authoring_Event_active DEFAULT 1,
        sort_order INT NOT NULL CONSTRAINT DF_DaGo_Authoring_Event_sort DEFAULT 100,
        CONSTRAINT CK_DaGo_Authoring_Event_condition_json CHECK (condition_json IS NULL OR ISJSON(condition_json) = 1),
        CONSTRAINT CK_DaGo_Authoring_Event_effect_json CHECK (effect_json IS NULL OR ISJSON(effect_json) = 1)
    );
END;
GO

MERGE dbo.DaGo_Authoring_Skill_Definition AS tgt
USING (VALUES
(N'inner',N'內功',N'body',N'體魄',10),(N'outer',N'外功',N'body',N'體魄',20),(N'light',N'輕功',N'body',N'體魄',30),(N'swim',N'水性',N'body',N'體魄',40),(N'climb',N'攀行',N'body',N'體魄',50),(N'pierce',N'刺擊',N'body',N'體魄',60),(N'slash',N'斬擊',N'body',N'體魄',70),(N'strike',N'打擊',N'body',N'體魄',80),(N'sense',N'感知',N'body',N'體魄',90),
(N'sleight',N'巧手',N'tech',N'技巧',110),(N'craft',N'工藝',N'tech',N'技巧',120),(N'appraise',N'辨別',N'tech',N'技巧',130),(N'medicine',N'醫術',N'tech',N'技巧',140),(N'pharma',N'調藥',N'tech',N'技巧',150),(N'ride',N'騎術',N'tech',N'技巧',160),(N'hide',N'躲藏',N'tech',N'技巧',170),(N'observe',N'觀察',N'tech',N'技巧',180),(N'listen',N'聆聽',N'tech',N'技巧',190),(N'smell',N'品嗅',N'tech',N'技巧',200),(N'office',N'政務',N'tech',N'技巧',210),(N'animal',N'馴養',N'tech',N'技巧',220),(N'threat',N'威嚇',N'tech',N'技巧',230),(N'art',N'表達',N'tech',N'技巧',240),(N'elegance',N'雅藝',N'tech',N'技巧',250),
(N'appearance',N'相貌',N'mind',N'智識',310),(N'resource',N'資源',N'mind',N'智識',320),(N'wealth',N'財富',N'mind',N'智識',330),(N'court',N'官場',N'mind',N'智識',340),(N'jianghu',N'江湖',N'mind',N'智識',350),(N'geo',N'地理',N'mind',N'智識',360),(N'nature',N'自然',N'mind',N'智識',370),(N'history',N'歷史',N'mind',N'智識',380),(N'religion',N'宗教',N'mind',N'智識',390),(N'study',N'學藝',N'mind',N'智識',400),(N'will',N'意志',N'mind',N'智識',410),(N'language',N'語言',N'mind',N'智識',420),(N'social',N'交際',N'mind',N'智識',430),(N'empathy',N'共情',N'mind',N'智識',440),(N'speech',N'口才',N'mind',N'智識',450)
) AS src(skill_code, skill_name, attribute_code, skill_group, sort_order)
ON tgt.skill_code = src.skill_code
WHEN MATCHED THEN UPDATE SET skill_name=src.skill_name, attribute_code=src.attribute_code, skill_group=src.skill_group, max_skill_level=5, training_only_growth=1, is_active=1, sort_order=src.sort_order
WHEN NOT MATCHED THEN INSERT (skill_code, skill_name, attribute_code, skill_group, max_skill_level, training_only_growth, sort_order) VALUES (src.skill_code, src.skill_name, src.attribute_code, src.skill_group, 5, 1, src.sort_order);
GO

MERGE dbo.DaGo_Authoring_NPC_Definition AS tgt
USING (VALUES
(N'npc_tea_master',N'茶博士',N'Tea',0,N'["情報","市井"]',N'城門茶棚掌櫃，知道南來北往的碎話。',10),
(N'npc_post_runner',N'驛卒',N'Relay',0,N'["北路","官信"]',N'掌管北路信匣，對銀川急信極為謹慎。',20),
(N'npc_old_scribe',N'老書吏',N'Yamen',0,N'["官署","魏氏"]',N'南京官署老書吏，熟悉魏氏案牘。',30),
(N'npc_boatman',N'船主',N'River',0,N'["江夏","糧船"]',N'秦淮河埠船主，聽過江夏糧船流言。',40),
(N'npc_accountant',N'帳房先生',N'Ledger',0,N'["南陽","商會"]',N'南市帳房，手中有南合商會帳目。',50),
(N'npc_qingyi',N'青衣商旅',N'Alley',-1,N'["紙包","崑崙"]',N'在後巷交付紙包的商旅。',60),
(N'npc_daotong',N'買紙道童',N'Kunlun',0,N'["崑崙","西街"]',N'南京西街買紙的道童。',70)
) AS src(npc_code,npc_name,location_code,relation_score,tag_json,npc_note,sort_order)
ON tgt.npc_code=src.npc_code
WHEN MATCHED THEN UPDATE SET npc_name=src.npc_name, location_code=src.location_code, relation_score=src.relation_score, tag_json=src.tag_json, npc_note=src.npc_note, is_active=1, sort_order=src.sort_order
WHEN NOT MATCHED THEN INSERT (npc_code,npc_name,location_code,relation_score,tag_json,npc_note,sort_order) VALUES (src.npc_code,src.npc_name,src.location_code,src.relation_score,src.tag_json,src.npc_note,src.sort_order);
GO

MERGE dbo.DaGo_Authoring_Quest_Definition AS tgt
USING (VALUES
(N'quest_south_ledger',N'南陽銀痕',N'["取得南合商會戳記","取得南陽帳目疑點","問出劉廷平舊名"]',N'{"coin":3,"reputation":1}',10),
(N'quest_north_letter',N'銀川急信',N'["取得銀川急信線索","取得北路送信圖","請馬客帶信"]',N'{"reputation":1}',20),
(N'quest_kunlun_rumour',N'崑崙遠訊',N'["取得崑崙受襲傳聞","取得崑崙書肆信物","查下山者去向"]',N'{"composure":2}',30)
) AS src(quest_code,quest_title,step_json,reward_json,sort_order)
ON tgt.quest_code=src.quest_code
WHEN MATCHED THEN UPDATE SET quest_title=src.quest_title, step_json=src.step_json, reward_json=src.reward_json, is_active=1, sort_order=src.sort_order
WHEN NOT MATCHED THEN INSERT (quest_code,quest_title,step_json,reward_json,sort_order) VALUES (src.quest_code,src.quest_title,src.step_json,src.reward_json,src.sort_order);
GO

MERGE dbo.DaGo_Authoring_Shop_Definition AS tgt
USING (VALUES
(N'shop_teahouse',N'茶棚小攤',N'Tea',N'[{"code":"tea","name":"熱茶","price":1,"effects":{"composure":1,"hunger":-1}},{"code":"dry_food","name":"乾糧","price":1,"effects":{"hunger":-12,"spirit":1}}]',10),
(N'shop_stationery',N'西街紙筆',N'Kunlun',N'[{"code":"paper_brush","name":"素紙筆","price":1,"effects":{"composure":1}},{"code":"small_map","name":"南京小圖","price":3,"effects":{}}]',20)
) AS src(shop_code,shop_name,location_code,item_json,sort_order)
ON tgt.shop_code=src.shop_code
WHEN MATCHED THEN UPDATE SET shop_name=src.shop_name, location_code=src.location_code, item_json=src.item_json, is_active=1, sort_order=src.sort_order
WHEN NOT MATCHED THEN INSERT (shop_code,shop_name,location_code,item_json,sort_order) VALUES (src.shop_code,src.shop_name,src.location_code,src.item_json,src.sort_order);
GO

MERGE dbo.DaGo_Authoring_Event_Pool AS tgt
USING (VALUES
(N'evt_patrol',N'巡丁視線',N'街口有巡丁多看了你一眼。',NULL,N'{"suspicion":1}',4,10),
(N'evt_rain',N'雨勢回潮',N'遠處驛馬急過，泥水濺上牆角。',NULL,N'{"fatigue":1}',4,20),
(N'evt_rumour',N'碎語換題',N'茶棚換了一批客人，話題變得更碎。',N'Tea',N'{"composure":-1}',4,30)
) AS src(event_code,event_title,event_text,location_code,effect_json,cooldown_turns,sort_order)
ON tgt.event_code=src.event_code
WHEN MATCHED THEN UPDATE SET event_title=src.event_title, event_text=src.event_text, location_code=src.location_code, effect_json=src.effect_json, cooldown_turns=src.cooldown_turns, is_active=1, sort_order=src.sort_order
WHEN NOT MATCHED THEN INSERT (event_code,event_title,event_text,location_code,effect_json,cooldown_turns,sort_order) VALUES (src.event_code,src.event_title,src.event_text,src.location_code,src.effect_json,src.cooldown_turns,src.sort_order);
GO

CREATE OR ALTER VIEW dbo.vw_DaGo_Nanjing_V5_World_Bundle_Rows
AS
SELECT N'skill' AS row_type, skill_code AS code, skill_name AS display_name, CONCAT(N'{"attr":"', attribute_code, N'","group":"', skill_group, N'","max":', max_skill_level, N'}') AS payload_json, sort_order
FROM dbo.DaGo_Authoring_Skill_Definition WHERE is_active=1
UNION ALL
SELECT N'npc', npc_code, npc_name, CONCAT(N'{"location":"', location_code, N'","relation":', relation_score, N',"tags":', tag_json, N'}'), sort_order
FROM dbo.DaGo_Authoring_NPC_Definition WHERE is_active=1
UNION ALL
SELECT N'quest', quest_code, quest_title, CONCAT(N'{"steps":', step_json, N',"reward":', COALESCE(reward_json,N'{}'), N'}'), sort_order
FROM dbo.DaGo_Authoring_Quest_Definition WHERE is_active=1
UNION ALL
SELECT N'shop', shop_code, shop_name, CONCAT(N'{"location":"', location_code, N'","items":', item_json, N'}'), sort_order
FROM dbo.DaGo_Authoring_Shop_Definition WHERE is_active=1
UNION ALL
SELECT N'event', event_code, event_title, CONCAT(N'{"text":"', STRING_ESCAPE(event_text,'json'), N'","location":', COALESCE(CONCAT(N'"', location_code, N'"'), N'null'), N',"effects":', COALESCE(effect_json,N'{}'), N',"cooldown":', cooldown_turns, N'}'), sort_order
FROM dbo.DaGo_Authoring_Event_Pool WHERE is_active=1;
GO
