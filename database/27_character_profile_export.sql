/*
27_character_profile_export.sql
Derived character profile views, chart-ready metrics, and JSON export.

Run after 00_create_database.sql through 26_performance_indexes.sql.
All profile text is selected from existing dbo tables; this script does not
create a manual summary table.
*/

USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

/* -------------------------------------------------------------------------
   1. Character page extension tables
   ------------------------------------------------------------------------- */

IF OBJECT_ID(N'dbo.Character_Profile_Image', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Character_Profile_Image
    (
        character_image_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Character_Profile_Image PRIMARY KEY,

        character_id INT NOT NULL,

        image_slot NVARCHAR(50) NOT NULL,

        image_file_name NVARCHAR(260) NULL,

        image_mime_type NVARCHAR(100) NULL,

        image_size_bytes INT NULL,

        image_data_url NVARCHAR(MAX) NULL,

        image_alt_text NVARCHAR(200) NULL,

        image_note NVARCHAR(MAX) NULL,

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Character_Profile_Image_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Character_Profile_Image_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_Character_Profile_Image_Player_Character
            FOREIGN KEY (character_id)
            REFERENCES dbo.Player_Character(character_id),

        CONSTRAINT UQ_Character_Profile_Image_Character_Slot
            UNIQUE (character_id, image_slot),

        CONSTRAINT CK_Character_Profile_Image_Slot
            CHECK (image_slot IN (
                N'headshot',
                N'fullbody'
            )),

        CONSTRAINT CK_Character_Profile_Image_Size
            CHECK (
                image_size_bytes IS NULL
                OR image_size_bytes >= 0
            )
    );
END;
GO

IF OBJECT_ID(N'dbo.Character_Freeform_Field', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Character_Freeform_Field
    (
        freeform_field_id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Character_Freeform_Field PRIMARY KEY,

        character_id INT NOT NULL,

        field_key NVARCHAR(100) NOT NULL,

        field_label NVARCHAR(200) NOT NULL,

        field_value NVARCHAR(MAX) NULL,

        display_order INT NOT NULL
            CONSTRAINT DF_Character_Freeform_Field_display_order
            DEFAULT 1,

        is_visible BIT NOT NULL
            CONSTRAINT DF_Character_Freeform_Field_is_visible
            DEFAULT 1,

        created_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Character_Freeform_Field_created_at
            DEFAULT SYSDATETIME(),

        updated_at DATETIME2(0) NOT NULL
            CONSTRAINT DF_Character_Freeform_Field_updated_at
            DEFAULT SYSDATETIME(),

        CONSTRAINT FK_Character_Freeform_Field_Player_Character
            FOREIGN KEY (character_id)
            REFERENCES dbo.Player_Character(character_id),

        CONSTRAINT UQ_Character_Freeform_Field_Character_Key
            UNIQUE (character_id, field_key),

        CONSTRAINT CK_Character_Freeform_Field_Key_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(field_key))) > 0),

        CONSTRAINT CK_Character_Freeform_Field_Label_Not_Blank
            CHECK (LEN(LTRIM(RTRIM(field_label))) > 0),

        CONSTRAINT CK_Character_Freeform_Field_Display_Order
            CHECK (display_order >= 1)
    );
END;
GO

/* -------------------------------------------------------------------------
   2. Character export lookup indexes
   ------------------------------------------------------------------------- */

IF OBJECT_ID(N'dbo.Plot_Event', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.Plot_Event')
          AND name = N'IX_Plot_Event_ActorCharacter_Profile'
    )
    BEGIN
        DROP INDEX IX_Plot_Event_ActorCharacter_Profile
        ON dbo.Plot_Event;
    END;

    CREATE NONCLUSTERED INDEX IX_Plot_Event_ActorCharacter_Profile
    ON dbo.Plot_Event (actor_character_id, session_id, event_no)
    INCLUDE
    (
        scene_id,
        event_code,
        event_title,
        event_type,
        event_function,
        event_importance,
        target_character_id,
        include_in_analysis,
        review_status
    )
    WHERE actor_character_id IS NOT NULL;
END;
GO

IF OBJECT_ID(N'dbo.Plot_Event', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.Plot_Event')
          AND name = N'IX_Plot_Event_TargetCharacter_Profile'
    )
    BEGIN
        DROP INDEX IX_Plot_Event_TargetCharacter_Profile
        ON dbo.Plot_Event;
    END;

    CREATE NONCLUSTERED INDEX IX_Plot_Event_TargetCharacter_Profile
    ON dbo.Plot_Event (target_character_id, session_id, event_no)
    INCLUDE
    (
        scene_id,
        event_code,
        event_title,
        event_type,
        event_function,
        event_importance,
        actor_character_id,
        include_in_analysis,
        review_status
    )
    WHERE target_character_id IS NOT NULL;
END;
GO

IF OBJECT_ID(N'dbo.Decision_Log', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.Decision_Log')
          AND name = N'IX_Decision_Log_ProposerCharacter_Profile'
    )
    BEGIN
        DROP INDEX IX_Decision_Log_ProposerCharacter_Profile
        ON dbo.Decision_Log;
    END;

    CREATE NONCLUSTERED INDEX IX_Decision_Log_ProposerCharacter_Profile
    ON dbo.Decision_Log (proposer_character_id, session_id, decision_no)
    INCLUDE
    (
        scene_id,
        decision_code,
        decision_title,
        decision_type,
        decision_status,
        consensus_level,
        decision_importance,
        final_actor_character_id,
        include_in_analysis,
        review_status
    )
    WHERE proposer_character_id IS NOT NULL;
END;
GO

IF OBJECT_ID(N'dbo.Decision_Log', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.Decision_Log')
          AND name = N'IX_Decision_Log_FinalActorCharacter_Profile'
    )
    BEGIN
        DROP INDEX IX_Decision_Log_FinalActorCharacter_Profile
        ON dbo.Decision_Log;
    END;

    CREATE NONCLUSTERED INDEX IX_Decision_Log_FinalActorCharacter_Profile
    ON dbo.Decision_Log (final_actor_character_id, session_id, decision_no)
    INCLUDE
    (
        scene_id,
        decision_code,
        decision_title,
        decision_type,
        decision_status,
        consensus_level,
        decision_importance,
        proposer_character_id,
        include_in_analysis,
        review_status
    )
    WHERE final_actor_character_id IS NOT NULL;
END;
GO

IF OBJECT_ID(N'dbo.Knowledge_Retrieval_Log', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.Knowledge_Retrieval_Log')
          AND name = N'IX_Knowledge_Retrieval_Log_InitiatorCharacter_Profile'
    )
    BEGIN
        DROP INDEX IX_Knowledge_Retrieval_Log_InitiatorCharacter_Profile
        ON dbo.Knowledge_Retrieval_Log;
    END;

    CREATE NONCLUSTERED INDEX IX_Knowledge_Retrieval_Log_InitiatorCharacter_Profile
    ON dbo.Knowledge_Retrieval_Log (query_initiator_character_id, session_id, retrieval_no)
    INCLUDE
    (
        scene_id,
        retrieval_code,
        retrieval_type,
        retrieval_purpose,
        retrieval_success,
        retrieval_success_level,
        related_decision_id,
        related_plot_event_id,
        related_item_id,
        include_in_analysis,
        review_status
    )
    WHERE query_initiator_character_id IS NOT NULL;
END;
GO

IF OBJECT_ID(N'dbo.Character_Profile_Image', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.Character_Profile_Image')
          AND name = N'IX_Character_Profile_Image_Character'
    )
    BEGIN
        DROP INDEX IX_Character_Profile_Image_Character
        ON dbo.Character_Profile_Image;
    END;

    CREATE NONCLUSTERED INDEX IX_Character_Profile_Image_Character
    ON dbo.Character_Profile_Image (character_id, image_slot)
    INCLUDE
    (
        image_file_name,
        image_mime_type,
        image_size_bytes,
        updated_at
    );
END;
GO

