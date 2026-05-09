param
(
    [string]$Prefix = "http://localhost:8787/",
    [string]$Server = ".\SQLEXPRESS",
    [string]$Database = "TRPG_Corpus_DB"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function New-DbConnection {
    $connectionString = "Server=$Server;Database=$Database;Integrated Security=True;Encrypt=True;TrustServerCertificate=True"
    return [System.Data.SqlClient.SqlConnection]::new($connectionString)
}

function Add-DbParameter {
    param
    (
        [System.Data.SqlClient.SqlCommand]$Command,
        [string]$Name,
        [System.Data.SqlDbType]$Type,
        [object]$Value,
        [int]$Size = 0
    )

    if ($Size -ne 0) {
        $parameter = $Command.Parameters.Add($Name, $Type, $Size)
    }
    else {
        $parameter = $Command.Parameters.Add($Name, $Type)
    }

    if ($null -eq $Value) {
        $parameter.Value = [DBNull]::Value
    }
    else {
        $parameter.Value = $Value
    }

    return $parameter
}

function ConvertFrom-QueryString {
    param([string]$Query)

    $result = @{}
    if ([string]::IsNullOrWhiteSpace($Query)) {
        return $result
    }

    $pairs = $Query.TrimStart("?").Split([char[]]@("&"), [System.StringSplitOptions]::RemoveEmptyEntries)
    foreach ($pair in $pairs) {
        $parts = $pair.Split([char[]]@("="), 2)
        $name = [System.Uri]::UnescapeDataString($parts[0])
        $value = ""
        if ($parts.Length -gt 1) {
            $value = [System.Uri]::UnescapeDataString($parts[1])
        }
        $result[$name] = $value
    }
    return $result
}

function Read-RequestJson {
    param([System.Net.HttpListenerRequest]$Request)

    $reader = [System.IO.StreamReader]::new($Request.InputStream, $Request.ContentEncoding)
    try {
        $body = $reader.ReadToEnd()
        if ([string]::IsNullOrWhiteSpace($body)) {
            return $null
        }
        return $body | ConvertFrom-Json
    }
    finally {
        $reader.Dispose()
    }
}

function Get-JsonProperty {
    param
    (
        [object]$Object,
        [string]$Name
    )

    if ($null -eq $Object) {
        return $null
    }

    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}

function Get-FirstTextValue {
    param([object[]]$Values)

    foreach ($value in $Values) {
        if ($null -ne $value -and -not [string]::IsNullOrWhiteSpace([string]$value)) {
            return [string]$value
        }
    }
    return $null
}

function Convert-ToBooleanValue {
    param([object]$Value, [bool]$DefaultValue = $true)

    if ($null -eq $Value) {
        return $DefaultValue
    }
    if ($Value -is [bool]) {
        return [bool]$Value
    }
    $text = ([string]$Value).Trim().ToLowerInvariant()
    if ($text -in @("0", "false", "no", "off")) {
        return $false
    }
    if ($text -in @("1", "true", "yes", "on")) {
        return $true
    }
    return $DefaultValue
}

function Write-JsonResponse {
    param
    (
        [System.Net.HttpListenerResponse]$Response,
        [int]$StatusCode,
        [string]$Json
    )

    $Response.StatusCode = $StatusCode
    $Response.ContentType = "application/json; charset=utf-8"
    $Response.Headers["Access-Control-Allow-Origin"] = "*"
    $Response.Headers["Access-Control-Allow-Methods"] = "GET,POST,OPTIONS"
    $Response.Headers["Access-Control-Allow-Headers"] = "Content-Type"

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Json)
    $Response.ContentLength64 = $bytes.Length
    $Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $Response.Close()
}

function Write-ObjectResponse {
    param
    (
        [System.Net.HttpListenerResponse]$Response,
        [int]$StatusCode,
        [object]$Object
    )

    $json = ConvertTo-Json -InputObject $Object -Depth 12 -Compress
    Write-JsonResponse -Response $Response -StatusCode $StatusCode -Json $json
}

