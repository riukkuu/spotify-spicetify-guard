@echo off
chcp 65001 >nul
echo === Spotify Spicetify Guard uninstaller ===
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
cd /d "%TEMP%" >nul 2>&1
echo.
echo === Uninstall finished. You can now delete this folder. ===
echo.
echo Press any key to close this window...
pause >nul