IF OBJECT_ID(N'dbo.Character_Freeform_Field', N'U') IS NOT NULL
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.Character_Freeform_Field')
          AND name = N'IX_Character_Freeform_Field_Character_Order'
    )
    BEGIN
        DROP INDEX IX_Character_Freeform_Field_Character_Order
        ON dbo.Character_Freeform_Field;
    END;

    CREATE NONCLUSTERED INDEX IX_Character_Freeform_Field_Character_Order
    ON dbo.Character_Freeform_Field (character_id, is_visible, display_order)
    INCLUDE
    (
        field_key,
        field_label,
        updated_at
    );
END;
GO

/* -------------------------------------------------------------------------
   3. One-row character profile
   ------------------------------------------------------------------------- */

CREATE OR ALTER VIEW dbo.vw_Character_Profile
AS
WITH UtteranceByCharacter AS
(
    SELECT
        u.speaker_character_id AS character_id,
        COUNT_BIG(*) AS utterance_count,
        SUM(CASE WHEN u.utterance_function = N'dialogue' THEN 1 ELSE 0 END) AS dialogue_count,
        SUM(CASE WHEN u.utterance_function = N'action' THEN 1 ELSE 0 END) AS action_count,
        SUM(CASE WHEN u.utterance_function = N'decision' THEN 1 ELSE 0 END) AS decision_utterance_count,
        SUM(CASE WHEN u.utterance_function = N'question' THEN 1 ELSE 0 END) AS question_count,
        SUM(CASE WHEN u.emotion_label IS NOT NULL THEN 1 ELSE 0 END) AS emotion_labeled_utterance_count
    FROM dbo.Utterance AS u
    WHERE u.speaker_character_id IS NOT NULL
      AND u.include_in_analysis = 1
    GROUP BY u.speaker_character_id
),
TargetedUtteranceByCharacter AS
(
    SELECT
        u.interaction_target_character_id AS character_id,
        COUNT_BIG(*) AS targeted_utterance_count
    FROM dbo.Utterance AS u
    WHERE u.interaction_target_character_id IS NOT NULL
      AND u.include_in_analysis = 1
    GROUP BY u.interaction_target_character_id
),
PlotEventByCharacter AS
(
    SELECT
        pc.character_id,
        COUNT_BIG(pe.plot_event_id) AS plot_event_count,
        SUM(CASE WHEN pe.actor_character_id = pc.character_id THEN 1 ELSE 0 END) AS actor_event_count,
        SUM(CASE WHEN pe.target_character_id = pc.character_id THEN 1 ELSE 0 END) AS target_event_count,
        SUM(CASE WHEN pe.event_importance IN (N'high', N'critical') THEN 1 ELSE 0 END) AS high_importance_event_count
    FROM dbo.Player_Character AS pc
    LEFT JOIN dbo.Plot_Event AS pe
        ON pe.include_in_analysis = 1
       AND
       (
           pe.actor_character_id = pc.character_id
           OR pe.target_character_id = pc.character_id
       )
    GROUP BY pc.character_id
),
DecisionByCharacter AS
(
    SELECT
        pc.character_id,
        COUNT_BIG(dl.decision_id) AS decision_count,
        SUM(CASE WHEN dl.proposer_character_id = pc.character_id THEN 1 ELSE 0 END) AS proposed_decision_count,
        SUM(CASE WHEN dl.final_actor_character_id = pc.character_id THEN 1 ELSE 0 END) AS final_actor_decision_count,
        SUM(CASE WHEN dl.consensus_level IN (N'high', N'unanimous') THEN 1 ELSE 0 END) AS high_consensus_decision_count
    FROM dbo.Player_Character AS pc
    LEFT JOIN dbo.Decision_Log AS dl
        ON dl.include_in_analysis = 1
       AND
       (
           dl.proposer_character_id = pc.character_id
           OR dl.final_actor_character_id = pc.character_id
       )
    GROUP BY pc.character_id
),
RetrievalByCharacter AS
(
    SELECT
        krl.query_initiator_character_id AS character_id,
        COUNT_BIG(*) AS knowledge_retrieval_count,
        SUM(CASE WHEN krl.retrieval_success = 1 THEN 1 ELSE 0 END) AS successful_retrieval_count
    FROM dbo.Knowledge_Retrieval_Log AS krl
    WHERE krl.query_initiator_character_id IS NOT NULL
      AND krl.include_in_analysis = 1
    GROUP BY krl.query_initiator_character_id
),
ItemByCharacter AS
(
    SELECT
        i.owner_character_id AS character_id,
        COUNT_BIG(*) AS item_count,
        SUM(CASE WHEN i.is_clue = 1 THEN 1 ELSE 0 END) AS clue_item_count,
        SUM(CASE WHEN i.is_unique = 1 THEN 1 ELSE 0 END) AS unique_item_count
    FROM dbo.Item AS i
    WHERE i.owner_character_id IS NOT NULL
    GROUP BY i.owner_character_id
)
SELECT
    pc.character_id,
    pc.character_code,
    pc.character_name,
    pc.character_type,
    pc.archetype,
    pc.race_or_species,
    pc.class_or_profession,
    pc.faction,
    COALESCE(NULLIF(pc.background_story_verified, N''), NULLIF(pc.background_story_clean, N''), pc.background_story_raw) AS background_story,
    pc.personality_note,
    pc.motivation_note,
    pc.relationship_note,
    pc.ability_note,
    pc.item_note,
    pc.narrative_function,
    pc.is_active,
    pc.character_status,
    tm.team_member_id,
    tm.member_code,
    tm.member_role,
    tm.seat_no,
    t.team_id,
    t.team_code,
    t.team_name,
    t.condition_group,
    p.player_id,
    p.player_code,
    p.trpg_experience_level,
    p.writing_experience_level,
    p.game_experience_level,
    p.ai_tool_experience_level,
    p.database_experience_level,
    COALESCE(ubc.utterance_count, 0) AS utterance_count,
    COALESCE(ubc.dialogue_count, 0) AS dialogue_count,
    COALESCE(ubc.action_count, 0) AS action_count,
    COALESCE(ubc.decision_utterance_count, 0) AS decision_utterance_count,
    COALESCE(ubc.question_count, 0) AS question_count,
    COALESCE(ubc.emotion_labeled_utterance_count, 0) AS emotion_labeled_utterance_count,
    COALESCE(tubc.targeted_utterance_count, 0) AS targeted_utterance_count,
    COALESCE(pebc.plot_event_count, 0) AS plot_event_count,
    COALESCE(pebc.actor_event_count, 0) AS actor_event_count,
    COALESCE(pebc.target_event_count, 0) AS target_event_count,
    COALESCE(pebc.high_importance_event_count, 0) AS high_importance_event_count,
    COALESCE(dbc.decision_count, 0) AS decision_count,
    COALESCE(dbc.proposed_decision_count, 0) AS proposed_decision_count,
    COALESCE(dbc.final_actor_decision_count, 0) AS final_actor_decision_count,
    COALESCE(dbc.high_consensus_decision_count, 0) AS high_consensus_decision_count,
    COALESCE(rbc.knowledge_retrieval_count, 0) AS knowledge_retrieval_count,
    COALESCE(rbc.successful_retrieval_count, 0) AS successful_retrieval_count,
    COALESCE(ibc.item_count, 0) AS item_count,
    COALESCE(ibc.clue_item_count, 0) AS clue_item_count,
    COALESCE(ibc.unique_item_count, 0) AS unique_item_count,
    pc.created_at,
    pc.updated_at
FROM dbo.Player_Character AS pc
INNER JOIN dbo.Team_Member AS tm
    ON tm.team_member_id = pc.team_member_id
INNER JOIN dbo.Team AS t
    ON t.team_id = tm.team_id
INNER JOIN dbo.Player AS p
    ON p.player_id = tm.player_id
LEFT JOIN UtteranceByCharacter AS ubc
    ON ubc.character_id = pc.character_id
LEFT JOIN TargetedUtteranceByCharacter AS tubc
    ON tubc.character_id = pc.character_id
LEFT JOIN PlotEventByCharacter AS pebc
    ON pebc.character_id = pc.character_id
LEFT JOIN DecisionByCharacter AS dbc
    ON dbc.character_id = pc.character_id
LEFT JOIN RetrievalByCharacter AS rbc
    ON rbc.character_id = pc.character_id
LEFT JOIN ItemByCharacter AS ibc
    ON ibc.character_id = pc.character_id;
GO

/* -------------------------------------------------------------------------
   4. Text sections for profile pages
   ------------------------------------------------------------------------- */

