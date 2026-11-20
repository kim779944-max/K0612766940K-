# 3D/더싸인/슬롯 검수 공통 — CDP(헤드리스 크롬) + 이벤트(콘솔·예외·로그) 수집
. "$PSScriptRoot\..\..\theform_20261118\src\cdp.ps1"
$global:EVTS = New-Object System.Collections.ArrayList
Add-Type -AssemblyName System.Web.Extensions
$global:SER = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$global:SER.MaxJsonLength = [int]::MaxValue

function Send-Cdp([string]$method, $params = @{}) {
  $global:cdpId++
  $id = $global:cdpId
  $msg = @{ id = $id; method = $method; params = $params } | ConvertTo-Json -Depth 20 -Compress
  $bytes = [Text.Encoding]::UTF8.GetBytes($msg)
  $seg = New-Object System.ArraySegment[byte] -ArgumentList @(, $bytes)
  $global:cdpWs.SendAsync($seg, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [Threading.CancellationToken]::None).Wait()
  while ($true) {
    $txt = Receive-CdpMsg
    if ($txt -match ('^\{"id":' + $id + ',')) {
      $o = $global:SER.DeserializeObject($txt)
      if ($o.ContainsKey('error')) { throw ("CDP error " + $method + ": " + $txt) }
      return $o['result']
    }
    if ($txt -match '"method":"(Runtime\.exceptionThrown|Runtime\.consoleAPICalled|Log\.entryAdded)"') {
      $o = $global:SER.DeserializeObject($txt); $m = $o['method']; $p = $o['params']
      if ($m -eq 'Runtime.exceptionThrown') { [void]$global:EVTS.Add([pscustomobject]@{ kind = 'pageerror'; text = ($p['exceptionDetails'] | ConvertTo-Json -Depth 5 -Compress) }) }
      elseif ($m -eq 'Runtime.consoleAPICalled') { if ($p['type'] -eq 'error' -or $p['type'] -eq 'warning') { $a = @($p['args'] | ForEach-Object { $_['value'] }) -join ' '; [void]$global:EVTS.Add([pscustomobject]@{ kind = ('console.' + $p['type']); text = $a }) } }
      else { $e = $p['entry']; if ($e['level'] -eq 'error') { [void]$global:EVTS.Add([pscustomobject]@{ kind = ('log.' + $e['source']); text = ([string]$e['text'] + ' ' + [string]$e['url']) }) } }
    }
  }
}
function Open-Page([string]$url, [int]$port = 9351, [string]$extra = '', [int]$w = 390, [int]$h = 844) {
  Start-CdpChrome $port $extra | Out-Null
  Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = $w; height = $h; deviceScaleFactor = 2; mobile = $true } | Out-Null
  Send-Cdp 'Page.enable' | Out-Null
  Send-Cdp 'Runtime.enable' | Out-Null
  Send-Cdp 'Log.enable' | Out-Null
  Send-Cdp 'DOM.enable' | Out-Null
  try { Send-Cdp 'Page.setDownloadBehavior' @{ behavior = 'deny' } | Out-Null } catch {}
  Go-Url $url
}
function Go-Url([string]$url, [int]$ms = 2500) { Send-Cdp 'Page.navigate' @{ url = $url } | Out-Null; Start-Sleep -Milliseconds $ms }
function Js([string]$code) { return Invoke-Js ("(async()=>{ " + $code + " })()") -await }
function Pump([int]$ms = 300) { $null = Invoke-Js "1"; Start-Sleep -Milliseconds $ms; $null = Invoke-Js "1" }
function Mouse([string]$type, [double]$x, [double]$y, [int]$buttons = 1) {
  Send-Cdp 'Input.dispatchMouseEvent' @{ type = $type; x = $x; y = $y; button = 'left'; buttons = $buttons; clickCount = 1 } | Out-Null
}
function Tap([double]$x, [double]$y) { Mouse 'mouseMoved' $x $y 0; Mouse 'mousePressed' $x $y; Mouse 'mouseReleased' $x $y 0 }
function Drag([double]$x0, [double]$y0, [double]$x1, [double]$y1, [int]$steps = 8) {
  Mouse 'mouseMoved' $x0 $y0 0; Mouse 'mousePressed' $x0 $y0
  for ($i = 1; $i -le $steps; $i++) { Mouse 'mouseMoved' ($x0 + ($x1 - $x0) * $i / $steps) ($y0 + ($y1 - $y0) * $i / $steps) 1 }
  Mouse 'mouseReleased' $x1 $y1 0
}
function Rect([string]$sel, [string]$block = 'center') {
  $j = Invoke-Js ("(()=>{const e=document.querySelector('" + $sel + "'); if(!e) return null; e.scrollIntoView({block:'" + $block + "'}); const r=e.getBoundingClientRect(); return JSON.stringify({x:r.x,y:r.y,w:r.width,h:r.height})})()")
  if (-not $j) { throw "no element $sel" }
  return ($j | ConvertFrom-Json)
}
function TapSel([string]$sel) { $r = Rect $sel; Tap ($r.x + $r.w / 2) ($r.y + $r.h / 2); return $r }
function Shot([string]$path) { Start-Sleep -Milliseconds 300; Save-Screenshot $path }
function Shot-Clip([string]$path, [string]$sel) {
  $null = Rect $sel; Start-Sleep -Milliseconds 300
  $r = (Invoke-Js ("(()=>{const r=document.querySelector('" + $sel + "').getBoundingClientRect();return JSON.stringify({x:r.x+scrollX,y:r.y+scrollY,w:r.width,h:r.height})})()") | ConvertFrom-Json)
  $res = Send-Cdp 'Page.captureScreenshot' @{ format = 'png'; clip = @{ x = $r.x; y = $r.y; width = $r.w; height = $r.h; scale = 1 } }
  [IO.File]::WriteAllBytes($path, [Convert]::FromBase64String($res['data']))
}
function Wait-Js([string]$cond, [int]$ms = 20000) { $t = 0; while ($t -lt $ms) { if (Invoke-Js $cond) { return $true }; Start-Sleep -Milliseconds 250; $t += 250 }; return $false }
function Evts-Summary { $g = @{}; foreach ($e in $global:EVTS) { if (-not $g.ContainsKey($e.kind)) { $g[$e.kind] = 0 }; $g[$e.kind]++ }; return $g }
function Clear-Evts { $global:EVTS.Clear() }
function Sha([string]$p) { return (Get-FileHash -Algorithm SHA256 $p).Hash.Substring(0, 12) }
