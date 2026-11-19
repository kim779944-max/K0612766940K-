# assets/data/*.json → assets/data/bundle.js (file:// 로 열어도 데이터가 읽히게)
# 대표님이 JSON 을 고친 뒤 이 파일을 한 번 실행하면 화면에 반영됩니다.
# 사용: powershell -ExecutionPolicy Bypass -File src\build_data.ps1
$ErrorActionPreference = 'Stop'
$base = (Resolve-Path "$PSScriptRoot\..").Path
$dir = Join-Path $base 'assets\data'
$names = @('fees', 'duties', 'tags_ko', 'copy_ko', 'copy_en', 'copy_ja', 'blog_bones', 'insta_copy', 'sample_products')
$utf8 = New-Object System.Text.UTF8Encoding($false)
$sb = New-Object System.Text.StringBuilder
[void]$sb.Append("/* 자동 생성 파일 — 직접 고치지 말고 assets/data/*.json 을 고친 뒤 src/build_data.ps1 실행 */`n")
[void]$sb.Append("window.KTS_DATA = {`n")
$i = 0
foreach ($n in $names) {
  $p = Join-Path $dir ($n + '.json')
  $raw = [IO.File]::ReadAllText($p, [Text.Encoding]::UTF8)
  try { $null = $raw | ConvertFrom-Json } catch { Write-Output ("JSON 오류: " + $p + " :: " + $_.Exception.Message); exit 2 }

  [void]$sb.Append('"' + $n + '": ' + $raw.Trim() + ",`n")
  $i++
}
# 쿠팡 업로드 스크립트(src/upload_coupang.ps1)를 문자열로 함께 묶어 화면의 [업로드 스크립트 받기]가 같은 파일을 내려주게 함
$ps1 = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'upload_coupang.ps1'), [Text.Encoding]::UTF8).TrimStart([char]0xFEFF)
Add-Type -AssemblyName System.Web.Extensions
$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
$ser.MaxJsonLength = [int]::MaxValue
[void]$sb.Append('"upload_ps1": ' + $ser.Serialize($ps1) + "`n")
[void]$sb.Append("};`n")
[IO.File]::WriteAllText((Join-Path $dir 'bundle.js'), $sb.ToString(), $utf8)
Write-Output ("bundle.js OK · " + $names.Count + "개 · " + (Get-Item (Join-Path $dir 'bundle.js')).Length + " bytes")
