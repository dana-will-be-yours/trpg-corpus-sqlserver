USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

DECLARE @project_id INT;
DECLARE @team_id INT;
DECLARE @gm_player_id INT;
DECLARE @researcher_player_id INT;
DECLARE @gm_member_id INT;
DECLARE @researcher_member_id INT;
DECLARE @session_id INT;

MERGE dbo.Research_Project AS target
USING (VALUES
(
    N'DAGUO',
    N'大國年代記 da_go 劇情資料',
    N'DaGo TRPG corpus playable story data',
    N'TRPG 團錄、互文性、跨媒介敘事、SQL資料庫與 da_go 單人文字遊戲資料往返',
    N'保存大國年代記文本參考資料、研究者編寫劇情與 da_go 遊玩紀錄。',
    N'public authoring seed',
    N'大國年代記 TRPG corpus and da_go runtime',
    N'文本參考資料含世界觀簡史、祈禍、素雅、戎裝、雙孤團錄與二創小說。',
    N'zh-TW',
    N'draft',
    N'v1'
)
) AS source
(
    project_code,
    project_title,
    project_title_en,
    research_topic,
    research_goal,
    research_design,
    trpg_system_note,
    corpus_scope_note,
    data_language,
    data_status,
    project_version
)
ON target.project_code = source.project_code
WHEN MATCHED THEN UPDATE SET
    project_title = source.project_title,
    project_title_en = source.project_title_en,
    research_topic = source.research_topic,
    research_goal = source.research_goal,
    research_design = source.research_design,
    trpg_system_note = source.trpg_system_note,
    corpus_scope_note = source.corpus_scope_note,
    data_language = source.data_language,
    data_status = source.data_status,
    updated_at = SYSDATETIME()
WHEN NOT MATCHED THEN INSERT
(
    project_code,
    project_title,
    project_title_en,
    research_topic,
    research_goal,
    research_design,
    trpg_system_note,
    corpus_scope_note,
    data_language,
    data_status,
    project_version
)
VALUES
(
    source.project_code,
    source.project_title,
    source.project_title_en,
    source.research_topic,
    source.research_goal,
    source.research_design,
    source.trpg_system_note,
    source.corpus_scope_note,
    source.data_language,
    source.data_status,
    source.project_version
);

SELECT @project_id = project_id
FROM dbo.Research_Project
WHERE project_code = N'DAGUO';

MERGE dbo.Team AS target
USING (VALUES
(
    @project_id,
    N'DAGUO-T01',
    N'da_go 南京篇研究者測試隊',
    N'DAGUO-PUBLIC',
    1,
    CONVERT(BIT, 1),
    CONVERT(BIT, 1),
    N'GM-DA-GO',
    3,
    3,
    N'in_progress',
    N'GitHub Pages authoring seed.'
)
) AS source
(
    project_id,
    team_code,
    team_name,
    cohort_code,
    experiment_round_no,
    condition_trpg,
    condition_database,
    assigned_gm_code,
    planned_player_count,
    actual_player_count,
    team_status,
    team_note
)
ON target.project_id = source.project_id
   AND target.team_code = source.team_code
WHEN MATCHED THEN UPDATE SET
    team_name = source.team_name,
    cohort_code = source.cohort_code,
    experiment_round_no = source.experiment_round_no,
    condition_trpg = source.condition_trpg,
    condition_database = source.condition_database,
    assigned_gm_code = source.assigned_gm_code,
    planned_player_count = source.planned_player_count,
    actual_player_count = source.actual_player_count,
    team_status = source.team_status,
    team_note = source.team_note,
    updated_at = SYSDATETIME()
WHEN NOT MATCHED THEN INSERT
(
    project_id,
    team_code,
    team_name,
    cohort_code,
    experiment_round_no,
    condition_trpg,
    condition_database,
    assigned_gm_code,
    planned_player_count,
    actual_player_count,
    team_status,
    team_note
)
VALUES
(
    source.project_id,
    source.team_code,
    source.team_name,
    source.cohort_code,
    source.experiment_round_no,
    source.condition_trpg,
    source.condition_database,
    source.assigned_gm_code,
    source.planned_player_count,
    source.actual_player_count,
    source.team_status,
    source.team_note
);

SELECT @team_id = team_id
FROM dbo.Team
WHERE project_id = @project_id
  AND team_code = N'DAGUO-T01';

MERGE dbo.Player AS target
USING (VALUES
    (@project_id, N'PLAYER-DA-GO-GM', N'gm', N'consented', N'系統 GM 種子資料。'),
    (@project_id, N'PLAYER-DA-GO-RESEARCHER', N'researcher', N'consented', N'研究者編寫頁種子資料。')
) AS source(project_id, player_code, participant_role, consent_status, player_note)
ON target.project_id = source.project_id
   AND target.player_code = source.player_code
WHEN MATCHED THEN UPDATE SET
    participant_role = source.participant_role,
    consent_status = source.consent_status,
    player_note = source.player_note,
    updated_at = SYSDATETIME()
