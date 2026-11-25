#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CliPath,
    [string]$Output,
    [string]$LauncherExe
)

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot
if (-not $Output) { $Output = Join-Path $repo 'dist\Spotify-AdBlock-Portable.zip' }

if (-not (Test-Path -LiteralPath $CliPath)) { throw "CLI path not found: $CliPath" }
if (-not (Test-Path -LiteralPath (Join-Path $CliPath 'spicetify.exe'))) {
    throw "Not a Spicetify CLI folder (spicetify.exe missing): $CliPath"
}

$tmp = Join-Path $repo '.tmp\build'
Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $tmp -Force | Out-Null

# Scripts and docs at the archive root
Get-ChildItem -LiteralPath (Join-Path $repo 'src') -File | Copy-Item -Destination $tmp -Force

# Launcher executable
if (-not $LauncherExe) {
    $csc = 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
    if (-not (Test-Path -LiteralPath $csc)) { $csc = 'C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe' }
    if (-not (Test-Path -LiteralPath $csc)) { throw 'C# compiler not found. Pass -LauncherExe explicitly.' }
    $LauncherExe = Join-Path $tmp 'launcher-compiled.exe'
    & $csc /nologo /target:exe /optimize+ /out:"$LauncherExe" (Join-Path $repo 'src\launcher.cs') | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Failed to compile src\launcher.cs' }
}
Copy-Item -LiteralPath $LauncherExe -Destination (Join-Path $tmp 'Spotify-launcher.exe') -Force
if ($LauncherExe -ne (Join-Path $tmp 'Spotify-launcher.exe')) { Remove-Item -LiteralPath $LauncherExe -Force -ErrorAction SilentlyContinue }

# Portable Spicetify CLI
$cliDst = Join-Path $tmp 'cli'
New-Item -ItemType Directory -Path $cliDst -Force | Out-Null
Get-ChildItem -LiteralPath $CliPath -Force | Copy-Item -Destination $cliDst -Recurse -Force

# Assets
$assetsDst = Join-Path $tmp 'assets'
New-Item -ItemType Directory -Path $assetsDst -Force | Out-Null
Get-ChildItem -LiteralPath (Join-Path $repo 'assets') -Force | Copy-Item -Destination $assetsDst -Recurse -Force

# Spicetify profile snapshot
$profileDst = Join-Path $tmp 'profile'
New-Item -ItemType Directory -Path $profileDst, (Join-Path $profileDst 'Extensions'), (Join-Path $profileDst 'Themes\marketplace'), (Join-Path $profileDst 'CustomApps\marketplace') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $repo 'profile\config-xpui.ini') -Destination (Join-Path $profileDst 'config-xpui.ini') -Force
Copy-Item -LiteralPath (Join-Path $repo 'profile\marketplace-state.js') -Destination (Join-Path $profileDst 'Extensions\marketplace-state.js') -Force
Copy-Item -LiteralPath (Join-Path $repo 'profile\theme-color.ini') -Destination (Join-Path $profileDst 'Themes\marketplace\color.ini') -Force
Get-ChildItem -LiteralPath (Join-Path $repo 'profile\marketplace') -Force | Copy-Item -Destination (Join-Path $profileDst 'CustomApps\marketplace') -Recurse -Force

# ZIP with root-level entries
$outDir = Split-Path -Parent $Output
if ($outDir -and -not (Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
Remove-Item -LiteralPath $Output -Force -ErrorAction SilentlyContinue
Compress-Archive -Path (Join-Path $tmp '*') -DestinationPath $Output -CompressionLevel Optimal -Force

Write-Host "Built: $Output"
Get-Item -LiteralPath $Output | Select-Object FullName, Length, LastWriteTime | Format-List

Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
