# 공통: 헤드리스 크롬(390×844) 열기 + 오류 수집 + 다운로드 폴더 + JS 실행 도우미
. "$PSScriptRoot\cdp.ps1"
$global:BASE = (Resolve-Path "$PSScriptRoot\..").Path
$global:DL = Join-Path $global:BASE 'shots\dl'
$global:EXC = New-Object System.Collections.ArrayList

function Open-Tool([int]$port = 9351) {
  Start-CdpChrome $port | Out-Null
  Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 390; height = 844; deviceScaleFactor = 2; mobile = $true } | Out-Null
  Send-Cdp 'Page.enable' | Out-Null
  Send-Cdp 'DOM.enable' | Out-Null
  Send-Cdp 'Runtime.enable' | Out-Null
  Send-Cdp 'Log.enable' | Out-Null
  if (-not (Test-Path $global:DL)) { New-Item -ItemType Directory -Force $global:DL | Out-Null }
  try { Send-Cdp 'Browser.setDownloadBehavior' @{ behavior = 'allow'; downloadPath = $global:DL } | Out-Null } catch { Send-Cdp 'Page.setDownloadBehavior' @{ behavior = 'allow'; downloadPath = $global:DL } | Out-Null }
  # 페이지 안 오류 수집기(콘솔 error·pageerror·리소스 실패·외부 요청 기록)
  Send-Cdp 'Page.addScriptToEvaluateOnNewDocument' @{ source = "window.__errs=[];window.__net=[];window.addEventListener('error',function(e){var t=e.target;window.__errs.push(t&&t!==window&&(t.src||t.href)?('LOAD '+(t.src||t.href)):('JS '+e.message))},true);window.addEventListener('unhandledrejection',function(e){window.__errs.push('PROMISE '+(e.reason&&e.reason.message||e.reason))});(function(){var ce=console.error;console.error=function(){window.__errs.push('CONSOLE '+Array.prototype.join.call(arguments,' '));return ce.apply(console,arguments)}})();(function(){var f=window.fetch;window.fetch=function(u,o){window.__net.push(String(u));return f.apply(this,arguments)}})();" } | Out-Null
}
function Go-Tool([string]$rel) {
  $p = Join-Path $global:BASE ($rel -replace '\?.*$', '')
  $q = if ($rel -match '\?') { '?' + ($rel -replace '^[^?]*\?', '') } else { '' }
  Send-Cdp 'Page.navigate' @{ url = ((To-FileUrl $p) + $q) } | Out-Null
  Start-Sleep -Milliseconds 1500
}
function Js([string]$code) { return Invoke-Js ("(async()=>{ " + $code + " })()") -await }
function Wait-For([string]$cond, [int]$ms = 20000) {
  $t = 0; while ($t -lt $ms) { try { if (Invoke-Js $cond) { return $true } } catch {}; Start-Sleep -Milliseconds 250; $t += 250 }; return $false
}
function Errs { return (Invoke-Js "JSON.stringify(window.__errs||[])") }
function Clear-Dl { Get-ChildItem $global:DL -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue }
function Wait-Dl([string]$pattern, [int]$ms = 8000) {
  $t = 0
  while ($t -lt $ms) {
    $f = Get-ChildItem $global:DL -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -like $pattern -and $_.Name -notlike '*.crdownload' } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($f -and $f.Length -gt 0) { Start-Sleep -Milliseconds 200; return (Get-Item $f.FullName) }
    Start-Sleep -Milliseconds 250; $t += 250
  }
  return $null
}
