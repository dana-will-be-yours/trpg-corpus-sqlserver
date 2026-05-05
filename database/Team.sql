USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.Team', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Team
    (
        team_id INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Team PRIMARY KEY,

        project_id INT NOT NULL,

        team_code NVARCHAR(50) NOT NULL,

        team_name NVARCHAR(100) NULL,

        cohort_code NVARCHAR(50) NULL,

        experiment_round_no INT NULL,

        condition_trpg BIT NOT NULL,

        condition_database BIT NOT NULL,

        condition_group AS
            (
                CASE
                    WHEN condition_trpg = 0 AND condition_database = 0 THEN N'CONTROL'
                    WHEN condition_trpg = 1 AND condition_database = 0 THEN N'TRPG_ONLY'
                    WHEN condition_trpg = 0 AND condition_database = 1 THEN N'DATABASE_ONLY'
                    WHEN condition_trpg = 1 AND condition_database = 1 THEN N'TRPG_DATABASE'
                END
            ) PERSISTED,

        assigned_gm_code NVARCHAR(50) NULL,

        planned_player_count TINYINT NULL,

        actual_player_count TINYINT NULL,

        team_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Team_team_status
            DEFAULT N'planned',

        randomization_note NVARCHAR(MAX) NULL,

        team_note NVARCHAR(MAX) NULL,

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Team_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Team_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_Team_Research_Project
            FOREIGN KEY (project_id)
            REFERENCES dbo.Research_Project(project_id),

        CONSTRAINT UQ_Team_Project_TeamCode
            UNIQUE (project_id, team_code),

        CONSTRAINT CK_Team_TeamCode_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(team_code))) > 0),

        CONSTRAINT CK_Team_Experiment_Round_No
            CHECK (experiment_round_no IS NULL OR experiment_round_no >= 1),

        CONSTRAINT CK_Team_Planned_Player_Count
            CHECK (planned_player_count IS NULL OR planned_player_count BETWEEN 1 AND 12),

        CONSTRAINT CK_Team_Actual_Player_Count
            CHECK (actual_player_count IS NULL OR actual_player_count BETWEEN 0 AND 12),

        CONSTRAINT CK_Team_Status
            CHECK (team_status IN (
                N'planned',
                N'recruiting',
                N'assigned',
                N'in_progress',
                N'completed',
                N'excluded',
                N'cancelled'
            ))
    );
END;
GO