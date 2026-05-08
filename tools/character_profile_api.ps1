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

function Invoke-CharacterExport {
    param([int]$CharacterId)

    $connection = New-DbConnection
    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandText = "EXEC dbo.usp_Get_Character_Profile_Export @character_id = @character_id;"
        [void](Add-DbParameter -Command $command -Name "@character_id" -Type ([System.Data.SqlDbType]::Int) -Value $CharacterId)
        $result = $command.ExecuteScalar()
        if ($null -eq $result -or $result -is [DBNull]) {
            throw "No character export was returned."
        }
        return [string]$result
    }
    finally {
        $connection.Dispose()
    }
}

function Invoke-TeamStoryExport {
    param([int]$TeamId)

    $connection = New-DbConnection
    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandText = "EXEC dbo.usp_Get_Team_Story_Export @team_id = @team_id;"
        [void](Add-DbParameter -Command $command -Name "@team_id" -Type ([System.Data.SqlDbType]::Int) -Value $TeamId)
        $result = $command.ExecuteScalar()
        if ($null -eq $result -or $result -is [DBNull]) {
            throw "No team story export was returned."
        }
        return [string]$result
    }
    finally {
        $connection.Dispose()
    }
}

function Invoke-CreateCharacter {
    param([object]$Payload)

    $connection = New-DbConnection
    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandText = @"
EXEC dbo.usp_Create_Player_Character_From_Web
    @team_member_id = @team_member_id,
    @team_code = @team_code,
    @member_code = @member_code,
    @character_code = @character_code,
    @character_name = @character_name,
    @character_type = @character_type,
    @archetype = @archetype,
    @race_or_species = @race_or_species,
    @class_or_profession = @class_or_profession,
    @faction = @faction,
    @background_story_raw = @background_story_raw,
    @personality_note = @personality_note,
    @motivation_note = @motivation_note,
    @relationship_note = @relationship_note,
    @ability_note = @ability_note,
    @item_note = @item_note,
    @narrative_function = @narrative_function;
"@
        $teamMemberId = $null
        if ($null -ne $Payload.team_member_id -and -not [string]::IsNullOrWhiteSpace([string]$Payload.team_member_id)) {
            $teamMemberId = [int]$Payload.team_member_id
        }

        [void](Add-DbParameter -Command $command -Name "@team_member_id" -Type ([System.Data.SqlDbType]::Int) -Value $teamMemberId)
        [void](Add-DbParameter -Command $command -Name "@team_code" -Type ([System.Data.SqlDbType]::NVarChar) -Size 50 -Value $Payload.team_code)
        [void](Add-DbParameter -Command $command -Name "@member_code" -Type ([System.Data.SqlDbType]::NVarChar) -Size 50 -Value $Payload.member_code)
        [void](Add-DbParameter -Command $command -Name "@character_code" -Type ([System.Data.SqlDbType]::NVarChar) -Size 50 -Value $Payload.character_code)
        [void](Add-DbParameter -Command $command -Name "@character_name" -Type ([System.Data.SqlDbType]::NVarChar) -Size 100 -Value $Payload.character_name)
        [void](Add-DbParameter -Command $command -Name "@character_type" -Type ([System.Data.SqlDbType]::NVarChar) -Size 50 -Value $Payload.character_type)
        [void](Add-DbParameter -Command $command -Name "@archetype" -Type ([System.Data.SqlDbType]::NVarChar) -Size 100 -Value $Payload.archetype)
        [void](Add-DbParameter -Command $command -Name "@race_or_species" -Type ([System.Data.SqlDbType]::NVarChar) -Size 100 -Value $Payload.race_or_species)
        [void](Add-DbParameter -Command $command -Name "@class_or_profession" -Type ([System.Data.SqlDbType]::NVarChar) -Size 100 -Value $Payload.class_or_profession)
        [void](Add-DbParameter -Command $command -Name "@faction" -Type ([System.Data.SqlDbType]::NVarChar) -Size 100 -Value $Payload.faction)
        [void](Add-DbParameter -Command $command -Name "@background_story_raw" -Type ([System.Data.SqlDbType]::NVarChar) -Size -1 -Value $Payload.background_story_raw)
        [void](Add-DbParameter -Command $command -Name "@personality_note" -Type ([System.Data.SqlDbType]::NVarChar) -Size -1 -Value $Payload.personality_note)
        [void](Add-DbParameter -Command $command -Name "@motivation_note" -Type ([System.Data.SqlDbType]::NVarChar) -Size -1 -Value $Payload.motivation_note)
        [void](Add-DbParameter -Command $command -Name "@relationship_note" -Type ([System.Data.SqlDbType]::NVarChar) -Size -1 -Value $Payload.relationship_note)
        [void](Add-DbParameter -Command $command -Name "@ability_note" -Type ([System.Data.SqlDbType]::NVarChar) -Size -1 -Value $Payload.ability_note)
        [void](Add-DbParameter -Command $command -Name "@item_note" -Type ([System.Data.SqlDbType]::NVarChar) -Size -1 -Value $Payload.item_note)
        [void](Add-DbParameter -Command $command -Name "@narrative_function" -Type ([System.Data.SqlDbType]::NVarChar) -Size 100 -Value $Payload.narrative_function)

        $result = $command.ExecuteScalar()
        if ($null -eq $result -or $result -is [DBNull]) {
            throw "No character creation result was returned."
        }
        return [string]$result
    }
    finally {
        $connection.Dispose()
    }
}

