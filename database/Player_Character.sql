USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.Player_Character', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Player_Character
    (
        character_id INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Player_Character PRIMARY KEY,

        team_member_id INT NOT NULL,

        character_code NVARCHAR(50) NOT NULL,

        character_name NVARCHAR(100) NOT NULL,

        character_type NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Player_Character_character_type
            DEFAULT N'player_character',

        archetype NVARCHAR(100) NULL,

        race_or_species NVARCHAR(100) NULL,

        class_or_profession NVARCHAR(100) NULL,

        faction NVARCHAR(100) NULL,

        background_story_raw NVARCHAR(MAX) NULL,

        background_story_clean NVARCHAR(MAX) NULL,

        background_story_verified NVARCHAR(MAX) NULL,

        personality_note NVARCHAR(MAX) NULL,

        motivation_note NVARCHAR(MAX) NULL,

        relationship_note NVARCHAR(MAX) NULL,

        ability_note NVARCHAR(MAX) NULL,

        item_note NVARCHAR(MAX) NULL,

        narrative_function NVARCHAR(100) NULL,

        is_active BIT NOT NULL
            CONSTRAINT DF_Player_Character_is_active
            DEFAULT 1,

        character_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Player_Character_character_status
            DEFAULT N'draft',

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Player_Character_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Player_Character_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_Player_Character_Team_Member
            FOREIGN KEY (team_member_id)
            REFERENCES dbo.Team_Member(team_member_id),

        CONSTRAINT UQ_Player_Character_TeamMember_CharacterCode
            UNIQUE (team_member_id, character_code),

        CONSTRAINT CK_Player_Character_Code_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(character_code))) > 0),

        CONSTRAINT CK_Player_Character_Name_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(character_name))) > 0),

        CONSTRAINT CK_Player_Character_Type
            CHECK (character_type IN (
                N'player_character',
                N'sub_character',
                N'temporary_character'
            )),

        CONSTRAINT CK_Player_Character_Status
            CHECK (character_status IN (
                N'draft',
                N'cleaned',
                N'verified',
                N'in_play',
                N'retired',
                N'excluded'
            ))
    );
END;
GO