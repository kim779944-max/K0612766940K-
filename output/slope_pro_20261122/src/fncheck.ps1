# §0-2 함수 13개 본문 바이트 비교 (6d50013 vs 작업본)
param([string]$base = '6d50013')
$OcRoot = (Resolve-Path "$PSScriptRoot\..\..\..\..\oneclick").Path
function Get-FnBody([string]$src, [string]$name) {
  $m = [regex]::Match($src, '(?m)^function ' + [regex]::Escape($name) + '\(')
  if (-not $m.Success) { return $null }
  $i = $src.IndexOf('{', $m.Index); $d = 0
  for ($k = $i; $k -lt $src.Length; $k++) { $c = $src[$k]; if ($c -eq '{') { $d++ } elseif ($c -eq '}') { $d--; if ($d -eq 0) { return $src.Substring($m.Index, $k - $m.Index + 1) } } }
  return $null
}
Push-Location $OcRoot
$old = ([IO.File]::ReadAllText((Join-Path $env:TEMP ("old_" + $base + ".html")), [Text.Encoding]::UTF8)) -replace "`r`n", "`n"
Pop-Location
$new = ([IO.File]::ReadAllText((Join-Path $OcRoot 'slope\index.html'), [Text.Encoding]::UTF8)) -replace "`r`n", "`n"
$fns = 'render','scene','drawBase','drawSlopeImg','drawContours','drawGridLines','drawVWImg','drawParcelHL','drawMarker','drawProfile','analyze','paintResult','verdictOf'
$out = foreach ($f in $fns) { $a = Get-FnBody $old $f; $b = Get-FnBody $new $f; [pscustomobject]@{ fn = $f; len = $(if ($a) { $a.Length } else { -1 }); same = ($a -ne $null -and $a -ceq $b) } }
$out | ConvertTo-Json -Compress
'same=' + @($out | Where-Object { $_.same }).Count + '/' + $fns.Count
foreach ($t in 'kts_slope_free', '하루 3건 무료', '10건권 9,000원', 'SL', 'paintCard', 'DEFAULT_VW_KEY') { $t + ' old=' + ([regex]::Matches($old, [regex]::Escape($t)).Count) + ' new=' + ([regex]::Matches($new, [regex]::Escape($t)).Count) }
$fa = Get-FnBody $old 'paintCard'; $fb = Get-FnBody $new 'paintCard'; 'paintCard same=' + ($fa -ceq $fb)
$fa = Get-FnBody $old 'codeOK'; $fb = Get-FnBody $new 'codeOK'; 'codeOK same=' + ($fa -ceq $fb)
$fa = Get-FnBody $old 'tileUrl'; $fb = Get-FnBody $new 'tileUrl'; 'tileUrl same=' + ($fa -ceq $fb)
$fa = Get-FnBody $old 'exportPng'; $fb = Get-FnBody $new 'exportPng'; 'exportPng same=' + ($fa -ceq $fb)
$fa = Get-FnBody $old 'openResult'; $fb = Get-FnBody $new 'openResult'; 'openResult same=' + ($fa -ceq $fb)
