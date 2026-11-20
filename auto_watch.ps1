# KTS 자동 확인 실행기 (10분마다 작업 스케줄러가 실행)
#  1) 남은 미커밋 변경은 '보관 커밋'으로 저장하고, 원격 최신 지시서를 충돌 없이 받아온다
#  2) 결과 파일(CLAUDE_RESULT_*.md)이 아직 없는 CLAUDE_TASK_*.md 중 '가장 최근' 지시서를 고른다
#  3) claude --dangerously-skip-permissions -p "..." 로 무인 실행 (권한 대기로 읽기 전용 종료되지 않음)
#  4) 바뀐 것이 있으면 git commit · git push (실패하면 rebase 후 1회 재시도)
# 등록/해제: setup_autowatch.bat (해제: setup_autowatch.bat remove, 즉시 1회: setup_autowatch.bat run)
# 기록: %LOCALAPPDATA%\KTS_autowatch\autowatch.log
#   마지막 실행 시각: %LOCALAPPDATA%\KTS_autowatch\LAST_RUN.txt
#   시도 초과로 멈춘 지시서: %LOCALAPPDATA%\KTS_autowatch\BLOCKED.txt
#
# [2026-11-20 WATCHFIX 보강 — 한도(5시간 limit) 안전장치]
#  S1 한도 감지: 출력에 usage limit·429 등 신호가 있으면 시도 횟수({task}.try)를 되돌리고 BLOCKED 처리 안 함 · RATE_HIT.log 1줄
#  S2 한도 대기 게이트: RATE_HIT.txt 의 resetAt 전이면 이번 회차 건너뜀, 지났거나 리셋 시각을 못 읽었으면 10분마다 그대로 재시도
#  S3 리셋 시각 읽기: "reset at 3:00 PM" · "resets 5am" · "limit reached|<epoch>" → 7시간 넘게 뒤면 오독으로 보고 무시
#  S4 이어서 실행: 첫 시도에 --session-id 저장 → 다음 시도는 --resume <id> / --continue / '이어서' 문구 (재개 실패 시 같은 회차 -p 단독 1회)
#  S5 워치독: claude 를 Start-Process 로 띄워 $MaxRunMinutes(90분) 넘으면 프로세스 트리 종료 · 시도 횟수 안 셈 · 뮤텍스 해제
# 시험용 덮어쓰기(평소엔 비워 둠): $env:KTS_AW_STATEDIR · $env:KTS_AW_MUTEX · $env:KTS_AW_MAXRUNMIN

$ErrorActionPreference = 'Continue'
$Repo     = $PSScriptRoot
$StateDir = Join-Path $env:LOCALAPPDATA 'KTS_autowatch'
if ($env:KTS_AW_STATEDIR) { $StateDir = $env:KTS_AW_STATEDIR }
$Log      = Join-Path $StateDir 'autowatch.log'
$MaxTry   = 3          # 같은 지시서는 최대 3번까지만 시도(실패해도 무한 반복·요금 폭주 방지)
$MaxRunMinutes = 90    # S5: claude 1회 실행 상한(분). 넘으면 강제 종료하고 다음 회차에 이어서 실행
if ($env:KTS_AW_MAXRUNMIN) { $MaxRunMinutes = [double]$env:KTS_AW_MAXRUNMIN }
$MutexName = 'KTS_AutoWatch'
if ($env:KTS_AW_MUTEX) { $MutexName = $env:KTS_AW_MUTEX }
$Branch   = 'main'
New-Item -ItemType Directory -Force $StateDir | Out-Null

# 로그가 5MB를 넘으면 한 번 접어 둔다(무인 실행이 몇 달 쌓여도 안전하게)
if ((Test-Path -LiteralPath $Log) -and ((Get-Item -LiteralPath $Log).Length -gt 5242880)) {
  Move-Item -LiteralPath $Log -Destination ($Log + '.1') -Force
}

function Write-Log([string]$m){
  $line = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '  ' + $m
  Add-Content -Path $Log -Value $line -Encoding UTF8
}

