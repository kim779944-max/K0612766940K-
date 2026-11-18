# 공통: CDP 크롬 열기(390x844 @2x) + 오류 수집기 + 파일 저장 + 탭/끌기/캡처 도우미
. "$PSScriptRoot\cdp.ps1"
$global:ROOT = (Resolve-Path "$PSScriptRoot\..\..\..").Path
function Open-App([string]$rel, [int]$port = 9341) {
  Start-CdpChrome $port | Out-Null
  Send-Cdp 'Emulation.setDeviceMetricsOverride' @{ width = 390; height = 844; deviceScaleFactor = 2; mobile = $true } | Out-Null
  Send-Cdp 'Page.enable' | Out-Null
  Send-Cdp 'DOM.enable' | Out-Null
  try { Send-Cdp 'Page.setDownloadBehavior' @{ behavior = 'deny' } | Out-Null } catch {}
  Send-Cdp 'Page.addScriptToEvaluateOnNewDocument' @{ source = "window.__errs=[];window.addEventListener('error',function(e){var t=e.target;window.__errs.push(t&&t!==window&&(t.src||t.href)?('LOAD '+(t.src||t.href)):('JS '+e.message))},true);window.addEventListener('unhandledrejection',function(e){window.__errs.push('PROMISE '+(e.reason&&e.reason.message||e.reason))});window.print=function(){window.__printed=(window.__printed||0)+1};" } | Out-Null
  Nav $rel
}
$global:ERRS = @()
function Nav([string]$rel) {
  try { $e = Invoke-Js "JSON.stringify(window.__errs||[])"; if ($e -and $e -ne "[]") { $global:ERRS += $e } } catch {}
  Send-Cdp 'Page.navigate' @{ url = (To-FileUrl (Join-Path $global:ROOT $rel)) } | Out-Null
  Start-Sleep -Milliseconds 2500
}
function Js([string]$code) { return Invoke-Js ("(async()=>{ " + $code + " })()") -await }
function Save-B64([string]$b64, [string]$path) { [IO.File]::WriteAllBytes($path, [Convert]::FromBase64String($b64)) }
$global:B64JS = "const b2=async b=>{const u=new Uint8Array(await b.arrayBuffer());let s='';for(let i=0;i<u.length;i+=32768)s+=String.fromCharCode.apply(null,u.subarray(i,i+32768));return btoa(s)};"

# 손가락 대신 마우스 이벤트(페이지에는 포인터 이벤트로 들어감)
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
function RectNoScroll([string]$sel) {
  $j = Invoke-Js ("(()=>{const e=document.querySelector('" + $sel + "'); if(!e) return null; const r=e.getBoundingClientRect(); return JSON.stringify({x:r.x,y:r.y,w:r.width,h:r.height})})()")
  if (-not $j) { throw "no element $sel" }
  return ($j | ConvertFrom-Json)
}
function TapSel([string]$sel) { $r = Rect $sel; Tap ($r.x + $r.w / 2) ($r.y + $r.h / 2); return $r }
function TypeText([string]$t) { Send-Cdp 'Input.insertText' @{ text = $t } | Out-Null }
$global:MARKS = @()
function Shot([string]$dir, [string]$name, $marks = @()) {
  Start-Sleep -Milliseconds 350
  Save-Screenshot (Join-Path $dir ($name + '.png'))
  $sw = Invoke-Js "document.documentElement.scrollWidth"
  $global:MARKS += [pscustomobject]@{ shot = $name; marks = @($marks); scrollWidth = $sw }
  Write-Output ("shot " + $name + " sw=" + $sw)
}
function Mk([string]$kind, $r, [string]$note = '') { return [pscustomobject]@{ kind = $kind; x = [math]::Round($r.x, 1); y = [math]::Round($r.y, 1); w = [math]::Round($r.w, 1); h = [math]::Round($r.h, 1); note = $note } }
function Wait-Idle([string]$cond, [int]$ms = 15000) {
  $t = 0; while ($t -lt $ms) { if (Invoke-Js $cond) { return $true }; Start-Sleep -Milliseconds 200; $t += 200 }; return $false
}
function Print-Pdf([string]$path) {
  Send-Cdp 'Emulation.setEmulatedMedia' @{ media = 'print' } | Out-Null
  $r = Send-Cdp 'Page.printToPDF' @{ printBackground = $true; preferCSSPageSize = $true }
  [IO.File]::WriteAllBytes($path, [Convert]::FromBase64String($r['data']))
  Send-Cdp 'Emulation.setEmulatedMedia' @{ media = '' } | Out-Null
}
function Save-Marks([string]$path) { ConvertTo-Json -InputObject @($global:MARKS) -Depth 6 | Set-Content -Encoding UTF8 $path }
