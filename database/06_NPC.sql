USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.NPC', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.NPC
    (
        npc_id INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_NPC PRIMARY KEY,

        team_id INT NOT NULL,

        npc_code NVARCHAR(50) NOT NULL,

        npc_name NVARCHAR(100) NOT NULL,

        npc_type NVARCHAR(50) NOT NULL
            CONSTRAINT DF_NPC_npc_type
            DEFAULT N'npc',

        controller_member_id INT NULL,

        faction NVARCHAR(100) NULL,

        location_name NVARCHAR(100) NULL,

        role_in_story NVARCHAR(100) NULL,

        occupation_or_identity NVARCHAR(100) NULL,

        personality_note NVARCHAR(MAX) NULL,

        motivation_note NVARCHAR(MAX) NULL,

        relationship_note NVARCHAR(MAX) NULL,

        knowledge_note NVARCHAR(MAX) NULL,

        ability_note NVARCHAR(MAX) NULL,

        item_note NVARCHAR(MAX) NULL,

        first_appearance_session_no INT NULL,

        first_appearance_scene_no INT NULL,

        npc_description_raw NVARCHAR(MAX) NULL,

        npc_description_clean NVARCHAR(MAX) NULL,

        npc_description_verified NVARCHAR(MAX) NULL,

        is_recurring BIT NOT NULL
            CONSTRAINT DF_NPC_is_recurring
            DEFAULT 0,

        is_hostile BIT NULL,

        is_alive BIT NULL,

        npc_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_NPC_npc_status
            DEFAULT N'draft',

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_NPC_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_NPC_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_NPC_Team
            FOREIGN KEY (team_id)
            REFERENCES dbo.Team(team_id),

        CONSTRAINT FK_NPC_Controller_Team_Member
            FOREIGN KEY (controller_member_id)
            REFERENCES dbo.Team_Member(team_member_id),

        CONSTRAINT UQ_NPC_Team_NpcCode
            UNIQUE (team_id, npc_code),

        CONSTRAINT CK_NPC_Code_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(npc_code))) > 0),

        CONSTRAINT CK_NPC_Name_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(npc_name))) > 0),

        CONSTRAINT CK_NPC_Type
            CHECK (npc_type IN (
                N'npc',
                N'major_npc',
                N'minor_npc',
                N'antagonist',
                N'ally',
                N'monster',
                N'organization_agent',
                N'environment_voice',
                N'unknown'
            )),

        CONSTRAINT CK_NPC_First_Appearance_Session_No
            CHECK (
                first_appearance_session_no IS NULL
                OR first_appearance_session_no >= 1
            ),

        CONSTRAINT CK_NPC_First_Appearance_Scene_No
            CHECK (
                first_appearance_scene_no IS NULL
                OR first_appearance_scene_no >= 1
            ),

        CONSTRAINT CK_NPC_Status
            CHECK (npc_status IN (
                N'draft',
                N'cleaned',
                N'verified',
                N'in_play',
                N'inactive',
                N'dead',
                N'unknown',
                N'excluded'
            ))
    );
END;
GO