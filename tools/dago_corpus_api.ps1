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

        if ($request.HttpMethod -eq "POST" -and $segments.Length -eq 2 -and $segments[0] -eq "api" -and $segments[1] -eq "dago-playlogs") {
            $payload = Read-RequestJson -Request $request
            $result = Invoke-SavePlayLog -Payload $payload
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
