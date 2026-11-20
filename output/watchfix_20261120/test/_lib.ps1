# 시험 공용 함수 — run_T*.ps1 이 dot-source 한다. 실제 claude·실 저장소·실 상태 폴더는 건드리지 않는다.
#  시험 폴더: %TEMP%\aw_test  (origin.git = 가짜 원격, work = auto_watch 가 도는 사본, other = 원격에 커밋 넣는 다른 PC 역할)
#  상태 폴더: %TEMP%\aw_test\state  ·  뮤텍스: KTS_AW_TEST  ·  가짜 claude: %TEMP%\aw_test\bin\claude.exe
$ErrorActionPreference = 'Continue'
$T      = Join-Path $env:TEMP 'aw_test'
$TestDir = $PSScriptRoot
$PkgDir = Split-Path $TestDir
$Script = Join-Path $PkgDir 'after_auto_watch.ps1'   # 시험 대상(교체 전 보강본)
$Work   = Join-Path $T 'work'
$Other  = Join-Path $T 'other'
$Origin = Join-Path $T 'origin.git'
$State  = Join-Path $T 'state'
$Bin    = Join-Path $T 'bin'
$Argv   = Join-Path $T 'argv.txt'
$TaskN  = 'CLAUDE_TASK_20991231_TEST.md'
$ResN   = 'CLAUDE_RESULT_20991231_TEST.md'

function Build-Shim {
  New-Item -ItemType Directory -Force $Bin | Out-Null
  $exe = Join-Path $Bin 'claude.exe'
  if (Test-Path $exe) { return }
  $src = [IO.File]::ReadAllText((Join-Path $TestDir 'shim\claude_shim.cs'), [Text.Encoding]::UTF8)
  Add-Type -TypeDefinition $src -Language CSharp -OutputAssembly $exe -OutputType ConsoleApplication
}

function New-TestEnv {
  if (Test-Path $Work) { Remove-Item -Recurse -Force $Work, $Other, $Origin, $State -ErrorAction SilentlyContinue }
  Remove-Item $Argv -Force -ErrorAction SilentlyContinue
  New-Item -ItemType Directory -Force $T, $State | Out-Null
  Build-Shim
  git init -q --bare -b main $Origin
  git clone -q $Origin $Work 2>&1 | Out-Null
  Copy-Item $Script (Join-Path $Work 'auto_watch.ps1')
  Set-Content (Join-Path $Work $TaskN) '# 시험 지시서' -Encoding UTF8
  Set-Content (Join-Path $Work 'CLAUDE_TASK_20991230_OLD.md') '# 큐 뒤 지시서' -Encoding UTF8
  Set-Content (Join-Path $Work 'CLAUDE_QUEUE.txt') "# 큐`r`n$TaskN`r`nCLAUDE_TASK_20991230_OLD.md" -Encoding UTF8
  Set-Content (Join-Path $Work 'dummy.txt') 'v1' -Encoding UTF8
  git -C $Work add -A; git -C $Work commit -q -m 'seed'; git -C $Work branch -M main; git -C $Work push -q origin main 2>&1 | Out-Null
  git clone -q $Origin $Other 2>&1 | Out-Null
}

function Invoke-AW([string]$mode, [string]$maxMin = '90', [switch]$NoSess) {
  $env:KTS_AW_STATEDIR = $State; $env:KTS_AW_MUTEX = 'KTS_AW_TEST'; $env:KTS_AW_MAXRUNMIN = $maxMin
  $env:KTS_SHIM_MODE = $mode; $env:KTS_SHIM_ARGV = $Argv
  if ($NoSess) { $env:KTS_SHIM_NOSESS = '1' } else { $env:KTS_SHIM_NOSESS = '' }
  $oldPath = $env:PATH; $env:PATH = $Bin + ';' + $env:PATH
  $t0 = Get-Date
  powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Work 'auto_watch.ps1') | Out-Null
  $code = $LASTEXITCODE
  $env:PATH = $oldPath
  "  [실행] shim=$mode 상한=${maxMin}분 → 종료코드 $code · $([int]((Get-Date)-$t0).TotalSeconds)초"
}

function Get-Try { $f = Join-Path $State ($TaskN + '.try'); if (Test-Path $f) { (Get-Content $f -Raw).Trim() } else { '(없음)' } }
function Get-ArgvCount { if (Test-Path $Argv) { @(Get-Content $Argv -Encoding UTF8).Count } else { 0 } }
function Show-LogTail([int]$n = 8) { if (Test-Path (Join-Path $State 'autowatch.log')) { Get-Content (Join-Path $State 'autowatch.log') -Encoding UTF8 -Tail $n | ForEach-Object { '    log| ' + $_ } } }
function Check([string]$name, [bool]$ok, [string]$detail = '') { $r = if ($ok) { 'PASS' } else { 'FAIL' }; "  [$r] $name $detail" }
