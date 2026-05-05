USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.Event_Causal_Link', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Event_Causal_Link
    (
        causal_link_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Event_Causal_Link PRIMARY KEY,

        session_id INT NOT NULL,

        scene_id INT NULL,

        causal_link_code NVARCHAR(80) NOT NULL,

        cause_event_id BIGINT NOT NULL,

        effect_event_id BIGINT NOT NULL,

        link_type NVARCHAR(50) NOT NULL,

        link_strength NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Event_Causal_Link_link_strength
            DEFAULT N'medium',

        causal_direction NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Event_Causal_Link_causal_direction
            DEFAULT N'forward',

        evidence_utterance_id BIGINT NULL,

        evidence_gm_narration_id BIGINT NULL,

        evidence_decision_id BIGINT NULL,

        causal_description_raw NVARCHAR(MAX) NULL,

        causal_description_clean NVARCHAR(MAX) NULL,

        causal_description_verified NVARCHAR(MAX) NULL,

        cause_summary NVARCHAR(MAX) NULL,

        effect_summary NVARCHAR(MAX) NULL,

        condition_summary NVARCHAR(MAX) NULL,

        mechanism_summary NVARCHAR(MAX) NULL,

        alternative_cause_note NVARCHAR(MAX) NULL,

        uncertainty_note NVARCHAR(MAX) NULL,

        narrative_coherence_note NVARCHAR(MAX) NULL,

        decision_trace_note NVARCHAR(MAX) NULL,

        smm_relevance_note NVARCHAR(MAX) NULL,

        tms_relevance_note NVARCHAR(MAX) NULL,

        source_type NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Event_Causal_Link_source_type
            DEFAULT N'human_annotated',

        extraction_method NVARCHAR(50) NULL,

        review_status NVARCHAR(50) NOT NULL
            CONSTRAINT DF_Event_Causal_Link_review_status
            DEFAULT N'draft',

        include_in_analysis BIT NOT NULL
            CONSTRAINT DF_Event_Causal_Link_include_in_analysis
            DEFAULT 1,

        exclusion_reason NVARCHAR(MAX) NULL,

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Event_Causal_Link_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Event_Causal_Link_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_Event_Causal_Link_TRPG_Session
            FOREIGN KEY (session_id)
            REFERENCES dbo.TRPG_Session(session_id),

        CONSTRAINT FK_Event_Causal_Link_Scene
            FOREIGN KEY (scene_id)
            REFERENCES dbo.Scene(scene_id),

        CONSTRAINT FK_Event_Causal_Link_Cause_Event
            FOREIGN KEY (cause_event_id)
            REFERENCES dbo.Plot_Event(plot_event_id),

        CONSTRAINT FK_Event_Causal_Link_Effect_Event
            FOREIGN KEY (effect_event_id)
            REFERENCES dbo.Plot_Event(plot_event_id),

        CONSTRAINT FK_Event_Causal_Link_Evidence_Utterance
            FOREIGN KEY (evidence_utterance_id)
            REFERENCES dbo.Utterance(utterance_id),

        CONSTRAINT FK_Event_Causal_Link_Evidence_GM_Narration
            FOREIGN KEY (evidence_gm_narration_id)
            REFERENCES dbo.GM_Narration(gm_narration_id),

        CONSTRAINT UQ_Event_Causal_Link_Session_Code
            UNIQUE (session_id, causal_link_code),

        CONSTRAINT UQ_Event_Causal_Link_Cause_Effect_Type
            UNIQUE (cause_event_id, effect_event_id, link_type),

        CONSTRAINT CK_Event_Causal_Link_Code_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(causal_link_code))) > 0),

        CONSTRAINT CK_Event_Causal_Link_Not_Self_Link
            CHECK (cause_event_id <> effect_event_id),

        CONSTRAINT CK_Event_Causal_Link_Type
            CHECK (link_type IN (
                N'direct_cause',
                N'indirect_cause',
                N'enabling_condition',
                N'blocking_condition',
                N'consequence',
                N'escalation',
                N'de_escalation',
                N'reveal',
                N'foreshadowing',
                N'contradiction',
                N'correction',
                N'scene_transition',
                N'decision_result',
                N'rule_result',
                N'other'
            )),

        CONSTRAINT CK_Event_Causal_Link_Strength
            CHECK (link_strength IN (
                N'weak',
                N'medium',
                N'strong',
                N'confirmed',
                N'uncertain'
            )),

        CONSTRAINT CK_Event_Causal_Link_Direction
            CHECK (causal_direction IN (
                N'forward',
                N'backward_inferred',
                N'bidirectional',
                N'uncertain'
            )),

        CONSTRAINT CK_Event_Causal_Link_Source_Type
            CHECK (source_type IN (
                N'ai_extracted',
                N'ai_summarized',
                N'human_annotated',
                N'human_modified',
                N'transcript_extracted',
                N'database_imported',
                N'unknown'
            )),

        CONSTRAINT CK_Event_Causal_Link_Extraction_Method
            CHECK (
                extraction_method IS NULL
                OR extraction_method IN (
                    N'manual',
                    N'ai',
                    N'rule_based',
                    N'hybrid',
                    N'imported',
                    N'unknown'
                )
            ),

        CONSTRAINT CK_Event_Causal_Link_Review_Status
            CHECK (review_status IN (
                N'draft',
                N'in_review',
                N'reviewed',
                N'verified',
                N'excluded'
            )),

        CONSTRAINT CK_Event_Causal_Link_Include_Exclusion
            CHECK (
                include_in_analysis = 1
                OR exclusion_reason IS NOT NULL
            )
    );
END;
GO