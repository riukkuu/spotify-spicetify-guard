# Spotify Spicetify Guard

[Русская версия](README.ru.md)

A small, portable setup that keeps a **standalone Spotify** client patched with
**Spicetify + Marketplace + `adblockify`** after Spotify updates.

Ads are blocked by the Spicetify Marketplace extension **`adblockify`**.
This project does **not** use BlockTheSpot and does not patch Spotify's loader.

## Features

- Spotify updates stay **enabled**.
- No admin rights, no Task Scheduler, no WMI triggers, no registry hacks,
  no background watcher and no polling.
- Repair runs **only when Spotify starts**, then the launcher exits.
- Existing Spicetify installations are preserved, never replaced.
- If Spicetify is missing, it is installed from the bundled portable copy.
- The desktop and logon shortcuts only run a one-shot repair script.

## Requirements

- Windows x64.
- **Standalone Spotify** installed from https://www.spotify.com/download/windows/
  (`%APPDATA%\Spotify\Spotify.exe`).
- **Microsoft Store version is not supported** (`C:\Program Files\WindowsApps\SpotifyAB...`).
- Launch Spotify once before installing, so `%APPDATA%\Spotify` exists.
- No administrator rights required.

## Install

1. Install standalone Spotify from the official site and launch it once.
2. Download the ZIP from the **Releases** page and extract it anywhere.
3. Double-click **`Install.cmd`**.
   Do not right-click `install.ps1` → "Run with PowerShell": the default
   PowerShell execution policy blocks scripts. `Install.cmd` passes
   `-ExecutionPolicy Bypass` for you.
4. Wait for the `Done. Just start Spotify normally.` dialog and click **OK**.
5. Start Spotify normally.

The extracted folder can be deleted afterwards. Keep the ZIP for reinstalling.

## How it works

| File | Role |
|---|---|
| `Spotify.exe` | Tiny C# launcher. Runs the repair, then starts the real client. |
| `Spotify-real.exe` | Original signed Spotify client, renamed by the installer. |
| `Spotify-real.dll` | Hardlink to `Spotify.dll`, so the renamed client still loads. |
| `%LOCALAPPDATA%\SpotifyAdBlock\` | Live scripts, portable Spicetify CLI, profile snapshot and logs. |
| `repair.ps1` / `watch.ps1` | One-shot repair: checks launcher, hardlink, Spicetify, theme, extensions and Marketplace state. |
| `spicetify backup apply` | Re-applies theme and extensions after an update removed the patch. |

On a normal launch, when nothing changed, the repair is a no-op: no patching,
no new log lines.

## Verify

- In Spotify: **Marketplace → Extensions → adblockify** should be installed.
- `%APPDATA%\Spotify\Apps\xpui\spicetify-config.json` should exist with
  `theme_name = marketplace`.
- Logs:
  - `%LOCALAPPDATA%\SpotifyAdBlock\install-progress.log`
  - `%LOCALAPPDATA%\SpotifyAdBlock\watch.log`

## Uninstall

Double-click `Uninstall.cmd` from the extracted folder, or run:

```powershell
powershell -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\SpotifyAdBlock\uninstall.ps1"
```

This restores the original `Spotify.exe`, removes the launcher and shortcuts.
It does **not** delete Spicetify, the theme or the extensions.

## Build

The repository keeps the scripts and small assets only. The ready-made ZIP is
published as a GitHub Release. To build it locally you need the portable
Spicetify CLI folder (version 2.46.7 was used for the published build):

```powershell
.\build.ps1 -CliPath 'C:\path\to\spicetify-cli'
```

The script compiles `src/launcher.cs` with the .NET Framework C# compiler and
creates `dist\Spotify-AdBlock-Portable.zip` with all files at the archive root.

## License

This project is licensed under the **GNU General Public License v3.0 or later**.
See [LICENSE](LICENSE) and [COPYRIGHT](COPYRIGHT).

Bundled third-party components keep their own licenses; see
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Legal / credits

Modifying a client may violate Spotify's Terms of Service. Use at your own risk.
This project is not affiliated with or endorsed by Spotify AB.
