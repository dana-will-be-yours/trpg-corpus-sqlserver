USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = N'stg'
)
BEGIN
    EXEC(N'CREATE SCHEMA stg AUTHORIZATION dbo;');
END;
GO

/*
查核 stg schema 是否建立完成：
SELECT
    s.name AS schema_name,
    dp.name AS owner_name,
    s.schema_id
FROM sys.schemas AS s
INNER JOIN sys.database_principals AS dp
    ON s.principal_id = dp.principal_id
WHERE s.name = N'stg';
GO
*/