CREATE OR ALTER VIEW dbo.vw_Character_Profile_Section
AS
SELECT
    pc.character_id,
    CAST(N'角色背景' AS NVARCHAR(100)) AS section_name,
    CAST(N'Player_Character' AS NVARCHAR(128)) AS source_table,
    CONVERT(NVARCHAR(40), pc.character_id) AS source_id,
    CAST(N'background_story' AS NVARCHAR(128)) AS source_column,
    CAST(pc.character_name AS NVARCHAR(250)) AS source_title,
    COALESCE(NULLIF(pc.background_story_verified, N''), NULLIF(pc.background_story_clean, N''), pc.background_story_raw) AS source_text,
    CAST(NULL AS INT) AS session_no,
    CAST(NULL AS INT) AS scene_no,
    CAST(NULL AS INT) AS turn_no,
    CAST(10 AS INT) AS section_order,
    CAST(10 AS BIGINT) AS source_order
FROM dbo.Player_Character AS pc
WHERE COALESCE(NULLIF(pc.background_story_verified, N''), NULLIF(pc.background_story_clean, N''), pc.background_story_raw) IS NOT NULL

UNION ALL

SELECT
    pc.character_id,
    N'角色個性',
    N'Player_Character',
    CONVERT(NVARCHAR(40), pc.character_id),
    N'personality_note',
    CAST(pc.character_name AS NVARCHAR(250)),
    pc.personality_note,
    NULL,
    NULL,
    NULL,
    20,
    20
FROM dbo.Player_Character AS pc
WHERE pc.personality_note IS NOT NULL

UNION ALL

SELECT
    pc.character_id,
    N'角色動機',
    N'Player_Character',
    CONVERT(NVARCHAR(40), pc.character_id),
    N'motivation_note',
    CAST(pc.character_name AS NVARCHAR(250)),
    pc.motivation_note,
    NULL,
    NULL,
    NULL,
    30,
    30
FROM dbo.Player_Character AS pc
WHERE pc.motivation_note IS NOT NULL

UNION ALL

SELECT
    pc.character_id,
    N'角色關係',
    N'Player_Character',
    CONVERT(NVARCHAR(40), pc.character_id),
    N'relationship_note',
    CAST(pc.character_name AS NVARCHAR(250)),
    pc.relationship_note,
    NULL,
    NULL,
    NULL,
    40,
    40
FROM dbo.Player_Character AS pc
WHERE pc.relationship_note IS NOT NULL

UNION ALL

SELECT
    pc.character_id,
    N'能力與資源',
    N'Player_Character',
    CONVERT(NVARCHAR(40), pc.character_id),
    N'ability_note',
    CAST(pc.character_name AS NVARCHAR(250)),
    pc.ability_note,
    NULL,
    NULL,
    NULL,
    50,
    50
FROM dbo.Player_Character AS pc
WHERE pc.ability_note IS NOT NULL

UNION ALL

SELECT
    i.owner_character_id,
    N'持有物品',
    N'Item',
    CONVERT(NVARCHAR(40), i.item_id),
    N'item_summary',
    CAST(i.item_name AS NVARCHAR(250)),
    COALESCE(NULLIF(i.item_summary, N''), NULLIF(i.item_description_verified, N''), NULLIF(i.item_description_clean, N''), i.item_description_raw, i.narrative_function),
    i.introduced_session_no,
    i.introduced_scene_no,
    i.introduced_turn_no,
    60,
    CAST(600000000 AS BIGINT) + i.item_id
FROM dbo.Item AS i
WHERE i.owner_character_id IS NOT NULL
  AND COALESCE(NULLIF(i.item_summary, N''), NULLIF(i.item_description_verified, N''), NULLIF(i.item_description_clean, N''), i.item_description_raw, i.narrative_function) IS NOT NULL

UNION ALL

SELECT
    pc.character_id,
    N'角色經歷',
    N'Plot_Event',
    CONVERT(NVARCHAR(40), pe.plot_event_id),
    N'event_summary',
    CAST(pe.event_title AS NVARCHAR(250)),
    COALESCE(NULLIF(pe.event_summary, N''), NULLIF(pe.event_description_verified, N''), NULLIF(pe.event_description_clean, N''), pe.event_description_raw),
    ts.session_no,
    s.scene_no,
    NULL,
    70,
    CAST(ISNULL(ts.session_no, 0) AS BIGINT) * 1000000000
        + CAST(ISNULL(s.scene_no, 0) AS BIGINT) * 1000000
        + CAST(pe.event_no AS BIGINT) * 100
FROM dbo.Player_Character AS pc
INNER JOIN dbo.Plot_Event AS pe
    ON pe.include_in_analysis = 1
   AND
   (
       pe.actor_character_id = pc.character_id
       OR pe.target_character_id = pc.character_id
   )
INNER JOIN dbo.TRPG_Session AS ts
    ON ts.session_id = pe.session_id
LEFT JOIN dbo.Scene AS s
    ON s.scene_id = pe.scene_id
WHERE COALESCE(NULLIF(pe.event_summary, N''), NULLIF(pe.event_description_verified, N''), NULLIF(pe.event_description_clean, N''), pe.event_description_raw) IS NOT NULL

UNION ALL

SELECT
    pc.character_id,
    N'角色決策',
    N'Decision_Log',
    CONVERT(NVARCHAR(40), dl.decision_id),
    N'decision_summary',
    CAST(dl.decision_title AS NVARCHAR(250)),
    COALESCE(NULLIF(dl.decision_summary, N''), NULLIF(dl.decision_text_verified, N''), NULLIF(dl.decision_text_clean, N''), dl.decision_text_raw, dl.outcome_summary, dl.consequence_summary),
    ts.session_no,
    s.scene_no,
    NULL,
    80,
    CAST(ISNULL(ts.session_no, 0) AS BIGINT) * 1000000000
        + CAST(ISNULL(s.scene_no, 0) AS BIGINT) * 1000000
        + CAST(dl.decision_no AS BIGINT) * 100
FROM dbo.Player_Character AS pc
INNER JOIN dbo.Decision_Log AS dl
    ON dl.include_in_analysis = 1
   AND
   (
       dl.proposer_character_id = pc.character_id
       OR dl.final_actor_character_id = pc.character_id
   )
INNER JOIN dbo.TRPG_Session AS ts
    ON ts.session_id = dl.session_id
LEFT JOIN dbo.Scene AS s
    ON s.scene_id = dl.scene_id
WHERE COALESCE(NULLIF(dl.decision_summary, N''), NULLIF(dl.decision_text_verified, N''), NULLIF(dl.decision_text_clean, N''), dl.decision_text_raw, dl.outcome_summary, dl.consequence_summary) IS NOT NULL

UNION ALL

SELECT
    krl.query_initiator_character_id,
    N'知識查詢',
    N'Knowledge_Retrieval_Log',
    CONVERT(NVARCHAR(40), krl.retrieval_id),
    N'result_summary',
    CAST(COALESCE(krl.retrieval_purpose, krl.retrieval_type) AS NVARCHAR(250)),
    COALESCE(NULLIF(krl.result_summary, N''), NULLIF(krl.result_used_summary, N''), NULLIF(krl.query_result_verified, N''), NULLIF(krl.query_result_clean, N''), krl.query_result_raw),
    ts.session_no,
    s.scene_no,
    NULL,
    90,
    CAST(ISNULL(ts.session_no, 0) AS BIGINT) * 1000000000
        + CAST(ISNULL(s.scene_no, 0) AS BIGINT) * 1000000
        + CAST(krl.retrieval_no AS BIGINT) * 100
FROM dbo.Knowledge_Retrieval_Log AS krl
INNER JOIN dbo.TRPG_Session AS ts
    ON ts.session_id = krl.session_id
LEFT JOIN dbo.Scene AS s
    ON s.scene_id = krl.scene_id
WHERE krl.query_initiator_character_id IS NOT NULL
  AND krl.include_in_analysis = 1
  AND COALESCE(NULLIF(krl.result_summary, N''), NULLIF(krl.result_used_summary, N''), NULLIF(krl.query_result_verified, N''), NULLIF(krl.query_result_clean, N''), krl.query_result_raw) IS NOT NULL;
GO

