USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.Scene', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Scene
    (
        scene_id INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Scene PRIMARY KEY,

        session_id INT NOT NULL,

        scene_code NVARCHAR(50) NOT NULL,

        scene_no INT NOT NULL,

        scene_title NVARCHAR(200) NULL,

        scene_type NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Scene_scene_type
            DEFAULT N'play',

        parent_scene_id INT NULL,

        world_setting_id INT NULL,

        location_name NVARCHAR(200) NULL,

        start_turn_no INT NULL,

        end_turn_no INT NULL,

        start_timecode NVARCHAR(20) NULL,

        end_timecode NVARCHAR(20) NULL,

        estimated_duration_sec INT NULL,

        scene_goal NVARCHAR(MAX) NULL,

        scene_summary_raw NVARCHAR(MAX) NULL,

        scene_summary_clean NVARCHAR(MAX) NULL,

        scene_summary_verified NVARCHAR(MAX) NULL,

        conflict_summary NVARCHAR(MAX) NULL,

        decision_summary NVARCHAR(MAX) NULL,

        knowledge_summary NVARCHAR(MAX) NULL,

        outcome_summary NVARCHAR(MAX) NULL,

        involved_character_note NVARCHAR(MAX) NULL,

        involved_npc_note NVARCHAR(MAX) NULL,

        involved_item_note NVARCHAR(MAX) NULL,

        smm_note NVARCHAR(MAX) NULL,

        tms_note NVARCHAR(MAX) NULL,

        narrative_coherence_note NVARCHAR(MAX) NULL,

        source_type NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Scene_source_type
            DEFAULT N'transcript_extracted',

        extraction_method NVARCHAR(50) NULL,

        review_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Scene_review_status
            DEFAULT N'draft',

        include_in_analysis BIT NOT NULL
            CONSTRAINT DF_Scene_include_in_analysis
            DEFAULT 1,

        exclusion_reason NVARCHAR(MAX) NULL,

        scene_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Scene_scene_status
            DEFAULT N'draft',

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Scene_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Scene_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_Scene_TRPG_Session
            FOREIGN KEY (session_id)
            REFERENCES dbo.TRPG_Session(session_id),

        CONSTRAINT FK_Scene_Parent_Scene
            FOREIGN KEY (parent_scene_id)
            REFERENCES dbo.Scene(scene_id),

        CONSTRAINT FK_Scene_World_Setting
            FOREIGN KEY (world_setting_id)
            REFERENCES dbo.World_Setting(world_setting_id),

        CONSTRAINT UQ_Scene_Session_SceneCode
            UNIQUE (session_id, scene_code),

        CONSTRAINT UQ_Scene_Session_SceneNo
            UNIQUE (session_id, scene_no),

        CONSTRAINT CK_Scene_Code_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(scene_code))) > 0),

        CONSTRAINT CK_Scene_No
            CHECK (scene_no >= 1),

        CONSTRAINT CK_Scene_Type
            CHECK (scene_type IN (
                N'opening',
                N'worldbuilding',
                N'exploration',
                N'social',
                N'combat',
                N'investigation',
                N'rule_check',
                N'planning',
                N'decision',
                N'creation',
                N'debrief',
                N'transition',
                N'play',
                N'other'
            )),

        CONSTRAINT CK_Scene_Turn_Range
            CHECK (
                start_turn_no IS NULL
                OR end_turn_no IS NULL
                OR start_turn_no <= end_turn_no
            ),

        CONSTRAINT CK_Scene_Start_Turn_No
            CHECK (
                start_turn_no IS NULL
                OR start_turn_no >= 1
            ),

        CONSTRAINT CK_Scene_End_Turn_No
            CHECK (
                end_turn_no IS NULL
                OR end_turn_no >= 1
            ),

        CONSTRAINT CK_Scene_Estimated_Duration
            CHECK (
                estimated_duration_sec IS NULL
                OR estimated_duration_sec >= 0
            ),

        CONSTRAINT CK_Scene_Source_Type
            CHECK (source_type IN (
                N'gm_prepared',
                N'human_segmented',
                N'ai_segmented',
                N'ai_summarized',
                N'human_modified',
                N'transcript_extracted',
                N'database_imported',
                N'unknown'
            )),

        CONSTRAINT CK_Scene_Extraction_Method
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

        CONSTRAINT CK_Scene_Review_Status
            CHECK (review_status IN (
                N'draft',
                N'in_review',
                N'reviewed',
                N'verified',
                N'excluded'
            )),

        CONSTRAINT CK_Scene_Include_Exclusion
            CHECK (
                include_in_analysis = 1
                OR exclusion_reason IS NOT NULL
            ),

        CONSTRAINT CK_Scene_Status
            CHECK (scene_status IN (
                N'draft',
                N'cleaned',
                N'verified',
                N'active',
                N'merged',
                N'split',
                N'excluded'
            ))
    );
END;
GO