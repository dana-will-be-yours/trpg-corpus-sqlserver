# trpg-corpus-sqlserver
for TRPG use

# TRPG Corpus SQL Server Database

本專案為「以桌上角色扮演遊戲為基礎之共創機制研究」使用的 SQL Server 語料資料庫骨架。

研究目的：
1. 儲存 TRPG 共創歷程與敘事語料。
2. 支援角色查詢、劇情片段檢索、關聯故事查找、世界觀查詢。
3. 支援事件因果鏈回溯、設定共現查詢、敘事節奏檢視。
4. 對應 SMM 與 TMS 研究變數，保存問卷、標註、查詢紀錄與決策紀錄。

建置順序：
1. 在 SSMS 連線到 SQL Server。
2. 執行 `sql/00_create_database.sql`
3. 執行 `sql/01_schema_core.sql`
4. 執行 `sql/02_seed_lookup.sql`
5. 執行 `sql/03_views.sql`
6. 執行 `sql/04_sample_data.sql`
7. 使用 `sql/05_queries.sql` 測試查詢功能。

GitHub 使用：
```bash
git init
git add .
git commit -m "Initial TRPG corpus SQL Server schema"
git branch -M main
git remote add origin https://github.com/<your-account>/<your-repo>.git
git push -u origin main
```

注意：
- `.bak`、逐字稿原檔、受試者個資、錄音檔、影片檔不應直接上傳公開 GitHub。
- 研究資料應去識別化後才可進入版本庫。
- SQL Server 的資料庫內容本身不會自動同步到 GitHub；GitHub 主要保存 schema、查詢腳本、資料字典與匿名化樣本資料。
