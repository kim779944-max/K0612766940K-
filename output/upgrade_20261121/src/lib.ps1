# 2026-11-21 종합 개편 검수 공통 — slope3d 판 CDP 라이브러리 재사용 + 정적 서버
. "$PSScriptRoot\..\..\slope3d_20261121\src\lib3d.ps1"
$global:OcRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..\oneclick").Path
$global:ShotDir = (Resolve-Path "$PSScriptRoot\..\shots").Path
$global:Base = 'http://127.0.0.1:8765/'

function Start-Serve {
  try { $r = Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 ($global:Base + 'robots.txt'); if ($r.StatusCode -eq 200) { return } } catch {}
  $p = Start-Process powershell -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSScriptRoot\serve.ps1`"",'-Root',"`"$($global:OcRoot)`"",'-Port','8765') -WindowStyle Hidden -PassThru
  Set-Content -Path "$PSScriptRoot\serve.pid" -Value $p.Id
  Start-Sleep -Milliseconds 1500
}
function Stop-Serve { if (Test-Path "$PSScriptRoot\serve.pid") { $id = Get-Content "$PSScriptRoot\serve.pid"; try { Stop-Process -Id $id -Force } catch {}; Remove-Item "$PSScriptRoot\serve.pid" } }
function J($code) { return Invoke-Js ("(()=>{ " + $code + " })()") }
function SW { return Invoke-Js "JSON.stringify({sw:document.documentElement.scrollWidth,cw:document.documentElement.clientWidth})" }
function Errs { $g = Evts-Summary; return $g }
function ShotP([string]$name) { Shot (Join-Path $global:ShotDir $name) }
function ShotFull([string]$name) {
  # 페이지 전체 캡처(390 폭)
  $h = [int](Invoke-Js "Math.ceil(document.documentElement.scrollHeight)")
  $r = Send-Cdp 'Page.captureScreenshot' @{ format = 'png'; captureBeyondViewport = $true; clip = @{ x = 0; y = 0; width = 390; height = $h; scale = 1 } }
  [IO.File]::WriteAllBytes((Join-Path $global:ShotDir $name), [Convert]::FromBase64String($r['data']))
}
function SetSel([string]$sel, [string]$val) {
  return Invoke-Js ("(()=>{var e=document.querySelector('" + $sel + "');e.value='" + $val + "';var t=performance.now();e.dispatchEvent(new Event('change',{bubbles:true}));return (performance.now()-t).toFixed(2);})()")
}
