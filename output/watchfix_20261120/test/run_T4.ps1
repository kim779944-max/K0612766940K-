# T4 리셋 문구 없는 한도("429 Too Many Requests") → RATE_HIT.txt 미생성 · try 변화 0 · 다음 회차 바로 재시도
. (Join-Path $PSScriptRoot '_lib.ps1')
'== T4 ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
New-TestEnv
"  실행 전 try = $(Get-Try)"
Invoke-AW 'r429'
"  실행 후 try = $(Get-Try)"
Show-LogTail 3
'  RATE_HIT.log: ' + ((Get-Content (Join-Path $State 'RATE_HIT.log') -Encoding UTF8) -join ' / ')
Check 'RATE_HIT.txt 미생성' (-not (Test-Path (Join-Path $State 'RATE_HIT.txt')))
Check 'try 변화 0((없음)→(없음))' ((Get-Try) -eq '(없음)')
$n0 = Get-ArgvCount
Invoke-AW 'ok'
$n1 = Get-ArgvCount
Show-LogTail 4
Check "다음 회차 바로 재시도(claude 호출 $n0 → $n1)" ($n1 -eq $n0 + 1)
Check '재시도는 이어서 실행(--resume)' (@(Get-Content $Argv -Encoding UTF8)[-1] -match '--resume')
