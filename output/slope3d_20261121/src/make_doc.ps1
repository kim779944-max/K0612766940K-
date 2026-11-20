# 검수용 1쪽 계약서 그림(갑·을 날인란) 2장 만들기
Add-Type -AssemblyName System.Drawing
$dir = (Resolve-Path "$PSScriptRoot\..").Path
foreach ($n in 1, 2) {
  $b = New-Object Drawing.Bitmap 1240, 1754
  $g = [Drawing.Graphics]::FromImage($b)
  $g.Clear([Drawing.Color]::White)
  $f1 = New-Object Drawing.Font 'Malgun Gothic', 44, ([Drawing.FontStyle]::Bold)
  $f2 = New-Object Drawing.Font 'Malgun Gothic', 24
  $br = [Drawing.Brushes]::Black
  $g.DrawString("검수용 계약서 ($n 쪽)", $f1, $br, 330, 120)
  for ($i = 0; $i -lt 18; $i++) { $g.DrawString(("제" + ($i + 1) + "조  본 계약의 내용은 검수용 문장입니다. 갑과 을은 성실히 이행한다."), $f2, $br, 110, 300 + $i * 62) }
  $g.DrawString("갑 : 김갑동      (인)", $f2, $br, 180, 1500)
  $g.DrawString("을 : 이을순      (인)", $f2, $br, 720, 1500)
  $g.DrawString("입회인 : 박병      (인)", $f2, $br, 450, 1620)
  $g.Dispose()
  $b.Save((Join-Path $dir ("test_doc_" + $n + ".png")), [Drawing.Imaging.ImageFormat]::Png)
  $b.Dispose()
}
"ok"
