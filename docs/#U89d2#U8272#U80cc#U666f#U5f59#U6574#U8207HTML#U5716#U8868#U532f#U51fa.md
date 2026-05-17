# 角色背景彙整與 HTML 圖表匯出

本文件配合 `database/27_character_profile_export.sql`、`web/character-profile-report.html` 與 `tools/character_profile_api.ps1` 使用。第一頁讀取既有 `dbo` 表；第二頁圖片、第三頁玩家自填欄位、第四頁團務劇情與第五頁角色建立會透過本機 API 連到 SQL Server。

## 1. 新增資料庫物件

`database/27_character_profile_export.sql` 會建立下列物件：

| 物件 | 用途 |
|---|---|
| `dbo.vw_Character_Profile` | 單一角色一列，合併角色基本資料、玩家匿名代碼、隊伍代碼與統計數 |
| `dbo.vw_Character_Profile_Section` | 將背景、個性、動機、關係、物品、事件、決策、知識查詢整理成可顯示區塊 |
| `dbo.vw_Character_Timeline` | 將發言、劇情事件、決策、知識查詢整理成時間序列 |
| `dbo.vw_Character_Chart_Data` | 將圖表需要的標籤與數值整理成列資料 |
| `dbo.usp_Get_Character_Profile_Export` | 將單一角色輸出成 HTML 可讀取的 JSON |
| `dbo.Character_Profile_Image` | 儲存大頭照與全身立繪的圖片資料 |
| `dbo.Character_Freeform_Field` | 儲存玩家在第三頁新增的自填欄位 |
| `dbo.usp_Save_Character_Profile_Image` | 儲存單一圖片欄位 |
| `dbo.usp_Clear_Character_Profile_Image` | 清除單一圖片欄位 |
| `dbo.usp_Save_Character_Freeform_Fields` | 儲存第三頁的自填欄位清單 |
| `dbo.vw_Team_Story_Record` | 整理單一團隊的場次、場景、團務紀錄、劇情事件、決策、知識查詢與延伸創作 |
| `dbo.usp_Get_Team_Story_Export` | 匯出單一團隊團務劇情 JSON |
| `dbo.usp_Create_Player_Character_From_Web` | 由第五頁建立玩家角色並寫入 `dbo.Player_Character` |

## 2. 資料來源對照

| 資料內容 | 來源表與欄位 |
|---|---|
| 角色名稱、代碼、類型、原型、種族、職業、陣營 | `dbo.Player_Character` |
| 角色背景 | `background_story_verified`、`background_story_clean`、`background_story_raw`，以前者優先 |
| 角色個性、動機、關係、能力、物品備註 | `dbo.Player_Character` |
| 隊伍、成員、匿名玩家資料 | `dbo.Team_Member`、`dbo.Team`、`dbo.Player` |
| 角色發言與情緒標籤 | `dbo.Utterance` |
| 角色經歷 | `dbo.Plot_Event` 的 `actor_character_id`、`target_character_id` |
| 角色決策 | `dbo.Decision_Log` 的 `proposer_character_id`、`final_actor_character_id` |
| 角色查詢行為 | `dbo.Knowledge_Retrieval_Log` 的 `query_initiator_character_id` |
| 角色持有物 | `dbo.Item` 的 `owner_character_id` |
| 角色大頭照、全身立繪 | `dbo.Character_Profile_Image` |
| 玩家自填資料 | `dbo.Character_Freeform_Field` |
| 團務劇情捲軸紀錄 | `dbo.TRPG_Session`、`dbo.Scene`、`dbo.Team_Play_History`、`dbo.Plot_Event`、`dbo.Decision_Log`、`dbo.Knowledge_Retrieval_Log`、`dbo.Extended_Creation_Text` |
| 第五頁角色建立 | 寫入 `dbo.Player_Character`，需連到既有 `dbo.Team_Member` |

## 3. 安裝 SQL 腳本

