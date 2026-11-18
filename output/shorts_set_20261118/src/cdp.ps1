# Minimal Chrome DevTools Protocol client for PowerShell 5.1 (no node/python needed)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$global:CHROME = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
$global:cdpId = 0

function Start-CdpChrome([int]$port = 9333, [string]$extra = '') {
  $prof = Join-Path $env:TEMP ("cdpprof_" + $port)
  if (Test-Path $prof) { Remove-Item -Recurse -Force $prof -ErrorAction SilentlyContinue }
  $args = "--headless=new --remote-debugging-port=$port --user-data-dir=`"$prof`" --no-first-run --no-default-browser-check --autoplay-policy=no-user-gesture-required --allow-file-access-from-files --hide-scrollbars --lang=ko-KR $extra about:blank"
  $p = Start-Process -FilePath $global:CHROME -ArgumentList $args -PassThru
  for ($i = 0; $i -lt 50; $i++) {
    Start-Sleep -Milliseconds 300
    try { $t = Invoke-RestMethod "http://127.0.0.1:$port/json/list"; if ($t) { break } } catch {}
  }
  $page = ($t | Where-Object { $_.type -eq 'page' } | Select-Object -First 1)
  $ws = New-Object System.Net.WebSockets.ClientWebSocket
  $ws.Options.KeepAliveInterval = [TimeSpan]::FromSeconds(30)
  $ws.ConnectAsync([Uri]$page.webSocketDebuggerUrl, [Threading.CancellationToken]::None).Wait()
  $global:cdpWs = $ws
  $global:cdpProc = $p
  return $ws
}

function Receive-CdpMsg {
  $buf = New-Object byte[] 1048576
  $ms = New-Object System.IO.MemoryStream
  do {
    $seg = New-Object System.ArraySegment[byte] -ArgumentList @(, $buf)
    $r = $global:cdpWs.ReceiveAsync($seg, [Threading.CancellationToken]::None).Result
    $ms.Write($buf, 0, $r.Count)
  } while (-not $r.EndOfMessage)
  return [Text.Encoding]::UTF8.GetString($ms.ToArray())
}

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
      Add-Type -AssemblyName System.Web.Extensions
      $ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
      $ser.MaxJsonLength = [int]::MaxValue
      $o = $ser.DeserializeObject($txt)
      if ($o.ContainsKey('error')) { throw ("CDP error " + $method + ": " + $txt) }
      return $o['result']
    }
  }
}

function Invoke-Js([string]$expr, [switch]$await) {
  $r = Send-Cdp 'Runtime.evaluate' @{ expression = $expr; returnByValue = $true; awaitPromise = [bool]$await }
  if ($r.ContainsKey('exceptionDetails')) { throw ("JS exception: " + ($r['exceptionDetails'] | ConvertTo-Json -Depth 6 -Compress)) }
  return $r['result']['value']
}

function Save-Screenshot([string]$path) {
  $r = Send-Cdp 'Page.captureScreenshot' @{ format = 'png' }
  [IO.File]::WriteAllBytes($path, [Convert]::FromBase64String($r['data']))
}

function Stop-CdpChrome {
  try { $global:cdpWs.Dispose() } catch {}
  try { Stop-Process -Id $global:cdpProc.Id -Force } catch {}
  try { Get-WmiObject Win32_Process -Filter "name='chrome.exe'" | Where-Object { $_.CommandLine -match 'cdpprof_' } | ForEach-Object { try { Stop-Process -Id $_.ProcessId -Force } catch {} } } catch {}
}

function To-FileUrl([string]$p) { return ([Uri]$p).AbsoluteUri }

function Connect-Cdp([int]$port = 9333) {
  $t = Invoke-RestMethod "http://127.0.0.1:$port/json/list"
  $page = ($t | Where-Object { $_.type -eq 'page' } | Select-Object -First 1)
  $ws = New-Object System.Net.WebSockets.ClientWebSocket
  $ws.ConnectAsync([Uri]$page.webSocketDebuggerUrl, [Threading.CancellationToken]::None).Wait()
  $global:cdpWs = $ws
}

function Set-FileInput([string]$selector, [string[]]$files) {
  $doc = Send-Cdp 'DOM.getDocument' @{ depth = 0 }
  $n = Send-Cdp 'DOM.querySelector' @{ nodeId = $doc['root']['nodeId']; selector = $selector }
  Send-Cdp 'DOM.setFileInputFiles' @{ nodeId = $n['nodeId']; files = $files } | Out-Null
}
