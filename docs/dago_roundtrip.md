# da_go 與 trpg-corpus 循環流程

## 自我檢查

- 已檢查 `database/12_Utterance.sql`、`23_stg_Utterance_Import.sql`、`24_stg_usp_Validate_Utterance_Import.sql`、`25_stg_usp_Load_Utterance_Import_To_Dbo.sql`。
- 已加入 `27_stg_DaGo_Game_Run_Import.sql`、`28_dago_world_manifest_export.sql`、`29_stg_DaGo_PlayLog_Import.sql`、`30_stg_usp_Validate_DaGo_PlayLog_Import.sql`、`31_stg_usp_Load_DaGo_PlayLog_To_Utterance_Import.sql`、`38_dago_runtime_bundle.sql`、`39_stg_DaGo_Researcher_Story_Import.sql`。
- 已加入 `web/dago-corpus-input.html` 與 `tools/dago_corpus_api.ps1`。
- 已用 `/api/researcher-stories` 測試研究者劇情 JSON 暫存、驗證與載入錯誤回報。
- 已核對 Microsoft Learn SQL Server JSON 文件與 ACL Anthology TRPG/NLP 論文。
- 資料不足，需要新資料提供：真實團錄發布授權、匿名化規則、角色別名表、正式 SQL Server 連線位置、研究者帳號權限。

## 流程

1. 研究者把論壇 HTML、純文字團錄或手動整理內容放進 `web/dago-corpus-input.html`。
2. HTML 頁產生 `stg_Import_Batch` 與 `stg_Utterance_Import` JSON/CSV。
3. SQL Server 匯入 `stg.Utterance_Import` 後執行既有驗證與載入程序。
4. `dbo.usp_Export_DaGo_World_Manifest` 依 project、team、session 輸出 `da_go_world_manifest_v1`。
5. `dbo.usp_Export_DaGo_Runtime_Bundle` 輸出 `da_go_runtime_bundle_v1`，供前端直接執行。
6. da_go 從檔案或 API 讀取 runtime bundle，生成單人遊戲。
7. 研究者在 da_go 的「研究者」面板編寫 passage、choice 與正文。
8. `POST /api/researcher-stories` 保存原始 JSON，驗證後載入 `dbo.Game_Passage` 與 `dbo.Game_Choice`。
9. da_go 輸出 `da_go_playlog_json_v2`。
10. `stg.DaGo_PlayLog_Import` 保存原始 playlog。
11. `stg.usp_Load_DaGo_PlayLog_To_Utterance_Import` 轉成既有 `stg.Utterance_Import`。
12. 若使用整包 JSON 匯入，`POST /api/dago-game-runs` 會呼叫 `stg.usp_Load_DaGo_Game_Run_Json_To_Staging` 保存 `game_state` 與 `raw_game_events`，並將 `stg_Utterance_Import` 陣列拆入 `stg.Utterance_Import`。
13. 再跑既有 `stg.usp_Validate_Utterance_Import` 與 `stg.usp_Load_Utterance_Import_To_Dbo`。

## SQL 執行順序

```text
database/27_stg_DaGo_Game_Run_Import.sql
database/28_dago_world_manifest_export.sql
database/29_stg_DaGo_PlayLog_Import.sql
database/30_stg_usp_Validate_DaGo_PlayLog_Import.sql
database/31_stg_usp_Load_DaGo_PlayLog_To_Utterance_Import.sql
database/38_dago_runtime_bundle.sql
database/39_stg_DaGo_Researcher_Story_Import.sql
```

## API

啟動：

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\dago_corpus_api.ps1 -Prefix "http://localhost:8787/" -Server ".\SQLEXPRESS" -Database "TRPG_Corpus_DB"
```

讀取 manifest：

```text
GET http://localhost:8787/api/world-manifest?project_code=DAGO&team_code=DAGO-T01&session_code=DA20-CORPUS-RPG-001
```

讀取 runtime bundle：

```text
GET http://localhost:8787/api/runtime-bundle?project_code=DAGO&team_code=DAGO-T01&session_code=DA20-CORPUS-RPG-001
```

提交 playlog：

```text
POST http://localhost:8787/api/dago-playlogs
```

提交整包遊玩紀錄並直接拆入 staging：

```text
POST http://localhost:8787/api/dago-game-runs
```

提交研究者劇情：

```text
POST http://localhost:8787/api/researcher-stories
```

載入 `dbo.Game_Passage` 與 `dbo.Game_Choice` 前，資料庫需已有對應的 `project_code`、`team_code` 與 `session_code`。若缺少對應列，API 仍會保存 `stg.DaGo_Researcher_Story_Import`，並在回應內提供 `load_error`。

載入 playlog 到既有 staging：

```text
POST http://localhost:8787/api/dago-playlogs/{playlog_code}/load
```

直接載入整包遊玩紀錄 JSON：

```sql
DECLARE @json NVARCHAR(MAX);

SELECT @json = BulkColumn
FROM OPENROWSET(BULK N'C:\data\da_go_playlog.json', SINGLE_CLOB) AS source_file;

EXEC stg.usp_Load_DaGo_Game_Run_Json_To_Staging
    @source_json = @json,
    @imported_by = N'researcher',
    @source_file_name = N'da_go_playlog.json';
```

## 大國年代記輸入規則

- 來源頁是論壇列印頁，先以 HTML DOM 取文字，再依換行拆候選列。
- `黑大拿`、`GM`、`主持` 預設候選 `GM`。
- 未帶 speaker 的列預設 `Observer`，需人工改成正確 speaker。
- 角色別名只進入 `speaker_label_raw` 與 `speaker_code` 候選，不直接合併。
- 每列保留 `source_url` 與 `source_file_name` 到 `ai_annotation_json`。

## 參考文獻

Louis, A., & Sutton, C. (2018). Deep Dungeons and Dragons: Learning character-action interactions from role-playing game transcripts. In *Proceedings of the 2018 Conference of the North American Chapter of the Association for Computational Linguistics: Human Language Technologies, Volume 2 (Short Papers)* (pp. 708-713). Association for Computational Linguistics. https://doi.org/10.18653/v1/N18-2111

Microsoft. (n.d.). *Work with JSON data in SQL Server*. Microsoft Learn. Retrieved May 8, 2026, from https://learn.microsoft.com/en-us/sql/relational-databases/json/json-data-sql-server

Rameshkumar, R., & Bailey, P. (2020). Storytelling with dialogue: A Critical Role Dungeons and Dragons dataset. In *Proceedings of the 58th Annual Meeting of the Association for Computational Linguistics* (pp. 5121-5134). Association for Computational Linguistics. https://doi.org/10.18653/v1/2020.acl-main.459

Zhu, A., Aggarwal, K., Feng, A., Martin, L. J., & Callison-Burch, C. (2023). FIREBALL: A dataset of Dungeons and Dragons actual-play with structured game state information. In *Proceedings of the 61st Annual Meeting of the Association for Computational Linguistics (Volume 1: Long Papers)* (pp. 4171-4193). Association for Computational Linguistics. https://doi.org/10.18653/v1/2023.acl-long.229
