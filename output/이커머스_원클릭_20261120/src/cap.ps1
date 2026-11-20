# 390×844 캡처 — 허브 + 5개 도구(결과가 보이는 상태: 1번째 탭, 3번째 탭)
# 사용: powershell -ExecutionPolicy Bypass -File src\cap.ps1   → shots\390_*.png
. "$PSScriptRoot\lib.ps1"
$shots = Join-Path $global:BASE 'shots'
$list = @(
  @{ f = 'index.html'; q = ''; n = 'index' },
  @{ f = 'coupang.html'; q = '?sample=1&auto=1'; n = 'coupang' },
  @{ f = 'naver.html'; q = '?sample=1&auto=1'; n = 'naver' },
  @{ f = 'global.html'; q = '?sample=1&auto=1'; n = 'global' },
  @{ f = 'blog.html'; q = '?sample=1&auto=1'; n = 'blog' },
  @{ f = 'insta.html'; q = '?sample=1&auto=1'; n = 'insta' }
)
Open-Tool 9391
try {
  foreach ($t in $list) {
    Go-Tool ($t.f + $t.q)
    if ($t.q) { Wait-For "window.__done===true" 25000 | Out-Null }
    Start-Sleep -Milliseconds 600
    Save-Screenshot (Join-Path $shots ('390_' + $t.n + '_top.png'))
    if ($t.n -eq 'index') { Save-Screenshot (Join-Path $shots '390_index.png'); Write-Output '390_index.png'; continue }
    # 결과 영역: 탭 줄이 화면 위쪽에 오도록 스크롤
    Invoke-Js "(function(){var b=document.querySelectorAll('#tabs button'); b[0].click(); var y=document.querySelector('#tabs').getBoundingClientRect().top+window.scrollY-130; window.scrollTo(0,y); return 1;})()" | Out-Null
    Start-Sleep -Milliseconds 400
    Save-Screenshot (Join-Path $shots ('390_' + $t.n + '.png'))
    Invoke-Js "(function(){var b=document.querySelectorAll('#tabs button'); b[Math.min(2,b.length-1)].click(); var y=document.querySelector('#tabs').getBoundingClientRect().top+window.scrollY-130; window.scrollTo(0,y); return 1;})()" | Out-Null
    Start-Sleep -Milliseconds 400
    Save-Screenshot (Join-Path $shots ('390_' + $t.n + '_tab3.png'))
    Write-Output ('390_' + $t.n + '.png · _top · _tab3')
  }
} finally { Stop-CdpChrome }
Get-ChildItem $shots -Filter '390_*.png' | ForEach-Object { Add-Type -AssemblyName System.Drawing; $im = [System.Drawing.Image]::FromFile($_.FullName); Write-Output ("{0} {1}×{2} {3}B" -f $_.Name, $im.Width, $im.Height, $_.Length); $im.Dispose() }
