# T5 정상 종료(exit 0) + 결과 파일 → try 삭제 · RATE_HIT.txt 삭제 · 커밋·푸시 로그
. (Join-Path $PSScriptRoot '_lib.ps1')
'== T5 ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
New-TestEnv
Set-Content (Join-Path $State ($TaskN + '.try')) '2' -Encoding UTF8
Set-Content (Join-Path $State 'RATE_HIT.txt') ('{"task":"' + $TaskN + '","hitAt":"2026-11-20T10:00:00","resetAt":"2026-11-20T10:05:00"}') -Encoding UTF8
"  실행 전 try = $(Get-Try) · RATE_HIT.txt(지난 시각) 있음"
Invoke-AW 'ok'
Show-LogTail 6
$log = Get-Content (Join-Path $State 'autowatch.log') -Raw -Encoding UTF8
$rlog = git -C $Origin log --oneline -1 main
"  원격 최신 커밋: $rlog"
Check 'try 삭제' ((Get-Try) -eq '(없음)')
Check 'RATE_HIT.txt 삭제' (-not (Test-Path (Join-Path $State 'RATE_HIT.txt')))
Check '커밋·푸시 로그' ($log -match 'git push 완료')
Check '원격에 결과 커밋' ($rlog -match "auto: $TaskN 자동 실행 결과")
Check '완료 로그' ($log -match '완료 → CLAUDE_RESULT_20991231_TEST.md 생성됨')
