# trpg corpus input v1.4 工作手冊

版本正式名稱：

```text
trpg corpus input v1.4
```

本手冊是 `v1.4` 分支的工作基準。`v1.4` 由 v1.4 總驗收版複製建立，核心目標是保留 v1.4 已完成的語料整理、Speaker Mapping、IndexedDB 工作區、前端驗證、JSON / UTF-16LE TSV / XLSX 匯入匯出與分批匯出能力，作為下一步論文銜接計畫的穩定基準。

## 一、建立來源

```text
來源分支 / 來源部署：gh-pages 總驗收版
來源 commit：7549a90344aec49270cb2bc704f910dae31be228
新分支：v1.4
正式名稱：trpg corpus input v1.4
script query：trpg-corpus-input-v1-4
```

## 二、v1.4 active files

v1.4 沿用 v1.4 檔名與命名空間，避免大規模改名造成 JS 相依性中斷。正式版本名稱以頁面標題、core VERSION、文件與靜態檢查腳本為準。

```text
web/dago-corpus-input.html
web/dago-corpus-review.html
web/assets/dago-corpus-v1-4-core.js
web/assets/dago-corpus-workspace-v1-4.js
web/assets/dago-corpus-workspace-ops-v1-4.js
web/assets/dago-corpus-parser-v1-4.js
web/assets/dago-corpus-docx-v1-4.js
web/assets/dago-corpus-open-review-v1-4.js
web/assets/dago-corpus-input-ops-v1-4.js
web/assets/dago-corpus-review-v1-4.js
web/assets/dago-corpus-xlsx-core-v1-4.js
web/assets/dago-corpus-mapping-io-v1-4.js
web/assets/dago-corpus-export-v1-4.js
web/assets/dago-corpus-xlsx-parts-v1-4.js
web/assets/dago-corpus-large-import-v1-4.js
web/assets/dago-corpus-stress-test-v1-4.js
web/assets/dago-corpus-mapping-validation-v1-4.js
web/assets/dago-corpus-help-v1-4.js
web/assets/dago-corpus-v1-4-selftest.js
```

## 三、版本號檢查規則

每次編輯前必須先檢查下列位置是否一致：

```text
1. web/dago-corpus-input.html 大標題：trpg corpus input v1.4
2. web/dago-corpus-review.html 大標題：trpg corpus input v1.4
3. active script query：trpg-corpus-input-v1-4
4. web/assets/dago-corpus-v1-4-core.js 的 VERSION：trpg corpus input v1.4
5. 本手冊版本名稱
6. tools/check_v1_4_static_refs.ps1 的 ExpectedVersion / ExpectedQuery
```

## 四、保留功能

```text
1. Word .docx 匯入。
2. sourceText 解析。
3. IndexedDB workspaces / rows / maps。
4. Speaker Mapping 顯示、編輯、套用。
5. Speaker Mapping JSON 匯出與匯入。
6. Speaker Mapping UTF-16LE TSV 匯出與匯入。
7. Speaker Mapping XLSX 匯出與匯入。
8. 無 workspace 時可下載 Mapping 範本。
9. 無 workspace 時匯入 Mapping 可自動建立 Mapping 匯入 workspace。
10. stg.Utterance_Import 預覽。
11. input / review 分頁。
12. speaker filter。
13. 單列新增、刪除、分割與欄位更新。
14. JSON / UTF-16LE TSV / XLSX 全量匯出。
15. JSON / UTF-16LE TSV / XLSX cursor 分批匯出。
16. 前端驗證寫回 frontend_validation_error / frontend_validation_warning。
17. speaker_code mismatch 時寫回 Observer / OBS_MISMATCH。
18. Large Mode 分批解析與寫入。
19. 壓力測試資料產生器。
20. selftest 僅在 ?selftest=1 啟用。
```

## 五、Speaker Mapping mismatch 規則

```text
A. 找不到 mapping：
   不改 row，只寫 warning。

B. 找到 mapping，row.speaker_code 空白：
   speaker_code = mapping.speaker_code
   speaker_type = mapping.speaker_type
   is_in_character_text 依 speaker_type 更新
   寫入 warning。

C. 找到 mapping，row.speaker_code 與 mapping.speaker_code 一致：
   若 speaker_type 空白或不一致，依 mapping.speaker_type 修正。
   is_in_character_text 依 speaker_type 更新。
   寫入 warning。

D. 找到 mapping，row.speaker_code 與 mapping.speaker_code 不一致：
   speaker_type = Observer
   speaker_code = OBS_MISMATCH
   is_in_character_text = 0
   寫入 warning。
```

## 六、論文銜接定位

v1.4 是論文工具鏈的穩定前端基準，對應博士論文第 4 章先導研究與第 5 章資料庫與語料治理。下一步應依 `trpg_corpus_v1_4_next_github_plan_and_thesis_alignment.md` 推進實驗資料治理層。

下一階段不應優先擴充遊戲性。優先任務是建立正式實驗所需資料表與匯入流程：

```text
Experimental_Condition
Participant_Assignment
Questionnaire_Scale / Questionnaire_Item / Questionnaire_Response
Operation_Check
Participant_Query_Log
Consent_Record / IRB_Document / Safety_Event
Concept_Map / Concept_Map_Node / Concept_Map_Edge
Expert_Rater / Expert_Rating_Rubric / Rater_Reliability
Interview / Interview_Code
Main analysis views
```

## 七、SSMS 22 原則

```text
1. 修改 schema 前先備份 TRPG_Corpus_DB。
2. 新表使用 dbo schema。
3. 暫存匯入使用 stg schema。
4. 不使用 DROP、DELETE、TRUNCATE。
5. 不使用 MySQL、PostgreSQL、SQLite 語法。
6. 問卷、訪談、概念圖與評分資料保留 raw、clean、verified 或 version 欄位。
7. 分析 view 只查詢，不寫入資料。
```

## 八、結論

`trpg corpus input v1.4` 是 v1.4 的正式穩定化分支。它保留目前已驗收的前端語料處理能力，並為下一步論文銜接計畫提供固定基準。下一個開發分支應在 v1.4 之上建立實驗資料治理層，而非修改已穩定的逐字稿與 Speaker Mapping 工作流。
