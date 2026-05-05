USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.Game_Rule', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Game_Rule
    (
        rule_id INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Game_Rule PRIMARY KEY,

        project_id INT NOT NULL,

        rule_code NVARCHAR(50) NOT NULL,

        rule_name NVARCHAR(200) NOT NULL,

        rule_category NVARCHAR(50) NOT NULL,

        rule_subcategory NVARCHAR(100) NULL,

        rule_source_type NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Game_Rule_rule_source_type
            DEFAULT N'homebrew',

        source_title NVARCHAR(200) NULL,

        source_page NVARCHAR(50) NULL,

        rule_text_raw NVARCHAR(MAX) NULL,

        rule_text_clean NVARCHAR(MAX) NULL,

        rule_text_verified NVARCHAR(MAX) NULL,

        rule_summary NVARCHAR(MAX) NULL,

        rule_condition NVARCHAR(MAX) NULL,

        rule_effect NVARCHAR(MAX) NULL,

        dice_formula NVARCHAR(100) NULL,

        difficulty_rule NVARCHAR(MAX) NULL,

        success_effect NVARCHAR(MAX) NULL,

        failure_effect NVARCHAR(MAX) NULL,

        applies_to_speaker_type NVARCHAR(50) NULL,

        applies_to_character_type NVARCHAR(50) NULL,

        is_house_rule BIT NOT NULL
            CONSTRAINT DF_Game_Rule_is_house_rule
            DEFAULT 0,

        is_active BIT NOT NULL
            CONSTRAINT DF_Game_Rule_is_active
            DEFAULT 1,

        rule_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Game_Rule_rule_status
            DEFAULT N'draft',

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Game_Rule_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Game_Rule_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_Game_Rule_Research_Project
            FOREIGN KEY (project_id)
            REFERENCES dbo.Research_Project(project_id),

        CONSTRAINT UQ_Game_Rule_Project_RuleCode
            UNIQUE (project_id, rule_code),

        CONSTRAINT CK_Game_Rule_Code_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(rule_code))) > 0),

        CONSTRAINT CK_Game_Rule_Name_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(rule_name))) > 0),

        CONSTRAINT CK_Game_Rule_Category
            CHECK (rule_category IN (
                N'core',
                N'character_creation',
                N'action',
                N'skill_check',
                N'combat',
                N'magic',
                N'item',
                N'exploration',
                N'social',
                N'narrative',
                N'safety',
                N'database_use',
                N'house_rule',
                N'other'
            )),

        CONSTRAINT CK_Game_Rule_Source_Type
            CHECK (rule_source_type IN (
                N'official',
                N'homebrew',
                N'experiment_protocol',
                N'ai_generated',
                N'human_modified',
                N'unknown'
            )),

        CONSTRAINT CK_Game_Rule_Applies_To_Speaker_Type
            CHECK (
                applies_to_speaker_type IS NULL
                OR applies_to_speaker_type IN (
                    N'GM',
                    N'PL',
                    N'PC',
                    N'NPC',
                    N'Observer',
                    N'Researcher',
                    N'All'
                )
            ),

        CONSTRAINT CK_Game_Rule_Applies_To_Character_Type
            CHECK (
                applies_to_character_type IS NULL
                OR applies_to_character_type IN (
                    N'player_character',
                    N'npc',
                    N'all',
                    N'none'
                )
            ),

        CONSTRAINT CK_Game_Rule_Status
            CHECK (rule_status IN (
                N'draft',
                N'cleaned',
                N'verified',
                N'active',
                N'inactive',
                N'excluded'
            ))
    );
END;
GO