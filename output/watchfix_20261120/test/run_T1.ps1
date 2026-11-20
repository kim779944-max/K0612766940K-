# T1 한도 걸림(리셋 문구 있음) → try 변화 없음 · RATE_HIT.log 1줄 · RATE_HIT.txt 생성 · BLOCKED 0 · 결과 파일 없음
. (Join-Path $PSScriptRoot '_lib.ps1')
'== T1 ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
New-TestEnv
Set-Content (Join-Path $State ($TaskN + '.try')) '1' -Encoding UTF8   # 앞서 1번 실패한 상태라고 가정
"  실행 전 try = $(Get-Try)"
Invoke-AW 'ratelimit_reset'
"  실행 후 try = $(Get-Try)"
Show-LogTail 6
$rl = @(Get-Content (Join-Path $State 'RATE_HIT.log') -Encoding UTF8 -ErrorAction SilentlyContinue)
'  RATE_HIT.log: ' + ($rl -join ' / ')
$rt = Join-Path $State 'RATE_HIT.txt'
if (Test-Path $rt) { '  RATE_HIT.txt: ' + ((Get-Content $rt -Raw) -replace '\s+', ' ') }
$av = Get-Content $Argv -Raw -Encoding UTF8
'  argv: ' + $av.Substring(0, [Math]::Min(140, $av.Length))
Check 'try 변화 없음(1→1)' ((Get-Try) -eq '1')
Check 'RATE_HIT.log 1줄' ($rl.Count -eq 1)
Check 'RATE_HIT.txt 생성(resetAt 15:00)' ((Test-Path $rt) -and ((Get-Content $rt -Raw) -match 'T15:00:00'))
Check 'BLOCKED.txt 없음' (-not (Test-Path (Join-Path $State 'BLOCKED.txt')))
Check '결과 파일 없음' (-not (Test-Path (Join-Path $Work $ResN)))
Check '첫 시도 --session-id 사용' ($av -match '--session-id')
