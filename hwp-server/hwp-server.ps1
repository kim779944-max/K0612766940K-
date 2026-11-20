# KTS 구형 .hwp → PDF 변환 서버 (사무실 PC 전용)
#  - 127.0.0.1:8799 에만 바인딩. 외부로는 Cloudflare 터널로만 나간다.
#  - GET /health  → {"ok":true,"ver":"1.0"}
#  - POST /convert (multipart/form-data 또는 application/octet-stream + X-KTS-Name)
#  - 한글 COM(HWPFrame.HwpObject)은 STA 전용 → 변환은 STA 런스페이스 1개에서 1건씩.
#  - hwp-server/OFF 파일이 있으면 모든 요청 503.
# 실행:  powershell -NoProfile -STA -ExecutionPolicy Bypass -File hwp-server.ps1
param([int]$Port = 8799, [int]$TimeoutSec = 45)   # -TimeoutSec 은 시험용(504 경로 확인)

$ErrorActionPreference = 'Stop'
$VER        = '1.0'
$ALLOW_ORIG = 'https://autooneclick.com'
$MAX_BYTES  = 20MB
$TIMEOUT_S  = $TimeoutSec
$RATE_S     = 10
$Here    = $PSScriptRoot
$OffFile = Join-Path $Here 'OFF'
$LogDir  = Join-Path $Here 'logs'
$LogFile = Join-Path $LogDir 'hwp-server.log'
New-Item -ItemType Directory -Force $LogDir | Out-Null
$WorkRoot = Join-Path ([IO.Path]::GetTempPath()) 'kts-hwp-server'
New-Item -ItemType Directory -Force $WorkRoot | Out-Null
$Latin1 = [Text.Encoding]::GetEncoding(28591)

function Write-Log([string]$msg) {
  $line = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') + ' ' + $msg
  try { Add-Content -Path $LogFile -Value $line -Encoding UTF8 } catch {}
  Write-Host $line
}
function Get-NameHash([string]$s) {
  $sha = [Security.Cryptography.SHA256]::Create()
  $b = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes([string]$s))
  return (($b[0..5] | ForEach-Object { $_.ToString('x2') }) -join '')
}

# ---------- 응답 ----------
function Set-Cors($res) {
  $res.Headers['Access-Control-Allow-Origin']  = $ALLOW_ORIG
  $res.Headers['Access-Control-Allow-Methods'] = 'GET, POST, OPTIONS'
  $res.Headers['Access-Control-Allow-Headers'] = 'Content-Type, X-KTS-Name'
  $res.Headers['Access-Control-Max-Age']       = '600'
  $res.Headers['Vary'] = 'Origin'
}
function Send-Bytes($ctx, [int]$code, [byte[]]$bytes, [string]$type, $extra) {
  $res = $ctx.Response
  try {
    $res.StatusCode = $code
    Set-Cors $res
    $res.Headers['Cache-Control'] = 'no-store'
    $res.Headers['X-Content-Type-Options'] = 'nosniff'
    if ($extra) { foreach ($k in $extra.Keys) { $res.Headers[$k] = [string]$extra[$k] } }
    $res.ContentType = $type
    if ($bytes -and $bytes.Length) {
      $res.ContentLength64 = $bytes.Length
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
    } else { $res.ContentLength64 = 0 }
  } catch { } finally { try { $res.Close() } catch {} }
}
function Send-Json($ctx, [int]$code, [string]$json, $extra) {
  Send-Bytes $ctx $code ([Text.Encoding]::UTF8.GetBytes($json)) 'application/json; charset=utf-8' $extra
}
function Send-Err($ctx, [int]$code, [string]$err, $extra) {
  Send-Json $ctx $code ('{"ok":false,"err":"' + $err + '"}') $extra
}