/* -------------------------------------------------------------------------
   5. Timeline rows for one character
   ------------------------------------------------------------------------- */

CREATE OR ALTER VIEW dbo.vw_Character_Timeline
AS
SELECT
    u.speaker_character_id AS character_id,
    CAST(N'utterance' AS NVARCHAR(50)) AS timeline_kind,
    CAST(N'Utterance' AS NVARCHAR(128)) AS source_table,
    CONVERT(NVARCHAR(40), u.utterance_id) AS source_id,
    u.utterance_code AS source_code,
    CAST(u.utterance_function AS NVARCHAR(100)) AS type_label,
    CAST(N'發言者' AS NVARCHAR(100)) AS role_label,
    ts.session_no,
    s.scene_no,
    u.turn_no,
    CAST(NULL AS INT) AS source_no,
    CAST(CONCAT(N'回合 ', u.turn_no) AS NVARCHAR(250)) AS title,
    COALESCE(NULLIF(u.utterance_text_verified, N''), NULLIF(u.utterance_text_clean, N''), u.utterance_text_raw) AS summary_text,
    u.emotion_label,
    CAST(NULL AS NVARCHAR(50)) AS importance_label,
    u.review_status,
    CAST(ISNULL(ts.session_no, 0) AS BIGINT) * 1000000000
        + CAST(ISNULL(s.scene_no, 0) AS BIGINT) * 1000000
        + CAST(u.turn_no AS BIGINT)
        + CAST(ISNULL(u.sub_turn_no, 0) AS BIGINT) AS timeline_order
FROM dbo.Utterance AS u
INNER JOIN dbo.TRPG_Session AS ts
    ON ts.session_id = u.session_id
LEFT JOIN dbo.Scene AS s
    ON s.scene_id = u.scene_id
WHERE u.speaker_character_id IS NOT NULL
  AND u.include_in_analysis = 1

UNION ALL

SELECT
    pc.character_id,
    N'plot_event',
    N'Plot_Event',
    CONVERT(NVARCHAR(40), pe.plot_event_id),
    pe.event_code,
    pe.event_type,
    CASE
        WHEN pe.actor_character_id = pc.character_id AND pe.target_character_id = pc.character_id THEN N'行動者與對象'
        WHEN pe.actor_character_id = pc.character_id THEN N'行動者'
        ELSE N'對象'
    END,
    ts.session_no,
    s.scene_no,
    NULL,
    pe.event_no,
    CAST(pe.event_title AS NVARCHAR(250)),
    COALESCE(NULLIF(pe.event_summary, N''), NULLIF(pe.event_description_verified, N''), NULLIF(pe.event_description_clean, N''), pe.event_description_raw),
    NULL,
    pe.event_importance,
    pe.review_status,
    CAST(ISNULL(ts.session_no, 0) AS BIGINT) * 1000000000
        + CAST(ISNULL(s.scene_no, 0) AS BIGINT) * 1000000
        + CAST(pe.event_no AS BIGINT) * 100
        + 10
FROM dbo.Player_Character AS pc
INNER JOIN dbo.Plot_Event AS pe
    ON pe.include_in_analysis = 1
   AND
   (
       pe.actor_character_id = pc.character_id
       OR pe.target_character_id = pc.character_id
   )
INNER JOIN dbo.TRPG_Session AS ts
    ON ts.session_id = pe.session_id
LEFT JOIN dbo.Scene AS s
    ON s.scene_id = pe.scene_id

UNION ALL

SELECT
    pc.character_id,
    N'decision',
    N'Decision_Log',
    CONVERT(NVARCHAR(40), dl.decision_id),
    dl.decision_code,
    dl.decision_type,
    CASE
        WHEN dl.proposer_character_id = pc.character_id AND dl.final_actor_character_id = pc.character_id THEN N'提出者與執行者'
        WHEN dl.proposer_character_id = pc.character_id THEN N'提出者'
        ELSE N'執行者'
    END,
    ts.session_no,
    s.scene_no,
    NULL,
    dl.decision_no,
    CAST(dl.decision_title AS NVARCHAR(250)),
    COALESCE(NULLIF(dl.decision_summary, N''), NULLIF(dl.decision_text_verified, N''), NULLIF(dl.decision_text_clean, N''), dl.decision_text_raw, dl.outcome_summary),
    NULL,
    dl.decision_importance,
    dl.review_status,
    CAST(ISNULL(ts.session_no, 0) AS BIGINT) * 1000000000
        + CAST(ISNULL(s.scene_no, 0) AS BIGINT) * 1000000
        + CAST(dl.decision_no AS BIGINT) * 100
        + 20
FROM dbo.Player_Character AS pc
INNER JOIN dbo.Decision_Log AS dl
    ON dl.include_in_analysis = 1
   AND
   (
       dl.proposer_character_id = pc.character_id
       OR dl.final_actor_character_id = pc.character_id
   )
INNER JOIN dbo.TRPG_Session AS ts
    ON ts.session_id = dl.session_id
LEFT JOIN dbo.Scene AS s
    ON s.scene_id = dl.scene_id

UNION ALL

SELECT
    krl.query_initiator_character_id,
    N'knowledge_retrieval',
    N'Knowledge_Retrieval_Log',
    CONVERT(NVARCHAR(40), krl.retrieval_id),
    krl.retrieval_code,
    krl.retrieval_type,
    N'查詢者',
    ts.session_no,
    s.scene_no,
    NULL,
    krl.retrieval_no,
    CAST(COALESCE(krl.retrieval_purpose, krl.retrieval_type) AS NVARCHAR(250)),
    COALESCE(NULLIF(krl.result_summary, N''), NULLIF(krl.result_used_summary, N''), NULLIF(krl.query_text_verified, N''), NULLIF(krl.query_text_clean, N''), krl.query_text_raw),
    NULL,
    krl.retrieval_success_level,
    krl.review_status,
    CAST(ISNULL(ts.session_no, 0) AS BIGINT) * 1000000000
        + CAST(ISNULL(s.scene_no, 0) AS BIGINT) * 1000000
        + CAST(krl.retrieval_no AS BIGINT) * 100
        + 30
FROM dbo.Knowledge_Retrieval_Log AS krl
INNER JOIN dbo.TRPG_Session AS ts
    ON ts.session_id = krl.session_id
LEFT JOIN dbo.Scene AS s
    ON s.scene_id = krl.scene_id
WHERE krl.query_initiator_character_id IS NOT NULL
  AND krl.include_in_analysis = 1;
GO

/* -------------------------------------------------------------------------
   6. Chart-ready metric rows
   ------------------------------------------------------------------------- */

CREATE OR ALTER VIEW dbo.vw_Character_Chart_Data
AS
SELECT
    pc.character_id,
    CAST(N'source_count' AS NVARCHAR(80)) AS chart_key,
    CAST(N'資料來源筆數' AS NVARCHAR(120)) AS chart_title,
    CAST(N'角色基本資料' AS NVARCHAR(120)) AS label,
    CAST(1 AS DECIMAL(18,2)) AS metric_value,
    CAST(10 AS INT) AS metric_order
FROM dbo.Player_Character AS pc

UNION ALL

SELECT
    pc.character_id,
    N'source_count',
    N'資料來源筆數',
    N'發言',
    CAST(COUNT_BIG(u.utterance_id) AS DECIMAL(18,2)),
    20
FROM dbo.Player_Character AS pc
LEFT JOIN dbo.Utterance AS u
    ON u.speaker_character_id = pc.character_id
   AND u.include_in_analysis = 1
GROUP BY pc.character_id

UNION ALL

SELECT
    pc.character_id,
    N'source_count',
    N'資料來源筆數',
    N'劇情事件',
    CAST(COUNT_BIG(pe.plot_event_id) AS DECIMAL(18,2)),
    30
FROM dbo.Player_Character AS pc
LEFT JOIN dbo.Plot_Event AS pe
    ON pe.include_in_analysis = 1
   AND
   (
       pe.actor_character_id = pc.character_id
       OR pe.target_character_id = pc.character_id
   )
GROUP BY pc.character_id

UNION ALL

SELECT
    pc.character_id,
    N'source_count',
    N'資料來源筆數',
    N'決策紀錄',
    CAST(COUNT_BIG(dl.decision_id) AS DECIMAL(18,2)),
    40
