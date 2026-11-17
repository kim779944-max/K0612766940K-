@echo off
rem KTS auto-watch: register auto_watch.ps1 in Windows Task Scheduler (every 10 minutes, current user, only while logged on)
rem   setup_autowatch.bat          -> register (or update)
rem   setup_autowatch.bat remove   -> unregister
rem   setup_autowatch.bat run      -> run once now
chcp 65001 >nul
set "TN=KTS_AutoWatch"
set "PS1=%~dp0auto_watch.ps1"

if /I "%~1"=="remove" (
  schtasks /Delete /TN "%TN%" /F
  goto :eof
)
if /I "%~1"=="run" (
  schtasks /Run /TN "%TN%"
  goto :eof
)

schtasks /Create /TN "%TN%" /SC MINUTE /MO 10 /F /TR "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"%PS1%\""
if errorlevel 1 (
  echo.
  echo [failed] Run this file again from a normal Command Prompt.
  exit /b 1
)
echo.
echo [OK] %TN% registered - runs every 10 minutes.
echo      log: %LOCALAPPDATA%\KTS_autowatch\autowatch.log
echo      remove: setup_autowatch.bat remove
schtasks /Query /TN "%TN%" /FO LIST | findstr /I "TaskName Next Status"
