@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo 쓰레드(매일 08:10)·네이버 임시저장(매일 08:20) 자동 작업을 등록합니다.
echo 조건: .env.local 에 토큰·사용자ID·블로그ID가 있고 드라이런 2개가 통과해야 등록됩니다.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0register_sns_schedule.ps1" %*
echo.
pause