FROM dbo.Player_Character AS pc
LEFT JOIN dbo.Decision_Log AS dl
    ON dl.include_in_analysis = 1
   AND
   (
       dl.proposer_character_id = pc.character_id
       OR dl.final_actor_character_id = pc.character_id
   )
GROUP BY pc.character_id

UNION ALL

SELECT
    pc.character_id,
    N'source_count',
    N'資料來源筆數',
    N'知識查詢',
    CAST(COUNT_BIG(krl.retrieval_id) AS DECIMAL(18,2)),
    50
FROM dbo.Player_Character AS pc
LEFT JOIN dbo.Knowledge_Retrieval_Log AS krl
    ON krl.query_initiator_character_id = pc.character_id
   AND krl.include_in_analysis = 1
GROUP BY pc.character_id

UNION ALL

SELECT
    pc.character_id,
    N'source_count',
    N'資料來源筆數',
    N'物品',
    CAST(COUNT_BIG(i.item_id) AS DECIMAL(18,2)),
    60
FROM dbo.Player_Character AS pc
LEFT JOIN dbo.Item AS i
    ON i.owner_character_id = pc.character_id
GROUP BY pc.character_id

UNION ALL

SELECT
    u.speaker_character_id,
    N'utterance_function',
    N'發言功能',
    CAST(u.utterance_function AS NVARCHAR(120)),
    CAST(COUNT_BIG(*) AS DECIMAL(18,2)),
    100
FROM dbo.Utterance AS u
WHERE u.speaker_character_id IS NOT NULL
  AND u.include_in_analysis = 1
GROUP BY u.speaker_character_id, u.utterance_function

UNION ALL

SELECT
    u.speaker_character_id,
    N'emotion_label',
    N'情緒標籤',
    CAST(COALESCE(u.emotion_label, N'unlabeled') AS NVARCHAR(120)),
    CAST(COUNT_BIG(*) AS DECIMAL(18,2)),
    110
FROM dbo.Utterance AS u
WHERE u.speaker_character_id IS NOT NULL
  AND u.include_in_analysis = 1
GROUP BY u.speaker_character_id, COALESCE(u.emotion_label, N'unlabeled')

UNION ALL

SELECT
    pc.character_id,
    N'plot_event_type',
    N'事件類型',
    CAST(pe.event_type AS NVARCHAR(120)),
    CAST(COUNT_BIG(pe.plot_event_id) AS DECIMAL(18,2)),
    120
FROM dbo.Player_Character AS pc
INNER JOIN dbo.Plot_Event AS pe
    ON pe.include_in_analysis = 1
   AND
   (
       pe.actor_character_id = pc.character_id
       OR pe.target_character_id = pc.character_id
   )
GROUP BY pc.character_id, pe.event_type

UNION ALL

SELECT
    pc.character_id,
    N'plot_event_role',
    N'事件中的角色位置',
    N'行動者',
    CAST(SUM(CASE WHEN pe.actor_character_id = pc.character_id THEN 1 ELSE 0 END) AS DECIMAL(18,2)),
    130
FROM dbo.Player_Character AS pc
INNER JOIN dbo.Plot_Event AS pe
    ON pe.include_in_analysis = 1
   AND
   (
       pe.actor_character_id = pc.character_id
       OR pe.target_character_id = pc.character_id
   )
GROUP BY pc.character_id

UNION ALL

SELECT
    pc.character_id,
    N'plot_event_role',
    N'事件中的角色位置',
    N'對象',
    CAST(SUM(CASE WHEN pe.target_character_id = pc.character_id THEN 1 ELSE 0 END) AS DECIMAL(18,2)),
    131
FROM dbo.Player_Character AS pc
INNER JOIN dbo.Plot_Event AS pe
    ON pe.include_in_analysis = 1
   AND
   (
       pe.actor_character_id = pc.character_id
       OR pe.target_character_id = pc.character_id
   )
GROUP BY pc.character_id

UNION ALL

SELECT
    pc.character_id,
    N'decision_status',
    N'決策狀態',
    CAST(dl.decision_status AS NVARCHAR(120)),
    CAST(COUNT_BIG(dl.decision_id) AS DECIMAL(18,2)),
    140
FROM dbo.Player_Character AS pc
INNER JOIN dbo.Decision_Log AS dl
    ON dl.include_in_analysis = 1
   AND
   (
       dl.proposer_character_id = pc.character_id
       OR dl.final_actor_character_id = pc.character_id
   )
GROUP BY pc.character_id, dl.decision_status

UNION ALL

SELECT
    pc.character_id,
    N'consensus_level',
    N'共識程度',
    CAST(dl.consensus_level AS NVARCHAR(120)),
    CAST(COUNT_BIG(dl.decision_id) AS DECIMAL(18,2)),
    150
FROM dbo.Player_Character AS pc
INNER JOIN dbo.Decision_Log AS dl
    ON dl.include_in_analysis = 1
   AND
   (
       dl.proposer_character_id = pc.character_id
       OR dl.final_actor_character_id = pc.character_id
   )
GROUP BY pc.character_id, dl.consensus_level

UNION ALL

SELECT
    i.owner_character_id,
    N'item_category',
    N'物品類型',
    CAST(i.item_category AS NVARCHAR(120)),
    CAST(COUNT_BIG(*) AS DECIMAL(18,2)),
    160
FROM dbo.Item AS i
WHERE i.owner_character_id IS NOT NULL
GROUP BY i.owner_character_id, i.item_category

UNION ALL

SELECT
    krl.query_initiator_character_id,
    N'retrieval_success_level',
    N'查詢結果',
    CAST(krl.retrieval_success_level AS NVARCHAR(120)),
    CAST(COUNT_BIG(*) AS DECIMAL(18,2)),
    170
FROM dbo.Knowledge_Retrieval_Log AS krl
WHERE krl.query_initiator_character_id IS NOT NULL
  AND krl.include_in_analysis = 1
GROUP BY krl.query_initiator_character_id, krl.retrieval_success_level;
GO

/* -------------------------------------------------------------------------
   7. Team story export records
   ------------------------------------------------------------------------- */

CREATE OR ALTER VIEW dbo.vw_Team_Story_Record
AS
SELECT
    ts.team_id,
    CAST(N'session' AS NVARCHAR(50)) AS record_kind,
    CAST(N'TRPG_Session' AS NVARCHAR(128)) AS source_table,
    CONVERT(NVARCHAR(40), ts.session_id) AS source_id,
    ts.session_code AS source_code,
    ts.session_id,
    ts.session_no,
    CAST(NULL AS INT) AS scene_id,
    CAST(NULL AS INT) AS scene_no,
    ts.session_no AS record_no,
    CAST(COALESCE(ts.session_title, ts.session_code) AS NVARCHAR(250)) AS title,
    CAST(ts.session_type AS NVARCHAR(100)) AS type_label,
    COALESCE(NULLIF(ts.session_summary_verified, N''), NULLIF(ts.session_summary_clean, N''), NULLIF(ts.session_summary_raw, N''), ts.session_goal) AS summary_text,
    CAST(NULL AS NVARCHAR(MAX)) AS smm_note,
    CAST(NULL AS NVARCHAR(MAX)) AS tms_note,
    ts.human_review_status AS review_status,
    ts.include_in_analysis,
    CAST(ts.session_no AS BIGINT) * 1000000000 AS timeline_order
FROM dbo.TRPG_Session AS ts

UNION ALL

SELECT
    ts.team_id,
    N'scene',
    N'Scene',
    CONVERT(NVARCHAR(40), s.scene_id),
    s.scene_code,
    ts.session_id,
    ts.session_no,
    s.scene_id,
    s.scene_no,
    s.scene_no,
    CAST(COALESCE(s.scene_title, s.scene_code) AS NVARCHAR(250)),
    CAST(s.scene_type AS NVARCHAR(100)),
    COALESCE(NULLIF(s.scene_summary_verified, N''), NULLIF(s.scene_summary_clean, N''), NULLIF(s.scene_summary_raw, N''), s.scene_goal, s.outcome_summary),
    s.smm_note,
    s.tms_note,
    s.review_status,
    s.include_in_analysis,
    CAST(ts.session_no AS BIGINT) * 1000000000
        + CAST(s.scene_no AS BIGINT) * 1000000
        + 1000
