/*
26_performance_indexes.sql
Supplemental nonclustered indexes for staging import, code lookup,
utterance analysis, derived coding tables, and common foreign-key joins.

Run after 00_create_database.sql through 25_stg_usp_Load_Utterance_Import_To_Dbo.sql.
*/

USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

/* -------------------------------------------------------------------------
   1. Staging import workload
   ------------------------------------------------------------------------- */

IF OBJECT_ID(N'stg.Utterance_Import', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'stg.Utterance_Import')
          AND name = N'IX_stg_Utterance_Import_Batch_Status'
    )
    BEGIN
        DROP INDEX IX_stg_Utterance_Import_Batch_Status
        ON stg.Utterance_Import;
    END;

    CREATE NONCLUSTERED INDEX IX_stg_Utterance_Import_Batch_Status
    ON stg.Utterance_Import (import_batch_id, import_status, source_row_no)
    INCLUDE
    (
        utterance_import_id,
        project_code,
        team_code,
        session_code,
        scene_code,
        utterance_code,
        speaker_type,
        speaker_code,
        interaction_target_type,
        interaction_target_code,
        related_rule_code,
        related_world_setting_code,
        related_item_code
    );
END;
GO

IF OBJECT_ID(N'stg.Utterance_Import', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'stg.Utterance_Import')
          AND name = N'IX_stg_Utterance_Import_Batch_Session_Turn'
    )
    BEGIN
        DROP INDEX IX_stg_Utterance_Import_Batch_Session_Turn
        ON stg.Utterance_Import;
    END;

    CREATE NONCLUSTERED INDEX IX_stg_Utterance_Import_Batch_Session_Turn
    ON stg.Utterance_Import (import_batch_id, session_code, turn_no_text)
    INCLUDE
    (
        utterance_import_id,
        source_row_no,
        utterance_code,
        import_status
    );
END;
GO

IF OBJECT_ID(N'stg.Utterance_Import', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'stg.Utterance_Import')
          AND name = N'IX_stg_Utterance_Import_Batch_Session_Code'
    )
    BEGIN
        DROP INDEX IX_stg_Utterance_Import_Batch_Session_Code
        ON stg.Utterance_Import;
    END;

    CREATE NONCLUSTERED INDEX IX_stg_Utterance_Import_Batch_Session_Code
    ON stg.Utterance_Import (import_batch_id, session_code, utterance_code)
    INCLUDE
    (
        utterance_import_id,
        source_row_no,
        turn_no_text,
        import_status
    );
END;
GO

/* -------------------------------------------------------------------------
   2. Lookup paths not fully covered by existing UNIQUE constraints
   ------------------------------------------------------------------------- */

IF OBJECT_ID(N'dbo.Player_Character', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.Player_Character')
          AND name = N'IX_Player_Character_CharacterCode_TeamMember'
    )
    BEGIN
        DROP INDEX IX_Player_Character_CharacterCode_TeamMember
        ON dbo.Player_Character;
    END;

    CREATE NONCLUSTERED INDEX IX_Player_Character_CharacterCode_TeamMember
    ON dbo.Player_Character (character_code, team_member_id)
    INCLUDE (character_id);
END;
GO

IF OBJECT_ID(N'dbo.World_Setting', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.World_Setting')
          AND name = N'IX_World_Setting_Project_Setting_Team'
    )
    BEGIN
        DROP INDEX IX_World_Setting_Project_Setting_Team
        ON dbo.World_Setting;
    END;

    CREATE NONCLUSTERED INDEX IX_World_Setting_Project_Setting_Team
    ON dbo.World_Setting (project_id, setting_code, team_id)
    INCLUDE (world_setting_id);
END;
GO

/* -------------------------------------------------------------------------
   3. Utterance analysis workload
   ------------------------------------------------------------------------- */

IF OBJECT_ID(N'dbo.Utterance', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.Utterance')
          AND name = N'IX_Utterance_Analysis_Session_Turn'
    )
    BEGIN
        DROP INDEX IX_Utterance_Analysis_Session_Turn
        ON dbo.Utterance;
    END;

    CREATE NONCLUSTERED INDEX IX_Utterance_Analysis_Session_Turn
    ON dbo.Utterance (session_id, include_in_analysis, turn_no)
    INCLUDE
    (
        scene_id,
        sub_turn_no,
        speaker_type,
        utterance_function,
        is_in_character,
        is_gm_narration,
        is_rule_related,
        is_decision_related,
        is_knowledge_related,
        speaker_member_id,
        speaker_character_id,
        speaker_npc_id,
        related_rule_id,
        related_world_setting_id,
        related_item_id,
        emotion_label,
        language_code
    );
END;
GO