function Invoke-WorldManifest {
    param
    (
        [string]$ProjectCode,
        [string]$TeamCode,
        [string]$SessionCode
    )

    $connection = New-DbConnection
    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandText = "EXEC dbo.usp_Export_DaGo_World_Manifest @project_code = @project_code, @team_code = @team_code, @session_code = @session_code;"
        [void](Add-DbParameter -Command $command -Name "@project_code" -Type ([System.Data.SqlDbType]::NVarChar) -Size 50 -Value $ProjectCode)
        [void](Add-DbParameter -Command $command -Name "@team_code" -Type ([System.Data.SqlDbType]::NVarChar) -Size 50 -Value $TeamCode)
        $sessionCodeValue = $null
        if (-not [string]::IsNullOrWhiteSpace($SessionCode)) {
            $sessionCodeValue = $SessionCode
        }
        [void](Add-DbParameter -Command $command -Name "@session_code" -Type ([System.Data.SqlDbType]::NVarChar) -Size 50 -Value $sessionCodeValue)
        $result = $command.ExecuteScalar()
        if ($null -eq $result -or $result -is [DBNull]) {
            throw "No world manifest was returned."
        }
        return [string]$result
    }
    finally {
        $connection.Dispose()
    }
}

function Invoke-RuntimeBundle {
    param
    (
        [string]$ProjectCode,
        [string]$TeamCode,
        [string]$SessionCode
    )

    $connection = New-DbConnection
    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandText = "EXEC dbo.usp_Export_DaGo_Runtime_Bundle @project_code = @project_code, @team_code = @team_code, @session_code = @session_code;"
        [void](Add-DbParameter -Command $command -Name "@project_code" -Type ([System.Data.SqlDbType]::NVarChar) -Size 50 -Value $ProjectCode)
        [void](Add-DbParameter -Command $command -Name "@team_code" -Type ([System.Data.SqlDbType]::NVarChar) -Size 50 -Value $TeamCode)
        $sessionCodeValue = $null
        if (-not [string]::IsNullOrWhiteSpace($SessionCode)) {
            $sessionCodeValue = $SessionCode
        }
        [void](Add-DbParameter -Command $command -Name "@session_code" -Type ([System.Data.SqlDbType]::NVarChar) -Size 50 -Value $sessionCodeValue)
        $result = $command.ExecuteScalar()
        if ($null -eq $result -or $result -is [DBNull]) {
            throw "No runtime bundle was returned."
        }
        return [string]$result
    }
    finally {
        $connection.Dispose()
    }
}

function Invoke-AuthoringReference {
    $connection = New-DbConnection
    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandText = @"
SELECT
    rule_type,
    code,
    display_name,
    rule_json,
    sort_order
FROM dbo.vw_DaGo_Nanjing_V5_Authoring_Rules
ORDER BY rule_type, sort_order, code;

SELECT
    row_type,
    code,
    display_name,
    payload_json,
    sort_order
FROM dbo.vw_DaGo_Nanjing_V5_World_Bundle_Rows
ORDER BY row_type, sort_order, code;

SELECT TOP (100)
    source_document_code,
    source_title,
    source_document_type,
    file_name,
    import_status
FROM stg.Source_Document_Import
ORDER BY created_at DESC, source_document_import_id DESC;
"@
        $reader = $command.ExecuteReader()
        $rules = @()
        while ($reader.Read()) {
            $rules += @{
                type = [string]$reader["rule_type"]
                code = [string]$reader["code"]
                name = [string]$reader["display_name"]
                json = [string]$reader["rule_json"]
                sort_order = [int]$reader["sort_order"]
            }
        }

        [void]$reader.NextResult()
        $world = @()
        while ($reader.Read()) {
            $world += @{
                type = [string]$reader["row_type"]
                code = [string]$reader["code"]
                name = [string]$reader["display_name"]
                json = [string]$reader["payload_json"]
                sort_order = [int]$reader["sort_order"]
            }
        }

        [void]$reader.NextResult()
        $documents = @()
        while ($reader.Read()) {
            $documents += @{
                source_document_code = [string]$reader["source_document_code"]
                title = [string]$reader["source_title"]
                type = [string]$reader["source_document_type"]
                file_name = [string]$reader["file_name"]
                review_status = [string]$reader["import_status"]
            }
        }
        $reader.Dispose()

        return @{
            metadata = @{
                reference_format = "dago_authoring_reference_from_sql_v1"
                target_database = $Database
                exported_at = (Get-Date).ToString("o")
            }
            rules = $rules
            world = $world
            source_documents = $documents
        }
    }
    finally {
        $connection.Dispose()
    }
}

