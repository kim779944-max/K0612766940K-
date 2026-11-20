# kts_gate.py 대체 — G1 정적 검사(태그 짝·Base64·API키·연락처·내부링크·viewport)를 viewer.html 변경 전/후에 같이 돌린다
# 사용: gate_viewer.ps1 <oneclick 경로> <기준 커밋>   → exit = 새로 생긴 FAIL 수
param([string]$Oc, [string]$Base = 'b932497')
function Test-Html([string]$src, [string]$dir) {
  $r = [ordered]@{}
  $mk = [regex]::Replace($src, '(?is)(<script\b[^>]*>).*?(</script>)', '$1$2')
  $mk = [regex]::Replace($mk, '(?is)(<style\b[^>]*>).*?(</style>)', '$1$2')
  $bad = @(); foreach ($t in 'div','section','main','header','nav','table','script','style','label','select','button','a','ol','ul','p','h1','h2','h3','textarea') {
    $o = [regex]::Matches($mk, "(?i)<$t(\s[^>]*)?>").Count; $c = [regex]::Matches($mk, "(?i)</$t>").Count; if ($o -ne $c) { $bad += "$t $o/$c" } }
  $r['G1-2 태그 짝'] = if ($bad) { 'FAIL ' + ($bad -join ',') } else { 'PASS' }
  $sz = @([regex]::Matches($src, 'data:[a-z/+.-]+;base64,([A-Za-z0-9+/=]+)') | ForEach-Object { [math]::Floor($_.Groups[1].Value.Length * 3 / 4) })
  $mx = if ($sz) { ($sz | Measure-Object -Maximum).Maximum } else { 0 }; $sm = if ($sz) { ($sz | Measure-Object -Sum).Sum } else { 0 }
  $r['G1-3 Base64'] = $(if ($mx -gt 153600 -or $sm -gt 512000) { 'FAIL' } else { 'PASS' }) + " max=$mx sum=$sm"
  $k = [regex]::Matches($src, 'sk-[A-Za-z0-9]{16,}|AIza[0-9A-Za-z_\-]{20,}|apiKey\s*=\s*["''][^"'']{8,}').Count
  $r['G1-5 API키'] = $(if ($k) { 'FAIL' } else { 'PASS' }) + " $k"
  $tx = [regex]::Replace($src, 'data:[^"'')\s]+', '')
  $pii = [regex]::Matches($tx, '01[016789][-. ]?\d{3,4}[-. ]?\d{4}').Count + [regex]::Matches($tx, '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}').Count + [regex]::Matches($tx, '\d{6}-[1-4]\d{6}').Count
  $r['G1-6 연락처·주민번호'] = $(if ($pii) { 'FAIL' } else { 'PASS' }) + " $pii"
  $br = @(); foreach ($m in [regex]::Matches($mk, '(?i)(?:href|src)="([^"]+)"')) { $u = $m.Groups[1].Value
    if ($u -match '^(https?:|data:|mailto:|tel:|javascript:|#|blob:)') { continue }; $rel = $u -replace '[?#].*$', ''; if ($rel -and -not (Test-Path (Join-Path $dir $rel))) { $br += $u } }
  $r['G1-8 내부 링크'] = $(if ($br) { 'FAIL ' + ($br -join ',') } else { 'PASS' })
  $r['G1-9 viewport'] = if ($src -match '<meta name="viewport" content="width=device-width') { 'PASS' } else { 'FAIL' }
  $r['개인경로·PC이름'] = if ($src -match 'C:\\Users|DESKTOP-02') { 'FAIL' } else { 'PASS' }
  return $r
}
Push-Location $Oc
try {
  $old = (git show "${Base}:viewer.html") -join "`n"
  $new = [IO.File]::ReadAllText((Join-Path $Oc 'viewer.html'), [Text.Encoding]::UTF8)
  $a = Test-Html $old $Oc; $b = Test-Html $new $Oc
  $newFail = 0
  foreach ($key in $b.Keys) {
    $line = "{0,-16} 전: {1,-28} 후: {2}" -f $key, $a[$key], $b[$key]
    if ($b[$key] -like 'FAIL*' -and $a[$key] -notlike 'FAIL*') { $newFail++; $line += '   ← 새 FAIL' }
    Write-Output $line
  }
  Write-Output "새로 생긴 FAIL: $newFail"
} finally { Pop-Location }
exit $newFail
