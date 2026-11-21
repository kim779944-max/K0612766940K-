@echo off
chcp 65001 >nul
set "CHROME=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if not exist "%CHROME%" set "CHROME=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
if not exist "%CHROME%" set "CHROME=%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"
set "PROFILE=%USERPROFILE%\KTS_SNS_CHROME"
if not exist "%PROFILE%" mkdir "%PROFILE%"
echo 전용 크롬을 엽니다. 이 창에서 네이버에 한 번만 로그인해 두세요. (이 창은 닫지 마세요)
start "" "%CHROME%" --remote-debugging-port=9222 --user-data-dir="%PROFILE%" --no-first-run --no-default-browser-check "https://blog.naver.com"
