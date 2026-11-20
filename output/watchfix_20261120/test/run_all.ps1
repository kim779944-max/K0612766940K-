# T1~T8 순서대로 실행하고 test\logs\T*.txt 에 원문을 남긴다. (T2·T3 은 T1 상태를 이어 씀)
#  사용: powershell -NoProfile -ExecutionPolicy Bypass -File run_all.ps1
$logs = Join-Path $PSScriptRoot 'logs'
New-Item -ItemType Directory -Force $logs | Out-Null
foreach ($n in 1..8) {
  $out = powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "run_T$n.ps1") 2>&1 | Out-String
  [IO.File]::WriteAllText((Join-Path $logs "T$n.txt"), $out, (New-Object Text.UTF8Encoding $true))
  $out
}
