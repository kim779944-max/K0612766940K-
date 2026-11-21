Add-Type -AssemblyName System.Drawing
$out = (Resolve-Path "$PSScriptRoot\..\..\..\..\oneclick\shots").Path
$items = @(
  @{ k = 'gagebu'; t = '가계부'; s = '오늘 산 것 · 1초 비교' },
  @{ k = 'hogang'; t = '호갱'; s = '최저가 한 줄' },
  @{ k = 'golf'; t = '골프'; s = '스윙 교정 1·2·3' },
  @{ k = 'petmind'; t = '동물'; s = '행동 번역기' }
)
function RoundRect($g, $brush, $x, $y, $w, $h, $r) {
  $p = New-Object Drawing.Drawing2D.GraphicsPath
  $p.AddArc($x, $y, $r * 2, $r * 2, 180, 90); $p.AddArc($x + $w - $r * 2, $y, $r * 2, $r * 2, 270, 90)
  $p.AddArc($x + $w - $r * 2, $y + $h - $r * 2, $r * 2, $r * 2, 0, 90); $p.AddArc($x, $y + $h - $r * 2, $r * 2, $r * 2, 90, 90)
  $p.CloseFigure(); $g.FillPath($brush, $p); return $p
}
foreach ($it in $items) {
  $bmp = New-Object Drawing.Bitmap 256, 256
  $g = [Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'AntiAliasGridFit'
  $g.Clear([Drawing.Color]::FromArgb(0, 0, 0, 0))
  $bg = New-Object Drawing.Drawing2D.LinearGradientBrush ([Drawing.Point]::new(0, 0)), ([Drawing.Point]::new(0, 256)), ([Drawing.Color]::FromArgb(255, 18, 35, 63)), ([Drawing.Color]::FromArgb(255, 10, 18, 36))
  $pth = RoundRect $g $bg 6 6 244 244 44
  $pen = New-Object Drawing.Pen ([Drawing.Color]::FromArgb(255, 46, 67, 112)), 3
  $g.DrawPath($pen, $pth)
  $or = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(255, 255, 107, 0))
  $font = New-Object Drawing.Font 'Malgun Gothic', 50, ([Drawing.FontStyle]::Bold), ([Drawing.GraphicsUnit]::Pixel)
  $sz = $g.MeasureString($it.t, $font)
  $pw = [Math]::Min(220, $sz.Width + 40); $px = (256 - $pw) / 2
  RoundRect $g $or $px 78 $pw 84 26 | Out-Null
  $navy = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(255, 10, 18, 36))
  $g.DrawString($it.t, $font, $navy, (256 - $sz.Width) / 2, 120 - $sz.Height / 2)
  $f2 = New-Object Drawing.Font 'Malgun Gothic', 19, ([Drawing.FontStyle]::Bold), ([Drawing.GraphicsUnit]::Pixel)
  $s2 = $g.MeasureString($it.s, $f2)
  $wb = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(255, 255, 201, 143))
  $g.DrawString($it.s, $f2, $wb, (256 - $s2.Width) / 2, 182)
  $g.FillEllipse($or, 206, 26, 16, 16)
  $bmp.Save((Join-Path $out ('ic_' + $it.k + '.png')), [Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
  Write-Output ('ic_' + $it.k + '.png')
}
