USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.Team_Play_History', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Team_Play_History
    (
        play_history_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Team_Play_History PRIMARY KEY,

        team_id INT NOT NULL,

        session_id INT NULL,

        scene_id INT NULL,

        history_code NVARCHAR(80) NOT NULL,

        history_no INT NOT NULL,

        history_level NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Team_Play_History_history_level
            DEFAULT N'session',

        history_type NVARCHAR(50) NOT NULL,

        history_title NVARCHAR(200) NOT NULL,

        time_scope_start_session_no INT NULL,

        time_scope_end_session_no INT NULL,

        time_scope_start_scene_no INT NULL,

        time_scope_end_scene_no INT NULL,

        start_utterance_id BIGINT NULL,

        end_utterance_id BIGINT NULL,

        related_plot_event_id BIGINT NULL,

        related_decision_id BIGINT NULL,

        related_retrieval_id BIGINT NULL,

        related_causal_link_id BIGINT NULL,

        main_world_setting_id INT NULL,

        main_item_id INT NULL,

        main_npc_id INT NULL,

        history_description_raw NVARCHAR(MAX) NULL,

        history_description_clean NVARCHAR(MAX) NULL,

        history_description_verified NVARCHAR(MAX) NULL,

        history_summary NVARCHAR(MAX) NULL,

        mission_progress_summary NVARCHAR(MAX) NULL,

        character_interaction_summary NVARCHAR(MAX) NULL,

        cooperation_summary NVARCHAR(MAX) NULL,

        conflict_summary NVARCHAR(MAX) NULL,

        consensus_change_summary NVARCHAR(MAX) NULL,

        knowledge_sharing_summary NVARCHAR(MAX) NULL,

        database_use_summary NVARCHAR(MAX) NULL,

        rule_use_summary NVARCHAR(MAX) NULL,

        creation_material_summary NVARCHAR(MAX) NULL,

        narrative_progress_summary NVARCHAR(MAX) NULL,

        narrative_coherence_note NVARCHAR(MAX) NULL,

        smm_state_note NVARCHAR(MAX) NULL,

        smm_change_note NVARCHAR(MAX) NULL,

        tms_state_note NVARCHAR(MAX) NULL,

        tms_change_note NVARCHAR(MAX) NULL,

        traceability_note NVARCHAR(MAX) NULL,

        data_quality_note NVARCHAR(MAX) NULL,

        source_type NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Team_Play_History_source_type
            DEFAULT N'human_annotated',

        extraction_method NVARCHAR(50) NULL,

        review_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Team_Play_History_review_status
            DEFAULT N'draft',

        include_in_analysis BIT NOT NULL
            CONSTRAINT DF_Team_Play_History_include_in_analysis
            DEFAULT 1,

        exclusion_reason NVARCHAR(MAX) NULL,

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Team_Play_History_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Team_Play_History_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_Team_Play_History_Team
            FOREIGN KEY (team_id)
            REFERENCES dbo.Team(team_id),

        CONSTRAINT FK_Team_Play_History_TRPG_Session
            FOREIGN KEY (session_id)
            REFERENCES dbo.TRPG_Session(session_id),

        CONSTRAINT FK_Team_Play_History_Scene
            FOREIGN KEY (scene_id)
            REFERENCES dbo.Scene(scene_id),

        CONSTRAINT FK_Team_Play_History_Start_Utterance
            FOREIGN KEY (start_utterance_id)
            REFERENCES dbo.Utterance(utterance_id),

        CONSTRAINT FK_Team_Play_History_End_Utterance
            FOREIGN KEY (end_utterance_id)
            REFERENCES dbo.Utterance(utterance_id),

        CONSTRAINT FK_Team_Play_History_Plot_Event
            FOREIGN KEY (related_plot_event_id)
            REFERENCES dbo.Plot_Event(plot_event_id),

        CONSTRAINT FK_Team_Play_History_Decision_Log
            FOREIGN KEY (related_decision_id)
            REFERENCES dbo.Decision_Log(decision_id),

        CONSTRAINT FK_Team_Play_History_Knowledge_Retrieval_Log
            FOREIGN KEY (related_retrieval_id)
            REFERENCES dbo.Knowledge_Retrieval_Log(retrieval_id),

        CONSTRAINT FK_Team_Play_History_Event_Causal_Link
            FOREIGN KEY (related_causal_link_id)
            REFERENCES dbo.Event_Causal_Link(causal_link_id),

        CONSTRAINT FK_Team_Play_History_World_Setting
            FOREIGN KEY (main_world_setting_id)
            REFERENCES dbo.World_Setting(world_setting_id),

        CONSTRAINT FK_Team_Play_History_Item
            FOREIGN KEY (main_item_id)
            REFERENCES dbo.Item(item_id),

        CONSTRAINT FK_Team_Play_History_NPC
            FOREIGN KEY (main_npc_id)
            REFERENCES dbo.NPC(npc_id),

        CONSTRAINT UQ_Team_Play_History_Team_Code
            UNIQUE (team_id, history_code),

        CONSTRAINT UQ_Team_Play_History_Team_No
            UNIQUE (team_id, history_no),

        CONSTRAINT CK_Team_Play_History_Code_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(history_code))) > 0),

        CONSTRAINT CK_Team_Play_History_Title_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(history_title))) > 0),

        CONSTRAINT CK_Team_Play_History_No
            CHECK (history_no >= 1),

        CONSTRAINT CK_Team_Play_History_Level
            CHECK (history_level IN (
                N'team',
                N'session',
                N'scene',
                N'event',
                N'decision',
                N'retrieval',
                N'other'
            )),

        CONSTRAINT CK_Team_Play_History_Type
            CHECK (history_type IN (
                N'mission_progress',
                N'character_development',
                N'worldbuilding_progress',
                N'conflict_development',
                N'consensus_development',
                N'knowledge_sharing',
                N'database_use',
                N'rule_use',
                N'narrative_progress',
                N'creation_material',
                N'team_interaction',
                N'other'
            )),

        CONSTRAINT CK_Team_Play_History_Time_Session_Range
            CHECK (
                time_scope_start_session_no IS NULL
                OR time_scope_end_session_no IS NULL
                OR time_scope_start_session_no <= time_scope_end_session_no
            ),

        CONSTRAINT CK_Team_Play_History_Time_Scene_Range
            CHECK (
                time_scope_start_scene_no IS NULL
                OR time_scope_end_scene_no IS NULL
                OR time_scope_start_scene_no <= time_scope_end_scene_no
            ),

        CONSTRAINT CK_Team_Play_History_Start_Session_No
            CHECK (
                time_scope_start_session_no IS NULL
                OR time_scope_start_session_no >= 1
            ),

        CONSTRAINT CK_Team_Play_History_End_Session_No
            CHECK (
                time_scope_end_session_no IS NULL
                OR time_scope_end_session_no >= 1
            ),

        CONSTRAINT CK_Team_Play_History_Start_Scene_No
            CHECK (
                time_scope_start_scene_no IS NULL
                OR time_scope_start_scene_no >= 1
            ),

        CONSTRAINT CK_Team_Play_History_End_Scene_No
            CHECK (
                time_scope_end_scene_no IS NULL
                OR time_scope_end_scene_no >= 1
            ),

        CONSTRAINT CK_Team_Play_History_Utterance_Range
            CHECK (
                start_utterance_id IS NULL
                OR end_utterance_id IS NULL
                OR start_utterance_id <= end_utterance_id
            ),

        CONSTRAINT CK_Team_Play_History_Source_Type
            CHECK (source_type IN (
                N'ai_extracted',
                N'ai_summarized',
                N'human_annotated',
                N'human_modified',
                N'transcript_extracted',
                N'database_imported',
                N'system_generated',
                N'unknown'
            )),

        CONSTRAINT CK_Team_Play_History_Extraction_Method
            CHECK (
                extraction_method IS NULL
                OR extraction_method IN (
                    N'manual',
                    N'ai',
                    N'rule_based',
                    N'hybrid',
                    N'imported',
                    N'system',
                    N'unknown'
                )
            ),

        CONSTRAINT CK_Team_Play_History_Review_Status
            CHECK (review_status IN (
                N'draft',
                N'in_review',
                N'reviewed',
                N'verified',
                N'excluded'
            )),

        CONSTRAINT CK_Team_Play_History_Include_Exclusion
            CHECK (
                include_in_analysis = 1
                OR exclusion_reason IS NOT NULL
            )
    );
END;
GO