function Invoke-SavePlayLog {
    param([object]$Payload)

    $playlog = $Payload
    $payloadPlaylog = Get-JsonProperty -Object $Payload -Name "playlog_json"
    if ($null -ne $payloadPlaylog) {
        $playlog = $payloadPlaylog
    }

    $playlogJson = ConvertTo-Json -InputObject $playlog -Depth 60 -Compress
    $playlogCode = Get-JsonProperty -Object $Payload -Name "playlog_code"
    if ([string]::IsNullOrWhiteSpace([string]$playlogCode)) {
        $metadata = Get-JsonProperty -Object $playlog -Name "metadata"
        $sessionCode = Get-JsonProperty -Object $metadata -Name "session_code"
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $playlogCode = "DAGO_$($sessionCode)_$timestamp"
    }
    $playlogMetadata = Get-JsonProperty -Object $playlog -Name "metadata"

    $connection = New-DbConnection
    try {
        $connection.Open()
        $transaction = $connection.BeginTransaction()
        try {
            $command = $connection.CreateCommand()
            $command.Transaction = $transaction
            $command.CommandText = @"
INSERT INTO stg.DaGo_PlayLog_Import
(
    playlog_code,
    project_code,
    team_code,
    session_code,
    source_file_name,
    playlog_json
)
VALUES
(
    @playlog_code,
    @project_code,
    @team_code,
    @session_code,
    @source_file_name,
    @playlog_json
);
"@
            [void](Add-DbParameter -Command $command -Name "@playlog_code" -Type ([System.Data.SqlDbType]::NVarChar) -Size 100 -Value $playlogCode)
            [void](Add-DbParameter -Command $command -Name "@project_code" -Type ([System.Data.SqlDbType]::NVarChar) -Size 50 -Value (Get-JsonProperty -Object $playlogMetadata -Name "project_code"))
            [void](Add-DbParameter -Command $command -Name "@team_code" -Type ([System.Data.SqlDbType]::NVarChar) -Size 50 -Value (Get-JsonProperty -Object $playlogMetadata -Name "team_code"))
            [void](Add-DbParameter -Command $command -Name "@session_code" -Type ([System.Data.SqlDbType]::NVarChar) -Size 50 -Value (Get-JsonProperty -Object $playlogMetadata -Name "session_code"))
            [void](Add-DbParameter -Command $command -Name "@source_file_name" -Type ([System.Data.SqlDbType]::NVarChar) -Size 260 -Value "da_go_playlog.json")
            [void](Add-DbParameter -Command $command -Name "@playlog_json" -Type ([System.Data.SqlDbType]::NVarChar) -Size -1 -Value $playlogJson)
            [void]$command.ExecuteNonQuery()

            $validate = $connection.CreateCommand()
            $validate.Transaction = $transaction
            $validate.CommandText = "EXEC stg.usp_Validate_DaGo_PlayLog_Import @playlog_code = @playlog_code;"
            [void](Add-DbParameter -Command $validate -Name "@playlog_code" -Type ([System.Data.SqlDbType]::NVarChar) -Size 100 -Value $playlogCode)
            $reader = $validate.ExecuteReader()
            $result = @{}
            if ($reader.Read()) {
                for ($i = 0; $i -lt $reader.FieldCount; $i += 1) {
                    $result[$reader.GetName($i)] = $reader.GetValue($i)
                }
            }
            $reader.Dispose()
            $transaction.Commit()
            return $result
        }
        catch {
            $transaction.Rollback()
            throw
        }
    }
    finally {
        $connection.Dispose()
    }
}