FROM dbo.Scene AS s
INNER JOIN dbo.TRPG_Session AS ts
    ON ts.session_id = s.session_id

UNION ALL

SELECT
    tph.team_id,
    N'team_play_history',
    N'Team_Play_History',
    CONVERT(NVARCHAR(40), tph.play_history_id),
    tph.history_code,
    tph.session_id,
    ts.session_no,
    tph.scene_id,
    s.scene_no,
    tph.history_no,
    CAST(tph.history_title AS NVARCHAR(250)),
    CAST(tph.history_type AS NVARCHAR(100)),
    COALESCE(NULLIF(tph.history_summary, N''), NULLIF(tph.history_description_verified, N''), NULLIF(tph.history_description_clean, N''), tph.history_description_raw, tph.narrative_progress_summary, tph.mission_progress_summary),
    COALESCE(tph.smm_state_note, tph.smm_change_note),
    COALESCE(tph.tms_state_note, tph.tms_change_note),
    tph.review_status,
    tph.include_in_analysis,
    CAST(ISNULL(ts.session_no, ISNULL(tph.time_scope_start_session_no, 0)) AS BIGINT) * 1000000000
        + CAST(ISNULL(s.scene_no, ISNULL(tph.time_scope_start_scene_no, 0)) AS BIGINT) * 1000000
        + CAST(tph.history_no AS BIGINT) * 100
        + 10
FROM dbo.Team_Play_History AS tph
LEFT JOIN dbo.TRPG_Session AS ts
    ON ts.session_id = tph.session_id
LEFT JOIN dbo.Scene AS s
    ON s.scene_id = tph.scene_id

UNION ALL

SELECT
    ts.team_id,
    N'plot_event',
    N'Plot_Event',
    CONVERT(NVARCHAR(40), pe.plot_event_id),
    pe.event_code,
    pe.session_id,
    ts.session_no,
    pe.scene_id,
    s.scene_no,
    pe.event_no,
    CAST(pe.event_title AS NVARCHAR(250)),
    CAST(pe.event_type AS NVARCHAR(100)),
    COALESCE(NULLIF(pe.event_summary, N''), NULLIF(pe.event_description_verified, N''), NULLIF(pe.event_description_clean, N''), pe.event_description_raw, pe.consequence_summary),
    pe.smm_relevance_note,
    pe.tms_relevance_note,
    pe.review_status,
    pe.include_in_analysis,
    CAST(ts.session_no AS BIGINT) * 1000000000
        + CAST(ISNULL(s.scene_no, 0) AS BIGINT) * 1000000
        + CAST(pe.event_no AS BIGINT) * 100
        + 20
FROM dbo.Plot_Event AS pe
INNER JOIN dbo.TRPG_Session AS ts
    ON ts.session_id = pe.session_id
LEFT JOIN dbo.Scene AS s
    ON s.scene_id = pe.scene_id

UNION ALL

SELECT
    ts.team_id,
    N'decision',
    N'Decision_Log',
    CONVERT(NVARCHAR(40), dl.decision_id),
    dl.decision_code,
    dl.session_id,
    ts.session_no,
    dl.scene_id,
    s.scene_no,
    dl.decision_no,
    CAST(dl.decision_title AS NVARCHAR(250)),
    CAST(dl.decision_type AS NVARCHAR(100)),
    COALESCE(NULLIF(dl.decision_summary, N''), NULLIF(dl.decision_text_verified, N''), NULLIF(dl.decision_text_clean, N''), dl.decision_text_raw, dl.outcome_summary, dl.consequence_summary),
    dl.smm_alignment_note,
    dl.tms_process_note,
    dl.review_status,
    dl.include_in_analysis,
    CAST(ts.session_no AS BIGINT) * 1000000000
        + CAST(ISNULL(s.scene_no, 0) AS BIGINT) * 1000000
        + CAST(dl.decision_no AS BIGINT) * 100
        + 30
FROM dbo.Decision_Log AS dl
INNER JOIN dbo.TRPG_Session AS ts
    ON ts.session_id = dl.session_id
LEFT JOIN dbo.Scene AS s
    ON s.scene_id = dl.scene_id

UNION ALL

SELECT
    ts.team_id,
    N'knowledge_retrieval',
    N'Knowledge_Retrieval_Log',
    CONVERT(NVARCHAR(40), krl.retrieval_id),
    krl.retrieval_code,
    krl.session_id,
    ts.session_no,
    krl.scene_id,
    s.scene_no,
    krl.retrieval_no,
    CAST(COALESCE(krl.retrieval_purpose, krl.retrieval_type) AS NVARCHAR(250)),
    CAST(krl.retrieval_type AS NVARCHAR(100)),
    COALESCE(NULLIF(krl.result_summary, N''), NULLIF(krl.result_used_summary, N''), NULLIF(krl.query_text_verified, N''), NULLIF(krl.query_text_clean, N''), krl.query_text_raw),
    krl.smm_relevance_note,
    krl.tms_relevance_note,
    krl.review_status,
    krl.include_in_analysis,
    CAST(ts.session_no AS BIGINT) * 1000000000
        + CAST(ISNULL(s.scene_no, 0) AS BIGINT) * 1000000
        + CAST(krl.retrieval_no AS BIGINT) * 100
        + 40
FROM dbo.Knowledge_Retrieval_Log AS krl
INNER JOIN dbo.TRPG_Session AS ts
    ON ts.session_id = krl.session_id
LEFT JOIN dbo.Scene AS s
    ON s.scene_id = krl.scene_id

UNION ALL

SELECT
    ect.team_id,
    N'extended_creation_text',
    N'Extended_Creation_Text',
    CONVERT(NVARCHAR(40), ect.creation_text_id),
    ect.creation_code,
    ect.session_id,
    ts.session_no,
    ect.scene_id,
    s.scene_no,
    ect.creation_no,
    CAST(ect.creation_title AS NVARCHAR(250)),
    CAST(ect.creation_type AS NVARCHAR(100)),
    COALESCE(NULLIF(ect.creation_summary, N''), NULLIF(ect.plot_summary, N''), NULLIF(ect.creation_text_verified, N''), NULLIF(ect.creation_text_clean, N''), ect.creation_text_raw),
    ect.smm_relevance_note,
    ect.tms_relevance_note,
    ect.review_status,
    ect.include_in_analysis,
    CAST(ISNULL(ts.session_no, 0) AS BIGINT) * 1000000000
        + CAST(ISNULL(s.scene_no, 0) AS BIGINT) * 1000000
        + CAST(ect.creation_no AS BIGINT) * 100
        + 50
FROM dbo.Extended_Creation_Text AS ect
LEFT JOIN dbo.TRPG_Session AS ts
    ON ts.session_id = ect.session_id
LEFT JOIN dbo.Scene AS s
    ON s.scene_id = ect.scene_id;
GO

/* -------------------------------------------------------------------------
   8. Single-team story JSON export
   ------------------------------------------------------------------------- */

