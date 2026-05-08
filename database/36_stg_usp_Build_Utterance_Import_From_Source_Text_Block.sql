USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE stg.usp_Build_Utterance_Import_From_Source_Text_Block
    @source_document_code NVARCHAR(100),
    @batch_code NVARCHAR(100),
    @project_code NVARCHAR(50),
    @team_code NVARCHAR(50),
    @session_code NVARCHAR(50),
    @default_scene_code NVARCHAR(50) = NULL,
    @only_reviewed BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @source_document_import_id BIGINT;
    DECLARE @import_batch_id BIGINT;

    SELECT @source_document_import_id = source_document_import_id
    FROM stg.Source_Document_Import
    WHERE source_document_code = @source_document_code;

    IF @source_document_import_id IS NULL
    BEGIN
        THROW 51400, 'source_document_code not found.', 1;
    END;

    BEGIN TRANSACTION;

    IF NOT EXISTS (
        SELECT 1
        FROM stg.Import_Batch
        WHERE batch_code = @batch_code
    )
    BEGIN
        INSERT INTO stg.Import_Batch
        (
            batch_code,
            project_code,
            source_table_name,
            source_file_name,
            source_file_type,
            import_purpose,
            imported_by,
            import_status,
            total_row_count,
            import_note
        )
        SELECT
            @batch_code,
            @project_code,
            N'stg.Utterance_Import',
            sdi.file_name,
            COALESCE(NULLIF(sdi.file_extension, N''), N'unknown'),
            N'source document text blocks to utterance import',
            N'stg.usp_Build_Utterance_Import_From_Source_Text_Block',
            N'imported',
            COUNT(*),
            @source_document_code
        FROM stg.Source_Document_Import AS sdi
        INNER JOIN stg.Source_Text_Block_Import AS stb
            ON stb.source_document_import_id = sdi.source_document_import_id
        WHERE sdi.source_document_import_id = @source_document_import_id
          AND stb.block_type_candidate IN (
                N'utterance',
                N'action_note',
                N'dice_roll',
                N'dice_result',
                N'narration'
          )
          AND (
                @only_reviewed = 0
                OR stb.review_status IN (N'reviewed', N'verified')
          )
        GROUP BY sdi.file_name, sdi.file_extension;
    END;

    SELECT @import_batch_id = import_batch_id
    FROM stg.Import_Batch
    WHERE batch_code = @batch_code;

    IF EXISTS (
        SELECT 1
        FROM stg.Utterance_Import
        WHERE import_batch_id = @import_batch_id
    )
    BEGIN
        THROW 51401, 'Target stg.Utterance_Import batch already has rows.', 1;
    END;

    ;WITH Candidate AS
    (
        SELECT
            stb.*,
            ROW_NUMBER() OVER (ORDER BY stb.source_block_no) AS output_row_no
        FROM stg.Source_Text_Block_Import AS stb
        WHERE stb.source_document_import_id = @source_document_import_id
          AND stb.block_type_candidate IN (
                N'utterance',
                N'action_note',
                N'dice_roll',
                N'dice_result',
                N'narration'
          )
          AND (
                @only_reviewed = 0
                OR stb.review_status IN (N'reviewed', N'verified')
          )
          AND COALESCE(stb.include_in_analysis_text, N'1') NOT IN (N'0', N'false', N'FALSE', N'N', N'No', N'否')
    )
    INSERT INTO stg.Utterance_Import
    (
        import_batch_id,
        source_row_no,
        project_code,
        team_code,
        session_code,
        scene_code,
        turn_no_text,
        utterance_code,
        speaker_type,
        speaker_code,
        speaker_label_raw,
        utterance_function,
        is_in_character_text,
        is_gm_narration_text,
        is_rule_related_text,
        is_decision_related_text,
        is_knowledge_related_text,
        utterance_text_raw,
        utterance_text_clean,
        language_code,
        interaction_target_type,
        ai_annotation_json,
        review_status,
        include_in_analysis_text,
        import_status
    )
    SELECT
        @import_batch_id,
        c.output_row_no,
        @project_code,
        @team_code,
        @session_code,
        COALESCE(NULLIF(c.scene_code_candidate, N''), @default_scene_code),
        COALESCE(NULLIF(c.turn_no_text, N''), CONVERT(NVARCHAR(50), c.output_row_no)),
        CONCAT(@session_code, N'_U', RIGHT(N'000000' + CONVERT(NVARCHAR(20), c.output_row_no), 6)),
        COALESCE(NULLIF(c.speaker_type_candidate, N'Unknown'), N'Observer'),
        c.speaker_code_candidate,
        c.speaker_label_candidate,
        COALESCE(
            c.utterance_function_candidate,
            CASE
                WHEN c.block_type_candidate IN (N'dice_roll', N'dice_result') THEN N'rule_check'
                WHEN c.block_type_candidate = N'narration' THEN N'narration'
                WHEN c.block_type_candidate = N'action_note' THEN N'action'
                ELSE N'dialogue'
            END
        ),
        COALESCE(
            c.is_in_character_text,
            CASE
                WHEN c.speaker_type_candidate IN (N'PC', N'NPC') THEN N'1'
                ELSE N'0'
            END
        ),
        CASE
            WHEN c.speaker_type_candidate = N'GM'
             AND COALESCE(c.utterance_function_candidate, CASE WHEN c.block_type_candidate = N'narration' THEN N'narration' ELSE NULL END) = N'narration' THEN N'1'
            ELSE N'0'
        END,
        CASE WHEN c.block_type_candidate IN (N'dice_roll', N'dice_result') THEN N'1' ELSE N'0' END,
        CASE WHEN c.utterance_function_candidate IN (N'decision', N'negotiation', N'clarification') THEN N'1' ELSE N'0' END,
        CASE WHEN c.utterance_function_candidate IN (N'question', N'clarification', N'summary') THEN N'1' ELSE N'0' END,
        c.text_raw,
        COALESCE(c.text_clean, c.text_raw),
        N'zh-TW',
        N'unknown',
        (
            SELECT
                @source_document_code AS source_document_code,
                c.source_block_no AS source_block_no,
                c.paragraph_no AS paragraph_no,
                c.line_no AS line_no,
                c.block_type_candidate AS block_type_candidate
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ),
        N'draft',
        COALESCE(c.include_in_analysis_text, N'1'),
        N'raw'
    FROM Candidate AS c
    ORDER BY c.output_row_no;

    UPDATE stg.Source_Text_Block_Import
    SET
        import_status = N'converted_to_utterance_import',
        updated_at = SYSDATETIME()
    WHERE source_document_import_id = @source_document_import_id
      AND block_type_candidate IN (
            N'utterance',
            N'action_note',
            N'dice_roll',
            N'dice_result',
            N'narration'
      )
      AND (
            @only_reviewed = 0
            OR review_status IN (N'reviewed', N'verified')
      );

    COMMIT TRANSACTION;

    SELECT
        @source_document_code AS source_document_code,
        @batch_code AS batch_code,
        @import_batch_id AS import_batch_id,
        COUNT(*) AS inserted_row_count
    FROM stg.Utterance_Import
    WHERE import_batch_id = @import_batch_id;
END;
GO
