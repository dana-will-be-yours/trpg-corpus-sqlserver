/*
00_create_database.sql
Create TRPG_Corpus_DB.
Run this script first in SQL Server Management Studio.
*/

IF DB_ID(N'TRPG_Corpus_DB') IS NULL
BEGIN
    CREATE DATABASE TRPG_Corpus_DB;
END
GO

USE TRPG_Corpus_DB;
GO

/*
USE master;
GO

ALTER DATABASE TRPG_Corpus_DB 
SET SINGLE_USER 
WITH ROLLBACK IMMEDIATE;
GO

DROP DATABASE TRPG_Corpus_DB;
GO
*/