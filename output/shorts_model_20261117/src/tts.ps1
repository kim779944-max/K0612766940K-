# Synthesizes each cue with Windows SAPI (Microsoft Heami) to WAV and records the [tap] bookmark time.
param([string]$cues = "$PSScriptRoot\cues.json", [string]$outDir = "$PSScriptRoot\..\audio", [int]$rate = 1)
Add-Type -AssemblyName System.Speech
New-Item -ItemType Directory -Force $outDir | Out-Null
$cfg = [IO.File]::ReadAllText($cues, [Text.Encoding]::UTF8) | ConvertFrom-Json
$timing = @{}
foreach ($short in $cfg.PSObject.Properties.Name) {
  foreach ($c in $cfg.$short.cues) {
    $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
    $synth.SelectVoice('Microsoft Heami Desktop')
    $synth.Rate = $rate
    $global:bm = -1
    $synth.add_BookmarkReached({ param($s, $e) $global:bm = $e.AudioPosition.TotalMilliseconds })
    $wav = Join-Path $outDir ($c.id + '.wav')
    $fmt = New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo(24000, [System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen, [System.Speech.AudioFormat.AudioChannel]::Mono)
    $synth.SetOutputToWaveFile($wav, $fmt)
    $plain = $c.text -replace '\[tap\]', ''
    $esc = [Security.SecurityElement]::Escape($c.text) -replace '\[tap\]', '<mark name="tap"/>'
    $ssml = "<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xml:lang='ko-KR'>" + $esc + "</speak>"
    $synth.SpeakSsml($ssml)
    $synth.SetOutputToNull()
    $synth.Dispose()
    $len = (Get-Item $wav).Length
    $durMs = [math]::Round(($len - 44) / 48000.0 * 1000)
    $timing[$c.id] = @{ dur = $durMs; tap = [math]::Round($global:bm); text = $plain }
    Write-Output ("{0}`t{1}ms`ttap={2}`t{3}" -f $c.id, $durMs, [math]::Round($global:bm), $plain)
  }
}
[IO.File]::WriteAllText((Join-Path $outDir 'timing.json'), ($timing | ConvertTo-Json -Depth 4), (New-Object Text.UTF8Encoding($false)))
