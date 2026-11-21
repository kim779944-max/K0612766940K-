param([string]$prefix = 'A_', [string]$picks = '0,4,9', [string]$birth = '19690815', [string]$mode = 'self')
. "$PSScriptRoot\lib.ps1"
Start-Serve
$out = [ordered]@{}
try {
  Open-Page ($global:Base + 'navi2/') 9372
  Start-Sleep -Milliseconds 1500
  $out.introSW = SW
  ShotP ($prefix + 'navi_start.png')
  if ($mode -ne 'self') { J "document.querySelector('#segMode button[data-mode=other]').click(); document.querySelector('#relRow button[data-rel=$mode]').click(); return 1" | Out-Null }
  J "var b=document.querySelector('#birth'); b.value='$birth'; b.dispatchEvent(new Event('input')); return 1" | Out-Null
  J "var ps=document.querySelectorAll('#gal16 .pic'); [$picks].forEach(function(i){ps[i].click();}); return 1" | Out-Null
  J "document.querySelector('#btnStart').click(); return 1" | Out-Null
  Start-Sleep -Milliseconds 400
  $out.quizSW = SW
  $out.quizImgs = J "return document.querySelectorAll('#ogrid img').length"
  ShotP ($prefix + 'navi_quiz.png')
  for ($i = 1; $i -le 10; $i++) {
    J "var o=document.querySelectorAll('#ogrid .opt'); o[($i*7)%o.length].click(); return 1" | Out-Null
    Start-Sleep -Milliseconds 450
  }
  Start-Sleep -Milliseconds 1800
  J "document.querySelector('#btnReveal').click(); return 1" | Out-Null
  Start-Sleep -Milliseconds 800
  $out.resultSW = SW
  $out.lint = J "return JSON.stringify(window.__NAVI_LINT)"
  $out.caps = J "return JSON.stringify([].map.call(document.querySelectorAll('#resBody .sec > .cap'),function(c){return c.textContent}))"
  $out.resImgs = J "return JSON.stringify([].map.call(document.querySelectorAll('#resBody img'),function(i){return i.getAttribute('src')}))"
  $out.text = J "return document.querySelector('#resBody').innerText"
  ShotFull ($prefix + 'navi_result_full.png')
  $out.evts = Evts-Summary
  $out.evtList = @($global:EVTS | Select-Object -First 6 | ForEach-Object { $_.kind + ' :: ' + $_.text.Substring(0, [Math]::Min(300, $_.text.Length)) })
} finally { Stop-CdpChrome }
$out | ConvertTo-Json -Depth 5
