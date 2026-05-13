# da_go corpus input v13 工作手冊

版本：

```text
2026-05-12 json-xlsx-v13-indexeddb-large-workspace
```

本手冊是 v13 分支與 v13 preview 的工作基準。v13 的目標是將大型逐字稿工作區從 `sessionStorage rows` 改為 IndexedDB 本機工作區。

## 一、版本號檢查規則

每次編輯前必須先檢查一次版本號是否相同。

必查位置：

```text
1. web/dago-corpus-input.html 大標題
2. web/dago-corpus-review.html 大標題
3. web/v13-preview/dago-corpus-input.html 大標題
4. web/v13-preview/dago-corpus-review.html 大標題
5. 所有 active script 的 query string
6. 本手冊版本號
```

若版本號不一致，必須先更新成相同版本號，再開始功能修改。

目前統一版本號：

```text
2026-05-12 json-xlsx-v13-indexeddb-large-workspace
```

## 二、v13 active files

v13 分支 active files：

```text
web/dago-corpus-input.html
web/dago-corpus-review.html
web/assets/dago-corpus-workspace-v13.js
web/assets/dago-corpus-workspace-ops-v13.js
web/assets/dago-corpus-parser-v13.js
web/assets/dago-corpus-docx-v13.js
web/assets/dago-corpus-open-review-v13.js
web/assets/dago-corpus-input-ops-v13.js
web/assets/dago-corpus-review-v13.js
web/assets/dago-corpus-export-v13.js
```

v13 preview active files：

```text
web/v13-preview/dago-corpus-input.html
web/v13-preview/dago-corpus-review.html
web/v13-preview/assets/dago-corpus-workspace-v13.js
web/v13-preview/assets/dago-corpus-workspace-ops-v13.js
web/v13-preview/assets/dago-corpus-parser-v13.js
web/v13-preview/assets/dago-corpus-docx-v13.js
web/v13-preview/assets/dago-corpus-open-review-v13.js
web/v13-preview/assets/dago-corpus-input-ops-v13.js
web/v13-preview/assets/dago-corpus-review-v13.js
web/v13-preview/assets/dago-corpus-export-v13.js
```

## 三、目前資料流

```text
Word .docx
→ dago-corpus-docx-v13.js
→ sourceText
→ dago-corpus-parser-v13.js
→ rows / maps
→ dago-corpus-workspace-v13.js
→ IndexedDB workspaces / rows / maps
→ input preview / review page
```

## 四、目前已支援功能

```text
1. Word .docx 匯入。
2. sourceText 解析。
3. rows 寫入 IndexedDB。
4. maps 寫入 IndexedDB。
5. Speaker Mapping 顯示。
6. stg.Utterance_Import 預覽顯示。
7. 輸入頁上一頁 / 下一頁。
8. 審閱頁上一頁 / 下一頁。
9. speaker filter。
10. 單列上插。
11. 單列下插。
12. 單列刪除。
13. 單列分割。
14. 單列欄位修改後寫回 IndexedDB。
15. 清除本機工作區。
```

## 五、尚未完成

```text
1. JSON 從 IndexedDB 全量匯出。
2. XLSX 四工作表從 IndexedDB 全量匯出。
3. UTF-16LE TSV 從 IndexedDB 全量匯出。
4. 全量前端驗證。
5. 匯出前 source_row_no / turn_no_text / utterance_code 最終正規化。
```

目前 `dago-corpus-export-v13.js` 是佔位腳本，不應視為正式匯出功能。

## 六、檢查各表連線

在瀏覽器 Console 檢查：

```javascript
const id = DagoCorpusWorkspaceV13.getCurrentWorkspaceId();
const rows = await DagoCorpusWorkspaceV13.getAllRows(id);
const maps = await DagoCorpusWorkspaceV13.getAllMaps(id);
console.log(id, rows.length, maps.length);
console.log(document.querySelectorAll('#rows tr').length);
console.log(document.querySelectorAll('#mappingRows tr').length);
```

判斷：

```text
rows > 0 且 #rows tr > 0：stg.Utterance_Import 預覽已接上。
maps > 0 且 #mappingRows tr > 0：Speaker Mapping 已接上。
rows > 100 且下一頁可顯示資料：分頁已接上 IndexedDB。
審閱頁與輸入頁使用同一 workspace_id：跨頁讀取已接上。
```

## 七、不得修改項目

```text
database/*.sql
JSON 欄位
XLSX 四工作表
UTF-16LE TSV 欄位
stg.Utterance_Import
dbo.Utterance
```

正式資料仍應由匯出 JSON / XLSX / TSV 後，用 SSMS 22 匯入 SQL Server。v13 IndexedDB 僅是瀏覽器本機工作區。