function Invoke-ImportGameRun {
    param([object]$Payload)

    $gameRun = Get-JsonProperty -Object $Payload -Name "source_json"
    if ($null -eq $gameRun) {
        $gameRun = Get-JsonProperty -Object $Payload -Name "game_run_json"
    }
    if ($null -eq $gameRun) {
        $gameRun = Get-JsonProperty -Object $Payload -Name "playlog_json"
    }
    if ($null -eq $gameRun) {
        $gameRun = $Payload
    }

    if ($gameRun -is [string]) {
        $sourceJson = [string]$gameRun
    }
    else {
        $sourceJson = ConvertTo-Json -InputObject $gameRun -Depth 80 -Compress
    }

    $importedBy = Get-FirstTextValue @((Get-JsonProperty -Object $Payload -Name "imported_by"), "api")
    $sourceFileName = Get-FirstTextValue @((Get-JsonProperty -Object $Payload -Name "source_file_name"), "da_go_playlog.json")

    $connection = New-DbConnection
    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandText = "EXEC stg.usp_Load_DaGo_Game_Run_Json_To_Staging @source_json = @source_json, @imported_by = @imported_by, @source_file_name = @source_file_name;"
        [void](Add-DbParameter -Command $command -Name "@source_json" -Type ([System.Data.SqlDbType]::NVarChar) -Size -1 -Value $sourceJson)
        [void](Add-DbParameter -Command $command -Name "@imported_by" -Type ([System.Data.SqlDbType]::NVarChar) -Size 100 -Value $importedBy)
        [void](Add-DbParameter -Command $command -Name "@source_file_name" -Type ([System.Data.SqlDbType]::NVarChar) -Size 260 -Value $sourceFileName)
        $reader = $command.ExecuteReader()
        $rows = @()
        do {
            while ($reader.Read()) {
                $row = @{}
                for ($i = 0; $i -lt $reader.FieldCount; $i += 1) {
                    $row[$reader.GetName($i)] = $reader.GetValue($i)
                }
                $rows += $row
            }
        } while ($reader.NextResult())
        $reader.Dispose()
        return @{
            ok = $true
            source_file_name = $sourceFileName
            validation = $rows
        }
    }
    finally {
        $connection.Dispose()
    }
}

