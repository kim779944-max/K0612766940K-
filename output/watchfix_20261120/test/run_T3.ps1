# T3 resetAt 을 1분 전으로 고친 뒤 3회차 → '한도 리셋 시각 지남 → 이어서 재시도' · argv 에 --resume/--continue/이어서 문구
. (Join-Path $PSScriptRoot '_lib.ps1')
'== T3 ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
$rt = Join-Path $State 'RATE_HIT.txt'
$j = Get-Content $rt -Raw | ConvertFrom-Json
$j.resetAt = (Get-Date).AddMinutes(-1).ToString('yyyy-MM-ddTHH:mm:ss')
Set-Content $rt ($j | ConvertTo-Json) -Encoding UTF8
'  RATE_HIT.txt 수정: ' + ((Get-Content $rt -Raw) -replace '\s+', ' ')
Invoke-AW 'ok'
Show-LogTail 6
$a = @(Get-Content $Argv -Encoding UTF8)[-1]
'  마지막 argv: ' + $a
$log = Get-Content (Join-Path $State 'autowatch.log') -Raw -Encoding UTF8
Check '리셋 시각 지남 로그' ($log -match '한도 리셋 시각 지남.*이어서 재시도')
Check 'argv 에 --resume <세션>' ($a -match '--resume \| [0-9a-f-]{36}')
Check 'argv 에 이어서 문구' ($a -match '이전 실행이 중간에 끊겼습니다')
Check '결과 파일 생성 → try·session·RATE_HIT.txt 삭제' ((Test-Path (Join-Path $Work $ResN)) -and ((Get-Try) -eq '(없음)') -and -not (Test-Path $rt) -and -not (Test-Path (Join-Path $State ($TaskN + '.session'))))
