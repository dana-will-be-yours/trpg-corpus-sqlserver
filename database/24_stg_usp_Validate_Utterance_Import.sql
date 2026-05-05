USE TRPG_Corpus_DB;
GO

CREATE OR ALTER PROCEDURE stg.usp_Validate_Utterance_Import
    @batch_code NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @import_batch_id BIGINT;

    SELECT
        @import_batch_id = ib.import_batch_id
    FROM stg.Import_Batch AS ib
    WHERE ib.batch_code = @batch_code;

    IF @import_batch_id IS NULL
    BEGIN
        THROW 51001, N'找不到指定 batch_code。', 1;
    END;

    UPDATE stg.Import_Batch
        SET import_status = N'checking'
    WHERE import_batch_id = @import_batch_id;

    ;WITH Base AS
    (
        SELECT
            ui.utterance_import_id,
            ui.import_batch_id,
            ui.source_row_no,

            LTRIM(RTRIM(ui.project_code)) AS project_code_trim,
            LTRIM(RTRIM(ui.team_code)) AS team_code_trim,
            LTRIM(RTRIM(ui.session_code)) AS session_code_trim,
            NULLIF(LTRIM(RTRIM(ui.scene_code)), N'') AS scene_code_trim,

            TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(ui.turn_no_text)), N'')) AS turn_no_value,
            TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(ui.sub_turn_no_text)), N'')) AS sub_turn_no_value,

            COALESCE(
                NULLIF(LTRIM(RTRIM(ui.utterance_code)), N''),
                CONCAT(
                    LTRIM(RTRIM(ui.session_code)),
                    N'_U',
                    RIGHT(N'000000' + LTRIM(RTRIM(ui.turn_no_text)), 6)
                )
            ) AS effective_utterance_code,

            LTRIM(RTRIM(ui.speaker_type)) AS speaker_type_trim,
            NULLIF(LTRIM(RTRIM(ui.speaker_code)), N'') AS speaker_code_trim,
            LTRIM(RTRIM(ui.utterance_function)) AS utterance_function_trim,

            CASE
                WHEN UPPER(LTRIM(RTRIM(ui.is_in_character_text))) IN (N'1', N'TRUE', N'Y', N'YES', N'是') THEN CONVERT(BIT, 1)
                WHEN UPPER(LTRIM(RTRIM(ui.is_in_character_text))) IN (N'0', N'FALSE', N'N', N'NO', N'否') THEN CONVERT(BIT, 0)
                ELSE NULL
            END AS is_in_character_value,

            CASE
                WHEN ui.is_gm_narration_text IS NULL OR LTRIM(RTRIM(ui.is_gm_narration_text)) = N'' THEN CONVERT(BIT, 0)
                WHEN UPPER(LTRIM(RTRIM(ui.is_gm_narration_text))) IN (N'1', N'TRUE', N'Y', N'YES', N'是') THEN CONVERT(BIT, 1)
                WHEN UPPER(LTRIM(RTRIM(ui.is_gm_narration_text))) IN (N'0', N'FALSE', N'N', N'NO', N'否') THEN CONVERT(BIT, 0)
                ELSE NULL
            END AS is_gm_narration_value,

            CASE
                WHEN ui.is_rule_related_text IS NULL OR LTRIM(RTRIM(ui.is_rule_related_text)) = N'' THEN CONVERT(BIT, 0)
                WHEN UPPER(LTRIM(RTRIM(ui.is_rule_related_text))) IN (N'1', N'TRUE', N'Y', N'YES', N'是') THEN CONVERT(BIT, 1)
                WHEN UPPER(LTRIM(RTRIM(ui.is_rule_related_text))) IN (N'0', N'FALSE', N'N', N'NO', N'否') THEN CONVERT(BIT, 0)
                ELSE NULL
            END AS is_rule_related_value,

            CASE
                WHEN ui.is_decision_related_text IS NULL OR LTRIM(RTRIM(ui.is_decision_related_text)) = N'' THEN CONVERT(BIT, 0)
                WHEN UPPER(LTRIM(RTRIM(ui.is_decision_related_text))) IN (N'1', N'TRUE', N'Y', N'YES', N'是') THEN CONVERT(BIT, 1)
                WHEN UPPER(LTRIM(RTRIM(ui.is_decision_related_text))) IN (N'0', N'FALSE', N'N', N'NO', N'否') THEN CONVERT(BIT, 0)
                ELSE NULL
            END AS is_decision_related_value,

            CASE
                WHEN ui.is_knowledge_related_text IS NULL OR LTRIM(RTRIM(ui.is_knowledge_related_text)) = N'' THEN CONVERT(BIT, 0)
                WHEN UPPER(LTRIM(RTRIM(ui.is_knowledge_related_text))) IN (N'1', N'TRUE', N'Y', N'YES', N'是') THEN CONVERT(BIT, 1)
                WHEN UPPER(LTRIM(RTRIM(ui.is_knowledge_related_text))) IN (N'0', N'FALSE', N'N', N'NO', N'否') THEN CONVERT(BIT, 0)
                ELSE NULL
            END AS is_knowledge_related_value,

            TRY_CONVERT(DECIMAL(10,2), NULLIF(LTRIM(RTRIM(ui.duration_sec_text)), N'')) AS duration_sec_value,
            TRY_CONVERT(DECIMAL(5,4), NULLIF(LTRIM(RTRIM(ui.transcription_confidence_text)), N'')) AS transcription_confidence_value,

            CASE
                WHEN ui.include_in_analysis_text IS NULL OR LTRIM(RTRIM(ui.include_in_analysis_text)) = N'' THEN CONVERT(BIT, 1)
                WHEN UPPER(LTRIM(RTRIM(ui.include_in_analysis_text))) IN (N'1', N'TRUE', N'Y', N'YES', N'是') THEN CONVERT(BIT, 1)
                WHEN UPPER(LTRIM(RTRIM(ui.include_in_analysis_text))) IN (N'0', N'FALSE', N'N', N'NO', N'否') THEN CONVERT(BIT, 0)
                ELSE NULL
            END AS include_in_analysis_value,

            NULLIF(LTRIM(RTRIM(ui.language_code)), N'') AS language_code_trim,
            NULLIF(LTRIM(RTRIM(ui.review_status)), N'') AS review_status_trim,
            NULLIF(LTRIM(RTRIM(ui.emotion_label)), N'') AS emotion_label_trim,
            NULLIF(LTRIM(RTRIM(ui.interaction_target_type)), N'') AS interaction_target_type_trim,
            NULLIF(LTRIM(RTRIM(ui.interaction_target_code)), N'') AS interaction_target_code_trim,
            NULLIF(LTRIM(RTRIM(ui.related_rule_code)), N'') AS related_rule_code_trim,
            NULLIF(LTRIM(RTRIM(ui.related_world_setting_code)), N'') AS related_world_setting_code_trim,
            NULLIF(LTRIM(RTRIM(ui.related_item_code)), N'') AS related_item_code_trim,
            NULLIF(LTRIM(RTRIM(ui.exclusion_reason)), N'') AS exclusion_reason_trim,

            ui.duration_sec_text,
            ui.transcription_confidence_text,
            ui.utterance_text_raw
        FROM stg.Utterance_Import AS ui
        WHERE ui.import_batch_id = @import_batch_id
    ),
    Mapped AS
    (
        SELECT
            b.*,

            rp.project_id,
            t.team_id,
            s.session_id,
            sc.scene_id,

            tm_speaker.team_member_id AS speaker_member_id,
            pc_speaker.character_id AS speaker_character_id,
            npc_speaker.npc_id AS speaker_npc_id,

            tm_target.team_member_id AS target_member_id,
            pc_target.character_id AS target_character_id,
            npc_target.npc_id AS target_npc_id,

            gr.rule_id AS related_rule_id,
            ws.world_setting_id AS related_world_setting_id,
            it.item_id AS related_item_id,

            COUNT(*) OVER (
                PARTITION BY b.import_batch_id, b.session_code_trim, b.turn_no_value
            ) AS batch_turn_dup_count,

            COUNT(*) OVER (
                PARTITION BY b.import_batch_id, b.session_code_trim, b.effective_utterance_code
            ) AS batch_code_dup_count,

            u_turn.utterance_id AS existing_turn_utterance_id,
            u_code.utterance_id AS existing_code_utterance_id
        FROM Base AS b
        LEFT JOIN dbo.Research_Project AS rp
            ON rp.project_code = b.project_code_trim
        LEFT JOIN dbo.Team AS t
            ON t.project_id = rp.project_id
           AND t.team_code = b.team_code_trim
        LEFT JOIN dbo.TRPG_Session AS s
            ON s.team_id = t.team_id
           AND s.session_code = b.session_code_trim
        LEFT JOIN dbo.Scene AS sc
            ON sc.session_id = s.session_id
           AND sc.scene_code = b.scene_code_trim

        LEFT JOIN dbo.Team_Member AS tm_speaker
            ON tm_speaker.team_id = t.team_id
           AND tm_speaker.member_code = b.speaker_code_trim
           AND b.speaker_type_trim IN (N'GM', N'PL', N'Observer', N'Researcher')

        LEFT JOIN dbo.Player_Character AS pc_speaker
            ON pc_speaker.character_code = b.speaker_code_trim
           AND b.speaker_type_trim = N'PC'
        LEFT JOIN dbo.Team_Member AS pc_speaker_tm
            ON pc_speaker.team_member_id = pc_speaker_tm.team_member_id
           AND pc_speaker_tm.team_id = t.team_id

        LEFT JOIN dbo.NPC AS npc_speaker
            ON npc_speaker.team_id = t.team_id
           AND npc_speaker.npc_code = b.speaker_code_trim
           AND b.speaker_type_trim = N'NPC'

        LEFT JOIN dbo.Team_Member AS tm_target
            ON tm_target.team_id = t.team_id
           AND tm_target.member_code = b.interaction_target_code_trim
           AND b.interaction_target_type_trim = N'team_member'

        LEFT JOIN dbo.Player_Character AS pc_target
            ON pc_target.character_code = b.interaction_target_code_trim
           AND b.interaction_target_type_trim = N'player_character'
        LEFT JOIN dbo.Team_Member AS pc_target_tm
            ON pc_target.team_member_id = pc_target_tm.team_member_id
           AND pc_target_tm.team_id = t.team_id

        LEFT JOIN dbo.NPC AS npc_target
            ON npc_target.team_id = t.team_id
           AND npc_target.npc_code = b.interaction_target_code_trim
           AND b.interaction_target_type_trim = N'npc'

        LEFT JOIN dbo.Game_Rule AS gr
            ON gr.project_id = rp.project_id
           AND gr.rule_code = b.related_rule_code_trim

        LEFT JOIN dbo.World_Setting AS ws
            ON ws.project_id = rp.project_id
           AND ws.setting_code = b.related_world_setting_code_trim
           AND (
                ws.team_id = t.team_id
                OR ws.team_id IS NULL
           )

        LEFT JOIN dbo.Item AS it
            ON it.team_id = t.team_id
           AND it.item_code = b.related_item_code_trim

        LEFT JOIN dbo.Utterance AS u_turn
            ON u_turn.session_id = s.session_id
           AND u_turn.turn_no = b.turn_no_value

        LEFT JOIN dbo.Utterance AS u_code
            ON u_code.session_id = s.session_id
           AND u_code.utterance_code = b.effective_utterance_code
    ),
    Validated AS
    (
        SELECT
            m.utterance_import_id,

            NULLIF(CONCAT_WS(CHAR(10),

                CASE WHEN m.project_id IS NULL
                    THEN N'project_code 找不到對應 dbo.Research_Project。' END,

                CASE WHEN m.team_id IS NULL
                    THEN N'team_code 找不到對應 dbo.Team，或 team_code 不屬於 project_code。' END,

                CASE WHEN m.session_id IS NULL
                    THEN N'session_code 找不到對應 dbo.TRPG_Session，或 session_code 不屬於 team_code。' END,

                CASE WHEN m.scene_code_trim IS NOT NULL AND m.scene_id IS NULL
                    THEN N'scene_code 找不到對應 dbo.Scene，或 scene_code 不屬於 session_code。' END,

                CASE WHEN m.turn_no_value IS NULL
                    THEN N'turn_no_text 無法轉為 INT。' END,

                CASE WHEN m.turn_no_value IS NOT NULL AND m.turn_no_value < 1
                    THEN N'turn_no 必須大於等於 1。' END,

                CASE WHEN m.sub_turn_no_value IS NOT NULL AND m.sub_turn_no_value < 1
                    THEN N'sub_turn_no 必須大於等於 1。' END,

                CASE WHEN m.speaker_type_trim NOT IN (N'GM', N'PL', N'PC', N'NPC', N'Observer', N'Researcher')
                    THEN N'speaker_type 不在允許值內。' END,

                CASE WHEN m.utterance_function_trim NOT IN
                    (
                        N'narration',
                        N'dialogue',
                        N'action',
                        N'rule_check',
                        N'decision',
                        N'negotiation',
                        N'question',
                        N'clarification',
                        N'conflict',
                        N'summary'
                    )
                    THEN N'utterance_function 不在允許值內。' END,

                CASE WHEN m.is_in_character_value IS NULL
                    THEN N'is_in_character_text 無法轉為 BIT。允許 1、0、true、false、yes、no、是、否。' END,

                CASE WHEN m.is_gm_narration_value IS NULL
                    THEN N'is_gm_narration_text 無法轉為 BIT。' END,

                CASE WHEN m.is_rule_related_value IS NULL
                    THEN N'is_rule_related_text 無法轉為 BIT。' END,

                CASE WHEN m.is_decision_related_value IS NULL
                    THEN N'is_decision_related_text 無法轉為 BIT。' END,

                CASE WHEN m.is_knowledge_related_value IS NULL
                    THEN N'is_knowledge_related_text 無法轉為 BIT。' END,

                CASE WHEN m.include_in_analysis_value IS NULL
                    THEN N'include_in_analysis_text 無法轉為 BIT。' END,

                CASE WHEN m.duration_sec_text IS NOT NULL
                           AND LTRIM(RTRIM(m.duration_sec_text)) <> N''
                           AND m.duration_sec_value IS NULL
                    THEN N'duration_sec_text 無法轉為 DECIMAL(10,2)。' END,

                CASE WHEN m.duration_sec_value IS NOT NULL AND m.duration_sec_value < 0
                    THEN N'duration_sec 不可小於 0。' END,

                CASE WHEN m.transcription_confidence_text IS NOT NULL
                           AND LTRIM(RTRIM(m.transcription_confidence_text)) <> N''
                           AND m.transcription_confidence_value IS NULL
                    THEN N'transcription_confidence_text 無法轉為 DECIMAL(5,4)。' END,

                CASE WHEN m.transcription_confidence_value IS NOT NULL
                           AND (m.transcription_confidence_value < 0 OR m.transcription_confidence_value > 1)
                    THEN N'transcription_confidence 必須介於 0 到 1。' END,

                CASE WHEN m.review_status_trim IS NOT NULL
                           AND m.review_status_trim NOT IN
                           (
                               N'draft',
                               N'ai_transcribed',
                               N'human_corrected',
                               N'cleaned',
                               N'verified',
                               N'excluded'
                           )
                    THEN N'review_status 不在 dbo.Utterance 允許值內。' END,

                CASE WHEN m.emotion_label_trim IS NOT NULL
                           AND m.emotion_label_trim NOT IN
                           (
                               N'neutral',
                               N'positive',
                               N'negative',
                               N'confused',
                               N'excited',
                               N'tense',
                               N'humorous',
                               N'uncertain',
                               N'other'
                           )
                    THEN N'emotion_label 不在 dbo.Utterance 允許值內。' END,

                CASE WHEN m.interaction_target_type_trim IS NOT NULL
                           AND m.interaction_target_type_trim NOT IN
                           (
                               N'team_member',
                               N'player_character',
                               N'npc',
                               N'group',
                               N'system',
                               N'unknown'
                           )
                    THEN N'interaction_target_type 不在 dbo.Utterance 允許值內。' END,

                CASE WHEN m.speaker_type_trim IN (N'GM', N'PL', N'Observer', N'Researcher')
                           AND m.speaker_code_trim IS NULL
                    THEN N'speaker_type 為 GM、PL、Observer、Researcher 時，speaker_code 必填。' END,

                CASE WHEN m.speaker_type_trim = N'PC'
                           AND m.speaker_code_trim IS NULL
                    THEN N'speaker_type 為 PC 時，speaker_code 必填，且需對應 Player_Character.character_code。' END,

                CASE WHEN m.speaker_type_trim = N'NPC'
                           AND m.speaker_code_trim IS NULL
                    THEN N'speaker_type 為 NPC 時，speaker_code 必填，且需對應 NPC.npc_code。' END,

                CASE WHEN m.speaker_type_trim IN (N'GM', N'PL', N'Observer', N'Researcher')
                           AND m.speaker_code_trim IS NOT NULL
                           AND m.speaker_member_id IS NULL
                    THEN N'speaker_code 找不到對應 dbo.Team_Member.member_code。' END,

                CASE WHEN m.speaker_type_trim = N'PC'
                           AND m.speaker_code_trim IS NOT NULL
                           AND m.speaker_character_id IS NULL
                    THEN N'speaker_code 找不到對應 dbo.Player_Character.character_code，或該角色不屬於此 team_code。' END,

                CASE WHEN m.speaker_type_trim = N'NPC'
                           AND m.speaker_code_trim IS NOT NULL
                           AND m.speaker_npc_id IS NULL
                    THEN N'speaker_code 找不到對應 dbo.NPC.npc_code，或該 NPC 不屬於此 team_code。' END,

                CASE WHEN m.speaker_type_trim IN (N'PC', N'NPC')
                           AND m.is_in_character_value = 0
                    THEN N'PC 或 NPC 發言時 is_in_character 必須為 1。' END,

                CASE WHEN m.speaker_type_trim IN (N'GM', N'PL', N'Observer', N'Researcher')
                           AND m.is_in_character_value = 1
                    THEN N'GM、PL、Observer、Researcher 發言時 is_in_character 必須為 0。' END,

                CASE WHEN m.is_gm_narration_value = 1
                           AND NOT (m.speaker_type_trim = N'GM' AND m.utterance_function_trim = N'narration')
                    THEN N'is_gm_narration = 1 時，speaker_type 必須為 GM 且 utterance_function 必須為 narration。' END,

                CASE WHEN m.is_rule_related_value = 1
                           AND m.utterance_function_trim <> N'rule_check'
                           AND m.related_rule_id IS NULL
                    THEN N'is_rule_related = 1 時，utterance_function 應為 rule_check 或 related_rule_code 必須可對應 Game_Rule。' END,

                CASE WHEN m.is_decision_related_value = 1
                           AND m.utterance_function_trim NOT IN (N'decision', N'negotiation', N'clarification')
                    THEN N'is_decision_related = 1 時，utterance_function 必須為 decision、negotiation 或 clarification。' END,

                CASE WHEN m.is_knowledge_related_value = 1
                           AND m.utterance_function_trim NOT IN (N'question', N'clarification', N'summary')
                           AND m.related_world_setting_id IS NULL
                           AND m.related_item_id IS NULL
                    THEN N'is_knowledge_related = 1 時，utterance_function 應為 question、clarification、summary，或需連到世界觀 / 物件。' END,

                CASE WHEN m.interaction_target_type_trim = N'team_member'
                           AND m.interaction_target_code_trim IS NOT NULL
                           AND m.target_member_id IS NULL
                    THEN N'interaction_target_code 找不到對應 Team_Member。' END,

                CASE WHEN m.interaction_target_type_trim = N'player_character'
                           AND m.interaction_target_code_trim IS NOT NULL
                           AND m.target_character_id IS NULL
                    THEN N'interaction_target_code 找不到對應 Player_Character。' END,

                CASE WHEN m.interaction_target_type_trim = N'npc'
                           AND m.interaction_target_code_trim IS NOT NULL
                           AND m.target_npc_id IS NULL
                    THEN N'interaction_target_code 找不到對應 NPC。' END,

                CASE WHEN m.related_rule_code_trim IS NOT NULL
                           AND m.related_rule_id IS NULL
                    THEN N'related_rule_code 找不到對應 dbo.Game_Rule.rule_code。' END,

                CASE WHEN m.related_world_setting_code_trim IS NOT NULL
                           AND m.related_world_setting_id IS NULL
                    THEN N'related_world_setting_code 找不到對應 dbo.World_Setting.setting_code。' END,

                CASE WHEN m.related_item_code_trim IS NOT NULL
                           AND m.related_item_id IS NULL
                    THEN N'related_item_code 找不到對應 dbo.Item.item_code。' END,

                CASE WHEN m.batch_turn_dup_count > 1
                    THEN N'同一匯入批次、同一 session_code 中 turn_no_text 重複。' END,

                CASE WHEN m.batch_code_dup_count > 1
                    THEN N'同一匯入批次、同一 session_code 中 utterance_code 重複。' END,

                CASE WHEN m.existing_turn_utterance_id IS NOT NULL
                    THEN N'dbo.Utterance 已存在相同 session_id + turn_no。' END,

                CASE WHEN m.existing_code_utterance_id IS NOT NULL
                    THEN N'dbo.Utterance 已存在相同 session_id + utterance_code。' END,

                CASE WHEN m.include_in_analysis_value = 0
                           AND m.exclusion_reason_trim IS NULL
                    THEN N'include_in_analysis = 0 時 exclusion_reason 必填。' END

            ), N'') AS error_text,

            NULLIF(CONCAT_WS(CHAR(10),

                CASE WHEN m.scene_code_trim IS NULL
                    THEN N'scene_code 為空，匯入 dbo.Utterance 時 scene_id 將為 NULL。' END,

                CASE WHEN m.effective_utterance_code <> NULLIF(LTRIM(RTRIM((SELECT ui.utterance_code FROM stg.Utterance_Import AS ui WHERE ui.utterance_import_id = m.utterance_import_id))), N'')
                    THEN N'utterance_code 為空，系統將依 session_code + turn_no_text 自動產生。' END,

                CASE WHEN m.review_status_trim IS NULL
                    THEN N'review_status 為空，匯入時將使用 draft。' END,

                CASE WHEN m.language_code_trim IS NULL
                    THEN N'language_code 為空，匯入時將使用 zh-TW。' END

            ), N'') AS warning_text
        FROM Mapped AS m
    )
    UPDATE ui
        SET
            validation_error = v.error_text,
            validation_warning = v.warning_text,
            import_status =
                CASE
                    WHEN v.error_text IS NOT NULL THEN N'error'
                    WHEN v.warning_text IS NOT NULL THEN N'warning'
                    ELSE N'valid'
                END
    FROM stg.Utterance_Import AS ui
    INNER JOIN Validated AS v
        ON ui.utterance_import_id = v.utterance_import_id;

    UPDATE stg.Import_Batch
        SET
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
                  AND import_status IN (N'valid', N'warning')
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
            ),
            import_status =
                CASE
                    WHEN EXISTS
                    (
                        SELECT 1
                        FROM stg.Utterance_Import
                        WHERE import_batch_id = @import_batch_id
                          AND import_status = N'error'
                    )
                    THEN N'has_error'
                    ELSE N'checked'
                END
    WHERE import_batch_id = @import_batch_id;

    SELECT
        ui.import_status,
        COUNT(*) AS row_count
    FROM stg.Utterance_Import AS ui
    WHERE ui.import_batch_id = @import_batch_id
    GROUP BY ui.import_status
    ORDER BY ui.import_status;
END;
GO