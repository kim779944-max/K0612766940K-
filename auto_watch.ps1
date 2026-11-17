# KTS 자동 확인 실행기 (10분마다 작업 스케줄러가 실행)
#  1) 저장소에서 git pull
#  2) 결과 파일(CLAUDE_RESULT_*.md)이 아직 없는 지시서(CLAUDE_TASK_*.md)를 찾으면
#  3) claude --permission-mode auto -p "..." 로 실행 → 바뀐 것이 있으면 git commit · git push
# 등록/해제: setup_autowatch.bat (해제: setup_autowatch.bat remove)
# 기록: %LOCALAPPDATA%\KTS_autowatch\autowatch.log

$ErrorActionPreference = 'Continue'
$Repo     = $PSScriptRoot
$StateDir = Join-Path $env:LOCALAPPDATA 'KTS_autowatch'
$Log      = Join-Path $StateDir 'autowatch.log'
$MaxTry   = 2          # 같은 지시서는 최대 2번까지만 시도(실패해도 무한 반복·요금 폭주 방지)
New-Item -ItemType Directory -Force $StateDir | Out-Null

function Write-Log([string]$m){
  $line = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '  ' + $m
  Add-Content -Path $Log -Value $line -Encoding UTF8
}

# 동시에 두 번 돌지 않게(이전 실행이 아직 클로드 작업 중이면 이번 회차는 건너뜀)
$mutex = New-Object System.Threading.Mutex($false, 'KTS_AutoWatch')
if (-not $mutex.WaitOne(0)) { Write-Log '이전 실행이 아직 진행 중 → 건너뜀'; exit 0 }

try {
  Set-Location -LiteralPath $Repo

  $claude = (Get-Command claude -ErrorAction SilentlyContinue).Source
  if (-not $claude) { $claude = Join-Path $env:USERPROFILE '.local\bin\claude.exe' }
  if (-not (Test-Path -LiteralPath $claude)) { Write-Log "claude 실행 파일을 찾지 못함: $claude"; exit 1 }

  # 사람이 고치던 파일이 있으면 손대지 않는다(추적 중인 파일 기준)
  $dirty = git status --porcelain --untracked-files=no
  if ($dirty) { Write-Log '작업 폴더에 커밋 안 된 수정이 있어 이번 회차는 건너뜀'; exit 0 }

  $pull = git pull --ff-only 2>&1 | Out-String
  if ($LASTEXITCODE -ne 0) { Write-Log ('git pull 실패: ' + $pull.Trim()); exit 1 }

  # 결과 파일이 없는 지시서 찾기 (오래된 것부터 한 번에 하나)
  $todo = Get-ChildItem -LiteralPath $Repo -Filter 'CLAUDE_TASK_*.md' -File |
    Sort-Object LastWriteTime |
    Where-Object { -not (Test-Path -LiteralPath (Join-Path $Repo ($_.Name -replace '^CLAUDE_TASK_', 'CLAUDE_RESULT_'))) } |
    Select-Object -First 1
  if (-not $todo) { exit 0 }   # 할 일 없음(조용히 종료)

  $task   = $todo.Name
  $result = $task -replace '^CLAUDE_TASK_', 'CLAUDE_RESULT_'
  $tryFile = Join-Path $StateDir ($task + '.try')
  $tries = 0; if (Test-Path -LiteralPath $tryFile) { $tries = [int]((Get-Content -LiteralPath $tryFile -Raw).Trim()) }
  if ($tries -ge $MaxTry) { Write-Log "$task : $MaxTry 번 시도했지만 결과 파일이 없어 더 이상 자동 실행하지 않음(직접 확인 필요)"; exit 0 }
  Set-Content -LiteralPath $tryFile -Value ($tries + 1)

  Write-Log "$task 실행 시작 (시도 $($tries + 1)/$MaxTry)"
  $prompt = "$task 읽고 실행해 줘. 끝나면 결과를 $result 에 정리하고 git add, git commit, git push origin main 까지 해 줘."
  $out = & $claude --permission-mode auto -p $prompt 2>&1 | Out-String
  Add-Content -Path (Join-Path $StateDir ($task + '.out.txt')) -Value $out -Encoding UTF8
  Write-Log "$task 클로드 종료 (코드 $LASTEXITCODE)"

  # 클로드가 커밋·푸시를 못 했으면 여기서 마무리
  $changes = git status --porcelain
  if ($changes) {
    git add -A | Out-Null
    git commit -m "auto: $task 자동 실행 결과" | Out-Null
  }
  $ahead = git rev-list --count '@{u}..HEAD' 2>$null
  if ([int]$ahead -gt 0) {
    $push = git push origin HEAD 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { Write-Log ('git push 실패: ' + $push.Trim()) } else { Write-Log "git push 완료 ($ahead 커밋)" }
  }
  if (Test-Path -LiteralPath (Join-Path $Repo $result)) { Write-Log "$task 완료 → $result 생성됨" }
  else { Write-Log "$task : 결과 파일 $result 이 아직 없음" }
}
finally {
  $mutex.ReleaseMutex() | Out-Null
}
