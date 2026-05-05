USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.World_Setting', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.World_Setting
    (
        world_setting_id INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_World_Setting PRIMARY KEY,

        project_id INT NOT NULL,

        team_id INT NULL,

        setting_code NVARCHAR(50) NOT NULL,

        setting_name NVARCHAR(200) NOT NULL,

        setting_category NVARCHAR(50) NOT NULL,

        setting_subcategory NVARCHAR(100) NULL,

        parent_world_setting_id INT NULL,

        source_type NVARCHAR(50) NOT NULL
            CONSTRAINT DF_World_Setting_source_type
            DEFAULT N'human_created',

        source_reference NVARCHAR(200) NULL,

        introduced_session_no INT NULL,

        introduced_scene_no INT NULL,

        introduced_turn_no INT NULL,

        setting_description_raw NVARCHAR(MAX) NULL,

        setting_description_clean NVARCHAR(MAX) NULL,

        setting_description_verified NVARCHAR(MAX) NULL,

        setting_summary NVARCHAR(MAX) NULL,

        narrative_function NVARCHAR(200) NULL,

        related_rule_code NVARCHAR(50) NULL,

        is_team_specific BIT NOT NULL
            CONSTRAINT DF_World_Setting_is_team_specific
            DEFAULT 1,

        is_canon BIT NOT NULL
            CONSTRAINT DF_World_Setting_is_canon
            DEFAULT 0,

        is_active BIT NOT NULL
            CONSTRAINT DF_World_Setting_is_active
            DEFAULT 1,

        setting_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_World_Setting_setting_status
            DEFAULT N'draft',

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_World_Setting_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_World_Setting_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_World_Setting_Research_Project
            FOREIGN KEY (project_id)
            REFERENCES dbo.Research_Project(project_id),

        CONSTRAINT FK_World_Setting_Team
            FOREIGN KEY (team_id)
            REFERENCES dbo.Team(team_id),

        CONSTRAINT FK_World_Setting_Parent
            FOREIGN KEY (parent_world_setting_id)
            REFERENCES dbo.World_Setting(world_setting_id),

        CONSTRAINT UQ_World_Setting_Project_Team_Code
            UNIQUE (project_id, team_id, setting_code),

        CONSTRAINT CK_World_Setting_Code_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(setting_code))) > 0),

        CONSTRAINT CK_World_Setting_Name_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(setting_name))) > 0),

        CONSTRAINT CK_World_Setting_Category
            CHECK (setting_category IN (
                N'world',
                N'location',
                N'region',
                N'faction',
                N'organization',
                N'history',
                N'culture',
                N'religion',
                N'politics',
                N'economy',
                N'technology',
                N'magic',
                N'ecology',
                N'law',
                N'conflict',
                N'legend',
                N'mission_background',
                N'other'
            )),

        CONSTRAINT CK_World_Setting_Source_Type
            CHECK (source_type IN (
                N'gm_prepared',
                N'player_created',
                N'human_created',
                N'ai_generated',
                N'ai_summarized',
                N'human_modified',
                N'transcript_extracted',
                N'database_imported',
                N'unknown'
            )),

        CONSTRAINT CK_World_Setting_Introduced_Session_No
            CHECK (
                introduced_session_no IS NULL
                OR introduced_session_no >= 1
            ),

        CONSTRAINT CK_World_Setting_Introduced_Scene_No
            CHECK (
                introduced_scene_no IS NULL
                OR introduced_scene_no >= 1
            ),

        CONSTRAINT CK_World_Setting_Introduced_Turn_No
            CHECK (
                introduced_turn_no IS NULL
                OR introduced_turn_no >= 1
            ),

        CONSTRAINT CK_World_Setting_Team_Specific
            CHECK (
                (is_team_specific = 1 AND team_id IS NOT NULL)
                OR (is_team_specific = 0)
            ),

        CONSTRAINT CK_World_Setting_Status
            CHECK (setting_status IN (
                N'draft',
                N'cleaned',
                N'verified',
                N'canon',
                N'contradicted',
                N'inactive',
                N'excluded'
            ))
    );
END;
GO