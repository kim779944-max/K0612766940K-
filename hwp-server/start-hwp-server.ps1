# 구형 .hwp 변환 서버 켜기 — 대표님이 직접 실행 (작업 스케줄러 등록 없음)
#  ① 서버 기동 → ② /health 확인 → ③ Cloudflare 무료 터널 기동
#  → ④ 새 주소를 oneclick/hwp-host.json 에 쓰고 commit·push → ⑤ 창 유지
# 옵션: -NoTunnel (로컬 시험용, ③④ 생략) / -NoPush (④에서 커밋·푸시 생략) / -NoWait (⑤ 생략)
param([switch]$NoTunnel, [switch]$NoPush, [switch]$NoWait, [int]$Port = 8799)

$ErrorActionPreference = 'Stop'
$Here   = $PSScriptRoot
$RunDir = Join-Path $Here 'run'
New-Item -ItemType Directory -Force $RunDir | Out-Null
$SrvPidFile = Join-Path $RunDir 'server.pid'
$CfPidFile  = Join-Path $RunDir 'cloudflared.pid'
$CfLog      = Join-Path $RunDir 'cloudflared.log'
$Health     = "http://127.0.0.1:$Port/health"

function Test-Health {
  try { $r = Invoke-RestMethod -Uri $Health -TimeoutSec 3; return [bool]$r.ok } catch { return $false }
}
function Find-Cloudflared {
  $c = Get-Command cloudflared -ErrorAction SilentlyContinue
  if ($c) { return $c.Source }
  $cand = @(
    (Join-Path $Here 'bin\cloudflared.exe'),   # 관리자 권한 없이 받은 공식 단일 exe (커밋 안 함)
    (Join-Path $env:ProgramFiles 'cloudflared\cloudflared.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'cloudflared\cloudflared.exe')
  )
  $cand += @(Get-ChildItem (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages') -Recurse -Filter cloudflared.exe -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
  foreach ($p in $cand) { if ($p -and (Test-Path $p)) { return $p } }
  return $null
}
function Find-OneclickRepo {
  # 저장소 위치는 하드코딩하지 않는다 — 형제 폴더 중 oneclick 원격을 가진 git 저장소를 찾는다
  $base = Split-Path (Split-Path $Here -Parent) -Parent
  foreach ($d in Get-ChildItem $base -Directory) {
    $cfg = Join-Path $d.FullName '.git\config'
    if ((Test-Path $cfg) -and ((Get-Content $cfg -Raw) -match 'kim779944-max/oneclick\.git')) { return $d.FullName }
  }
  return $null
}

Write-Host '== KTS 구형 .hwp 변환 서버 =='
if (Test-Path (Join-Path $Here 'OFF')) { Write-Host '!! hwp-server\OFF 파일이 있습니다 — 서버는 켜지지만 모든 요청에 503 을 돌려줍니다.' }

# ① 서버 기동
if (Test-Health) {
  Write-Host '① 서버가 이미 켜져 있습니다.'
} else {
  $srv = Start-Process powershell -PassThru -WindowStyle Hidden -ArgumentList @(
    '-NoProfile', '-STA', '-ExecutionPolicy', 'Bypass', '-File', ('"' + (Join-Path $Here 'hwp-server.ps1') + '"'), '-Port', $Port)
  Set-Content -Path $SrvPidFile -Value $srv.Id -Encoding ASCII
  Write-Host "① 서버 기동 (pid $($srv.Id))"
}

# ② /health 확인
$ok = $false
for ($i = 0; $i -lt 40; $i++) { if (Test-Health) { $ok = $true; break }; Start-Sleep -Milliseconds 250 }
if (-not $ok) { Write-Host "② /health 응답 없음 — logs\hwp-server.log 를 확인하세요."; exit 1 }
Write-Host "② /health OK  ($Health)"
if ($NoTunnel) { Write-Host '-NoTunnel: 터널 생략'; exit 0 }

# ③ 터널 기동
$cf = Find-Cloudflared
if (-not $cf) {
  Write-Host '③ cloudflared 가 없습니다 — 공식 exe 를 hwp-server\bin 에 받습니다(관리자 권한 불필요)'
  New-Item -ItemType Directory -Force (Join-Path $Here 'bin') | Out-Null
  $cf = Join-Path $Here 'bin\cloudflared.exe'
  [Net.ServicePointManager]::SecurityProtocol = 'Tls12'
  Invoke-WebRequest -UseBasicParsing -OutFile $cf -Uri 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe'
  if ((Get-AuthenticodeSignature $cf).Status -ne 'Valid') { Remove-Item $cf -Force; Write-Host '   서명 확인 실패 — 중단'; exit 1 }
}
if (Test-Path $CfPidFile) {
  $old = Get-Content $CfPidFile -ErrorAction SilentlyContinue
  if ($old) { try { Stop-Process -Id ([int]$old) -Force -ErrorAction Stop } catch {} }
}
if (Test-Path $CfLog) { Remove-Item $CfLog -Force }
# HttpListener 는 Host 헤더로 접두사를 고르므로 터널이 보내는 Host 를 127.0.0.1:포트 로 바꿔 준다
$cfp = Start-Process $cf -PassThru -WindowStyle Hidden -ArgumentList @(
  'tunnel', '--no-autoupdate', '--url', "http://127.0.0.1:$Port", '--http-host-header', "127.0.0.1:$Port", '--logfile', ('"' + $CfLog + '"'))
Set-Content -Path $CfPidFile -Value $cfp.Id -Encoding ASCII
$url = $null
for ($i = 0; $i -lt 120; $i++) {
  Start-Sleep -Milliseconds 500
  if (Test-Path $CfLog) {
    $m = [regex]::Match((Get-Content $CfLog -Raw -ErrorAction SilentlyContinue), 'https://[a-z0-9-]+\.trycloudflare\.com')
    if ($m.Success) { $url = $m.Value; break }
  }
  if ($cfp.HasExited) { break }
}
if (-not $url) { Write-Host "③ 터널 주소를 얻지 못했습니다 — $CfLog 확인"; exit 1 }
Write-Host "③ 터널: $url"
$tok = $false
for ($i = 0; $i -lt 60; $i++) {
  try { $r = Invoke-RestMethod -Uri "$url/health" -TimeoutSec 5; if ($r.ok) { $tok = $true; break } } catch {}
  Start-Sleep -Seconds 1
}
Write-Host ("   터널 경유 /health: " + $(if ($tok) { 'OK' } else { '아직 응답 없음(DNS 전파 대기 — 잠시 뒤 자동 연결)' }))

# ④ hwp-host.json 갱신 → commit → push
$oc = Find-OneclickRepo
if (-not $oc) { Write-Host '④ oneclick 저장소를 찾지 못해 hwp-host.json 을 쓰지 못했습니다.'; exit 1 }
$at = (Get-Date).ToString('yyyy-MM-ddTHH:mm:sszzz')
$json = '{ "url": "' + $url + '", "ver": "1.0", "at": "' + $at + '" }' + "`n"
[IO.File]::WriteAllText((Join-Path $oc 'hwp-host.json'), $json, (New-Object Text.UTF8Encoding($false)))
Write-Host "④ hwp-host.json ← $url"
if (-not $NoPush) {
  Push-Location $oc
  try {
    git add -- hwp-host.json
    git commit -m 'chore(hwp): 터널 주소 갱신' -- hwp-host.json | Out-Host
    git pull --rebase --autostash | Out-Host
    git push origin main | Out-Host
    Write-Host ("   커밋 " + (git rev-parse --short HEAD) + ' — 1~2분 뒤 autooneclick.com 에 반영')
  } finally { Pop-Location }
}

# ⑤ 창 유지
if ($NoWait) { exit 0 }
Write-Host ''
Write-Host '켜져 있습니다. 이 창을 닫아도 서버·터널은 계속 돕니다.'
Write-Host '끄기: stop-hwp-server.ps1  /  즉시 차단: hwp-server 폴더에 OFF 파일 만들기'
while ($true) {
  Start-Sleep -Seconds 30
  $s = if (Test-Health) { 'OK' } else { 'DOWN' }
  $c = if ($cfp.HasExited) { 'DOWN' } else { 'OK' }
  Write-Host ((Get-Date).ToString('HH:mm:ss') + "  서버 $s · 터널 $c")
}
