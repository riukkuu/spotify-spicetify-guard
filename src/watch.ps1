param([switch]$Once)

$ErrorActionPreference = 'SilentlyContinue'

$sp = Join-Path $env:APPDATA 'Spotify'
$sg = Join-Path $env:APPDATA 'spicetify'
$cli = Join-Path $env:LOCALAPPDATA 'spicetify'
$store = Join-Path $env:LOCALAPPDATA 'SpotifyAdBlock'
$profile = Join-Path $store 'profile'
$log = Join-Path $store 'watch.log'
$spLog = Join-Path $store 'spicetify.log'
$template = Join-Path $store 'Spotify-launcher.exe'
$bootName = 'marketplace-state.js'

if (-not (Test-Path -LiteralPath $store)) { New-Item -ItemType Directory -Path $store -Force | Out-Null }

function Write-Log([string]$message) {
    $line = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + ' ' + $message
    Add-Content -LiteralPath $log -Value $line -Encoding UTF8
    if ((Get-Item -LiteralPath $log -ErrorAction SilentlyContinue).Length -gt 200000) {
        $tail = Get-Content -LiteralPath $log -Tail 500
        [IO.File]::WriteAllLines($log, $tail, (New-Object Text.UTF8Encoding($false)))
    }
}

function Get-Hash([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { return '' }
    return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-IniValue([string]$path, [string]$key) {
    if (-not (Test-Path -LiteralPath $path)) { return '' }
    $m = Select-String -LiteralPath $path -Pattern ('^\s*' + [regex]::Escape($key) + '\s*=\s*(.*)$')
    if ($m -and $m.Matches.Count -gt 0) { return $m.Matches[0].Groups[1].Value.Trim() }
    return ''
}

function Set-IniValue([string]$path, [string]$key, [string]$value) {
    $lines = @(Get-Content -LiteralPath $path)
    $found = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match ('^\s*' + [regex]::Escape($key) + '\s*=')) {
            $lines[$i] = ($key.PadRight(21)) + '= ' + $value
            $found = $true
        }
    }
    if (-not $found) { $lines += (($key.PadRight(21)) + '= ' + $value) }
    [IO.File]::WriteAllText($path, ($lines -join "`r`n"), (New-Object Text.UTF8Encoding($false)))
}

function Add-ToExtensionList([string]$current, [string]$name) {
    $parts = @($current -split '[,|]' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if ($parts -notcontains $name) { $parts = @($name) + $parts }
    return ($parts -join ',')
}

function Copy-TreeContents([string]$src, [string]$dst) {
    if (-not (Test-Path -LiteralPath $src)) { return }
    New-Item -ItemType Directory -Path $dst -Force | Out-Null
    Get-ChildItem -LiteralPath $src -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $dst -Recurse -Force
    }
}

function Restore-TreeContents([string]$src, [string]$dst) {
    if (-not (Test-Path -LiteralPath $src)) { return }
    New-Item -ItemType Directory -Path $dst -Force | Out-Null
    Get-ChildItem -LiteralPath $src -Recurse -File -Force | ForEach-Object {
        $rel = $_.FullName.Substring($src.Length).TrimStart('\')
        $target = Join-Path $dst $rel
        if (-not (Test-Path -LiteralPath $target)) {
            $parent = Split-Path -Parent $target
            if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
            Copy-Item -LiteralPath $_.FullName -Destination $target -Force
        }
    }
}

function Test-RealSpotifyRunning {
    $real = Join-Path $sp 'Spotify-real.exe'
    $found = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
        Where-Object { $_.ExecutablePath -and $_.ExecutablePath -ieq $real }).Count
    return ($found -gt 0)
}

function Snapshot-Spicetify {
    New-Item -ItemType Directory -Path $profile -Force | Out-Null
    $cfg = Join-Path $sg 'config-xpui.ini'
    if (Test-Path -LiteralPath $cfg) { Copy-Item -LiteralPath $cfg -Destination (Join-Path $profile 'config-xpui.ini') -Force }
    foreach ($dir in @('Extensions', 'CustomApps', 'Themes')) {
        $src = Join-Path $sg $dir
        $dst = Join-Path $profile $dir
        if (Test-Path -LiteralPath $src) {
            New-Item -ItemType Directory -Path $dst -Force | Out-Null
            Get-ChildItem -LiteralPath $src -Force | ForEach-Object {
                $target = Join-Path $dst $_.Name
                if (-not (Test-Path -LiteralPath $target)) { Copy-Item -LiteralPath $_.FullName -Destination $target -Recurse -Force }
            }
        }
    }
}

