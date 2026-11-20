# 구형 .hwp 변환 서버 끄기 — 서버·터널 프로세스를 PID 파일로 종료
$Here   = $PSScriptRoot
$RunDir = Join-Path $Here 'run'
foreach ($f in 'cloudflared.pid', 'server.pid') {
  $p = Join-Path $RunDir $f
  if (Test-Path $p) {
    $id = Get-Content $p -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($id) {
      try { Stop-Process -Id ([int]$id) -Force -ErrorAction Stop; Write-Host "종료: $f (pid $id)" } catch { Write-Host "이미 꺼짐: $f (pid $id)" }
    }
    Remove-Item $p -Force -ErrorAction SilentlyContinue
  }
}
# PID 파일이 없어도 포트를 잡고 있는 서버가 남아 있으면 정리
$left = Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
  Where-Object { $_.CommandLine -match 'hwp-server\.ps1' }
foreach ($w in $left) { try { Stop-Process -Id $w.ProcessId -Force -ErrorAction Stop; Write-Host "종료: hwp-server (pid $($w.ProcessId))" } catch {} }
try { Invoke-RestMethod -Uri 'http://127.0.0.1:8799/health' -TimeoutSec 2 | Out-Null; Write-Host '!! 아직 응답이 있습니다' } catch { Write-Host '꺼졌습니다.' }
