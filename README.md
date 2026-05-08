# trpg-corpus-sqlserver

本倉庫保存「以桌上角色扮演遊戲為基礎之共創機制研究」使用的 SQL Server 語料資料庫腳本、關聯圖、匯入工具與網頁輸入頁。

## 目前版本

- GitHub `main` HEAD：`3585009b998a169b4fc97a5027426f70c6f3d4b2`
- 資料庫名稱：`TRPG_Corpus_DB`
- SQL 腳本位置：`database/00_create_database.sql` 至 `database/37_stg_usp_Load_Extended_Creation_Text_Import_To_Dbo.sql`
- 本機檢查環境：SQL Server 2025 Express、SQLCMD ODBC Driver 18、SSMS 22 可連線到同一執行個體
- 已建立物件：`dbo` 22 張表、`stg` 6 張表、`dbo` 7 支程序、`stg` 7 支程序、`dbo` 5 個檢視

## 用途

本資料庫用於保存 TRPG 實驗中的研究專案、隊伍、玩家、角色、NPC、規則、世界設定、物件、場次、場景、逐字稿發言、GM 旁白、劇情事件、事件因果鏈、決策、知識查詢、隊伍歷程、延伸創作文本與專家評分。

研究使用情境：

1. 管理匿名化後的 TRPG 活動資料。
2. 對應 SMM 與 TMS 過程註記，例如場景摘要、知識分享、決策追蹤、查詢紀錄。
3. 保存逐字稿與創作文本，供後續 NLP、情感分析、知識圖譜、數據分析與專家評分使用。
4. 透過 staging 匯入流程降低大量逐字稿匯入時的欄位錯誤與代碼對應錯誤。
5. 提供 `da_go` 可讀取的世界資料匯出，並接收 `da_go` 單人遊戲紀錄回寫。

