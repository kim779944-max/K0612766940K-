# 측정.txt 조립: shots\_gate.txt + shots\_verify.txt 를 이어 붙입니다(어느 스크립트를 다시 돌려도 같은 형식).
function Build-Measure([string]$base) {
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.AppendLine('# 측정.txt — 이커머스 원클릭 5종 (2026-11-20 COMMERCE)')
  [void]$sb.AppendLine('# 이 파일은 src/gate.ps1 · src/verify.ps1 이 자동으로 다시 씁니다. 손으로 고치지 마세요.')
  [void]$sb.AppendLine('')
  foreach ($n in @('_gate.txt', '_verify.txt')) {
    $p = Join-Path $base ('shots\' + $n)
    if (Test-Path $p) { [void]$sb.AppendLine([IO.File]::ReadAllText($p, [Text.Encoding]::UTF8).TrimStart([char]0xFEFF)); [void]$sb.AppendLine('') }
    else { [void]$sb.AppendLine('(' + $n + ' 아직 없음 — 해당 스크립트 미실행)'); [void]$sb.AppendLine('') }
  }
  [IO.File]::WriteAllText((Join-Path $base '측정.txt'), $sb.ToString(), (New-Object System.Text.UTF8Encoding($true)))
}