function Invoke-SaveResearcherStory {
    param([object]$Payload)

    $story = $Payload
    $payloadStory = Get-JsonProperty -Object $Payload -Name "story_json"
    if ($null -ne $payloadStory) {
        $story = $payloadStory
    }

    $storyJson = ConvertTo-Json -InputObject $story -Depth 80 -Compress
    $metadata = Get-JsonProperty -Object $story -Name "metadata"
    $config = Get-JsonProperty -Object $story -Name "config"

    $storyCode = Get-FirstTextValue @(
        (Get-JsonProperty -Object $Payload -Name "story_code"),
        (Get-JsonProperty -Object $story -Name "story_code")
    )
    if ([string]::IsNullOrWhiteSpace($storyCode)) {
        $sessionCode = Get-FirstTextValue @(
            (Get-JsonProperty -Object $metadata -Name "session_code"),
            (Get-JsonProperty -Object $config -Name "session_code")
        )
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $storyCode = "DAGO_STORY_$($sessionCode)_$timestamp"
    }

    $projectCode = Get-FirstTextValue @(
        (Get-JsonProperty -Object $Payload -Name "project_code"),
        (Get-JsonProperty -Object $metadata -Name "project_code"),
        (Get-JsonProperty -Object $config -Name "project_code"),
        (Get-JsonProperty -Object $story -Name "project_code")
    )
    $teamCode = Get-FirstTextValue @(
        (Get-JsonProperty -Object $Payload -Name "team_code"),
        (Get-JsonProperty -Object $metadata -Name "team_code"),
        (Get-JsonProperty -Object $config -Name "team_code"),
        (Get-JsonProperty -Object $story -Name "team_code")
    )
    $sessionCode = Get-FirstTextValue @(
        (Get-JsonProperty -Object $Payload -Name "session_code"),
        (Get-JsonProperty -Object $metadata -Name "session_code"),
        (Get-JsonProperty -Object $config -Name "session_code"),
        (Get-JsonProperty -Object $story -Name "session_code")
    )
    $autoLoad = Convert-ToBooleanValue -Value (Get-FirstTextValue @(
        (Get-JsonProperty -Object $Payload -Name "auto_load"),
        (Get-JsonProperty -Object $story -Name "auto_load")
    )) -DefaultValue $true

    $validation = @{}
    $connection = New-DbConnection
    try {
        $connection.Open()
        $transaction = $connection.BeginTransaction()
        try {
            $command = $connection.CreateCommand()
            $command.Transaction = $transaction
            $command.CommandText = @"
MERGE stg.DaGo_Researcher_Story_Import AS target
USING (
    SELECT
        @story_code AS story_code,
        @project_code AS project_code,
        @team_code AS team_code,
        @session_code AS session_code,
        @source_file_name AS source_file_name,
        @story_json AS story_json,
        @auto_load AS auto_load
) AS source
ON target.story_code = source.story_code
WHEN MATCHED THEN
    UPDATE SET
        project_code = source.project_code,
        team_code = source.team_code,
        session_code = source.session_code,
        source_file_name = source.source_file_name,
        story_json = source.story_json,
        auto_load = source.auto_load,
        validation_status = N'raw',
        validation_message = NULL,
        import_status = N'raw',
        loaded_at = NULL
WHEN NOT MATCHED THEN
    INSERT
    (
        story_code,
        project_code,
        team_code,
        session_code,
        source_file_name,
        story_json,
        auto_load
    )
    VALUES
    (
        source.story_code,
        source.project_code,
        source.team_code,
        source.session_code,
        source.source_file_name,
        source.story_json,
        source.auto_load
    );
"@
            [void](Add-DbParameter -Command $command -Name "@story_code" -Type ([System.Data.SqlDbType]::NVarChar) -Size 100 -Value $storyCode)
            [void](Add-DbParameter -Command $command -Name "@project_code" -Type ([System.Data.SqlDbType]::NVarChar) -Size 50 -Value $projectCode)
            [void](Add-DbParameter -Command $command -Name "@team_code" -Type ([System.Data.SqlDbType]::NVarChar) -Size 50 -Value $teamCode)
            [void](Add-DbParameter -Command $command -Name "@session_code" -Type ([System.Data.SqlDbType]::NVarChar) -Size 50 -Value $sessionCode)
            [void](Add-DbParameter -Command $command -Name "@source_file_name" -Type ([System.Data.SqlDbType]::NVarChar) -Size 260 -Value "da_go_researcher_story.json")
            [void](Add-DbParameter -Command $command -Name "@story_json" -Type ([System.Data.SqlDbType]::NVarChar) -Size -1 -Value $storyJson)
            [void](Add-DbParameter -Command $command -Name "@auto_load" -Type ([System.Data.SqlDbType]::Bit) -Value $autoLoad)
            [void]$command.ExecuteNonQuery()

            $validate = $connection.CreateCommand()
            $validate.Transaction = $transaction
            $validate.CommandText = "EXEC stg.usp_Validate_DaGo_Researcher_Story_Import @story_code = @story_code;"
            [void](Add-DbParameter -Command $validate -Name "@story_code" -Type ([System.Data.SqlDbType]::NVarChar) -Size 100 -Value $storyCode)
            $reader = $validate.ExecuteReader()
            if ($reader.Read()) {
                for ($i = 0; $i -lt $reader.FieldCount; $i += 1) {
                    $validation[$reader.GetName($i)] = $reader.GetValue($i)
                }
            }
            $reader.Dispose()

            $transaction.Commit()
        }
        catch {
            $transaction.Rollback()
            throw
        }
    }
    finally {
        $connection.Dispose()
    }

    $loadResult = $null
    $loadError = $null
    if ($autoLoad -and [string]$validation["validation_status"] -eq "valid") {
        $loadConnection = New-DbConnection
        try {
            $loadConnection.Open()
            $loadTransaction = $loadConnection.BeginTransaction()
            try {
                $load = $loadConnection.CreateCommand()
                $load.Transaction = $loadTransaction
                $load.CommandText = "EXEC stg.usp_Load_DaGo_Researcher_Story_To_Runtime @story_code = @story_code;"
                [void](Add-DbParameter -Command $load -Name "@story_code" -Type ([System.Data.SqlDbType]::NVarChar) -Size 100 -Value $storyCode)
                $reader = $load.ExecuteReader()
                $loadResult = @{}
                if ($reader.Read()) {
                    for ($i = 0; $i -lt $reader.FieldCount; $i += 1) {
                        $loadResult[$reader.GetName($i)] = $reader.GetValue($i)
                    }
                }
                $reader.Dispose()
                $loadTransaction.Commit()
            }
            catch {
                $loadTransaction.Rollback()
                throw
            }
        }
        catch {
            $loadError = $_.Exception.Message
        }
        finally {
            $loadConnection.Dispose()
        }
    }

    return @{
        story_code = $storyCode
        validation = $validation
        load = $loadResult
        load_error = $loadError
    }
}