function Invoke-SaveImageSlot {
    param
    (
        [int]$CharacterId,
        [string]$Slot,
        [object]$Image
    )

    $connection = New-DbConnection
    try {
        $connection.Open()
        $command = $connection.CreateCommand()

        if ($null -eq $Image -or [string]::IsNullOrWhiteSpace([string]$Image.data_url)) {
            $command.CommandText = "EXEC dbo.usp_Clear_Character_Profile_Image @character_id = @character_id, @image_slot = @image_slot;"
            [void](Add-DbParameter -Command $command -Name "@character_id" -Type ([System.Data.SqlDbType]::Int) -Value $CharacterId)
            [void](Add-DbParameter -Command $command -Name "@image_slot" -Type ([System.Data.SqlDbType]::NVarChar) -Size 50 -Value $Slot)
            [void]$command.ExecuteNonQuery()
            return
        }

        $command.CommandText = @"
EXEC dbo.usp_Save_Character_Profile_Image
    @character_id = @character_id,
    @image_slot = @image_slot,
    @image_file_name = @image_file_name,
    @image_mime_type = @image_mime_type,
    @image_size_bytes = @image_size_bytes,
    @image_data_url = @image_data_url,
    @image_alt_text = @image_alt_text,
    @image_note = @image_note;
"@
        [void](Add-DbParameter -Command $command -Name "@character_id" -Type ([System.Data.SqlDbType]::Int) -Value $CharacterId)
        [void](Add-DbParameter -Command $command -Name "@image_slot" -Type ([System.Data.SqlDbType]::NVarChar) -Size 50 -Value $Slot)
        [void](Add-DbParameter -Command $command -Name "@image_file_name" -Type ([System.Data.SqlDbType]::NVarChar) -Size 260 -Value $Image.file_name)
        [void](Add-DbParameter -Command $command -Name "@image_mime_type" -Type ([System.Data.SqlDbType]::NVarChar) -Size 100 -Value $Image.mime_type)
        [void](Add-DbParameter -Command $command -Name "@image_size_bytes" -Type ([System.Data.SqlDbType]::Int) -Value $Image.size_bytes)
        [void](Add-DbParameter -Command $command -Name "@image_data_url" -Type ([System.Data.SqlDbType]::NVarChar) -Size -1 -Value $Image.data_url)
        [void](Add-DbParameter -Command $command -Name "@image_alt_text" -Type ([System.Data.SqlDbType]::NVarChar) -Size 200 -Value $Image.alt_text)
        [void](Add-DbParameter -Command $command -Name "@image_note" -Type ([System.Data.SqlDbType]::NVarChar) -Size -1 -Value $Image.note)
        [void]$command.ExecuteNonQuery()
    }
    finally {
        $connection.Dispose()
    }
}

