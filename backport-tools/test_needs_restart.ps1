# After a "send to test" copy: does the update need a fresh game start, or is /reload enough?
# WoW 3.3.5 reads TOCs and the addon file list only at client start, so a restart is needed
# when an addon folder or file is new, or a TOC changed outside its version/release lines.
# Exit 1 = restart needed (then the saved variables reset applies), 0 = /reload is enough.
param([Parameter(Mandatory)][string]$Backup)
$test = 'D:\Jogo\Whitemane\Games\FrostmourneRebuffed\Interface\AddOns'
$project = Split-Path $PSScriptRoot -Parent
if (-not [IO.Path]::IsPathRooted($Backup)) { $Backup = Join-Path $project $Backup }
$Backup = (Resolve-Path -LiteralPath $Backup).Path
$Folders = @(Get-ChildItem -LiteralPath $project -Directory -Filter 'EllesmereUI*' | ForEach-Object Name) + 'EUIStandaloneDamageMeters'
$reasons = @()
function TocBody($path) {
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    (Get-Content -LiteralPath $path | Where-Object { $_ -notmatch '^\s*## (Version|X-EUI-Release):' } | ForEach-Object { $_.TrimEnd() }) -join "`n"
}
foreach ($name in $Folders) {
    $old = Join-Path $Backup $name; $new = Join-Path $test $name
    if (-not (Test-Path -LiteralPath $new)) { continue }
    if (-not (Test-Path -LiteralPath $old)) { $reasons += "new addon $name"; continue }
    $oldFiles = @{}
    Get-ChildItem -LiteralPath $old -Recurse -File | ForEach-Object { $oldFiles[$_.FullName.Substring($old.Length).ToLowerInvariant()] = $true }
    Get-ChildItem -LiteralPath $new -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($new.Length)
        if (-not $oldFiles.ContainsKey($rel.ToLowerInvariant())) { $reasons += "new file $name$rel" }
    }
    Get-ChildItem -LiteralPath $new -File -Filter '*.toc' | ForEach-Object {
        if ((TocBody $_.FullName) -ne (TocBody (Join-Path $old $_.Name))) { $reasons += "TOC changed $name\$($_.Name)" }
    }
}
if ($reasons.Count) {
    Write-Output "RESTART NEEDED ($($reasons.Count)):"; $reasons | Select-Object -First 15 | ForEach-Object { "  $_" }
    if ($reasons.Count -gt 15) { "  ..." }
    exit 1
}
Write-Output 'RELOAD IS ENOUGH: no new files or TOC changes.'; exit 0