WHEN NOT MATCHED THEN INSERT
(
    project_id,
    player_code,
    participant_role,
    consent_status,
    is_anonymized,
    player_note
)
VALUES
(
    source.project_id,
    source.player_code,
    source.participant_role,
    source.consent_status,
    1,
    source.player_note
);

SELECT @gm_player_id = player_id
FROM dbo.Player
WHERE project_id = @project_id
  AND player_code = N'PLAYER-DA-GO-GM';

SELECT @researcher_player_id = player_id
FROM dbo.Player
WHERE project_id = @project_id
  AND player_code = N'PLAYER-DA-GO-RESEARCHER';

MERGE dbo.Team_Member AS target
USING (VALUES
    (@team_id, @gm_player_id, N'GM-DA-GO', N'gm', CONVERT(BIT, 1), CONVERT(BIT, 0), CONVERT(BIT, 0), CONVERT(BIT, 0)),
    (@team_id, @researcher_player_id, N'TM-RESEARCHER', N'researcher', CONVERT(BIT, 0), CONVERT(BIT, 0), CONVERT(BIT, 0), CONVERT(BIT, 1))
) AS source(team_id, player_id, member_code, member_role, is_gm, is_player, is_observer, is_researcher)
ON target.team_id = source.team_id
   AND target.member_code = source.member_code
WHEN MATCHED THEN UPDATE SET
    player_id = source.player_id,
    member_role = source.member_role,
    is_gm = source.is_gm,
    is_player = source.is_player,
    is_observer = source.is_observer,
    is_researcher = source.is_researcher,
    attendance_status = N'attended',
    include_in_analysis = 1,
    updated_at = SYSDATETIME()
WHEN NOT MATCHED THEN INSERT
(
    team_id,
    player_id,
    member_code,
    member_role,
    is_gm,
    is_player,
    is_observer,
    is_researcher,
    attendance_status,
    include_in_analysis
)
VALUES
(
    source.team_id,
    source.player_id,
    source.member_code,
    source.member_role,
    source.is_gm,
    source.is_player,
    source.is_observer,
    source.is_researcher,
    N'attended',
    1
);

SELECT @gm_member_id = team_member_id
FROM dbo.Team_Member
WHERE team_id = @team_id
  AND member_code = N'GM-DA-GO';

SELECT @researcher_member_id = team_member_id
FROM dbo.Team_Member
WHERE team_id = @team_id
  AND member_code = N'TM-RESEARCHER';

MERGE dbo.TRPG_Session AS target
USING (VALUES
(
    @team_id,
    N'DX20-NANJING-002',
    1,
    N'da_go 南京篇公開測試',
    N'play',
    CONVERT(DATE, '2026-05-09'),
    N'online',
    N'GitHub Pages / local API',
    N'用於 da_go runtime bundle 與研究者劇情匯入。',
    N'南京開局，涵蓋南陽、崑崙、銀川、五毒與雙孤線索。',
    @gm_member_id,
    @researcher_member_id,
    N'in_progress'
)
) AS source
(
    team_id,
    session_code,
    session_no,
    session_title,
    session_type,
    session_date,
    location_type,
    location_note,
    session_goal,
    session_summary_clean,
    gm_member_id,
    recorder_member_id,
    session_status
)
ON target.team_id = source.team_id
   AND target.session_code = source.session_code
WHEN MATCHED THEN UPDATE SET
    session_title = source.session_title,
    session_type = source.session_type,
    session_date = source.session_date,
    location_type = source.location_type,
    location_note = source.location_note,
    session_goal = source.session_goal,
    session_summary_clean = source.session_summary_clean,
    gm_member_id = source.gm_member_id,
    recorder_member_id = source.recorder_member_id,
    transcript_status = N'imported',
    ai_summary_status = N'cleaned',
    human_review_status = N'reviewed',
    session_status = source.session_status,
    updated_at = SYSDATETIME()
WHEN NOT MATCHED THEN INSERT
(
    team_id,
    session_code,
    session_no,
    session_title,
    session_type,
    session_date,
    location_type,
    location_note,
    session_goal,
    session_summary_clean,
    gm_member_id,
    recorder_member_id,
    transcript_status,
    ai_summary_status,
    human_review_status,
    session_status
)
VALUES
(
    source.team_id,
    source.session_code,
    source.session_no,
    source.session_title,
    source.session_type,
    source.session_date,
    source.location_type,
    source.location_note,
    source.session_goal,
    source.session_summary_clean,
    source.gm_member_id,
    source.recorder_member_id,
    N'imported',
    N'cleaned',
    N'reviewed',
    source.session_status
);

SELECT @session_id = session_id
FROM dbo.TRPG_Session
WHERE team_id = @team_id
  AND session_code = N'DX20-NANJING-002';

DECLARE @passages TABLE
(
    passage_code NVARCHAR(100) NOT NULL PRIMARY KEY,
    title NVARCHAR(200) NOT NULL,
    body_markdown NVARCHAR(MAX) NOT NULL,
    location_name NVARCHAR(200) NULL,
    time_slot NVARCHAR(30) NULL,
    tag_json NVARCHAR(MAX) NULL,
    is_start BIT NOT NULL,
    sort_order INT NOT NULL
);