function Invoke-SaveFreeformFields {
    param
    (
        [int]$CharacterId,
        [object[]]$Fields
    )

    $json = ConvertTo-Json -InputObject @($Fields) -Depth 8 -Compress
    $connection = New-DbConnection
    try {
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandText = "EXEC dbo.usp_Save_Character_Freeform_Fields @character_id = @character_id, @fields_json = @fields_json;"
        [void](Add-DbParameter -Command $command -Name "@character_id" -Type ([System.Data.SqlDbType]::Int) -Value $CharacterId)
        [void](Add-DbParameter -Command $command -Name "@fields_json" -Type ([System.Data.SqlDbType]::NVarChar) -Size -1 -Value $json)
        [void]$command.ExecuteNonQuery()
    }
    finally {
        $connection.Dispose()
    }
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
    $Response.Headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,OPTIONS"
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

    $json = ConvertTo-Json -InputObject $Object -Depth 10 -Compress
    Write-JsonResponse -Response $Response -StatusCode $StatusCode -Json $json
}

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add($Prefix)
$listener.Start()
Write-Host "Character profile API listening on $Prefix"
Write-Host "SQL Server: $Server / $Database"
Write-Host "Press Ctrl+C to stop."

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    $response.Headers["Access-Control-Allow-Origin"] = "*"
    $response.Headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,OPTIONS"
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

        if ($request.HttpMethod -eq "POST" -and $segments.Length -eq 2 -and $segments[0] -eq "api" -and $segments[1] -eq "characters") {
            $payload = Read-RequestJson -Request $request
            $json = Invoke-CreateCharacter -Payload $payload
            Write-JsonResponse -Response $response -StatusCode 201 -Json $json
            continue
        }

        if ($segments.Length -eq 4 -and $segments[0] -eq "api" -and $segments[1] -eq "characters") {
            $characterId = [int]$segments[2]
            $target = $segments[3]

            if ($request.HttpMethod -eq "GET" -and $target -eq "profile") {
                $json = Invoke-CharacterExport -CharacterId $characterId
                Write-JsonResponse -Response $response -StatusCode 200 -Json $json
                continue
            }

            if ($request.HttpMethod -eq "PUT" -and $target -eq "images") {
                $payload = Read-RequestJson -Request $request
                Invoke-SaveImageSlot -CharacterId $characterId -Slot "headshot" -Image $payload.headshot
                Invoke-SaveImageSlot -CharacterId $characterId -Slot "fullbody" -Image $payload.fullbody
                Write-ObjectResponse -Response $response -StatusCode 200 -Object @{ ok = $true }
                continue
            }

            if ($request.HttpMethod -eq "PUT" -and $target -eq "freeform-fields") {
                $payload = Read-RequestJson -Request $request
                Invoke-SaveFreeformFields -CharacterId $characterId -Fields @($payload.fields)
                Write-ObjectResponse -Response $response -StatusCode 200 -Object @{ ok = $true }
                continue
            }
        }

        if ($segments.Length -eq 4 -and $segments[0] -eq "api" -and $segments[1] -eq "teams") {
            $teamId = [int]$segments[2]
            $target = $segments[3]

            if ($request.HttpMethod -eq "GET" -and $target -eq "story") {
                $json = Invoke-TeamStoryExport -TeamId $teamId
                Write-JsonResponse -Response $response -StatusCode 200 -Json $json
                continue
            }
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
