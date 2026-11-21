# KTS SNS 자동 게시 — 작업 스케줄러 등록 (register_sns_schedule.bat 이 부른다)
# §4-1 조건(토큰·사용자ID·블로그ID 있음 + 두 드라이런 종료 0)을 모두 만족할 때만 등록한다.
param([switch]$CheckOnly)
$ErrorActionPreference = 'Stop'
$Dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$EnvFile = Join-Path $Dir '.env.local'
$env:PYTHONUTF8 = '1'

$PyExe = $null; $PyArgs = @()
if (Get-Command py -ErrorAction SilentlyContinue) { $PyExe = 'py'; $PyArgs = @('-3') }
elseif (Test-Path "$env:LOCALAPPDATA\Programs\Python\Launcher\py.exe") { $PyExe = "$env:LOCALAPPDATA\Programs\Python\Launcher\py.exe"; $PyArgs = @('-3') }
else { $PyExe = 'python' }

$cfg = @{}
if (Test-Path $EnvFile) {
    foreach ($line in [IO.File]::ReadAllLines($EnvFile, [Text.Encoding]::UTF8)) {
        $s = $line.Trim()
        if ($s -and -not $s.StartsWith('#') -and $s.Contains('=')) {
            $kv = $s.Split('=', 2); $cfg[$kv[0].Trim()] = $kv[1].Trim().Trim('"').Trim("'")
        }
    }
}
$fail = @()
foreach ($k in 'THREADS_ACCESS_TOKEN', 'THREADS_USER_ID', 'NAVER_BLOG_ID') {
    if (-not $cfg[$k]) { $fail += "$k 없음 (.env.local)" }
}
Push-Location $Dir
try {
    & $PyExe @PyArgs threads_autopost.py --dry-run *> $null
    if ($LASTEXITCODE -ne 0) { $fail += "threads_autopost.py --dry-run 종료 $LASTEXITCODE" }
    & $PyExe @PyArgs naver_blog_draft.py --dry-run *> $null
    if ($LASTEXITCODE -ne 0) { $fail += "naver_blog_draft.py --dry-run 종료 $LASTEXITCODE" }
} finally { Pop-Location }

if ($fail.Count) {
    Write-Host '[등록 안 함] 아래 조건이 아직 안 됐습니다 (README_설정가이드.md 1~2단계):'
    $fail | ForEach-Object { Write-Host "  - $_" }
    exit 3
}
Write-Host '[조건 통과] 토큰·사용자ID·블로그ID 있음, 드라이런 2개 종료 0'
if ($CheckOnly) { exit 0 }

$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 30)
$jobs = @(
    @{ Name = 'KTS_SNS_THREADS'; Bat = 'run_threads.bat'; At = '08:10'; Desc = 'KTS 쓰레드 하루 1건 자동 게시' },
    @{ Name = 'KTS_SNS_NAVER';   Bat = 'run_naver.bat';   At = '08:20'; Desc = 'KTS 네이버 블로그 임시저장(발행 안 함)' }
)
foreach ($j in $jobs) {
    $a = New-ScheduledTaskAction -Execute (Join-Path $Dir $j.Bat) -WorkingDirectory $Dir
    $t = New-ScheduledTaskTrigger -Daily -At $j.At
    Register-ScheduledTask -TaskName $j.Name -Action $a -Trigger $t -Settings $settings -Description $j.Desc -Force | Out-Null
    $info = Get-ScheduledTaskInfo -TaskName $j.Name
    Write-Host ("[OK] {0} 매일 {1} · 다음 실행 {2}" -f $j.Name, $j.At, $info.NextRunTime)
}
Write-Host ''
Write-Host '* StartWhenAvailable: PC가 꺼져 있어 못 돌린 날은 켜지면 곧바로 한 번 돌립니다.'
Write-Host '* 시간 바꾸기: schtasks /Change /TN "KTS_SNS_THREADS" /ST 19:30'
Write-Host '* 비상 정지: .env.local 에 SNS_DAILY_ENABLED=0'
exit 0
