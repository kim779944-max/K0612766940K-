param([string]$src,[string]$dst,[int]$y0,[int]$y1,[double]$scale=1)
Add-Type -AssemblyName System.Drawing
$b=[Drawing.Bitmap]::FromFile($src); $w=$b.Width; $h=$y1-$y0
$o=New-Object Drawing.Bitmap ([int]($w*$scale)),([int]($h*$scale)); $g=[Drawing.Graphics]::FromImage($o); $g.InterpolationMode='HighQualityBicubic'
$g.DrawImage($b,(New-Object Drawing.Rectangle 0,0,$o.Width,$o.Height),(New-Object Drawing.Rectangle 0,$y0,$w,$h),[Drawing.GraphicsUnit]::Pixel)
$o.Save($dst,[Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $o.Dispose(); $b.Dispose()
