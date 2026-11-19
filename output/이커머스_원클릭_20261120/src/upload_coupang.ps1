# 쿠팡 오픈 API 상품 등록 — 서명·전송 스크립트 (PowerShell 5.1 그대로 실행, 템플릿)
# · 열쇠는 이 파일에 쓰지 않습니다. 실행 창에서만 환경변수로 넣으세요:
#     $env:COUPANG_ACCESS_KEY = '...'; $env:COUPANG_SECRET_KEY = '...'; $env:COUPANG_VENDOR_ID = 'A0...'
# · 기본은 미리보기(-WhatIf): 요청 본문·서명·헤더만 출력하고 아무것도 보내지 않습니다.
# · 실제 전송은 -Send 를 붙였을 때만 합니다.
#     powershell -ExecutionPolicy Bypass -File upload_coupang.ps1                 (미리보기)
#     powershell -ExecutionPolicy Bypass -File upload_coupang.ps1 -Send           (실제 전송)
# · 서명 규칙(쿠팡 HMAC): message = signedDate + method + path + query ('?' 없이), HMAC-SHA256(secretKey) → hex 소문자
#   signedDate 형식 yyMMdd'T'HHmmss'Z' (GMT)
param(
  [string]$BodyFile = '',
  [string]$SignedDate = '',
  [string]$Method = 'POST',
  [string]$Path = '/v2/providers/seller_api/apis/api/v1/marketplace/seller-products',
  [string]$Query = '',
  [switch]$WhatIf,
  [switch]$Send
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$ApiHost = 'https://api-gateway.coupang.com'
if (-not $BodyFile) { $BodyFile = Join-Path $PSScriptRoot 'coupang_body.json' }

$ak = $env:COUPANG_ACCESS_KEY
$sk = $env:COUPANG_SECRET_KEY
$vendor = $env:COUPANG_VENDOR_ID

if (-not $SignedDate) { $SignedDate = [DateTime]::UtcNow.ToString("yyMMdd'T'HHmmss'Z'", [Globalization.CultureInfo]::InvariantCulture) }
$message = $SignedDate + $Method + $Path + $Query

$sig = ''
if ($sk) {
  $hm = New-Object System.Security.Cryptography.HMACSHA256 (, [Text.Encoding]::UTF8.GetBytes($sk))
  $sig = -join ($hm.ComputeHash([Text.Encoding]::UTF8.GetBytes($message)) | ForEach-Object { $_.ToString('x2') })
}
$auth = 'CEA algorithm=HmacSHA256, access-key=' + $ak + ', signed-date=' + $SignedDate + ', signature=' + $sig
$authMasked = 'CEA algorithm=HmacSHA256, access-key=***, signed-date=' + $SignedDate + ', signature=' + $sig

$body = ''
if (Test-Path $BodyFile) {
  $body = [IO.File]::ReadAllText($BodyFile, [Text.Encoding]::UTF8)
  if ($vendor) { $body = $body.Replace('"VENDOR_ID"', '"' + $vendor + '"') }
}

Write-Output ('MESSAGE=' + $message)
Write-Output ('SIGNATURE=' + $(if ($sig) { $sig } else { '(SECRET 없음 - 서명 생략)' }))
Write-Output ('AUTHORIZATION=' + $authMasked)
Write-Output ('URL=' + $ApiHost + $Path + $(if ($Query) { '?' + $Query } else { '' }))
Write-Output ('BODY_BYTES=' + [Text.Encoding]::UTF8.GetByteCount($body))

if (-not $Send) {
  Write-Output 'MODE=WhatIf (미리보기 - 아무것도 보내지 않았습니다. 실제 전송은 -Send)'
  exit 0
}
if (-not $ak -or -not $sk) { Write-Output 'ERROR=환경변수 COUPANG_ACCESS_KEY / COUPANG_SECRET_KEY 가 비어 있습니다'; exit 3 }
if (-not $body) { Write-Output ('ERROR=요청 본문 파일이 없습니다: ' + $BodyFile); exit 4 }
if ($body.Contains('"VENDOR_ID"')) { Write-Output 'ERROR=업체코드(COUPANG_VENDOR_ID)를 넣어 주세요'; exit 5 }

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$uri = $ApiHost + $Path + $(if ($Query) { '?' + $Query } else { '' })
try {
  $r = Invoke-WebRequest -UseBasicParsing -Method $Method -Uri $uri -Headers @{ Authorization = $auth; 'X-EXTENDED-TIMEOUT' = '90000' } -ContentType 'application/json;charset=UTF-8' -Body ([Text.Encoding]::UTF8.GetBytes($body))
  Write-Output ('STATUS=' + $r.StatusCode)
  Write-Output $r.Content
} catch {
  Write-Output ('ERROR=' + $_.Exception.Message)
  try { $sr = New-Object IO.StreamReader($_.Exception.Response.GetResponseStream()); Write-Output $sr.ReadToEnd() } catch {}
  exit 6
}