先執行原本 `00` 到 `26` 號腳本，再執行第 `27` 號腳本：

```powershell
sqlcmd -S <server> -E -C -b -f 65001 -i "C:\Users\sun\Documents\New project\trpg-corpus-sqlserver\database\27_character_profile_export.sql"
```

把 `<server>` 換成 SSMS 連線視窗中的伺服器名稱，例如 `localhost`、`.` 或 `.\SQLEXPRESS`。本機已確認 `.\SQLEXPRESS` 有 `TRPG_Corpus_DB`。

## 4. 查詢角色 ID

```sql
SELECT
    character_id,
    team_code,
    member_code,
    character_code,
    character_name
FROM dbo.vw_Character_Profile
ORDER BY team_code, member_code, character_code;
```

## 5. 匯出 JSON

用 `character_id` 匯出：

```powershell
sqlcmd -S <server> -d TRPG_Corpus_DB -E -C -f 65001 -h -1 -W -w 65535 -y 0 -Q "SET NOCOUNT ON; EXEC dbo.usp_Get_Character_Profile_Export @character_id = 1;" -o "C:\Users\sun\Documents\New project\trpg-corpus-sqlserver\exports\character_1.json"
```

用隊伍代碼、成員代碼、角色代碼匯出：

```powershell
sqlcmd -S <server> -d TRPG_Corpus_DB -E -C -f 65001 -h -1 -W -w 65535 -y 0 -Q "SET NOCOUNT ON; EXEC dbo.usp_Get_Character_Profile_Export @team_code=N'T01', @member_code=N'P01', @character_code=N'PC01';" -o "C:\Users\sun\Documents\New project\trpg-corpus-sqlserver\exports\character_T01_P01_PC01.json"
```

若在 SSMS 執行，可用下列 SQL，將結果格中的 JSON 貼到 HTML 的文字欄位：

```sql
EXEC dbo.usp_Get_Character_Profile_Export
    @character_id = 1;
```

匯出的 JSON 會包含 `profile`、`sections`、`timeline`、`charts`、`images`、`freeform_fields`。

## 6. 啟動本機 API

若要讓第二頁與第三頁讀寫 SQL Server，先開啟 PowerShell，執行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\sun\Documents\New project\trpg-corpus-sqlserver\tools\character_profile_api.ps1" -Prefix "http://localhost:8787/" -Server ".\SQLEXPRESS" -Database "TRPG_Corpus_DB"
```

健康檢查網址：

```text
http://localhost:8787/api/health
```

HTML 內「本機 API」預設為 `http://localhost:8787`。若改用其他連接埠，需同步修改頁面欄位。第四頁與第五頁也使用同一個本機 API。

## 7. 開啟 HTML 圖表頁

開啟下列檔案：

```text
C:\Users\sun\Documents\New project\trpg-corpus-sqlserver\web\character-profile-report.html
```

在頁面選擇第 5 步輸出的 JSON 檔，或貼上 SSMS 輸出的 JSON 後按「載入文字」。頁面會顯示：

| 區塊 | 內容 |
|---|---|
| 第一頁：角色資料 | 角色概覽、指標、圖表、角色資料、時間序列 |
| 第二頁：角色圖片 | 大頭照、全身立繪，可由本機 API 讀取與儲存 |
| 第三頁：自填欄位 | 玩家可新增欄位與內容，可由本機 API 讀取與儲存 |
| 第四頁：團務劇情 | 以捲軸呈現單一團隊的場次、場景、團務紀錄、劇情事件、決策、知識查詢與延伸創作 |
| 第五頁：角色建立 | 玩家填寫角色資訊後，建立角色並寫入 `dbo.Player_Character` |

使用資料庫連動：

