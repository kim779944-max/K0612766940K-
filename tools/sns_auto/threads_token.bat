@echo off
chcp 65001 >nul
cd /d "%~dp0"
set "PYTHONUTF8=1"
set "PY="
where py >nul 2>nul && set "PY=py -3"
if not defined PY if exist "%LOCALAPPDATA%\Programs\Python\Launcher\py.exe" set PY="%LOCALAPPDATA%\Programs\Python\Launcher\py.exe" -3
if not defined PY set "PY=python"
echo 1) 새 토큰 받기 (앱 ID - 앱 시크릿 - code 순서로 붙여 넣기)
echo 2) 토큰 갱신 (--refresh)
set /p SEL=번호를 넣고 Enter: 
if "%SEL%"=="2" (
  %PY% threads_token.py --refresh
) else (
  %PY% threads_token.py
)
echo.
pause