CREATE OR ALTER PROCEDURE dbo.usp_Get_Team_Story_Export
    @team_id INT = NULL,
    @team_code NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @resolved_team_id INT;
    DECLARE @match_count INT;

    IF @team_id IS NOT NULL
    BEGIN
        SELECT @match_count = COUNT(*)
        FROM dbo.Team
        WHERE team_id = @team_id;

        IF @match_count = 0
        BEGIN
            THROW 51030, N'No team matched @team_id.', 1;
        END;

        SET @resolved_team_id = @team_id;
    END
    ELSE
    BEGIN
        IF @team_code IS NULL
        BEGIN
            THROW 51031, N'Provide @team_id or @team_code.', 1;
        END;

        SELECT @match_count = COUNT(*)
        FROM dbo.Team
        WHERE team_code = @team_code;

        IF @match_count = 0
        BEGIN
            THROW 51032, N'No team matched @team_code.', 1;
        END;

        IF @match_count > 1
        BEGIN
            THROW 51033, N'More than one team matched. Use @team_id.', 1;
        END;

        SELECT @resolved_team_id = team_id
        FROM dbo.Team
        WHERE team_code = @team_code;
    END;

    SELECT
        @resolved_team_id AS team_id,
        CONVERT(VARCHAR(19), SYSUTCDATETIME(), 126) + 'Z' AS exported_at_utc,
        JSON_QUERY
        (
            (
                SELECT
                    t.team_id,
                    t.team_code,
                    t.team_name,
                    t.cohort_code,
                    t.experiment_round_no,
                    t.condition_trpg,
                    t.condition_database,
                    t.condition_group,
                    t.assigned_gm_code,
                    t.planned_player_count,
                    t.actual_player_count,
                    t.team_status,
                    t.team_note,
                    rp.project_id,
                    rp.project_code,
                    rp.project_title
                FROM dbo.Team AS t
                INNER JOIN dbo.Research_Project AS rp
                    ON rp.project_id = t.project_id
                WHERE t.team_id = @resolved_team_id
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
            )
        ) AS team,
        JSON_QUERY
        (
            (
                SELECT
                    record_kind,
                    source_table,
                    source_id,
                    source_code,
                    session_id,
                    session_no,
                    scene_id,
                    scene_no,
                    record_no,
                    title,
                    type_label,
                    summary_text,
                    smm_note,
                    tms_note,
                    review_status,
                    include_in_analysis,
                    timeline_order
                FROM dbo.vw_Team_Story_Record
                WHERE team_id = @resolved_team_id
                  AND include_in_analysis = 1
                ORDER BY timeline_order, source_table, source_id
                FOR JSON PATH
            )
        ) AS records,
        JSON_QUERY
        (
            (
                SELECT
                    record_kind AS label,
                    COUNT_BIG(*) AS metric_value
                FROM dbo.vw_Team_Story_Record
                WHERE team_id = @resolved_team_id
                  AND include_in_analysis = 1
                GROUP BY record_kind
                ORDER BY record_kind
                FOR JSON PATH
            )
        ) AS record_counts
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
END;
GO

/* -------------------------------------------------------------------------
   9. Web character creation
   ------------------------------------------------------------------------- */

CREATE OR ALTER PROCEDURE dbo.usp_Create_Player_Character_From_Web
    @team_member_id INT = NULL,
    @team_code NVARCHAR(50) = NULL,
    @member_code NVARCHAR(50) = NULL,
    @character_code NVARCHAR(50),
    @character_name NVARCHAR(100),
    @character_type NVARCHAR(50) = N'player_character',
    @archetype NVARCHAR(100) = NULL,
    @race_or_species NVARCHAR(100) = NULL,
    @class_or_profession NVARCHAR(100) = NULL,
    @faction NVARCHAR(100) = NULL,
    @background_story_raw NVARCHAR(MAX) = NULL,
    @personality_note NVARCHAR(MAX) = NULL,
    @motivation_note NVARCHAR(MAX) = NULL,
    @relationship_note NVARCHAR(MAX) = NULL,
    @ability_note NVARCHAR(MAX) = NULL,
    @item_note NVARCHAR(MAX) = NULL,
    @narrative_function NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @resolved_team_member_id INT;
    DECLARE @match_count INT;
    DECLARE @new_character_id INT;

    IF @character_code IS NULL OR LEN(LTRIM(RTRIM(@character_code))) = 0
    BEGIN
        THROW 51040, N'@character_code is required.', 1;
    END;

    IF @character_name IS NULL OR LEN(LTRIM(RTRIM(@character_name))) = 0
    BEGIN
        THROW 51041, N'@character_name is required.', 1;
    END;

    SET @character_type = COALESCE(NULLIF(LTRIM(RTRIM(@character_type)), N''), N'player_character');

    IF @character_type NOT IN (N'player_character', N'sub_character', N'temporary_character')
    BEGIN
        THROW 51042, N'@character_type is invalid.', 1;
    END;

    IF @team_member_id IS NOT NULL
    BEGIN
        SELECT @match_count = COUNT(*)
        FROM dbo.Team_Member
        WHERE team_member_id = @team_member_id;

        IF @match_count = 0
        BEGIN
            THROW 51043, N'No team member matched @team_member_id.', 1;
        END;

        SET @resolved_team_member_id = @team_member_id;
    END
    ELSE
    BEGIN
        IF @team_code IS NULL OR @member_code IS NULL
        BEGIN
            THROW 51044, N'Provide @team_member_id, or provide @team_code and @member_code.', 1;
        END;

        SELECT @match_count = COUNT(*)
        FROM dbo.Team_Member AS tm
        INNER JOIN dbo.Team AS t
            ON t.team_id = tm.team_id
        WHERE t.team_code = @team_code
          AND tm.member_code = @member_code;

        IF @match_count = 0
        BEGIN
            THROW 51045, N'No team member matched @team_code and @member_code.', 1;
        END;

        IF @match_count > 1
        BEGIN
            THROW 51046, N'More than one team member matched. Use @team_member_id.', 1;
        END;

        SELECT @resolved_team_member_id = tm.team_member_id
        FROM dbo.Team_Member AS tm
        INNER JOIN dbo.Team AS t
            ON t.team_id = tm.team_id
        WHERE t.team_code = @team_code
          AND tm.member_code = @member_code;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.Player_Character
        WHERE team_member_id = @resolved_team_member_id
          AND character_code = @character_code
    )
    BEGIN
        THROW 51047, N'The character_code already exists for this team member.', 1;
    END;

    INSERT INTO dbo.Player_Character
    (
        team_member_id,
        character_code,
        character_name,
        character_type,
        archetype,
        race_or_species,
        class_or_profession,
        faction,
        background_story_raw,
        personality_note,
        motivation_note,
        relationship_note,
        ability_note,
        item_note,
        narrative_function,
        character_status
    )
    VALUES
    (
        @resolved_team_member_id,
        LTRIM(RTRIM(@character_code)),
        LTRIM(RTRIM(@character_name)),
        @character_type,
        @archetype,
        @race_or_species,
        @class_or_profession,
        @faction,
        @background_story_raw,
        @personality_note,
        @motivation_note,
        @relationship_note,
        @ability_note,
        @item_note,
        @narrative_function,
        N'in_play'
    );

    SET @new_character_id = CONVERT(INT, SCOPE_IDENTITY());

    SELECT
        @new_character_id AS character_id,
        @resolved_team_member_id AS team_member_id,
        LTRIM(RTRIM(@character_code)) AS character_code,
        LTRIM(RTRIM(@character_name)) AS character_name
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
END;
GO

/* -------------------------------------------------------------------------
   10. Single-character JSON export
   ------------------------------------------------------------------------- */

