# T6 claude 가 끝나지 않음(가짜 120초 대기) · 상한 1분 → 1분 뒤 종료·로그 1줄·try 안 셈·뮤텍스 풀림(다음 회차 정상 진입)
#  (지시서 표의 '30초 대기'는 상한 1분보다 짧아 워치독이 발동하지 않으므로, 가짜 claude 를 120초 대기로 바꿔 시험)
. (Join-Path $PSScriptRoot '_lib.ps1')
'== T6 ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
New-TestEnv
"  실행 전 try = $(Get-Try)"
$t0 = Get-Date
Invoke-AW 'hang' '1'
$sec = [int]((Get-Date) - $t0).TotalSeconds
"  실행 후 try = $(Get-Try) · 걸린 시간 ${sec}초"
Show-LogTail 4
$left = @(Get-Process claude -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "$Bin*" })
$log = Get-Content (Join-Path $State 'autowatch.log') -Raw -Encoding UTF8
Check '상한 초과 로그 1줄' (([regex]::Matches($log, '실행 상한 초과로 종료')).Count -eq 1)
Check "약 1분 뒤 종료(${sec}초)" ($sec -ge 55 -and $sec -lt 110)
Check '가짜 claude 프로세스 남지 않음' ($left.Count -eq 0)
Check 'try 안 셈' ((Get-Try) -eq '(없음)')
Invoke-AW 'ok'
Show-LogTail 5
Check '뮤텍스 풀림 → 다음 회차 정상 진입·완료' (Test-Path (Join-Path $Work $ResN))
