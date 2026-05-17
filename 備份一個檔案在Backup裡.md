# 備份一個檔案在 Backup 裡

適用環境：SQL Server Management Studio 22、資料庫 `TRPG_Corpus_DB`、正式表 `dbo`、暫存表 `stg`。本檔只處理 SQL Server 資料庫備份與還原，不處理 Git 分支備份。

目前前端 v1.4 使用瀏覽器 IndexedDB 暫存匯入資料，包含 `dagoCorpusWorkspaceDB_v14` 舊版列式工作區與 `dagoCorpusTurboChunkDB_v3` 大量資料 chunk 工作區。這些資料在瀏覽器本機端，不能由 SQL Server `BACKUP DATABASE` 備份。正式研究資料完成匯入 SQL Server 後，才使用本檔備份。

## 1. 建立備份資料夾

先在 Windows 建立資料夾，並確認 SQL Server 服務帳號有寫入權限。

```powershell
New-Item -ItemType Directory -Force -Path "D:\TRPG_Corpus_SQLServer\Backup"
```

若 SQL Server 無法寫入 D 槽，改用 SQL Server 服務帳號可寫入的路徑，例如：

```text
C:\SQLBackup\TRPG_Corpus_DB
```

## 2. 備份前檢查資料庫狀態

```sql
USE master;
GO

SELECT
    name,
    state_desc,
    recovery_model_desc,
    compatibility_level,
    collation_name
FROM sys.databases
WHERE name = N'TRPG_Corpus_DB';
GO
```

## 3. 建議使用時間戳備份檔名

SSMS 22 可直接執行下列 T-SQL。檔名會包含日期時間，避免覆寫前一版備份。

```sql
USE master;
GO

DECLARE @BackupFolder NVARCHAR(260) = N'D:\TRPG_Corpus_SQLServer\Backup\';
DECLARE @FileName NVARCHAR(4000) =
    @BackupFolder
    + N'TRPG_Corpus_DB_'
    + CONVERT(CHAR(8), GETDATE(), 112)
    + N'_'
    + REPLACE(CONVERT(CHAR(8), GETDATE(), 108), N':', N'')
    + N'.bak';

BACKUP DATABASE TRPG_Corpus_DB
TO DISK = @FileName
WITH
    INIT,
    COMPRESSION,
    CHECKSUM,
    STATS = 10;

SELECT @FileName AS backup_file_path;
GO
```

## 4. 固定檔名備份

只在需要覆寫同一個備份檔時使用。`WITH INIT` 會重寫同名 `.bak`。

```sql
USE master;
GO

BACKUP DATABASE TRPG_Corpus_DB
TO DISK = N'D:\TRPG_Corpus_SQLServer\Backup\TRPG_Corpus_DB_before_revision.bak'
WITH
    INIT,
    COMPRESSION,
    CHECKSUM,
    STATS = 10;
GO
```

## 5. 查詢備份檔資訊

```sql
USE master;
GO

RESTORE HEADERONLY
FROM DISK = N'D:\TRPG_Corpus_SQLServer\Backup\TRPG_Corpus_DB_before_revision.bak';
GO

RESTORE FILELISTONLY
FROM DISK = N'D:\TRPG_Corpus_SQLServer\Backup\TRPG_Corpus_DB_before_revision.bak';
GO
```

## 6. 驗證備份檔

```sql
USE master;
GO

RESTORE VERIFYONLY
FROM DISK = N'D:\TRPG_Corpus_SQLServer\Backup\TRPG_Corpus_DB_before_revision.bak'
WITH CHECKSUM;
GO
```

## 7. 還原到只讀檢查用資料庫

請先用 `RESTORE FILELISTONLY` 確認 logical name。下例假設 logical name 是 `TRPG_Corpus_DB` 與 `TRPG_Corpus_DB_log`。

```sql
USE master;
GO

RESTORE DATABASE TRPG_Corpus_DB_ReadOnly
FROM DISK = N'D:\TRPG_Corpus_SQLServer\Backup\TRPG_Corpus_DB_before_revision.bak'
WITH
    MOVE N'TRPG_Corpus_DB' TO N'C:\SQLData\TRPG_Corpus_DB_ReadOnly.mdf',
    MOVE N'TRPG_Corpus_DB_log' TO N'C:\SQLData\TRPG_Corpus_DB_ReadOnly_log.ldf',
    RECOVERY,
    REPLACE,
    CHECKSUM,
    STATS = 10;
GO

ALTER DATABASE TRPG_Corpus_DB_ReadOnly SET READ_ONLY WITH ROLLBACK IMMEDIATE;
GO
```

## 8. 前端 v1.4 匯入資料的備份原則

前端 v1.4 的大型匯入會先存在瀏覽器 IndexedDB：

```text
dagoCorpusTurboChunkDB_v3
```

此工作區支援 50,000 rows chunk storage、DOCX turbo 匯入、Speaker Mapping 權威套用、row 操作 adapter。這些資料尚未寫入 SQL Server 時，應使用前端下載功能備份：

```text
下載 JSON
下載 XLSX
下載 UTF-16LE TSV
分批 JSON
分批 XLSX
分批 TSV
下載 Mapping JSON
下載 Mapping XLSX
下載 Mapping UTF-16LE TSV
```

建議檔名格式：

```text
<batch_code>_stg_Utterance_Import_<yyyymmdd_hhmmss>.json
<batch_code>_Speaker_Mapping_<yyyymmdd_hhmmss>.xlsx
```

## 9. 修改 schema 前的最低備份流程

```text
1. 在前端下載當前 stg.Utterance_Import JSON / XLSX / TSV。
2. 下載 Speaker Mapping JSON / XLSX / TSV。
3. 確認資料已匯入 SQL Server stg schema。
4. 執行 BACKUP DATABASE TRPG_Corpus_DB。
5. 執行 RESTORE VERIFYONLY WITH CHECKSUM。
6. 再執行 schema 修改或載入正式表。
```

本專案除非明確要求，不使用 `DROP`、`DELETE`、`TRUNCATE` 等破壞性語法。若必須清理資料，先完成本檔的資料庫備份與前端匯出備份。