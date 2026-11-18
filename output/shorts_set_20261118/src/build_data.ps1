# Bundles frames, rects, cue timings, narration WAVs, model clips (mp4) and the official model photo into data_<short>.js
param([string]$short)
$base = (Resolve-Path "$PSScriptRoot\..").Path
$root = (Resolve-Path "$PSScriptRoot\..\..\..").Path
$cfg = [IO.File]::ReadAllText("$PSScriptRoot\cues.json", [Text.Encoding]::UTF8) | ConvertFrom-Json
$S = $cfg.$short
$timing = [IO.File]::ReadAllText("$base\audio\timing.json", [Text.Encoding]::UTF8) | ConvertFrom-Json
$rects = [IO.File]::ReadAllText("$base\frames\$short\rects.json", [Text.Encoding]::UTF8)
$sb = New-Object Text.StringBuilder
[void]$sb.Append("window.SHORT = {name:'$short', title:" + (ConvertTo-Json $S.title) + ", url:" + (ConvertTo-Json $S.url) + ", end1:" + (ConvertTo-Json $S.end1) + ", rects:" + $rects + ", cues:[")
foreach ($c in $S.cues) {
  $t = $timing.($c.id)
  $wav = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$base\audio\$($c.id).wav"))
  $cj = ConvertTo-Json $c -Compress -Depth 5
  [void]$sb.Append("Object.assign($cj, {dur:$($t.dur), tapMs:$($t.tap), wav:'$wav'}),")
}
[void]$sb.Append("], frames:{")
$names = @()
foreach ($c in $S.cues) { if ($c.frame) { $names += $c.frame }; if ($c.seq) { $names += @($c.seq) } }
foreach ($n in ($names | Select-Object -Unique)) {
  $png = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$base\frames\$short\$n.png"))
  [void]$sb.Append("'$n':'data:image/png;base64,$png',")
}
[void]$sb.Append("}, clips:{")
foreach ($k in ($S.cues | Where-Object { $_.clip } | ForEach-Object { $_.clip } | Select-Object -Unique)) {
  $mp4 = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$root\assets\model_clips\$k.mp4"))
  [void]$sb.Append("'$k':'$mp4',")
}
$model = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$root\assets\model_friends_23_final.png"))
$thumbs = @()
foreach ($i in 1..4) { $thumbs += ("'data:image/jpeg;base64," + [Convert]::ToBase64String([IO.File]::ReadAllBytes("$root\saycap\samples\sample$i.jpg")) + "'") }
[void]$sb.Append("}, model:'data:image/png;base64,$model', thumbs:[" + ($thumbs -join ',') + "]};")
[IO.File]::WriteAllText("$PSScriptRoot\data_$short.js", $sb.ToString(), (New-Object Text.UTF8Encoding($false)))
Write-Output ("data_$short.js " + (Get-Item "$PSScriptRoot\data_$short.js").Length)
