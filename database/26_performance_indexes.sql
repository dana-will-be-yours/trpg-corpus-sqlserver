USE TRPG_Corpus_DB;
GO

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'dbo.Player_Character', N'U') IS NOT NULL
   AND NOT EXISTS
   (
       SELECT 1
       FROM sys.indexes
       WHERE object_id = OBJECT_ID(N'dbo.Player_Character')
         AND name = N'IX_Player_Character_CharacterCode_TeamMember'
   )
BEGIN
    CREATE NONCLUSTERED INDEX IX_Player_Character_CharacterCode_TeamMember
    ON dbo.Player_Character (character_code, team_member_id)
    INCLUDE (character_id);
END;
GO

IF OBJECT_ID(N'dbo.World_Setting', N'U') IS NOT NULL
   AND NOT EXISTS
   (
       SELECT 1
       FROM sys.indexes
       WHERE object_id = OBJECT_ID(N'dbo.World_Setting')
         AND name = N'IX_World_Setting_Project_Setting_Team'
   )
BEGIN
    CREATE NONCLUSTERED INDEX IX_World_Setting_Project_Setting_Team
    ON dbo.World_Setting (project_id, setting_code, team_id)
    INCLUDE (world_setting_id);
END;
GO

IF OBJECT_ID(N'stg.Utterance_Import', N'U') IS NOT NULL
   AND NOT EXISTS
   (
       SELECT 1
       FROM sys.indexes
       WHERE object_id = OBJECT_ID(N'stg.Utterance_Import')
         AND name = N'IX_stg_Utterance_Import_Batch_Status'
   )
BEGIN
    CREATE NONCLUSTERED INDEX IX_stg_Utterance_Import_Batch_Status
    ON stg.Utterance_Import (import_batch_id, import_status)
    INCLUDE (utterance_import_id, source_row_no);
END;
GO
