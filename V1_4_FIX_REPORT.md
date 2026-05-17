# v1.4 完全隔離修正報告

修正目標：移除 active v13 參照，建立 v1.4 專用前端檔案、命名空間與本機 IndexedDB 工作區。

主要判準：

1. active HTML 不再載入 `*-v13.js`。
2. active JavaScript 使用 `DagoCorpus*V14`。
3. IndexedDB DB_NAME 使用 `dagoCorpusWorkspaceDB_v14`。
4. SESSION_KEY 使用 `dagoCorpusWorkspaceCurrentV14`。
5. Speaker Mapping mismatch 警告包含 `偵測發話人未知，待確認`。