IF OBJECT_ID(N'dbo.Utterance', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.Utterance')
          AND name = N'IX_Utterance_Analysis_Function'
    )
    BEGIN
        DROP INDEX IX_Utterance_Analysis_Function
        ON dbo.Utterance;
    END;

    CREATE NONCLUSTERED INDEX IX_Utterance_Analysis_Function
    ON dbo.Utterance (include_in_analysis, utterance_function, session_id, turn_no)
    INCLUDE
    (
        scene_id,
        speaker_type,
        is_rule_related,
        is_decision_related,
        is_knowledge_related,
        speaker_member_id,
        speaker_character_id,
        speaker_npc_id
    );
END;
GO

IF OBJECT_ID(N'dbo.Utterance', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.Utterance')
          AND name = N'IX_Utterance_Speaker_Member'
    )
    BEGIN
        DROP INDEX IX_Utterance_Speaker_Member
        ON dbo.Utterance;
    END;

    CREATE NONCLUSTERED INDEX IX_Utterance_Speaker_Member
    ON dbo.Utterance (speaker_member_id, session_id, turn_no)
    INCLUDE (utterance_function, include_in_analysis)
    WHERE speaker_member_id IS NOT NULL;
END;
GO

IF OBJECT_ID(N'dbo.Utterance', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.Utterance')
          AND name = N'IX_Utterance_Speaker_Character'
    )
    BEGIN
        DROP INDEX IX_Utterance_Speaker_Character
        ON dbo.Utterance;
    END;

    CREATE NONCLUSTERED INDEX IX_Utterance_Speaker_Character
    ON dbo.Utterance (speaker_character_id, session_id, turn_no)
    INCLUDE (utterance_function, include_in_analysis)
    WHERE speaker_character_id IS NOT NULL;
END;
GO

IF OBJECT_ID(N'dbo.Utterance', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.Utterance')
          AND name = N'IX_Utterance_Speaker_NPC'
    )
    BEGIN
        DROP INDEX IX_Utterance_Speaker_NPC
        ON dbo.Utterance;
    END;

    CREATE NONCLUSTERED INDEX IX_Utterance_Speaker_NPC
    ON dbo.Utterance (speaker_npc_id, session_id, turn_no)
    INCLUDE (utterance_function, include_in_analysis)
    WHERE speaker_npc_id IS NOT NULL;
END;
GO

IF OBJECT_ID(N'dbo.Utterance', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.Utterance')
          AND name = N'IX_Utterance_Related_Rule'
    )
    BEGIN
        DROP INDEX IX_Utterance_Related_Rule
        ON dbo.Utterance;
    END;

    CREATE NONCLUSTERED INDEX IX_Utterance_Related_Rule
    ON dbo.Utterance (related_rule_id, session_id, turn_no)
    INCLUDE (utterance_function, include_in_analysis)
    WHERE related_rule_id IS NOT NULL;
END;
GO

IF OBJECT_ID(N'dbo.Utterance', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.Utterance')
          AND name = N'IX_Utterance_Related_WorldSetting'
    )
    BEGIN
        DROP INDEX IX_Utterance_Related_WorldSetting
        ON dbo.Utterance;
    END;

    CREATE NONCLUSTERED INDEX IX_Utterance_Related_WorldSetting
    ON dbo.Utterance (related_world_setting_id, session_id, turn_no)
    INCLUDE (utterance_function, include_in_analysis)
    WHERE related_world_setting_id IS NOT NULL;
END;
GO

IF OBJECT_ID(N'dbo.Utterance', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.Utterance')
          AND name = N'IX_Utterance_Related_Item'
    )
    BEGIN
        DROP INDEX IX_Utterance_Related_Item
        ON dbo.Utterance;
    END;

    CREATE NONCLUSTERED INDEX IX_Utterance_Related_Item
    ON dbo.Utterance (related_item_id, session_id, turn_no)
    INCLUDE (utterance_function, include_in_analysis)
    WHERE related_item_id IS NOT NULL;
END;
GO

/* -------------------------------------------------------------------------
   4. Derived coding and analysis tables
   ------------------------------------------------------------------------- */

IF OBJECT_ID(N'dbo.GM_Narration', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.GM_Narration')
          AND name = N'IX_GM_Narration_Analysis'
    )
    BEGIN
        DROP INDEX IX_GM_Narration_Analysis
        ON dbo.GM_Narration;
    END;

    CREATE NONCLUSTERED INDEX IX_GM_Narration_Analysis
    ON dbo.GM_Narration (session_id, include_in_analysis, narration_function)
    INCLUDE
    (
        scene_id,
        utterance_id,
        narration_type,
        related_world_setting_id,
        related_npc_id,
        related_item_id,
        related_rule_id
    );
END;
GO