# S1: 한도 걸림 신호
function Test-RateLimit([string]$out){
  if ([string]::IsNullOrWhiteSpace($out)) { return $false }
  $p = '(?i)(usage limit reached|5[- ]hour limit|hit your (?:usage )?limit|reached your (?:usage )?limit|limit (?:will )?reset|rate[_ -]?limit_error|rate[_ -]?limit|429 ?(?:Too Many Requests|too many requests)|quota exceeded|You are out of (?:extra )?usage|Please try again (?:later|in \d+))'
  return ($out -match $p)
}

# S3: 리셋 시각 읽기 (못 읽거나 미덥지 않으면 $null → 10분 재시도로 처리)
function Get-ResetHint([string]$out){
  if ([string]::IsNullOrWhiteSpace($out)) { return $null }
  $now = Get-Date
  # "Claude AI usage limit reached|1763622000" (유닉스 초)
  $e = [regex]::Match($out, '(?i)limit reached\|(\d{10})')
  if ($e.Success) {
    $cand = ([datetime]'1970-01-01Z').AddSeconds([double]$e.Groups[1].Value).ToLocalTime()
    if ($cand -gt $now -and $cand -le $now.AddHours(7)) { return $cand }
    return $null
  }
  # "Your limit will reset at 3:00 PM" · "resets at 15:00" · "reset 2:30pm" · "resets 5am"
  $m = [regex]::Match($out, '(?i)reset(?:s)?(?:\s+(?:at|on))?\s*:?\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm)?')
  if (-not $m.Success) { return $null }
  $h = [int]$m.Groups[1].Value
  $mi = 0
  if ($m.Groups[2].Success) { $mi = [int]$m.Groups[2].Value }
  $ap = $m.Groups[3].Value.ToLower()
  if ($ap -eq 'pm' -and $h -lt 12) { $h += 12 }
  if ($ap -eq 'am' -and $h -eq 12) { $h = 0 }
  if ($h -gt 23 -or $mi -gt 59) { return $null }
  $cand = Get-Date -Year $now.Year -Month $now.Month -Day $now.Day -Hour $h -Minute $mi -Second 0 -Millisecond 0
  if ($cand -le $now) { $cand = $cand.AddDays(1) }      # 오늘 그 시각이 지났으면 내일
  if ($cand -gt $now.AddHours(7)) { return $null }       # 5시간 한도인데 7시간 뒤는 오독 → 무시(10분 재시도로 처리)
  return $cand
}

# Windows 명령줄 인자 1개를 안전하게 따옴표 처리
function ConvertTo-ArgString([string[]]$list){
  $parts = foreach ($a in $list) {
    if ($a -ne '' -and $a -notmatch '[\s"]') { $a; continue }
    $s = $a -replace '(\\*)"', '$1$1\"'
    $s = $s -replace '(\\+)$', '$1$1'
    '"' + $s + '"'
  }
  return ($parts -join ' ')
}