function Restore-SpicetifySnapshot {
    $cfg = Join-Path $sg 'config-xpui.ini'
    $savedCfg = Join-Path $profile 'config-xpui.ini'
    if (-not (Test-Path -LiteralPath $cfg) -and (Test-Path -LiteralPath $savedCfg)) {
        New-Item -ItemType Directory -Path $sg -Force | Out-Null
        Copy-Item -LiteralPath $savedCfg -Destination $cfg -Force
    }
    foreach ($dir in @('Extensions', 'CustomApps', 'Themes')) {
        Restore-TreeContents (Join-Path $profile $dir) (Join-Path $sg $dir)
    }
}

function Write-FreshConfig {
    $real = Join-Path $sp 'Spotify-real.exe'
    $exe = if (Test-Path -LiteralPath $real) { $real } else { Join-Path $sp 'Spotify.exe' }
    $version = (Get-Item -LiteralPath $exe -ErrorAction SilentlyContinue).VersionInfo.ProductVersion
    if (-not $version) { $version = '1.3.10.2586' }
    $cfg = Join-Path $sg 'config-xpui.ini'
    $text = @"
[Setting]
prefs_path             = $env:APPDATA\Spotify\prefs
current_theme          = marketplace
color_scheme           = 
inject_theme_js        = 1
always_enable_devtools = 0
spotify_path           = $env:APPDATA\Spotify
inject_css             = 1
replace_colors         = 1
overwrite_assets       = 0
spotify_launch_flags   = 
check_spicetify_update = 1

[Preprocesses]
disable_sentry     = 1
disable_ui_logging = 1
remove_rtl_rule    = 1
expose_apis        = 1

[AdditionalOptions]
home_config           = 1
experimental_features = 1
extensions            = $bootName
custom_apps           = marketplace
sidebar_config        = 0

[Patch]

; DO NOT CHANGE!
[Backup]
version = $version
with    = 2.46.7
"@
    [IO.File]::WriteAllText($cfg, $text, (New-Object Text.UTF8Encoding($false)))
}

function Ensure-SpicetifyInstalled {
    $exe = Join-Path $cli 'spicetify.exe'
    if (Test-Path -LiteralPath $exe) { return $null }

    $srcCli = Join-Path $store 'cli'
    if (-not (Test-Path -LiteralPath (Join-Path $srcCli 'spicetify.exe'))) {
        Write-Log 'Spicetify is absent and no portable copy is available in the repair store'
        return $null
    }
    Copy-TreeContents $srcCli $cli
    New-Item -ItemType Directory -Path $sg -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $sg 'Extensions') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $sg 'CustomApps') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $sg 'Themes') -Force | Out-Null
    Write-FreshConfig
    Copy-TreeContents (Join-Path $profile 'CustomApps') (Join-Path $sg 'CustomApps')
    Copy-TreeContents (Join-Path $profile 'Themes') (Join-Path $sg 'Themes')
    Copy-TreeContents (Join-Path $profile 'Extensions') (Join-Path $sg 'Extensions')
    return 'Spicetify installed from the portable package'
}

function Ensure-BootstrapExtension {
    $cfg = Join-Path $sg 'config-xpui.ini'
    if (-not (Test-Path -LiteralPath $cfg)) { return }
    $src = Join-Path $profile 'Extensions\marketplace-state.js'
    $dst = Join-Path $sg 'Extensions\marketplace-state.js'
    if ((Test-Path -LiteralPath $src) -and -not (Test-Path -LiteralPath $dst)) {
        New-Item -ItemType Directory -Path (Join-Path $sg 'Extensions') -Force | Out-Null
        Copy-Item -LiteralPath $src -Destination $dst -Force
    }
    $current = Get-IniValue $cfg 'extensions'
    $updated = Add-ToExtensionList $current $bootName
    if ($updated -ne $current) { Set-IniValue $cfg 'extensions' $updated }
}

