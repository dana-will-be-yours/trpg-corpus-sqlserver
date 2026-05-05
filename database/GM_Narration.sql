USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.GM_Narration', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.GM_Narration
    (
        gm_narration_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_GM_Narration PRIMARY KEY,

        utterance_id BIGINT NOT NULL,

        session_id INT NOT NULL,

        scene_id INT NULL,

        narration_code NVARCHAR(80) NOT NULL,

        narration_type NVARCHAR(50) NOT NULL,

        narration_function NVARCHAR(50) NOT NULL,

        related_world_setting_id INT NULL,

        related_npc_id INT NULL,

        related_item_id INT NULL,

        related_rule_id INT NULL,

        trigger_event_hint NVARCHAR(MAX) NULL,

        narration_text_raw NVARCHAR(MAX) NOT NULL,

        narration_text_clean NVARCHAR(MAX) NULL,

        narration_text_verified NVARCHAR(MAX) NULL,

        setting_description NVARCHAR(MAX) NULL,

        atmosphere_description NVARCHAR(MAX) NULL,

        sensory_description NVARCHAR(MAX) NULL,

        npc_action_description NVARCHAR(MAX) NULL,

        consequence_description NVARCHAR(MAX) NULL,

        rule_prompt_description NVARCHAR(MAX) NULL,

        player_prompt_description NVARCHAR(MAX) NULL,

        hidden_information_note NVARCHAR(MAX) NULL,

        foreshadowing_note NVARCHAR(MAX) NULL,

        narrative_coherence_note NVARCHAR(MAX) NULL,

        source_type NVARCHAR(50) NOT NULL
            CONSTRAINT DF_GM_Narration_source_type
            DEFAULT N'utterance_extracted',

        extraction_method NVARCHAR(50) NULL,

        review_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_GM_Narration_review_status
            DEFAULT N'draft',

        include_in_analysis BIT NOT NULL
            CONSTRAINT DF_GM_Narration_include_in_analysis
            DEFAULT 1,

        exclusion_reason NVARCHAR(MAX) NULL,

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_GM_Narration_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_GM_Narration_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_GM_Narration_Utterance
            FOREIGN KEY (utterance_id)
            REFERENCES dbo.Utterance(utterance_id),

        CONSTRAINT FK_GM_Narration_TRPG_Session
            FOREIGN KEY (session_id)
            REFERENCES dbo.TRPG_Session(session_id),

        CONSTRAINT FK_GM_Narration_Scene
            FOREIGN KEY (scene_id)
            REFERENCES dbo.Scene(scene_id),

        CONSTRAINT FK_GM_Narration_World_Setting
            FOREIGN KEY (related_world_setting_id)
            REFERENCES dbo.World_Setting(world_setting_id),

        CONSTRAINT FK_GM_Narration_NPC
            FOREIGN KEY (related_npc_id)
            REFERENCES dbo.NPC(npc_id),

        CONSTRAINT FK_GM_Narration_Item
            FOREIGN KEY (related_item_id)
            REFERENCES dbo.Item(item_id),

        CONSTRAINT FK_GM_Narration_Game_Rule
            FOREIGN KEY (related_rule_id)
            REFERENCES dbo.Game_Rule(rule_id),

        CONSTRAINT UQ_GM_Narration_Utterance
            UNIQUE (utterance_id),

        CONSTRAINT UQ_GM_Narration_Session_Code
            UNIQUE (session_id, narration_code),

        CONSTRAINT CK_GM_Narration_Code_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(narration_code))) > 0),

        CONSTRAINT CK_GM_Narration_Text_Raw_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(narration_text_raw))) > 0),

        CONSTRAINT CK_GM_Narration_Type
            CHECK (narration_type IN (
                N'scene_description',
                N'atmosphere',
                N'world_reveal',
                N'npc_action',
                N'event_trigger',
                N'consequence',
                N'rule_prompt',
                N'player_prompt',
                N'transition',
                N'summary',
                N'other'
            )),

        CONSTRAINT CK_GM_Narration_Function
            CHECK (narration_function IN (
                N'establish_scene',
                N'introduce_conflict',
                N'provide_clue',
                N'advance_plot',
                N'resolve_action',
                N'apply_rule',
                N'guide_attention',
                N'create_tension',
                N'transition_scene',
                N'summarize_state',
                N'other'
            )),

        CONSTRAINT CK_GM_Narration_Source_Type
            CHECK (source_type IN (
                N'utterance_extracted',
                N'ai_extracted',
                N'human_annotated',
                N'human_modified',
                N'database_imported',
                N'unknown'
            )),

        CONSTRAINT CK_GM_Narration_Extraction_Method
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

        CONSTRAINT CK_GM_Narration_Review_Status
            CHECK (review_status IN (
                N'draft',
                N'in_review',
                N'reviewed',
                N'verified',
                N'excluded'
            )),

        CONSTRAINT CK_GM_Narration_Include_Exclusion
            CHECK (
                include_in_analysis = 1
                OR exclusion_reason IS NOT NULL
            )
    );
END;
GO