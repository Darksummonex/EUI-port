# Zip the EllesmereUI* addon folders, exact folder names at the archive root, ready to
# extract into Interface/AddOns. Usage: zip_addons.ps1 [output.zip]
param([string]$Out)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$root = Split-Path $PSScriptRoot -Parent
if (-not $Out) { $Out = Join-Path $root ("EllesmereUI-3.3.5-addons-{0:yyyyMMdd-HHmm}.zip" -f (Get-Date)) }
if (Test-Path $Out) { throw "$Out already exists" }
$folders = Get-ChildItem $root -Directory -Filter 'EllesmereUI*' | Sort-Object Name
if (-not $folders) { throw 'no EllesmereUI folders' }
$zip = [IO.Compression.ZipFile]::Open($Out, 'Create')
$count = 0
try {
    foreach ($folder in $folders) {
        if (-not (Test-Path (Join-Path $folder.FullName "$($folder.Name).toc"))) { throw "$($folder.Name): missing TOC" }
        foreach ($f in Get-ChildItem $folder.FullName -Recurse -File | Sort-Object FullName) {
            $entry = $f.FullName.Substring($root.Length + 1).Replace('\', '/')
            [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $f.FullName, $entry, 'Optimal')
            $count++
        }
    }
} finally { $zip.Dispose() }
"{0} | {1} addons, {2} files, {3:N1} MB" -f $Out, $folders.Count, $count, ((Get-Item $Out).Length / 1MB)
