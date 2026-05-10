param
(
    [string]$Server = ".\SQLEXPRESS",
    [string]$Database = "TRPG_Corpus_DB",
    [string]$Sqlcmd = "sqlcmd"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$DatabaseDir = Join-Path $Root "database"

$Files = @(
    "00_create_database.sql",
    "01_Research_Project.sql",
    "02_Team.sql",
    "03_Player.sql",
    "04_Team_Member.sql",
    "05_Player_Character.sql",
    "06_NPC.sql",
    "07_Game_Rule.sql",
    "08_World_Setting.sql",
    "09_Item.sql",
    "10_TRPG_Session.sql",
    "11_Scene.sql",
    "12_Utterance.sql",
    "13_GM_Narration.sql",
    "14_Plot_Event.sql",
    "15_Event_Causal_Link.sql",
    "16_Decision_Log.sql",
    "17_Knowledge_Retrieval_Log.sql",
    "18_Team_Play_History.sql",
    "19_Extended_Creation_Text.sql",
    "20_Expert_Rating.sql",
    "21_stg_schema.sql",
    "22_stg_Import_Batch.sql",
    "23_stg_Utterance_Import.sql",
    "24_stg_usp_Validate_Utterance_Import.sql",
    "25_stg_usp_Load_Utterance_Import_To_Dbo.sql",
    "26_performance_indexes.sql",
    "27_character_profile_export.sql",
    "28_dago_world_manifest_export.sql",
    "29_stg_DaGo_PlayLog_Import.sql",
    "30_stg_usp_Validate_DaGo_PlayLog_Import.sql",
    "31_stg_usp_Load_DaGo_PlayLog_To_Utterance_Import.sql",
    "32_stg_Source_Document_Import.sql",
    "33_stg_Source_Text_Block_Import.sql",
    "34_stg_Extended_Creation_Text_Import.sql",
    "35_stg_usp_Load_Source_Document_Json.sql",
    "36_stg_usp_Build_Utterance_Import_From_Source_Text_Block.sql",
    "37_stg_usp_Load_Extended_Creation_Text_Import_To_Dbo.sql",
    "38_dago_runtime_bundle.sql",
    "39_stg_DaGo_Researcher_Story_Import.sql",
    "40_dago_authoring_reference_schema.sql",
    "42_dago_scenario_authoring_schema.sql",
    "42_dago_reference_project_story_seed.sql",
    "43_dago_xiaocheng_jiushi_seed.sql"
)

foreach ($Name in $Files) {
    $Path = Join-Path $DatabaseDir $Name
    if (-not (Test-Path $Path)) {
        throw "Missing SQL file: $Name"
    }
    Write-Host "Executing $Name"
    & $Sqlcmd -S $Server -E -C -f 65001 -b -i $Path
    if ($LASTEXITCODE -ne 0) {
        throw "sqlcmd failed on $Name"
    }
}

$CheckSql = @"
USE [$Database];
DECLARE @json NVARCHAR(MAX);
EXEC dbo.usp_Export_DaGo_Runtime_Bundle
    @project_code = N'DAGO',
    @team_code = N'DAGO-T01',
    @session_code = N'DC10-XIAOCHENG-001';

SELECT
    'dago_sql_validation' AS check_name,
    (SELECT COUNT(*) FROM dbo.Game_Passage WHERE passage_code IS NOT NULL) AS passage_count,
    (SELECT COUNT(*) FROM dbo.Game_Choice WHERE choice_code IS NOT NULL) AS choice_count,
    (SELECT COUNT(*) FROM dbo.DaGo_Authoring_Scenario_Location WHERE scenario_code = N'xiaocheng_jiushi' AND is_active = 1) AS active_location_count;
"@

$Temp = Join-Path $env:TEMP "dago_runtime_validation.sql"
Set-Content -Path $Temp -Value $CheckSql -Encoding UTF8
& $Sqlcmd -S $Server -E -C -f 65001 -b -i $Temp
if ($LASTEXITCODE -ne 0) {
    throw "runtime bundle validation failed"
}
Write-Host "DaGo SQL validation completed."