# ---------- 요청 본문 ----------
function Read-Body($req, [int]$limit) {
  # 반환: byte[] / $null(초과)
  $ms = New-Object IO.MemoryStream
  $buf = New-Object byte[] 65536
  $st = $req.InputStream
  while (($n = $st.Read($buf, 0, $buf.Length)) -gt 0) {
    $ms.Write($buf, 0, $n)
    if ($ms.Length -gt $limit) { return $null }
  }
  return ,$ms.ToArray()
}
function Get-MultipartFile([byte[]]$body, [string]$ctype) {
  # 첫 번째 filename= 파트를 꺼낸다. 반환 @{name; data}
  $m = [regex]::Match($ctype, 'boundary=(?:"([^"]+)"|([^;]+))')
  if (-not $m.Success) { return $null }
  $bd = if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value.Trim() }
  $s = $Latin1.GetString($body)          # 바이트 위치 1:1 대응
  $delim = '--' + $bd
  $pos = 0
  while ($true) {
    $i = $s.IndexOf($delim, $pos, [StringComparison]::Ordinal)
    if ($i -lt 0) { return $null }
    $hs = $i + $delim.Length
    if ($s.Substring($hs, [Math]::Min(2, $s.Length - $hs)) -eq '--') { return $null }
    $he = $s.IndexOf("`r`n`r`n", $hs, [StringComparison]::Ordinal)
    if ($he -lt 0) { return $null }
    $hdr = $s.Substring($hs, $he - $hs)
    $ds = $he + 4
    $next = $s.IndexOf("`r`n" + $delim, $ds, [StringComparison]::Ordinal)
    if ($next -lt 0) { return $null }
    $fm = [regex]::Match($hdr, 'filename\*?=(?:"([^"]*)"|([^;\r\n]*))', 'IgnoreCase')
    if ($fm.Success) {
      $raw = if ($fm.Groups[1].Success) { $fm.Groups[1].Value } else { $fm.Groups[2].Value }
      $name = [Text.Encoding]::UTF8.GetString($Latin1.GetBytes($raw))
      $data = New-Object byte[] ($next - $ds)
      [Array]::Copy($body, $ds, $data, 0, $data.Length)
      return @{ name = $name; data = $data }
    }
    $pos = $next + 2
  }
}
function Test-Magic([byte[]]$d, [string]$ext) {
  if ($d.Length -lt 8) { return $false }
  if ($ext -eq '.hwp') {   # OLE 복합문서 D0 CF 11 E0 A1 B1 1A E1
    $sig = 0xD0,0xCF,0x11,0xE0,0xA1,0xB1,0x1A,0xE1
    for ($i = 0; $i -lt 8; $i++) { if ($d[$i] -ne $sig[$i]) { return $false } }
    return $true
  }
  if ($ext -eq '.hwpx') {  # ZIP PK\x03\x04
    return ($d[0] -eq 0x50 -and $d[1] -eq 0x4B -and $d[2] -eq 0x03 -and $d[3] -eq 0x04)
  }
  return $false
}

# ---------- 변환 작업자 (STA 런스페이스) ----------
$ConvertScript = {
  param([string]$src, [string]$dst, [string]$fmt)
  $h = $null
  try {
    # 직전 변환의 한글이 막 종료되는 중이면 그 개체에 붙어 RPC_E_DISCONNECTED(0x80010108)가 난다 → 잠깐 쉬고 다시
    for ($try = 1; ; $try++) {
      try {
        $h = New-Object -ComObject HWPFrame.HwpObject
        try { [void]$h.RegisterModule('FilePathCheckDLL', 'FilePathCheckerModule') } catch {}
        try { $h.XHwpWindows.Item(0).Visible = $false } catch {}
        $ok = $h.Open($src, $fmt, 'forceopen:true;suspendpassword:true')
        break
      } catch {
        if ($try -ge 4 -or $_.Exception.Message -notmatch '80010108|800706BA|800706BE|80010001') { throw }
        $h = $null
        Start-Sleep -Milliseconds (700 * $try)
      }
    }
    if (-not $ok) { return 'ERR:open' }
    $pages = 0; try { $pages = [int]$h.PageCount } catch {}
    $ok = $h.SaveAs($dst, 'PDF', '')
    if (-not $ok) { return 'ERR:save' }
    return 'OK:' + $pages
  } catch {
    return 'ERR:' + $_.Exception.Message
  } finally {
    if ($h) {
      try { $h.Clear(1) } catch {}
      try { $h.Quit() } catch {}
      try { [void][Runtime.InteropServices.Marshal]::FinalReleaseComObject($h) } catch {}
    }
  }
}
$script:Rs = $null
function New-Worker {
  if ($script:Rs) { try { $script:Rs.Dispose() } catch {} }
  $rs = [runspacefactory]::CreateRunspace()
  $rs.ApartmentState = 'STA'
  $rs.ThreadOptions = 'ReuseThread'
  $rs.Open()
  $script:Rs = $rs
}
function Get-HwpPids { @(Get-Process -Name 'Hwp' -ErrorAction SilentlyContinue | ForEach-Object { $_.Id }) }

