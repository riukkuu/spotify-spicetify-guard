$ErrorActionPreference = 'SilentlyContinue'
$sp = Join-Path $env:APPDATA 'Spotify'
$store = Join-Path $env:LOCALAPPDATA 'SpotifyAdBlock'

Get-CimInstance Win32_Process -Filter "name = 'powershell.exe'" |
    Where-Object {
        $_.CommandLine -like '*SpotifyAdBlock*repair.ps1*' -or
        $_.CommandLine -like '*SpotifyAdBlock*watch.ps1*'
    } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }

Get-Process -Name 'Spotify', 'Spotify-real' -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

$real = Join-Path $sp 'Spotify-real.exe'
$exe = Join-Path $sp 'Spotify.exe'
if (Test-Path -LiteralPath $real) {
    Remove-Item -LiteralPath $exe -Force -ErrorAction SilentlyContinue
    Move-Item -LiteralPath $real -Destination $exe -Force
}
Remove-Item -LiteralPath (Join-Path $sp 'Spotify-real.dll') -Force

$startup = [Environment]::GetFolderPath('Startup')
$desktop = [Environment]::GetFolderPath('Desktop')
Remove-Item -LiteralPath (Join-Path $startup 'Spotify Spicetify Guard (Logon).lnk') -Force
Remove-Item -LiteralPath (Join-Path $startup 'Spotify AdBlock Repair (Logon).lnk') -Force
Remove-Item -LiteralPath (Join-Path $desktop 'Spotify Spicetify Guard.lnk') -Force
Remove-Item -LiteralPath (Join-Path $desktop 'Spotify AdBlock Repair.lnk') -Force

$startMenuLnk = Join-Path ([Environment]::GetFolderPath('StartMenu')) 'Programs\Spotify.lnk'
if (Test-Path -LiteralPath $startMenuLnk) {
    $ws = New-Object -ComObject WScript.Shell
    $s = $ws.CreateShortcut($startMenuLnk)
    $s.TargetPath = $exe
    $s.Arguments = ''
    $s.IconLocation = $exe + ',0'
    $s.Save()
}

Remove-Item -LiteralPath $store -Recurse -Force
Write-Output 'Launcher and guard removed. Spicetify and its theme/extensions were left untouched.'
