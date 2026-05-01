## 備份
BACKUP DATABASE TRPG_Corpus_DB
TO DISK = 'D:\TRPG_Corpus_SQLServer\Backup\TRPG_Corpus_DB_before_revision.bak'
WITH INIT;
GO

## 查詢
RESTORE HEADERONLY
FROM DISK = 'D:\TRPG_Corpus_SQLServer\Backup\TRPG_Corpus_DB_before_revision.bak';
GO

RESTORE FILELISTONLY
FROM DISK = 'D:\TRPG_Corpus_SQLServer\Backup\TRPG_Corpus_DB_before_revision.bak';
GO

## 檢查備份檔是否正常
RESTORE VERIFYONLY
FROM DISK = 'D:\TRPG_Corpus_SQLServer\Backup\TRPG_Corpus_DB_before_revision.bak';
GO

## 還原
RESTORE DATABASE TRPG_Corpus_DB_ReadOnly
FROM DISK = 'D:\TRPG_Corpus_SQLServer\Backup\TRPG_Corpus_DB_before_revision.bak'
WITH 
    MOVE 'TRPG_Corpus_DB' TO 'C:\SQLData\TRPG_Corpus_DB_ReadOnly.mdf',
    MOVE 'TRPG_Corpus_DB_log' TO 'C:\SQLData\TRPG_Corpus_DB_ReadOnly_log.ldf',
    RECOVERY,
    REPLACE;
GO
