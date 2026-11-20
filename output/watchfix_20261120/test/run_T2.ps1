# T2 (T1 직후) 리셋 전 2회차 → '한도 대기 중 … 건너뜀' 1줄 · claude 호출 0회
. (Join-Path $PSScriptRoot '_lib.ps1')
'== T2 ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
$n0 = Get-ArgvCount
Invoke-AW 'ok'
$n1 = Get-ArgvCount
Show-LogTail 2
$last = (Get-Content (Join-Path $State 'autowatch.log') -Encoding UTF8 -Tail 1)
Check '한도 대기 로그' ($last -match '한도 대기 중 .* 건너뜀')
Check "claude 호출 0회 ($n0 → $n1)" ($n1 -eq $n0)
Check '결과 파일 없음' (-not (Test-Path (Join-Path $Work $ResN)))
