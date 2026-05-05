USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.Utterance', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Utterance
    (
        utterance_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Utterance PRIMARY KEY,

        session_id INT NOT NULL,

        scene_id INT NULL,

        turn_no INT NOT NULL,

        sub_turn_no INT NULL,

        utterance_code NVARCHAR(80) NOT NULL,

        speaker_type NVARCHAR(50) NOT NULL,

        speaker_member_id INT NULL,

        speaker_character_id INT NULL,

        speaker_npc_id INT NULL,

        speaker_label_raw NVARCHAR(100) NULL,

        utterance_function NVARCHAR(50) NOT NULL,

        is_in_character BIT NOT NULL,

        is_gm_narration BIT NOT NULL
            CONSTRAINT DF_Utterance_is_gm_narration
            DEFAULT 0,

        is_rule_related BIT NOT NULL
            CONSTRAINT DF_Utterance_is_rule_related
            DEFAULT 0,

        is_decision_related BIT NOT NULL
            CONSTRAINT DF_Utterance_is_decision_related
            DEFAULT 0,

        is_knowledge_related BIT NOT NULL
            CONSTRAINT DF_Utterance_is_knowledge_related
            DEFAULT 0,

        start_timecode NVARCHAR(20) NULL,

        end_timecode NVARCHAR(20) NULL,

        duration_sec DECIMAL(10,2) NULL,

        utterance_text_raw NVARCHAR(MAX) NOT NULL,

        utterance_text_clean NVARCHAR(MAX) NULL,

        utterance_text_verified NVARCHAR(MAX) NULL,

        language_code NVARCHAR(20) NOT NULL
            CONSTRAINT DF_Utterance_language_code
            DEFAULT N'zh-TW',

        emotion_label NVARCHAR(50) NULL,

        interaction_target_type NVARCHAR(50) NULL,

        interaction_target_member_id INT NULL,

        interaction_target_character_id INT NULL,

        interaction_target_npc_id INT NULL,

        related_rule_id INT NULL,

        related_world_setting_id INT NULL,

        related_item_id INT NULL,

        ai_summary NVARCHAR(MAX) NULL,

        ai_annotation_json NVARCHAR(MAX) NULL,

        human_annotation_note NVARCHAR(MAX) NULL,

        transcription_confidence DECIMAL(5,4) NULL,

        review_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Utterance_review_status
            DEFAULT N'draft',

        include_in_analysis BIT NOT NULL
            CONSTRAINT DF_Utterance_include_in_analysis
            DEFAULT 1,

        exclusion_reason NVARCHAR(MAX) NULL,

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Utterance_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Utterance_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_Utterance_TRPG_Session
            FOREIGN KEY (session_id)
            REFERENCES dbo.TRPG_Session(session_id),

        CONSTRAINT FK_Utterance_Scene
            FOREIGN KEY (scene_id)
            REFERENCES dbo.Scene(scene_id),

        CONSTRAINT FK_Utterance_Speaker_Team_Member
            FOREIGN KEY (speaker_member_id)
            REFERENCES dbo.Team_Member(team_member_id),

        CONSTRAINT FK_Utterance_Speaker_Player_Character
            FOREIGN KEY (speaker_character_id)
            REFERENCES dbo.Player_Character(character_id),

        CONSTRAINT FK_Utterance_Speaker_NPC
            FOREIGN KEY (speaker_npc_id)
            REFERENCES dbo.NPC(npc_id),

        CONSTRAINT FK_Utterance_Target_Team_Member
            FOREIGN KEY (interaction_target_member_id)
            REFERENCES dbo.Team_Member(team_member_id),

        CONSTRAINT FK_Utterance_Target_Player_Character
            FOREIGN KEY (interaction_target_character_id)
            REFERENCES dbo.Player_Character(character_id),

        CONSTRAINT FK_Utterance_Target_NPC
            FOREIGN KEY (interaction_target_npc_id)
            REFERENCES dbo.NPC(npc_id),

        CONSTRAINT FK_Utterance_Game_Rule
            FOREIGN KEY (related_rule_id)
            REFERENCES dbo.Game_Rule(rule_id),

        CONSTRAINT FK_Utterance_World_Setting
            FOREIGN KEY (related_world_setting_id)
            REFERENCES dbo.World_Setting(world_setting_id),

        CONSTRAINT FK_Utterance_Item
            FOREIGN KEY (related_item_id)
            REFERENCES dbo.Item(item_id),

        CONSTRAINT UQ_Utterance_Session_TurnNo
            UNIQUE (session_id, turn_no),

        CONSTRAINT UQ_Utterance_Session_Code
            UNIQUE (session_id, utterance_code),

        CONSTRAINT CK_Utterance_Turn_No
            CHECK (turn_no >= 1),

        CONSTRAINT CK_Utterance_Sub_Turn_No
            CHECK (
                sub_turn_no IS NULL
                OR sub_turn_no >= 1
            ),

        CONSTRAINT CK_Utterance_Code_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(utterance_code))) > 0),

        CONSTRAINT CK_Utterance_Speaker_Type
            CHECK (speaker_type IN (
                N'GM',
                N'PL',
                N'PC',
                N'NPC',
                N'Observer',
                N'Researcher'
            )),

        CONSTRAINT CK_Utterance_Function
            CHECK (utterance_function IN (
                N'narration',
                N'dialogue',
                N'action',
                N'rule_check',
                N'decision',
                N'negotiation',
                N'question',
                N'clarification',
                N'conflict',
                N'summary'
            )),

        CONSTRAINT CK_Utterance_Text_Raw_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(utterance_text_raw))) > 0),

        CONSTRAINT CK_Utterance_Duration
            CHECK (
                duration_sec IS NULL
                OR duration_sec >= 0
            ),

        CONSTRAINT CK_Utterance_Transcription_Confidence
            CHECK (
                transcription_confidence IS NULL
                OR transcription_confidence BETWEEN 0 AND 1
            ),

        CONSTRAINT CK_Utterance_Emotion_Label
            CHECK (
                emotion_label IS NULL
                OR emotion_label IN (
                    N'neutral',
                    N'positive',
                    N'negative',
                    N'confused',
                    N'excited',
                    N'tense',
                    N'humorous',
                    N'uncertain',
                    N'other'
                )
            ),

        CONSTRAINT CK_Utterance_Target_Type
            CHECK (
                interaction_target_type IS NULL
                OR interaction_target_type IN (
                    N'team_member',
                    N'player_character',
                    N'npc',
                    N'group',
                    N'system',
                    N'unknown'
                )
            ),

        CONSTRAINT CK_Utterance_Review_Status
            CHECK (review_status IN (
                N'draft',
                N'ai_transcribed',
                N'human_corrected',
                N'cleaned',
                N'verified',
                N'excluded'
            )),

        CONSTRAINT CK_Utterance_Include_Exclusion
            CHECK (
                include_in_analysis = 1
                OR exclusion_reason IS NOT NULL
            ),

        CONSTRAINT CK_Utterance_GM_Narration_Consistency
            CHECK (
                is_gm_narration = 0
                OR (
                    speaker_type = N'GM'
                    AND utterance_function = N'narration'
                )
            ),

        CONSTRAINT CK_Utterance_Rule_Related_Consistency
            CHECK (
                is_rule_related = 0
                OR utterance_function = N'rule_check'
                OR related_rule_id IS NOT NULL
            ),

        CONSTRAINT CK_Utterance_Decision_Related_Consistency
            CHECK (
                is_decision_related = 0
                OR utterance_function IN (
                    N'decision',
                    N'negotiation',
                    N'clarification'
                )
            ),

        CONSTRAINT CK_Utterance_Knowledge_Related_Consistency
            CHECK (
                is_knowledge_related = 0
                OR utterance_function IN (
                    N'question',
                    N'clarification',
                    N'summary'
                )
                OR related_world_setting_id IS NOT NULL
                OR related_item_id IS NOT NULL
            ),

        CONSTRAINT CK_Utterance_Speaker_Reference_By_Type
            CHECK (
                (speaker_type = N'PC' AND speaker_character_id IS NOT NULL)
                OR (speaker_type = N'NPC' AND speaker_npc_id IS NOT NULL)
                OR (speaker_type IN (N'GM', N'PL', N'Observer', N'Researcher') AND speaker_member_id IS NOT NULL)
            ),

        CONSTRAINT CK_Utterance_In_Character_Consistency
            CHECK (
                (speaker_type IN (N'PC', N'NPC') AND is_in_character = 1)
                OR (speaker_type IN (N'GM', N'PL', N'Observer', N'Researcher') AND is_in_character = 0)
            )
    );
END;
GO