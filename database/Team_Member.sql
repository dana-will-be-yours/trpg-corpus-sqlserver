USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.Team_Member', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Team_Member
    (
        team_member_id INT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Team_Member PRIMARY KEY,

        team_id INT NOT NULL,

        player_id INT NOT NULL,

        member_code NVARCHAR(50) NOT NULL,

        member_role NVARCHAR(50) NOT NULL,

        seat_no TINYINT NULL,

        is_gm BIT NOT NULL
            CONSTRAINT DF_Team_Member_is_gm
            DEFAULT 0,

        is_player BIT NOT NULL
            CONSTRAINT DF_Team_Member_is_player
            DEFAULT 1,

        is_observer BIT NOT NULL
            CONSTRAINT DF_Team_Member_is_observer
            DEFAULT 0,

        is_researcher BIT NOT NULL
            CONSTRAINT DF_Team_Member_is_researcher
            DEFAULT 0,

        attendance_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Team_Member_attendance_status
            DEFAULT N'planned',

        include_in_analysis BIT NOT NULL
            CONSTRAINT DF_Team_Member_include_in_analysis
            DEFAULT 1,

        exclusion_reason NVARCHAR(MAX) NULL,

        join_note NVARCHAR(MAX) NULL,

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Team_Member_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Team_Member_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_Team_Member_Team
            FOREIGN KEY (team_id)
            REFERENCES dbo.Team(team_id),

        CONSTRAINT FK_Team_Member_Player
            FOREIGN KEY (player_id)
            REFERENCES dbo.Player(player_id),

        CONSTRAINT UQ_Team_Member_Team_Player
            UNIQUE (team_id, player_id),

        CONSTRAINT UQ_Team_Member_Team_MemberCode
            UNIQUE (team_id, member_code),

        CONSTRAINT CK_Team_Member_MemberCode_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(member_code))) > 0),

        CONSTRAINT CK_Team_Member_Role
            CHECK (member_role IN (
                N'player',
                N'gm',
                N'observer',
                N'researcher',
                N'recorder',
                N'expert'
            )),

        CONSTRAINT CK_Team_Member_Seat_No
            CHECK (seat_no IS NULL OR seat_no BETWEEN 1 AND 12),

        CONSTRAINT CK_Team_Member_Attendance_Status
            CHECK (attendance_status IN (
                N'planned',
                N'attended',
                N'late',
                N'left_early',
                N'absent',
                N'withdrawn',
                N'excluded'
            )),

        CONSTRAINT CK_Team_Member_Exclusion_Reason
            CHECK (
                include_in_analysis = 1
                OR exclusion_reason IS NOT NULL
            ),

        CONSTRAINT CK_Team_Member_Role_Flag_Consistency
            CHECK (
                (member_role = N'gm' AND is_gm = 1)
                OR (member_role = N'player' AND is_player = 1)
                OR (member_role = N'observer' AND is_observer = 1)
                OR (member_role = N'researcher' AND is_researcher = 1)
                OR member_role IN (N'recorder', N'expert')
            )
    );
END;
GO