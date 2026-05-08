USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE stg.usp_Load_Extended_Creation_Text_Import_To_Dbo
    @source_document_code NVARCHAR(100),
    @allow_unreviewed BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @source_document_import_id BIGINT;

    SELECT @source_document_import_id = source_document_import_id
    FROM stg.Source_Document_Import
    WHERE source_document_code = @source_document_code;

    IF @source_document_import_id IS NULL
    BEGIN
        THROW 51500, 'source_document_code not found.', 1;
    END;

    ;WITH Mapped AS
    (
        SELECT
            eci.extended_creation_text_import_id,
            t.team_id,
            s.session_id,
            sc.scene_id,
            tm.team_member_id AS author_member_id,
            TRY_CONVERT(INT, eci.creation_no_text) AS creation_no_value,
            TRY_CONVERT(INT, COALESCE(NULLIF(eci.version_no_text, N''), N'1')) AS version_no_value,
            TRY_CONVERT(INT, NULLIF(eci.word_count_text, N'')) AS word_count_value,
            CASE
                WHEN UPPER(LTRIM(RTRIM(COALESCE(eci.is_final_version_text, N'0')))) IN (N'1', N'TRUE', N'Y', N'YES', N'是') THEN CONVERT(BIT, 1)
                ELSE CONVERT(BIT, 0)
            END AS is_final_version_value,
            ect.creation_text_id AS existing_creation_text_id,
            eci.review_status
        FROM stg.Extended_Creation_Text_Import AS eci
        INNER JOIN dbo.Research_Project AS rp
            ON rp.project_code = eci.project_code
        INNER JOIN dbo.Team AS t
            ON t.project_id = rp.project_id
           AND t.team_code = eci.team_code
        LEFT JOIN dbo.TRPG_Session AS s
            ON s.team_id = t.team_id
           AND s.session_code = eci.session_code
        LEFT JOIN dbo.Scene AS sc
            ON sc.session_id = s.session_id
           AND sc.scene_code = eci.scene_code
        LEFT JOIN dbo.Team_Member AS tm
            ON tm.team_id = t.team_id
           AND tm.member_code = eci.author_member_code
        LEFT JOIN dbo.Extended_Creation_Text AS ect
            ON ect.team_id = t.team_id
           AND ect.creation_code = eci.creation_code
        WHERE eci.source_document_import_id = @source_document_import_id
    )
    UPDATE eci
    SET
        import_status =
            CASE
                WHEN m.team_id IS NULL THEN N'error'
                WHEN m.creation_no_value IS NULL OR m.creation_no_value < 1 THEN N'error'
                WHEN m.version_no_value IS NULL OR m.version_no_value < 1 THEN N'error'
                WHEN m.existing_creation_text_id IS NOT NULL THEN N'error'
                WHEN @allow_unreviewed = 0 AND m.review_status NOT IN (N'reviewed', N'verified') THEN N'warning'
                ELSE N'valid'
            END,
        validation_error =
            CASE
                WHEN m.team_id IS NULL THEN N'project_code or team_code could not be mapped.'
                WHEN m.creation_no_value IS NULL OR m.creation_no_value < 1 THEN N'creation_no_text is invalid.'
                WHEN m.version_no_value IS NULL OR m.version_no_value < 1 THEN N'version_no_text is invalid.'
                WHEN m.existing_creation_text_id IS NOT NULL THEN N'creation_code already exists for this team.'
                ELSE NULL
            END,
        validation_warning =
            CASE
                WHEN @allow_unreviewed = 0 AND m.review_status NOT IN (N'reviewed', N'verified') THEN N'review_status should be reviewed or verified before loading.'
                ELSE NULL
            END,
        updated_at = SYSDATETIME()
    FROM stg.Extended_Creation_Text_Import AS eci
    INNER JOIN Mapped AS m
        ON m.extended_creation_text_import_id = eci.extended_creation_text_import_id;

    IF EXISTS (
        SELECT 1
        FROM stg.Extended_Creation_Text_Import
        WHERE source_document_import_id = @source_document_import_id
          AND import_status = N'error'
    )
    BEGIN
        THROW 51501, 'Extended creation import has error rows.', 1;
    END;

    IF @allow_unreviewed = 0
       AND EXISTS (
            SELECT 1
            FROM stg.Extended_Creation_Text_Import
            WHERE source_document_import_id = @source_document_import_id
              AND import_status = N'warning'
       )
    BEGIN
        THROW 51502, 'Extended creation import has unreviewed rows.', 1;
    END;

    BEGIN TRANSACTION;

    ;WITH SourceRows AS
    (
        SELECT
            eci.*,
            t.team_id,
            s.session_id,
            sc.scene_id,
            tm.team_member_id AS author_member_id,
            TRY_CONVERT(INT, eci.creation_no_text) AS creation_no_value,
            TRY_CONVERT(INT, COALESCE(NULLIF(eci.version_no_text, N''), N'1')) AS version_no_value,
            TRY_CONVERT(INT, NULLIF(eci.word_count_text, N'')) AS word_count_value,
            CASE
                WHEN UPPER(LTRIM(RTRIM(COALESCE(eci.is_final_version_text, N'0')))) IN (N'1', N'TRUE', N'Y', N'YES', N'是') THEN CONVERT(BIT, 1)
                ELSE CONVERT(BIT, 0)
            END AS is_final_version_value,
            CASE
                WHEN UPPER(LTRIM(RTRIM(COALESCE(eci.include_in_analysis_text, N'1')))) IN (N'1', N'TRUE', N'Y', N'YES', N'是') THEN CONVERT(BIT, 1)
                ELSE CONVERT(BIT, 0)
            END AS include_in_analysis_value
        FROM stg.Extended_Creation_Text_Import AS eci
        INNER JOIN dbo.Research_Project AS rp
            ON rp.project_code = eci.project_code
        INNER JOIN dbo.Team AS t
            ON t.project_id = rp.project_id
           AND t.team_code = eci.team_code
        LEFT JOIN dbo.TRPG_Session AS s
            ON s.team_id = t.team_id
           AND s.session_code = eci.session_code
        LEFT JOIN dbo.Scene AS sc
            ON sc.session_id = s.session_id
           AND sc.scene_code = eci.scene_code
        LEFT JOIN dbo.Team_Member AS tm
            ON tm.team_id = t.team_id
           AND tm.member_code = eci.author_member_code
        WHERE eci.source_document_import_id = @source_document_import_id
          AND eci.import_status IN (N'valid', N'warning')
    )
    INSERT INTO dbo.Extended_Creation_Text
    (
        team_id,
        session_id,
        scene_id,
        creation_code,
        creation_no,
        creation_title,
        creation_type,
        creation_stage,
        authoring_mode,
        author_member_id,
        source_material_note,
        creation_text_raw,
        creation_text_clean,
        creation_text_verified,
        creation_summary,
        theme_summary,
        plot_summary,
        character_summary,
        worldbuilding_summary,
        conflict_summary,
        decision_trace_summary,
        knowledge_trace_summary,
        trpg_source_trace_summary,
        narrative_coherence_note,
        originality_note,
        completeness_note,
        smm_relevance_note,
        tms_relevance_note,
        evaluation_note,
        word_count,
        version_no,
        is_final_version,
        source_type,
        extraction_method,
        review_status,
        include_in_analysis,
        exclusion_reason
    )
    SELECT
        team_id,
        session_id,
        scene_id,
        creation_code,
        creation_no_value,
        creation_title,
        creation_type,
        creation_stage,
        authoring_mode,
        author_member_id,
        source_material_note,
        creation_text_raw,
        creation_text_clean,
        creation_text_verified,
        creation_summary,
        theme_summary,
        plot_summary,
        character_summary,
        worldbuilding_summary,
        conflict_summary,
        decision_trace_summary,
        knowledge_trace_summary,
        trpg_source_trace_summary,
        narrative_coherence_note,
        originality_note,
        completeness_note,
        smm_relevance_note,
        tms_relevance_note,
        evaluation_note,
        word_count_value,
        version_no_value,
        is_final_version_value,
        source_type,
        extraction_method,
        review_status,
        include_in_analysis_value,
        exclusion_reason
    FROM SourceRows;

    UPDATE stg.Extended_Creation_Text_Import
    SET
        import_status = N'loaded_to_dbo',
        updated_at = SYSDATETIME()
    WHERE source_document_import_id = @source_document_import_id
      AND import_status IN (N'valid', N'warning');

    UPDATE stg.Source_Document_Import
    SET
        import_status = N'loaded',
        updated_at = SYSDATETIME()
    WHERE source_document_import_id = @source_document_import_id;

    COMMIT TRANSACTION;

    SELECT
        @source_document_code AS source_document_code,
        COUNT(*) AS loaded_row_count
    FROM stg.Extended_Creation_Text_Import
    WHERE source_document_import_id = @source_document_import_id
      AND import_status = N'loaded_to_dbo';
END;
GO
