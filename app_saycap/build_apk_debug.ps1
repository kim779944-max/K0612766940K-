# ============================================================
#  KTS SayCap - debug APK build WITHOUT Gradle / Android Studio
#  aapt2 -> javac -> d8 -> zipalign -> apksigner
#  Only requirement: JDK 17 (JAVA_HOME) + Android SDK (ANDROID_HOME)
#
#  Usage:
#    powershell -NoProfile -ExecutionPolicy Bypass -File .\build_apk_debug.ps1
#    powershell -NoProfile -ExecutionPolicy Bypass -File .\build_apk_debug.ps1 -VersionCode 14 -VersionName 1.4
#
#  This script changes ONLY android:versionCode / android:versionName
#  in AndroidManifest.xml. It never touches src/, res/ or assets/.
#  Output: ..\output\apk_20261117\KTS_saycap_v<VersionName>_debug.apk
# ============================================================
param(
  [int]$VersionCode = 14,
  [string]$VersionName = "1.4",
  [string]$OutDir = ""
)

$ErrorActionPreference = "Stop"
$Proj = $PSScriptRoot
Set-Location $Proj
if ([string]::IsNullOrWhiteSpace($OutDir)) { $OutDir = Join-Path $Proj "..\output\apk_20261117" }

function Step($m) { Write-Host ""; Write-Host "== $m" -ForegroundColor Cyan }
function Fail($m) { Write-Host ""; Write-Host "FAILED: $m" -ForegroundColor Red; exit 1 }
function Check($what, $code) { if ($code -ne 0) { Fail "$what (exit code $code)" } }

Write-Host "KTS SayCap debug APK build"
Write-Host "project : $Proj"
Write-Host "version : $VersionCode / $VersionName"

# ---------- 1. JDK 17 ----------
Step "1) locate JDK 17"
function TestJdk($p) { return ($p -and (Test-Path (Join-Path $p "bin\javac.exe"))) }
$JavaHome = $env:JAVA_HOME
if (-not (TestJdk $JavaHome)) {
  $roots = @(
    "C:\Program Files\Eclipse Adoptium",
    "C:\Program Files\Java",
    "C:\Program Files\Microsoft",
    "C:\Program Files\Android\Android Studio\jbr",
    "$env:LOCALAPPDATA\Programs\Eclipse Adoptium",
    "$env:LOCALAPPDATA\Android\jdk",
    "$env:USERPROFILE\.jdks",
    "$env:USERPROFILE\jdk"
  )
  $cands = @()
  foreach ($r in $roots) {
    if (Test-Path $r) {
      $leaf = Split-Path $r -Leaf
      if ($leaf -eq "jbr") { $cands += (Get-Item $r) }
      else { $cands += (Get-ChildItem $r -Directory -ErrorAction SilentlyContinue) }
    }
  }
  $pick17 = $cands | Where-Object { $_.Name -match "17" -and $_.Name -notmatch "jre" } | Sort-Object Name -Descending | Select-Object -First 1
  if (-not $pick17) { $pick17 = $cands | Sort-Object Name -Descending | Select-Object -First 1 }
  if ($pick17) { $JavaHome = $pick17.FullName }
}
if (-not (TestJdk $JavaHome)) { Fail "JDK not found. Install Temurin 17 and set JAVA_HOME (needs bin\javac.exe)." }
$env:JAVA_HOME = $JavaHome
$env:PATH = (Join-Path $JavaHome "bin") + ";" + $env:PATH
Write-Host "JAVA_HOME = $JavaHome"
& (Join-Path $JavaHome "bin\java.exe") -version 2>&1 | ForEach-Object { Write-Host "  $_" }

# ---------- 2. Android SDK ----------
Step "2) locate Android SDK"
$Sdk = $env:ANDROID_HOME
if (-not $Sdk) { $Sdk = $env:ANDROID_SDK_ROOT }
if (-not $Sdk) { $d = Join-Path $env:LOCALAPPDATA "Android\Sdk"; if (Test-Path $d) { $Sdk = $d } }
if (-not $Sdk -or -not (Test-Path $Sdk)) { Fail "Android SDK not found. Install cmdline-tools and set ANDROID_HOME." }
$env:ANDROID_HOME = $Sdk
Write-Host "ANDROID_HOME = $Sdk"

$btRoot = Join-Path $Sdk "build-tools"
if (-not (Test-Path $btRoot)) { Fail "SDK build-tools folder missing: $btRoot" }
$bt = $null
$preferred = Join-Path $btRoot "34.0.0"
if (Test-Path (Join-Path $preferred "aapt2.exe")) { $bt = Get-Item $preferred }
if (-not $bt) {
  $bt = Get-ChildItem $btRoot -Directory | Where-Object { Test-Path (Join-Path $_.FullName "aapt2.exe") } | Sort-Object Name | Select-Object -Last 1
}
if (-not $bt) { Fail "No build-tools with aapt2.exe under $btRoot" }
Write-Host "build-tools = $($bt.Name)"

$platRoot = Join-Path $Sdk "platforms"
$plat = $null
$prefPlat = Join-Path $platRoot "android-34\android.jar"
if (Test-Path $prefPlat) { $plat = $prefPlat }
if (-not $plat) {
  $pj = Get-ChildItem $platRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object { Join-Path $_.FullName "android.jar" } | Where-Object { Test-Path $_ } | Sort-Object | Select-Object -Last 1
  $plat = $pj
}
if (-not $plat) { Fail "No platforms\android-*\android.jar under $platRoot" }
Write-Host "android.jar = $plat"

