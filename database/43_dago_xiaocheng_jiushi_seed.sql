USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/*
    da_go 1.11.1 小城舊事劇本種子
    劇本時間：大興十年
    劇本地點：天津郡 常山縣
    研究者隱藏目標：在此地找到工作生活一年
*/

IF OBJECT_ID(N'dbo.DaGo_Authoring_Scenario', N'U') IS NULL
BEGIN
    THROW 50001, N'請先執行 database/42_dago_scenario_authoring_schema.sql。', 1;
END;
GO

UPDATE dbo.DaGo_Authoring_Scenario
SET is_active = 0,
    updated_at = SYSDATETIME()
WHERE scenario_code IN (N'xiaocheng_jiushi', N'changshan_year');
GO

MERGE dbo.DaGo_Authoring_Scenario AS target
USING (VALUES
    (
        N'xiaocheng_jiushi',
        N'小城舊事',
        N'大興十年天津郡常山縣',
        N'大興十年，玩家是天津郡常山縣本地人。縣城、客棧、市集、縣衙、河埠與田里提供短工、問訊、休息、修習與人物往來。',
        N'大興十年正月八日起；玩家活動以天津郡常山縣為主。',
        N'天津郡 常山縣',
        N'["常山縣本地人開局","天津郡、常山縣、衡水縣、珩灣縣與滄北邑地點參照","疲勞、飢餓、精神與鎮定管理","NPC 日常往來與長期事件","4D3+調整值+技能值檢定","可回寫 TRPG Corpus playlog JSON"]',
        N'{"title":"大國年代記","abbreviation":"DAGO","era_abbreviation":"DC","political_context":"大興十年，天津郡常山縣位在水陸轉運與鄉里糧務交會處，縣衙、商旅、工坊與河埠各有消息來源。天津郡下含常山縣、衡水縣、珩灣縣，滄北邑隸屬珩灣縣。","hidden_goal":"在此地找到工作生活一年","themes":["立足","活計","人情","地方秩序","長期生活"]}',
        N'assets/data/scenarios/xiaocheng-jiushi.json',
        10
    )
) AS source(scenario_code, scenario_name, scenario_subtitle, scenario_summary, time_span_note, player_area, play_feature_json, worldview_json, runtime_bundle_path, sort_order)
ON target.scenario_code = source.scenario_code
WHEN MATCHED THEN UPDATE SET
    scenario_name = source.scenario_name,
    scenario_subtitle = source.scenario_subtitle,
    scenario_summary = source.scenario_summary,
    time_span_note = source.time_span_note,
    player_area = source.player_area,
    play_feature_json = source.play_feature_json,
    worldview_json = source.worldview_json,
    runtime_bundle_path = source.runtime_bundle_path,
    sort_order = source.sort_order,
    is_active = 1,
    updated_at = SYSDATETIME()
WHEN NOT MATCHED THEN INSERT
    (scenario_code, scenario_name, scenario_subtitle, scenario_summary, time_span_note, player_area, play_feature_json, worldview_json, runtime_bundle_path, sort_order)
    VALUES
    (source.scenario_code, source.scenario_name, source.scenario_subtitle, source.scenario_summary, source.time_span_note, source.player_area, source.play_feature_json, source.worldview_json, source.runtime_bundle_path, source.sort_order);
GO

DELETE FROM dbo.DaGo_Authoring_Scenario_Location
WHERE scenario_code IN (N'xiaocheng_jiushi', N'changshan_year');
DELETE FROM dbo.DaGo_Authoring_Scenario_NPC
WHERE scenario_code IN (N'xiaocheng_jiushi', N'changshan_year');
DELETE FROM dbo.DaGo_Authoring_Scenario_Quest
WHERE scenario_code IN (N'xiaocheng_jiushi', N'changshan_year');
GO

