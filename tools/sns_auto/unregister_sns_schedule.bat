@echo off
chcp 65001 >nul
schtasks /Delete /TN "KTS_SNS_THREADS" /F
schtasks /Delete /TN "KTS_SNS_NAVER" /F
echo 자동 게시 작업을 해제했습니다.
pause