function Invoke-LoadPlayLog {
    param([string]$PlaylogCode)

    $connection = New-DbConnection
    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandText = "EXEC stg.usp_Load_DaGo_PlayLog_To_Utterance_Import @playlog_code = @playlog_code;"
        [void](Add-DbParameter -Command $command -Name "@playlog_code" -Type ([System.Data.SqlDbType]::NVarChar) -Size 100 -Value $PlaylogCode)
        $reader = $command.ExecuteReader()
        $result = @{}
        if ($reader.Read()) {
            for ($i = 0; $i -lt $reader.FieldCount; $i += 1) {
                $result[$reader.GetName($i)] = $reader.GetValue($i)
            }
        }
        $reader.Dispose()
        return $result
    }
    finally {
        $connection.Dispose()
    }
}

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add($Prefix)
$listener.Start()
Write-Host "da_go corpus API listening on $Prefix"
Write-Host "SQL Server: $Server / $Database"
Write-Host "Press Ctrl+C to stop."

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    $response.Headers["Access-Control-Allow-Origin"] = "*"
    $response.Headers["Access-Control-Allow-Methods"] = "GET,POST,OPTIONS"
    $response.Headers["Access-Control-Allow-Headers"] = "Content-Type"

    try {
        if ($request.HttpMethod -eq "OPTIONS") {
            $response.StatusCode = 204
            $response.Close()
            continue
        }

        $segments = $request.Url.AbsolutePath.Trim("/").Split([char[]]@("/"), [System.StringSplitOptions]::RemoveEmptyEntries)

        if ($request.HttpMethod -eq "GET" -and $segments.Length -eq 2 -and $segments[0] -eq "api" -and $segments[1] -eq "health") {
            Write-ObjectResponse -Response $response -StatusCode 200 -Object @{
                ok = $true
                server = $Server
                database = $Database
            }
            continue
        }

        if ($request.HttpMethod -eq "GET" -and $segments.Length -eq 2 -and $segments[0] -eq "api" -and $segments[1] -eq "world-manifest") {
            $query = ConvertFrom-QueryString -Query $request.Url.Query
            $json = Invoke-WorldManifest -ProjectCode $query["project_code"] -TeamCode $query["team_code"] -SessionCode $query["session_code"]
            Write-JsonResponse -Response $response -StatusCode 200 -Json $json
            continue
        }

        if ($request.HttpMethod -eq "GET" -and $segments.Length -eq 2 -and $segments[0] -eq "api" -and $segments[1] -eq "runtime-bundle") {
            $query = ConvertFrom-QueryString -Query $request.Url.Query
            $json = Invoke-RuntimeBundle -ProjectCode $query["project_code"] -TeamCode $query["team_code"] -SessionCode $query["session_code"]
            Write-JsonResponse -Response $response -StatusCode 200 -Json $json
            continue
        }

        if ($request.HttpMethod -eq "GET" -and $segments.Length -eq 2 -and $segments[0] -eq "api" -and $segments[1] -eq "authoring-reference") {
            $result = Invoke-AuthoringReference
            Write-ObjectResponse -Response $response -StatusCode 200 -Object $result
            continue
        }

        if ($request.HttpMethod -eq "POST" -and $segments.Length -eq 2 -and $segments[0] -eq "api" -and $segments[1] -eq "dago-playlogs") {
            $payload = Read-RequestJson -Request $request
            $result = Invoke-SavePlayLog -Payload $payload
            Write-ObjectResponse -Response $response -StatusCode 201 -Object $result
            continue
        }

        if ($request.HttpMethod -eq "POST" -and $segments.Length -eq 2 -and $segments[0] -eq "api" -and $segments[1] -eq "dago-game-runs") {
            $payload = Read-RequestJson -Request $request
            $result = Invoke-ImportGameRun -Payload $payload
            Write-ObjectResponse -Response $response -StatusCode 201 -Object $result
            continue
        }

        if ($request.HttpMethod -eq "POST" -and $segments.Length -eq 2 -and $segments[0] -eq "api" -and $segments[1] -eq "researcher-stories") {
            $payload = Read-RequestJson -Request $request
            $result = Invoke-SaveResearcherStory -Payload $payload
            Write-ObjectResponse -Response $response -StatusCode 201 -Object $result
            continue
        }

        if ($request.HttpMethod -eq "POST" -and $segments.Length -eq 4 -and $segments[0] -eq "api" -and $segments[1] -eq "dago-playlogs" -and $segments[3] -eq "load") {
            $result = Invoke-LoadPlayLog -PlaylogCode $segments[2]
            Write-ObjectResponse -Response $response -StatusCode 200 -Object $result
            continue
        }

        Write-ObjectResponse -Response $response -StatusCode 404 -Object @{
            ok = $false
            error = "Route not found."
        }
    }
    catch {
        Write-ObjectResponse -Response $response -StatusCode 500 -Object @{
            ok = $false
            error = $_.Exception.Message
        }
    }
}
