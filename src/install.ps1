#requires -Version 5.1
$ErrorActionPreference = 'Stop'

$pkg = Split-Path -Parent $MyInvocation.MyCommand.Path
$sp = Join-Path $env:APPDATA 'Spotify'
$sg = Join-Path $env:APPDATA 'spicetify'
$cli = Join-Path $env:LOCALAPPDATA 'spicetify'
$store = Join-Path $env:LOCALAPPDATA 'SpotifyAdBlock'
$progressLog = Join-Path $store 'install-progress.log'
New-Item -ItemType Directory -Path $store -Force | Out-Null
Set-Content -LiteralPath $progressLog -Value ("=== installer started {0} ===" -f (Get-Date -Format 'o')) -Encoding UTF8 -ErrorAction SilentlyContinue

function Say([string]$m) {
    Write-Host $m -ForegroundColor Cyan
    Add-Content -LiteralPath $progressLog -Value ("{0}  {1}" -f (Get-Date -Format 'HH:mm:ss'), $m) -Encoding UTF8 -ErrorAction SilentlyContinue
}
function Fail([string]$m) {
    Write-Host $m -ForegroundColor Red
    Add-Content -LiteralPath $progressLog -Value ("{0}  ERROR: {1}" -f (Get-Date -Format 'HH:mm:ss'), $m) -Encoding UTF8 -ErrorAction SilentlyContinue
    Show-Popup $m 'Spotify Spicetify Guard - ERROR' 16
    exit 1
}

trap {
    $msg = "{0}  UNEXPECTED ERROR: {1}" -f (Get-Date -Format 'HH:mm:ss'), $_.Exception.Message
    Write-Host $msg -ForegroundColor Red
    Add-Content -LiteralPath $progressLog -Value $msg -Encoding UTF8 -ErrorAction SilentlyContinue
    continue
}

function Show-Popup([string]$text, [string]$title, [int]$icon) {
    try {
        $w = New-Object -ComObject WScript.Shell
        [void]$w.Popup($text, 0, $title, $icon)
    } catch {}
}

function Copy-TreeContents([string]$src, [string]$dst) {
    if (-not (Test-Path -LiteralPath $src)) { return }
    New-Item -ItemType Directory -Path $dst -Force | Out-Null
    Get-ChildItem -LiteralPath $src -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $dst -Recurse -Force
    }
}

Say '=== Spotify Spicetify Guard installer ==='

if (-not (Test-Path -LiteralPath $sp)) {
    $appx = $null
    try { $appx = Get-AppxPackage -Name 'SpotifyAB.SpotifyMusic' -ErrorAction SilentlyContinue | Select-Object -First 1 } catch {}
    Write-Host '' -ForegroundColor Red
    Write-Host 'Standalone Spotify profile directory was not found.' -ForegroundColor Red
    Write-Host "Expected: $sp" -ForegroundColor Red
    Write-Host '' -ForegroundColor Yellow
    if ($appx) {
        Write-Host 'DETECTED: Microsoft Store version of Spotify is installed.' -ForegroundColor Red
        Write-Host "  Package:      $($appx.Name)" -ForegroundColor Yellow
        Write-Host "  Installed at: $($appx.InstallLocation)" -ForegroundColor Yellow
        Write-Host '' -ForegroundColor Yellow
        Write-Host 'This package does NOT support the Microsoft Store version.' -ForegroundColor Red
        Write-Host '' -ForegroundColor Yellow
        Write-Host 'What to do:' -ForegroundColor Yellow
        Write-Host '  1) Settings -> Apps -> Installed apps -> Spotify -> Uninstall.' -ForegroundColor Yellow
        Write-Host '  2) Download the desktop installer from https://www.spotify.com/download/windows/' -ForegroundColor Yellow
        Write-Host '     (choose the direct Windows download, NOT "Get from Microsoft Store").' -ForegroundColor Yellow
        Write-Host '  3) Run SpotifySetup.exe, then launch Spotify once.' -ForegroundColor Yellow
        Write-Host '  4) Run Install.cmd again.' -ForegroundColor Yellow
    } else {
        Write-Host 'Most likely one of these is true:' -ForegroundColor Yellow
        Write-Host '  1) Spotify was installed from Microsoft Store (this package does NOT support Store version).' -ForegroundColor Yellow
        Write-Host '  2) Spotify was installed but has never been launched on this Windows account.' -ForegroundColor Yellow
        Write-Host '' -ForegroundColor Yellow
        Write-Host 'What to do:' -ForegroundColor Yellow
        Write-Host '  1) If Spotify is installed from Microsoft Store, uninstall it.' -ForegroundColor Yellow
        Write-Host '  2) Download and install the normal desktop version from https://www.spotify.com/download/windows/' -ForegroundColor Yellow
        Write-Host '  3) Launch Spotify once, log in or just close its window, then run Install.cmd again.' -ForegroundColor Yellow
    }
    Write-Host '' -ForegroundColor Red
    Fail 'Installation stopped.'
}
$exe = Join-Path $sp 'Spotify.exe'
$real = Join-Path $sp 'Spotify-real.exe'
if (-not (Test-Path -LiteralPath $exe) -and -not (Test-Path -LiteralPath $real)) { Fail 'Spotify.exe not found.' }
if (-not (Test-Path -LiteralPath (Join-Path $sp 'Spotify.dll'))) { Fail 'Spotify.dll not found - unsupported installation.' }

