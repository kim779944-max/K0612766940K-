# 시험용 정적 파일 서버(로컬 전용) — catalog.json 을 fetch 하는 실서비스 동작을 file:// 대신 http:// 로 재현
param([string]$Root, [int]$Port = 8765)
$mime = @{ '.html' = 'text/html; charset=utf-8'; '.js' = 'application/javascript; charset=utf-8'; '.json' = 'application/json; charset=utf-8'; '.css' = 'text/css; charset=utf-8'; '.png' = 'image/png'; '.jpg' = 'image/jpeg'; '.svg' = 'image/svg+xml'; '.webmanifest' = 'application/manifest+json'; '.mp4' = 'video/mp4' }
$l = New-Object Net.HttpListener; $l.Prefixes.Add("http://localhost:$Port/"); $l.Start()
while ($l.IsListening) {
  $ctx = $l.GetContext(); $path = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath.TrimStart('/'))
  if ($path -eq '__stop') { $ctx.Response.Close(); break }
  if ($path -eq '' -or $path.EndsWith('/')) { $path += 'index.html' }
  $f = Join-Path $Root ($path -replace '/', '\')
  if (Test-Path -LiteralPath $f -PathType Leaf) {
    $b = [IO.File]::ReadAllBytes($f); $ext = [IO.Path]::GetExtension($f).ToLower()
    $ctx.Response.ContentType = $(if ($mime[$ext]) { $mime[$ext] } else { 'application/octet-stream' })
    $ctx.Response.OutputStream.Write($b, 0, $b.Length)
  } else { $ctx.Response.StatusCode = 404 }
  $ctx.Response.Close()
}
$l.Stop()
