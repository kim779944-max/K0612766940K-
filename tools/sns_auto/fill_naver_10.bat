@echo off
chcp 65001 >nul
cd /d "%~dp0"
if not exist logs mkdir logs
set "PYTHONUTF8=1"
set "PY="
where py >nul 2>nul && set "PY=py -3"
if not defined PY if exist "%LOCALAPPDATA%\Programs\Python\Launcher\py.exe" set PY="%LOCALAPPDATA%\Programs\Python\Launcher\py.exe" -3
if not defined PY set "PY=python"
echo 네이버 임시저장함에 10편을 채웁니다(발행은 하지 않습니다). 10~15분 걸립니다.
%PY% naver_blog_draft.py --live --count 10
echo.
pause
