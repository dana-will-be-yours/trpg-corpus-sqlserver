USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.Decision_Log', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Decision_Log
    (
        decision_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Decision_Log PRIMARY KEY,

        session_id INT NOT NULL,

        scene_id INT NULL,

        decision_code NVARCHAR(80) NOT NULL,

        decision_no INT NOT NULL,

        decision_title NVARCHAR(200) NOT NULL,

        decision_type NVARCHAR(50) NOT NULL,

        decision_scope NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Decision_Log_decision_scope
            DEFAULT N'team',

        decision_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Decision_Log_decision_status
            DEFAULT N'proposed',

        consensus_level NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Decision_Log_consensus_level
            DEFAULT N'unclear',

        consensus_quality_score DECIMAL(5,2) NULL,

        decision_importance NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Decision_Log_decision_importance
            DEFAULT N'medium',

        proposer_member_id INT NULL,

        proposer_character_id INT NULL,

        proposer_npc_id INT NULL,

        final_actor_member_id INT NULL,

        final_actor_character_id INT NULL,

        related_plot_event_id BIGINT NULL,

        resulting_plot_event_id BIGINT NULL,

        related_causal_link_id BIGINT NULL,

        related_rule_id INT NULL,

        related_world_setting_id INT NULL,

        related_item_id INT NULL,

        start_utterance_id BIGINT NULL,

        end_utterance_id BIGINT NULL,

        source_utterance_id BIGINT NULL,

        final_decision_utterance_id BIGINT NULL,

        decision_text_raw NVARCHAR(MAX) NULL,

        decision_text_clean NVARCHAR(MAX) NULL,

        decision_text_verified NVARCHAR(MAX) NULL,

        decision_summary NVARCHAR(MAX) NULL,

        option_summary NVARCHAR(MAX) NULL,

        selected_option NVARCHAR(MAX) NULL,

        rejected_option_summary NVARCHAR(MAX) NULL,

        rationale_raw NVARCHAR(MAX) NULL,

        rationale_clean NVARCHAR(MAX) NULL,

        rationale_verified NVARCHAR(MAX) NULL,

        evidence_summary NVARCHAR(MAX) NULL,

        rule_basis_summary NVARCHAR(MAX) NULL,

        knowledge_basis_summary NVARCHAR(MAX) NULL,

        conflict_summary NVARCHAR(MAX) NULL,

        negotiation_summary NVARCHAR(MAX) NULL,

        outcome_summary NVARCHAR(MAX) NULL,

        consequence_summary NVARCHAR(MAX) NULL,

        smm_alignment_note NVARCHAR(MAX) NULL,

        tms_process_note NVARCHAR(MAX) NULL,

        traceability_note NVARCHAR(MAX) NULL,

        source_type NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Decision_Log_source_type
            DEFAULT N'transcript_extracted',

        extraction_method NVARCHAR(50) NULL,

        review_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Decision_Log_review_status
            DEFAULT N'draft',

        include_in_analysis BIT NOT NULL
            CONSTRAINT DF_Decision_Log_include_in_analysis
            DEFAULT 1,

        exclusion_reason NVARCHAR(MAX) NULL,

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Decision_Log_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Decision_Log_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_Decision_Log_TRPG_Session
            FOREIGN KEY (session_id)
            REFERENCES dbo.TRPG_Session(session_id),

        CONSTRAINT FK_Decision_Log_Scene
            FOREIGN KEY (scene_id)
            REFERENCES dbo.Scene(scene_id),

        CONSTRAINT FK_Decision_Log_Proposer_Team_Member
            FOREIGN KEY (proposer_member_id)
            REFERENCES dbo.Team_Member(team_member_id),

        CONSTRAINT FK_Decision_Log_Proposer_Player_Character
            FOREIGN KEY (proposer_character_id)
            REFERENCES dbo.Player_Character(character_id),

        CONSTRAINT FK_Decision_Log_Proposer_NPC
            FOREIGN KEY (proposer_npc_id)
            REFERENCES dbo.NPC(npc_id),

        CONSTRAINT FK_Decision_Log_Final_Actor_Team_Member
            FOREIGN KEY (final_actor_member_id)
            REFERENCES dbo.Team_Member(team_member_id),

        CONSTRAINT FK_Decision_Log_Final_Actor_Player_Character
            FOREIGN KEY (final_actor_character_id)
            REFERENCES dbo.Player_Character(character_id),

        CONSTRAINT FK_Decision_Log_Related_Plot_Event
            FOREIGN KEY (related_plot_event_id)
            REFERENCES dbo.Plot_Event(plot_event_id),

        CONSTRAINT FK_Decision_Log_Resulting_Plot_Event
            FOREIGN KEY (resulting_plot_event_id)
            REFERENCES dbo.Plot_Event(plot_event_id),

        CONSTRAINT FK_Decision_Log_Related_Causal_Link
            FOREIGN KEY (related_causal_link_id)
            REFERENCES dbo.Event_Causal_Link(causal_link_id),

        CONSTRAINT FK_Decision_Log_Game_Rule
            FOREIGN KEY (related_rule_id)
            REFERENCES dbo.Game_Rule(rule_id),

        CONSTRAINT FK_Decision_Log_World_Setting
            FOREIGN KEY (related_world_setting_id)
            REFERENCES dbo.World_Setting(world_setting_id),

        CONSTRAINT FK_Decision_Log_Item
            FOREIGN KEY (related_item_id)
            REFERENCES dbo.Item(item_id),

        CONSTRAINT FK_Decision_Log_Start_Utterance
            FOREIGN KEY (start_utterance_id)
            REFERENCES dbo.Utterance(utterance_id),

        CONSTRAINT FK_Decision_Log_End_Utterance
            FOREIGN KEY (end_utterance_id)
            REFERENCES dbo.Utterance(utterance_id),

        CONSTRAINT FK_Decision_Log_Source_Utterance
            FOREIGN KEY (source_utterance_id)
            REFERENCES dbo.Utterance(utterance_id),

        CONSTRAINT FK_Decision_Log_Final_Decision_Utterance
            FOREIGN KEY (final_decision_utterance_id)
            REFERENCES dbo.Utterance(utterance_id),

        CONSTRAINT UQ_Decision_Log_Session_DecisionCode
            UNIQUE (session_id, decision_code),

        CONSTRAINT UQ_Decision_Log_Session_DecisionNo
            UNIQUE (session_id, decision_no),

        CONSTRAINT CK_Decision_Log_Code_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(decision_code))) > 0),

        CONSTRAINT CK_Decision_Log_Title_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(decision_title))) > 0),

        CONSTRAINT CK_Decision_Log_No
            CHECK (decision_no >= 1),

        CONSTRAINT CK_Decision_Log_Type
            CHECK (decision_type IN (
                N'action_choice',
                N'route_choice',
                N'combat_choice',
                N'social_choice',
                N'investigation_choice',
                N'rule_interpretation',
                N'resource_allocation',
                N'role_assignment',
                N'worldbuilding_choice',
                N'creation_choice',
                N'conflict_resolution',
                N'other'
            )),

        CONSTRAINT CK_Decision_Log_Scope
            CHECK (decision_scope IN (
                N'individual',
                N'pair',
                N'team',
                N'gm',
                N'system',
                N'unknown'
            )),

        CONSTRAINT CK_Decision_Log_Status
            CHECK (decision_status IN (
                N'proposed',
                N'discussed',
                N'agreed',
                N'contested',
                N'revised',
                N'implemented',
                N'abandoned',
                N'unclear',
                N'excluded'
            )),

        CONSTRAINT CK_Decision_Log_Consensus_Level
            CHECK (consensus_level IN (
                N'none',
                N'low',
                N'medium',
                N'high',
                N'unanimous',
                N'gm_decided',
                N'unclear'
            )),

        CONSTRAINT CK_Decision_Log_Consensus_Quality_Score
            CHECK (
                consensus_quality_score IS NULL
                OR consensus_quality_score BETWEEN 0 AND 100
            ),

        CONSTRAINT CK_Decision_Log_Importance
            CHECK (decision_importance IN (
                N'low',
                N'medium',
                N'high',
                N'critical'
            )),

        CONSTRAINT CK_Decision_Log_Utterance_Range
            CHECK (
                start_utterance_id IS NULL
                OR end_utterance_id IS NULL
                OR start_utterance_id <= end_utterance_id
            ),

        CONSTRAINT CK_Decision_Log_Proposer_Only_One
            CHECK (
                (
                    CASE WHEN proposer_member_id IS NULL THEN 0 ELSE 1 END
                    + CASE WHEN proposer_character_id IS NULL THEN 0 ELSE 1 END
                    + CASE WHEN proposer_npc_id IS NULL THEN 0 ELSE 1 END
                ) <= 1
            ),

        CONSTRAINT CK_Decision_Log_Final_Actor_Only_One
            CHECK (
                (
                    CASE WHEN final_actor_member_id IS NULL THEN 0 ELSE 1 END
                    + CASE WHEN final_actor_character_id IS NULL THEN 0 ELSE 1 END
                ) <= 1
            ),

        CONSTRAINT CK_Decision_Log_Source_Type
            CHECK (source_type IN (
                N'utterance_extracted',
                N'ai_extracted',
                N'ai_summarized',
                N'human_annotated',
                N'human_modified',
                N'database_imported',
                N'unknown'
            )),

        CONSTRAINT CK_Decision_Log_Extraction_Method
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

        CONSTRAINT CK_Decision_Log_Review_Status
            CHECK (review_status IN (
                N'draft',
                N'in_review',
                N'reviewed',
                N'verified',
                N'excluded'
            )),

        CONSTRAINT CK_Decision_Log_Include_Exclusion
            CHECK (
                include_in_analysis = 1
                OR exclusion_reason IS NOT NULL
            )
    );
END;
GO