USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.Expert_Rating', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Expert_Rating
    (
        expert_rating_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Expert_Rating PRIMARY KEY,

        project_id INT NOT NULL,

        team_id INT NULL,

        expert_player_id INT NOT NULL,

        rating_code NVARCHAR(80) NOT NULL,

        rating_batch_code NVARCHAR(80) NULL,

        rating_target_type NVARCHAR(50) NOT NULL,

        creation_text_id BIGINT NULL,

        scene_id INT NULL,

        plot_event_id BIGINT NULL,

        decision_id BIGINT NULL,

        play_history_id BIGINT NULL,

        rating_round_no INT NOT NULL
            CONSTRAINT DF_Expert_Rating_rating_round_no
            DEFAULT 1,

        rubric_version NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Expert_Rating_rubric_version
            DEFAULT N'v1',

        overall_score DECIMAL(5,2) NULL,

        creativity_score DECIMAL(5,2) NULL,

        narrative_coherence_score DECIMAL(5,2) NULL,

        character_depth_score DECIMAL(5,2) NULL,

        worldbuilding_score DECIMAL(5,2) NULL,

        conflict_design_score DECIMAL(5,2) NULL,

        originality_score DECIMAL(5,2) NULL,

        completeness_score DECIMAL(5,2) NULL,

        decision_traceability_score DECIMAL(5,2) NULL,

        consensus_quality_score DECIMAL(5,2) NULL,

        smm_quality_score DECIMAL(5,2) NULL,

        tms_quality_score DECIMAL(5,2) NULL,

        database_usefulness_score DECIMAL(5,2) NULL,

        trpg_integration_score DECIMAL(5,2) NULL,

        rating_comment_raw NVARCHAR(MAX) NULL,

        rating_comment_clean NVARCHAR(MAX) NULL,

        rating_comment_verified NVARCHAR(MAX) NULL,

        strength_comment NVARCHAR(MAX) NULL,

        weakness_comment NVARCHAR(MAX) NULL,

        improvement_suggestion NVARCHAR(MAX) NULL,

        evidence_note NVARCHAR(MAX) NULL,

        uncertainty_note NVARCHAR(MAX) NULL,

        blinded_condition_code NVARCHAR(50) NULL,

        is_blinded BIT NOT NULL
            CONSTRAINT DF_Expert_Rating_is_blinded
            DEFAULT 1,

        rating_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Expert_Rating_rating_status
            DEFAULT N'draft',

        include_in_analysis BIT NOT NULL
            CONSTRAINT DF_Expert_Rating_include_in_analysis
            DEFAULT 1,

        exclusion_reason NVARCHAR(MAX) NULL,

        rated_at DATETIME2(0) NULL,

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Expert_Rating_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Expert_Rating_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_Expert_Rating_Research_Project
            FOREIGN KEY (project_id)
            REFERENCES dbo.Research_Project(project_id),

        CONSTRAINT FK_Expert_Rating_Team
            FOREIGN KEY (team_id)
            REFERENCES dbo.Team(team_id),

        CONSTRAINT FK_Expert_Rating_Expert_Player
            FOREIGN KEY (expert_player_id)
            REFERENCES dbo.Player(player_id),

        CONSTRAINT FK_Expert_Rating_Extended_Creation_Text
            FOREIGN KEY (creation_text_id)
            REFERENCES dbo.Extended_Creation_Text(creation_text_id),

        CONSTRAINT FK_Expert_Rating_Scene
            FOREIGN KEY (scene_id)
            REFERENCES dbo.Scene(scene_id),

        CONSTRAINT FK_Expert_Rating_Plot_Event
            FOREIGN KEY (plot_event_id)
            REFERENCES dbo.Plot_Event(plot_event_id),

        CONSTRAINT FK_Expert_Rating_Decision_Log
            FOREIGN KEY (decision_id)
            REFERENCES dbo.Decision_Log(decision_id),

        CONSTRAINT FK_Expert_Rating_Team_Play_History
            FOREIGN KEY (play_history_id)
            REFERENCES dbo.Team_Play_History(play_history_id),

        CONSTRAINT UQ_Expert_Rating_Project_Code
            UNIQUE (project_id, rating_code),

        CONSTRAINT UQ_Expert_Rating_Expert_Target_Round
            UNIQUE
            (
                expert_player_id,
                rating_target_type,
                creation_text_id,
                scene_id,
                plot_event_id,
                decision_id,
                play_history_id,
                rating_round_no
            ),

        CONSTRAINT CK_Expert_Rating_Code_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(rating_code))) > 0),

        CONSTRAINT CK_Expert_Rating_Target_Type
            CHECK (rating_target_type IN (
                N'extended_creation_text',
                N'scene',
                N'plot_event',
                N'decision',
                N'team_play_history'
            )),

        CONSTRAINT CK_Expert_Rating_Target_Only_One
            CHECK (
                (
                    CASE WHEN creation_text_id IS NULL THEN 0 ELSE 1 END
                    + CASE WHEN scene_id IS NULL THEN 0 ELSE 1 END
                    + CASE WHEN plot_event_id IS NULL THEN 0 ELSE 1 END
                    + CASE WHEN decision_id IS NULL THEN 0 ELSE 1 END
                    + CASE WHEN play_history_id IS NULL THEN 0 ELSE 1 END
                ) = 1
            ),

        CONSTRAINT CK_Expert_Rating_Target_Type_Match
            CHECK (
                (rating_target_type = N'extended_creation_text' AND creation_text_id IS NOT NULL)
                OR (rating_target_type = N'scene' AND scene_id IS NOT NULL)
                OR (rating_target_type = N'plot_event' AND plot_event_id IS NOT NULL)
                OR (rating_target_type = N'decision' AND decision_id IS NOT NULL)
                OR (rating_target_type = N'team_play_history' AND play_history_id IS NOT NULL)
            ),

        CONSTRAINT CK_Expert_Rating_Round_No
            CHECK (rating_round_no >= 1),

        CONSTRAINT CK_Expert_Rating_Overall_Score
            CHECK (overall_score IS NULL OR overall_score BETWEEN 0 AND 100),

        CONSTRAINT CK_Expert_Rating_Creativity_Score
            CHECK (creativity_score IS NULL OR creativity_score BETWEEN 0 AND 100),

        CONSTRAINT CK_Expert_Rating_Narrative_Coherence_Score
            CHECK (narrative_coherence_score IS NULL OR narrative_coherence_score BETWEEN 0 AND 100),

        CONSTRAINT CK_Expert_Rating_Character_Depth_Score
            CHECK (character_depth_score IS NULL OR character_depth_score BETWEEN 0 AND 100),

        CONSTRAINT CK_Expert_Rating_Worldbuilding_Score
            CHECK (worldbuilding_score IS NULL OR worldbuilding_score BETWEEN 0 AND 100),

        CONSTRAINT CK_Expert_Rating_Conflict_Design_Score
            CHECK (conflict_design_score IS NULL OR conflict_design_score BETWEEN 0 AND 100),

        CONSTRAINT CK_Expert_Rating_Originality_Score
            CHECK (originality_score IS NULL OR originality_score BETWEEN 0 AND 100),

        CONSTRAINT CK_Expert_Rating_Completeness_Score
            CHECK (completeness_score IS NULL OR completeness_score BETWEEN 0 AND 100),

        CONSTRAINT CK_Expert_Rating_Decision_Traceability_Score
            CHECK (decision_traceability_score IS NULL OR decision_traceability_score BETWEEN 0 AND 100),

        CONSTRAINT CK_Expert_Rating_Consensus_Quality_Score
            CHECK (consensus_quality_score IS NULL OR consensus_quality_score BETWEEN 0 AND 100),

        CONSTRAINT CK_Expert_Rating_SMM_Quality_Score
            CHECK (smm_quality_score IS NULL OR smm_quality_score BETWEEN 0 AND 100),

        CONSTRAINT CK_Expert_Rating_TMS_Quality_Score
            CHECK (tms_quality_score IS NULL OR tms_quality_score BETWEEN 0 AND 100),

        CONSTRAINT CK_Expert_Rating_Database_Usefulness_Score
            CHECK (database_usefulness_score IS NULL OR database_usefulness_score BETWEEN 0 AND 100),

        CONSTRAINT CK_Expert_Rating_TRPG_Integration_Score
            CHECK (trpg_integration_score IS NULL OR trpg_integration_score BETWEEN 0 AND 100),

        CONSTRAINT CK_Expert_Rating_Status
            CHECK (rating_status IN (
                N'draft',
                N'in_progress',
                N'submitted',
                N'reviewed',
                N'verified',
                N'excluded'
            )),

        CONSTRAINT CK_Expert_Rating_Include_Exclusion
            CHECK (
                include_in_analysis = 1
                OR exclusion_reason IS NOT NULL
            )
    );
END;
GO