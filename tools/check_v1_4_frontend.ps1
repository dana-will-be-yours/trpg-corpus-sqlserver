param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
$errors = New-Object System.Collections.Generic.List[string]
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
    $matches = [regex]::Matches($html, '<script\s+src="([^"]+)"')
    if ($matches.Count -eq 0) {
        $errors.Add("No script src found in $relative")
        continue
    }

    foreach ($m in $matches) {
        $src = $m.Groups[1].Value
        $srcPath = ($src -replace '\?.*$','')

        if ($srcPath -match 'archive/') {
            $errors.Add("$relative loads archived asset: $src")
        }

        if ($srcPath -match 'dago-corpus-.+-v(\d+)\.js$') {
            $ver = [int]$Matches[1]
            if ($ver -lt 13) {
                $errors.Add("$relative loads legacy v$ver asset: $src")
            }
        }

        if ($srcPath -match 'dago-corpus-input-v\d+\.js$') {
            $errors.Add("$relative must not load legacy monolithic input asset: $src")
        }

        $assetPath = Join-Path (Split-Path $path -Parent) $srcPath
        if (-not (Test-Path $assetPath)) {
            $errors.Add("$relative references missing script: $src")
        }
    }

    $firstScript = $matches[0].Groups[1].Value -replace '\?.*$',''
    if ($firstScript -ne 'assets/dago-corpus-v1-4-core.js') {
        $errors.Add("$relative must load assets/dago-corpus-v1-4-core.js first; actual first script: $firstScript")
    }
}

if ($errors.Count -gt 0) {
    Write-Host 'v1.4 frontend static path check failed:' -ForegroundColor Red
    $errors | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'v1.4 frontend static path check passed.' -ForegroundColor Green
exit 0
