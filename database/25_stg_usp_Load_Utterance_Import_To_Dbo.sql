USE TRPG_Corpus_DB;
GO

CREATE OR ALTER PROCEDURE stg.usp_Load_Utterance_Import_To_Dbo
    @batch_code NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @import_batch_id BIGINT;
    DECLARE @error_count INT;

    SELECT
        @import_batch_id = ib.import_batch_id
    FROM stg.Import_Batch AS ib
    WHERE ib.batch_code = @batch_code;

    IF @import_batch_id IS NULL
    BEGIN
        THROW 52001, N'找不到指定 batch_code。', 1;
    END;

    EXEC stg.usp_Validate_Utterance_Import
        @batch_code = @batch_code;

    SELECT
        @error_count = COUNT(*)
    FROM stg.Utterance_Import AS ui
    WHERE ui.import_batch_id = @import_batch_id
      AND ui.import_status = N'error';

    IF @error_count > 0
    BEGIN
        THROW 52002, N'stg.Utterance_Import 尚有 error 資料列，停止匯入 dbo.Utterance。', 1;
    END;

    BEGIN TRANSACTION;

    ;WITH SourceRows AS
    (
        SELECT
            ui.utterance_import_id,

            rp.project_id,
            t.team_id,
            s.session_id,
            sc.scene_id,

            TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(ui.turn_no_text)), N'')) AS turn_no,
            TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(ui.sub_turn_no_text)), N'')) AS sub_turn_no,

            COALESCE(
                NULLIF(LTRIM(RTRIM(ui.utterance_code)), N''),
                CONCAT(
                    LTRIM(RTRIM(ui.session_code)),
                    N'_U',
                    RIGHT(N'000000' + LTRIM(RTRIM(ui.turn_no_text)), 6)
                )
            ) AS utterance_code,

            LTRIM(RTRIM(ui.speaker_type)) AS speaker_type,

            tm_speaker.team_member_id AS speaker_member_id,
            pc_speaker.character_id AS speaker_character_id,
            npc_speaker.npc_id AS speaker_npc_id,

            NULLIF(LTRIM(RTRIM(ui.speaker_label_raw)), N'') AS speaker_label_raw,
            LTRIM(RTRIM(ui.utterance_function)) AS utterance_function,

            CASE
                WHEN UPPER(LTRIM(RTRIM(ui.is_in_character_text))) IN (N'1', N'TRUE', N'Y', N'YES', N'是') THEN CONVERT(BIT, 1)
                ELSE CONVERT(BIT, 0)
            END AS is_in_character,

            CASE
                WHEN UPPER(LTRIM(RTRIM(ISNULL(ui.is_gm_narration_text, N'0')))) IN (N'1', N'TRUE', N'Y', N'YES', N'是') THEN CONVERT(BIT, 1)
                ELSE CONVERT(BIT, 0)
            END AS is_gm_narration,

            CASE
                WHEN UPPER(LTRIM(RTRIM(ISNULL(ui.is_rule_related_text, N'0')))) IN (N'1', N'TRUE', N'Y', N'YES', N'是') THEN CONVERT(BIT, 1)
                ELSE CONVERT(BIT, 0)
            END AS is_rule_related,

            CASE
                WHEN UPPER(LTRIM(RTRIM(ISNULL(ui.is_decision_related_text, N'0')))) IN (N'1', N'TRUE', N'Y', N'YES', N'是') THEN CONVERT(BIT, 1)
                ELSE CONVERT(BIT, 0)
            END AS is_decision_related,

            CASE
                WHEN UPPER(LTRIM(RTRIM(ISNULL(ui.is_knowledge_related_text, N'0')))) IN (N'1', N'TRUE', N'Y', N'YES', N'是') THEN CONVERT(BIT, 1)
                ELSE CONVERT(BIT, 0)
            END AS is_knowledge_related,

            NULLIF(LTRIM(RTRIM(ui.start_timecode)), N'') AS start_timecode,
            NULLIF(LTRIM(RTRIM(ui.end_timecode)), N'') AS end_timecode,
            TRY_CONVERT(DECIMAL(10,2), NULLIF(LTRIM(RTRIM(ui.duration_sec_text)), N'')) AS duration_sec,

            ui.utterance_text_raw,
            ui.utterance_text_clean,
            ui.utterance_text_verified,

            COALESCE(NULLIF(LTRIM(RTRIM(ui.language_code)), N''), N'zh-TW') AS language_code,

            NULLIF(LTRIM(RTRIM(ui.emotion_label)), N'') AS emotion_label,
            NULLIF(LTRIM(RTRIM(ui.interaction_target_type)), N'') AS interaction_target_type,

            tm_target.team_member_id AS interaction_target_member_id,
            pc_target.character_id AS interaction_target_character_id,
            npc_target.npc_id AS interaction_target_npc_id,

            gr.rule_id AS related_rule_id,
            ws.world_setting_id AS related_world_setting_id,
            it.item_id AS related_item_id,

            ui.ai_summary,
            ui.ai_annotation_json,
            ui.human_annotation_note,

            TRY_CONVERT(DECIMAL(5,4), NULLIF(LTRIM(RTRIM(ui.transcription_confidence_text)), N'')) AS transcription_confidence,

            COALESCE(NULLIF(LTRIM(RTRIM(ui.review_status)), N''), N'draft') AS review_status,

            CASE
                WHEN ui.include_in_analysis_text IS NULL OR LTRIM(RTRIM(ui.include_in_analysis_text)) = N'' THEN CONVERT(BIT, 1)
                WHEN UPPER(LTRIM(RTRIM(ui.include_in_analysis_text))) IN (N'1', N'TRUE', N'Y', N'YES', N'是') THEN CONVERT(BIT, 1)
                ELSE CONVERT(BIT, 0)
            END AS include_in_analysis,

            ui.exclusion_reason
        FROM stg.Utterance_Import AS ui
        INNER JOIN dbo.Research_Project AS rp
            ON rp.project_code = LTRIM(RTRIM(ui.project_code))
        INNER JOIN dbo.Team AS t
            ON t.project_id = rp.project_id
           AND t.team_code = LTRIM(RTRIM(ui.team_code))
        INNER JOIN dbo.TRPG_Session AS s
            ON s.team_id = t.team_id
           AND s.session_code = LTRIM(RTRIM(ui.session_code))
        LEFT JOIN dbo.Scene AS sc
            ON sc.session_id = s.session_id
           AND sc.scene_code = NULLIF(LTRIM(RTRIM(ui.scene_code)), N'')

        LEFT JOIN dbo.Team_Member AS tm_speaker
            ON tm_speaker.team_id = t.team_id
           AND tm_speaker.member_code = NULLIF(LTRIM(RTRIM(ui.speaker_code)), N'')
           AND LTRIM(RTRIM(ui.speaker_type)) IN (N'GM', N'PL', N'Observer', N'Researcher')

        LEFT JOIN dbo.Player_Character AS pc_speaker
            ON pc_speaker.character_code = NULLIF(LTRIM(RTRIM(ui.speaker_code)), N'')
           AND LTRIM(RTRIM(ui.speaker_type)) = N'PC'
        LEFT JOIN dbo.Team_Member AS pc_speaker_tm
            ON pc_speaker.team_member_id = pc_speaker_tm.team_member_id
           AND pc_speaker_tm.team_id = t.team_id

        LEFT JOIN dbo.NPC AS npc_speaker
            ON npc_speaker.team_id = t.team_id
           AND npc_speaker.npc_code = NULLIF(LTRIM(RTRIM(ui.speaker_code)), N'')
           AND LTRIM(RTRIM(ui.speaker_type)) = N'NPC'

        LEFT JOIN dbo.Team_Member AS tm_target
            ON tm_target.team_id = t.team_id
           AND tm_target.member_code = NULLIF(LTRIM(RTRIM(ui.interaction_target_code)), N'')
           AND NULLIF(LTRIM(RTRIM(ui.interaction_target_type)), N'') = N'team_member'

        LEFT JOIN dbo.Player_Character AS pc_target
            ON pc_target.character_code = NULLIF(LTRIM(RTRIM(ui.interaction_target_code)), N'')
           AND NULLIF(LTRIM(RTRIM(ui.interaction_target_type)), N'') = N'player_character'
        LEFT JOIN dbo.Team_Member AS pc_target_tm
            ON pc_target.team_member_id = pc_target_tm.team_member_id
           AND pc_target_tm.team_id = t.team_id

        LEFT JOIN dbo.NPC AS npc_target
            ON npc_target.team_id = t.team_id
           AND npc_target.npc_code = NULLIF(LTRIM(RTRIM(ui.interaction_target_code)), N'')
           AND NULLIF(LTRIM(RTRIM(ui.interaction_target_type)), N'') = N'npc'

        LEFT JOIN dbo.Game_Rule AS gr
            ON gr.project_id = rp.project_id
           AND gr.rule_code = NULLIF(LTRIM(RTRIM(ui.related_rule_code)), N'')

        LEFT JOIN dbo.World_Setting AS ws
            ON ws.project_id = rp.project_id
           AND ws.setting_code = NULLIF(LTRIM(RTRIM(ui.related_world_setting_code)), N'')
           AND (
                ws.team_id = t.team_id
                OR ws.team_id IS NULL
           )

        LEFT JOIN dbo.Item AS it
            ON it.team_id = t.team_id
           AND it.item_code = NULLIF(LTRIM(RTRIM(ui.related_item_code)), N'')

        WHERE ui.import_batch_id = @import_batch_id
          AND ui.import_status IN (N'valid', N'warning')
    )
    INSERT INTO dbo.Utterance
    (
        session_id,
        scene_id,
        turn_no,
        sub_turn_no,
        utterance_code,
        speaker_type,
        speaker_member_id,
        speaker_character_id,
        speaker_npc_id,
        speaker_label_raw,
        utterance_function,
        is_in_character,
        is_gm_narration,
        is_rule_related,
        is_decision_related,
        is_knowledge_related,
        start_timecode,
        end_timecode,
        duration_sec,
        utterance_text_raw,
        utterance_text_clean,
        utterance_text_verified,
        language_code,
        emotion_label,
        interaction_target_type,
        interaction_target_member_id,
        interaction_target_character_id,
        interaction_target_npc_id,
        related_rule_id,
        related_world_setting_id,
        related_item_id,
        ai_summary,
        ai_annotation_json,
        human_annotation_note,
        transcription_confidence,
        review_status,
        include_in_analysis,
        exclusion_reason
    )
    SELECT
        sr.session_id,
        sr.scene_id,
        sr.turn_no,
        sr.sub_turn_no,
        sr.utterance_code,
        sr.speaker_type,
        sr.speaker_member_id,
        sr.speaker_character_id,
        sr.speaker_npc_id,
        sr.speaker_label_raw,
        sr.utterance_function,
        sr.is_in_character,
        sr.is_gm_narration,
        sr.is_rule_related,
        sr.is_decision_related,
        sr.is_knowledge_related,
        sr.start_timecode,
        sr.end_timecode,
        sr.duration_sec,
        sr.utterance_text_raw,
        sr.utterance_text_clean,
        sr.utterance_text_verified,
        sr.language_code,
        sr.emotion_label,
        sr.interaction_target_type,
        sr.interaction_target_member_id,
        sr.interaction_target_character_id,
        sr.interaction_target_npc_id,
        sr.related_rule_id,
        sr.related_world_setting_id,
        sr.related_item_id,
        sr.ai_summary,
        sr.ai_annotation_json,
        sr.human_annotation_note,
        sr.transcription_confidence,
        sr.review_status,
        sr.include_in_analysis,
        sr.exclusion_reason
    FROM SourceRows AS sr
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.Utterance AS u
        WHERE u.session_id = sr.session_id
          AND u.turn_no = sr.turn_no
    )
      AND NOT EXISTS
    (
        SELECT 1
        FROM dbo.Utterance AS u
        WHERE u.session_id = sr.session_id
          AND u.utterance_code = sr.utterance_code
    );

    UPDATE ui
        SET import_status = N'loaded_to_dbo'
    FROM stg.Utterance_Import AS ui
    INNER JOIN dbo.Research_Project AS rp
        ON rp.project_code = LTRIM(RTRIM(ui.project_code))
    INNER JOIN dbo.Team AS t
        ON t.project_id = rp.project_id
       AND t.team_code = LTRIM(RTRIM(ui.team_code))
    INNER JOIN dbo.TRPG_Session AS s
        ON s.team_id = t.team_id
       AND s.session_code = LTRIM(RTRIM(ui.session_code))
    INNER JOIN dbo.Utterance AS u
        ON u.session_id = s.session_id
       AND u.utterance_code =
            COALESCE(
                NULLIF(LTRIM(RTRIM(ui.utterance_code)), N''),
                CONCAT(
                    LTRIM(RTRIM(ui.session_code)),
                    N'_U',
                    RIGHT(N'000000' + LTRIM(RTRIM(ui.turn_no_text)), 6)
                )
            )
    WHERE ui.import_batch_id = @import_batch_id
      AND ui.import_status IN (N'valid', N'warning');

    UPDATE stg.Import_Batch
        SET
            import_status = N'loaded_to_dbo',
            import_finished_at = SYSDATETIME(),
            total_row_count =
            (
                SELECT COUNT(*)
                FROM stg.Utterance_Import
                WHERE import_batch_id = @import_batch_id
            ),
            valid_row_count =
            (
                SELECT COUNT(*)
                FROM stg.Utterance_Import
                WHERE import_batch_id = @import_batch_id
                  AND import_status = N'loaded_to_dbo'
            ),
            invalid_row_count =
            (
                SELECT COUNT(*)
                FROM stg.Utterance_Import
                WHERE import_batch_id = @import_batch_id
                  AND import_status = N'error'
            ),
            warning_count =
            (
                SELECT COUNT(*)
                FROM stg.Utterance_Import
                WHERE import_batch_id = @import_batch_id
                  AND validation_warning IS NOT NULL
            ),
            error_count =
            (
                SELECT COUNT(*)
                FROM stg.Utterance_Import
                WHERE import_batch_id = @import_batch_id
                  AND validation_error IS NOT NULL
            )
    WHERE import_batch_id = @import_batch_id;

    COMMIT TRANSACTION;

    SELECT
        ui.import_status,
        COUNT(*) AS row_count
    FROM stg.Utterance_Import AS ui
    WHERE ui.import_batch_id = @import_batch_id
    GROUP BY ui.import_status
    ORDER BY ui.import_status;
END;
GO