function Spicetify-IsApplied {
    $cfg = Join-Path $sg 'config-xpui.ini'
    $theme = Get-IniValue $cfg 'current_theme'
    $marker = Join-Path $sp 'Apps\xpui\spicetify-config.json'
    if (-not (Test-Path -LiteralPath $marker)) { return $false }
    if (-not $theme) { return $true }
    $text = Get-Content -LiteralPath $marker -Raw
    return ($text -match ('"theme_name"\s*:\s*"' + [regex]::Escape($theme) + '"'))
}

function Repair-Spicetify {
    $exe = Join-Path $cli 'spicetify.exe'
    if (-not (Test-Path -LiteralPath $exe)) { return $null }
    if (Spicetify-IsApplied) { return $null }
    if (Test-RealSpotifyRunning) { return 'Spicetify patch missing, but Spotify is running; apply skipped' }

    & $exe backup apply *> $spLog
    $exit = $LASTEXITCODE
    if ($exit -ne 0) {
        & $exe apply *> $spLog
        $exit = $LASTEXITCODE
    }
    return 'spicetify backup apply: exit=' + $exit
}

function Ensure-Launcher {
    $exe = Join-Path $sp 'Spotify.exe'
    $real = Join-Path $sp 'Spotify-real.exe'
    $mainDll = Join-Path $sp 'Spotify.dll'
    $realDll = Join-Path $sp 'Spotify-real.dll'

    if ((Test-Path -LiteralPath $real) -and (Test-Path -LiteralPath $mainDll)) {
        $needLink = -not (Test-Path -LiteralPath $realDll)
        if (-not $needLink) {
            $a = Get-Item -LiteralPath $realDll
            $b = Get-Item -LiteralPath $mainDll
            $needLink = ($a.Length -ne $b.Length) -or ($a.LastWriteTimeUtc -ne $b.LastWriteTimeUtc)
        }
        if ($needLink) {
            Remove-Item -LiteralPath $realDll -Force -ErrorAction SilentlyContinue
            & fsutil hardlink create $realDll $mainDll 2>&1 | Out-Null
        }
    }

    if (-not (Test-Path -LiteralPath $template)) { return }
    $templateHash = Get-Hash $template
    if ((Test-Path -LiteralPath $exe) -and (Get-Hash $exe) -eq $templateHash) { return }

    if (Test-Path -LiteralPath $exe) {
        $sig = Get-AuthenticodeSignature -LiteralPath $exe
        if ($sig.Status -eq 'Valid' -and $sig.SignerCertificate.Subject -match 'Spotify AB') {
            Copy-Item -LiteralPath $exe -Destination $real -Force
        }
    }
    if (-not (Test-Path -LiteralPath $real)) {
        Write-Log 'Spotify-real.exe missing; launcher cannot be installed'
        return
    }
    Copy-Item -LiteralPath $template -Destination $exe -Force
    Write-Log 'Spotify.exe launcher re-installed'
}

function Invoke-Pass {
    try { Ensure-Launcher } catch { Write-Log ('launcher check failed: ' + $_.Exception.Message) }

    try { $msg = Ensure-SpicetifyInstalled; if ($msg) { Write-Log $msg } }
    catch { Write-Log ('spicetify install failed: ' + $_.Exception.Message) }

    try { Restore-SpicetifySnapshot } catch { Write-Log ('spicetify snapshot restore failed: ' + $_.Exception.Message) }
    try { Ensure-BootstrapExtension } catch { Write-Log ('bootstrap extension check failed: ' + $_.Exception.Message) }

    try { $msg = Repair-Spicetify; if ($msg) { Write-Log $msg } }
    catch { Write-Log ('spicetify repair failed: ' + $_.Exception.Message) }

    try { Snapshot-Spicetify } catch { Write-Log ('spicetify snapshot failed: ' + $_.Exception.Message) }
}

if ($Once) {
    $mutex = New-Object System.Threading.Mutex($false, 'Local\SpotifySpicetifyRepair')
    if (-not $mutex.WaitOne(0)) { exit 0 }
    try { Invoke-Pass } finally { $mutex.ReleaseMutex() }
    exit 0
}

# Kept for compatibility only: the resident watcher is intentionally not started.
Write-Log 'watch.ps1 invoked without -Once; nothing to do'
