param([string]$src, [string]$dst)
. "$PSScriptRoot\px.ps1"
$p = New-Object Px $src
if ($p.W -ne 1489 -or $p.H -ne 2105) { throw "size " + $p.W + "x" + $p.H }
# ⑥ 갑 서명칸 회색 '자필서명' 글씨만 흰색 — '(인)'(x 1305~1344)과 검정 테두리는 그대로
"⑥ whitened gray px: " + $p.WhitenGray(1115, 1290, 1612, 1660, 120)
# ② '특약사항 :' (x79~195, y1301~1325) → x117, y1223 (dx +38, dy -78)
$p.MoveBlock(76, 210, 1296, 1330, 38, -78)
# ④ 하단 블록(1505~1769, 전체 폭) 아래로 +220
$p.MoveBlock(0, 1488, 1505, 1769, 0, 220)
# 프레임 좌우 세로선 1505~1989 이어 그리기 (y1400 단면, 더 어두운 값만)
foreach ($x in (73..75 + 1412..1414)) { $p.MinCol($x, 1400, 1505, 1989) }
# 새 아래 끝 가로선 — 위 테두리(143~146) 단면 그대로 1986~1989
foreach ($i in 0..3) { $p.MinRowCopy(143 + $i, 1986 + $i, 73, 1414) }
# ① 제목 뒤 '(당사자용)' — 제목+꼬리 전체를 가운데로
$bb = $p.Text('(당사자용)', 'Malgun Gothic', 46, $false, 0, 0, $false)
$sw = $bb[2] - $bb[0] + 1; $gap = 18
$d = [int][math]::Round(($sw + $gap) / 2)
$p.MoveBlock(480, 1000, 148, 214, - $d, 0)
$tl = 490 - $d; $tr = 988 - $d
$p.Text('(당사자용)', 'Malgun Gothic', 46, $false, $tr + 1 + $gap, 209, $true) | Out-Null
"title: $tl~$tr  suffix: " + ($tr + 1 + $gap) + "~" + ($tr + $gap + $sw) + " (w $sw, h " + ($bb[3]-$bb[1]+1) + ")"
$p.Save($dst)
"saved $dst"
