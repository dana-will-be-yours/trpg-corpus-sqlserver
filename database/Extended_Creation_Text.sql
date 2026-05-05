USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.Extended_Creation_Text', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Extended_Creation_Text
    (
        creation_text_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Extended_Creation_Text PRIMARY KEY,

        team_id INT NOT NULL,

        session_id INT NULL,

        scene_id INT NULL,

        creation_code NVARCHAR(80) NOT NULL,

        creation_no INT NOT NULL,

        creation_title NVARCHAR(250) NOT NULL,

        creation_type NVARCHAR(50) NOT NULL,

        creation_stage NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Extended_Creation_Text_creation_stage
            DEFAULT N'draft',

        authoring_mode NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Extended_Creation_Text_authoring_mode
            DEFAULT N'team',

        author_member_id INT NULL,

        related_play_history_id BIGINT NULL,

        related_plot_event_id BIGINT NULL,

        related_decision_id BIGINT NULL,

        related_retrieval_id BIGINT NULL,

        related_world_setting_id INT NULL,

        related_item_id INT NULL,

        related_npc_id INT NULL,

        source_start_utterance_id BIGINT NULL,

        source_end_utterance_id BIGINT NULL,

        source_material_note NVARCHAR(MAX) NULL,

        creation_text_raw NVARCHAR(MAX) NULL,

        creation_text_clean NVARCHAR(MAX) NULL,

        creation_text_verified NVARCHAR(MAX) NULL,

        creation_summary NVARCHAR(MAX) NULL,

        theme_summary NVARCHAR(MAX) NULL,

        plot_summary NVARCHAR(MAX) NULL,

        character_summary NVARCHAR(MAX) NULL,

        worldbuilding_summary NVARCHAR(MAX) NULL,

        conflict_summary NVARCHAR(MAX) NULL,

        decision_trace_summary NVARCHAR(MAX) NULL,

        knowledge_trace_summary NVARCHAR(MAX) NULL,

        trpg_source_trace_summary NVARCHAR(MAX) NULL,

        narrative_coherence_note NVARCHAR(MAX) NULL,

        originality_note NVARCHAR(MAX) NULL,

        completeness_note NVARCHAR(MAX) NULL,

        smm_relevance_note NVARCHAR(MAX) NULL,

        tms_relevance_note NVARCHAR(MAX) NULL,

        evaluation_note NVARCHAR(MAX) NULL,

        word_count INT NULL,

        version_no INT NOT NULL
            CONSTRAINT DF_Extended_Creation_Text_version_no
            DEFAULT 1,

        is_final_version BIT NOT NULL
            CONSTRAINT DF_Extended_Creation_Text_is_final_version
            DEFAULT 0,

        source_type NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Extended_Creation_Text_source_type
            DEFAULT N'human_created',

        extraction_method NVARCHAR(50) NULL,

        review_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Extended_Creation_Text_review_status
            DEFAULT N'draft',

        include_in_analysis BIT NOT NULL
            CONSTRAINT DF_Extended_Creation_Text_include_in_analysis
            DEFAULT 1,

        exclusion_reason NVARCHAR(MAX) NULL,

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Extended_Creation_Text_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Extended_Creation_Text_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_Extended_Creation_Text_Team
            FOREIGN KEY (team_id)
            REFERENCES dbo.Team(team_id),

        CONSTRAINT FK_Extended_Creation_Text_TRPG_Session
            FOREIGN KEY (session_id)
            REFERENCES dbo.TRPG_Session(session_id),

        CONSTRAINT FK_Extended_Creation_Text_Scene
            FOREIGN KEY (scene_id)
            REFERENCES dbo.Scene(scene_id),

        CONSTRAINT FK_Extended_Creation_Text_Author_Team_Member
            FOREIGN KEY (author_member_id)
            REFERENCES dbo.Team_Member(team_member_id),

        CONSTRAINT FK_Extended_Creation_Text_Team_Play_History
            FOREIGN KEY (related_play_history_id)
            REFERENCES dbo.Team_Play_History(play_history_id),

        CONSTRAINT FK_Extended_Creation_Text_Plot_Event
            FOREIGN KEY (related_plot_event_id)
            REFERENCES dbo.Plot_Event(plot_event_id),

        CONSTRAINT FK_Extended_Creation_Text_Decision_Log
            FOREIGN KEY (related_decision_id)
            REFERENCES dbo.Decision_Log(decision_id),

        CONSTRAINT FK_Extended_Creation_Text_Knowledge_Retrieval_Log
            FOREIGN KEY (related_retrieval_id)
            REFERENCES dbo.Knowledge_Retrieval_Log(retrieval_id),

        CONSTRAINT FK_Extended_Creation_Text_World_Setting
            FOREIGN KEY (related_world_setting_id)
            REFERENCES dbo.World_Setting(world_setting_id),

        CONSTRAINT FK_Extended_Creation_Text_Item
            FOREIGN KEY (related_item_id)
            REFERENCES dbo.Item(item_id),

        CONSTRAINT FK_Extended_Creation_Text_NPC
            FOREIGN KEY (related_npc_id)
            REFERENCES dbo.NPC(npc_id),

        CONSTRAINT FK_Extended_Creation_Text_Source_Start_Utterance
            FOREIGN KEY (source_start_utterance_id)
            REFERENCES dbo.Utterance(utterance_id),

        CONSTRAINT FK_Extended_Creation_Text_Source_End_Utterance
            FOREIGN KEY (source_end_utterance_id)
            REFERENCES dbo.Utterance(utterance_id),

        CONSTRAINT UQ_Extended_Creation_Text_Team_Code
            UNIQUE (team_id, creation_code),

        CONSTRAINT UQ_Extended_Creation_Text_Team_No_Version
            UNIQUE (team_id, creation_no, version_no),

        CONSTRAINT CK_Extended_Creation_Text_Code_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(creation_code))) > 0),

        CONSTRAINT CK_Extended_Creation_Text_Title_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(creation_title))) > 0),

        CONSTRAINT CK_Extended_Creation_Text_No
            CHECK (creation_no >= 1),

        CONSTRAINT CK_Extended_Creation_Text_Type
            CHECK (creation_type IN (
                N'short_story',
                N'novel_excerpt',
                N'worldbuilding_text',
                N'character_story',
                N'ip_proposal',
                N'game_proposal',
                N'story_outline',
                N'script',
                N'campaign_summary',
                N'creative_brief',
                N'other'
            )),

        CONSTRAINT CK_Extended_Creation_Text_Stage
            CHECK (creation_stage IN (
                N'draft',
                N'revised',
                N'cleaned',
                N'verified',
                N'final',
                N'excluded'
            )),

        CONSTRAINT CK_Extended_Creation_Text_Authoring_Mode
            CHECK (authoring_mode IN (
                N'individual',
                N'pair',
                N'team',
                N'gm',
                N'ai_assisted',
                N'unknown'
            )),

        CONSTRAINT CK_Extended_Creation_Text_Utterance_Range
            CHECK (
                source_start_utterance_id IS NULL
                OR source_end_utterance_id IS NULL
                OR source_start_utterance_id <= source_end_utterance_id
            ),

        CONSTRAINT CK_Extended_Creation_Text_Word_Count
            CHECK (
                word_count IS NULL
                OR word_count >= 0
            ),

        CONSTRAINT CK_Extended_Creation_Text_Version_No
            CHECK (version_no >= 1),

        CONSTRAINT CK_Extended_Creation_Text_Source_Type
            CHECK (source_type IN (
                N'human_created',
                N'ai_generated',
                N'ai_assisted',
                N'human_modified',
                N'trpg_derived',
                N'database_imported',
                N'unknown'
            )),

        CONSTRAINT CK_Extended_Creation_Text_Extraction_Method
            CHECK (
                extraction_method IS NULL
                OR extraction_method IN (
                    N'manual',
                    N'ai',
                    N'hybrid',
                    N'imported',
                    N'unknown'
                )
            ),

        CONSTRAINT CK_Extended_Creation_Text_Review_Status
            CHECK (review_status IN (
                N'draft',
                N'in_review',
                N'reviewed',
                N'verified',
                N'excluded'
            )),

        CONSTRAINT CK_Extended_Creation_Text_Include_Exclusion
            CHECK (
                include_in_analysis = 1
                OR exclusion_reason IS NOT NULL
            )
    );
END;
GO