$aapt2   = Join-Path $bt.FullName "aapt2.exe"
$zipalign = Join-Path $bt.FullName "zipalign.exe"
$apksigner = Join-Path $bt.FullName "apksigner.bat"
$d8      = Join-Path $bt.FullName "d8.bat"
foreach ($t in @($aapt2, $zipalign, $apksigner, $d8)) { if (-not (Test-Path $t)) { Fail "tool missing: $t" } }

# ---------- 3. version only ----------
Step "3) set android:versionCode / android:versionName (nothing else)"
$mf = Join-Path $Proj "AndroidManifest.xml"
$raw = [System.IO.File]::ReadAllText($mf)
$new = [regex]::Replace($raw, 'android:versionCode="[0-9]+"', ('android:versionCode="' + $VersionCode + '"'))
$new = [regex]::Replace($new, 'android:versionName="[^"]*"', ('android:versionName="' + $VersionName + '"'))
if ($new -ne $raw) {
  [System.IO.File]::WriteAllText($mf, $new, (New-Object System.Text.UTF8Encoding($false)))
  Write-Host "manifest version bumped -> $VersionCode / $VersionName"
} else {
  Write-Host "manifest already at $VersionCode / $VersionName"
}
$chk = [System.IO.File]::ReadAllText($mf)
if ($chk -notmatch ('android:versionCode="' + $VersionCode + '"')) { Fail "manifest versionCode did not change" }

# ---------- 4. compile resources ----------
Step "4) aapt2 compile"
if (Test-Path "build") { Remove-Item "build" -Recurse -Force }
New-Item -ItemType Directory -Force "build\gen" | Out-Null
New-Item -ItemType Directory -Force "build\classes" | Out-Null
New-Item -ItemType Directory -Force "build\dex" | Out-Null
& $aapt2 compile --dir res -o build\res.zip
Check "aapt2 compile" $LASTEXITCODE

Step "5) aapt2 link (res + assets)"
& $aapt2 link -o build\base.apk -I $plat --manifest AndroidManifest.xml -A assets build\res.zip --java build\gen --min-sdk-version 24 --target-sdk-version 34 --version-code $VersionCode --version-name $VersionName
Check "aapt2 link" $LASTEXITCODE

# ---------- 6. java -> dex ----------
Step "6) javac"
$srcs  = @(Get-ChildItem "src" -Recurse -Filter *.java | ForEach-Object { $_.FullName })
$gens  = @(Get-ChildItem "build\gen" -Recurse -Filter *.java | ForEach-Object { $_.FullName })
$jargs = @("-source","8","-target","8","-encoding","UTF-8","-classpath",$plat,"-d","build\classes") + $srcs + $gens
& (Join-Path $JavaHome "bin\javac.exe") $jargs
Check "javac" $LASTEXITCODE

Step "7) d8"
$classFiles = @(Get-ChildItem "build\classes" -Recurse -Filter *.class | ForEach-Object { $_.FullName })
if ($classFiles.Count -eq 0) { Fail "no .class files produced" }
& $d8 --release --lib $plat --min-api 24 --output build\dex $classFiles
Check "d8" $LASTEXITCODE
if (-not (Test-Path "build\dex\classes.dex")) { Fail "classes.dex not produced" }

# ---------- 8. pack ----------
Step "8) pack classes.dex into the APK"
Copy-Item "build\base.apk" "build\unsigned.apk" -Force
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipPath = (Resolve-Path "build\unsigned.apk").Path
$dexPath = (Resolve-Path "build\dex\classes.dex").Path
$zip = [System.IO.Compression.ZipFile]::Open($zipPath, 'Update')
try {
  $entry = $zip.CreateEntry('classes.dex', [System.IO.Compression.CompressionLevel]::Optimal)
  $es = $entry.Open()
  $ds = [System.IO.File]::OpenRead($dexPath)
  $ds.CopyTo($es)
  $ds.Close(); $es.Close()
} finally { $zip.Dispose() }

& $zipalign -f -p 4 build\unsigned.apk build\aligned.apk
Check "zipalign" $LASTEXITCODE

# ---------- 9. debug sign ----------
Step "9) debug signing"
$ksDir = Join-Path $env:USERPROFILE ".android"
New-Item -ItemType Directory -Force $ksDir | Out-Null
$ks = Join-Path $ksDir "debug.keystore"
if (-not (Test-Path $ks)) {
  & (Join-Path $JavaHome "bin\keytool.exe") -genkeypair -keystore $ks -storepass android -keypass android -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
  Check "keytool (debug keystore)" $LASTEXITCODE
  Write-Host "created debug keystore: $ks"
}
New-Item -ItemType Directory -Force $OutDir | Out-Null
$outApk = Join-Path $OutDir ("KTS_saycap_v" + $VersionName + "_debug.apk")
& $apksigner sign --ks $ks --ks-pass pass:android --key-pass pass:android --min-sdk-version 24 --v1-signing-enabled true --v2-signing-enabled true --v3-signing-enabled true --out $outApk "build\aligned.apk"
Check "apksigner sign" $LASTEXITCODE

# ---------- 10. verify ----------
Step "10) verify"
& $apksigner verify -v --print-certs $outApk
Check "apksigner verify" $LASTEXITCODE

Write-Host ""
Write-Host "badging:"
& $aapt2 dump badging $outApk 2>$null | Select-Object -First 3 | ForEach-Object { Write-Host "  $_" }

$fi = Get-Item $outApk
$sha = (Get-FileHash $outApk -Algorithm SHA256).Hash.ToLower()
Write-Host ""
Write-Host "APK    : $($fi.FullName)"
Write-Host "SIZE   : $($fi.Length) bytes"
Write-Host "SHA256 : $sha"
Write-Host ""
Write-Host "BUILD OK" -ForegroundColor Green