$versionExe = if (Test-Path -LiteralPath $real) { $real } else { $exe }
$version = (Get-Item -LiteralPath $versionExe).VersionInfo.ProductVersion
Say "Spotify version: $version"

New-Item -ItemType Directory -Path $store -Force | Out-Null
foreach ($name in @('watch.ps1', 'repair.ps1', 'uninstall.ps1', 'launcher.cs', 'Spotify-launcher.exe')) {
    Copy-Item -LiteralPath (Join-Path $pkg $name) -Destination (Join-Path $store $name) -Force
}
Copy-TreeContents (Join-Path $pkg 'cli') (Join-Path $store 'cli')
Copy-TreeContents (Join-Path $pkg 'profile') (Join-Path $store 'profile')
if (Test-Path -LiteralPath (Join-Path $pkg 'assets\marketplace-state.json')) {
    Copy-Item -LiteralPath (Join-Path $pkg 'assets\marketplace-state.json') -Destination (Join-Path $store 'marketplace-state.json') -Force
}

$spicetifyPresent = Test-Path -LiteralPath (Join-Path $cli 'spicetify.exe')
if ($spicetifyPresent) {
    Say 'Existing Spicetify detected: it will be preserved, not replaced.'
} else {
    Say 'Spicetify not found: it will be installed from the portable copy.'
}

Say 'Closing Spotify...'
try {
    $toClose = @(Get-Process -Name 'Spotify', 'Spotify-real' -ErrorAction SilentlyContinue)
    foreach ($p in $toClose) { try { $p.CloseMainWindow() | Out-Null } catch {} }
    Start-Sleep -Seconds 3
    $toKill = @(Get-Process -Name 'Spotify', 'Spotify-real' -ErrorAction SilentlyContinue)
    foreach ($p in $toKill) { try { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } catch {} }
    Start-Sleep -Seconds 2
} catch {
    Say ("Warning while closing Spotify: " + $_.Exception.Message)
}

Say 'Installing launcher...'
if (-not (Test-Path -LiteralPath $real)) {
    $sig = Get-AuthenticodeSignature -LiteralPath $exe
    if ($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notmatch 'Spotify AB') {
        Fail 'Spotify.exe is not signed by Spotify. Refusing to replace an unknown executable.'
    }
    Rename-Item -LiteralPath $exe -NewName 'Spotify-real.exe' -Force
}

$mainDll = Join-Path $sp 'Spotify.dll'
$realDll = Join-Path $sp 'Spotify-real.dll'
if (-not (Test-Path -LiteralPath $realDll)) {
    & fsutil hardlink create $realDll $mainDll 2>&1 | Out-Null
}
if (-not (Test-Path -LiteralPath $realDll)) { Fail 'Failed to create Spotify-real.dll hardlink.' }
Copy-Item -LiteralPath (Join-Path $store 'Spotify-launcher.exe') -Destination $exe -Force

Say 'Creating shortcuts...'
$ws = New-Object -ComObject WScript.Shell
$startup = [Environment]::GetFolderPath('Startup')
$desktop = [Environment]::GetFolderPath('Desktop')
$args = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + (Join-Path $store 'repair.ps1') + '"'

$logon = $ws.CreateShortcut((Join-Path $startup 'Spotify Spicetify Guard (Logon).lnk'))
$logon.TargetPath = 'powershell.exe'
$logon.Arguments = $args
$logon.WindowStyle = 7
$logon.Description = 'Restore Spicetify, theme and Marketplace extensions after a Spotify update'
$logon.Save()

$manual = $ws.CreateShortcut((Join-Path $desktop 'Spotify Spicetify Guard.lnk'))
$manual.TargetPath = 'powershell.exe'
$manual.Arguments = $args
$manual.WindowStyle = 7
$manual.Description = 'Restore Spicetify, theme and Marketplace extensions now'
$manual.Save()

$startMenu = Join-Path ([Environment]::GetFolderPath('StartMenu')) 'Programs\Spotify.lnk'
if (Test-Path -LiteralPath $startMenu) {
    $s = $ws.CreateShortcut($startMenu)
    $s.TargetPath = $exe
    $s.Arguments = ''
    $s.IconLocation = $exe + ',0'
    $s.Save()
}

Say 'Applying Spicetify theme and extensions...'
$log = Join-Path $store 'watch.log'
$before = @(Get-Content -LiteralPath $log -ErrorAction SilentlyContinue).Count
& powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File (Join-Path $store 'repair.ps1')
$newLines = @(Get-Content -LiteralPath $log -ErrorAction SilentlyContinue | Select-Object -Skip $before)
if ($newLines -match 'Spicetify is absent') {
    Write-Host 'WARNING: Spicetify could not be installed from the portable copy.' -ForegroundColor Yellow
}

Set-Content -LiteralPath (Join-Path $store 'install-complete.txt') -Value ("Install completed successfully at {0}" -f (Get-Date -Format 'o')) -Encoding UTF8

Say ''
Say 'Done. Just start Spotify normally.'
Say "Log: $log"
Say "Progress log: $progressLog"
Say 'Uninstall: powershell -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\SpotifyAdBlock\uninstall.ps1"'

Show-Popup "Done. Just start Spotify normally.`n`nSpicetify, theme and Marketplace adblockify are installed.`n`nLog: $log" 'Spotify Spicetify Guard' 64