MERGE dbo.DaGo_Authoring_Scenario_Location AS target
USING (VALUES
    (N'xiaocheng_jiushi', N'Tianjin', N'天津郡郡城', N'天津郡', N'prefecture', 1, N'郡城掌水陸文移、倉運與差役調度。', 5),
    (N'xiaocheng_jiushi', N'Gate', N'常山縣東門', N'東門', N'city_gate', 1, N'開局地點，連接活計牌、客棧、河埠與縣衙。', 10),
    (N'xiaocheng_jiushi', N'WorkBoard', N'活計牌', N'東門', N'job_board', 1, N'短工、跑腿、搬運與抄錄工作來源。', 20),
    (N'xiaocheng_jiushi', N'Inn', N'客棧', N'縣城', N'lodging', 1, N'短租、旅人消息與梁三、姚娘人物線。', 30),
    (N'xiaocheng_jiushi', N'Market', N'市集', N'縣城', N'market', 1, N'貨郎、醫鋪、工坊與日用交易。', 40),
    (N'xiaocheng_jiushi', N'Granary', N'糧倉', N'官倉', N'workplace', 1, N'搬糧、盤帳、糧價與縣中秩序。', 50),
    (N'xiaocheng_jiushi', N'Workshop', N'工坊', N'縣城', N'workplace', 1, N'修車、辨材與工匠關係。', 60),
    (N'xiaocheng_jiushi', N'Yamen', N'縣衙', N'官署', N'government', 1, N'舊案、戶籍與唐簡、沈簿人物線。', 70),
    (N'xiaocheng_jiushi', N'Dock', N'南河埠', N'河埠', N'harbour', 1, N'水路、搬運與夜運消息。', 80),
    (N'xiaocheng_jiushi', N'RiverPath', N'河岸小路', N'河埠', N'path', 1, N'跟蹤、觀察與繞行情節。', 90),
    (N'xiaocheng_jiushi', N'Field', N'田埂', N'田里', N'field', 1, N'田工、水渠、糧務與趙禾人物線。', 100),
    (N'xiaocheng_jiushi', N'Clinic', N'醫鋪', N'縣城', N'clinic', 1, N'小傷病、藥材與林菱人物線。', 110),
    (N'xiaocheng_jiushi', N'Shrine', N'城隍廟', N'縣城', N'shrine', 1, N'阿芫、傳聞與隱蔽問訊。', 120),
    (N'xiaocheng_jiushi', N'Lodging', N'借住小院', N'住處', N'save_point', 1, N'休息、存檔點與修習入口。', 130),
    (N'xiaocheng_jiushi', N'Hengshui', N'衡水縣方向', N'衡水縣', N'county', 1, N'常山以西，田地與水渠消息來源。', 140),
    (N'xiaocheng_jiushi', N'Hengwan', N'珩灣縣方向', N'珩灣縣', N'county', 1, N'靠水路，船家、鹽貨與外地商旅較多。', 150),
    (N'xiaocheng_jiushi', N'Cangbei', N'滄北邑方向', N'珩灣縣 / 滄北邑', N'town', 1, N'滄北邑隸屬珩灣縣，北家舊識、船路與邊市傳聞多從此處進入常山。', 160)
) AS source(scenario_code, location_code, location_name, district_name, location_type, allowed_for_player, story_note, sort_order)
ON target.scenario_code = source.scenario_code
   AND target.location_code = source.location_code
WHEN MATCHED THEN UPDATE SET
    location_name = source.location_name,
    district_name = source.district_name,
    location_type = source.location_type,
    allowed_for_player = source.allowed_for_player,
    story_note = source.story_note,
    sort_order = source.sort_order
WHEN NOT MATCHED THEN INSERT
    (scenario_code, location_code, location_name, district_name, location_type, allowed_for_player, story_note, sort_order)
    VALUES
    (source.scenario_code, source.location_code, source.location_name, source.district_name, source.location_type, source.allowed_for_player, source.story_note, source.sort_order);
GO

