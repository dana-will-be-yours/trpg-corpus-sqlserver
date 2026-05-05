USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.Plot_Event', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Plot_Event
    (
        plot_event_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Plot_Event PRIMARY KEY,

        session_id INT NOT NULL,

        scene_id INT NULL,

        event_code NVARCHAR(80) NOT NULL,

        event_no INT NOT NULL,

        event_title NVARCHAR(200) NOT NULL,

        event_type NVARCHAR(50) NOT NULL,

        event_function NVARCHAR(50) NULL,

        event_importance NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Plot_Event_event_importance
            DEFAULT N'medium',

        start_utterance_id BIGINT NULL,

        end_utterance_id BIGINT NULL,

        source_utterance_id BIGINT NULL,

        gm_narration_id BIGINT NULL,

        actor_type NVARCHAR(50) NULL,

        actor_member_id INT NULL,

        actor_character_id INT NULL,

        actor_npc_id INT NULL,

        target_type NVARCHAR(50) NULL,

        target_character_id INT NULL,

        target_npc_id INT NULL,

        target_item_id INT NULL,

        related_world_setting_id INT NULL,

        related_item_id INT NULL,

        related_rule_id INT NULL,

        event_description_raw NVARCHAR(MAX) NULL,

        event_description_clean NVARCHAR(MAX) NULL,

        event_description_verified NVARCHAR(MAX) NULL,

        event_summary NVARCHAR(MAX) NULL,

        cause_summary NVARCHAR(MAX) NULL,

        consequence_summary NVARCHAR(MAX) NULL,

        player_intent_summary NVARCHAR(MAX) NULL,

        gm_interpretation_summary NVARCHAR(MAX) NULL,

        rule_resolution_summary NVARCHAR(MAX) NULL,

        narrative_state_before NVARCHAR(MAX) NULL,

        narrative_state_after NVARCHAR(MAX) NULL,

        smm_relevance_note NVARCHAR(MAX) NULL,

        tms_relevance_note NVARCHAR(MAX) NULL,

        narrative_coherence_note NVARCHAR(MAX) NULL,

        decision_trace_note NVARCHAR(MAX) NULL,

        source_type NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Plot_Event_source_type
            DEFAULT N'transcript_extracted',

        extraction_method NVARCHAR(50) NULL,

        review_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Plot_Event_review_status
            DEFAULT N'draft',

        include_in_analysis BIT NOT NULL
            CONSTRAINT DF_Plot_Event_include_in_analysis
            DEFAULT 1,

        exclusion_reason NVARCHAR(MAX) NULL,

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Plot_Event_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Plot_Event_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_Plot_Event_TRPG_Session
            FOREIGN KEY (session_id)
            REFERENCES dbo.TRPG_Session(session_id),

        CONSTRAINT FK_Plot_Event_Scene
            FOREIGN KEY (scene_id)
            REFERENCES dbo.Scene(scene_id),

        CONSTRAINT FK_Plot_Event_Start_Utterance
            FOREIGN KEY (start_utterance_id)
            REFERENCES dbo.Utterance(utterance_id),

        CONSTRAINT FK_Plot_Event_End_Utterance
            FOREIGN KEY (end_utterance_id)
            REFERENCES dbo.Utterance(utterance_id),

        CONSTRAINT FK_Plot_Event_Source_Utterance
            FOREIGN KEY (source_utterance_id)
            REFERENCES dbo.Utterance(utterance_id),

        CONSTRAINT FK_Plot_Event_GM_Narration
            FOREIGN KEY (gm_narration_id)
            REFERENCES dbo.GM_Narration(gm_narration_id),

        CONSTRAINT FK_Plot_Event_Actor_Team_Member
            FOREIGN KEY (actor_member_id)
            REFERENCES dbo.Team_Member(team_member_id),

        CONSTRAINT FK_Plot_Event_Actor_Player_Character
            FOREIGN KEY (actor_character_id)
            REFERENCES dbo.Player_Character(character_id),

        CONSTRAINT FK_Plot_Event_Actor_NPC
            FOREIGN KEY (actor_npc_id)
            REFERENCES dbo.NPC(npc_id),

        CONSTRAINT FK_Plot_Event_Target_Player_Character
            FOREIGN KEY (target_character_id)
            REFERENCES dbo.Player_Character(character_id),

        CONSTRAINT FK_Plot_Event_Target_NPC
            FOREIGN KEY (target_npc_id)
            REFERENCES dbo.NPC(npc_id),

        CONSTRAINT FK_Plot_Event_Target_Item
            FOREIGN KEY (target_item_id)
            REFERENCES dbo.Item(item_id),

        CONSTRAINT FK_Plot_Event_World_Setting
            FOREIGN KEY (related_world_setting_id)
            REFERENCES dbo.World_Setting(world_setting_id),

        CONSTRAINT FK_Plot_Event_Related_Item
            FOREIGN KEY (related_item_id)
            REFERENCES dbo.Item(item_id),

        CONSTRAINT FK_Plot_Event_Game_Rule
            FOREIGN KEY (related_rule_id)
            REFERENCES dbo.Game_Rule(rule_id),

        CONSTRAINT UQ_Plot_Event_Session_EventCode
            UNIQUE (session_id, event_code),

        CONSTRAINT UQ_Plot_Event_Session_EventNo
            UNIQUE (session_id, event_no),

        CONSTRAINT CK_Plot_Event_Code_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(event_code))) > 0),

        CONSTRAINT CK_Plot_Event_Title_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(event_title))) > 0),

        CONSTRAINT CK_Plot_Event_No
            CHECK (event_no >= 1),

        CONSTRAINT CK_Plot_Event_Type
            CHECK (event_type IN (
                N'world_reveal',
                N'character_action',
                N'npc_action',
                N'item_acquired',
                N'item_used',
                N'clue_discovered',
                N'rule_resolution',
                N'combat_event',
                N'social_event',
                N'exploration_event',
                N'decision_event',
                N'conflict_event',
                N'consequence_event',
                N'scene_transition',
                N'creation_event',
                N'other'
            )),

        CONSTRAINT CK_Plot_Event_Function
            CHECK (
                event_function IS NULL
                OR event_function IN (
                    N'introduce_information',
                    N'advance_plot',
                    N'create_conflict',
                    N'resolve_conflict',
                    N'change_world_state',
                    N'change_character_state',
                    N'change_resource_state',
                    N'generate_decision_point',
                    N'confirm_consensus',
                    N'produce_creation_material',
                    N'other'
                )
            ),

        CONSTRAINT CK_Plot_Event_Importance
            CHECK (event_importance IN (
                N'low',
                N'medium',
                N'high',
                N'critical'
            )),

        CONSTRAINT CK_Plot_Event_Actor_Type
            CHECK (
                actor_type IS NULL
                OR actor_type IN (
                    N'team_member',
                    N'player_character',
                    N'npc',
                    N'gm',
                    N'group',
                    N'system',
                    N'unknown'
                )
            ),

        CONSTRAINT CK_Plot_Event_Target_Type
            CHECK (
                target_type IS NULL
                OR target_type IN (
                    N'player_character',
                    N'npc',
                    N'item',
                    N'world_setting',
                    N'group',
                    N'system',
                    N'unknown'
                )
            ),

        CONSTRAINT CK_Plot_Event_Source_Type
            CHECK (source_type IN (
                N'gm_prepared',
                N'utterance_extracted',
                N'gm_narration_extracted',
                N'ai_extracted',
                N'ai_summarized',
                N'human_annotated',
                N'human_modified',
                N'database_imported',
                N'unknown'
            )),

        CONSTRAINT CK_Plot_Event_Extraction_Method
            CHECK (
                extraction_method IS NULL
                OR extraction_method IN (
                    N'manual',
                    N'ai',
                    N'rule_based',
                    N'hybrid',
                    N'imported',
                    N'unknown'
                )
            ),

        CONSTRAINT CK_Plot_Event_Review_Status
            CHECK (review_status IN (
                N'draft',
                N'in_review',
                N'reviewed',
                N'verified',
                N'excluded'
            )),

        CONSTRAINT CK_Plot_Event_Include_Exclusion
            CHECK (
                include_in_analysis = 1
                OR exclusion_reason IS NOT NULL
            ),

        CONSTRAINT CK_Plot_Event_Utterance_Range
            CHECK (
                start_utterance_id IS NULL
                OR end_utterance_id IS NULL
                OR start_utterance_id <= end_utterance_id
            ),

        CONSTRAINT CK_Plot_Event_Actor_Reference
            CHECK (
                actor_type IS NULL
                OR actor_type = N'unknown'
                OR actor_type = N'group'
                OR actor_type = N'system'
                OR (actor_type IN (N'team_member', N'gm') AND actor_member_id IS NOT NULL)
                OR (actor_type = N'player_character' AND actor_character_id IS NOT NULL)
                OR (actor_type = N'npc' AND actor_npc_id IS NOT NULL)
            ),

        CONSTRAINT CK_Plot_Event_Target_Reference
            CHECK (
                target_type IS NULL
                OR target_type = N'unknown'
                OR target_type = N'group'
                OR target_type = N'system'
                OR target_type = N'world_setting'
                OR (target_type = N'player_character' AND target_character_id IS NOT NULL)
                OR (target_type = N'npc' AND target_npc_id IS NOT NULL)
                OR (target_type = N'item' AND target_item_id IS NOT NULL)
            )
    );
END;
GO