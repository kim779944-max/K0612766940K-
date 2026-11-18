# 2차 4종 공통: 직전 회차 도구(lib.ps1: CDP 크롬 390x844 @2x · 탭/타이핑/캡처/좌표 기록) 그대로 재사용
. "$PSScriptRoot\..\..\theform_20261118\src\lib.ps1"
$global:PM2 = (Resolve-Path "$PSScriptRoot\..").Path
function AppDir([string]$app) { $d = Join-Path $global:PM2 $app; New-Item -ItemType Directory -Force (Join-Path $d 'files') | Out-Null; return $d }
function Pages([string]$pdf) { $raw = [Text.Encoding]::GetEncoding(28591).GetString([IO.File]::ReadAllBytes($pdf)); return ([regex]::Matches($raw, '/Type\s*/Page[^s]')).Count }
function ScrollTo([string]$sel, [string]$block = 'start', [int]$dy = 0) { Invoke-Js ("(()=>{document.querySelector('#toast').classList.remove('on');const e=document.querySelector('" + $sel + "'); e.scrollIntoView({block:'" + $block + "'}); window.scrollBy(0," + $dy + "); return 1})()") | Out-Null; Start-Sleep -Milliseconds 250 }
function Toast() { return (Invoke-Js "document.querySelector('#toast').textContent") }
function Finish([string]$dir, $log) {
  $log += 'errors(now): ' + (Js 'return JSON.stringify(window.__errs)') + ' / before-nav: [' + ($global:ERRS -join ',') + ']'
  $log += 'print calls: ' + (Js 'return String(window.__printed||0)')
  Save-Marks (Join-Path $dir 'marks.json')
  $log | Set-Content -Encoding UTF8 (Join-Path $dir 'run_log.txt')
  $bad = @($global:MARKS | Where-Object { $_.scrollWidth -ne 390 })
  Write-Output ("shots=" + $global:MARKS.Count + " overflow(scrollWidth!=390)=" + $bad.Count)
  return $log
}
