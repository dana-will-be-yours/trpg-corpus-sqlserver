# trpg-corpus-sqlserver
本專案為「以桌上角色扮演遊戲為基礎之共創機制研究」使用的 SQL Server 語料資料庫骨架。
研究目的：
1. 儲存 TRPG 共創歷程與敘事語料。
2. 支援角色查詢、劇情片段檢索、關聯故事查找、世界觀查詢。
3. 支援事件因果鏈回溯、設定共現查詢、敘事節奏檢視。
4. 對應 SMM 與 TMS 研究變數，保存問卷、標註、查詢紀錄與決策紀錄。

# TRPG Corpus SQL Server Database
本倉庫保存「以桌上角色扮演遊戲為基礎之共創機制研究」使用的 SQL Server 語料資料庫腳本、關聯圖與 SSMS 匯入範本。

## 目前版本
- GitHub `main` HEAD：`e2da4827d970f34ca0a59233d22930bec75f3e42`
- 資料庫名稱：`TRPG_Corpus_DB`
- SQL 腳本位置：`database/00_create_database.sql` 至 `database/26_performance_indexes.sql`
- 正式表：`dbo` schema 共 20 張
- 暫存表：`stg` schema 共 2 張
- 暫存程序：`stg.usp_Validate_Utterance_Import`、`stg.usp_Load_Utterance_Import_To_Dbo`
- 匯入範本：`database/TRPG_SSMS22_staging_import_template_20260505.xlsx`
- 關聯圖：`database/TRPG_Corpus_DB_正式表關聯圖.md`

## 用途
本資料庫用於保存 TRPG 實驗中的研究專案、隊伍、玩家、角色、NPC、規則、世界設定、物件、場次、場景、逐字稿發言、GM 旁白、劇情事件、事件因果鏈、決策、知識查詢、隊伍歷程、延伸創作文本與專家評分。
研究使用情境：
1. 管理匿名化後的 TRPG 活動資料。
2. 對應 SMM 與 TMS 過程註記，例如場景摘要、知識分享、決策追蹤、查詢紀錄。
3. 保存逐字稿與創作文本，供後續 NLP、情感分析、知識圖譜、數據分析與專家評分使用。
4. 透過 staging 匯入流程降低大量逐字稿匯入時的欄位錯誤與代碼對應錯誤。

## 建置順序
在 SSMS 連到 SQL Server 後，依檔名順序執行：
```text
database/00_create_database.sql
database/01_Research_Project.sql
database/02_Team.sql
database/03_Player.sql
database/04_Team_Member.sql
database/05_Player_Character.sql
database/06_NPC.sql
database/07_Game_Rule.sql
database/08_World_Setting.sql
database/09_Item.sql
database/10_TRPG_Session.sql
database/11_Scene.sql
database/12_Utterance.sql
database/13_GM_Narration.sql
database/14_Plot_Event.sql
database/15_Event_Causal_Link.sql
database/16_Decision_Log.sql
database/17_Knowledge_Retrieval_Log.sql
database/18_Team_Play_History.sql
database/19_Extended_Creation_Text.sql
database/20_Expert_Rating.sql
database/21_stg_schema.sql
database/22_stg_Import_Batch.sql
database/23_stg_Utterance_Import.sql
database/24_stg_usp_Validate_Utterance_Import.sql
database/25_stg_usp_Load_Utterance_Import_To_Dbo.sql
database/26_performance_indexes.sql
```

建置後可用下列 SQL 查核物件：
```sql
USE TRPG_Corpus_DB;
GO

SELECT s.name AS schema_name, t.name AS table_name
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
WHERE s.name IN (N'dbo', N'stg')
ORDER BY s.name, t.name;

SELECT s.name AS schema_name, p.name AS procedure_name
FROM sys.procedures AS p
INNER JOIN sys.schemas AS s
    ON s.schema_id = p.schema_id
WHERE s.name = N'stg'
ORDER BY p.name;
```
預期結果：`dbo` 20 張表、`stg` 2 張表、`stg` 2 支程序。

## 資料表分工
主檔與實驗條件：
- `dbo.Research_Project`：研究專案、倫理與匿名化說明。
- `dbo.Team`：隊伍、2x2 條件分組與分派註記。
- `dbo.Player`：匿名參與者、GM、觀察者、研究人員與專家。
- `dbo.Team_Member`：隊伍成員與活動角色。
- `dbo.Player_Character`：玩家角色。
- `dbo.NPC`：非玩家角色。

敘事與語料：
- `dbo.Game_Rule`：規則條目。
- `dbo.World_Setting`：世界設定。
- `dbo.Item`：物件、線索、裝備與任務物。
- `dbo.TRPG_Session`：活動場次、錄音錄影與逐字稿檔案欄位。
- `dbo.Scene`：場景切分、摘要、SMM/TMS 註記。
- `dbo.Utterance`：逐字稿發言。
- `dbo.GM_Narration`：GM 旁白。

分析與評分：
- `dbo.Plot_Event`：劇情事件。
- `dbo.Event_Causal_Link`：事件因果鏈。
- `dbo.Decision_Log`：決策、共識與理由。
- `dbo.Knowledge_Retrieval_Log`：資料庫查詢、規則查詢、世界設定查詢與 TMS 行為。
- `dbo.Team_Play_History`：隊伍歷程摘要。
- `dbo.Extended_Creation_Text`：延伸創作文本。
- `dbo.Expert_Rating`：專家評分。

匯入流程：
- `stg.Import_Batch`：逐字稿匯入批次。
- `stg.Utterance_Import`：Excel 匯入的逐字稿暫存列。

## 逐字稿匯入流程
大量發言資料請先進 `stg`，再載入 `dbo.Utterance`。
1. 使用 `database/TRPG_SSMS22_staging_import_template_20260505.xlsx` 填寫 `stg.Import_Batch` 與 `stg.Utterance_Import`。
2. 先匯入 `stg.Import_Batch`，取得 `import_batch_id`。
3. 將 `import_batch_id` 填到 `stg.Utterance_Import` 每列。
4. 在 SSMS 透過 `Tasks > Import Data` 匯入 Excel 工作表到同名暫存表。
5. 執行驗證程序：
```sql
EXEC stg.usp_Validate_Utterance_Import
    @batch_code = N'TRPG_UTT_20260505_T01_S01_v01';
```

6. 檢查 `validation_error` 與 `validation_warning`。
7. 無 `error` 後載入正式表：
```sql
EXEC stg.usp_Load_Utterance_Import_To_Dbo
    @batch_code = N'TRPG_UTT_20260505_T01_S01_v01';
```

注意：
- `.bak`、逐字稿原檔、受試者個資、錄音檔、影片檔不應直接上傳公開 GitHub。
- 研究資料應去識別化後才可進入版本庫。
- SQL Server 的資料庫內容本身不會自動同步到 GitHub；GitHub 主要保存 schema、查詢腳本、資料字典與匿名化樣本資料。