資料不足，需要新資料提供：目前 SQL 尚未包含正式問卷題項、問卷填答、訪談逐字稿、安全事件、隨機分派紀錄、同意書版本、IRB 文件與概念圖資料表。若論文要執行前後測、中介模型、心理安全調節、訪談編碼或概念圖分析，需另行新增資料表或提供資料設計。

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
database/27_character_profile_export.sql
database/28_dago_world_manifest_export.sql
database/29_stg_DaGo_PlayLog_Import.sql
database/30_stg_usp_Validate_DaGo_PlayLog_Import.sql
database/31_stg_usp_Load_DaGo_PlayLog_To_Utterance_Import.sql
database/32_stg_Source_Document_Import.sql
database/33_stg_Source_Text_Block_Import.sql
database/34_stg_Extended_Creation_Text_Import.sql
database/35_stg_usp_Load_Source_Document_Json.sql
database/36_stg_usp_Build_Utterance_Import_From_Source_Text_Block.sql
database/37_stg_usp_Load_Extended_Creation_Text_Import_To_Dbo.sql
```

含中文字串的 SQL 檔以 UTF-8 讀取。若用 `sqlcmd` 檢查或批次執行，需加 `-f 65001`：

```powershell
$files = Get-ChildItem -Path database -Filter *.sql | Sort-Object Name
foreach ($file in $files) {
    sqlcmd -S .\SQLEXPRESS -E -C -f 65001 -b -i $file.FullName
}
```

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

擴充匯出與輸入：

- `dbo.Character_Profile_Image`、`dbo.Character_Freeform_Field`：角色頁圖片與自由欄位。
- `stg.Import_Batch`、`stg.Utterance_Import`：逐字稿匯入批次與暫存列。
- `stg.DaGo_PlayLog_Import`：`da_go` 遊戲紀錄回寫。
- `stg.Source_Document_Import`、`stg.Source_Text_Block_Import`、`stg.Extended_Creation_Text_Import`：團錄與二創文本匯入。

## 主要流程

逐字稿匯入：

1. 使用 `database/TRPG_SSMS22_staging_import_template_20260505.xlsx` 填寫 `stg.Import_Batch` 與 `stg.Utterance_Import`。
2. 在 SSMS 透過 `Tasks > Import Data` 匯入 Excel 工作表到同名暫存表。
3. 執行 `stg.usp_Validate_Utterance_Import` 檢查欄位與代碼。
4. 無 `error` 後執行 `stg.usp_Load_Utterance_Import_To_Dbo` 載入正式表。

團錄與二創文本匯入：

1. 使用 `tools/extract_source_document.py` 將 `.docx`、`.html`、`.txt` 或 `.json` 轉為 JSON。
2. 以 `tools/dago_corpus_api.ps1` 或 `web/dago-corpus-input.html` 建立 `stg.Source_Document_Import` 與文字區塊。
3. 依文本種類執行 `stg.usp_Build_Utterance_Import_From_Source_Text_Block` 或 `stg.usp_Load_Extended_Creation_Text_Import_To_Dbo`。

`da_go` 往返：

1. `dbo.usp_Export_DaGo_World_Manifest` 匯出單人遊戲世界資料。
2. `da_go` 讀取 JSON 後進行單人遊戲。
3. `stg.DaGo_PlayLog_Import` 接收遊戲紀錄。
4. `stg.usp_Load_DaGo_PlayLog_To_Utterance_Import` 轉為 `stg.Utterance_Import` 可處理格式。

## 常用文件

- `快捷使用.md`：可直接貼到 SSMS 的常用查詢。
- `docs/dago_roundtrip.md`：`da_go` 與本資料庫的資料往返流程。
- `docs/source_document_ingest.md`：團錄與二創文本匯入流程。
- `docs/角色背景彙整與HTML圖表匯出.md`：角色資料頁與 HTML 圖表匯出流程。
- `database/TRPG_Corpus_DB_正式表關聯圖.md`：正式表關聯摘要。
- `database/TRPG_SSMS22_staging_import_template_20260505.xlsx`：SSMS 22 匯入範本。

## GitHub 與研究資料注意事項

- 不要上傳 `.bak`、逐字稿原檔、受試者個資、錄音檔、影片檔與未去識別化資料。
- GitHub 保存 SQL、資料字典、查詢腳本、匿名化範例與文件。
- SQL Server 的資料庫內容需另行匯出與備份，GitHub 僅保存文件與腳本。
- 若要發布真實資料，需先完成匿名化、授權範圍確認與倫理審查要求。

## 自我檢查

- 已快轉本機 `main` 至 GitHub `origin/main`。
- 已用 SQL Server 2025 Express 與 `sqlcmd -f 65001` 依序執行 `database/00_create_database.sql` 至 `database/37_stg_usp_Load_Extended_Creation_Text_Import_To_Dbo.sql`。
- 已核對建立後物件數量：`dbo` 22 張表、`stg` 6 張表、`dbo` 7 支程序、`stg` 7 支程序、`dbo` 5 個檢視。
- 已查核 Microsoft Learn 關於 SSMS 22 與 `sqlcmd` UTF-8/憑證參數的官方文件。
- 已保留 SMM 與 TMS 文獻來源。

## 參考文獻

DeChurch, L. A., & Mesmer-Magnus, J. R. (2010). The cognitive underpinnings of effective teamwork: A meta-analysis. *Journal of Applied Psychology, 95*(1), 32-53. https://doi.org/10.1037/a0017328

Lewis, K. (2003). Measuring transactive memory systems in the field: Scale development and validation. *Journal of Applied Psychology, 88*(4), 587-604. https://doi.org/10.1037/0021-9010.88.4.587

Mathieu, J. E., Heffner, T. S., Goodwin, G. F., Salas, E., & Cannon-Bowers, J. A. (2000). The influence of shared mental models on team process and performance. *Journal of Applied Psychology, 85*(2), 273-283. https://doi.org/10.1037/0021-9010.85.2.273

Microsoft. (2026, April 28). *Release notes for SQL Server Management Studio (SSMS)*. Microsoft Learn. https://learn.microsoft.com/en-us/ssms/release-notes-22

Microsoft. (2025, July 15). *Run Transact-SQL commands with the sqlcmd utility*. Microsoft Learn. https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-utility
