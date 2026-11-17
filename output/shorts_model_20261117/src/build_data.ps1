# Bundles captured frames (PNG), element rects, cue timings and narration WAVs into data_<short>.js for player.html
param([string]$short)
$base = (Resolve-Path "$PSScriptRoot\..").Path
$cfg = [IO.File]::ReadAllText("$PSScriptRoot\cues.json", [Text.Encoding]::UTF8) | ConvertFrom-Json
$timing = [IO.File]::ReadAllText("$base\audio\timing.json", [Text.Encoding]::UTF8) | ConvertFrom-Json
$rects = [IO.File]::ReadAllText("$base\frames\$short\rects.json", [Text.Encoding]::UTF8)
$sb = New-Object Text.StringBuilder
[void]$sb.Append("window.SHORT = {name:'$short', title:" + (ConvertTo-Json $cfg.$short.title) + ", rects:" + $rects + ", cues:[")
foreach ($c in $cfg.$short.cues) {
  $t = $timing.($c.id)
  $wav = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$base\audio\$($c.id).wav"))
  $cj = ConvertTo-Json $c -Compress -Depth 5
  [void]$sb.Append("Object.assign($cj, {dur:$($t.dur), tapMs:$($t.tap), wav:'$wav'}),")
}
[void]$sb.Append("], frames:{")
$names = $cfg.$short.cues | ForEach-Object { $_.frame } | Select-Object -Unique
foreach ($n in $names) {
  $png = [Convert]::ToBase64String([IO.File]::ReadAllBytes("$base\frames\$short\$n.png"))
  [void]$sb.Append("'$n':'data:image/png;base64,$png',")
}
[void]$sb.Append("}};")
[IO.File]::WriteAllText("$PSScriptRoot\data_$short.js", $sb.ToString(), (New-Object Text.UTF8Encoding($false)))
Write-Output ("data_$short.js " + (Get-Item "$PSScriptRoot\data_$short.js").Length)
