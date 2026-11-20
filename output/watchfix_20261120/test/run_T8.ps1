# T8 회귀 R1~R8 (기존 동작 그대로인지)
. (Join-Path $PSScriptRoot '_lib.ps1')
'== T8 ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
function LogHas([string]$p) { (Get-Content (Join-Path $State 'autowatch.log') -Raw -Encoding UTF8) -match $p }

'-- R1 뮤텍스: 1번 실행이 도는 중(가짜 claude 대기)에 2번 실행'
New-TestEnv
$env:KTS_AW_STATEDIR = $State; $env:KTS_AW_MUTEX = 'KTS_AW_TEST'; $env:KTS_AW_MAXRUNMIN = '0.5'; $env:KTS_SHIM_MODE = 'hang'; $env:KTS_SHIM_ARGV = $Argv; $env:KTS_SHIM_NOSESS = ''
$oldPath = $env:PATH; $env:PATH = $Bin + ';' + $env:PATH
$p1 = Start-Process powershell -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + (Join-Path $Work 'auto_watch.ps1') + '"') -PassThru -WindowStyle Hidden
$env:PATH = $oldPath
Start-Sleep 8
Invoke-AW 'ok'
$p1.WaitForExit()
Show-LogTail 5
Check 'R1 두 번째 실행 건너뜀' (LogHas '이전 실행이 아직 진행 중 → 건너뜀')

'-- R2 미커밋 변경(추적 파일 수정) → 보관 커밋 후 계속'
New-TestEnv
Set-Content (Join-Path $Work 'dummy.txt') 'v2-dirty' -Encoding UTF8
Invoke-AW 'r429'
Show-LogTail 4
$g = git -C $Work log --oneline -3 | Out-String
'  ' + ($g.Trim() -replace "`r?`n", ' / ')
Check 'R2 보관 커밋 생성' ($g -match 'auto: 이전 실행 잔여 변경 보관')
Check 'R2 로그 1줄' (LogHas '남아 있던 미커밋 변경을 보관 커밋으로 저장하고 계속 진행')

'-- R3-a 원격만 앞섬 → reset --hard'
New-TestEnv
Set-Content (Join-Path $Other 'remote1.txt') 'r' -Encoding UTF8; git -C $Other add -A; git -C $Other commit -q -m 'remote1'; git -C $Other push -q origin main 2>&1 | Out-Null
Invoke-AW 'r429'
Check 'R3-a 원격 최신으로 맞춤' (LogHas '원격 최신으로 맞춤 \(1 커밋')
'-- R3-b 로컬·원격 둘 다 앞섬 → pull --rebase'
Set-Content (Join-Path $Work 'local1.txt') 'l' -Encoding UTF8; git -C $Work add -A; git -C $Work commit -q -m 'local1'
git -C $Other pull -q origin main 2>&1 | Out-Null
Set-Content (Join-Path $Other 'remote2.txt') 'r' -Encoding UTF8; git -C $Other add -A; git -C $Other commit -q -m 'remote2'; git -C $Other push -q origin main 2>&1 | Out-Null
Invoke-AW 'r429'
Check 'R3-b rebase 완료' (LogHas 'rebase 완료 \(원격 1 커밋 위에 로컬 1 커밋\)')
Check 'R3-b 로컬 커밋이 원격에 올라감' ((git -C $Origin log --oneline main | Out-String) -match 'local1')
'-- R3-c 로컬만 앞섬 → 맞추기 없이 진행, 4) 에서 푸시'
Set-Content (Join-Path $Work 'local2.txt') 'l' -Encoding UTF8; git -C $Work add -A; git -C $Work commit -q -m 'local2'
Invoke-AW 'r429'
Show-LogTail 4
Check 'R3-c 로컬 커밋 푸시' ((git -C $Origin log --oneline main | Out-String) -match 'local2')

'-- R4 큐 순서: 큐 첫 줄(TEST) 1개만 → 끝나면 다음(OLD)'
New-TestEnv
Invoke-AW 'ok'
$a1 = @(Get-Content $Argv -Encoding UTF8)
Invoke-AW 'ok'
$a2 = @(Get-Content $Argv -Encoding UTF8)
'  1회차 argv 줄 수 ' + $a1.Count + ' · 2회차 누적 ' + $a2.Count
Check 'R4 1회차는 TEST 하나만' ($a1.Count -eq 1 -and $a1[0] -match 'CLAUDE_TASK_20991231_TEST' -and $a1[0] -notmatch '20991230_OLD')
Check 'R4 2회차는 OLD' ($a2.Count -eq 2 -and $a2[1] -match 'CLAUDE_TASK_20991230_OLD')