INSERT INTO @passages
(
    passage_code,
    title,
    body_markdown,
    location_name,
    time_slot,
    tag_json,
    is_start,
    sort_order
)
VALUES
(N'NANJING_GATE_REFERENCE', N'南京外城', N'大興二十年的南京，城門口的驛馬、茶棚、南市帳房與官署差役把南陽、崑崙、銀川與五毒的消息帶到同一條街上。', N'南京外城', N'卯時', N'["南京","開局","大國年代記"]', 1, 100),
(N'TEA_REFERENCE', N'城門茶棚', N'茶博士收起抹布。旁桌商旅說起江郡北虎商會、南陽商銀與江夏糧船，也有人低聲提到崑崙受襲。', N'南京茶棚', N'辰時', N'["茶棚","情報","南陽","崑崙"]', 0, 200),
(N'YAMEN_REFERENCE', N'官署門廊', N'老書吏不願多談北路，只說魏無紛在銀川，魏無忌在朝中。名字若落到錯的人手裡，後患會很快追上來。', N'南京官署', N'巳時', N'["官署","銀川","魏氏"]', 0, 300),
(N'LEDGER_REFERENCE', N'南市帳房', N'算籌壓著一張改過數次的借據。南合商會的名號反覆出現，收貨與付款卻分開走。', N'南京南市', N'午時', N'["南市","帳目","南陽"]', 0, 400);

MERGE dbo.Game_Passage AS target
USING @passages AS source
ON target.team_id = @team_id
   AND target.passage_code = source.passage_code
WHEN MATCHED THEN UPDATE SET
    project_id = @project_id,
    session_id = @session_id,
    title = source.title,
    body_markdown = source.body_markdown,
    location_name = source.location_name,
    time_slot = source.time_slot,
    tag_json = source.tag_json,
    is_start = source.is_start,
    is_terminal = 0,
    is_active = 1,
    sort_order = source.sort_order,
    updated_at = SYSDATETIME()
WHEN NOT MATCHED THEN INSERT
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
    is_start,
    is_terminal,
    is_active,
    sort_order
)
VALUES
(
    @project_id,
    @team_id,
    @session_id,
    source.passage_code,
    source.title,
    source.body_markdown,
    source.location_name,
    source.time_slot,
    source.tag_json,
    source.is_start,
    0,
    1,
    source.sort_order
);

DELETE gc
FROM dbo.Game_Choice AS gc
INNER JOIN dbo.Game_Passage AS gp
    ON gp.passage_id = gc.passage_id
WHERE gp.team_id = @team_id
  AND gp.passage_code IN (SELECT passage_code FROM @passages);

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
    weight,
    sort_order,
    is_repeatable,
    is_active
)
SELECT
    gp.passage_id,
    source.choice_code,
    source.choice_text,
    source.next_passage_code,
    source.utterance_function,
    source.condition_json,
    source.effect_json,
    source.skill_check_json,
    1,
    source.sort_order,
    1,
    1
FROM
(
    VALUES
    (N'NANJING_GATE_REFERENCE', N'TO_TEA', N'去茶棚聽南來商旅說話', N'TEA_REFERENCE', N'question', NULL, N'[{"op":"add","path":"stats.fatigue","value":1}]', N'{"skill":"listen","dc":8}', 100),
    (N'NANJING_GATE_REFERENCE', N'TO_YAMEN', N'到官署問北路急信', N'YAMEN_REFERENCE', N'question', NULL, N'[{"op":"add","path":"stats.suspicion","value":1}]', N'{"skill":"office","dc":10}', 200),
    (N'TEA_REFERENCE', N'ASK_SOUTH', N'請茶博士說清南陽商銀異動', N'LEDGER_REFERENCE', N'question', NULL, N'[{"op":"gain","value":"南陽帳目疑點"}]', N'{"skill":"speech","dc":10}', 100),
    (N'YAMEN_REFERENCE', N'CHECK_DOSSIER', N'查魏無忌近年任官', N'NANJING_GATE_REFERENCE', N'action', NULL, N'[{"op":"gain","value":"魏無忌任官摘記"}]', N'{"skill":"office","dc":12}', 100),
    (N'LEDGER_REFERENCE', N'BACK_GATE', N'把帳目疑點記入札記後回南京外城', N'NANJING_GATE_REFERENCE', N'summary', NULL, N'[{"op":"gain","value":"帳目來源"}]', NULL, 100)
) AS source(passage_code, choice_code, choice_text, next_passage_code, utterance_function, condition_json, effect_json, skill_check_json, sort_order)
INNER JOIN dbo.Game_Passage AS gp
    ON gp.team_id = @team_id
   AND gp.passage_code = source.passage_code;

SELECT
    N'DAGUO' AS project_code,
    N'DAGUO-T01' AS team_code,
    N'DX20-NANJING-002' AS session_code,
    (SELECT COUNT(*) FROM @passages) AS passage_count,
    5 AS choice_count;
GO
