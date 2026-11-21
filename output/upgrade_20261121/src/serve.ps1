param([string]$Root, [int]$Port = 8765)
# 정적 파일 서버 (검수용) — oneclick 저장소를 http://127.0.0.1:PORT/ 로
$l = New-Object System.Net.HttpListener
$l.Prefixes.Add("http://127.0.0.1:$Port/")
$l.Start()
$mime = @{ '.html'='text/html; charset=utf-8'; '.js'='application/javascript; charset=utf-8'; '.json'='application/json; charset=utf-8';
  '.css'='text/css'; '.png'='image/png'; '.jpg'='image/jpeg'; '.jpeg'='image/jpeg'; '.webp'='image/webp'; '.svg'='image/svg+xml';
  '.webmanifest'='application/manifest+json'; '.ico'='image/x-icon'; '.xml'='application/xml'; '.md'='text/plain; charset=utf-8' }
while ($l.IsListening) {
  try {
    $c = $l.GetContext()
    $p = [Uri]::UnescapeDataString($c.Request.Url.AbsolutePath.TrimStart('/'))
    if ($p -eq '' -or $p.EndsWith('/')) { $p = $p + 'index.html' }
    $f = Join-Path $Root $p
    if ((Test-Path $f -PathType Container)) { $f = Join-Path $f 'index.html' }
    if (Test-Path $f -PathType Leaf) {
      $b = [IO.File]::ReadAllBytes($f)
      $ext = [IO.Path]::GetExtension($f).ToLower()
      $c.Response.ContentType = $(if ($mime.ContainsKey($ext)) { $mime[$ext] } else { 'application/octet-stream' })
      $c.Response.Headers.Add('Cache-Control', 'no-store')
      $c.Response.OutputStream.Write($b, 0, $b.Length)
    } else { $c.Response.StatusCode = 404 }
    $c.Response.Close()
  } catch {}
}