IF OBJECT_ID(N'dbo.Plot_Event', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.Plot_Event')
          AND name = N'IX_Plot_Event_Analysis'
    )
    BEGIN
        DROP INDEX IX_Plot_Event_Analysis
        ON dbo.Plot_Event;
    END;

    CREATE NONCLUSTERED INDEX IX_Plot_Event_Analysis
    ON dbo.Plot_Event (session_id, include_in_analysis, event_type, event_no)
    INCLUDE
    (
        scene_id,
        event_function,
        event_importance,
        start_utterance_id,
        end_utterance_id,
        source_utterance_id,
        gm_narration_id,
        related_world_setting_id,
        related_item_id,
        related_rule_id
    );
END;
GO

IF OBJECT_ID(N'dbo.Event_Causal_Link', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.Event_Causal_Link')
          AND name = N'IX_Event_Causal_Link_Analysis'
    )
    BEGIN
        DROP INDEX IX_Event_Causal_Link_Analysis
        ON dbo.Event_Causal_Link;
    END;

    CREATE NONCLUSTERED INDEX IX_Event_Causal_Link_Analysis
    ON dbo.Event_Causal_Link (session_id, include_in_analysis, link_type)
    INCLUDE
    (
        scene_id,
        cause_event_id,
        effect_event_id,
        link_strength,
        causal_direction,
        evidence_utterance_id,
        evidence_gm_narration_id,
        evidence_decision_id
    );
END;
GO

IF OBJECT_ID(N'dbo.Decision_Log', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.Decision_Log')
          AND name = N'IX_Decision_Log_Analysis'
    )
    BEGIN
        DROP INDEX IX_Decision_Log_Analysis
        ON dbo.Decision_Log;
    END;

    CREATE NONCLUSTERED INDEX IX_Decision_Log_Analysis
    ON dbo.Decision_Log (session_id, include_in_analysis, decision_type, decision_no)
    INCLUDE
    (
        scene_id,
        decision_status,
        consensus_level,
        consensus_quality_score,
        decision_importance,
        proposer_member_id,
        proposer_character_id,
        final_actor_member_id,
        final_actor_character_id,
        related_plot_event_id,
        resulting_plot_event_id,
        related_rule_id,
        related_world_setting_id,
        related_item_id,
        start_utterance_id,
        end_utterance_id,
        source_utterance_id,
        final_decision_utterance_id
    );
END;
GO

IF OBJECT_ID(N'dbo.Knowledge_Retrieval_Log', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.Knowledge_Retrieval_Log')
          AND name = N'IX_Knowledge_Retrieval_Log_Analysis'
    )
    BEGIN
        DROP INDEX IX_Knowledge_Retrieval_Log_Analysis
        ON dbo.Knowledge_Retrieval_Log;
    END;

    CREATE NONCLUSTERED INDEX IX_Knowledge_Retrieval_Log_Analysis
    ON dbo.Knowledge_Retrieval_Log (session_id, include_in_analysis, retrieval_type, retrieval_no)
    INCLUDE
    (
        scene_id,
        query_initiator_member_id,
        query_initiator_character_id,
        source_utterance_id,
        query_start_utterance_id,
        query_end_utterance_id,
        related_decision_id,
        related_plot_event_id,
        related_causal_link_id,
        related_rule_id,
        related_world_setting_id,
        related_item_id,
        retrieval_success,
        retrieval_success_level,
        was_result_used_in_decision,
        was_result_used_in_event
    );
END;
GO

IF OBJECT_ID(N'dbo.Team_Play_History', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.Team_Play_History')
          AND name = N'IX_Team_Play_History_Analysis'
    )
    BEGIN
        DROP INDEX IX_Team_Play_History_Analysis
        ON dbo.Team_Play_History;
    END;

    CREATE NONCLUSTERED INDEX IX_Team_Play_History_Analysis
    ON dbo.Team_Play_History (team_id, include_in_analysis, history_type, history_no)
    INCLUDE
    (
        session_id,
        scene_id,
        history_level,
        start_utterance_id,
        end_utterance_id,
        related_plot_event_id,
        related_decision_id,
        related_retrieval_id,
        related_causal_link_id,
        main_world_setting_id,
        main_item_id,
        main_npc_id
    );
END;
GO

IF OBJECT_ID(N'dbo.Extended_Creation_Text', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.Extended_Creation_Text')
          AND name = N'IX_Extended_Creation_Text_Analysis'
    )
    BEGIN
        DROP INDEX IX_Extended_Creation_Text_Analysis
        ON dbo.Extended_Creation_Text;
    END;

    CREATE NONCLUSTERED INDEX IX_Extended_Creation_Text_Analysis
    ON dbo.Extended_Creation_Text (team_id, include_in_analysis, creation_type, creation_no, version_no)
    INCLUDE
    (
        session_id,
        scene_id,
        creation_stage,
        authoring_mode,
        author_member_id,
        related_play_history_id,
        related_plot_event_id,
        related_decision_id,
        related_retrieval_id,
        related_world_setting_id,
        related_item_id,
        related_npc_id,
        source_start_utterance_id,
        source_end_utterance_id,
        is_final_version,
        word_count
    );
