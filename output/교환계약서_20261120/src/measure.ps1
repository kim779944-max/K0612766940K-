param([string]$img)
. "$PSScriptRoot\px.ps1"
$p = New-Object Px $img
"size " + $p.W + "x" + $p.H
"text rows x80-1400 y1100-2100: " + $p.Rows(80,1400,1100,2100,120)
"HLines x80-1400 y1100-2105 (>=60%): " + $p.HLines(80,1400,1100,2104,120,0.6)
"VLines y1560-1600: " + $p.VLines(70,1420,1560,1600,120,0.95)
"VLines y1720-1760: " + $p.VLines(70,1420,1720,1760,120,0.95)
"VLines frame y1250-1450: " + $p.VLines(70,1420,1250,1450,120,0.95)
"제5조 first x y1143-1166: " + $p.FirstDarkX(76,400,1143,1166,120) + " / line2: " + $p.FirstDarkX(76,400,1183,1206,120)
"제4조 first x y1063-1086: " + $p.FirstDarkX(76,400,1063,1086,120)
"특약 rows x76-300 y1250-1400: " + $p.Rows(76,300,1250,1400,120) + " firstX " + $p.FirstDarkX(76,400,1290,1330,120)
"특약 cols: " + $p.Cols(76,400,1290,1330,0,119)
"sign cell gray cols x1112-1411 y1611-1662 (130-250): " + $p.Cols(1112,1411,1611,1662,130,250)
"sign cell gray rows: " + $p.Rows(1112,1411,1611,1662,251)
"sign cell dark(<120) count: " + $p.Count(1115,1408,1612,1660,0,119)
"title rows x400-1100 y146-240: " + $p.Rows(400,1100,146,240,120) + " cols: " + $p.Cols(300,1410,150,215,0,119)
"bottom tail rows y1760-2104: " + $p.Rows(0,1488,1760,2104,250)
"frame bottom row 1769 dark count: " + $p.Count(70,1420,1769,1769,0,119) + " 1768: " + $p.Count(70,1420,1768,1768,0,119)+ " 1770: " + $p.Count(70,1420,1770,1770,0,119)