$script:Job = $null   # 진행 중 변환 1건
function Start-Convert($ctx, [byte[]]$data, [string]$ext, [string]$nameHash) {
  $dir = Join-Path $WorkRoot ([guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Force $dir | Out-Null
  $src = Join-Path $dir ('in' + $ext)
  $dst = Join-Path $dir 'out.pdf'
  [IO.File]::WriteAllBytes($src, $data)
  $fmt = if ($ext -eq '.hwpx') { 'HWPX' } else { 'HWP' }
  $before = Get-HwpPids
  $ps = [powershell]::Create()
  $ps.Runspace = $script:Rs
  [void]$ps.AddScript($ConvertScript).AddArgument($src).AddArgument($dst).AddArgument($fmt)
  $script:Job = @{
    ctx = $ctx; ps = $ps; ar = $ps.BeginInvoke(); dir = $dir; dst = $dst
    t0 = [Diagnostics.Stopwatch]::StartNew(); before = $before; bytes = $data.Length; nh = $nameHash
  }
}
function Remove-JobFiles($job) {
  try { Remove-Item -LiteralPath $job.dir -Recurse -Force -ErrorAction Stop } catch {
    Start-Sleep -Milliseconds 300
    try { Remove-Item -LiteralPath $job.dir -Recurse -Force -ErrorAction Stop } catch { Write-Log "WARN 임시폴더 삭제 실패" }
  }
}
function Step-Convert {
  $job = $script:Job
  if (-not $job) { return }
  $ms = $job.t0.ElapsedMilliseconds
  if ($job.ar.IsCompleted) {
    $script:Job = $null
    try {
      $out = $null
      try { $out = @($job.ps.EndInvoke($job.ar)) | Select-Object -Last 1 } catch { $out = 'ERR:' + $_.Exception.Message }
      $job.ps.Dispose()
      if ("$out".StartsWith('OK:') -and (Test-Path -LiteralPath $job.dst)) {
        $pdf = [IO.File]::ReadAllBytes($job.dst)
        $pages = "$out".Substring(3)
        Send-Bytes $job.ctx 200 $pdf 'application/pdf' @{ 'X-KTS-Pages' = $pages }
        Write-Log ("convert 200 name#{0} in={1}B out={2}B pages={3} {4}ms" -f $job.nh, $job.bytes, $pdf.Length, $pages, $ms)
      } else {
        $why = ("$out" -replace '[^\w:. -]', '')
        if ($why.Length -gt 80) { $why = $why.Substring(0, 80) }
        Send-Err $job.ctx 422 'convert_failed'
        Write-Log ("convert 422 name#{0} in={1}B {2}ms {3}" -f $job.nh, $job.bytes, $ms, $why)
      }
    } finally { Remove-JobFiles $job }
    return
  }
  if ($ms -gt ($TIMEOUT_S * 1000)) {
    $script:Job = $null
    try {
      Send-Err $job.ctx 504 'timeout'     # 응답 먼저 — 정리 작업이 늦어져도 손님은 기다리지 않게
      # 이 변환이 띄운 한글 프로세스만 강제 종료(대표님이 열어 둔 한글 창은 건드리지 않음)
      $new = @(Get-HwpPids | Where-Object { $job.before -notcontains $_ })
      foreach ($p in $new) { try { Stop-Process -Id $p -Force -ErrorAction Stop } catch {} }
      # 멈춘 COM 호출이 풀릴 때까지 기다리지 않는다: 비동기 정지 + 새 작업자 런스페이스
      try { [void]$job.ps.BeginStop($null, $null) } catch {}
      $script:Rs = $null
      New-Worker
      Write-Log ("convert 504 name#{0} in={1}B {2}ms killed={3}" -f $job.nh, $job.bytes, $ms, $new.Count)
    } finally { Remove-JobFiles $job }
  }
}

# ---------- 요청 처리 ----------
$script:LastByIp = @{}
function Get-ClientIp($req) {
  $cf = $req.Headers['CF-Connecting-IP']
  if ($cf -and $req.RemoteEndPoint.Address.ToString() -eq '127.0.0.1') { return $cf.Trim() }
  return $req.RemoteEndPoint.Address.ToString()
}
function Invoke-Request($ctx) {
  $req = $ctx.Request
  $path = $req.Url.AbsolutePath.TrimEnd('/')
  if (Test-Path -LiteralPath $OffFile) { Send-Err $ctx 503 'off'; Write-Log "$($req.HttpMethod) $path 503 off"; return }
  if ($req.HttpMethod -eq 'OPTIONS') { Send-Bytes $ctx 204 $null 'text/plain' $null; return }
  if ($path -eq '/health' -and $req.HttpMethod -eq 'GET') { Send-Json $ctx 200 ('{"ok":true,"ver":"' + $VER + '"}') $null; return }
  if ($path -ne '/convert') { Send-Err $ctx 404 'not_found'; return }
  if ($req.HttpMethod -ne 'POST') { Send-Err $ctx 405 'method' @{ 'Allow' = 'POST, OPTIONS' }; return }

  if ($script:Job) { Send-Err $ctx 429 'busy' @{ 'Retry-After' = '5' }; Write-Log "convert 429 busy"; return }
  $ip = Get-ClientIp $req
  $now = [DateTime]::UtcNow
  if ($script:LastByIp.ContainsKey($ip) -and ($now - $script:LastByIp[$ip]).TotalSeconds -lt $RATE_S) {
    Send-Err $ctx 429 'rate' @{ 'Retry-After' = [string][Math]::Ceiling($RATE_S - ($now - $script:LastByIp[$ip]).TotalSeconds) }
    Write-Log "convert 429 rate"; return
  }
  $script:LastByIp[$ip] = $now
  if ($script:LastByIp.Count -gt 2000) { $script:LastByIp.Clear() }

  if ($req.ContentLength64 -gt $MAX_BYTES + 64KB) { Send-Err $ctx 413 'too_large'; Write-Log "convert 413 len=$($req.ContentLength64)"; return }
  $body = Read-Body $req ($MAX_BYTES + 64KB)
  if ($null -eq $body) { Send-Err $ctx 413 'too_large'; Write-Log "convert 413 stream"; return }

  $ctype = [string]$req.ContentType
  $name = $null; $data = $null
  if ($ctype -match '^multipart/form-data') {
    $part = Get-MultipartFile $body $ctype
    if ($part) { $name = $part.name; $data = $part.data }
  } else {
    $hn = [string]$req.Headers['X-KTS-Name']
    try { $name = [Uri]::UnescapeDataString($hn) } catch { $name = $hn }
    $data = $body
  }
  if (-not $data -or -not $name) { Send-Err $ctx 400 'no_file'; Write-Log "convert 400 no_file"; return }
  if ($data.Length -gt $MAX_BYTES) { Send-Err $ctx 413 'too_large'; Write-Log "convert 413 file=$($data.Length)B"; return }
  $ext = [IO.Path]::GetExtension($name.Trim()).ToLowerInvariant()
  $nh = Get-NameHash $name
  if (($ext -ne '.hwp' -and $ext -ne '.hwpx') -or -not (Test-Magic $data $ext)) {
    Send-Err $ctx 415 'unsupported'; Write-Log ("convert 415 name#{0} ext={1} {2}B" -f $nh, ($ext -replace '[^\w.]', ''), $data.Length); return
  }
  Start-Convert $ctx $data $ext $nh
}

# ---------- 메인 루프 ----------
if ([Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') { Write-Log 'WARN 메인 스레드가 STA가 아님(-STA 권장)' }
New-Worker
$listener = New-Object Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
$listener.IgnoreWriteExceptions = $true
$listener.Start()
Write-Log "hwp-server $VER listening http://127.0.0.1:$Port/ (pid $PID)"
$pending = $listener.GetContextAsync()
try {
  while ($listener.IsListening) {
    if ($pending.Wait(100)) {
      $ctx = $pending.Result
      $pending = $listener.GetContextAsync()
      try { Invoke-Request $ctx } catch {
        Write-Log ("ERR request: " + ($_.Exception.Message -replace '[\r\n]', ' '))
        try { Send-Err $ctx 500 'internal' } catch {}
      }
    }
    try { Step-Convert } catch { Write-Log ("ERR step: " + ($_.Exception.Message -replace '[\r\n]', ' ')) }
  }
} finally {
  try { $listener.Stop() } catch {}
  Write-Log 'hwp-server stopped'
}
