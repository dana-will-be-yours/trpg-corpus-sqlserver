USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE stg.usp_Load_Source_Document_Json
    @source_document_json NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF ISJSON(@source_document_json) <> 1
    BEGIN
        THROW 51300, 'source_document_json is not valid JSON.', 1;
    END;

    DECLARE @source_document_code NVARCHAR(100) = JSON_VALUE(@source_document_json, '$.source_document.source_document_code');
    DECLARE @source_document_import_id BIGINT;

    IF NULLIF(LTRIM(RTRIM(@source_document_code)), N'') IS NULL
    BEGIN
        THROW 51301, 'source_document_code is required.', 1;
    END;

    IF EXISTS (
        SELECT 1
        FROM stg.Source_Document_Import
        WHERE source_document_code = @source_document_code
    )
    BEGIN
        THROW 51302, 'source_document_code already exists.', 1;
    END;

    BEGIN TRANSACTION;

    INSERT INTO stg.Source_Document_Import
    (
        source_document_code,
        project_code,
        team_code,
        session_code,
        source_document_type,
        source_title,
        source_author_label,
        source_url,
        source_folder_label,
        file_name,
        file_extension,
        mime_type,
        file_size_bytes,
        file_sha256,
        storage_mode,
        storage_uri,
        extracted_text_raw,
        parser_name,
        parser_version,
        docx_core_title,
        docx_core_creator,
        docx_core_created_at,
        docx_core_modified_at,
        paragraph_count,
        text_unit_count,
        speaker_line_count,
        dice_line_count,
        table_count,
        import_status
    )
    SELECT
        source_document_code,
        project_code,
        team_code,
        session_code,
        source_document_type,
        source_title,
        source_author_label,
        source_url,
        source_folder_label,
        file_name,
        file_extension,
        mime_type,
        TRY_CONVERT(BIGINT, file_size_bytes),
        file_sha256,
        COALESCE(storage_mode, N'text_only'),
        storage_uri,
        extracted_text_raw,
        parser_name,
        parser_version,
        docx_core_title,
        docx_core_creator,
        TRY_CONVERT(DATETIME2(0), docx_core_created_at),
        TRY_CONVERT(DATETIME2(0), docx_core_modified_at),
        TRY_CONVERT(INT, paragraph_count),
        TRY_CONVERT(INT, text_unit_count),
        TRY_CONVERT(INT, speaker_line_count),
        TRY_CONVERT(INT, dice_line_count),
        TRY_CONVERT(INT, table_count),
        N'parsed'
    FROM OPENJSON(@source_document_json, '$.source_document')
    WITH
    (
        source_document_code NVARCHAR(100) '$.source_document_code',
        project_code NVARCHAR(50) '$.project_code',
        team_code NVARCHAR(50) '$.team_code',
        session_code NVARCHAR(50) '$.session_code',
        source_document_type NVARCHAR(50) '$.source_document_type',
        source_title NVARCHAR(250) '$.source_title',
        source_author_label NVARCHAR(100) '$.source_author_label',
        source_url NVARCHAR(500) '$.source_url',
        source_folder_label NVARCHAR(200) '$.source_folder_label',
        file_name NVARCHAR(260) '$.file_name',
        file_extension NVARCHAR(20) '$.file_extension',
        mime_type NVARCHAR(100) '$.mime_type',
        file_size_bytes NVARCHAR(50) '$.file_size_bytes',
        file_sha256 CHAR(64) '$.file_sha256',
        storage_mode NVARCHAR(50) '$.storage_mode',
        storage_uri NVARCHAR(500) '$.storage_uri',
        extracted_text_raw NVARCHAR(MAX) '$.extracted_text_raw',
        parser_name NVARCHAR(100) '$.parser_name',
        parser_version NVARCHAR(50) '$.parser_version',
        docx_core_title NVARCHAR(250) '$.docx_core_title',
        docx_core_creator NVARCHAR(100) '$.docx_core_creator',
        docx_core_created_at NVARCHAR(50) '$.docx_core_created_at',
        docx_core_modified_at NVARCHAR(50) '$.docx_core_modified_at',
        paragraph_count NVARCHAR(50) '$.paragraph_count',
        text_unit_count NVARCHAR(50) '$.text_unit_count',
        speaker_line_count NVARCHAR(50) '$.speaker_line_count',
        dice_line_count NVARCHAR(50) '$.dice_line_count',
        table_count NVARCHAR(50) '$.table_count'
    ) AS doc;

    SET @source_document_import_id = SCOPE_IDENTITY();

    INSERT INTO stg.Source_Text_Block_Import
    (
        source_document_import_id,
        source_block_no,
        paragraph_no,
        line_no,
        style_name,
        block_type_candidate,
        scene_code_candidate,
        turn_no_text,
        speaker_type_candidate,
        speaker_code_candidate,
        speaker_label_candidate,
        utterance_function_candidate,
        is_in_character_text,
        text_raw,
        text_clean,
        extraction_note,
        ai_annotation_json,
        review_status,
        include_in_analysis_text,
        import_status
    )
    SELECT
        @source_document_import_id,
        source_block_no,
        paragraph_no,
        line_no,
        style_name,
        block_type_candidate,
        scene_code_candidate,
        turn_no_text,
        speaker_type_candidate,
        speaker_code_candidate,
        speaker_label_candidate,
        utterance_function_candidate,
        is_in_character_text,
        text_raw,
        text_clean,
        extraction_note,
        ai_annotation_json,
        COALESCE(review_status, N'needs_review'),
        include_in_analysis_text,
        N'parsed'
    FROM OPENJSON(@source_document_json, '$.source_text_blocks')
    WITH
    (
        source_block_no INT '$.source_block_no',
        paragraph_no INT '$.paragraph_no',
        line_no INT '$.line_no',
        style_name NVARCHAR(100) '$.style_name',
        block_type_candidate NVARCHAR(50) '$.block_type_candidate',
        scene_code_candidate NVARCHAR(50) '$.scene_code_candidate',
        turn_no_text NVARCHAR(50) '$.turn_no_text',
        speaker_type_candidate NVARCHAR(50) '$.speaker_type_candidate',
        speaker_code_candidate NVARCHAR(80) '$.speaker_code_candidate',
        speaker_label_candidate NVARCHAR(100) '$.speaker_label_candidate',
        utterance_function_candidate NVARCHAR(50) '$.utterance_function_candidate',
        is_in_character_text NVARCHAR(20) '$.is_in_character_text',
        text_raw NVARCHAR(MAX) '$.text_raw',
        text_clean NVARCHAR(MAX) '$.text_clean',
        extraction_note NVARCHAR(MAX) '$.extraction_note',
        ai_annotation_json NVARCHAR(MAX) '$.ai_annotation_json',
        review_status NVARCHAR(50) '$.review_status',
        include_in_analysis_text NVARCHAR(20) '$.include_in_analysis_text'
    ) AS blocks;

    IF JSON_QUERY(@source_document_json, '$.extended_creation_import') IS NOT NULL
    BEGIN
        INSERT INTO stg.Extended_Creation_Text_Import
        (
            source_document_import_id,
            source_row_no,
            project_code,
            team_code,
            session_code,
            scene_code,
            creation_code,
            creation_no_text,
            creation_title,
            creation_type,
            creation_stage,
            authoring_mode,
            author_member_code,
            source_material_note,
            creation_text_raw,
            creation_text_clean,
            creation_summary,
            word_count_text,
            version_no_text,
            is_final_version_text,
            source_type,
            extraction_method,
            review_status,
            include_in_analysis_text,
            import_status
        )
        SELECT
            @source_document_import_id,
            1,
            project_code,
            team_code,
            session_code,
            scene_code,
            creation_code,
            creation_no_text,
            creation_title,
            creation_type,
            creation_stage,
            authoring_mode,
            author_member_code,
            source_material_note,
            creation_text_raw,
            creation_text_clean,
            creation_summary,
            word_count_text,
            version_no_text,
            is_final_version_text,
            source_type,
            extraction_method,
            review_status,
            include_in_analysis_text,
            N'raw'
        FROM OPENJSON(@source_document_json, '$.extended_creation_import')
        WITH
        (
            project_code NVARCHAR(50) '$.project_code',
            team_code NVARCHAR(50) '$.team_code',
            session_code NVARCHAR(50) '$.session_code',
            scene_code NVARCHAR(50) '$.scene_code',
            creation_code NVARCHAR(80) '$.creation_code',
            creation_no_text NVARCHAR(50) '$.creation_no_text',
            creation_title NVARCHAR(250) '$.creation_title',
            creation_type NVARCHAR(50) '$.creation_type',
            creation_stage NVARCHAR(50) '$.creation_stage',
            authoring_mode NVARCHAR(50) '$.authoring_mode',
            author_member_code NVARCHAR(50) '$.author_member_code',
            source_material_note NVARCHAR(MAX) '$.source_material_note',
            creation_text_raw NVARCHAR(MAX) '$.creation_text_raw',
            creation_text_clean NVARCHAR(MAX) '$.creation_text_clean',
            creation_summary NVARCHAR(MAX) '$.creation_summary',
            word_count_text NVARCHAR(50) '$.word_count_text',
            version_no_text NVARCHAR(50) '$.version_no_text',
            is_final_version_text NVARCHAR(20) '$.is_final_version_text',
            source_type NVARCHAR(50) '$.source_type',
            extraction_method NVARCHAR(50) '$.extraction_method',
            review_status NVARCHAR(50) '$.review_status',
            include_in_analysis_text NVARCHAR(20) '$.include_in_analysis_text'
        ) AS creation_rows;
    END;

    COMMIT TRANSACTION;

    SELECT
        @source_document_import_id AS source_document_import_id,
        @source_document_code AS source_document_code,
        (SELECT COUNT(*) FROM stg.Source_Text_Block_Import WHERE source_document_import_id = @source_document_import_id) AS text_block_count,
        (SELECT COUNT(*) FROM stg.Extended_Creation_Text_Import WHERE source_document_import_id = @source_document_import_id) AS extended_creation_count;
END;
GO