CREATE OR ALTER PROCEDURE dbo.usp_Get_Character_Profile_Export
    @character_id INT = NULL,
    @team_code NVARCHAR(50) = NULL,
    @member_code NVARCHAR(50) = NULL,
    @character_code NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @resolved_character_id INT;
    DECLARE @match_count INT;

    IF @character_id IS NOT NULL
    BEGIN
        SELECT @match_count = COUNT(*)
        FROM dbo.vw_Character_Profile
        WHERE character_id = @character_id;

        IF @match_count = 0
        BEGIN
            THROW 51000, N'No character matched @character_id.', 1;
        END;

        SET @resolved_character_id = @character_id;
    END
    ELSE
    BEGIN
        IF @character_code IS NULL
        BEGIN
            THROW 51001, N'Provide @character_id, or provide @character_code with optional @team_code and @member_code.', 1;
        END;

        SELECT @match_count = COUNT(*)
        FROM dbo.vw_Character_Profile
        WHERE character_code = @character_code
          AND (@team_code IS NULL OR team_code = @team_code)
          AND (@member_code IS NULL OR member_code = @member_code);

        IF @match_count = 0
        BEGIN
            THROW 51002, N'No character matched the supplied code filters.', 1;
        END;

        IF @match_count > 1
        BEGIN
            THROW 51003, N'More than one character matched. Add @team_code, @member_code, or use @character_id.', 1;
        END;

        SELECT @resolved_character_id = character_id
        FROM dbo.vw_Character_Profile
        WHERE character_code = @character_code
          AND (@team_code IS NULL OR team_code = @team_code)
          AND (@member_code IS NULL OR member_code = @member_code);
    END;

    SELECT
        @resolved_character_id AS character_id,
        CONVERT(VARCHAR(19), SYSUTCDATETIME(), 126) + 'Z' AS exported_at_utc,
        JSON_QUERY
        (
            (
                SELECT
                    character_id,
                    character_code,
                    character_name,
                    character_type,
                    archetype,
                    race_or_species,
                    class_or_profession,
                    faction,
                    background_story,
                    personality_note,
                    motivation_note,
                    relationship_note,
                    ability_note,
                    item_note,
                    narrative_function,
                    is_active,
                    character_status,
                    team_member_id,
                    member_code,
                    member_role,
                    seat_no,
                    team_id,
                    team_code,
                    team_name,
                    condition_group,
                    player_id,
                    player_code,
                    trpg_experience_level,
                    writing_experience_level,
                    game_experience_level,
                    ai_tool_experience_level,
                    database_experience_level,
                    utterance_count,
                    dialogue_count,
                    action_count,
                    decision_utterance_count,
                    question_count,
                    emotion_labeled_utterance_count,
                    targeted_utterance_count,
                    plot_event_count,
                    actor_event_count,
                    target_event_count,
                    high_importance_event_count,
                    decision_count,
                    proposed_decision_count,
                    final_actor_decision_count,
                    high_consensus_decision_count,
                    knowledge_retrieval_count,
                    successful_retrieval_count,
                    item_count,
                    clue_item_count,
                    unique_item_count,
                    created_at,
                    updated_at
                FROM dbo.vw_Character_Profile
                WHERE character_id = @resolved_character_id
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
            )
        ) AS profile,
        JSON_QUERY
        (
            (
                SELECT
                    section_name,
                    source_table,
                    source_id,
                    source_column,
                    source_title,
                    source_text,
                    session_no,
                    scene_no,
                    turn_no,
                    section_order,
                    source_order
                FROM dbo.vw_Character_Profile_Section
                WHERE character_id = @resolved_character_id
                ORDER BY section_order, source_order, source_table, source_id
                FOR JSON PATH
            )
        ) AS sections,
        JSON_QUERY
        (
            (
                SELECT
                    timeline_kind,
                    source_table,
                    source_id,
                    source_code,
                    type_label,
                    role_label,
                    session_no,
                    scene_no,
                    turn_no,
                    source_no,
                    title,
                    summary_text,
                    emotion_label,
                    importance_label,
                    review_status,
                    timeline_order
                FROM dbo.vw_Character_Timeline
                WHERE character_id = @resolved_character_id
                ORDER BY timeline_order, source_table, source_id
                FOR JSON PATH
            )
        ) AS timeline,
        JSON_QUERY
        (
            (
                SELECT
                    chart_key,
                    chart_title,
                    label,
                    metric_value,
                    metric_order
                FROM dbo.vw_Character_Chart_Data
                WHERE character_id = @resolved_character_id
                ORDER BY chart_key, metric_order, label
                FOR JSON PATH
            )
        ) AS charts,
        JSON_QUERY
        (
            (
                SELECT
                    image_slot,
                    image_file_name,
                    image_mime_type,
                    image_size_bytes,
                    image_data_url,
                    image_alt_text,
                    image_note,
                    created_at,
                    updated_at
                FROM dbo.Character_Profile_Image
                WHERE character_id = @resolved_character_id
                ORDER BY
                    CASE image_slot
                        WHEN N'headshot' THEN 1
                        WHEN N'fullbody' THEN 2
                        ELSE 99
                    END
                FOR JSON PATH
            )
        ) AS images,
        JSON_QUERY
        (
            (
                SELECT
                    freeform_field_id,
                    field_key,
                    field_label,
                    field_value,
                    display_order,
                    is_visible,
                    created_at,
                    updated_at
                FROM dbo.Character_Freeform_Field
                WHERE character_id = @resolved_character_id
                  AND is_visible = 1
                ORDER BY display_order, freeform_field_id
                FOR JSON PATH
            )
        ) AS freeform_fields
    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
END;
GO

/* -------------------------------------------------------------------------
   11. Character image and freeform save procedures
   ------------------------------------------------------------------------- */

CREATE OR ALTER PROCEDURE dbo.usp_Save_Character_Profile_Image
    @character_id INT,
    @image_slot NVARCHAR(50),
    @image_file_name NVARCHAR(260) = NULL,
    @image_mime_type NVARCHAR(100) = NULL,
    @image_size_bytes INT = NULL,
    @image_data_url NVARCHAR(MAX) = NULL,
    @image_alt_text NVARCHAR(200) = NULL,
    @image_note NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Player_Character
        WHERE character_id = @character_id
    )
    BEGIN
        THROW 51010, N'No character matched @character_id.', 1;
    END;

    IF @image_slot NOT IN (N'headshot', N'fullbody')
    BEGIN
        THROW 51011, N'@image_slot must be headshot or fullbody.', 1;
    END;

    MERGE dbo.Character_Profile_Image AS target
    USING
    (
        SELECT
            @character_id AS character_id,
            @image_slot AS image_slot
    ) AS source
    ON target.character_id = source.character_id
       AND target.image_slot = source.image_slot
    WHEN MATCHED THEN
        UPDATE SET
            image_file_name = @image_file_name,
            image_mime_type = @image_mime_type,
            image_size_bytes = @image_size_bytes,
            image_data_url = @image_data_url,
            image_alt_text = @image_alt_text,
            image_note = @image_note,
            updated_at = SYSDATETIME()
    WHEN NOT MATCHED THEN
        INSERT
        (
            character_id,
            image_slot,
            image_file_name,
            image_mime_type,
            image_size_bytes,
            image_data_url,
            image_alt_text,
            image_note
        )
        VALUES
        (
            @character_id,
            @image_slot,
            @image_file_name,
            @image_mime_type,
            @image_size_bytes,
            @image_data_url,
            @image_alt_text,
            @image_note
        );
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Clear_Character_Profile_Image
    @character_id INT,
    @image_slot NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM dbo.Character_Profile_Image
    WHERE character_id = @character_id
      AND image_slot = @image_slot;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Save_Character_Freeform_Fields
    @character_id INT,
    @fields_json NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.Player_Character
        WHERE character_id = @character_id
    )
    BEGIN
        THROW 51020, N'No character matched @character_id.', 1;
    END;

    IF ISJSON(@fields_json) <> 1
    BEGIN
        THROW 51021, N'@fields_json must be a JSON array.', 1;
    END;

    DECLARE @ParsedFields TABLE
    (
        field_key NVARCHAR(100) NOT NULL,
        field_label NVARCHAR(200) NOT NULL,
        field_value NVARCHAR(MAX) NULL,
        display_order INT NOT NULL
    );

    INSERT INTO @ParsedFields
    (
        field_key,
        field_label,
        field_value,
        display_order
    )
    SELECT
        LEFT(LTRIM(RTRIM(COALESCE(field_key, N''))), 100) AS field_key,
        LEFT(LTRIM(RTRIM(COALESCE(field_label, N''))), 200) AS field_label,
        field_value,
        ROW_NUMBER() OVER (ORDER BY display_order, json_order) AS display_order
    FROM
    (
        SELECT
            TRY_CONVERT(INT, field_rows.[key]) AS json_order,
            field_data.field_key,
            field_data.field_label,
            field_data.field_value,
            COALESCE(field_data.display_order, TRY_CONVERT(INT, field_rows.[key]) + 1, 1) AS display_order
        FROM OPENJSON(@fields_json) AS field_rows
        CROSS APPLY OPENJSON(field_rows.value)
        WITH
        (
            field_key NVARCHAR(100) '$.field_key',
            field_label NVARCHAR(200) '$.field_label',
            field_value NVARCHAR(MAX) '$.field_value',
            display_order INT '$.display_order'
        ) AS field_data
    ) AS parsed
    WHERE LEN(LTRIM(RTRIM(COALESCE(field_key, N'')))) > 0
      AND LEN(LTRIM(RTRIM(COALESCE(field_label, N'')))) > 0;

    DELETE FROM dbo.Character_Freeform_Field
    WHERE character_id = @character_id;

    INSERT INTO dbo.Character_Freeform_Field
    (
        character_id,
        field_key,
        field_label,
        field_value,
        display_order,
        is_visible
    )
    SELECT
        @character_id,
        field_key,
        field_label,
        field_value,
        display_order,
        1
    FROM @ParsedFields;
END;
GO