END;
GO

IF OBJECT_ID(N'dbo.Expert_Rating', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.Expert_Rating')
          AND name = N'IX_Expert_Rating_Analysis'
    )
    BEGIN
        DROP INDEX IX_Expert_Rating_Analysis
        ON dbo.Expert_Rating;
    END;

    CREATE NONCLUSTERED INDEX IX_Expert_Rating_Analysis
    ON dbo.Expert_Rating (project_id, include_in_analysis, rating_target_type, rating_round_no)
    INCLUDE
    (
        team_id,
        expert_player_id,
        creation_text_id,
        scene_id,
        plot_event_id,
        decision_id,
        play_history_id,
        overall_score,
        creativity_score,
        narrative_coherence_score,
        smm_quality_score,
        tms_quality_score,
        database_usefulness_score,
        trpg_integration_score,
        rating_status
    );
END;
GO

/* -------------------------------------------------------------------------
   5. Supplemental foreign-key join paths
   ------------------------------------------------------------------------- */

IF OBJECT_ID(N'dbo.Team_Member', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.Team_Member')
          AND name = N'IX_Team_Member_Player'
    )
    BEGIN
        DROP INDEX IX_Team_Member_Player
        ON dbo.Team_Member;
    END;

    CREATE NONCLUSTERED INDEX IX_Team_Member_Player
    ON dbo.Team_Member (player_id)
    INCLUDE (team_id, member_code, member_role);
END;
GO

IF OBJECT_ID(N'dbo.NPC', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.NPC')
          AND name = N'IX_NPC_ControllerMember'
    )
    BEGIN
        DROP INDEX IX_NPC_ControllerMember
        ON dbo.NPC;
    END;

    CREATE NONCLUSTERED INDEX IX_NPC_ControllerMember
    ON dbo.NPC (controller_member_id)
    INCLUDE (team_id, npc_code)
    WHERE controller_member_id IS NOT NULL;
END;
GO

IF OBJECT_ID(N'dbo.Scene', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.Scene')
          AND name = N'IX_Scene_WorldSetting'
    )
    BEGIN
        DROP INDEX IX_Scene_WorldSetting
        ON dbo.Scene;
    END;

    CREATE NONCLUSTERED INDEX IX_Scene_WorldSetting
    ON dbo.Scene (world_setting_id)
    INCLUDE (session_id, scene_code, scene_no)
    WHERE world_setting_id IS NOT NULL;
END;
GO

IF OBJECT_ID(N'dbo.Item', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.Item')
          AND name = N'IX_Item_RelatedWorldSetting'
    )
    BEGIN
        DROP INDEX IX_Item_RelatedWorldSetting
        ON dbo.Item;
    END;

    CREATE NONCLUSTERED INDEX IX_Item_RelatedWorldSetting
    ON dbo.Item (related_world_setting_id)
    INCLUDE (team_id, item_code)
    WHERE related_world_setting_id IS NOT NULL;
END;
GO

IF OBJECT_ID(N'dbo.Item', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.Item')
          AND name = N'IX_Item_OwnerCharacter'
    )
    BEGIN
        DROP INDEX IX_Item_OwnerCharacter
        ON dbo.Item;
    END;

    CREATE NONCLUSTERED INDEX IX_Item_OwnerCharacter
    ON dbo.Item (owner_character_id)
    INCLUDE (team_id, item_code)
    WHERE owner_character_id IS NOT NULL;
END;
GO

IF OBJECT_ID(N'dbo.Item', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.Item')
          AND name = N'IX_Item_OwnerNPC'
    )
    BEGIN
        DROP INDEX IX_Item_OwnerNPC
        ON dbo.Item;
    END;

    CREATE NONCLUSTERED INDEX IX_Item_OwnerNPC
    ON dbo.Item (owner_npc_id)
    INCLUDE (team_id, item_code)
    WHERE owner_npc_id IS NOT NULL;
END;
GO

IF OBJECT_ID(N'dbo.Item', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.Item')
          AND name = N'IX_Item_CurrentLocationSetting'
    )
    BEGIN
        DROP INDEX IX_Item_CurrentLocationSetting
        ON dbo.Item;
    END;

    CREATE NONCLUSTERED INDEX IX_Item_CurrentLocationSetting
    ON dbo.Item (current_location_setting_id)
    INCLUDE (team_id, item_code)
    WHERE current_location_setting_id IS NOT NULL;
END;
GO
