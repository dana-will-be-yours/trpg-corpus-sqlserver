param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
$ExpectedVersion = '2026-05-17 mapping-io-validation-selftest'
$ExpectedQuery = '20260517-mapping-io-validation-selftest'
$errors = New-Object System.Collections.Generic.List[string]

$corePath = Join-Path $Root 'web/assets/dago-corpus-v13-core.js'
if (-not (Test-Path $corePath)) {
    $errors.Add('Missing web/assets/dago-corpus-v13-core.js')
} else {
    $core = Get-Content $corePath -Raw -Encoding UTF8
    if ($core -notmatch [regex]::Escape($ExpectedVersion)) {
        $errors.Add('Core VERSION does not contain expected version string.')
    }
    foreach ($name in @('UTT_FIELDS','MAP_FIELDS','BATCH_FIELDS','SPEAKER_TYPES','UTTERANCE_FUNCTIONS','targetTableForSpeakerType')) {
        if ($core -notmatch $name) { $errors.Add("Core missing constant/function: $name") }
    }
}

$activeHtml = @(
    'web/dago-corpus-input.html',
    'web/dago-corpus-review.html'
)

foreach ($relative in $activeHtml) {
    $path = Join-Path $Root $relative
    if (-not (Test-Path $path)) {
        $errors.Add("Missing active HTML: $relative")
        continue
    }
    $html = Get-Content $path -Raw -Encoding UTF8
    if ($html -notmatch [regex]::Escape($ExpectedVersion)) {
        $errors.Add("$relative does not contain expected visible version string.")
    }
    $scripts = [regex]::Matches($html, '<script\s+src="([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
    foreach ($src in $scripts) {
        if ($src -notmatch [regex]::Escape($ExpectedQuery)) {
            $errors.Add("$relative script missing expected query version: $src")
        }
        if ($src -match 'v(\d+)') {
            $ver = [int]$Matches[1]
            if ($ver -lt 13) { $errors.Add("$relative references legacy version in script: $src") }
        }
        if ($src -match 'archive/') {
            $errors.Add("$relative references archive script: $src")
        }
    }
    foreach ($requiredScript in @(
        'assets/dago-corpus-v13-core.js',
        'assets/dago-corpus-workspace-v13.js',
        'assets/dago-corpus-workspace-ops-v13.js',
        'assets/dago-corpus-xlsx-core-v13.js',
        'assets/dago-corpus-mapping-io-v13.js',
        'assets/dago-corpus-export-v13.js',
        'assets/dago-corpus-mapping-validation-v13.js',
        'assets/dago-corpus-v13-selftest.js'
    )) {
        if ($html -notmatch [regex]::Escape($requiredScript)) {
            $errors.Add("$relative missing required script: $requiredScript")
        }
    }
}

$docPath = Join-Path $Root 'docs/dago_corpus_input_v13_工作手冊.md'
if (-not (Test-Path $docPath)) {
    $errors.Add('Missing docs/dago_corpus_input_v13_工作手冊.md')
} else {
    $doc = Get-Content $docPath -Raw -Encoding UTF8
    if ($doc -match 'web/v13-preview') {
        $errors.Add('v13 docs still reference non-existent web/v13-preview path.')
    }
    foreach ($required in @(
        'web/assets/dago-corpus-v13-core.js',
        'web/assets/dago-corpus-workspace-v13.js',
        'web/assets/dago-corpus-xlsx-core-v13.js',
        'web/assets/dago-corpus-mapping-io-v13.js',
        'web/assets/dago-corpus-export-v13.js',
        'web/assets/dago-corpus-large-import-v13.js',
        'web/assets/dago-corpus-mapping-validation-v13.js',
        'web/assets/dago-corpus-v13-selftest.js',
        'OBS_MISMATCH',
        'Speaker_Mapping',
        '2026-05-17 mapping-io-validation-selftest'
    )) {
        if ($doc -notmatch [regex]::Escape($required)) {
            $errors.Add("v13 docs missing required text: $required")
        }
    }
}

if ($errors.Count -gt 0) {
    Write-Host 'v13 static reference check failed:' -ForegroundColor Red
    $errors | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'v13 static reference check passed.' -ForegroundColor Green
exit 0