MERGE dbo.DaGo_Authoring_Scenario_NPC AS target
USING (VALUES
    (N'xiaocheng_jiushi', N'npc_liang_san', N'梁三', N'客棧跑堂，熟悉旅人去向。', N'Inn', N'["客棧","旅人"]', N'旅人消息入口。', 10),
    (N'xiaocheng_jiushi', N'npc_yao_niang', N'姚娘', N'客棧掌櫃，掌握短租與欠帳消息。', N'Inn', N'["客棧","短租"]', N'借住與錢債線。', 20),
    (N'xiaocheng_jiushi', N'npc_chen_si', N'貨郎陳四', N'市集貨郎，知道各家近況。', N'Market', N'["市集","貨物"]', N'日用品、流言與價格線。', 30),
    (N'xiaocheng_jiushi', N'npc_zhao_he', N'趙禾', N'田里雇主，常招短工。', N'Field', N'["田里","活計"]', N'長期工作線。', 40),
    (N'xiaocheng_jiushi', N'npc_lao_zhou', N'老周', N'糧倉管事，掌握糧務與搬運。', N'Granary', N'["糧倉","糧務"]', N'糧務與工錢線。', 50),
    (N'xiaocheng_jiushi', N'npc_lao_pei', N'老裴', N'河埠船工，熟悉水路與夜運。', N'Dock', N'["河埠","水路"]', N'水路與夜運線。', 60),
    (N'xiaocheng_jiushi', N'npc_tang_jian', N'唐簡', N'縣衙書吏，熟悉案卷。', N'Yamen', N'["縣衙","案卷"]', N'舊案與戶籍入口。', 70),
    (N'xiaocheng_jiushi', N'npc_lin_ling', N'林菱', N'醫鋪學徒，能處理小傷小病。', N'Clinic', N'["醫鋪","藥材"]', N'醫療與藥材線。', 80),
    (N'xiaocheng_jiushi', N'npc_a_yuan', N'阿芫', N'城隍廟賣香人，記人很準。', N'Shrine', N'["城隍廟","傳聞"]', N'人際與隱蔽消息線。', 90),
    (N'xiaocheng_jiushi', N'npc_shen_bu', N'沈簿', N'縣衙簿書，偶爾查核戶籍。', N'Yamen', N'["縣衙","戶籍"]', N'身份查核與壓力事件。', 100)
) AS source(scenario_code, npc_code, npc_name, npc_role, default_location_code, tag_json, gm_note, sort_order)
ON target.scenario_code = source.scenario_code
   AND target.npc_code = source.npc_code
WHEN MATCHED THEN UPDATE SET
    npc_name = source.npc_name,
    npc_role = source.npc_role,
    default_location_code = source.default_location_code,
    tag_json = source.tag_json,
    gm_note = source.gm_note,
    sort_order = source.sort_order
WHEN NOT MATCHED THEN INSERT
    (scenario_code, npc_code, npc_name, npc_role, default_location_code, tag_json, gm_note, sort_order)
    VALUES
    (source.scenario_code, source.npc_code, source.npc_name, source.npc_role, source.default_location_code, source.tag_json, source.gm_note, source.sort_order);
GO

MERGE dbo.DaGo_Authoring_Scenario_Quest AS target
USING (VALUES
    (N'xiaocheng_jiushi', N'quest_work_life', N'常山立足', N'研究者隱藏目標：玩家在此地找到工作生活一年。玩家端不直接顯示。', N'["接觸活計牌","取得可重複短工","找到穩定住處","維持一年生活"]', 10),
    (N'xiaocheng_jiushi', N'quest_npc_relations', N'地方人物', N'研究者用：透過短工、問訊、交易與休息累積 NPC 關係。', N'["認識客棧人物","接觸市集人物","接觸縣衙人物","接觸河埠與田里人物"]', 20),
    (N'xiaocheng_jiushi', N'quest_county_records', N'縣中舊案', N'研究者用：縣衙、河埠、糧倉與市集消息形成一年分支。', N'["取得戶籍線索","取得夜運線索","取得糧務線索","依玩家狀態開啟事件"]', 30)
) AS source(scenario_code, quest_code, quest_title, quest_goal, quest_step_json, sort_order)
ON target.scenario_code = source.scenario_code
   AND target.quest_code = source.quest_code
WHEN MATCHED THEN UPDATE SET
    quest_title = source.quest_title,
    quest_goal = source.quest_goal,
    quest_step_json = source.quest_step_json,
    sort_order = source.sort_order
WHEN NOT MATCHED THEN INSERT
    (scenario_code, quest_code, quest_title, quest_goal, quest_step_json, sort_order)
    VALUES
    (source.scenario_code, source.quest_code, source.quest_title, source.quest_goal, source.quest_step_json, source.sort_order);
GO

SELECT
    N'xiaocheng_jiushi' AS scenario_code,
    N'1.11.1-xiaocheng-local' AS da_go_version,
    (SELECT COUNT(*) FROM dbo.DaGo_Authoring_Scenario_Location WHERE scenario_code = N'xiaocheng_jiushi') AS location_count,
    (SELECT COUNT(*) FROM dbo.DaGo_Authoring_Scenario_NPC WHERE scenario_code = N'xiaocheng_jiushi') AS npc_count,
    (SELECT COUNT(*) FROM dbo.DaGo_Authoring_Scenario_Quest WHERE scenario_code = N'xiaocheng_jiushi') AS quest_count;
GO