'-- R5 --dangerously-skip-permissions 거부 → --permission-mode bypassPermissions 재시도'
New-TestEnv
Invoke-AW 'badflag'
$a = @(Get-Content $Argv -Encoding UTF8)
$a | ForEach-Object { '    argv| ' + $_.Substring(0, [Math]::Min(110, $_.Length)) }
Check 'R5 1번째 --dangerously-skip-permissions' ($a[0] -match '--dangerously-skip-permissions')
Check 'R5 2번째 --permission-mode | bypassPermissions' ($a.Count -eq 2 -and $a[1] -match '--permission-mode \| bypassPermissions')
Check 'R5 로그' (LogHas 'bypassPermissions 로 재시도')

'-- R6 결과 파일 생기면 try 삭제'
Check 'R6 try 삭제(R5 회차 완료 후)' ((Get-Try) -eq '(없음)' -and (Test-Path (Join-Path $Work $ResN)))

'-- R7 로그 5MB 접기 · LAST_RUN.txt 갱신'
$lg = Join-Path $State 'autowatch.log'
$fs = [IO.File]::Open($lg, 'Append'); $fs.SetLength(6MB); $fs.Close()
Start-Sleep 1
$before = (Get-Item (Join-Path $State 'LAST_RUN.txt')).LastWriteTime
Invoke-AW 'ok'
Check 'R7 autowatch.log.1 생김(6MB)' ((Test-Path ($lg + '.1')) -and (Get-Item ($lg + '.1')).Length -ge 6MB)
Check 'R7 새 autowatch.log 작음' ((Get-Item $lg).Length -lt 100KB)
Check 'R7 LAST_RUN.txt 갱신' ((Get-Item (Join-Path $State 'LAST_RUN.txt')).LastWriteTime -gt $before)

'-- R8 실행 도중 다른 PC 가 먼저 푸시 → push 실패 → rebase 1회 → 재푸시'
New-TestEnv
$env:KTS_SHIM_PUSHOTHER = $Other
Invoke-AW 'ok'
$env:KTS_SHIM_PUSHOTHER = ''
Show-LogTail 4
$ol = git -C $Origin log --oneline main | Out-String
Check 'R8 git push 재시도 성공' (LogHas 'git push 재시도 성공')
Check 'R8 원격에 결과 커밋·다른 PC 커밋 둘 다' (($ol -match 'auto: CLAUDE_TASK_20991231_TEST.md') -and ($ol -match 'other-pc'))

'-- 추가: S4-4 재개 실패(--resume 세션 없음) → 같은 회차 -p 단독 1회'
New-TestEnv
Set-Content (Join-Path $State ($TaskN + '.session')) ([guid]::NewGuid().ToString()) -Encoding ASCII
Invoke-AW 'resumefail'
$a = @(Get-Content $Argv -Encoding UTF8)
Show-LogTail 4
Check 'S4-4 1번째 --resume · 2번째 -p 단독' ($a.Count -eq 2 -and $a[0] -match '--resume' -and $a[1] -notmatch '--resume|--continue' -and $a[1] -match '이전 실행이 중간에 끊겼습니다')
Check 'S4-4 로그' (LogHas '재개 실패')
'-- 추가: --session-id·--resume·--continue 미지원 claude → .resume 표시 파일 · 다음 시도는 이어서 문구'
New-TestEnv
Invoke-AW 'r429' -NoSess
$m1 = Test-Path (Join-Path $State ($TaskN + '.resume'))
Invoke-AW 'ok' -NoSess
$a = @(Get-Content $Argv -Encoding UTF8)
Check 'session-id 미지원 → .resume 표시' $m1
Check '다음 시도 이어서 문구만(--resume/--continue 미지원 shim)' ($a[1] -notmatch '--resume|--continue' -and $a[1] -match '이전 실행이 중간에 끊겼습니다')
