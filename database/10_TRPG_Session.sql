USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.TRPG_Session', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.TRPG_Session
    (
        session_id INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_TRPG_Session PRIMARY KEY,

        team_id INT NOT NULL,

        session_code NVARCHAR(50) NOT NULL,

        session_no INT NOT NULL,

        session_title NVARCHAR(200) NULL,

        session_type NVARCHAR(50) NOT NULL
            CONSTRAINT DF_TRPG_Session_session_type
            DEFAULT N'play',

        session_date DATE NULL,

        planned_start_time TIME(0) NULL,

        planned_end_time TIME(0) NULL,

        actual_start_time TIME(0) NULL,

        actual_end_time TIME(0) NULL,

        planned_duration_min INT NULL,

        actual_duration_min INT NULL,

        location_type NVARCHAR(50) NULL,

        location_note NVARCHAR(200) NULL,

        recording_audio_file NVARCHAR(260) NULL,

        recording_video_file NVARCHAR(260) NULL,

        transcript_file NVARCHAR(260) NULL,

        transcript_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_TRPG_Session_transcript_status
            DEFAULT N'not_started',

        ai_summary_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_TRPG_Session_ai_summary_status
            DEFAULT N'not_started',

        human_review_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_TRPG_Session_human_review_status
            DEFAULT N'not_started',

        session_goal NVARCHAR(MAX) NULL,

        session_summary_raw NVARCHAR(MAX) NULL,

        session_summary_clean NVARCHAR(MAX) NULL,

        session_summary_verified NVARCHAR(MAX) NULL,

        gm_member_id INT NULL,

        recorder_member_id INT NULL,

        observer_member_id INT NULL,

        protocol_deviation_note NVARCHAR(MAX) NULL,

        data_quality_note NVARCHAR(MAX) NULL,

        include_in_analysis BIT NOT NULL
            CONSTRAINT DF_TRPG_Session_include_in_analysis
            DEFAULT 1,

        exclusion_reason NVARCHAR(MAX) NULL,

        session_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_TRPG_Session_session_status
            DEFAULT N'planned',

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_TRPG_Session_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_TRPG_Session_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_TRPG_Session_Team
            FOREIGN KEY (team_id)
            REFERENCES dbo.Team(team_id),

        CONSTRAINT FK_TRPG_Session_GM_Team_Member
            FOREIGN KEY (gm_member_id)
            REFERENCES dbo.Team_Member(team_member_id),

        CONSTRAINT FK_TRPG_Session_Recorder_Team_Member
            FOREIGN KEY (recorder_member_id)
            REFERENCES dbo.Team_Member(team_member_id),

        CONSTRAINT FK_TRPG_Session_Observer_Team_Member
            FOREIGN KEY (observer_member_id)
            REFERENCES dbo.Team_Member(team_member_id),

        CONSTRAINT UQ_TRPG_Session_Team_SessionCode
            UNIQUE (team_id, session_code),

        CONSTRAINT UQ_TRPG_Session_Team_SessionNo
            UNIQUE (team_id, session_no),

        CONSTRAINT CK_TRPG_Session_Code_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(session_code))) > 0),

        CONSTRAINT CK_TRPG_Session_No
            CHECK (session_no >= 1),

        CONSTRAINT CK_TRPG_Session_Type
            CHECK (session_type IN (
                N'orientation',
                N'character_creation',
                N'worldbuilding',
                N'play',
                N'debrief',
                N'creation',
                N'interview',
                N'pilot',
                N'other'
            )),

        CONSTRAINT CK_TRPG_Session_Planned_Duration
            CHECK (
                planned_duration_min IS NULL
                OR planned_duration_min BETWEEN 1 AND 600
            ),

        CONSTRAINT CK_TRPG_Session_Actual_Duration
            CHECK (
                actual_duration_min IS NULL
                OR actual_duration_min BETWEEN 1 AND 600
            ),

        CONSTRAINT CK_TRPG_Session_Location_Type
            CHECK (
                location_type IS NULL
                OR location_type IN (
                    N'onsite',
                    N'online',
                    N'hybrid',
                    N'unknown'
                )
            ),

        CONSTRAINT CK_TRPG_Session_Transcript_Status
            CHECK (transcript_status IN (
                N'not_started',
                N'ai_transcribed',
                N'human_corrected',
                N'imported',
                N'verified',
                N'excluded'
            )),

        CONSTRAINT CK_TRPG_Session_AI_Summary_Status
            CHECK (ai_summary_status IN (
                N'not_started',
                N'generated',
                N'cleaned',
                N'verified',
                N'excluded'
            )),

        CONSTRAINT CK_TRPG_Session_Human_Review_Status
            CHECK (human_review_status IN (
                N'not_started',
                N'in_review',
                N'reviewed',
                N'verified',
                N'excluded'
            )),

        CONSTRAINT CK_TRPG_Session_Include_Exclusion
            CHECK (
                include_in_analysis = 1
                OR exclusion_reason IS NOT NULL
            ),

        CONSTRAINT CK_TRPG_Session_Status
            CHECK (session_status IN (
                N'planned',
                N'in_progress',
                N'completed',
                N'cancelled',
                N'excluded',
                N'archived'
            )),

        CONSTRAINT CK_TRPG_Session_Time_Order
            CHECK (
                actual_start_time IS NULL
                OR actual_end_time IS NULL
                OR actual_start_time < actual_end_time
            )
    );
END;
GO