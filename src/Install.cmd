@echo off
chcp 65001 >nul
echo === Spotify Spicetify Guard installer ===
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
cd /d "%TEMP%" >nul 2>&1
echo.
echo === PowerShell exit code: %ERRORLEVEL% ===
echo.
if exist "%LOCALAPPDATA%\SpotifyAdBlock\install-complete.txt" (
    echo === INSTALL COMPLETE MARKER EXISTS ===
) else (
    echo === NO COMPLETE MARKER - SEE install-progress.log ===
)
if exist "%LOCALAPPDATA%\SpotifyAdBlock\install-progress.log" (
    echo.
    echo === install-progress.log ===
    type "%LOCALAPPDATA%\SpotifyAdBlock\install-progress.log"
)
echo.
echo Press any key to close this window...
pause >nul
