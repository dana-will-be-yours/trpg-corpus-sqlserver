$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$pattern = '[vV]' + '13'
$activePaths = @(
  (Join-Path $Root "web"),
  (Join-Path $Root "tools"),
  (Join-Path $Root "docs"),
  (Join-Path $Root "index.html"),
  (Join-Path $Root "README.md")
)
$files = foreach ($path in $activePaths) {
  if (Test-Path $path -PathType Container) {
    Get-ChildItem $path -Recurse -File
  } elseif (Test-Path $path -PathType Leaf) {
    Get-Item $path
  }
}
$hits = @()
foreach ($f in $files) {
  if ($f.FullName -match $pattern) { $hits += [pscustomobject]@{ File=$f.FullName; Line=0; Text='legacy version token found in path' } }
  if ($f.Extension -in @('.js','.html','.md','.ps1','.py','.sql','.json','.txt','.css','.csv','.tsv')) {
    $m = Select-String -Path $f.FullName -Pattern $pattern -ErrorAction SilentlyContinue
    foreach ($x in $m) { $hits += [pscustomobject]@{ File=$x.Path; Line=$x.LineNumber; Text=$x.Line.Trim() } }
  }
}
if ($hits.Count -gt 0) {
  $hits | Format-Table -AutoSize
  throw "v1.4 static reference check failed: legacy version tokens remain."
}
Write-Host "v1.4 static reference check passed: no legacy version tokens found."
