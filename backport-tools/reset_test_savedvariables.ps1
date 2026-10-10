# Backs up, then deletes, the EllesmereUI saved variables (Ellesmere*/EUI*, .lua and .lua.bak)
# of Test account ALEXF10: account-wide and every realm/character. Refuses while Test WoW runs,
# because WoW rewrites saved variables from memory on /reload and logout.
param([string]$Account = 'ALEXF10')
$ErrorActionPreference = 'Stop'
$game = 'D:\Jogo\Whitemane\Games\FrostmourneRebuffed'
$root = Join-Path $game "WTF\Account\$Account"
$project = Split-Path $PSScriptRoot -Parent

$running = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match 'wow' -and $_.Path -and $_.Path.StartsWith($game, [StringComparison]::OrdinalIgnoreCase) }
if ($running) { Write-Output "SKIPPED: Test WoW is running ($($running[0].Path)). Exit WoW, then run again."; exit 2 }
if (-not (Test-Path $root)) { Write-Output "Nothing to do: $root not found."; exit 0 }

$files = @(Get-ChildItem $root -Recurse -File | Where-Object {
    $_.Directory.Name -eq 'SavedVariables' -and ($_.Name -like 'Ellesmere*' -or $_.Name -like 'EUI*') -and ($_.Name -like '*.lua' -or $_.Name -like '*.lua.bak')
})
if ($files.Count -eq 0) { Write-Output 'Nothing to do: no EUI saved variables.'; exit 0 }

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup = Join-Path $project ".codex-backups\test-savedvariables-before-reset-$stamp"
foreach ($f in $files) {
    $dest = Join-Path $backup $f.FullName.Substring($root.Length).TrimStart('\')
    New-Item -ItemType Directory -Force -Path (Split-Path $dest -Parent) | Out-Null
    Copy-Item -LiteralPath $f.FullName -Destination $dest
}
foreach ($f in $files) { Remove-Item -LiteralPath $f.FullName }
Write-Output "Reset $($files.Count) files. Backup: $backup"
