USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.Knowledge_Retrieval_Log', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Knowledge_Retrieval_Log
    (
        retrieval_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Knowledge_Retrieval_Log PRIMARY KEY,

        session_id INT NOT NULL,

        scene_id INT NULL,

        retrieval_code NVARCHAR(80) NOT NULL,

        retrieval_no INT NOT NULL,

        retrieval_type NVARCHAR(50) NOT NULL,

        retrieval_purpose NVARCHAR(100) NULL,

        query_initiator_member_id INT NULL,

        query_initiator_character_id INT NULL,

        query_initiator_role NVARCHAR(50) NULL,

        source_utterance_id BIGINT NULL,

        query_start_utterance_id BIGINT NULL,

        query_end_utterance_id BIGINT NULL,

        related_decision_id BIGINT NULL,

        related_plot_event_id BIGINT NULL,

        related_causal_link_id BIGINT NULL,

        related_rule_id INT NULL,

        related_world_setting_id INT NULL,

        related_item_id INT NULL,

        retrieval_system NVARCHAR(100) NULL,

        retrieval_source_type NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Knowledge_Retrieval_Log_retrieval_source_type
            DEFAULT N'database',

        query_text_raw NVARCHAR(MAX) NULL,

        query_text_clean NVARCHAR(MAX) NULL,

        query_text_verified NVARCHAR(MAX) NULL,

        search_keyword NVARCHAR(500) NULL,

        sql_query_text NVARCHAR(MAX) NULL,

        query_result_raw NVARCHAR(MAX) NULL,

        query_result_clean NVARCHAR(MAX) NULL,

        query_result_verified NVARCHAR(MAX) NULL,

        result_summary NVARCHAR(MAX) NULL,

        result_used_summary NVARCHAR(MAX) NULL,

        retrieval_success BIT NOT NULL
            CONSTRAINT DF_Knowledge_Retrieval_Log_retrieval_success
            DEFAULT 0,

        retrieval_success_level NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Knowledge_Retrieval_Log_retrieval_success_level
            DEFAULT N'unknown',

        query_duration_sec DECIMAL(10,2) NULL,

        result_count INT NULL,

        was_result_used_in_decision BIT NOT NULL
            CONSTRAINT DF_Knowledge_Retrieval_Log_was_result_used_in_decision
            DEFAULT 0,

        was_result_used_in_event BIT NOT NULL
            CONSTRAINT DF_Knowledge_Retrieval_Log_was_result_used_in_event
            DEFAULT 0,

        knowledge_domain NVARCHAR(100) NULL,

        tms_role NVARCHAR(100) NULL,

        smm_relevance_note NVARCHAR(MAX) NULL,

        tms_relevance_note NVARCHAR(MAX) NULL,

        traceability_note NVARCHAR(MAX) NULL,

        data_quality_note NVARCHAR(MAX) NULL,

        source_type NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Knowledge_Retrieval_Log_source_type
            DEFAULT N'utterance_extracted',

        extraction_method NVARCHAR(50) NULL,

        review_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Knowledge_Retrieval_Log_review_status
            DEFAULT N'draft',

        include_in_analysis BIT NOT NULL
            CONSTRAINT DF_Knowledge_Retrieval_Log_include_in_analysis
            DEFAULT 1,

        exclusion_reason NVARCHAR(MAX) NULL,

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Knowledge_Retrieval_Log_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Knowledge_Retrieval_Log_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_Knowledge_Retrieval_Log_TRPG_Session
            FOREIGN KEY (session_id)
            REFERENCES dbo.TRPG_Session(session_id),

        CONSTRAINT FK_Knowledge_Retrieval_Log_Scene
            FOREIGN KEY (scene_id)
            REFERENCES dbo.Scene(scene_id),

        CONSTRAINT FK_Knowledge_Retrieval_Log_Initiator_Team_Member
            FOREIGN KEY (query_initiator_member_id)
            REFERENCES dbo.Team_Member(team_member_id),

        CONSTRAINT FK_Knowledge_Retrieval_Log_Initiator_Player_Character
            FOREIGN KEY (query_initiator_character_id)
            REFERENCES dbo.Player_Character(character_id),

        CONSTRAINT FK_Knowledge_Retrieval_Log_Source_Utterance
            FOREIGN KEY (source_utterance_id)
            REFERENCES dbo.Utterance(utterance_id),

        CONSTRAINT FK_Knowledge_Retrieval_Log_Query_Start_Utterance
            FOREIGN KEY (query_start_utterance_id)
            REFERENCES dbo.Utterance(utterance_id),

        CONSTRAINT FK_Knowledge_Retrieval_Log_Query_End_Utterance
            FOREIGN KEY (query_end_utterance_id)
            REFERENCES dbo.Utterance(utterance_id),

        CONSTRAINT FK_Knowledge_Retrieval_Log_Decision_Log
            FOREIGN KEY (related_decision_id)
            REFERENCES dbo.Decision_Log(decision_id),

        CONSTRAINT FK_Knowledge_Retrieval_Log_Plot_Event
            FOREIGN KEY (related_plot_event_id)
            REFERENCES dbo.Plot_Event(plot_event_id),

        CONSTRAINT FK_Knowledge_Retrieval_Log_Event_Causal_Link
            FOREIGN KEY (related_causal_link_id)
            REFERENCES dbo.Event_Causal_Link(causal_link_id),

        CONSTRAINT FK_Knowledge_Retrieval_Log_Game_Rule
            FOREIGN KEY (related_rule_id)
            REFERENCES dbo.Game_Rule(rule_id),

        CONSTRAINT FK_Knowledge_Retrieval_Log_World_Setting
            FOREIGN KEY (related_world_setting_id)
            REFERENCES dbo.World_Setting(world_setting_id),

        CONSTRAINT FK_Knowledge_Retrieval_Log_Item
            FOREIGN KEY (related_item_id)
            REFERENCES dbo.Item(item_id),

        CONSTRAINT UQ_Knowledge_Retrieval_Log_Session_Code
            UNIQUE (session_id, retrieval_code),

        CONSTRAINT UQ_Knowledge_Retrieval_Log_Session_No
            UNIQUE (session_id, retrieval_no),

        CONSTRAINT CK_Knowledge_Retrieval_Log_Code_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(retrieval_code))) > 0),

        CONSTRAINT CK_Knowledge_Retrieval_Log_No
            CHECK (retrieval_no >= 1),

        CONSTRAINT CK_Knowledge_Retrieval_Log_Type
            CHECK (retrieval_type IN (
                N'rule_lookup',
                N'world_setting_lookup',
                N'item_lookup',
                N'npc_lookup',
                N'character_lookup',
                N'event_lookup',
                N'decision_lookup',
                N'causal_lookup',
                N'transcript_lookup',
                N'ai_summary_lookup',
                N'database_query',
                N'manual_lookup',
                N'other'
            )),

        CONSTRAINT CK_Knowledge_Retrieval_Log_Initiator_Role
            CHECK (
                query_initiator_role IS NULL
                OR query_initiator_role IN (
                    N'GM',
                    N'PL',
                    N'PC',
                    N'Observer',
                    N'Researcher',
                    N'unknown'
                )
            ),

        CONSTRAINT CK_Knowledge_Retrieval_Log_Initiator_Only_One
            CHECK (
                (
                    CASE WHEN query_initiator_member_id IS NULL THEN 0 ELSE 1 END
                    + CASE WHEN query_initiator_character_id IS NULL THEN 0 ELSE 1 END
                ) <= 1
            ),

        CONSTRAINT CK_Knowledge_Retrieval_Log_Source_Type
            CHECK (retrieval_source_type IN (
                N'database',
                N'rulebook',
                N'world_setting',
                N'character_sheet',
                N'gm_note',
                N'transcript',
                N'ai_summary',
                N'human_memory',
                N'web',
                N'unknown'
            )),

        CONSTRAINT CK_Knowledge_Retrieval_Log_Utterance_Range
            CHECK (
                query_start_utterance_id IS NULL
                OR query_end_utterance_id IS NULL
                OR query_start_utterance_id <= query_end_utterance_id
            ),

        CONSTRAINT CK_Knowledge_Retrieval_Log_Duration
            CHECK (
                query_duration_sec IS NULL
                OR query_duration_sec >= 0
            ),

        CONSTRAINT CK_Knowledge_Retrieval_Log_Result_Count
            CHECK (
                result_count IS NULL
                OR result_count >= 0
            ),

        CONSTRAINT CK_Knowledge_Retrieval_Log_Success_Level
            CHECK (retrieval_success_level IN (
                N'none',
                N'partial',
                N'full',
                N'failed',
                N'unknown'
            )),

        CONSTRAINT CK_Knowledge_Retrieval_Log_Source_Origin
            CHECK (source_type IN (
                N'utterance_extracted',
                N'ai_extracted',
                N'ai_summarized',
                N'human_annotated',
                N'human_modified',
                N'system_log',
                N'database_imported',
                N'unknown'
            )),

        CONSTRAINT CK_Knowledge_Retrieval_Log_Extraction_Method
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

        CONSTRAINT CK_Knowledge_Retrieval_Log_Review_Status
            CHECK (review_status IN (
                N'draft',
                N'in_review',
                N'reviewed',
                N'verified',
                N'excluded'
            )),

        CONSTRAINT CK_Knowledge_Retrieval_Log_Include_Exclusion
            CHECK (
                include_in_analysis = 1
                OR exclusion_reason IS NOT NULL
            ),

        CONSTRAINT CK_Knowledge_Retrieval_Log_Success_Consistency
            CHECK (
                (retrieval_success = 1 AND retrieval_success_level IN (N'partial', N'full'))
                OR
                (retrieval_success = 0 AND retrieval_success_level IN (N'none', N'failed', N'unknown'))
            )
    );
END;
GO