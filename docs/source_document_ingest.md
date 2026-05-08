# TRPG 團錄與二創文本接收設計

## 自我檢查

- 已檢查 5 個 TRPG 團錄 `.docx`、2 個二創小說 `.docx`、大國年代記正史足跡 HTML。
- 已比對既有 `dbo.Utterance`、`stg.Utterance_Import`、`dbo.Extended_Creation_Text`。
- 已新增來源文件層、文字區塊層、二創文本 staging、docx/html 抽取工具。
- 已核對 Microsoft Learn `OPENJSON`、SQL Server FILESTREAM、Open XML WordprocessingML 文件。
- 資料不足，需要新資料提供：角色別名表、PL/PC/GM 對應、二創作者對應、授權範圍、匿名化規則、是否可將原始二進位檔放入 SQL Server。

## 檔案型態判斷

| 檔案 | 類型 | 文字單位 | 擲骰列 | 建議進入路徑 |
| --- | --- | ---: | ---: | --- |
| `團錄參考(劇本祈禍－PC楚服&陽月&花瓊瑤).docx` | 團錄 | 19,021 | 704 | `stg.Source_Text_Block_Import` 到 `stg.Utterance_Import` |
| `團錄參考(劇本素雅－PC楚服&陽月&花瓊瑤).docx` | 團錄 | 7,588 | 860 | `stg.Source_Text_Block_Import` 到 `stg.Utterance_Import` |
| `團錄參考(劇本雙孤－PC楚服).docx` | 團錄 | 19,373 | 519 | `stg.Source_Text_Block_Import` 到 `stg.Utterance_Import` |
| `團錄參考(劇本雙孤－PC花瓊瑤).docx` | 團錄 | 3,423 | 79 | `stg.Source_Text_Block_Import` 到 `stg.Utterance_Import` |
| `團錄參考(劇本雙孤－PC陽月).docx` | 團錄 | 21,195 | 467 | `stg.Source_Text_Block_Import` 到 `stg.Utterance_Import` |
| `大國年代記－戎裝.docx` | 二創小說 | 4,128 | 0 | `stg.Extended_Creation_Text_Import` 到 `dbo.Extended_Creation_Text` |
| `大國年代記－素雅.docx` | 混合二創 | 8,719 | 862 | 完整文本進二創 staging，擲骰與角色列保留為來源區塊 |

團錄檔主要有 `說話者：內容`、動作括號、擲骰列與骰值結果。二創小說多為散文段落；`大國年代記－素雅.docx` 含回合與擲骰，需標為混合文本。

## 新增資料表

1. `stg.Source_Document_Import`
   - 保存檔名、SHA-256、來源資料夾、文件類型、抽取文字、docx core metadata、段落數、文字單位數、擲骰列數。
   - 文件類型：`trpg_transcript`、`extended_creation`、`hybrid_creation`、`forum_html`、`da_go_playlog`、`researcher_note`、`other`。

2. `stg.Source_Text_Block_Import`
   - 保存每個段落或行的候選資料。
   - 候選類型：`utterance`、`action_note`、`dice_roll`、`dice_result`、`narration`、`prose`、`chapter_heading`。
   - 所有 speaker 與 block type 都先進候選欄位，人工審核後再轉進正式匯入路徑。

3. `stg.Extended_Creation_Text_Import`
   - 保存二創小說與混合文本的全文 staging。
   - 審核後載入 `dbo.Extended_Creation_Text`。

## 新增程序

| 程序 | 用途 |
| --- | --- |
| `stg.usp_Load_Source_Document_Json` | 將工具輸出的 JSON 載入來源文件與文字區塊 staging |
| `stg.usp_Build_Utterance_Import_From_Source_Text_Block` | 將已審核來源區塊轉成 `stg.Utterance_Import` |
| `stg.usp_Load_Extended_Creation_Text_Import_To_Dbo` | 將已審核二創文本載入 `dbo.Extended_Creation_Text` |

## 抽取工具

```powershell
python .\tools\extract_source_document.py `
  ".\TRPG遊戲團錄範例\團錄參考(劇本雙孤－PC陽月).docx" `
  --out-dir ".\exports\source_documents" `
  --project-code "DAGUO" `
  --team-code "DAGUO-T01" `
  --session-code "DA20-SHUANGGU-YANGYUE"
```

工具輸出 JSON 後，將 JSON 內容傳給 SQL：

```sql
DECLARE @json NVARCHAR(MAX) = N'...';

EXEC stg.usp_Load_Source_Document_Json
    @source_document_json = @json;
```

團錄轉入逐字稿 staging：

```sql
EXEC stg.usp_Build_Utterance_Import_From_Source_Text_Block
    @source_document_code = N'SRC-example',
    @batch_code = N'DAGUO_TRANSCRIPT_001',
    @project_code = N'DAGUO',
    @team_code = N'DAGUO-T01',
    @session_code = N'DA20-SHUANGGU-YANGYUE',
    @default_scene_code = N'SCN-REVIEW-001',
    @only_reviewed = 1;
```

二創文本轉入正式表：

```sql
EXEC stg.usp_Load_Extended_Creation_Text_Import_To_Dbo
    @source_document_code = N'SRC-example',
    @allow_unreviewed = 0;
```

## 原始檔處理

原始 `.docx`、`.html`、`.pdf`、DoL zip 與解壓目錄不提交到 GitHub。匯入後保留以下資料即可追溯：

- SHA-256
- 檔名與來源資料夾
- 抽取文字
- 段落號與行號
- speaker 與 block 候選欄位
- 人工審核欄位

若研究流程要求保存原始二進位檔，使用 `storage_mode = database_binary` 或 SQL Server FILESTREAM。若倫理或授權要求不保存，使用 `storage_mode = text_only`。

## 參考文獻

Microsoft. (n.d.). *FILESTREAM (SQL Server)*. Microsoft Learn. Retrieved May 8, 2026, from https://learn.microsoft.com/en-us/sql/relational-databases/blob/filestream-sql-server

Microsoft. (n.d.). *OPENJSON (Transact-SQL)*. Microsoft Learn. Retrieved May 8, 2026, from https://learn.microsoft.com/en-us/sql/t-sql/functions/openjson-transact-sql

Microsoft. (n.d.). *Open and add text to a word processing document*. Microsoft Learn. Retrieved May 8, 2026, from https://learn.microsoft.com/en-us/office/open-xml/word/how-to-open-and-add-text-to-a-word-processing-document

Rameshkumar, R., & Bailey, P. (2020). Storytelling with dialogue: A Critical Role Dungeons and Dragons dataset. In *Proceedings of the 58th Annual Meeting of the Association for Computational Linguistics* (pp. 5121-5134). Association for Computational Linguistics. https://doi.org/10.18653/v1/2020.acl-main.459

Zhu, A., Aggarwal, K., Feng, A., Martin, L. J., & Callison-Burch, C. (2023). FIREBALL: A dataset of Dungeons and Dragons actual-play with structured game state information. In *Proceedings of the 61st Annual Meeting of the Association for Computational Linguistics (Volume 1: Long Papers)* (pp. 4171-4193). Association for Computational Linguistics. https://doi.org/10.18653/v1/2023.acl-long.229