# S5: claude 를 상한 시간 안에서 실행 (표준출력·오류는 파일로)
function Invoke-Claude([string]$exe, [string[]]$argv, [string]$stem){
  $outF = $stem + '.out.txt'; $errF = $stem + '.err.txt'; $inF = Join-Path $StateDir 'empty_stdin.txt'
  Set-Content -LiteralPath $inF -Value '' -NoNewline -Encoding ASCII
  $r = [pscustomobject]@{ Out = ''; Code = -1; TimedOut = $false; Seconds = 0 }
  $t0 = Get-Date
  try {
    $p = Start-Process -FilePath $exe -ArgumentList (ConvertTo-ArgString $argv) -WorkingDirectory $Repo -NoNewWindow -PassThru `
         -RedirectStandardOutput $outF -RedirectStandardError $errF -RedirectStandardInput $inF
  } catch { $r.Out = '실행 실패: ' + $_.Exception.Message; return $r }
  $null = $p.Handle   # ExitCode 를 읽으려면 핸들을 먼저 잡아 둔다(PS 5.1)
  if (-not $p.WaitForExit([int]($MaxRunMinutes * 60000))) {
    $r.TimedOut = $true
    & taskkill.exe /T /F /PID $p.Id 2>&1 | Out-Null
    Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
    $null = $p.WaitForExit(15000)
  }
  else { $p.WaitForExit(); $r.Code = $p.ExitCode }
  $r.Seconds = [int]((Get-Date) - $t0).TotalSeconds
  $o = ''; $e = ''
  if (Test-Path -LiteralPath $outF) { $o = Get-Content -LiteralPath $outF -Raw -Encoding UTF8 }
  if (Test-Path -LiteralPath $errF) { $e = Get-Content -LiteralPath $errF -Raw -Encoding UTF8 }
  $r.Out = ([string]$o + "`n" + [string]$e).Trim()
  return $r
}

# 동시에 두 번 돌지 않게(이전 실행이 아직 클로드 작업 중이면 이번 회차는 건너뜀)
$mutex = New-Object System.Threading.Mutex($false, $MutexName)
if (-not $mutex.WaitOne(0)) { Write-Log '이전 실행이 아직 진행 중 → 건너뜀'; exit 0 }

try {
  Set-Location -LiteralPath $Repo
  Set-Content -LiteralPath (Join-Path $StateDir 'LAST_RUN.txt') -Value (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -Encoding UTF8

  # ---------- S2) 한도 대기 게이트 (리셋 예상 시각 전이면 이번 회차는 건너뜀) ----------
  $rateFile = Join-Path $StateDir 'RATE_HIT.txt'
  if (Test-Path -LiteralPath $rateFile) {
    $w = $null
    try { $w = Get-Content -LiteralPath $rateFile -Raw -Encoding UTF8 | ConvertFrom-Json } catch { Write-Log 'RATE_HIT.txt 판독 실패 → 무시하고 진행'; Remove-Item -LiteralPath $rateFile -Force -ErrorAction SilentlyContinue }
    if ($w -and $w.resetAt) {
      $resetAt = $null
      if ($w.resetAt -is [datetime]) { $resetAt = $w.resetAt }
      else { try { $resetAt = [datetime]::Parse([string]$w.resetAt, [Globalization.CultureInfo]::InvariantCulture) } catch {} }
      if ($resetAt -and (Get-Date) -lt $resetAt) {
        Write-Log ("한도 대기 중 → 리셋 예상 " + $resetAt.ToString('MM-dd HH:mm') + " 까지 건너뜀 (" + $w.task + ")")
        exit 0
      }
      Write-Log ("한도 리셋 시각 지남(" + [string]$w.resetAt + ") → 이어서 재시도")
    }
  }

  # ---------- 0) claude 실행 파일 ----------
  $claude = (Get-Command claude -ErrorAction SilentlyContinue).Source
  if (-not $claude) { $claude = Join-Path $env:USERPROFILE '.local\bin\claude.exe' }
  if (-not (Test-Path -LiteralPath $claude)) { Write-Log "claude 실행 파일을 찾지 못함: $claude"; exit 1 }

  # ---------- 1) 남은 미커밋 변경은 '보관 커밋'으로 저장 (건너뛰지 않아 풀이 막히지 않게) ----------
  $dirty = git status --porcelain -uno 2>$null
  if ($dirty) {
    git add -A 2>&1 | Out-Null
    git commit -m ("auto: 이전 실행 잔여 변경 보관 " + (Get-Date -Format 'MM-dd HH:mm')) 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { Write-Log '남아 있던 미커밋 변경을 보관 커밋으로 저장하고 계속 진행' }
    else { Write-Log '남은 변경을 커밋하지 못해 이번 회차는 건너뜀'; exit 0 }
  }

  # ---------- 2) 최신 지시서 받기 (충돌 없이) ----------
  $fetch = git fetch origin $Branch 2>&1 | Out-String
  if ($LASTEXITCODE -ne 0) {
    Write-Log ('기본 fetch 실패 → 얕은 fetch로 재시도: ' + ($fetch.Trim() -replace '\s+', ' '))
    $fetch = git fetch --depth 1 origin $Branch 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
      Write-Log ('git fetch 실패(네트워크·용량): ' + ($fetch.Trim() -replace '\s+', ' '))
      exit 1
    }
  }

  $ahead  = [int](git rev-list --count "origin/$Branch..HEAD" 2>$null)
  $behind = [int](git rev-list --count "HEAD..origin/$Branch" 2>$null)

  if ($behind -gt 0) {
    if ($ahead -eq 0) {
      # 로컬에 앞선 커밋이 없으면 그대로 원격 기준으로 맞춘다(충돌 자체가 생길 수 없음)
      git reset --hard "origin/$Branch" 2>&1 | Out-Null
      if ($LASTEXITCODE -eq 0) { Write-Log "원격 최신으로 맞춤 ($behind 커밋·로컬 앞선 커밋 없음)" }
      else { Write-Log 'git reset --hard 실패'; exit 1 }
    }
    else {
      # 로컬에 아직 못 올린 커밋이 있으면 그 위에 원격 최신을 얹는다
      $reb = git pull --rebase --autostash origin $Branch 2>&1 | Out-String
      if ($LASTEXITCODE -eq 0) {
        Write-Log "rebase 완료 (원격 $behind 커밋 위에 로컬 $ahead 커밋)"
      }
      else {
        git rebase --abort 2>&1 | Out-Null
        $patchDir = Join-Path $StateDir 'patches'
        New-Item -ItemType Directory -Force $patchDir | Out-Null
        git format-patch "origin/$Branch" -o $patchDir 2>&1 | Out-Null
        git reset --hard "origin/$Branch" 2>&1 | Out-Null
        Write-Log ('rebase 충돌 → 미푸시 커밋을 patches 폴더에 보존하고 원격 기준으로 재설정: ' + $patchDir)
      }
    }
  }

  # ---------- 3) 실행할 지시서 고르기 (결과 파일이 없는 것 중 가장 최근) ----------
  $cands = @()
  foreach ($f in (Get-ChildItem -LiteralPath $Repo -Filter 'CLAUDE_TASK_*.md' -File)) {
    $resName = $f.Name -replace '^CLAUDE_TASK_', 'CLAUDE_RESULT_'
    if (Test-Path -LiteralPath (Join-Path $Repo $resName)) { continue }

    $tryFile = Join-Path $StateDir ($f.Name + '.try')
    $tries = 0
    if (Test-Path -LiteralPath $tryFile) { $tries = [int]((Get-Content -LiteralPath $tryFile -Raw).Trim()) }

    if ($tries -ge $MaxTry) {
      $blocked = Join-Path $StateDir ($f.Name + '.blocked')
      if (-not (Test-Path -LiteralPath $blocked)) {
        Set-Content -LiteralPath $blocked -Value (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -Encoding UTF8
        Add-Content -Path (Join-Path $StateDir 'BLOCKED.txt') -Value ("$((Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))  $f.Name : $MaxTry 번 시도 후 결과 파일 없음 · 직접 확인 필요") -Encoding UTF8
      }
      continue
    }

    $dm = [regex]::Match($f.Name, '\d{8}')
    $dateKey = '00000000'
    if ($dm.Success) { $dateKey = $dm.Value }
    $cands += [pscustomobject]@{
      Name    = $f.Name
      Result  = $resName
      DateKey = $dateKey
      Time    = $f.LastWriteTime
      Tries   = $tries
    }
  }

  # ---------- 3-2) 실행 순서 (CLAUDE_QUEUE.txt 우선) ----------
  # git pull 직후에는 날짜가 같은 지시서들의 수정시각이 같아져 '가장 최근' 정렬이 뒤섞인다.
  # 저장소에 CLAUDE_QUEUE.txt 가 있으면 그 순서를 따르고, 큐에 없는 지시서는 기존 정렬(최근순)로 뒤에 붙인다.
  $byRecent = @($cands |
    Sort-Object -Property @{ Expression = { $_.DateKey }; Descending = $true }, @{ Expression = { $_.Time }; Descending = $true })
  $queueFile = Join-Path $Repo 'CLAUDE_QUEUE.txt'
  $ordered = @()
  if (Test-Path -LiteralPath $queueFile) {
    foreach ($line in (Get-Content -LiteralPath $queueFile -Encoding UTF8)) {
      $name = $line.Trim()
      if (-not $name -or $name.StartsWith('#')) { continue }
      $hit = $cands | Where-Object { $_.Name -eq $name } | Select-Object -First 1
      if ($hit) { $ordered += $hit }
    }
    foreach ($c in $byRecent) {
      if (-not ($ordered | Where-Object { $_.Name -eq $c.Name })) { $ordered += $c }
    }
  }
  else { $ordered = $byRecent }

  $todo = $ordered | Select-Object -First 1
  if (-not $todo) { exit 0 }   # 할 일 없음(모든 지시서에 결과 파일이 있거나 시도 초과) → 조용히 종료

  $task   = $todo.Name
  $result = $todo.Result
  $tryFile = Join-Path $StateDir ($task + '.try')
  Set-Content -LiteralPath $tryFile -Value ($todo.Tries + 1) -Encoding UTF8

  # ---------- S4) 이어서 실행 준비 ----------
  $sessFile   = Join-Path $StateDir ($task + '.session')
  $resumeFlag = Join-Path $StateDir ($task + '.resume')
  $help = ''
  try { $help = & $claude --help 2>&1 | Out-String } catch {}
  $hasSessId  = $help -match '--session-id'
  $hasResume  = $help -match '--resume'
  $hasContinue = $help -match '--continue'
  $isResume = (Test-Path -LiteralPath $sessFile) -or (Test-Path -LiteralPath $resumeFlag)

  $prompt = "$task 읽고 실행해 줘. 권한은 전부 자동 승인 상태로 열려 있어. 읽기 전용으로 끝내지 말고, 지시서에 적힌 파일 생성·수정·빌드·검증까지 실제로 끝낸 뒤 결과를 $result 에 정리하고 git add -A, git commit, git push origin $Branch 까지 마쳐 줘."
  $resumeText = "이전 실행이 중간에 끊겼습니다(한도·중단). 이미 만든 파일·이미 끝낸 과업은 다시 만들지 말고, ① 지금 저장소 상태를 먼저 확인하고 ② 남은 부분만 이어서 끝낸 뒤 ③ 결과 보고서 맨 위에 `"이어서 실행(앞 실행 산출물 승계)`" 이라고 적고 git add -A → commit → push origin $Branch 까지 마쳐 주세요."
  $sessArgs = @(); $mode = '처음'
  if ($isResume) {
    $sid = ''
    if (Test-Path -LiteralPath $sessFile) { $sid = (Get-Content -LiteralPath $sessFile -Raw).Trim() }
    if ($hasResume -and $sid) { $sessArgs = @('--resume', $sid); $mode = "이어서(--resume $sid)" }
    elseif ($hasContinue) { $sessArgs = @('--continue'); $mode = '이어서(--continue)' }
    else { $mode = '이어서(문구만)' }
    $prompt = $resumeText + " 원래 지시: " + $prompt
  }
  else {
    if ($hasSessId) {
      $sid = [guid]::NewGuid().ToString()
      Set-Content -LiteralPath $sessFile -Value $sid -Encoding ASCII
      $sessArgs = @('--session-id', $sid); $mode = "처음(--session-id $sid)"
    }
    else { Set-Content -LiteralPath $resumeFlag -Value (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -Encoding UTF8 }
  }

  Write-Log "$task 실행 시작 (시도 $($todo.Tries + 1)/$MaxTry · 권한 자동 승인 · $mode)"
  $stem = Join-Path $StateDir $task
  $perm = @('--dangerously-skip-permissions')
  $run = Invoke-Claude $claude ($perm + $sessArgs + @('-p', $prompt)) $stem
  if (-not $run.TimedOut -and $run.Code -ne 0 -and $run.Out -match 'unknown option|unrecognized|invalid option') {
    Write-Log '이 클로드 버전이 --dangerously-skip-permissions 를 받지 않음 → --permission-mode bypassPermissions 로 재시도'
    $perm = @('--permission-mode', 'bypassPermissions')
    $run = Invoke-Claude $claude ($perm + $sessArgs + @('-p', $prompt)) $stem
  }
  # S4-4) --resume / --continue 가 바로 실패하면(세션 없음 등) 같은 회차에 -p 단독으로 1회만
  if ($sessArgs.Count -and $isResume -and -not $run.TimedOut -and $run.Code -ne 0 -and
      -not (Test-RateLimit $run.Out) -and ($run.Seconds -lt 120 -or $run.Out -match '(?i)no conversation|session.{0,40}not found|not a valid|invalid session|could not (?:find|resume)')) {
    Write-Log ("재개 실패(" + $mode + ") → 같은 회차에 -p 단독으로 1회 재시도: " + (($run.Out -replace '\s+', ' ').Trim() | ForEach-Object { if ($_.Length -gt 200) { $_.Substring(0, 200) } else { $_ } }))
    Remove-Item -LiteralPath $sessFile -Force -ErrorAction SilentlyContinue
    Set-Content -LiteralPath $resumeFlag -Value (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -Encoding UTF8
    $run = Invoke-Claude $claude ($perm + @('-p', $prompt)) $stem
  }
  $out = $run.Out; $code = $run.Code
  Add-Content -Path ($stem + '.history.txt') -Value ("===== " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + " 코드 $code`r`n" + $out) -Encoding UTF8
  if ($run.TimedOut) { Write-Log "$task 실행 상한 초과로 종료($MaxRunMinutes 분) · 시도 횟수 안 셈 · 다음 회차에 이어서" }
  else { Write-Log "$task 클로드 종료 (코드 $code)" }

  # ---------- S1) 한도 걸림이면 시도 횟수를 되돌린다 ----------
  $resultNow = Test-Path -LiteralPath (Join-Path $Repo $result)
  $rateHit = (-not $resultNow) -and (-not $run.TimedOut) -and (Test-RateLimit $out) -and ($code -ne 0 -or $out.Length -lt 400)
  if ($rateHit -or $run.TimedOut) {
    if ($todo.Tries -gt 0) { Set-Content -LiteralPath $tryFile -Value $todo.Tries -Encoding UTF8 }
    else { Remove-Item -LiteralPath $tryFile -Force -ErrorAction SilentlyContinue }
  }
  if ($rateHit) {
    $mm = [regex]::Match($out, '(?is).{0,60}(usage limit|hour limit|your (?:usage )?limit|limit (?:will )?reset|rate[_ -]?limit|429|quota exceeded|out of (?:extra )?usage|try again).{0,140}')
    $said = ($mm.Value -replace '\s+', ' ').Trim()
    if (-not $said) { $said = ($out -replace '\s+', ' ').Trim() }
    if ($said.Length -gt 200) { $said = $said.Substring(0, 200) }
    $reset = Get-ResetHint $out
    $resetTxt = '못 읽음(10분 뒤 재시도)'
    if ($reset) { $resetTxt = $reset.ToString('yyyy-MM-dd HH:mm') }
    Add-Content -Path (Join-Path $StateDir 'RATE_HIT.log') -Value ((Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + ' · ' + $task + ' · ' + $said + ' · ' + $resetTxt) -Encoding UTF8
    if ($reset) {
      $j = [ordered]@{ task = $task; hitAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'); resetAt = $reset.ToString('yyyy-MM-ddTHH:mm:ss') } | ConvertTo-Json
      Set-Content -LiteralPath $rateFile -Value $j -Encoding UTF8
    }
    else { Remove-Item -LiteralPath $rateFile -Force -ErrorAction SilentlyContinue }
    Write-Log "$task 한도 걸림 → 시도 횟수 안 셈 · 리셋 예상 $resetTxt"
  }
  elseif (-not $run.TimedOut) { Remove-Item -LiteralPath $rateFile -Force -ErrorAction SilentlyContinue }

  # ---------- 4) 커밋·푸시 ----------
  $changes = git status --porcelain
  if ($changes) {
    git add -A 2>&1 | Out-Null
    git commit -m "auto: $task 자동 실행 결과" 2>&1 | Out-Null
  }
  $ahead2 = [int](git rev-list --count "origin/$Branch..HEAD" 2>$null)
  if ($ahead2 -gt 0) {
    $push = git push origin HEAD 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
      git fetch origin $Branch 2>&1 | Out-Null
      git rebase --autostash "origin/$Branch" 2>&1 | Out-Null
      if ($LASTEXITCODE -ne 0) { git rebase --abort 2>&1 | Out-Null }
      $push = git push origin HEAD 2>&1 | Out-String
      if ($LASTEXITCODE -ne 0) { Write-Log ('git push 실패: ' + ($push.Trim() -replace '\s+', ' ')) }
      else { Write-Log "git push 재시도 성공 ($ahead2 커밋)" }
    }
    else { Write-Log "git push 완료 ($ahead2 커밋)" }
  }

  if (Test-Path -LiteralPath (Join-Path $Repo $result)) {
    Write-Log "$task 완료 → $result 생성됨"
    Remove-Item -LiteralPath $tryFile, $sessFile, $resumeFlag, $rateFile -Force -ErrorAction SilentlyContinue
  }
  else { Write-Log "$task : 결과 파일 $result 이 아직 없음 (다음 회차 재시도)" }
}
finally {
  $mutex.ReleaseMutex() | Out-Null
}
