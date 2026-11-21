@echo off
chcp 65001 >nul
cd /d "%~dp0"
if not exist logs mkdir logs
set "PYTHONUTF8=1"
set "PY="
where py >nul 2>nul && set "PY=py -3"
if not defined PY if exist "%LOCALAPPDATA%\Programs\Python\Launcher\py.exe" set PY="%LOCALAPPDATA%\Programs\Python\Launcher\py.exe" -3
if not defined PY set "PY=python"
rem 인자 없이 = 스케줄러용 1건(오늘 이미 했으면 건너뜀). 처음 10편 채우기: run_naver.bat --live --count 10
%PY% naver_blog_draft.py %* >> logs\run_naver_%date:~0,4%%date:~5,2%%date:~8,2%.log 2>&1
exit /b %errorlevel%
