# 빠른 연기 시험: 5종 + 허브를 ?sample=1&auto=1 로 열어 완주 여부·오류 수만 봅니다(자세한 판정은 verify.ps1).
param([string[]]$Only = @())
. "$PSScriptRoot\lib.ps1"
$tools = @('index.html', 'coupang.html', 'naver.html', 'global.html', 'blog.html', 'insta.html')
if ($Only.Count) { $tools = $Only }
Open-Tool 9361
try {
  foreach ($t in $tools) {
    $f = Join-Path $global:BASE $t
    if (-not (Test-Path $f)) { Write-Output ("SKIP " + $t + " (파일 없음)"); continue }
    Go-Tool ($t + '?sample=1&auto=1')
    $done = if ($t -eq 'index.html') { $true } else { Wait-For "window.__done===true" 20000 }
    $sw = Invoke-Js "document.documentElement.scrollWidth"
    Write-Output ("{0,-14} done={1} sw={2} errs={3}" -f $t, $done, $sw, (Errs))
  }
} finally { Stop-CdpChrome }
