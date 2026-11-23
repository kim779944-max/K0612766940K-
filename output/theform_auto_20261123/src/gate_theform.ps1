# kts_gate.py 대체(PowerShell 이식판, 146번용: theform/index.html) — G1 정적 검사를 바뀐 파일의 변경 전(149a7de)/후에 같이 돌린다
# 사용: gate_multi.ps1 <oneclick 경로> <기준 커밋>  → exit = 새로 생긴 FAIL 수
param([string]$Oc, [string]$Base = 'd6f95a9')
function Test-Src([string]$src, [string]$dir, [bool]$isHtml) {
  $r = [ordered]@{}
  if ($isHtml) {
    $mk = [regex]::Replace($src, '(?is)(<script\b[^>]*>).*?(</script>)', '$1$2')
    $mk = [regex]::Replace($mk, '(?is)(<style\b[^>]*>).*?(</style>)', '$1$2')
    $bad = @(); foreach ($t in 'div','section','main','header','nav','table','script','style','label','select','button','a','ol','ul','p','h1','h2','h3','textarea') {
      $o = [regex]::Matches($mk, "(?i)<$t(\s[^>]*)?>").Count; $c = [regex]::Matches($mk, "(?i)</$t>").Count; if ($o -ne $c) { $bad += "$t $o/$c" } }
    $r['G1-2 태그 짝'] = if ($bad) { 'FAIL ' + ($bad -join ',') } else { 'PASS' }
  }
  $sz = @([regex]::Matches($src, 'data:[a-z/+.-]+;base64,([A-Za-z0-9+/=]+)') | ForEach-Object { [math]::Floor($_.Groups[1].Value.Length * 3 / 4) })
  $mx = if ($sz) { ($sz | Measure-Object -Maximum).Maximum } else { 0 }; $sm = if ($sz) { ($sz | Measure-Object -Sum).Sum } else { 0 }
  $r['G1-3 Base64'] = $(if ($mx -gt 153600 -or $sm -gt 512000) { 'FAIL' } else { 'PASS' }) + " max=$mx sum=$sm"
  $k = [regex]::Matches($src, 'sk-[A-Za-z0-9]{16,}|AIza[0-9A-Za-z_\-]{20,}|apiKey\s*=\s*["''][^"'']{8,}').Count
  $r['G1-5 API키'] = $(if ($k) { 'FAIL' } else { 'PASS' }) + " $k"
  $tx = [regex]::Replace($src, 'data:[^"'')\s]+', '')
  $pii = [regex]::Matches($tx, '01[016789][-. ]?\d{3,4}[-. ]?\d{4}').Count + [regex]::Matches($tx, '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}').Count + [regex]::Matches($tx, '\d{6}-[1-4]\d{6}').Count
  $r['G1-6 연락처·주민번호'] = $(if ($pii) { 'FAIL' } else { 'PASS' }) + " $pii"
  if ($isHtml) {
    $br = @(); foreach ($m in [regex]::Matches($mk, '(?i)(?:href|src)="([^"]+)"')) { $u = $m.Groups[1].Value
      if ($u -match '^(https?:|data:|mailto:|tel:|sms:|javascript:|#|blob:)') { continue }; $rel = $u -replace '[?#].*$', ''; if ($rel -and -not (Test-Path (Join-Path $dir $rel))) { $br += $u } }
    $r['G1-8 내부 링크'] = $(if ($br) { 'FAIL ' + ($br -join ',') } else { 'PASS' })
    $r['G1-9 viewport'] = if ($src -match '<meta name="viewport" content="width=device-width') { 'PASS' } else { 'FAIL' }
  }
  $r['G1-1 파일 존재'] = if ($src.Length -gt 0) { 'PASS' } else { 'FAIL' }
  $iw = [regex]::Matches($src, '원가|마진율|내부용|TODO|FIXME').Count
  $r['G1-7 원가·내부문구'] = $(if ($iw) { 'FAIL' } else { 'PASS' }) + " $iw"
  $r['개인경로·PC이름'] = if ($src -match 'C:\\Users|DESKTOP-02|OneDrive') { 'FAIL' } else { 'PASS' }
  return $r
}
$newFail = 0
Push-Location $Oc
try {
  foreach ($f in 'theform/index.html') {
    $isHtml = $f -like '*.html'
    $dir = Split-Path (Join-Path $Oc $f) -Parent
    $tmpO = [IO.Path]::GetTempFileName(); cmd /c "git show ${Base}:$f > `"$tmpO`" 2>nul"; $old = [IO.File]::ReadAllText($tmpO, [Text.Encoding]::UTF8); Remove-Item $tmpO
    $new = [IO.File]::ReadAllText((Join-Path $Oc $f), [Text.Encoding]::UTF8)
    $a = if ($old) { Test-Src $old $dir $isHtml } else { $null }
    $b = Test-Src $new $dir $isHtml
    Write-Output ("== " + $f + $(if (-not $old) { ' (새 파일)' } else { '' }))
    foreach ($key in $b.Keys) {
      $av = if ($a) { $a[$key] } else { '(없음)' }
      $line = "  {0,-16} 전: {1,-30} 후: {2}" -f $key, $av, $b[$key]
      if ($b[$key] -like 'FAIL*' -and ($av -notlike 'FAIL*')) { $newFail++; $line += '   ← 새 FAIL' }
      Write-Output $line
    }
  }
  Write-Output "새로 생긴 FAIL: $newFail"
} finally { Pop-Location }
exit $newFail
