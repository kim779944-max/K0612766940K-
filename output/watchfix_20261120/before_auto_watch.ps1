# KTS 자동 확인 실행기 (10분마다 작업 스케줄러가 실행)
#  1) 남은 미커밋 변경은 '보관 커밋'으로 저장하고, 원격 최신 지시서를 충돌 없이 받아온다
#  2) 결과 파일(CLAUDE_RESULT_*.md)이 아직 없는 CLAUDE_TASK_*.md 중 '가장 최근' 지시서를 고른다
#  3) claude --dangerously-skip-permissions -p "..." 로 무인 실행 (권한 대기로 읽기 전용 종료되지 않음)
#  4) 바뀐 것이 있으면 git commit · git push (실패하면 rebase 후 1회 재시도)
# 등록/해제: setup_autowatch.bat (해제: setup_autowatch.bat remove, 즉시 1회: setup_autowatch.bat run)
# 기록: %LOCALAPPDATA%\KTS_autowatch\autowatch.log
#   마지막 실행 시각: %LOCALAPPDATA%\KTS_autowatch\LAST_RUN.txt
#   시도 초과로 멈춘 지시서: %LOCALAPPDATA%\KTS_autowatch\BLOCKED.txt

$ErrorActionPreference = 'Continue'
$Repo     = $PSScriptRoot
$StateDir = Join-Path $env:LOCALAPPDATA 'KTS_autowatch'
$Log      = Join-Path $StateDir 'autowatch.log'
$MaxTry   = 3          # 같은 지시서는 최대 3번까지만 시도(실패해도 무한 반복·요금 폭주 방지)
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

# 동시에 두 번 돌지 않게(이전 실행이 아직 클로드 작업 중이면 이번 회차는 건너뜀)
$mutex = New-Object System.Threading.Mutex($false, 'KTS_AutoWatch')
if (-not $mutex.WaitOne(0)) { Write-Log '이전 실행이 아직 진행 중 → 건너뜀'; exit 0 }

try {
  Set-Location -LiteralPath $Repo
  Set-Content -LiteralPath (Join-Path $StateDir 'LAST_RUN.txt') -Value (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -Encoding UTF8

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

  Write-Log "$task 실행 시작 (시도 $($todo.Tries + 1)/$MaxTry · 권한 자동 승인)"
  $prompt = "$task 읽고 실행해 줘. 권한은 전부 자동 승인 상태로 열려 있어. 읽기 전용으로 끝내지 말고, 지시서에 적힌 파일 생성·수정·빌드·검증까지 실제로 끝낸 뒤 결과를 $result 에 정리하고 git add -A, git commit, git push origin $Branch 까지 마쳐 줘."
  $out = & $claude --dangerously-skip-permissions -p $prompt 2>&1 | Out-String
  $code = $LASTEXITCODE
  $badFlag = $false
  if ($code -ne 0) {
    if ($out -match 'unknown option|unrecognized|invalid option') { $badFlag = $true }
  }
  if ($badFlag) {
    Write-Log '이 클로드 버전이 --dangerously-skip-permissions 를 받지 않음 → --permission-mode bypassPermissions 로 재시도'
    $out = & $claude --permission-mode bypassPermissions -p $prompt 2>&1 | Out-String
    $code = $LASTEXITCODE
  }
  Add-Content -Path (Join-Path $StateDir ($task + '.out.txt')) -Value $out -Encoding UTF8
  Write-Log "$task 클로드 종료 (코드 $code)"

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
    Remove-Item -LiteralPath $tryFile -Force -ErrorAction SilentlyContinue
  }
  else { Write-Log "$task : 결과 파일 $result 이 아직 없음 (다음 회차 재시도)" }
}
finally {
  $mutex.ReleaseMutex() | Out-Null
}