1. 啟動第 6 步的本機 API。
2. 在 HTML 第二頁或第三頁填入 `角色 ID`。
3. 按「讀取資料庫」載入該角色的資料。
4. 第二頁選擇圖片後，按「儲存當前頁」。
5. 第三頁新增或修改欄位後，按「儲存」或「儲存當前頁」。
6. 第四頁填入 `團隊 ID`，按「讀取團務劇情」。
7. 第五頁填入 `成員 ID`，或填入 `團隊代碼` 與 `成員代碼`，再填寫角色代碼與角色名稱後按「建立角色」。

第五頁建立角色的最低資料需求：

| 欄位 | 說明 |
|---|---|
| `成員 ID` | 對應 `dbo.Team_Member.team_member_id`。也可改用團隊代碼與成員代碼 |
| `團隊代碼`、`成員代碼` | 未填成員 ID 時使用 |
| `角色代碼` | 同一成員不可重複 |
| `角色名稱` | 必填 |

HTML 使用 Chart.js CDN。若離線開啟且 Chart.js 未載入，文字與表格仍可閱讀。

## 8. 自我檢查

- 已檢查 `05_Player_Character.sql`、`09_Item.sql`、`12_Utterance.sql`、`14_Plot_Event.sql`、`16_Decision_Log.sql`、`17_Knowledge_Retrieval_Log.sql` 的欄位，新增查詢未使用不存在的欄位。
- 已用 GitHub 連結讀取遠端 `database/05_Player_Character.sql`，確認本機欄位與遠端主線檔案相符。
- 已查 Microsoft Learn 的 SQL Server 視圖、預存程序、`FOR JSON PATH` 與 `sqlcmd` 文件，確認視圖、JSON 與輸出檔命令用法。
- 已查 Chart.js、MDN Fetch API、MDN FileReader 與 Microsoft `HttpListener` 文件，確認 HTML 圖表、圖片讀取與本機 API 呼叫方式。
- 已在 `.\SQLEXPRESS / TRPG_Corpus_DB` 執行第 `27` 號腳本，確認新增資料表、視圖與程序存在，包含 `dbo.vw_Team_Story_Record`、`dbo.usp_Get_Team_Story_Export` 與 `dbo.usp_Create_Player_Character_From_Web`。
- 已短暫啟動 `tools/character_profile_api.ps1`，`/api/health` 回傳 `ok=true`。

## 參考文獻

Chart.js. (2025). *Getting started*. https://www.chartjs.org/docs/latest/getting-started/

MDN contributors. (n.d.). *Fetch API*. MDN Web Docs. Retrieved May 6, 2026, from https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API

MDN contributors. (n.d.). *FileReader: readAsDataURL() method*. MDN Web Docs. Retrieved May 6, 2026, from https://developer.mozilla.org/en-US/docs/Web/API/FileReader/readAsDataURL

MDN contributors. (n.d.). *FileReader: readAsText() method*. MDN Web Docs. Retrieved May 6, 2026, from https://developer.mozilla.org/en-US/docs/Web/API/FileReader/readAsText

Microsoft. (n.d.). *Create views - SQL Server*. Microsoft Learn. Retrieved May 6, 2026, from https://learn.microsoft.com/en-us/sql/relational-databases/views/create-views

Microsoft. (n.d.). *CREATE PROCEDURE (Transact-SQL)*. Microsoft Learn. Retrieved May 6, 2026, from https://learn.microsoft.com/en-us/sql/t-sql/statements/create-procedure-transact-sql

Microsoft. (n.d.). *System.Net.HttpListener class*. Microsoft Learn. Retrieved May 6, 2026, from https://learn.microsoft.com/en-us/dotnet/fundamentals/runtime-libraries/system-net-httplistener

Microsoft. (n.d.). *Solve common issues with JSON in SQL Server*. Microsoft Learn. Retrieved May 6, 2026, from https://learn.microsoft.com/en-us/sql/relational-databases/json/solve-common-issues-with-json-in-sql-server

Microsoft. (n.d.). *Use sqlcmd - SQL Server*. Microsoft Learn. Retrieved May 6, 2026, from https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-use-utility
