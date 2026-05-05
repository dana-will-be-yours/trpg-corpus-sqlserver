USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.Research_Project', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Research_Project
    (
        project_id INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Research_Project PRIMARY KEY,

        project_code NVARCHAR(50) NOT NULL,

        project_title NVARCHAR(250) NOT NULL,

        project_title_en NVARCHAR(250) NULL,

        research_topic NVARCHAR(500) NOT NULL,

        research_goal NVARCHAR(MAX) NULL,

        research_design NVARCHAR(100) NOT NULL
            CONSTRAINT DF_Research_Project_research_design
            DEFAULT N'2x2 factorial team-level experiment',

        trpg_system_note NVARCHAR(MAX) NULL,

        corpus_scope_note NVARCHAR(MAX) NULL,

        data_language NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Research_Project_data_language
            DEFAULT N'zh-TW',

        ethics_approval_code NVARCHAR(100) NULL,

        consent_policy_note NVARCHAR(MAX) NULL,

        recording_policy_note NVARCHAR(MAX) NULL,

        anonymization_policy_note NVARCHAR(MAX) NULL,

        data_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Research_Project_data_status
            DEFAULT N'draft',

        project_version NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Research_Project_project_version
            DEFAULT N'v1',

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Research_Project_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Research_Project_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT UQ_Research_Project_Code
            UNIQUE (project_code),

        CONSTRAINT UQ_Research_Project_Title_Version
            UNIQUE (project_title, project_version),

        CONSTRAINT CK_Research_Project_Code_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(project_code))) > 0),

        CONSTRAINT CK_Research_Project_Title_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(project_title))) > 0),

        CONSTRAINT CK_Research_Project_Topic_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(research_topic))) > 0),

        CONSTRAINT CK_Research_Project_Data_Status
            CHECK (data_status IN (
                N'draft',
                N'active',
                N'importing',
                N'cleaning',
                N'verified',
                N'locked',
                N'archived'
            ))
    );
END;
GO