# da_go corpus input v9 使用手冊

版本記錄：

```text
2026-05-12 json-xlsx-v5-mapping
2026-05-12 json-xlsx-v6-edit-stable
2026-05-12 json-xlsx-v7-row-delete-responsive
2026-05-12 json-xlsx-v8-field-notes
2026-05-12 json-xlsx-v9-block-clean-preview
```

本手冊以 v9 作為後續維護基準。v9 新增前端解析增強：speaker block 合併、括號動作辨識、clean preview 欄。v9 不修改 SQL Server 暫存表與正式表，不修改 JSON 欄位結構，不修改 XLSX 工作表結構。

公開頁：

```text
https://dana-will-be-yours.github.io/trpg-corpus-sqlserver/web/dago-corpus-input.html?v=20260512-v9-block-clean-preview
```

主分支檔案：

```text
web/dago-corpus-input.html
web/assets/dago-corpus-input-v9.js
web/assets/dago-corpus-input-v8.js
web/assets/dago-corpus-input-v7.js
web/assets/dago-corpus-input-v6.js
web/assets/dago-corpus-input-v5.js
```

## 一、v9 目標

v9 目標是讓 TRPG 團錄 raw 文字更接近研究者預期的清洗結果。

原始資料常見格式：

```text
陽月：這個嘛…
我家的商會在以前似乎只是間賣雜貨的鋪子。
義父好像為了還清開店借的錢，跑去從軍一段時日，這裡還受了傷。(用手指著臉
幸好店免於當年戰火的波及，就帶傷回了雁洄繼續做著小本生意。
```

v9 解析後會把沒有 speaker 前綴的後續行接到上一位 speaker，成為同一個 speaker block。

clean preview 會產生：

```text
(對話)這個嘛… (對話)我家的商會在以前似乎只是間賣雜貨的鋪子。 (對話)義父好像為了還清開店借的錢，跑去從軍一段時日，這裡還受了傷。 (動作)用手指著臉 (對話)幸好店免於當年戰火的波及，就帶傷回了雁洄繼續做著小本生意。
```

## 二、新增函式

v9 新增或重點修改：

```text
parseTranscriptBlocks()
splitInlineActionSegments()
buildCleanUtteranceText()
parse()
renderRows()
```

用途：

```text
parseTranscriptBlocks()
將 raw 文字切成 speaker blocks。遇到「角色名：內容」建立新 block；沒有角色名前綴的行接續上一個 block。

splitInlineActionSegments()
拆分括號內與括號外文字。括號外標為對話；括號內標為動作。

buildCleanUtteranceText()
依 splitInlineActionSegments() 結果產生 clean preview。

parse()
由逐行建立 row 改為先建立 speaker block，再建立 stg.Utterance_Import row。

renderRows()
新增 clean preview 欄，對應 utterance_text_clean。
```

## 三、資料欄位不變

v9 不新增 JSON/XLSX 欄位。仍使用既有欄位：

```text
utterance_text_raw
utterance_text_clean
utterance_text_verified
```

對應規則：

```text
raw text       → utterance_text_raw
clean preview  → utterance_text_clean
人工確認文本   → utterance_text_verified
```

`stg_Utterance_Import` 工作表欄位仍維持既有設計，不因前端新增 clean preview 欄而改變匯出欄位。

## 四、範例轉換

raw：

```text
樂喜：當然是雁洄的了！
蕭嚴華：(富有興趣地準備跟著聽一聽
陽月：這個嘛…
我家的商會在以前似乎只是間賣雜貨的鋪子。
義父好像為了還清開店借的錢，跑去從軍一段時日，這裡還受了傷。(用手指著臉
```

v9 預期 row：

```text
row 1
speaker_label_raw = 樂喜
utterance_text_raw = 樂喜：當然是雁洄的了！
utterance_text_clean = (對話)當然是雁洄的了！

row 2
speaker_label_raw = 蕭嚴華
utterance_text_raw = 蕭嚴華：(富有興趣地準備跟著聽一聽
utterance_text_clean = (動作)富有興趣地準備跟著聽一聽

row 3
speaker_label_raw = 陽月
utterance_text_raw = 陽月：這個嘛… + 後續接續行
utterance_text_clean = (對話)這個嘛… (對話)我家的商會在以前似乎只是間賣雜貨的鋪子。 (對話)義父好像為了還清開店借的錢，跑去從軍一段時日，這裡還受了傷。 (動作)用手指著臉
```

## 五、function 判斷

v9 的 function 判斷以 clean text 為基礎：

```text
GM speaker → narration
只有動作、沒有對話 → action
含擲骰、檢定、規則、成功、失敗 → rule_check
含決定、我選、我們要、同意、不同意、採用、投票 → decision
含問句或疑問詞 → question
含動作段落 → action
其他 → dialogue
```

注意：這是前端初步分類。正式研究分類仍應由研究者審閱與人工修正。

## 六、Speaker Mapping

speaker_code 必須改成 SQL Server 正式表已有 code。

```text
GM / PL / Observer / Researcher → dbo.Team_Member.member_code
PC                              → dbo.Player_Character.character_code
NPC                             → dbo.NPC.npc_code
```

前端自動產生的 code 只作為暫時值。

## 七、匯出與 SQL 匯入流程

v9 匯出 JSON / XLSX 的流程不變。

JSON 包含：

```text
metadata
stg_Import_Batch
stg_Utterance_Import
Code_Mapping
frontend_validation_summary
```

XLSX 包含：

```text
stg_Import_Batch
stg_Utterance_Import
Code_Mapping
Metadata
```

SQL Server 仍使用既有流程：

```sql
EXEC stg.usp_Import_Utterance_From_Json
    @json = @json,
    @source_file_name = N'dago_utterance_import.json',
    @imported_by = N'researcher',
    @run_validation = 1;
GO
```

或 XLSX raw 流程：

```sql
EXEC stg.usp_Move_Utterance_Xlsx_Raw_To_Import
    @batch_code = N'DAGO_HTML_UTT_001',
    @source_file_name = N'dago_utterance_import.xlsx',
    @imported_by = N'researcher',
    @run_validation = 1;
GO
```

正式載入前請先備份資料庫。

## 八、版本接續原則

後續修改請以 v9 作為基準：

```text
版本：2026-05-12 json-xlsx-v9-block-clean-preview
主分支：main
公開分支：gh-pages
公開頁：web/dago-corpus-input.html
核心腳本：web/assets/dago-corpus-input-v9.js
保留回溯腳本：web/assets/dago-corpus-input-v8.js
保留回溯腳本：web/assets/dago-corpus-input-v7.js
保留回溯腳本：web/assets/dago-corpus-input-v6.js
保留回溯腳本：web/assets/dago-corpus-input-v5.js
```

若後續新增欄位，必須同步修改：

```text
1. HTML 預覽表頭
2. JS 的 U / B / M 欄位陣列
3. JSON payload()
4. XLSX sheets
5. stg.Utterance_Import_Xlsx_Raw
6. stg.usp_Import_Utterance_From_Json
7. stg.usp_Move_Utterance_Xlsx_Raw_To_Import
8. stg.usp_Validate_Utterance_Import
9. stg.usp_Load_Utterance_Import_To_Dbo
```
