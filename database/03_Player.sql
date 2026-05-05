USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.Player', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Player
    (
        player_id INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Player PRIMARY KEY,

        project_id INT NOT NULL,

        player_code NVARCHAR(50) NOT NULL,

        participant_role NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Player_participant_role
            DEFAULT N'player',

        age_group NVARCHAR(50) NULL,

        gender_code NVARCHAR(50) NULL,

        education_level NVARCHAR(100) NULL,

        major_field NVARCHAR(100) NULL,

        trpg_experience_level NVARCHAR(50) NULL,

        writing_experience_level NVARCHAR(50) NULL,

        game_experience_level NVARCHAR(50) NULL,

        ai_tool_experience_level NVARCHAR(50) NULL,

        database_experience_level NVARCHAR(50) NULL,

        consent_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Player_consent_status
            DEFAULT N'pending',

        is_anonymized BIT NOT NULL
            CONSTRAINT DF_Player_is_anonymized
            DEFAULT 1,

        player_note NVARCHAR(MAX) NULL,

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Player_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Player_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_Player_Research_Project
            FOREIGN KEY (project_id)
            REFERENCES dbo.Research_Project(project_id),

        CONSTRAINT UQ_Player_Project_PlayerCode
            UNIQUE (project_id, player_code),

        CONSTRAINT CK_Player_PlayerCode_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(player_code))) > 0),

        CONSTRAINT CK_Player_Participant_Role
            CHECK (participant_role IN (
                N'player',
                N'gm',
                N'observer',
                N'researcher',
                N'expert'
            )),

        CONSTRAINT CK_Player_TRPG_Experience_Level
            CHECK (
                trpg_experience_level IS NULL
                OR trpg_experience_level IN (
                    N'none',
                    N'beginner',
                    N'intermediate',
                    N'advanced'
                )
            ),

        CONSTRAINT CK_Player_Writing_Experience_Level
            CHECK (
                writing_experience_level IS NULL
                OR writing_experience_level IN (
                    N'none',
                    N'beginner',
                    N'intermediate',
                    N'advanced'
                )
            ),

        CONSTRAINT CK_Player_Game_Experience_Level
            CHECK (
                game_experience_level IS NULL
                OR game_experience_level IN (
                    N'none',
                    N'beginner',
                    N'intermediate',
                    N'advanced'
                )
            ),

        CONSTRAINT CK_Player_AI_Tool_Experience_Level
            CHECK (
                ai_tool_experience_level IS NULL
                OR ai_tool_experience_level IN (
                    N'none',
                    N'beginner',
                    N'intermediate',
                    N'advanced'
                )
            ),

        CONSTRAINT CK_Player_Database_Experience_Level
            CHECK (
                database_experience_level IS NULL
                OR database_experience_level IN (
                    N'none',
                    N'beginner',
                    N'intermediate',
                    N'advanced'
                )
            ),

        CONSTRAINT CK_Player_Consent_Status
            CHECK (consent_status IN (
                N'pending',
                N'consented',
                N'withdrawn',
                N'excluded'
            ))
    );
END;
GO