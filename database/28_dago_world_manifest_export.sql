USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Export_DaGo_World_Manifest
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

    SELECT
        N'da_go_world_manifest_v1' AS manifest_format,
        JSON_QUERY((
            SELECT
                N'trpg-corpus-sqlserver' AS source,
                SYSDATETIMEOFFSET() AS exported_at,
                DB_NAME() AS database_name,
                @project_code AS project_code,
                @team_code AS team_code,
                @resolved_session_code AS session_code
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
                pc.character_code,
                pc.character_name,
                pc.archetype,
                pc.faction,
                pc.background_story_clean,
                pc.personality_note,
                pc.motivation_note,
                pc.relationship_note,
                pc.ability_note,
                pc.item_note,
                pc.narrative_function,
                tm.member_code,
                tm.member_role
            FROM dbo.Player_Character AS pc
            INNER JOIN dbo.Team_Member AS tm
                ON tm.team_member_id = pc.team_member_id
            WHERE tm.team_id = @team_id
              AND pc.is_active = 1
              AND pc.character_status <> N'excluded'
            ORDER BY tm.seat_no, pc.character_code
            FOR JSON PATH
        )) AS characters,
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
                ws.setting_code,
                ws.setting_name,
                ws.setting_category,
                ws.setting_subcategory,
                ws.source_type,
                ws.source_reference,
                ws.setting_summary,
                ws.setting_description_clean,
                ws.narrative_function,
                ws.related_rule_code,
                ws.is_canon,
                ws.is_active
            FROM dbo.World_Setting AS ws
            WHERE ws.project_id = @project_id
              AND (ws.team_id IS NULL OR ws.team_id = @team_id)
              AND ws.setting_status <> N'excluded'
            ORDER BY ws.setting_category, ws.setting_code
            FOR JSON PATH
        )) AS world_settings,
        JSON_QUERY((
            SELECT
                i.item_code,
                i.item_name,
                i.item_category,
                i.item_subcategory,
                i.source_type,
                i.source_reference,
                i.item_summary,
                i.item_description_clean,
                i.narrative_function,
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
                gr.rule_subcategory,
                gr.rule_source_type,
                gr.rule_summary,
                gr.rule_condition,
                gr.rule_effect,
                gr.dice_formula,
                gr.difficulty_rule,
                gr.success_effect,
                gr.failure_effect,
                gr.applies_to_speaker_type,
                gr.applies_to_character_type,
                gr.is_house_rule
            FROM dbo.Game_Rule AS gr
            WHERE gr.project_id = @project_id
              AND gr.is_active = 1
              AND gr.rule_status <> N'excluded'
            ORDER BY gr.rule_category, gr.rule_code
            FOR JSON PATH
        )) AS rules,
        JSON_QUERY((
            SELECT
                sc.scene_code AS scene_key,
                sc.scene_code,
                sc.scene_no,
                sc.scene_title,
                sc.scene_type,
                sc.location_name,
                sc.scene_goal,
                sc.scene_summary_clean,
                sc.scene_summary_raw,
                sc.conflict_summary,
                sc.decision_summary,
                sc.knowledge_summary,
                sc.outcome_summary,
                sc.involved_character_note,
                sc.involved_npc_note,
                sc.involved_item_note,
                sc.smm_note,
                sc.tms_note,
                JSON_QUERY((
                    SELECT TOP (6)
                        d.decision_code,
                        d.decision_title AS text,
                        sc_next.scene_code AS next_scene_code,
                        N'decision' AS utterance_function,
                        d.decision_type,
                        d.decision_summary,
                        d.selected_option
                    FROM dbo.Decision_Log AS d
                    LEFT JOIN dbo.Plot_Event AS pe
                        ON pe.plot_event_id = d.resulting_plot_event_id
                    LEFT JOIN dbo.Scene AS sc_next
                        ON sc_next.scene_id = pe.scene_id
                    WHERE d.scene_id = sc.scene_id
                      AND d.review_status <> N'excluded'
                    ORDER BY d.decision_no
                    FOR JSON PATH
                )) AS choices
            FROM dbo.Scene AS sc
            WHERE sc.session_id = @session_id
              AND sc.include_in_analysis = 1
              AND sc.scene_status <> N'excluded'
            ORDER BY sc.scene_no
            FOR JSON PATH
        )) AS scenes,
        JSON_QUERY((
            SELECT
                pe.event_code,
                pe.event_no,
                pe.event_title,
                pe.event_type,
                pe.event_function,
                pe.event_importance,
                sc.scene_code,
                pe.event_summary,
                pe.cause_summary,
                pe.consequence_summary,
                pe.player_intent_summary,
                pe.smm_relevance_note,
                pe.tms_relevance_note,
                pe.decision_trace_note
            FROM dbo.Plot_Event AS pe
            LEFT JOIN dbo.Scene AS sc
                ON sc.scene_id = pe.scene_id
            WHERE pe.session_id = @session_id
              AND pe.include_in_analysis = 1
              AND pe.review_status <> N'excluded'
            ORDER BY pe.event_no
            FOR JSON PATH
        )) AS plot_events
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
END;
GO
